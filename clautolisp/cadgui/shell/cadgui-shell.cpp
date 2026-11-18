// cadgui-shell -- the embedded-ECL Qt6 shell of the cadgui host.
// cadgui-2-qt6-gui-host.issue slices A/C/D/E + the MULTI-THREADED live window.
//
// The shell is the host PROCESS: it boots embedded ECL, loads clautolisp/cadgui
// (which pulls cador), and is an interactive CAD canvas on the cador model.
//   CL owns the model; C++ owns the window + per-frame paint + pan/zoom + input.
//   The boundary (the cadgui protocol) crosses only on regen and on input.
//
// THREADING (the "right architecture", cadgui-2 "Threading architecture"):
//   Qt's event loop and ALL QWidget work run on the MAIN thread. The application
//   lisp runs on a NEW ECL thread (mp:process-run-function) -- it is the single
//   actor that touches the cador model: it evaluates commands AND exports the
//   display list, both on its own thread, so there is no cross-thread CL race
//   and no cador-wide lock. The main thread only ever reads a C++ SNAPSHOT
//   (std::mutex-guarded) to paint, and hands the runner work across two
//   thread-safe queues:
//     - CommandQueue: the command line posts strings; the runner evaluates them.
//     - PointQueue:   a click posts a world point; the runner's blocked
//                     getpoint/entsel (via *cadgui-input-hook*) consumes it.
//   After each command the runner exports a fresh snapshot and asks the main
//   thread to repaint, cross-thread, via QMetaObject::invokeMethod(Queued).
//   This is the single-document shape of cador's park-by-threads model; the
//   multi-document scheduler (per-document runner/driver pairs) layers on top.
//
// Modes:
//   (default)        a LIVE window: real mouse drives getpoint/entsel, wheel
//                    zooms, middle-drag pans, 'e' zoom-extents, a command line
//                    at the bottom evals AutoLISP; QApplication::exec(). The app
//                    lisp runs on its own thread.
//   --render FILE    render the current scene offscreen to FILE and exit (CI);
//                    static, no runner thread.
//   --demo FILE      offscreen, threaded: start the runner, post a getpoint-
//                    driven command, feed SYNTHETIC device clicks through the
//                    REAL handler (device->world->PointQueue) when the runner is
//                    awaiting, wait for the published snapshot, save FILE. The
//                    headless validation of the multi-threaded live path.

#include <ecl/ecl.h>

// When built with -DCADGUI_USE_LIB, the whole clautolisp/cadgui closure is
// linked in as a monolithic static library (build-cadgui-lib.sh) and
// initialized from C via ecl_init_module -- no ASDF/Quicklisp at runtime, so no
// warm-cache planner overflow and no ~96 s recompile. The generated header
// declares the (randomised) init symbol as CADGUI_LIB_INIT. See NOTES-ecl.md.
#ifdef CADGUI_USE_LIB
#  include "cadgui-lib-init.h"
#endif

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QColor>
#include <QtGui/QMouseEvent>
#include <QtGui/QWheelEvent>
#include <QtGui/QKeyEvent>
#include <QtCore/QString>
#include <QtCore/QPointF>
#include <QtCore/QTimer>
#include <QtCore/QMetaObject>

#include <vector>
#include <deque>
#include <string>
#include <mutex>
#include <condition_variable>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>

// ---- embedded-ECL helpers ------------------------------------------------
static cl_object eval_str(const char *code) {
    return cl_safe_eval(c_string_to_object(code), ECL_NIL, ECL_NIL);
}
static std::string lisp_string(cl_object s) {
    if (ECL_STRINGP(s)) {
        cl_object b = si_coerce_to_base_string(s);
        return std::string((const char *)b->base_string.self, b->base_string.fillp);
    }
    return std::string();
}
static cl_object to_base_string(const std::string &s) {
    return ecl_make_simple_base_string(s.c_str(), (cl_index)s.size());
}

// ---- a thread-safe blocking queue (runner blocks in take, main does put) ---
template <class T>
class BlockingQueue {
public:
    void put(T v) {
        { std::lock_guard<std::mutex> g(m_); q_.push_back(std::move(v)); }
        cv_.notify_one();
    }
    T take() {                                   // blocks the calling thread
        std::unique_lock<std::mutex> l(m_);
        cv_.wait(l, [this] { return !q_.empty(); });
        T v = std::move(q_.front()); q_.pop_front();
        return v;
    }
private:
    std::deque<T> q_;
    std::mutex m_;
    std::condition_variable cv_;
};

