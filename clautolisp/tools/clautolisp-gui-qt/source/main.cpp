// clautolisp-gui-qt — Qt6 subprocess driver for the clautolisp DCL
// renderer. Speaks the sexp wire protocol over stdio.
//
// stdin is read on a dedicated worker thread because Qt's
// QSocketNotifier is unreliable on macOS for non-socket file
// descriptors (pipes). The worker reads one complete s-expression
// per message (counting parens / handling escaped strings) and
// emits the raw bytes via a queued Qt signal. The main thread
// parses and dispatches.

#include "dialog_window.hpp"
#include "sexp.hpp"
#include "wire.hpp"

#include <QApplication>
#include <QByteArray>
#include <QHash>
#include <QPointer>
#include <QThread>

#include <iostream>
#include <sstream>
#include <string>

namespace {

class StdinReader : public QThread {
    Q_OBJECT
public:
    void run() override {
        std::string buffer;
        int paren_depth = 0;
        bool in_string = false;
        bool escape_next = false;
        bool seen_form = false;
        while (true) {
            int c = std::cin.get();
            if (c == EOF) {
                emit eof();
                return;
            }
            buffer.push_back(static_cast<char>(c));
            if (in_string) {
                if (escape_next) {
                    escape_next = false;
                } else if (c == '\\') {
                    escape_next = true;
                } else if (c == '"') {
                    in_string = false;
                }
                continue;
            }
            if (c == '"') {
                in_string = true;
                seen_form = true;
                continue;
            }
            if (c == '(') {
                paren_depth++;
                seen_form = true;
                continue;
            }
            if (c == ')') {
                paren_depth--;
                if (paren_depth == 0) {
                    emit messageReady(QByteArray::fromStdString(buffer));
                    buffer.clear();
                    seen_form = false;
                }
                continue;
            }
            // Whitespace at depth 0 with no form started: discard.
            if (paren_depth == 0 && !seen_form &&
                (c == ' ' || c == '\t' || c == '\n' || c == '\r')) {
                buffer.clear();
            }
        }
    }

signals:
    void messageReady(QByteArray bytes);
    void eof();
};

class Driver : public QObject {
    Q_OBJECT
public:
    Driver() {
        connect(&reader_, &StdinReader::messageReady,
                this, &Driver::onMessage,
                Qt::QueuedConnection);
        connect(&reader_, &StdinReader::eof,
                qApp, &QApplication::quit,
                Qt::QueuedConnection);
        reader_.start();
    }

    ~Driver() override {
        if (reader_.isRunning()) {
            reader_.terminate();
            reader_.wait(200);
        }
    }

    void emitAction(long long id, const QString& key, const QString& value, const QString& reason) {
        clautolisp::SexpList items;
        items.push_back(clautolisp::Sexp::makeKeyword("ACTION"));
        items.push_back(clautolisp::Sexp::makeInt(id));
        items.push_back(clautolisp::Sexp::makeString(key.toStdString()));
        items.push_back(clautolisp::Sexp::makeString(value.toStdString()));
        items.push_back(clautolisp::Sexp::makeKeyword(
            QString("REASON-").append(reason).toUpper().toStdString()));
        clautolisp::writeMessage(std::cout,
                                  clautolisp::Sexp::makeList(std::move(items)));
    }

    void emitDone(long long id, int status) {
        clautolisp::SexpList items;
        items.push_back(clautolisp::Sexp::makeKeyword("DONE"));
        items.push_back(clautolisp::Sexp::makeInt(id));
        items.push_back(clautolisp::Sexp::makeInt(status));
        clautolisp::writeMessage(std::cout,
                                  clautolisp::Sexp::makeList(std::move(items)));
    }

private slots:
    void onMessage(QByteArray bytes) {
        std::istringstream in(bytes.toStdString());
        clautolisp::SexpReader reader(in);
        clautolisp::Sexp msg;
        try {
            if (!reader.readMessage(msg)) return;
        } catch (const std::exception& e) {
            std::cerr << "[gui-qt] sexp read error: " << e.what() << '\n';
            return;
        }
        if (msg.type() != clautolisp::Sexp::Type::List || msg.asList().empty()) {
            return;
        }
        const auto& items = msg.asList();
        const auto& head = items[0];
        if (head.type() != clautolisp::Sexp::Type::Keyword) return;
        const std::string& tag = head.asKeyword();
        if (tag == "OPEN-DIALOG") {
            handleOpen(msg);
        } else if (tag == "CLOSE-DIALOG") {
            handleClose(msg);
        } else if (tag == "SET-TILE") {
            handleSet(msg);
        } else if (tag == "MODE-TILE") {
            handleMode(msg);
        } else if (tag == "FOCUS") {
            // Optional: focus a key.
        } else if (tag == "BYE") {
            QApplication::quit();
        }
    }

private:
    StdinReader reader_;
    QHash<long long, QPointer<clautolisp::DialogWindow>> windows_;

    void handleOpen(const clautolisp::Sexp& msg) {
        const auto& items = msg.asList();
        if (items.size() < 4) return;
        long long id = items[1].asInt();
        try {
            clautolisp::Tile tile = clautolisp::decodeTile(items[3]);
            auto* window = new clautolisp::DialogWindow(
                id, tile,
                [this, id](const QString& k, const QString& v, const QString& r) {
                    emitAction(id, k, v, r);
                },
                [this, id](int status) {
                    emitDone(id, status);
                });
            windows_.insert(id, window);
            window->show();
            window->raise();
            window->activateWindow();
        } catch (const std::exception& e) {
            std::cerr << "[gui-qt] decode error: " << e.what() << '\n';
        }
    }

    void handleClose(const clautolisp::Sexp& msg) {
        const auto& items = msg.asList();
        if (items.size() < 2) return;
        long long id = items[1].asInt();
        if (auto window = windows_.take(id)) window->close();
    }

    void handleSet(const clautolisp::Sexp& msg) {
        const auto& items = msg.asList();
        if (items.size() < 4) return;
        long long id = items[1].asInt();
        if (auto window = windows_.value(id)) {
            window->setTileValue(clautolisp::sexpToQString(items[2]),
                                  clautolisp::sexpToQString(items[3]));
        }
    }

    void handleMode(const clautolisp::Sexp& msg) {
        const auto& items = msg.asList();
        if (items.size() < 4) return;
        long long id = items[1].asInt();
        if (auto window = windows_.value(id)) {
            window->setTileMode(clautolisp::sexpToQString(items[2]),
                                 static_cast<int>(items[3].asInt()));
        }
    }
};

} // namespace

#include "main.moc"

int main(int argc, char** argv) {
    QApplication app(argc, argv);

    // --demo: pop a built-in dialog and exit. Useful for verifying
    // that Qt itself is healthy before debugging the wire protocol.
    for (int i = 1; i < argc; ++i) {
        if (std::string(argv[i]) == "--demo") {
            clautolisp::Tile root;
            root.type = "DIALOG";
            root.attributes["label"] = "clautolisp-gui-qt smoke test";
            clautolisp::Tile text;
            text.type = "TEXT";
            text.attributes["label"] = "If you can see this, Qt is wired up.";
            root.children.append(text);
            clautolisp::Tile ok;
            ok.type = "OK-ONLY";
            root.children.append(ok);
            clautolisp::DialogWindow window(0, root,
                [](const QString&, const QString&, const QString&) {},
                [](int) { QApplication::quit(); });
            window.show();
            window.raise();
            window.activateWindow();
            return app.exec();
        }
    }

    Driver driver;
    return app.exec();
}
