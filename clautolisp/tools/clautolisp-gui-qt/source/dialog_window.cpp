#include "dialog_window.hpp"

#include <QBoxLayout>
#include <QCheckBox>
#include <QComboBox>
#include <QDialogButtonBox>
#include <QFormLayout>
#include <QGroupBox>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QPushButton>
#include <QRadioButton>
#include <QVBoxLayout>

namespace clautolisp {

namespace {

QString attrAsString(const Tile& t, const QString& name, const QString& fallback = QString()) {
    auto it = t.attributes.find(name);
    if (it == t.attributes.end()) return fallback;
    return it.value().toString();
}

bool attrAsBool(const Tile& t, const QString& name) {
    auto it = t.attributes.find(name);
    if (it == t.attributes.end()) return false;
    QVariant v = it.value();
    if (v.typeId() == QMetaType::Bool) return v.toBool();
    return v.toString() == "t" || v.toString() == "true";
}

} // namespace

DialogWindow::DialogWindow(long long id, const Tile& root,
                           ActionEmitter actionFn, DoneEmitter doneFn,
                           QWidget* parent)
    : QDialog(parent), id_(id),
      actionFn_(std::move(actionFn)), doneFn_(std::move(doneFn)) {
    setWindowTitle(attrAsString(root, "label", "Dialog"));
    auto* layout = new QVBoxLayout(this);
    for (const auto& child : root.children) {
        if (auto* widget = buildTile(child)) {
            layout->addWidget(widget);
        }
    }
}

QWidget* DialogWindow::buildTile(const Tile& tile) {
    const QString& type = tile.type;
    if (type == "TEXT") {
        return new QLabel(attrAsString(tile, "label"));
    }
    if (type == "SPACER") {
        auto* w = new QWidget;
        w->setMinimumHeight(8);
        return w;
    }
    if (type == "BUTTON") {
        auto* btn = new QPushButton(attrAsString(tile, "label", tile.key));
        btn->setObjectName(tile.key);
        QString key = tile.key;
        connect(btn, &QPushButton::clicked, this, [this, key, tile]() {
            actionFn_(key, "1", "selected");
            if (attrAsBool(tile, "is_default")) doneFn_(1);
            else if (attrAsBool(tile, "is_cancel")) doneFn_(0);
        });
        return btn;
    }
    if (type == "EDIT-BOX" || type == "EDIT_BOX") {
        auto* container = new QWidget;
        auto* layout = new QFormLayout(container);
        auto* edit = new QLineEdit(attrAsString(tile, "value"));
        edit->setObjectName(tile.key);
        QString key = tile.key;
        connect(edit, &QLineEdit::editingFinished, this, [this, edit, key]() {
            actionFn_(key, edit->text(), "selected");
        });
        layout->addRow(attrAsString(tile, "label", tile.key), edit);
        return container;
    }
    if (type == "TOGGLE") {
        auto* box = new QCheckBox(attrAsString(tile, "label", tile.key));
        box->setObjectName(tile.key);
        QString key = tile.key;
        connect(box, &QCheckBox::toggled, this, [this, key](bool on) {
            actionFn_(key, on ? "1" : "0", "selected");
        });
        return box;
    }
    if (type == "LIST-BOX" || type == "LIST_BOX") {
        auto* list = new QListWidget;
        list->setObjectName(tile.key);
        QString key = tile.key;
        connect(list, &QListWidget::currentRowChanged, this, [this, key](int row) {
            actionFn_(key, QString::number(row), "selected");
        });
        return list;
    }
    if (type == "POPUP-LIST" || type == "POPUP_LIST") {
        auto* combo = new QComboBox;
        combo->setObjectName(tile.key);
        QString key = tile.key;
        connect(combo, qOverload<int>(&QComboBox::currentIndexChanged),
                this, [this, key](int row) {
                    actionFn_(key, QString::number(row), "selected");
                });
        return combo;
    }
    if (type == "ROW" || type == "BOXED-ROW" || type == "BOXED_ROW") {
        auto* container = (type == "ROW")
            ? static_cast<QWidget*>(new QWidget)
            : static_cast<QWidget*>(new QGroupBox(attrAsString(tile, "label")));
        auto* layout = new QHBoxLayout(container);
        for (const auto& child : tile.children) {
            if (auto* widget = buildTile(child)) layout->addWidget(widget);
        }
        return container;
    }
    if (type == "COLUMN" || type == "BOXED-COLUMN" || type == "BOXED_COLUMN") {
        auto* container = (type == "COLUMN")
            ? static_cast<QWidget*>(new QWidget)
            : static_cast<QWidget*>(new QGroupBox(attrAsString(tile, "label")));
        auto* layout = new QVBoxLayout(container);
        for (const auto& child : tile.children) {
            if (auto* widget = buildTile(child)) layout->addWidget(widget);
        }
        return container;
    }
    if (type == "OK-CANCEL" || type == "OK_CANCEL" ||
        type == "OK-ONLY" || type == "OK_ONLY" ||
        type == "OK-CANCEL-HELP" || type == "OK_CANCEL_HELP") {
        auto* box = new QDialogButtonBox;
        auto* ok = box->addButton(QDialogButtonBox::Ok);
        connect(ok, &QPushButton::clicked, this, [this]() {
            actionFn_("accept", "1", "selected");
            doneFn_(1);
        });
        if (type != "OK-ONLY" && type != "OK_ONLY") {
            auto* cancel = box->addButton(QDialogButtonBox::Cancel);
            connect(cancel, &QPushButton::clicked, this, [this]() {
                actionFn_("cancel", "0", "selected");
                doneFn_(0);
            });
        }
        if (type == "OK-CANCEL-HELP" || type == "OK_CANCEL_HELP") {
            auto* help = box->addButton(QDialogButtonBox::Help);
            connect(help, &QPushButton::clicked, this, [this]() {
                actionFn_("help", "0", "selected");
            });
        }
        return box;
    }
    // Fallback: render as a placeholder label.
    return new QLabel(QStringLiteral("[%1 %2]").arg(type, tile.key));
}

void DialogWindow::setTileValue(const QString& key, const QString& value) {
    if (auto* widget = findChild<QWidget*>(key)) {
        if (auto* edit = qobject_cast<QLineEdit*>(widget)) edit->setText(value);
        else if (auto* box = qobject_cast<QCheckBox*>(widget)) box->setChecked(value == "1");
        else if (auto* label = qobject_cast<QLabel*>(widget)) label->setText(value);
    }
}

void DialogWindow::setTileMode(const QString& key, int mode) {
    if (auto* widget = findChild<QWidget*>(key)) {
        // mode 0 = enabled, 1 = disabled, 2 = focus, 3 = select all
        widget->setEnabled(mode != 1);
        if (mode == 2) widget->setFocus();
    }
}

} // namespace clautolisp
