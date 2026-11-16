// Phase-2 spike #2: the LIVE interactive window -- the ECL<->Qt event-loop
// marriage the issue flags as the expertise-bound bit.
//
// The problem: Common Lisp owns the command loop; a CAD command blocks in
// getpoint waiting for input, while Qt must keep processing events. The design
// validated here: ONE thread, a NESTED QEventLoop. CL's getpoint calls into
// C++, which enters a nested event loop that runs until an event supplies the
// point (a real mousePressEvent, or -- headless here -- a scripted injection on
// the SAME code path), then returns it to CL. CL updates its model and asks for
// a repaint; the canvas pulls the fresh display list from CL and paints. No
// second thread, so no GC/thread marriage across the ECL boundary.
//
// This exercises: ECL + Qt event loop coexistence, CL->C++ (getpoint) and
// C++->CL (repaint) calls, a CL command loop driven by input, the
// regen->paint cycle, and GC stability (consing a cl_object list per point).

#include <ecl/ecl.h>

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QMouseEvent>
#include <QtGui/QColor>
#include <QtCore/QEventLoop>
#include <QtCore/QTimer>
#include <QtCore/QPointF>

#include <vector>
#include <cstdio>
#include <cstdlib>

// ---- the input bridge: a blocking getPoint() built on a nested event loop ----
class InputBridge : public QObject {   // QObject for timer/context; no Q_OBJECT
public:
    std::vector<QPointF> script;       // headless: scripted "clicks"
    size_t idx = 0;

    QPointF getPoint() {
        QEventLoop loop;
        loopPtr = &loop;
        captured = QPointF();
        // A real window delivers a mousePressEvent here; headless, schedule the
        // next scripted click onto the SAME supplyPoint() path, so the nested
        // loop has something to consume.
        QTimer::singleShot(0, this, [this] {
            // Cycle the scripted clicks so a long (GC-stress) run never runs out.
            supplyPoint(script[(idx++) % script.size()]);
        });
        loop.exec();                   // <-- Qt keeps running while CL "blocks"
        loopPtr = nullptr;
        return captured;
    }
    void supplyPoint(QPointF p) {      // called by mousePressEvent OR the script
        captured = p;
        if (loopPtr) loopPtr->quit();
    }
private:
    QPointF captured;
    QEventLoop *loopPtr = nullptr;
};

struct Seg { double x1, y1, x2, y2; };

static std::vector<Seg> fetch_display_list()
{
    std::vector<Seg> segs;
    cl_object r = cl_safe_eval(c_string_to_object("(get-display-list)"), ECL_NIL, ECL_NIL);
    for (cl_object p = r; p != ECL_NIL; p = ecl_cdr(p)) {
        cl_object s = ecl_car(p);
        segs.push_back({ ecl_to_double(ecl_car(s)),
                         ecl_to_double(ecl_car(ecl_cdr(s))),
                         ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(s)))),
                         ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(ecl_cdr(s))))) });
    }
    return segs;
}

class Canvas : public QWidget {
public:
    InputBridge *bridge = nullptr;
protected:
    void mousePressEvent(QMouseEvent *e) override {   // the real input path
        if (bridge) bridge->supplyPoint(e->position());
    }
    void paintEvent(QPaintEvent *) override {
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(20, 24, 32));
        QPen pen(QColor(120, 220, 160)); pen.setWidthF(2.5); g.setPen(pen);
        for (const Seg &s : fetch_display_list())        // pull CL's model
            g.drawLine(QPointF(s.x1, s.y1), QPointF(s.x2, s.y2));
    }
};

// ---- C functions exposed to Common Lisp (the command's view of the GUI) -----
static InputBridge *g_bridge = nullptr;
static Canvas      *g_canvas = nullptr;

static cl_object spike_get_point()         // (spike-get-point) -> (x y)
{
    QPointF p = g_bridge->getPoint();
    return cl_list(2, ecl_make_double_float(p.x()), ecl_make_double_float(p.y()));
}
static cl_object spike_request_repaint()   // (spike-request-repaint) -> nil
{
    if (g_canvas) { g_canvas->update(); }
    return ECL_NIL;
}

int main(int argc, char **argv)
{
    cl_boot(argc, argv);

    // Register the two C primitives the CL command calls.
    ecl_def_c_function(c_string_to_object("SPIKE-GET-POINT"),
                       (cl_objectfn_fixed)spike_get_point, 0);
    ecl_def_c_function(c_string_to_object("SPIKE-REQUEST-REPAINT"),
                       (cl_objectfn_fixed)spike_request_repaint, 0);

    // CL owns the model and the command loop: draw a polyline through points
    // read interactively, repainting after each segment.
    cl_safe_eval(c_string_to_object(
        "(progn"
        "  (defparameter *segments* '())"
        "  (defun get-display-list () (reverse *segments*))"
        "  (defun run-command (n)"
        "    (let ((p0 (spike-get-point)))"
        "      (dotimes (i n)"
        "        (dotimes (j 200) (make-list 20))"   // GC pressure during the loop
        "        (let ((p1 (spike-get-point)))"
        "          (push (list (first p0) (second p0) (first p1) (second p1)) *segments*)"
        "          (spike-request-repaint)"
        "          (setf p0 p1)))"
        "      (length *segments*))))"), ECL_NIL, ECL_NIL);

    qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    QApplication app(argc, argv);

    InputBridge bridge;
    bridge.script = { {40,40}, {280,70}, {150,280}, {60,170}, {250,250} };
    Canvas canvas;
    canvas.resize(320, 320);
    canvas.bridge = &bridge;
    g_bridge = &bridge;
    g_canvas = &canvas;

    // Run the CL command for N points (default 4; a large N is the GC-stress
    // run). Its (spike-get-point) calls each enter a nested Qt event loop; the
    // scripted clicks drive it, repaints happen between points.
    long n = (argc > 2) ? std::atol(argv[2]) : 4;
    char form[64];
    std::snprintf(form, sizeof form, "(run-command %ld)", n);
    cl_object count = cl_safe_eval(c_string_to_object(form), ECL_NIL, ECL_NIL);
    std::fprintf(stderr, "spike2: CL command built %ld segments from interactive input\n",
                 (long)ecl_to_fixnum(count));

    QPixmap pm = canvas.grab();
    const QString out = (argc > 1) ? QString::fromUtf8(argv[1])
                                   : QStringLiteral("spike2-out.png");
    bool ok = pm.save(out, "PNG");
    std::fprintf(stderr, "spike2: saved %s = %s\n", out.toUtf8().constData(),
                 ok ? "OK" : "FAILED");

    cl_shutdown();
    return (ok && ecl_to_fixnum(count) == n) ? 0 : 1;
}