// ---- the cador display-list model, marshalled to C++ ----------------------
struct Prim {
    std::string handle, layer;
    long aci = 256; bool closed = false;
    std::vector<double> pts;
};
// pull_* call into Lisp -- they run ONLY on the runner thread (or on the main
// thread BEFORE the runner starts, when there is no concurrency).
static std::vector<Prim> pull_prims(const char *form) {
    std::vector<Prim> prims;
    cl_object dl = eval_str(form);
    for (cl_object p = dl; p != ECL_NIL; p = ecl_cdr(p)) {
        cl_object prim = ecl_car(p), rest = ecl_cdr(prim);
        Prim out;
        out.handle = lisp_string(ecl_car(rest)); rest = ecl_cdr(rest);
        out.layer  = lisp_string(ecl_car(rest)); rest = ecl_cdr(rest);
        out.aci    = ecl_to_fixnum(ecl_car(rest)); rest = ecl_cdr(rest);
        out.closed = (ecl_car(rest) != ECL_NIL); rest = ecl_cdr(rest);
        for (cl_object q = ecl_car(rest); q != ECL_NIL; q = ecl_cdr(q))
            out.pts.push_back(ecl_to_double(ecl_car(q)));
        prims.push_back(out);
    }
    return prims;
}
static std::vector<Prim> pull_display_list() {
    return pull_prims("(clautolisp.cadgui:cadgui-display-list)");
}
static std::vector<Prim> pull_selection() {     // the entsel-highlighted entity
    return pull_prims("(clautolisp.cadgui:cadgui-selection-geometry)");
}
static bool pull_extents(double &x0, double &y0, double &x1, double &y1) {
    cl_object e = eval_str("(clautolisp.cadgui:cadgui-extents)");
    if (e == ECL_NIL) return false;
    x0 = ecl_to_double(ecl_car(e));
    y0 = ecl_to_double(ecl_car(ecl_cdr(e)));
    x1 = ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(e))));
    y1 = ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(ecl_cdr(e)))));
    return true;
}
static QColor aci_to_rgb(long aci) {
    switch (aci) {
        case 1: return QColor(255, 80, 80);  case 2: return QColor(255, 255, 90);
        case 3: return QColor(110, 230, 120); case 4: return QColor(100, 220, 230);
        case 5: return QColor(120, 160, 255); case 6: return QColor(230, 120, 230);
        case 7: return QColor(235, 235, 235); default: return QColor(200, 210, 220);
    }
}

// ---- the SNAPSHOT: the runner publishes it, the main thread paints it ------
struct Snapshot {
    std::vector<Prim> prims;
    std::vector<Prim> selected;              // entsel-highlighted geometry, overdrawn
    double x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    bool haveExtents = false;
};
static std::mutex  g_snapMutex;
static Snapshot    g_snap;
static void     storeSnapshot(Snapshot s) { std::lock_guard<std::mutex> g(g_snapMutex); g_snap = std::move(s); }
static Snapshot loadSnapshot()            { std::lock_guard<std::mutex> g(g_snapMutex); return g_snap; }
static Snapshot buildSnapshot() {          // calls Lisp -> runner thread only
    Snapshot s;
    s.prims = pull_display_list();
    s.selected = pull_selection();
    s.haveExtents = pull_extents(s.x0, s.y0, s.x1, s.y1);
    return s;
}

// ---- the cross-thread channels --------------------------------------------
struct Cmd { bool quit = false; std::string text; };
static BlockingQueue<QPointF> g_pointQueue;      // click -> runner's getpoint
static BlockingQueue<Cmd>     g_cmdQueue;        // command line -> runner
static std::atomic<bool>      g_awaiting{false}; // runner is blocked in getpoint
static std::atomic<int>       g_pointRequests{0};// total getpoint/entsel requests so far
static QWidget               *g_canvas = nullptr;

static void requestRepaint() {                   // ask the MAIN thread to repaint
    if (g_canvas)
        QMetaObject::invokeMethod(g_canvas, [] { if (g_canvas) g_canvas->update(); },
                                  Qt::QueuedConnection);
}

