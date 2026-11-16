// cadgui-shell -- the embedded-ECL Qt6 shell of the cadgui host.
// cadgui-2-qt6-gui-host.issue slices A + C.
//
// The shell is the host PROCESS: it boots embedded ECL, loads the real
// clautolisp/cadgui system (which pulls cador), and renders the cador DISPLAY
// LIST (clautolisp.cadgui:cadgui-display-list -> cador-scene-display-list) on a
// Qt6 canvas with a fit-to-extents transform. CL owns the model; C++ owns the
// paint; the boundary is the cadgui protocol, crossed only on regen.
//
// This build renders OFFSCREEN (the headless-screenshot path) and also knows how
// to show a live window; here we validate the offscreen render of a real cador
// scene built through the engine.

#include <ecl/ecl.h>

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QColor>
#include <QtCore/QString>
#include <QtCore/QPointF>

#include <vector>
#include <string>
#include <cstdio>
#include <cstdlib>
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
static bool truthy(cl_object o) { return o != ECL_NIL; }

// ---- the cador display-list model, marshalled to C++ ----------------------

struct Prim {
    std::string handle, layer;
    long aci = 256;
    bool closed = false;
    std::vector<double> pts;   // flat x0 y0 x1 y1 ...
};

static std::vector<Prim> pull_display_list() {
    std::vector<Prim> prims;
    cl_object dl = eval_str("(clautolisp.cadgui:cadgui-display-list)");
    for (cl_object p = dl; p != ECL_NIL; p = ecl_cdr(p)) {
        cl_object prim = ecl_car(p);           // (:polyline H L ACI CLOSED PTS)
        Prim out;
        cl_object rest = ecl_cdr(prim);        // skip the :polyline tag
        out.handle = lisp_string(ecl_car(rest)); rest = ecl_cdr(rest);
        out.layer  = lisp_string(ecl_car(rest)); rest = ecl_cdr(rest);
        out.aci    = ecl_to_fixnum(ecl_car(rest)); rest = ecl_cdr(rest);
        out.closed = truthy(ecl_car(rest)); rest = ecl_cdr(rest);
        for (cl_object q = ecl_car(rest); q != ECL_NIL; q = ecl_cdr(q))
            out.pts.push_back(ecl_to_double(ecl_car(q)));
        prims.push_back(out);
    }
    return prims;
}

// extents (xmin ymin xmax ymax) or empty
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
        case 1: return QColor(255, 80, 80);
        case 2: return QColor(255, 255, 90);
        case 3: return QColor(110, 230, 120);
        case 4: return QColor(100, 220, 230);
        case 5: return QColor(120, 160, 255);
        case 6: return QColor(230, 120, 230);
        case 7: return QColor(235, 235, 235);
        default: return QColor(200, 210, 220);   // BYLAYER/BYBLOCK placeholder
    }
}

// ---- the canvas -----------------------------------------------------------

class Canvas : public QWidget {
public:
    std::vector<Prim> prims;
    double ex0=0, ey0=0, ex1=1, ey1=1; bool have_ext=false;
protected:
    void paintEvent(QPaintEvent *) override {
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(18, 22, 30));
        const double W = width(), H = height(), margin = 24.0;
        // fit-to-extents world->device transform (Y flipped)
        double sx = 1, sy = 1, ox = margin, oy = margin, s = 1;
        if (have_ext) {
            double dw = std::max(1e-9, ex1 - ex0), dh = std::max(1e-9, ey1 - ey0);
            s = std::min((W - 2*margin) / dw, (H - 2*margin) / dh);
        }
        auto dev = [&](double wx, double wy) {
            double cx = ox + s * (wx - ex0);
            double cy = H - (oy + s * (wy - ey0));   // flip Y: world up = screen up
            return QPointF(cx, cy);
        };
        // axes through the world origin
        g.setPen(QPen(QColor(60, 70, 85), 1.0));
        if (have_ext) {
            g.drawLine(dev(ex0, 0), dev(ex1, 0));
            g.drawLine(dev(0, ey0), dev(0, ey1));
        }
        for (const Prim &pr : prims) {
            QPen pen(aci_to_rgb(pr.aci)); pen.setWidthF(1.8);
            g.setPen(pen);
            QVector<QPointF> poly;
            for (size_t i = 0; i + 1 < pr.pts.size(); i += 2)
                poly.push_back(dev(pr.pts[i], pr.pts[i+1]));
            if (pr.closed && !poly.isEmpty()) poly.push_back(poly.first());
            if (poly.size() >= 2) g.drawPolyline(poly.constData(), poly.size());
            else if (poly.size() == 1) g.drawPoint(poly.first());
        }
    }
};

