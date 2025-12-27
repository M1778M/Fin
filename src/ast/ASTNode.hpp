#pragma once

#include <string>
#include <vector>
#include <memory>
#include <optional>
#include <variant>
#include "../lexer/tokens.hpp"

namespace fin {

// Forward Declarations
class Statement;
class Expression;
class Block;

// ============================================================================
// Base & Helpers
// ============================================================================
class ASTNode {
public:
    int line = 0;
    int column = 0;
    virtual ~ASTNode() = default;
    
    // Helper to attach location from Bison location
    template<typename Loc>
    void setLoc(const Loc& loc) {
        line = loc.begin.line;
        column = loc.begin.column;
    }
};

// ============================================================================
// Core Types
// ============================================================================

// Represents a type like "int", "Box<T>", "fn(int)<void>"
class TypeNode : public ASTNode {
public:
    std::string name; // "int", "Box", etc.
    std::vector<std::unique_ptr<TypeNode>> generics;
    bool is_pointer = false;
    bool is_array = false;
    std::unique_ptr<Expression> array_size = nullptr; // For [int, 10]

    TypeNode(std::string n) : name(std::move(n)) {}
};

class GenericParam : public ASTNode {
public:
    std::string name;
    std::unique_ptr<TypeNode> constraint; // T : Castable
    GenericParam(std::string n, std::unique_ptr<TypeNode> c = nullptr) 
        : name(std::move(n)), constraint(std::move(c)) {}
};

class Attribute : public ASTNode {
public:
    std::string name;
    // Value can be bool (flag), string, or list of args. Storing as string/vector for now.
    std::string value_str; 
    bool is_flag = true;
    
    Attribute(std::string n, bool flag) : name(std::move(n)), is_flag(flag) {}
    Attribute(std::string n, std::string v) : name(std::move(n)), value_str(std::move(v)), is_flag(false) {}
};

// ============================================================================
// Expressions
// ============================================================================
class Expression : public ASTNode {};

class Literal : public Expression {
public:
    std::string value;
    TokenKind kind; // INTEGER, FLOAT, STRING, NULL
    Literal(std::string v, TokenKind k) : value(std::move(v)), kind(k) {}
};

class Identifier : public Expression {
public:
    std::string name;
    Identifier(std::string n) : name(std::move(n)) {}
};

class BinaryOp : public Expression {
public:
    std::unique_ptr<Expression> left;
    TokenKind op;
    std::unique_ptr<Expression> right;
    BinaryOp(std::unique_ptr<Expression> l, TokenKind o, std::unique_ptr<Expression> r)
        : left(std::move(l)), op(o), right(std::move(r)) {}
};

class UnaryOp : public Expression {
public:
    TokenKind op;
    std::unique_ptr<Expression> operand;
    UnaryOp(TokenKind o, std::unique_ptr<Expression> e) : op(o), operand(std::move(e)) {}
};

class FunctionCall : public Expression {
public:
    std::string name;
    std::vector<std::unique_ptr<Expression>> args;
    std::vector<std::unique_ptr<TypeNode>> generic_args; // ::<int>
    
    FunctionCall(std::string n, std::vector<std::unique_ptr<Expression>> a) 
        : name(std::move(n)), args(std::move(a)) {}
};

class StructInstantiation : public Expression {
public:
    std::string struct_name;
    // Using a pair for field assignments: name : value
    std::vector<std::pair<std::string, std::unique_ptr<Expression>>> fields;
    
    StructInstantiation(std::string n, std::vector<std::pair<std::string, std::unique_ptr<Expression>>> f)
        : struct_name(std::move(n)), fields(std::move(f)) {}
};

class MemberAccess : public Expression {
public:
    std::unique_ptr<Expression> object;
    std::string member;
    MemberAccess(std::unique_ptr<Expression> obj, std::string m) 
        : object(std::move(obj)), member(std::move(m)) {}
};

class ArrayLiteral : public Expression {
public:
    std::vector<std::unique_ptr<Expression>> elements;
    ArrayLiteral(std::vector<std::unique_ptr<Expression>> e) : elements(std::move(e)) {}
};

class NewExpression : public Expression {
public:
    std::unique_ptr<TypeNode> type;
    std::vector<std::unique_ptr<Expression>> args; // Constructor args
    NewExpression(std::unique_ptr<TypeNode> t, std::vector<std::unique_ptr<Expression>> a)
        : type(std::move(t)), args(std::move(a)) {}
};

class SizeofExpression : public Expression {
public:
    std::unique_ptr<TypeNode> type_target;
    std::unique_ptr<Expression> expr_target;
    // One of these will be null
};

class MacroCall : public Expression {
public:
    std::string name;
    std::vector<std::unique_ptr<Expression>> args;
    MacroCall(std::string n, std::vector<std::unique_ptr<Expression>> a)
        : name(std::move(n)), args(std::move(a)) {}
};

// ============================================================================
// Statements
// ============================================================================
class Statement : public ASTNode {};

class Block : public Statement {
public:
    std::vector<std::unique_ptr<Statement>> statements;
    Block(std::vector<std::unique_ptr<Statement>> s) : statements(std::move(s)) {}
};

class VariableDeclaration : public Statement {
public:
    bool is_mutable;
    std::string name;
    std::unique_ptr<TypeNode> type;
    std::unique_ptr<Expression> initializer;
    