// ---- C functions the LISP runner thread calls -----------------------------
#ifdef CADGUI_TRACE
#  define CTRACE(...) do { std::fprintf(stderr, "[cadgui] " __VA_ARGS__); std::fprintf(stderr, "\n"); std::fflush(stderr); } while (0)
#else
#  define CTRACE(...) do {} while (0)
#endif

static cl_object cadgui_shell_await_input() {    // *cadgui-input-hook* -> "x,y"
    g_pointRequests++;                           // one more getpoint/entsel request
    CTRACE("runner: awaiting point (request #%d)", g_pointRequests.load());
    g_awaiting = true;  requestRepaint();        // show the crosshair
    QPointF w = g_pointQueue.take();             // BLOCKS the runner thread
    g_awaiting = false; requestRepaint();
    CTRACE("runner: got point %.3g,%.3g", w.x(), w.y());
    char buf[80];
    std::snprintf(buf, sizeof buf, "%.10g,%.10g", w.x(), w.y());
    return ecl_make_simple_base_string(buf, (cl_index)std::strlen(buf));
}
static cl_object cadgui_shell_next_command() {   // blocks for the next command
    CTRACE("runner: waiting for command");
    Cmd c = g_cmdQueue.take();
    if (c.quit) { CTRACE("runner: quit"); return ECL_NIL; }
    CTRACE("runner: got command");
    return to_base_string(c.text);
}
static cl_object cadgui_shell_publish() {        // export a snapshot + repaint
    storeSnapshot(buildSnapshot());              // on the runner thread (owns CL)
    CTRACE("runner: published %zu prims", loadSnapshot().prims.size());
    requestRepaint();
    return ECL_NIL;
}

// ---- the view transform (pan / zoom, Y flipped) ---------------------------
struct View {
    double scale = 1.0, ox = 0.0, oy = 0.0;   // devX = ox + scale*wx; devY = oy - scale*wy
    QPointF toDev(double wx, double wy) const { return QPointF(ox + scale*wx, oy - scale*wy); }
    QPointF toWorld(double dx, double dy) const { return QPointF((dx - ox)/scale, (oy - dy)/scale); }
    void fit(double x0, double y0, double x1, double y1, int W, int H, double m) {
        double dw = std::max(1e-9, x1 - x0), dh = std::max(1e-9, y1 - y0);
        scale = std::min((W - 2*m)/dw, (H - 2*m)/dh);
        ox = W/2.0 - scale*(x0 + x1)/2.0;
        oy = H/2.0 + scale*(y0 + y1)/2.0;
    }
    void zoomAt(QPointF d, double f) {           // cursor-anchored zoom
        QPointF w = toWorld(d.x(), d.y());
        scale *= f;
        ox = d.x() - scale*w.x();
        oy = d.y() + scale*w.y();
    }
};

// ---- the canvas: paints the SNAPSHOT (read cross-thread, under the lock) ----
class Canvas : public QWidget {
public:
    View view;
    bool haveFit = false;
    QPointF cursorDev;

