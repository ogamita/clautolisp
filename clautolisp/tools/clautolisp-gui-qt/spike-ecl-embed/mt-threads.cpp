// Phase-2 spike #3: the MULTI-THREADED architecture foundation.
// cadgui-2-qt6-gui-host.issue "Threading architecture".
//
// The real cadgui host: Qt's event loop MUST run on the MAIN thread, and the
// cador runtime is multi-threaded (runner + driver threads per lisp image). So
// the APPLICATION LISP runs on a NEW thread, NOT the main thread. This spike
// validates that marriage, minimally (no cador, so it is fast):
//
//   - cl_boot on the MAIN thread; Qt event loop on the MAIN thread.
//   - the application lisp runs on a NEW ECL thread (mp:process-run-function).
//   - that runner calls (mt-await-point): a C function that BLOCKS the runner on
//     a thread-safe queue the MAIN thread fills on a (synthetic) mouse click --
//     the cross-thread getpoint. No nested event loop; the runner just blocks,
//     and Qt keeps running on main.
//   - the runner mutates a CL model under a LOCK; the MAIN thread reads the model
//     under the same lock to paint (cross-thread CL access, serialized).
//   - the runner cons-storms for GC stress while all this interleaves.
//
// Success = the runner (on its own thread) draws N segments between the points
// the main thread supplied, the window repaints cross-thread, and nothing
// crashes or deadlocks -- i.e. ECL threads + Qt-on-main + a shared CL model are
// stable together.

#include <ecl/ecl.h>

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QPainter>
#include <QtGui/QPixmap>
#include <QtGui/QColor>
#include <QtCore/QPointF>
#include <QtCore/QTimer>

#include <vector>
#include <deque>
#include <mutex>
#include <condition_variable>
#include <cstdio>
#include <cstring>
#include <cstdlib>

// ---- a thread-safe point queue: runner blocks in take(), main does put() -----
class PointQueue {
public:
    void put(QPointF p) {
        { std::lock_guard<std::mutex> g(m_); q_.push_back(p); }
        cv_.notify_one();
    }
    QPointF take() {                       // blocks the calling (runner) thread
        std::unique_lock<std::mutex> l(m_);
        cv_.wait(l, [this] { return !q_.empty(); });
        QPointF p = q_.front(); q_.pop_front();
        return p;
    }
private:
    std::deque<QPointF> q_;
    std::mutex m_;
    std::condition_variable cv_;
};

static PointQueue g_queue;
static QWidget   *g_canvas = nullptr;
static volatile bool g_runner_done = false;

// ---- C functions the LISP runner thread calls -----------------------------
static cl_object mt_await_point() {        // the cross-thread getpoint
    QPointF p = g_queue.take();            // BLOCKS this (runner) thread
    return cl_list(2, ecl_make_double_float(p.x()), ecl_make_double_float(p.y()));
}
static cl_object mt_request_repaint() {    // ask the MAIN thread to repaint
    if (g_canvas)
        QMetaObject::invokeMethod(g_canvas, [] { g_canvas->update(); },
                                  Qt::QueuedConnection);
    return ECL_NIL;
}
static cl_object mt_signal_done() {        // runner finished
    g_runner_done = true;
    return ECL_NIL;
}

// ---- the canvas: paints the CL model (read cross-thread, under the lock) -----
struct Seg { double x1, y1, x2, y2; };
static std::vector<Seg> pull_model() {     // called on the MAIN thread
    std::vector<Seg> segs;
    cl_object dl = cl_safe_eval(c_string_to_object("(mt-display-list)"), ECL_NIL, ECL_NIL);
    for (cl_object p = dl; p != ECL_NIL; p = ecl_cdr(p)) {
        cl_object s = ecl_car(p);
        segs.push_back({ ecl_to_double(ecl_car(s)),
                         ecl_to_double(ecl_car(ecl_cdr(s))),
                         ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(s)))),
                         ecl_to_double(ecl_car(ecl_cdr(ecl_cdr(ecl_cdr(s))))) });
    }
    return segs;
}
class Canvas : public QWidget {
protected:
    void paintEvent(QPaintEvent *) override {
        QPainter g(this);
        g.setRenderHint(QPainter::Antialiasing, true);
        g.fillRect(rect(), QColor(18, 22, 30));
        QPen pen(QColor(120, 220, 160)); pen.setWidthF(2.0); g.setPen(pen);
        for (const Seg &s : pull_model())
            g.drawLine(QPointF(s.x1, s.y1), QPointF(s.x2, s.y2));
    }
};

