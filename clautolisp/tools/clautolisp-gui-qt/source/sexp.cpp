#include "sexp.hpp"

#include <cctype>
#include <istream>
#include <ostream>
#include <sstream>
#include <stdexcept>

namespace clautolisp {

SexpReader::SexpReader(std::istream& in) : in_(in) {}

int SexpReader::peek() { return in_.peek(); }

int SexpReader::advance() { return in_.get(); }

void SexpReader::skipWhitespace() {
    int c;
    while ((c = peek()) != EOF) {
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            advance();
        } else {
            break;
        }
    }
}

bool SexpReader::readMessage(Sexp& out) {
    skipWhitespace();
    if (peek() == EOF) {
        return false;
    }
    out = readForm();
    return true;
}

Sexp SexpReader::readForm() {
    skipWhitespace();
    int c = peek();
    if (c == EOF) {
        throw std::runtime_error("unexpected EOF");
    }
    if (c == '(') { advance(); return readList(); }
    if (c == ')') { throw std::runtime_error("unexpected )"); }
    if (c == '"') { advance(); return readString(); }
    return readToken();
}

Sexp SexpReader::readList() {
    SexpList items;
    while (true) {
        skipWhitespace();
        int c = peek();
        if (c == EOF) {
            throw std::runtime_error("unterminated list");
        }
        if (c == ')') {
            advance();
            return Sexp::makeList(std::move(items));
        }
        items.push_back(readForm());
    }
}

Sexp SexpReader::readString() {
    std::string buf;
    while (true) {
        int c = advance();
        if (c == EOF) {
            throw std::runtime_error("unterminated string");
        }
        if (c == '"') {
            return Sexp::makeString(std::move(buf));
        }
        if (c == '\\') {
            int next = advance();
            switch (next) {
                case 'n': buf.push_back('\n'); break;
                case 't': buf.push_back('\t'); break;
                case 'r': buf.push_back('\r'); break;
                case '\\': buf.push_back('\\'); break;
                case '"': buf.push_back('"'); break;
                default:
                    if (next != EOF) buf.push_back(static_cast<char>(next));
                    break;
            }
        } else {
            buf.push_back(static_cast<char>(c));
        }
    }
}

Sexp SexpReader::readToken() {
    std::string buf;
    while (true) {
        int c = peek();
        if (c == EOF) break;
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r' ||
            c == '(' || c == ')' || c == '"') break;
        buf.push_back(static_cast<char>(advance()));
    }
    if (buf.empty()) {
        throw std::runtime_error("empty token");
    }
    if (buf[0] == ':') {
        std::string name = buf.substr(1);
        for (auto& ch : name) ch = static_cast<char>(std::toupper(static_cast<unsigned char>(ch)));
        return Sexp::makeKeyword(std::move(name));
    }
    if (buf == "nil") return Sexp::makeNil();
    if (buf == "t" || buf == "T") return Sexp::makeBool(true);
    // Numeric?
    {
        std::stringstream ss(buf);
        long long iv;
        ss >> iv;
        if (ss.eof() && !ss.fail()) {
            return Sexp::makeInt(iv);
        }
    }
    {
        std::stringstream ss(buf);
        double dv;
        ss >> dv;
        if (ss.eof() && !ss.fail()) {
            return Sexp::makeDouble(dv);
        }
    }
    // Bare identifier -> uppercase keyword.
    std::string name = buf;
    for (auto& ch : name) ch = static_cast<char>(std::toupper(static_cast<unsigned char>(ch)));
    return Sexp::makeKeyword(std::move(name));
}

static void writeForm(std::ostream& out, const Sexp& s) {
    switch (s.type()) {
        case Sexp::Type::Nil: out << "nil"; break;
        case Sexp::Type::Bool: out << (s.asBool() ? "t" : "nil"); break;
        case Sexp::Type::Integer: out << s.asInt(); break;
        case Sexp::Type::Double: out << s.asDouble(); break;
        case Sexp::Type::String: {
            out << '"';
            for (char c : s.asString()) {
                switch (c) {
                    case '\\': out << "\\\\"; break;
                    case '"': out << "\\\""; break;
                    case '\n': out << "\\n"; break;
                    case '\t': out << "\\t"; break;
                    case '\r': out << "\\r"; break;
                    default: out << c; break;
                }
            }
            out << '"';
            break;
        }
        case Sexp::Type::Keyword: {
            out << ':';
            std::string name = s.asKeyword();
            for (auto& ch : name) ch = static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
            out << name;
            break;
        }
        case Sexp::Type::List: {
            out << '(';
            const auto& items = s.asList();
            for (size_t i = 0; i < items.size(); ++i) {
                if (i > 0) out << ' ';
                writeForm(out, items[i]);
            }
            out << ')';
            break;
        }
    }
}

void writeMessage(std::ostream& out, const Sexp& s) {
    writeForm(out, s);
    out << '\n';
    out.flush();
}

} // namespace clautolisp