    void refresh() { if (!haveFit) zoomExtents(); update(); }   // snapshot already stored
    void zoomExtents() {
        Snapshot s = loadSnapshot();
        if (s.haveExtents) { view.fit(s.x0, s.y0, s.x1, s.y1, width(), height(), 28); haveFit = true; }
        update();
    }
protected:
    void mousePressEvent(QMouseEvent *e) override {
        if (e->button() == Qt::LeftButton && g_awaiting.load())
            g_pointQueue.put(view.toWorld(e->position().x(), e->position().y()));
        else if (e->button() == Qt::MiddleButton) { panning = true; panFrom = e->position(); }
    }
    void mouseMoveEvent(QMouseEvent *e) override {
        cursorDev = e->position();
        if (panning) { QPointF d = e->position() - panFrom; view.ox += d.x(); view.oy += d.y();
                       panFrom = e->position(); }
        update();
    }
    void mouseReleaseEvent(QMouseEvent *e) override {
        if (e->button() == Qt::MiddleButton) panning = false;
    }
    void wheelEvent(QWheelEvent *e) override {
        double f = (e->angleDelta().y() > 0) ? 1.15 : 1.0/1.15;
        view.zoomAt(e->position(), f); update();
    }
    void keyPressEvent(QKeyEvent *e) override {
        if (e->key() == Qt::Key_E) zoomExtents();
    }
    void paintEvent(QPaintEvent *) override {
        Snapshot s = loadSnapshot();                             // read cross-thread
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(18, 22, 30));
        g.setPen(QPen(QColor(55, 64, 78), 1.0));                 // axes
        g.drawLine(view.toDev(-1e5,0), view.toDev(1e5,0));
        g.drawLine(view.toDev(0,-1e5), view.toDev(0,1e5));
        for (const Prim &pr : s.prims) {
            QPen pen(aci_to_rgb(pr.aci)); pen.setWidthF(1.8); g.setPen(pen);
            QVector<QPointF> poly;
            for (size_t i = 0; i + 1 < pr.pts.size(); i += 2)
                poly.push_back(view.toDev(pr.pts[i], pr.pts[i+1]));
            if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
            if (poly.size() >= 2) g.drawPolyline(poly.constData(), poly.size());
            else if (poly.size() == 1) g.drawPoint(poly.first());
        }
        // The entsel selection, overdrawn highlighted (thick dashed white).
        if (!s.selected.empty()) {
            QPen hp(QColor(255, 255, 255)); hp.setWidthF(3.0);
            hp.setStyle(Qt::DashLine); g.setPen(hp);
            for (const Prim &pr : s.selected) {
                QVector<QPointF> poly;
                for (size_t i = 0; i + 1 < pr.pts.size(); i += 2)
                    poly.push_back(view.toDev(pr.pts[i], pr.pts[i+1]));
                if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
                if (poly.size() >= 2) g.drawPolyline(poly.constData(), poly.size());
                else if (poly.size() == 1) g.drawPoint(poly.first());
            }
        }
        if (g_awaiting.load()) {                                 // crosshair while picking
            g.setPen(QPen(QColor(120, 220, 160), 1.0));
            g.drawLine(QPointF(0, cursorDev.y()), QPointF(width(), cursorDev.y()));
            g.drawLine(QPointF(cursorDev.x(), 0), QPointF(cursorDev.x(), height()));
        }
    }
private:
    bool panning = false; QPointF panFrom;
};

// ---- the main window ------------------------------------------------------
class MainWindow : public QWidget {
public:
    Canvas *canvas; QLineEdit *cmd;
    MainWindow() {
        auto *lay = new QVBoxLayout(this); lay->setContentsMargins(0,0,0,0); lay->setSpacing(0);
        canvas = new Canvas; canvas->setMinimumSize(480, 360);
        cmd = new QLineEdit; cmd->setPlaceholderText("command: e.g. (command \"CIRCLE\" (getpoint) 5.0)");
        lay->addWidget(canvas, 1); lay->addWidget(cmd, 0);
        QObject::connect(cmd, &QLineEdit::returnPressed, this, [this] {
            std::string s = cmd->text().toStdString(); cmd->clear();
            if (!s.empty()) g_cmdQueue.put(Cmd{false, s});       // hand it to the runner
        });
    }
};

