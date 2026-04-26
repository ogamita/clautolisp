#pragma once
//
// Tile-form decoder: converts a (:tile TYPE KEY (:attr ...) (:children ...))
// sexp into something the dialog window can render.

#include "sexp.hpp"

#include <QString>
#include <QVariant>
#include <QVariantMap>
#include <QVector>

namespace clautolisp {

struct Tile {
    QString type;
    QString key;
    QVariantMap attributes;
    QVector<Tile> children;
};

Tile decodeTile(const Sexp& form);

QString sexpToQString(const Sexp& form);
QVariant sexpToVariant(const Sexp& form);

} // namespace clautolisp
