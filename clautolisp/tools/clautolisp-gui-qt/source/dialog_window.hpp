#pragma once
//
// DCL dialog window: builds a Qt6 widget tree from a Tile and wires
// each interactive widget to emit (:action DID KEY VALUE :reason-selected)
// upstream.

#include "sexp.hpp"
#include "wire.hpp"

#include <QDialog>
#include <QWidget>
#include <functional>

namespace clautolisp {

class DialogWindow : public QDialog {
    Q_OBJECT
public:
    using ActionEmitter = std::function<void(const QString& key,
                                              const QString& value,
                                              const QString& reason)>;
    using DoneEmitter = std::function<void(int status)>;

    DialogWindow(long long id, const Tile& root,
                 ActionEmitter actionFn, DoneEmitter doneFn,
                 QWidget* parent = nullptr);

    long long dialogId() const { return id_; }
    void setTileValue(const QString& key, const QString& value);
    void setTileMode(const QString& key, int mode);
    // Populate a list_box / popup_list. OPERATION matches the
    // AutoLISP start_list contract: 1 = replace one item at INDEX,
    // 2 = append, 3 = clear and replace.
    void populateList(const QString& key, int operation, int index,
                      const QStringList& items);
    // Paint a list of image primitives onto the pixmap of an
    // image / image_button tile. PRIMITIVES is the parsed sexp
    // list — each entry starts with a keyword (:fill / :vector /
    // :slide) followed by integer / string arguments per the
    // wire-protocol grammar.
    void paintImage(const QString& key, const SexpList& primitives);

private:
    long long id_;
    ActionEmitter actionFn_;
    DoneEmitter doneFn_;
    QWidget* buildTile(const Tile& tile);
    // Walk every interactive child widget and emit its current
    // value as an :action upstream. Called immediately before any
    // exiting button fires so the runtime's get_tile observes the
    // latest user input without depending on focus-change timing.
    void flushInputs();
};

} // namespace clautolisp