// ---- register the C hooks + start the application-lisp RUNNER thread --------
static void install_runner_hooks() {
    ecl_def_c_function(c_string_to_object("CADGUI-SHELL-AWAIT-INPUT"),
                       (cl_objectfn_fixed)cadgui_shell_await_input, 0);
    ecl_def_c_function(c_string_to_object("CADGUI-SHELL-NEXT-COMMAND"),
                       (cl_objectfn_fixed)cadgui_shell_next_command, 0);
    ecl_def_c_function(c_string_to_object("CADGUI-SHELL-PUBLISH"),
                       (cl_objectfn_fixed)cadgui_shell_publish, 0);
    // getpoint/entsel read the canvas through this hook.
    eval_str("(setf clautolisp.cadgui:*cadgui-input-hook*"
             "      (symbol-function 'cadgui-shell-await-input))");
    // The runner loop (CL-USER so c_string_to_object reads the bare symbols in
    // the CL-USER package): take a command, eval it (may block in getpoint on
    // the point queue), publish a fresh snapshot, repeat until a NIL command.
    // Publish (re-export + repaint) only when the command changed something
    // visible: the drawing (regen-on-dbmod, via the monotonic drawing-dbtick) OR
    // the selection (an entsel highlights without modifying the model). A pure
    // query redraws nothing.
    eval_str("(defun cadgui-shell-runner ()"
             "  (loop"
             "    (let ((cmd (cadgui-shell-next-command)))"
             "      (when (null cmd) (return))"
             "      (let ((serial (clautolisp.cadgui:cadgui-regen-serial))"
             "            (sel (clautolisp.cadgui:cadgui-selection)))"
             "        (handler-case (clautolisp.cadgui:cadgui-eval-command cmd)"
             "          (error (e) (format *error-output* \"~&cadgui command error: ~a~%\" e)))"
             "        (when (or (/= serial (clautolisp.cadgui:cadgui-regen-serial))"
             "                  (not (equal sel (clautolisp.cadgui:cadgui-selection))))"
             "          (cadgui-shell-publish))))))");
}
static void start_runner() {
    eval_str("(mp:process-run-function \"cadgui-app\" (function cadgui-shell-runner))");
    CTRACE("main: runner started");
}

// ---- main ----------------------------------------------------------------
static void boot_ecl_and_load(int argc, char **argv) {
    cl_boot(argc, argv);
    eval_str("(progn (ext:set-limit (quote ext:binding-stack) (* 1024 1024 64))"
             "       (ext:set-limit (quote ext:frame-stack) (* 1024 1024))"
             "       (ext:set-limit (quote ext:lisp-stack) (* 1024 1024 64)))");
    eval_str("(setf *debugger-hook* (lambda (c h) (declare (ignore h))"
             "  (format *error-output* \"~&cadgui-shell lisp error: ~a~%\" c) (ext:quit 7)))");
#ifdef CADGUI_USE_LIB
    // Frozen engine: initialize the linked-in monolithic library from C. This
    // runs every module's top-level forms (defpackage/defun/...), exactly as
    // asdf:load-system would, but with no planner and no compile.
    //
    // Create the ASDF/UIOP packages BEFORE init: they are ECL built-ins, NOT in
    // the bundle, yet the bundled cffi/cador objects reference uiop: symbols at
    // init (ecl skill EC9). They must be the SAME ASDF/UIOP the library was
    // COMPILED against -- Quicklisp's 3.3.7.3 (UIOP 3.3.7, which defines
    // UIOP/LAUNCH-PROGRAM &c). The bundled 3.1.8.8 UIOP lacks those sub-packages
    // and init fails "Package UIOP/... has not been created". So load Quicklisp
    // (brings 3.3.7.3); it compiles only ASDF, never clautolisp -- still instant.
    eval_str("(require :asdf)");
    eval_str("(let ((ql (merge-pathnames #P\"quicklisp/setup.lisp\" (user-homedir-pathname))))"
             "  (when (probe-file ql) (load ql)))");
    std::fprintf(stderr, "cadgui-shell: initializing linked-in clautolisp/cadgui ...\n");
    ecl_init_module(NULL, CADGUI_LIB_INIT);
    std::fprintf(stderr, "cadgui-shell: engine ready (frozen library).\n");
#else
    const char *root = std::getenv("CADGUI_CLAUTOLISP_DIR");
    std::string asd = std::string(root ? root : ".") + "/clautolisp.asd";
    // ecl skill EC1: (require :asdf) BEFORE loading Quicklisp. (In this
    // environment Quicklisp upgrades ASDF to 3.3.7.3 regardless, but keeping
    // the order is still correct practice.) NOTE: this ECL cannot reuse a WARM
    // fasl cache -- asdf:load-system against a populated cache overflows the C
    // stack in the planner (ASDF/PLAN::STAMP), under BOTH 3.3.7.3 and the
    // bundled 3.1.8.8 (measured). So run.sh clears the cache each run and this
    // embedded boot pays the full compile. To iterate without that cost, use
    // the dev image (build-dev-image.sh); freezing the engine into the shell
    // (monolithic library) is the standing follow-up -- see NOTES-ecl.md.
    eval_str("(require :asdf)");
    eval_str("(let ((ql (merge-pathnames #P\"quicklisp/setup.lisp\" (user-homedir-pathname))))"
             "  (when (probe-file ql) (load ql)))");
    eval_str("(when (find-package :ql) (funcall (read-from-string \"ql:quickload\")"
             "  (list \"babel\" \"trivial-gray-streams\" \"cffi\") :silent t))");
    { std::string f = "(asdf:load-asd \"" + asd + "\")"; eval_str(f.c_str()); }
    std::fprintf(stderr, "cadgui-shell: loading clautolisp/cadgui ...\n");
    eval_str("(handler-case (asdf:load-system \"clautolisp/cadgui\" :verbose nil)"
             "  (error (e) (format *error-output* \"load failed: ~a~%\" e) (ext:quit 1)))");
#endif
}

