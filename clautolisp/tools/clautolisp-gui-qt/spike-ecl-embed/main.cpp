// Phase-2 spike: embed ECL in a Qt6 Widgets C++ shell, let COMMON LISP compute
// the geometry (a "display list" of line segments), have C++ paint it with
// QPainter, and render OFFSCREEN to a PNG (the headless-screenshot path).
//
// This validates the committed phase-2 architecture end to end:
//   CL owns the model/regen -> hands C++ a display list -> C++ paints it,
//   crossing the ECL boundary only on regen (here: once), never per pixel;
//   and the whole thing runs with no windowing environment (offscreen QPA).
//
// Build: see build.sh (pkg-config Qt6Widgets + ecl-config).

#include <ecl/ecl.h>

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QColor>
#include <QtCore/QString>

#include <vector>
#include <cstdio>

struct Seg { double x1, y1, x2, y2; };

// Cross the ECL boundary ONCE: ask Lisp for the display list and marshal it to
// a plain C++ vector. In the real canvas this happens on regen, not per frame.
static std::vector<Seg> fetch_display_list_from_lisp()
{
    std::vector<Seg> segs;
    cl_object result =
        cl_safe_eval(c_string_to_object("(model->display-list)"),
                     ECL_NIL, ECL_NIL);
    for (cl_object p = result; p != ECL_NIL; p = ecl_cdr(p)) {
        cl_object s = ecl_car(p);
        Seg seg;
        seg.x1 = ecl_to_double(ecl_car(s));
        seg.y1 = ecl_to_double(ecl_car(ecl_cdr(s)));
        seg.x2 = ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(s))));
        seg.y2 = ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(ecl_cdr(s)))));
        segs.push_back(seg);
    }
    return segs;
}

class Canvas : public QWidget {   // no Q_OBJECT needed: we only override paint
public:
    std::vector<Seg> segs;
protected:
    void paintEvent(QPaintEvent *) override {
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(20, 24, 32));
        QPen pen(QColor(120, 200, 255));
        pen.setWidthF(2.0);
        g.setPen(pen);
        for (const Seg &s : segs)
            g.drawLine(QPointF(s.x1, s.y1), QPointF(s.x2, s.y2));
    }
};

int main(int argc, char **argv)
{
    // 1. Boot the embedded Common Lisp.
    cl_boot(argc, argv);

    // 2. CL owns the model: define a package + a function that COMPUTES the
    //    geometry (a 5-pointed star), returned as a list of (x1 y1 x2 y2).
    cl_safe_eval(c_string_to_object(
        "(progn"
        "  (defun model->display-list ()"
        "    (let ((cx 160d0) (cy 160d0) (ro 130d0) (ri 52d0) (n 5) (pts '()))"
        "      (dotimes (i (* 2 n))"
        "        (let* ((a (* pi (/ i (float n 1d0))))"
        "               (r (if (evenp i) ro ri))"
        "               (x (+ cx (* r (sin a))))"
        "               (y (- cy (* r (cos a)))))"
        "          (push (list x y) pts)))"
        "      (setf pts (nreverse pts))"
        "      (let ((segs '()) (first-pt (first pts)))"
        "        (loop for cell on pts"
        "              for p = (car cell)"
        "              for q = (if (cdr cell) (second cell) first-pt)"
        "              do (push (list (first p) (second p) (first q) (second q)) segs))"
        "        (nreverse segs)))))"),
        ECL_NIL, ECL_NIL);

    // 3. Offscreen QPA so there is no windowing environment to require.
    qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    QApplication app(argc, argv);

    Canvas c;
    c.resize(320, 320);
    c.segs = fetch_display_list_from_lisp();   // regen: cross the boundary once
    std::fprintf(stderr, "spike: Lisp produced %zu segments\n", c.segs.size());

    // 4. Paint offscreen and save a PNG (the headless-screenshot path).
    QPixmap pm = c.grab();
    const QString out = (argc > 1) ? QString::fromUtf8(argv[1])
                                   : QStringLiteral("spike-out.png");
    bool ok = pm.save(out, "PNG");
    std::fprintf(stderr, "spike: saved %s = %s\n",
                 out.toUtf8().constData(), ok ? "OK" : "FAILED");

    cl_shutdown();
    return (ok && !c.segs.empty()) ? 0 : 1;
}
