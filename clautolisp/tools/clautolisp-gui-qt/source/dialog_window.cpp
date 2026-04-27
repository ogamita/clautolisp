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

#include <QPainter>
#include <QPixmap>

#include <cstdlib>
#include <iostream>

namespace {
bool guiDebug() {
    static const bool flag = std::getenv("CLAUTOLISP_GUI_DEBUG") != nullptr;
    return flag;
}
} // namespace

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
            // Flush all interactive tiles' current values upstream
            // before firing the button so (get_tile) inside the
            // button's action callback observes the latest input.
            flushInputs();
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
        // Fire on every keystroke so callbacks see the live value
        // even if the user clicks a button without tab-ing out.
        connect(edit, &QLineEdit::textChanged, this,
                [this, key](const QString& text) {
                    actionFn_(key, text, "selected");
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
    if (type == "IMAGE" || type == "IMAGE-BUTTON" || type == "IMAGE_BUTTON") {
        // Render the image as a QLabel holding a pixmap. The
        // image is sized from the tile's width / height attrs (or
        // a default 100x60 placeholder); paintImage() draws the
        // primitives onto it later.
        int width = 100, height = 60;
        bool ok = false;
        if (tile.attributes.contains("width")) {
            int w = tile.attributes.value("width").toInt(&ok);
            if (ok && w > 0) width = w * 6;  // DCL units -> pixels
        }
        if (tile.attributes.contains("height")) {
            int h = tile.attributes.value("height").toInt(&ok);
            if (ok && h > 0) height = h * 12;
        }
        auto* label = new QLabel;
        label->setObjectName(tile.key);
        QPixmap pm(width, height);
        pm.fill(Qt::black);
        label->setPixmap(pm);
        label->setFixedSize(width, height);
        // image_button clicks are not yet wired upstream — a
        // follow-up could install an event filter and emit
        // (:action key "0" :reason-selected) on mousePressEvent.
        return label;
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
            flushInputs();
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

void DialogWindow::flushInputs() {
    auto edits = findChildren<QLineEdit*>();
    auto boxes = findChildren<QCheckBox*>();
    if (guiDebug()) {
        std::cerr << "[gui-qt] flushInputs: "
                  << edits.size() << " edits, "
                  << boxes.size() << " toggles\n";
        std::cerr.flush();
    }
    for (auto* edit : edits) {
        if (guiDebug()) {
            std::cerr << "[gui-qt] flush edit '" << edit->objectName().toStdString()
                      << "' = '" << edit->text().toStdString() << "'\n";
            std::cerr.flush();
        }
        if (!edit->objectName().isEmpty()) {
            actionFn_(edit->objectName(), edit->text(), "selected");
        }
    }
    for (auto* box : boxes) {
        if (guiDebug()) {
            std::cerr << "[gui-qt] flush toggle '" << box->objectName().toStdString()
                      << "' = " << (box->isChecked() ? "1" : "0") << "\n";
            std::cerr.flush();
        }
        if (!box->objectName().isEmpty()) {
            actionFn_(box->objectName(), box->isChecked() ? "1" : "0", "selected");
        }
    }
    for (auto* combo : findChildren<QComboBox*>()) {
        if (!combo->objectName().isEmpty()) {
            actionFn_(combo->objectName(),
                      QString::number(combo->currentIndex()), "selected");
        }
    }
    for (auto* list : findChildren<QListWidget*>()) {
        if (!list->objectName().isEmpty()) {
            actionFn_(list->objectName(),
                      QString::number(list->currentRow()), "selected");
        }
    }
}

void DialogWindow::setTileValue(const QString& key, const QString& value) {
    if (auto* widget = findChild<QWidget*>(key)) {
        if (auto* edit = qobject_cast<QLineEdit*>(widget)) edit->setText(value);
        else if (auto* box = qobject_cast<QCheckBox*>(widget)) box->setChecked(value == "1");
        else if (auto* label = qobject_cast<QLabel*>(widget)) label->setText(value);
    }
}

void DialogWindow::populateList(const QString& key, int operation, int index,
                                 const QStringList& items) {
    auto* widget = findChild<QWidget*>(key);
    if (!widget) return;
    if (auto* list = qobject_cast<QListWidget*>(widget)) {
        switch (operation) {
            case 1:
                if (index >= 0 && index < list->count() && !items.isEmpty()) {
                    list->item(index)->setText(items.first());
                }
                break;
            case 2:
                list->addItems(items);
                break;
            default:
                list->clear();
                list->addItems(items);
                break;
        }
        return;
    }
    if (auto* combo = qobject_cast<QComboBox*>(widget)) {
        switch (operation) {
            case 1:
                if (index >= 0 && index < combo->count() && !items.isEmpty()) {
                    combo->setItemText(index, items.first());
                }
                break;
            case 2:
                combo->addItems(items);
                break;
            default:
                combo->clear();
                combo->addItems(items);
                break;
        }
        return;
    }
}

namespace {
QColor aciToRgb(int aci) {
    // Minimal 8-colour AutoCAD ACI mapping. Anything else falls
    // back to a neutral grey so unknown indices still render.
    switch (aci) {
        case 0: return Qt::black;
        case 1: return Qt::red;
        case 2: return Qt::yellow;
        case 3: return Qt::green;
        case 4: return Qt::cyan;
        case 5: return Qt::blue;
        case 6: return Qt::magenta;
        case 7: return Qt::white;
        case 8: return QColor(128, 128, 128);
        case 9: return QColor(192, 192, 192);
        default: return QColor(128, 128, 128);
    }
}
} // namespace

void DialogWindow::paintImage(const QString& key,
                               const SexpList& primitives) {
    auto* widget = findChild<QWidget*>(key);
    auto* label = qobject_cast<QLabel*>(widget);
    if (!label) return;
    QPixmap pm = label->pixmap();
    if (pm.isNull()) {
        pm = QPixmap(label->size());
        pm.fill(Qt::black);
    }
    QPainter p(&pm);
    for (const auto& prim : primitives) {
        if (prim.type() != Sexp::Type::List) continue;
        const auto& items = prim.asList();
        if (items.empty()) continue;
        if (items[0].type() != Sexp::Type::Keyword) continue;
        const std::string& tag = items[0].asKeyword();
        if (tag == "FILL" && items.size() >= 6) {
            int x = items[1].asInt(), y = items[2].asInt();
            int w = items[3].asInt(), h = items[4].asInt();
            int c = items[5].asInt();
            p.fillRect(x, y, w, h, aciToRgb(c));
        } else if (tag == "VECTOR" && items.size() >= 6) {
            int x1 = items[1].asInt(), y1 = items[2].asInt();
            int x2 = items[3].asInt(), y2 = items[4].asInt();
            int c = items[5].asInt();
            p.setPen(aciToRgb(c));
            p.drawLine(x1, y1, x2, y2);
        } else if (tag == "SLIDE") {
            // Slides are .sld files — full support is a follow-up
            // pass. For now we render a placeholder rectangle so
            // the user knows a slide was requested.
            if (items.size() >= 5) {
                int x = items[1].asInt(), y = items[2].asInt();
                int w = items[3].asInt(), h = items[4].asInt();
                p.setPen(Qt::white);
                p.drawRect(x, y, w - 1, h - 1);
                p.drawText(x + 2, y + 12, "[slide]");
            }
        }
    }
    p.end();
    label->setPixmap(pm);
}

void DialogWindow::setTileMode(const QString& key, int mode) {
    if (auto* widget = findChild<QWidget*>(key)) {
        // mode 0 = enabled, 1 = disabled, 2 = focus, 3 = select all
        widget->setEnabled(mode != 1);
        if (mode == 2) widget->setFocus();
    }
}

} // namespace clautolisp
