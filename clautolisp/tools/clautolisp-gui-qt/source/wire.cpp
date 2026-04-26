#include "wire.hpp"

#include <stdexcept>

namespace clautolisp {

QString sexpToQString(const Sexp& form) {
    switch (form.type()) {
        case Sexp::Type::String: return QString::fromStdString(form.asString());
        case Sexp::Type::Keyword: return QString::fromStdString(form.asKeyword());
        case Sexp::Type::Integer: return QString::number(form.asInt());
        case Sexp::Type::Double: return QString::number(form.asDouble());
        case Sexp::Type::Bool: return form.asBool() ? "t" : "nil";
        case Sexp::Type::Nil: return QString();
        default: return QString();
    }
}

QVariant sexpToVariant(const Sexp& form) {
    switch (form.type()) {
        case Sexp::Type::String: return QString::fromStdString(form.asString());
        case Sexp::Type::Keyword: return QString::fromStdString(form.asKeyword());
        case Sexp::Type::Integer: return QVariant::fromValue(form.asInt());
        case Sexp::Type::Double: return form.asDouble();
        case Sexp::Type::Bool: return form.asBool();
        case Sexp::Type::Nil: return QVariant();
        default: return QVariant();
    }
}

Tile decodeTile(const Sexp& form) {
    if (form.type() != Sexp::Type::List || form.asList().size() < 5) {
        throw std::runtime_error("invalid tile form");
    }
    const auto& items = form.asList();
    if (items[0].type() != Sexp::Type::Keyword || items[0].asKeyword() != "TILE") {
        throw std::runtime_error("tile form does not start with :tile");
    }
    Tile t;
    t.type = sexpToQString(items[1]);
    t.key = sexpToQString(items[2]);
    if (t.key == "NOKEY") t.key.clear();
    // (:attr (NAME VALUE) ...)
    if (items[3].type() == Sexp::Type::List) {
        const auto& attrList = items[3].asList();
        for (size_t i = 1; i < attrList.size(); ++i) {
            const auto& pair = attrList[i];
            if (pair.type() == Sexp::Type::List && pair.asList().size() == 2) {
                QString name = sexpToQString(pair.asList()[0]);
                QVariant value = sexpToVariant(pair.asList()[1]);
                t.attributes[name] = value;
            }
        }
    }
    // (:children TILE-FORM ...)
    if (items[4].type() == Sexp::Type::List) {
        const auto& childList = items[4].asList();
        for (size_t i = 1; i < childList.size(); ++i) {
            t.children.append(decodeTile(childList[i]));
        }
    }
    return t;
}

} // namespace clautolisp