int main(int argc, char **argv) {
    // 1. Boot embedded ECL.
    cl_boot(argc, argv);
    eval_str("(progn (ext:set-limit (quote ext:binding-stack) (* 1024 1024 64))"
             "       (ext:set-limit (quote ext:frame-stack) (* 1024 1024))"
             "       (ext:set-limit (quote ext:lisp-stack) (* 1024 1024 64)))");
    eval_str("(setf *debugger-hook* (lambda (c h) (declare (ignore h))"
             "  (format *error-output* \"~&cadgui-shell lisp error: ~a~%\" c)"
             "  (ext:quit 7)))");

    // 2. Load the REAL clautolisp/cadgui (pulls cador) under embedded ECL.
    const char *root = std::getenv("CADGUI_CLAUTOLISP_DIR");
    std::string asd = std::string(root ? root : ".") + "/clautolisp.asd";
    eval_str("(let ((ql (merge-pathnames #P\"quicklisp/setup.lisp\" (user-homedir-pathname))))"
             "  (when (probe-file ql) (load ql)))");
    eval_str("(when (find-package :ql) (funcall (read-from-string \"ql:quickload\")"
             "  (list \"babel\" \"trivial-gray-streams\" \"cffi\") :silent t))");
    eval_str("(require :asdf)");
    {
        std::string f = "(asdf:load-asd \"" + asd + "\")";
        eval_str(f.c_str());
    }
    std::fprintf(stderr, "cadgui-shell: loading clautolisp/cadgui ...\n");
    eval_str("(handler-case (asdf:load-system \"clautolisp/cadgui\" :verbose nil)"
             "  (error (e) (format *error-output* \"load failed: ~a~%\" e) (ext:quit 1)))");

    // 3. Start a session and build a demo scene THROUGH THE REAL ENGINE.
    eval_str("(clautolisp.cadgui:cadgui-start)");
    eval_str("(progn"
             "  (clautolisp.cadgui:cadgui-add-line 0 0 60 0 :color 1)"
             "  (clautolisp.cadgui:cadgui-add-line 60 0 60 40 :color 2)"
             "  (clautolisp.cadgui:cadgui-add-line 60 40 0 40 :color 3)"
             "  (clautolisp.cadgui:cadgui-add-line 0 40 0 0 :color 4)"
             "  (clautolisp.cadgui:cadgui-add-circle 30 20 15 :color 5)"
             "  (clautolisp.cadgui:cadgui-add-line 15 20 45 20 :color 6))");

    // 4. Qt must exist before any QWidget: create the application first.
    qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    QApplication app(argc, argv);

    // 5. Pull the display list + extents across the boundary (regen) and paint.
    Canvas c;
    c.resize(480, 360);
    c.prims = pull_display_list();
    c.have_ext = pull_extents(c.ex0, c.ey0, c.ex1, c.ey1);
    std::fprintf(stderr, "cadgui-shell: scene has %zu primitives; extents %s\n",
                 c.prims.size(), c.have_ext ? "yes" : "no");
    c.update();
    QPixmap pm = c.grab();
    const QString out = (argc > 1) ? QString::fromUtf8(argv[1])
                                   : QStringLiteral("cadgui-scene.png");
    bool ok = pm.save(out, "PNG");
    std::fprintf(stderr, "cadgui-shell: saved %s = %s\n",
                 out.toUtf8().constData(), ok ? "OK" : "FAILED");

    cl_shutdown();
    return (ok && !c.prims.empty()) ? 0 : 1;
}