// ---- the MULTI-WINDOW (MDI) path -----------------------------------------
// Render a document's own prim list to a PNG (one document window's frame).
static bool render_prims_png(const std::vector<Prim> &prims, const std::string &file,
                             int W, int H) {
    View view;
    double x0 = 1e18, y0 = 1e18, x1 = -1e18, y1 = -1e18;
    for (const Prim &pr : prims)
        for (size_t i = 0; i + 1 < pr.pts.size(); i += 2) {
            x0 = std::min(x0, pr.pts[i]);   x1 = std::max(x1, pr.pts[i]);
            y0 = std::min(y0, pr.pts[i+1]); y1 = std::max(y1, pr.pts[i+1]);
        }
    if (x0 > x1) { x0 = 0; y0 = 0; x1 = 1; y1 = 1; }
    view.fit(x0, y0, x1, y1, W, H, 28);
    QPixmap pm(W, H);
    QPainter g(&pm);
    g.setRenderHint(QPainter::Antialiasing, true);
    g.fillRect(0, 0, W, H, QColor(18, 22, 30));
    g.setPen(QPen(QColor(55, 64, 78), 1.0));
    g.drawLine(view.toDev(-1e5, 0), view.toDev(1e5, 0));
    g.drawLine(view.toDev(0, -1e5), view.toDev(0, 1e5));
    for (const Prim &pr : prims) {
        QPen pen(aci_to_rgb(pr.aci)); pen.setWidthF(1.8); g.setPen(pen);
        QVector<QPointF> poly;
        for (size_t i = 0; i + 1 < pr.pts.size(); i += 2)
            poly.push_back(view.toDev(pr.pts[i], pr.pts[i+1]));
        if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
        if (poly.size() >= 2) g.drawPolyline(poly.constData(), poly.size());
        else if (poly.size() == 1) g.drawPoint(poly.first());
    }
    g.end();
    return pm.save(QString::fromStdString(file), "PNG");
}

// A 2-document workspace, launched and parked, with a Lisp DRIVER THREAD running
// the multiplexing driver. Each document's command reads two points (getpoint)
// and draws a line. Read in CL-USER so the bare symbols resolve there.
static const char *MDI_SETUP =
  "(progn"
  "  (defparameter *mdi-ws* (clautolisp.cadgui:cadgui-make-workspace))"
  "  (defun mdi-line-thunk (h)"
  "    (let ((p1 (clautolisp.autolisp-host:host-getpoint h nil))"
  "          (p2 (clautolisp.autolisp-host:host-getpoint h nil)))"
  "      (clautolisp.autolisp-host:host-entmake h"
  "        (list (cons 0 \"LINE\")"
  "              (cons 10 (list (first p1) (second p1) 0d0))"
  "              (cons 11 (list (first p2) (second p2) 0d0))))))"
  "  (defparameter *mdi-da* (clautolisp.cadgui:cadgui-open-document *mdi-ws* :a (function mdi-line-thunk)))"
  "  (defparameter *mdi-db* (clautolisp.cadgui:cadgui-open-document *mdi-ws* :b (function mdi-line-thunk)))"
  "  (clautolisp.cadgui:cadgui-workspace-launch *mdi-ws* *mdi-da*)"
  "  (format *error-output* \"~&mdi: a launched, step=~a~%\" (clautolisp.cadgui:cadgui-workspace-drive-step *mdi-ws*))"
  "  (clautolisp.cadgui:cadgui-workspace-launch *mdi-ws* *mdi-db*)"
  "  (format *error-output* \"~&mdi: b launched, step=~a~%\" (clautolisp.cadgui:cadgui-workspace-drive-step *mdi-ws*))"
  "  (finish-output *error-output*)"
  "  (mp:process-run-function \"mdi-driver\""
  "    (lambda () (loop (let ((ev (clautolisp.cadgui:cadgui-workspace-drive-step *mdi-ws* 3)))"
  "                       (format *error-output* \"~&mdi-driver: ~a~%\" ev) (finish-output *error-output*)"
  "                       (when (eq ev :timeout) (return)))))))";