    VariableDeclaration(bool mut, std::string n, std::unique_ptr<TypeNode> t, std::unique_ptr<Expression> init)
        : is_mutable(mut), name(std::move(n)), type(std::move(t)), initializer(std::move(init)) {}
};

class ReturnStatement : public Statement {
public:
    std::unique_ptr<Expression> value;
    ReturnStatement(std::unique_ptr<Expression> v) : value(std::move(v)) {}
};

class ExpressionStatement : public Statement {
public:
    std::unique_ptr<Expression> expr;
    ExpressionStatement(std::unique_ptr<Expression> e) : expr(std::move(e)) {}
};

class IfStatement : public Statement {
public:
    std::unique_ptr<Expression> condition;
    std::unique_ptr<Block> then_block;
    // Else can be Block or another IfStatement (for else if)
    std::unique_ptr<Statement> else_stmt; 
    
    IfStatement(std::unique_ptr<Expression> c, std::unique_ptr<Block> t, std::unique_ptr<Statement> e)
        : condition(std::move(c)), then_block(std::move(t)), else_stmt(std::move(e)) {}
};

class WhileLoop : public Statement {
public:
    std::unique_ptr<Expression> condition;
    std::unique_ptr<Block> body;
    WhileLoop(std::unique_ptr<Expression> c, std::unique_ptr<Block> b)
        : condition(std::move(c)), body(std::move(b)) {}
};

class ForLoop : public Statement {
public:
    std::unique_ptr<Statement> init; // VariableDecl
    std::unique_ptr<Expression> condition;
    std::unique_ptr<Expression> increment;
    std::unique_ptr<Block> body;
    
    ForLoop(std::unique_ptr<Statement> i, std::unique_ptr<Expression> c, std::unique_ptr<Expression> inc, std::unique_ptr<Block> b)
        : init(std::move(i)), condition(std::move(c)), increment(std::move(inc)), body(std::move(b)) {}
};

class TryCatch : public Statement {
public:
    std::unique_ptr<Block> try_block;
    std::string catch_var;
    std::unique_ptr<TypeNode> catch_type;
    std::unique_ptr<Block> catch_block;
    
    TryCatch(std::unique_ptr<Block> t, std::string cv, std::unique_ptr<TypeNode> ct, std::unique_ptr<Block> cb)
        : try_block(std::move(t)), catch_var(std::move(cv)), catch_type(std::move(ct)), catch_block(std::move(cb)) {}
};

class BlameStatement : public Statement {
public:
    std::unique_ptr<Expression> error_expr;
    BlameStatement(std::unique_ptr<Expression> e) : error_expr(std::move(e)) {}
};

class ImportModule : public Statement {
public:
    std::string source;
    bool is_package;
    std::string alias;
    std::vector<std::string> targets; // import { A, B }
    
    ImportModule(std::string src, bool pkg, std::string al, std::vector<std::string> tgts)
        : source(std::move(src)), is_package(pkg), alias(std::move(al)), targets(std::move(tgts)) {}
};

// ============================================================================
// Top Level Declarations
// ============================================================================

class Parameter : public ASTNode {
public:
    std::string name;
    std::unique_ptr<TypeNode> type;
    std::unique_ptr<Expression> default_value;
    bool is_vararg = false;
    
    Parameter(std::string n, std::unique_ptr<TypeNode> t, std::unique_ptr<Expression> d, bool v)
        : name(std::move(n)), type(std::move(t)), default_value(std::move(d)), is_vararg(v) {}
};

class FunctionDeclaration : public Statement {
public:
    std::string name;
    std::vector<std::unique_ptr<Parameter>> params;
    std::unique_ptr<TypeNode> return_type;
    std::unique_ptr<Block> body;
    bool is_public;
    bool is_static;
    std::vector<std::unique_ptr<GenericParam>> generic_params;
    std::vector<std::unique_ptr<Attribute>> attributes;

    FunctionDeclaration(std::string n, std::vector<std::unique_ptr<Parameter>> p, std::unique_ptr<TypeNode> rt, std::unique_ptr<Block> b)
        : name(std::move(n)), params(std::move(p)), return_type(std::move(rt)), body(std::move(b)) {}
};

class StructMember : public ASTNode {
public:
    std::string name;
    std::unique_ptr<TypeNode> type;
    std::unique_ptr<Expression> default_value;
    bool is_public;
    
    StructMember(std::string n, std::unique_ptr<TypeNode> t, bool pub)
        : name(std::move(n)), type(std::move(t)), is_public(pub) {}
};

class StructDeclaration : public Statement {
public:
    std::string name;
    std::vector<std::unique_ptr<StructMember>> members;
    std::vector<std::unique_ptr<FunctionDeclaration>> methods;
    std::vector<std::unique_ptr<GenericParam>> generic_params;
    bool is_public;
    
    StructDeclaration(std::string n, std::vector<std::unique_ptr<StructMember>> m, bool pub)
        : name(std::move(n)), members(std::move(m)), is_public(pub) {}
};

class EnumDeclaration : public Statement {
public:
    std::string name;
    std::vector<std::pair<std::string, std::unique_ptr<Expression>>> values;
    EnumDeclaration(std::string n, std::vector<std::pair<std::string, std::unique_ptr<Expression>>> v)
        : name(std::move(n)), values(std::move(v)) {}
};

class Program : public ASTNode {
public:
    std::vector<std::unique_ptr<Statement>> statements;
    Program(std::vector<std::unique_ptr<Statement>> s) : statements(std::move(s)) {}
};

} // namespace fin