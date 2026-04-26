#pragma once
//
// DCL dialog window: builds a Qt6 widget tree from a Tile and wires
// each interactive widget to emit (:action DID KEY VALUE :reason-selected)
// upstream.

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
