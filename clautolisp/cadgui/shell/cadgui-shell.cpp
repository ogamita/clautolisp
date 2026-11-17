// cadgui-shell -- the embedded-ECL Qt6 shell of the cadgui host.
// cadgui-2-qt6-gui-host.issue slices A/C/D/E + the LIVE interactive window.
//
// The shell is the host PROCESS: it boots embedded ECL, loads clautolisp/cadgui
// (which pulls cador), and is an interactive CAD canvas on the cador model.
//   CL owns the model; C++ owns the window + per-frame paint + pan/zoom + input.
//   The boundary (the cadgui protocol) crosses only on regen and on input.
//
// Modes:
//   (default)        a LIVE window: real mouse drives getpoint/entsel, wheel
//                    zooms, middle-drag pans, 'e' zoom-extents, a command line
//                    at the bottom evals AutoLISP; QApplication::exec().
//   --render FILE    render the current scene offscreen to FILE and exit (CI).
//   --demo FILE      offscreen, drive SYNTHETIC mouse events through the real
//                    handlers (device->world->getpoint) + a command line eval,
//                    then save FILE (headless validation of the live path).

#include <ecl/ecl.h>

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
#include <QtCore/QEventLoop>
#include <QtCore/QTimer>

#include <vector>
#include <string>
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

// ---- the cador display-list model, marshalled to C++ ----------------------
struct Prim {
    std::string handle, layer;
    long aci = 256; bool closed = false;
    std::vector<double> pts;
};
static std::vector<Prim> pull_display_list() {
    std::vector<Prim> prims;
    cl_object dl = eval_str("(clautolisp.cadgui:cadgui-display-list)");
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

// ---- the input bridge: a blocked getpoint reads a canvas click -------------
class InputBridge : public QObject {
public:
    bool awaiting = false;
    QPointF world;                               // the supplied WORLD point
    std::vector<QPointF> demoDeviceClicks; size_t demoIdx = 0;  // --demo
    class Canvas *canvas = nullptr;
    QPointF getPoint();                           // runs the nested event loop
    void supplyWorld(QPointF w) { world = w; if (loop) loop->quit(); }
private:
    QEventLoop *loop = nullptr;
    void driveDemoClick();                        // defined after Canvas
};
static InputBridge *g_bridge = nullptr;

static cl_object cadgui_shell_await_input() {     // *cadgui-input-hook* -> "x,y"
    QPointF w = g_bridge->getPoint();
    char buf[80];
    std::snprintf(buf, sizeof buf, "%.10g,%.10g", w.x(), w.y());
    return ecl_make_simple_base_string(buf, (cl_index)std::strlen(buf));
}

// ---- the canvas ----------------------------------------------------------
class Canvas : public QWidget {
public:
    std::vector<Prim> prims;
    View view;
    bool haveFit = false;
    QPointF cursorDev;
    InputBridge *bridge = nullptr;

    void refresh() { prims = pull_display_list(); if (!haveFit) zoomExtents(); update(); }
    void zoomExtents() {
        double x0,y0,x1,y1;
        if (pull_extents(x0,y0,x1,y1)) { view.fit(x0,y0,x1,y1, width(), height(), 28); haveFit = true; }
        update();
    }
protected:
    void mousePressEvent(QMouseEvent *e) override {
        if (e->button() == Qt::LeftButton && bridge && bridge->awaiting)
            bridge->supplyWorld(view.toWorld(e->position().x(), e->position().y()));
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
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(18, 22, 30));
        g.setPen(QPen(QColor(55, 64, 78), 1.0));                 // axes
        g.drawLine(view.toDev(-1e5,0), view.toDev(1e5,0));
        g.drawLine(view.toDev(0,-1e5), view.toDev(0,1e5));
        for (const Prim &pr : prims) {
            QPen pen(aci_to_rgb(pr.aci)); pen.setWidthF(1.8); g.setPen(pen);
            QVector<QPointF> poly;
            for (size_t i = 0; i + 1 < pr.pts.size(); i += 2)
                poly.push_back(view.toDev(pr.pts[i], pr.pts[i+1]));
            if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
            if (poly.size() >= 2) g.drawPolyline(poly.constData(), poly.size());
            else if (poly.size() == 1) g.drawPoint(poly.first());
        }
        if (bridge && bridge->awaiting) {                        // crosshair while picking
            g.setPen(QPen(QColor(120, 220, 160), 1.0));
            g.drawLine(QPointF(0, cursorDev.y()), QPointF(width(), cursorDev.y()));
            g.drawLine(QPointF(cursorDev.x(), 0), QPointF(cursorDev.x(), height()));
        }
    }
private:
    bool panning = false; QPointF panFrom;
};

QPointF InputBridge::getPoint() {
    awaiting = true; if (canvas) canvas->update();
    QEventLoop lp; loop = &lp;
    if (!demoDeviceClicks.empty()) driveDemoClick();             // --demo: synth click
    lp.exec();
    loop = nullptr; awaiting = false; if (canvas) canvas->update();
    return world;
}
void InputBridge::driveDemoClick() {
    QTimer::singleShot(0, this, [this] {
        if (demoIdx < demoDeviceClicks.size() && canvas) {
            QPointF d = demoDeviceClicks[demoIdx++];
            // a REAL left-click through the real handler (device -> world -> supply)
            QMouseEvent press(QEvent::MouseButtonPress, d, canvas->mapToGlobal(d.toPoint()),
                              Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QApplication::sendEvent(canvas, &press);
        } else if (loop) loop->quit();
    });
}

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
            std::string form = "(clautolisp.cadgui:cadgui-eval-command " +
                               std::string("\"") + s + "\")";    // (naive: assumes no embedded quotes)
            eval_str(form.c_str());
            canvas->refresh();
        });
    }
};

