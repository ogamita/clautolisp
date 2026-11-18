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
// the multiplexing driver. Each document runs cadgui-document-command-loop: it
// reads a TYPED AutoLISP command from its input and evaluates it IN ITS OWN
// scheduler context -- so the command's getpoints park and resume from that
// document's canvas, exactly as the live window drives it. Read in CL-USER so
// the bare symbols resolve there.
static const char *MDI_SETUP =
  "(progn"
  "  (defparameter *mdi-ws* (clautolisp.cadgui:cadgui-make-workspace))"
  "  (defparameter *mdi-da* (clautolisp.cadgui:cadgui-open-document *mdi-ws* :a"
  "                           (function clautolisp.cadgui:cadgui-document-command-loop)))"
  "  (defparameter *mdi-db* (clautolisp.cadgui:cadgui-open-document *mdi-ws* :b"
  "                           (function clautolisp.cadgui:cadgui-document-command-loop)))"
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

    // Each window TYPES a LINE command, then clicks two points; document B is fed
    // FIRST (out of order). The driver's per-document queue absorbs input that
    // arrives before a document parks, and :eof ends each document's loop.
    static const char *feeds[] = {
        "(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* *mdi-db* \"(command \\\"LINE\\\" (getpoint) (getpoint))\")",
        "(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* *mdi-da* \"(command \\\"LINE\\\" (getpoint) (getpoint))\")",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-db* 0.0 0.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-db* 9.0 9.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-da* 0.0 0.0)",
        "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* *mdi-da* 5.0 5.0)",
        "(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* *mdi-db* :eof)",
        "(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* *mdi-da* :eof)" };
    static const int nfeeds = 8;
    static int fed = 0;
    QTimer feeder;
    QObject::connect(&feeder, &QTimer::timeout, &app, [] {
        if (fed < nfeeds) {
            std::fprintf(stderr, "mdi-feed %d\n", fed); std::fflush(stderr);
            eval_str(feeds[fed++]);               // on the Qt main thread
        }
    });
    feeder.start(20);

    QTimer watchdog; int ticks = 0;
    QObject::connect(&watchdog, &QTimer::timeout, &app, [&] {
        bool done = (fed >= nfeeds) &&
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

// ======================= the LIVE multi-window (MDI) app ===================
// Real per-document windows: each a canvas + a command line, painting from its
// OWN mutex-guarded snapshot that the document's thread publishes after each
// command (so the paint is race-free). A Lisp driver thread multiplexes; the Qt
// main thread owns the windows and routes a command line / a canvas click to
// that document via cadgui-doc-feed. Headless (--mdi PREFIX) it drives synthetic
// commands + points and grabs each window; on a display (no PREFIX) it is live.

struct DocView {
    std::mutex mutex;
    std::vector<Prim> prims;
    QWidget *canvas = nullptr;               // the MdiCanvas (a QWidget) to repaint
    int idx = 0;
};
static std::vector<DocView*> g_mdidocs;

// Called FROM the document's own thread (cadgui-document-command-loop's
// after-command hook) -> pulls this document's model on the thread that owns it
// (race-free) into the snapshot, then asks the Qt main thread to repaint.
static cl_object cadgui_mdi_publish(cl_object idx_obj) {
    int idx = (int)ecl_to_fixnum(idx_obj);
    if (idx < 0 || idx >= (int)g_mdidocs.size()) return ECL_NIL;
    DocView *dv = g_mdidocs[idx];
    char form[160];
    std::snprintf(form, sizeof form,
                  "(clautolisp.cadgui:cadgui-doc-display-list (aref *mdi-docs* %d))", idx);
    std::vector<Prim> prims = pull_prims(form);
    { std::lock_guard<std::mutex> g(dv->mutex); dv->prims = std::move(prims); }
    if (dv->canvas)
        QMetaObject::invokeMethod(dv->canvas, [dv] { if (dv->canvas) dv->canvas->update(); },
                                  Qt::QueuedConnection);
    return ECL_NIL;
}

class MdiCanvas : public QWidget {
public:
    int idx = 0;
    View view;
    bool haveFit = false;
    QPointF cursorDev;
    MdiCanvas() { setMinimumSize(360, 300); setMouseTracking(true); }
    void feedPoint(double wx, double wy) {
        char form[220];
        std::snprintf(form, sizeof form,
            "(clautolisp.cadgui:cadgui-doc-feed-point *mdi-ws* (aref *mdi-docs* %d) %.10g %.10g)",
            idx, wx, wy);
        eval_str(form);
    }
protected:
    void mousePressEvent(QMouseEvent *e) override {
        if (e->button() == Qt::LeftButton) {
            QPointF w = view.toWorld(e->position().x(), e->position().y());
            feedPoint(w.x(), w.y());             // a click answers a getpoint
        } else if (e->button() == Qt::MiddleButton) { panning = true; panFrom = e->position(); }
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
        view.zoomAt(e->position(), (e->angleDelta().y() > 0) ? 1.15 : 1.0/1.15); update();
    }
    void paintEvent(QPaintEvent *) override {
        std::vector<Prim> prims;
        { std::lock_guard<std::mutex> g(g_mdidocs[idx]->mutex); prims = g_mdidocs[idx]->prims; }
        if (!haveFit && !prims.empty()) {        // first content -> fit
            double x0=1e18,y0=1e18,x1=-1e18,y1=-1e18;
            for (const Prim &pr : prims) for (size_t i=0;i+1<pr.pts.size();i+=2) {
                x0=std::min(x0,pr.pts[i]); x1=std::max(x1,pr.pts[i]);
                y0=std::min(y0,pr.pts[i+1]); y1=std::max(y1,pr.pts[i+1]); }
            if (x0<=x1) { view.fit(x0,y0,x1,y1,width(),height(),28); haveFit=true; }
        }
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(18, 22, 30));
        g.setPen(QPen(QColor(55, 64, 78), 1.0));
        g.drawLine(view.toDev(-1e5,0), view.toDev(1e5,0));
        g.drawLine(view.toDev(0,-1e5), view.toDev(0,1e5));
        for (const Prim &pr : prims) {
            QPen pen(aci_to_rgb(pr.aci)); pen.setWidthF(1.8); g.setPen(pen);
            QVector<QPointF> poly;
            for (size_t i=0;i+1<pr.pts.size();i+=2) poly.push_back(view.toDev(pr.pts[i],pr.pts[i+1]));
            if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
            if (poly.size()>=2) g.drawPolyline(poly.constData(), poly.size());
            else if (poly.size()==1) g.drawPoint(poly.first());
        }
    }
private:
    bool panning = false; QPointF panFrom;
};

class DocWindow : public QWidget {
public:
    MdiCanvas *canvas; QLineEdit *cmd; int idx;
    DocWindow(int i) : idx(i) {
        auto *lay = new QVBoxLayout(this); lay->setContentsMargins(0,0,0,0); lay->setSpacing(0);
        canvas = new MdiCanvas; canvas->idx = i;
        cmd = new QLineEdit; cmd->setPlaceholderText("command, e.g. (command \"LINE\" (getpoint) (getpoint))");
        lay->addWidget(canvas, 1); lay->addWidget(cmd, 0);
        QObject::connect(cmd, &QLineEdit::returnPressed, this, [this] {
            std::string s = cmd->text().toStdString(); cmd->clear();
            if (s.empty()) return;
            // feed the TYPED command to this document (escape embedded quotes)
            std::string esc; for (char c : s) { if (c=='"'||c=='\\') esc.push_back('\\'); esc.push_back(c); }
            std::string form = "(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* (aref *mdi-docs* "
                               + std::to_string(idx) + ") \"" + esc + "\")";
            eval_str(form.c_str());
        });
    }
};

// Set up the workspace + N documents (each publishing after every command) and
// the Lisp driver thread. Registered C publish + the per-doc after-command hook.
static const char *MDI_LIVE_SETUP =
  "(progn"
  "  (defparameter *mdi-ws* (clautolisp.cadgui:cadgui-make-workspace))"
  "  (defparameter *mdi-docs*"
  "    (vector"
  "      (clautolisp.cadgui:cadgui-open-document *mdi-ws* :a"
  "        (lambda (h) (clautolisp.cadgui:cadgui-document-command-loop h (lambda () (cadgui-mdi-publish 0)))))"
  "      (clautolisp.cadgui:cadgui-open-document *mdi-ws* :b"
  "        (lambda (h) (clautolisp.cadgui:cadgui-document-command-loop h (lambda () (cadgui-mdi-publish 1)))))))"
  "  (dotimes (i (length *mdi-docs*))"
  "    (clautolisp.cadgui:cadgui-workspace-launch *mdi-ws* (aref *mdi-docs* i))"
  "    (format *error-output* \"~&mdi-setup: doc ~a step=~a~%\" i (clautolisp.cadgui:cadgui-workspace-drive-step *mdi-ws*)))"
  "  (finish-output *error-output*)"
  "  (mp:process-run-function \"mdi-driver\""
  "    (lambda () (loop (let ((ev (clautolisp.cadgui:cadgui-workspace-drive-step *mdi-ws* 3)))"
  "                       (format *error-output* \"~&mdi-live-driver: ~a~%\" ev) (finish-output *error-output*)"
  "                       (when (eq ev :timeout) (return)))))))";

static int run_mdi_live(const std::string &grabPrefix) {
    const bool headless = !grabPrefix.empty();
    if (headless) qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    ecl_def_c_function(c_string_to_object("CADGUI-MDI-PUBLISH"),
                       (cl_objectfn_fixed)cadgui_mdi_publish, 1);
    eval_str(MDI_LIVE_SETUP);

    int argc0 = 0; QApplication app(argc0, nullptr);
    const int N = 2;
    std::vector<DocWindow *> wins;
    for (int i = 0; i < N; i++) {
        DocView *dv = new DocView; dv->idx = i;
        DocWindow *w = new DocWindow(i);
        dv->canvas = w->canvas;
        g_mdidocs.push_back(dv);
        w->resize(380, 340); w->setWindowTitle(QString("cadgui doc %1").arg(i == 0 ? "A" : "B"));
        w->move(40 + i*420, 60); w->show();
        wins.push_back(w);
    }
    if (!headless) return app.exec();            // live: real windows on a display

    // Headless: TYPE a LINE command in each window's command line (exercising the
    // real widget -> feed), then feed its two points; grab each window.
    static int step = 0;
    QTimer driver;
    QObject::connect(&driver, &QTimer::timeout, &app, [&] {
        switch (step++) {
          case 1: wins[0]->cmd->setText("(command \"LINE\" (getpoint) (getpoint))");
                  emit wins[0]->cmd->returnPressed(); break;
          case 2: wins[1]->cmd->setText("(command \"LINE\" (getpoint) (getpoint))");
                  emit wins[1]->cmd->returnPressed(); break;
          case 3: wins[0]->canvas->feedPoint(0, 0);  break;
          case 4: wins[1]->canvas->feedPoint(0, 0);  break;
          case 5: wins[0]->canvas->feedPoint(5, 5);  break;
          case 6: wins[1]->canvas->feedPoint(9, 9);  break;
          case 7: eval_str("(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* (aref *mdi-docs* 0) :eof)"); break;
          case 8: eval_str("(clautolisp.cadgui:cadgui-doc-feed *mdi-ws* (aref *mdi-docs* 1) :eof)"); break;
          default: break;
        }
    });
    driver.start(25);
    QTimer watchdog; int ticks = 0;
    QObject::connect(&watchdog, &QTimer::timeout, &app, [&] {
        bool done = (step > 8) &&
            (eval_str("(if (clautolisp.cadgui:cadgui-workspace-all-finished-p *mdi-ws*) t nil)") != ECL_NIL);
        if (done || ++ticks > 500) {
            app.processEvents();
            bool ok = true; size_t total = 0;
            for (int i = 0; i < N; i++) {
                { std::lock_guard<std::mutex> g(g_mdidocs[i]->mutex); total += g_mdidocs[i]->prims.size(); }
                QPixmap pm = wins[i]->canvas->grab();
                ok = ok && pm.save(QString::fromStdString(grabPrefix + (i==0?"-a.png":"-b.png")), "PNG");
            }
            std::fprintf(stderr, "cadgui-shell: --mdi done=%d; %zu prims across windows; saved %s\n",
                         done ? 1 : 0, total, ok ? "OK" : "FAIL");
            app.exit((done && ok && total == 2) ? 0 : 1);
        }
    });
    watchdog.start(20);
    return app.exec();
}

int main(int argc, char **argv) {
    std::string mode, file;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if ((a == "--render" || a == "--demo" || a == "--mdidemo") && i + 1 < argc) {
            mode = a; file = argv[++i];
        } else if (a == "--mdi") {               // live multi-window; PREFIX => headless grab
            mode = a; if (i + 1 < argc) file = argv[++i];
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
    if (mode == "--mdi") {                         // the LIVE multi-window app
        return run_mdi_live(file);                 // (file empty => live on a display)
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