// --mdidemo PREFIX: open two document windows on ONE workspace, drive them from
// the Qt main thread with OUT-OF-ORDER input (document B fed before A) through
// cadgui-doc-feed, let the Lisp driver thread + the two document context threads
// run, and render each document's OWN scene to PREFIX-a.png / PREFIX-b.png. The
// GUI realization of the multiplexing driver, headless.
static int run_mdi_demo(const std::string &prefix) {
    qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    eval_str(MDI_SETUP);                          // workspace + 2 docs + driver thread
    int argc0 = 0; QApplication app(argc0, nullptr);

    // Feed the four corner points, document B FIRST (out of order). The driver's
    // per-document queue absorbs any that arrive before a document parks.
    static const char *feeds[] = {
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-db* 0.0 0.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-da* 0.0 0.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-db* 9.0 9.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-da* 5.0 5.0)" };
    static int fed = 0;
    QTimer feeder;
    QObject::connect(&feeder, &QTimer::timeout, &app, [] {
        if (fed < 4) {
            std::fprintf(stderr, "mdi-feed %d\n", fed); std::fflush(stderr);
            eval_str(feeds[fed++]);               // on the Qt main thread
        }
    });
    feeder.start(20);

    QTimer watchdog; int ticks = 0;
    QObject::connect(&watchdog, &QTimer::timeout, &app, [&] {
        bool done = (fed >= 4) &&
            (eval_str("(if (clautolisp.cadgui:cadgui-workspace-all-finished-p *mdi-ws*) t nil)")
             != ECL_NIL);
        if (done || ++ticks > 500) {
            // Both document threads are finished -> pulling their models is race-free.
            std::vector<Prim> a = pull_prims("(clautolisp.cadgui:cadgui-doc-display-list *mdi-da*)");
            std::vector<Prim> b = pull_prims("(clautolisp.cadgui:cadgui-doc-display-list *mdi-db*)");
            bool oka = render_prims_png(a, prefix + "-a.png", 360, 360);
            bool okb = render_prims_png(b, prefix + "-b.png", 360, 360);
            std::fprintf(stderr, "cadgui-shell: --mdidemo done=%d; doc A %zu prims, doc B %zu prims; "
                         "saved %s\n", done ? 1 : 0, a.size(), b.size(), (oka && okb) ? "OK" : "FAIL");
            app.exit((done && oka && okb && a.size() == 1 && b.size() == 1) ? 0 : 1);
        }
    });
    watchdog.start(15);
    return app.exec();
}