// ---- main ----------------------------------------------------------------
static void boot_ecl_and_load(int argc, char **argv) {
    cl_boot(argc, argv);
    eval_str("(progn (ext:set-limit (quote ext:binding-stack) (* 1024 1024 64))"
             "       (ext:set-limit (quote ext:frame-stack) (* 1024 1024))"
             "       (ext:set-limit (quote ext:lisp-stack) (* 1024 1024 64)))");
    eval_str("(setf *debugger-hook* (lambda (c h) (declare (ignore h))"
             "  (format *error-output* \"~&cadgui-shell lisp error: ~a~%\" c) (ext:quit 7)))");
    const char *root = std::getenv("CADGUI_CLAUTOLISP_DIR");
    std::string asd = std::string(root ? root : ".") + "/clautolisp.asd";
    eval_str("(let ((ql (merge-pathnames #P\"quicklisp/setup.lisp\" (user-homedir-pathname))))"
             "  (when (probe-file ql) (load ql)))");
    eval_str("(when (find-package :ql) (funcall (read-from-string \"ql:quickload\")"
             "  (list \"babel\" \"trivial-gray-streams\" \"cffi\") :silent t))");
    eval_str("(require :asdf)");
    { std::string f = "(asdf:load-asd \"" + asd + "\")"; eval_str(f.c_str()); }
    std::fprintf(stderr, "cadgui-shell: loading clautolisp/cadgui ...\n");
    eval_str("(handler-case (asdf:load-system \"clautolisp/cadgui\" :verbose nil)"
             "  (error (e) (format *error-output* \"load failed: ~a~%\" e) (ext:quit 1)))");
}

int main(int argc, char **argv) {
    std::string mode, file;
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if ((a == "--render" || a == "--demo") && i + 1 < argc) { mode = a; file = argv[++i]; }
    }
    const bool offscreen = (mode == "--render" || mode == "--demo");
    if (offscreen) qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));

    boot_ecl_and_load(argc, argv);
    eval_str("(clautolisp.cadgui:cadgui-start)");
    // a small base scene so there is something to see / zoom to
    eval_str("(progn (clautolisp.cadgui:cadgui-add-line 0 0 60 0 :color 1)"
             "       (clautolisp.cadgui:cadgui-add-line 60 0 60 40 :color 2)"
             "       (clautolisp.cadgui:cadgui-add-line 60 40 0 40 :color 3)"
             "       (clautolisp.cadgui:cadgui-add-line 0 40 0 0 :color 4)"
             "       (clautolisp.cadgui:cadgui-add-circle 30 20 15 :color 5))");

    QApplication app(argc, argv);

    InputBridge bridge; g_bridge = &bridge;
    ecl_def_c_function(c_string_to_object("CADGUI-SHELL-AWAIT-INPUT"),
                       (cl_objectfn_fixed)cadgui_shell_await_input, 0);
    eval_str("(setf clautolisp.cadgui:*cadgui-input-hook*"
             "      (symbol-function 'cadgui-shell-await-input))");

    MainWindow win; win.resize(480, 420);
    bridge.canvas = win.canvas; win.canvas->bridge = &bridge;
    win.canvas->refresh();                       // pull + zoom-extents

    if (mode == "--render") {
        QPixmap pm = win.canvas->grab();
        bool ok = pm.save(QString::fromStdString(file), "PNG");
        std::fprintf(stderr, "cadgui-shell: --render %s = %s\n", file.c_str(), ok ? "OK" : "FAIL");
        cl_shutdown(); return ok ? 0 : 1;
    }
    if (mode == "--demo") {
        // Drive a getpoint-driven command through the REAL handlers: click two
        // canvas points; the command draws a line between the WORLD points they
        // map to under the current view (device->world is thus exercised live).
        bridge.demoDeviceClicks = { QPointF(120, 120), QPointF(360, 250) };
        win.canvas->resize(480, 360);
        win.show();                              // give widgets geometry (offscreen)
        eval_str("(clautolisp.cadgui:cadgui-eval-command"
                 "  \"(entmake (list (cons 0 \\\"LINE\\\") (cons 62 7)"
                 "                   (cons 10 (getpoint)) (cons 11 (getpoint))))\")");
        win.canvas->refresh();
        QPixmap pm = win.canvas->grab();
        bool ok = pm.save(QString::fromStdString(file), "PNG");
        std::fprintf(stderr, "cadgui-shell: --demo %s = %s; scene has %zu prims\n",
                     file.c_str(), ok ? "OK" : "FAIL", win.canvas->prims.size());
        cl_shutdown(); return ok ? 0 : 1;
    }

    // LIVE: a real interactive window.
    win.setWindowTitle("cadgui");
    win.show();
    int rc = app.exec();
    cl_shutdown();
    return rc;
}