int main(int argc, char **argv) {
    // 1. ECL on the main thread.
    cl_boot(argc, argv);
    cl_safe_eval(c_string_to_object(
        "(progn (ext:set-limit (quote ext:binding-stack) (* 1024 1024 64))"
        "       (ext:set-limit (quote ext:lisp-stack) (* 1024 1024 64)))"), ECL_NIL, ECL_NIL);

    // 2. The CL program: a lock-guarded model + a runner loop that reads points,
    //    adds a segment and asks for a repaint, cons-storming for GC stress.
    cl_safe_eval(c_string_to_object(
        "(progn"
        "  (defvar *mt-lock* (mp:make-lock :name \"model\"))"
        "  (defvar *mt-model* '())"
        "  (defun mt-add-segment (x1 y1 x2 y2)"
        "    (mp:with-lock (*mt-lock*) (push (list x1 y1 x2 y2) *mt-model*)))"
        "  (defun mt-display-list () (mp:with-lock (*mt-lock*) (copy-list *mt-model*)))"
        "  (defun mt-app-loop (n)"
        "    (let ((p0 (mt-await-point)))"
        "      (dotimes (i n)"
        "        (dotimes (j 200) (make-list 20))"          // GC stress
        "        (let ((p1 (mt-await-point)))"
        "          (mt-add-segment (first p0) (second p0) (first p1) (second p1))"
        "          (mt-request-repaint)"
        "          (setf p0 p1))))"
        "    (mt-signal-done)))"), ECL_NIL, ECL_NIL);

    // 3. Register the C hooks the runner calls.
    ecl_def_c_function(c_string_to_object("MT-AWAIT-POINT"),
                       (cl_objectfn_fixed)mt_await_point, 0);
    ecl_def_c_function(c_string_to_object("MT-REQUEST-REPAINT"),
                       (cl_objectfn_fixed)mt_request_repaint, 0);
    ecl_def_c_function(c_string_to_object("MT-SIGNAL-DONE"),
                       (cl_objectfn_fixed)mt_signal_done, 0);

    // 4. Qt on the MAIN thread.
    qputenv("QT_QPA_PLATFORM", QByteArrayLiteral("offscreen"));
    QApplication app(argc, argv);
    Canvas c; c.resize(320, 320);
    g_canvas = &c;

    // 5. Start the APPLICATION LISP on a NEW ECL thread (runner != main).
    cl_safe_eval(c_string_to_object(
        "(mp:process-run-function \"app-lisp\" (lambda () (mt-app-loop 5)))"),
        ECL_NIL, ECL_NIL);

    // 6. The main thread feeds the runner 6 points over time (stand-in for mouse
    //    clicks), then, once the runner is done, grabs a frame and quits.
    static const QPointF pts[] = { {40,40},{280,60},{150,280},{60,170},{250,250},{160,40} };
    static int fed = 0;
    QTimer feeder;
    QObject::connect(&feeder, &QTimer::timeout, [&] {
        if (fed < 6) g_queue.put(pts[fed++]);
    });
    feeder.start(15);
    QTimer watchdog;
    int ticks = 0;
    QObject::connect(&watchdog, &QTimer::timeout, [&] {
        if (g_runner_done || ++ticks > 400) {         // done, or ~6s safety
            c.update();
            app.processEvents();
            QPixmap pm = c.grab();
            const char *out = (argc > 1) ? argv[1] : "mt-out.png";
            bool ok = pm.save(QString::fromUtf8(out), "PNG");
            std::fprintf(stderr, "mt-spike: runner_done=%d segments=%zu saved %s=%s\n",
                         g_runner_done ? 1 : 0, pull_model().size(), out, ok ? "OK" : "FAIL");
            app.exit((ok && g_runner_done) ? 0 : 1);
        }
    });
    watchdog.start(15);

    int rc = app.exec();
    cl_shutdown();
    return rc;
}
