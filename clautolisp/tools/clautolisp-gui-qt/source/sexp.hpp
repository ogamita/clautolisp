#pragma once
//
// Minimal sexp reader/writer for the clautolisp DCL wire protocol.
//
// Grammar (matches autolisp-dcl/source/sexp-wire.lisp):
//   - `(` and `)` group lists
//   - `"..."` is a string with `\\`, `\"`, `\n`, `\t`, `\r` escapes
//   - `:keyword` is a keyword
//   - `nil` and `t` are literals
//   - `42`, `-7`, `3.14` are numbers
//   - bare identifiers become uppercased keywords
//
// Values are tagged unions (Sexp). The reader takes a std::istream
// (typically std::cin) and yields one Sexp per call. The writer
// formats a Sexp onto a std::ostream, terminated by '\n'.

#include <iosfwd>
#include <memory>
#include <string>
#include <variant>
#include <vector>

namespace clautolisp {

class Sexp;
using SexpList = std::vector<Sexp>;

class Sexp {
public:
    enum class Type { Nil, Bool, Integer, Double, String, Keyword, List };

    Sexp() : type_(Type::Nil) {}
    static Sexp makeNil() { return Sexp(); }
    static Sexp makeBool(bool b) { Sexp s; s.type_ = Type::Bool; s.bval_ = b; return s; }
    static Sexp makeInt(long long i) { Sexp s; s.type_ = Type::Integer; s.ival_ = i; return s; }
    static Sexp makeDouble(double d) { Sexp s; s.type_ = Type::Double; s.dval_ = d; return s; }
    static Sexp makeString(std::string v) { Sexp s; s.type_ = Type::String; s.sval_ = std::move(v); return s; }
    static Sexp makeKeyword(std::string v) { Sexp s; s.type_ = Type::Keyword; s.sval_ = std::move(v); return s; }
    static Sexp makeList(SexpList v) { Sexp s; s.type_ = Type::List; s.list_ = std::move(v); return s; }

    Type type() const { return type_; }
    bool asBool() const { return bval_; }
    long long asInt() const { return ival_; }
    double asDouble() const { return dval_; }
    const std::string& asString() const { return sval_; }
    const std::string& asKeyword() const { return sval_; }
    const SexpList& asList() const { return list_; }

private:
    Type type_;
    bool bval_ = false;
    long long ival_ = 0;
    double dval_ = 0.0;
    std::string sval_;
    SexpList list_;
};

// Reads one sexp form from `in`. Returns std::nullopt at EOF.
// Throws std::runtime_error on malformed input.
class SexpReader {
public:
    explicit SexpReader(std::istream& in);
    bool readMessage(Sexp& out);

private:
    std::istream& in_;
    Sexp readForm();
    Sexp readList();
    Sexp readString();
    Sexp readToken();
    void skipWhitespace();
    int peek();
    int advance();
};

// Writes `s` to `out` followed by a newline; flushes.
void writeMessage(std::ostream& out, const Sexp& s);

} // namespace clautolisp