int main(int argc, char **argv) {
    std::string mode, file;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if ((a == "--render" || a == "--demo" || a == "--mdidemo") && i + 1 < argc) {
            mode = a; file = argv[++i];
        }
    }
    const bool offscreen = (mode == "--render" || mode == "--demo" || mode == "--mdidemo");
    if (offscreen) qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));

    // 1. ECL + the base scene, all on the main thread BEFORE any runner starts
    //    (no concurrency yet, so main may touch the model here).
    boot_ecl_and_load(argc, argv);

    if (mode == "--mdidemo") {                    // the multi-window path: the
        return run_mdi_demo(file);                // driver + input are pure Lisp
    }

    eval_str("(clautolisp.cadgui:cadgui-start)");
    eval_str("(progn (clautolisp.cadgui:cadgui-add-line 0 0 60 0 :color 1)"
             "       (clautolisp.cadgui:cadgui-add-line 60 0 60 40 :color 2)"
             "       (clautolisp.cadgui:cadgui-add-line 60 40 0 40 :color 3)"
             "       (clautolisp.cadgui:cadgui-add-line 0 40 0 0 :color 4)"
             "       (clautolisp.cadgui:cadgui-add-circle 30 20 15 :color 5))");
    storeSnapshot(buildSnapshot());              // the first frame (still single-threaded)

    QApplication app(argc, argv);

    MainWindow win; win.resize(480, 420);
    g_canvas = win.canvas;
    win.canvas->zoomExtents();                   // fit to the base scene

    if (mode == "--render") {                    // static: no runner thread
        QPixmap pm = win.canvas->grab();
        bool ok = pm.save(QString::fromStdString(file), "PNG");
        std::fprintf(stderr, "cadgui-shell: --render %s = %s\n", file.c_str(), ok ? "OK" : "FAIL");
        cl_shutdown(); return ok ? 0 : 1;
    }

    // 2. From here the APPLICATION LISP owns the model, on its OWN thread.
    install_runner_hooks();
    start_runner();

    if (mode == "--demo") {
        // Headless validation of the MULTI-THREADED live path: post a getpoint-
        // driven command, then feed SYNTHETIC device clicks through the REAL
        // mousePressEvent (device->world->PointQueue) -- one per awaiting
        // episode -- and wait for the runner to publish the resulting snapshot.
        win.canvas->resize(480, 360);
        win.show();                              // give widgets geometry (offscreen)
        // 1) draw a LINE between two getpoint'd clicks; 2) (entsel) a third click
        //    ON that line -> it highlights (the selection overdraw).
        g_cmdQueue.put(Cmd{false,
            "(entmake (list (cons 0 \"LINE\") (cons 62 7)"
            "               (cons 10 (getpoint)) (cons 11 (getpoint))))"});
        g_cmdQueue.put(Cmd{false, "(entsel)"});
        // clicks 0,1 are the line's endpoints; click 2 is its device midpoint,
        // which lies on the drawn segment, so entsel picks it.
        static const QPointF clicks[] = { QPointF(120, 120), QPointF(360, 250),
                                          QPointF(240, 185) };
        static const int nClicks = 3;
        static int clicksSent = 0;
        const size_t expectPrims = 6;            // 4 lines + circle + the new line

        // Send exactly one synthetic click per getpoint REQUEST, in order. We
        // gate on the runner's request COUNT (g_pointRequests), not on a
        // g_awaiting edge: the awaiting=false window between two getpoints is
        // sub-millisecond and a poll would miss it (that deadlocked click #2).
        QTimer feeder;
        QObject::connect(&feeder, &QTimer::timeout, win.canvas, [&win] {
            if (clicksSent >= nClicks) return;
            if (g_pointRequests.load() <= clicksSent) return;    // request not up yet
            QPointF d = clicks[clicksSent];
            CTRACE("feeder: sending click %d at dev %.0f,%.0f", clicksSent, d.x(), d.y());
            clicksSent++;
            QMouseEvent press(QEvent::MouseButtonPress, d, win.canvas->mapToGlobal(d.toPoint()),
                              Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QApplication::sendEvent(win.canvas, &press);         // REAL handler
        });
        feeder.start(5);

        QTimer watchdog; int ticks = 0;
        QObject::connect(&watchdog, &QTimer::timeout, &app, [&] {
            Snapshot s = loadSnapshot();
            // Done when the line is drawn AND the entsel highlight is set (or
            // timeout). The selection overdraw is thus visible in the frame.
            bool ready = (s.prims.size() >= expectPrims && !s.selected.empty());
            if (ready || ++ticks > 600) {        // done or ~6s
                QPixmap pm = win.canvas->grab();
                bool ok = pm.save(QString::fromStdString(file), "PNG");
                std::fprintf(stderr, "cadgui-shell: --demo %s = %s; scene %zu prims, %zu selected\n",
                             file.c_str(), ok ? "OK" : "FAIL", s.prims.size(), s.selected.size());
                g_cmdQueue.put(Cmd{true, ""});   // tell the runner to exit
                app.exit((ok && ready) ? 0 : 1);
            }
        });
        watchdog.start(10);
        return app.exec();                       // process exits; runner reaped
    }

    // LIVE: a real interactive window; the app lisp runs on its own thread.
    win.setWindowTitle("cadgui");
    win.show();
    int rc = app.exec();
    g_cmdQueue.put(Cmd{true, ""});               // ask the runner to finish
    return rc;
}
