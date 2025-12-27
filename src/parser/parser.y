%skeleton "lalr1.cc"
%require "3.2"
%defines
%define api.token.constructor
%define api.value.type variant
%define api.namespace {fin}
%define parse.assert
%locations

%code requires {
    #include <string>
    #include <vector>
    #include <memory>
    #include <utility>
    #include "../ast/ASTNode.hpp"
}

%code {
    #include "../lexer/lexer.hpp"
    fin::parser::symbol_type yylex();
}

/* ========================================================================== */
/*                                   TOKENS                                   */
/* ========================================================================== */

%token END 0 "end of file"

/* Literals */
%token <std::string> IDENTIFIER INTEGER FLOAT STRING_LITERAL CHAR_LITERAL

/* Keywords */
%token KW_LET KW_BEZ KW_CONST KW_BETON KW_AUTO
%token KW_FUN KW_NORET KW_RETURN
%token KW_PUB KW_PRIV
%token KW_STRUCT KW_ENUM KW_INTERFACE
%token KW_MACRO KW_STATIC KW_NULL
%token KW_WHILE KW_FOR KW_FOREACH KW_BREAK KW_CONTINUE
%token KW_IF KW_ELSE KW_ELSEIF KW_IN
%token KW_TRY KW_CATCH KW_BLAME KW_SUPER KW_SELF_TYPE
%token KW_IMPORT KW_AS KW_FROM
%token KW_NEW KW_DELETE KW_SIZEOF KW_TYPEOF KW_AS_PTR
%token KW_STD_CONV KW_OPERATOR
%token KW_SPECIAL KW_AT_RETURN KW_FN_TYPE KW_DEFINE
%token KW_INTERFACE KW_MACRO KW_STATIC KW_NULL
%token KW_TRY KW_CATCH KW_BLAME KW_SUPER KW_SELF_TYPE
%token KW_IMPORT KW_AS KW_FROM
%token KW_NEW KW_DELETE KW_SIZEOF KW_TYPEOF KW_AS_PTR KW_STD_CONV KW_OPERATOR
%token KW_SPECIAL KW_AT_RETURN KW_FN_TYPE KW_DEFINE KW_M1778
%token KW_M1778

/* Types */
%token TYPE_INT TYPE_FLOAT TYPE_DOUBLE TYPE_BOOL 
%token TYPE_STRING TYPE_CHAR TYPE_VOID TYPE_LONG
%token TYPE_INT TYPE_FLOAT TYPE_DOUBLE TYPE_BOOL TYPE_STRING TYPE_CHAR TYPE_VOID TYPE_LONG

/* Punctuation */
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token SEMICOLON COLON DOUBLE_COLON COMMA DOT ARROW ELLIPSIS
%token AT DOLLAR HASH

/* Operators */
%token EQUAL PLUSEQUAL MINUSEQUAL MULTEQUAL DIVEQUAL
%token EQEQ NOTEQ LT GT LTEQ GTEQ
%token AND OR NOT
%token PLUS MINUS MULT DIV MOD
%token AMPERSAND
%token INCREMENT DECREMENT


/* Punctuation */
%token ARROW DOUBLE_COLON ELLIPSIS
%token INCREMENT DECREMENT
%token PLUSEQUAL MINUSEQUAL MULTEQUAL DIVEQUAL
%token EQEQ NOTEQ LT GT LTEQ GTEQ AND OR NOT
%token AMPERSAND LBRACKET RBRACKET DOLLAR HASH

/* Precedence (Matching Python) */
%right EQUAL PLUSEQUAL MINUSEQUAL MULTEQUAL DIVEQUAL
%left OR
%left AND
%nonassoc EQEQ NOTEQ LT GT LTEQ GTEQ
%left PLUS MINUS
%left MULT DIV MOD
%right NOT UMINUS ADDRESSOF_PREC DEREFERENCE_PREC
%left LPAREN LBRACKET DOT LBRACE
%left INCREMENT DECREMENT

/* ========================================================================== */
/*                                    TYPES                                   */
/* ========================================================================== */

/* Core */
%type <std::unique_ptr<fin::Program>> program
%type <std::vector<std::unique_ptr<fin::Statement>>> statements block_stmts
%type <std::unique_ptr<fin::Statement>> statement 
%type <std::unique_ptr<fin::Block>> block

/* Declarations */
%type <std::unique_ptr<fin::Statement>> variable_declaration function_declaration struct_declaration enum_declaration
%type <std::unique_ptr<fin::Statement>> import_statement
%type <std::unique_ptr<fin::TypeNode>> type type_specifier base_type pointer_type array_type
%type <std::vector<std::unique_ptr<fin::Parameter>>> params param_list
%type <std::unique_ptr<fin::Parameter>> param

/* Structs */
%type <std::vector<std::unique_ptr<fin::StructMember>>> struct_members
%type <std::unique_ptr<fin::StructMember>> struct_member

/* Control Flow */
%type <std::unique_ptr<fin::Statement>> if_statement while_loop for_loop try_catch_statement blame_statement return_statement expression_statement

/* Expressions */
%type <std::unique_ptr<fin::Expression>> expression assignment_expression conditional_expression logical_or logical_and equality comparison additive multiplicative unary postfix primary
%type <std::unique_ptr<fin::Expression>> literal
%type <std::vector<std::unique_ptr<fin::Expression>>> arguments expression_list
%type <std::vector<std::pair<std::string, std::unique_ptr<fin::Expression>>>> field_assignments

/* Helpers */
%type <bool> visibility_opt
%type <std::string> primitive_type dotted_path

%%

/* ========================================================================== */
/*                                   GRAMMAR                                  */
/* ========================================================================== */

program:
    statements { 
        $$ = std::make_unique<fin::Program>(std::move($1)); 
        $$->setLoc(@$);
    }
    ;

statements:
    statements statement {
        $1.push_back(std::move($2));
        $$ = std::move($1);
    }
    | statement {
        std::vector<std::unique_ptr<fin::Statement>> vec;
        if ($1) vec.push_back(std::move($1));
        $$ = std::move(vec);
    }
    | %empty {
        $$ = std::vector<std::unique_ptr<fin::Statement>>();
    }
    ;

statement:
      variable_declaration { $$ = std::move($1); }
    | function_declaration { $$ = std::move($1); }
    | struct_declaration   { $$ = std::move($1); }
    | enum_declaration     { $$ = std::move($1); }
    | import_statement     { $$ = std::move($1); }
    | if_statement         { $$ = std::move($1); }
    | while_loop           { $$ = std::move($1); }
    | for_loop             { $$ = std::move($1); }
    | try_catch_statement  { $$ = std::move($1); }
    | blame_statement      { $$ = std::move($1); }
    | return_statement     { $$ = std::move($1); }
    | expression_statement { $$ = std::move($1); }
    | SEMICOLON            { $$ = nullptr; } /* Empty statement */
    ;

block:
    LBRACE block_stmts RBRACE {
        $$ = std::make_unique<fin::Block>(std::move($2));
        $$->setLoc(@$);
    }
    ;

block_stmts:
    statements { $$ = std::move($1); }
    ;

/* ========================================================================== */
/*                                  IMPORTS                                   */
/* ========================================================================== */

import_statement:
    KW_IMPORT STRING_LITERAL SEMICOLON {
        std::vector<std::string> empty_targets;
        $$ = std::make_unique<fin::ImportModule>($2, false, "", empty_targets);
        $$->setLoc(@$);
    }
    | KW_IMPORT dotted_path SEMICOLON {
        std::vector<std::string> empty_targets;
        $$ = std::make_unique<fin::ImportModule>($2, true, "", empty_targets);
        $$->setLoc(@$);
    }
    ;

dotted_path:
    IDENTIFIER { $$ = $1; }
    | dotted_path DOT IDENTIFIER { $$ = $1 + "." + $3; }
    ;

/* ========================================================================== */
/*                                  STRUCTS                                   */
/* ========================================================================== */

struct_declaration:
    visibility_opt KW_STRUCT IDENTIFIER LBRACE struct_members RBRACE {
        $$ = std::make_unique<fin::StructDeclaration>($3, std::move($5), $1);
        $$->setLoc(@$);
    }
    ;

struct_members:
    struct_members struct_member COMMA { 
        $1.push_back(std::move($2)); $$ = std::move($1); 
    }
    | struct_members struct_member { 
        $1.push_back(std::move($2)); $$ = std::move($1); 
    }
    | struct_member COMMA { 
        std::vector<std::unique_ptr<fin::StructMember>> v; v.push_back(std::move($1)); $$ = std::move(v); 
    }
    | struct_member { 
        std::vector<std::unique_ptr<fin::StructMember>> v; v.push_back(std::move($1)); $$ = std::move(v); 
    }
    | %empty { $$ = std::vector<std::unique_ptr<fin::StructMember>>(); }
    ;

struct_member:
    visibility_opt IDENTIFIER COLON LT type GT {
        $$ = std::make_unique<fin::StructMember>($2, std::move($5), $1);
        $$->setLoc(@$);
    }
    ;

/* ========================================================================== */
/*                                 FUNCTIONS                                  */
/* ========================================================================== */

function_declaration:
    visibility_opt KW_FUN IDENTIFIER LPAREN params RPAREN LT type GT block {
        $$ = std::make_unique<fin::FunctionDeclaration>($3, std::move($5), std::move($8), std::move($10));
        static_cast<fin::FunctionDeclaration*>($$.get())->is_public = $1;
        $$->setLoc(@$);
    }
    | visibility_opt KW_FUN IDENTIFIER LPAREN params RPAREN KW_NORET block {
        auto voidType = std::make_unique<fin::TypeNode>("void");
        $$ = std::make_unique<fin::FunctionDeclaration>($3, std::move($5), std::move(voidType), std::move($8));
        static_cast<fin::FunctionDeclaration*>($$.get())->is_public = $1;
        $$->setLoc(@$);
    }
    ;

params:
    param_list { $$ = std::move($1); }
    | %empty { $$ = std::vector<std::unique_ptr<fin::Parameter>>(); }
    ;

param_list:
    param_list COMMA param { $1.push_back(std::move($3)); $$ = std::move($1); }
    | param { std::vector<std::unique_ptr<fin::Parameter>> v; v.push_back(std::move($1)); $$ = std::move(v); }
    ;

param:
    IDENTIFIER COLON LT type GT {
        $$ = std::make_unique<fin::Parameter>($1, std::move($4), nullptr, false);
        $$->setLoc(@$);
    }
    | ELLIPSIS IDENTIFIER COLON LT type GT {
        $$ = std::make_unique<fin::Parameter>($2, std::move($5), nullptr, true);
        $$->setLoc(@$);
    }
    ;

/* ========================================================================== */
/*                                 VARIABLES                                  */
/* ========================================================================== */

variable_declaration:
    KW_LET IDENTIFIER LT type GT EQUAL expression SEMICOLON {
        $$ = std::make_unique<fin::VariableDeclaration>(true, $2, std::move($4), std::move($7));
        $$->setLoc(@$);
    }
    | KW_CONST IDENTIFIER LT type GT EQUAL expression SEMICOLON {
        $$ = std::make_unique<fin::VariableDeclaration>(false, $2, std::move($4), std::move($7));
        $$->setLoc(@$);
    }
    | KW_LET IDENTIFIER LT type GT SEMICOLON {
        $$ = std::make_unique<fin::VariableDeclaration>(true, $2, std::move($4), nullptr);
        $$->setLoc(@$);
    }
    ;

/* ========================================================================== */
/*                                   TYPES                                    */
/* ========================================================================== */

type:
    base_type { $$ = std::move($1); }
    | pointer_type { $$ = std::move($1); }
    | array_type { $$ = std::move($1); }
    ;

base_type:
    primitive_type { $$ = std::make_unique<fin::TypeNode>($1); }
    | IDENTIFIER { $$ = std::make_unique<fin::TypeNode>($1); }
    | KW_AUTO { $$ = std::make_unique<fin::TypeNode>("auto"); }
    ;

pointer_type:
    AMPERSAND type {
        $$ = std::move($2);
        $$->is_pointer = true;
    }
    ;

array_type:
    LBRACKET type RBRACKET {
        $$ = std::move($2);
        $$->is_array = true;
    }
    | LBRACKET type COMMA expression RBRACKET {
        $$ = std::move($2);
        $$->is_array = true;
        $$->array_size = std::move($4);
    }
    ;

primitive_type:
    TYPE_INT { $$ = "int"; } | TYPE_FLOAT { $$ = "float"; } | TYPE_STRING { $$ = "string"; }
    | TYPE_VOID { $$ = "void"; } | TYPE_BOOL { $$ = "bool"; }
    ;

/* ========================================================================== */
/*                                CONTROL FLOW                                */
/* ========================================================================== */

if_statement:
    KW_IF LPAREN expression RPAREN block {
        $$ = std::make_unique<fin::IfStatement>(std::move($3), std::move($5), nullptr);
        $$->setLoc(@$);
    }
    | KW_IF LPAREN expression RPAREN block KW_ELSE block {
        $$ = std::make_unique<fin::IfStatement>(std::move($3), std::move($5), std::move($7));
        $$->setLoc(@$);
    }
    ;

while_loop:
    KW_WHILE LPAREN expression RPAREN block {
        $$ = std::make_unique<fin::WhileLoop>(std::move($3), std::move($5));
        $$->setLoc(@$);
    }
    ;

for_loop:
    KW_FOR LPAREN variable_declaration expression SEMICOLON expression RPAREN block {
        $$ = std::make_unique<fin::ForLoop>(std::move($3), std::move($4), std::move($6), std::move($8));
        $$->setLoc(@$);
    }
    ;

try_catch_statement:
    KW_TRY block KW_CATCH LPAREN IDENTIFIER KW_AS type RPAREN block {
        $$ = std::make_unique<fin::TryCatch>(std::move($2), $5, std::move($7), std::move($9));
        $$->setLoc(@$);
    }
    ;

blame_statement:
    KW_BLAME expression SEMICOLON {
        $$ = std::make_unique<fin::BlameStatement>(std::move($2));
        $$->setLoc(@$);
    }
    ;

return_statement:
    KW_RETURN expression SEMICOLON { $$ = std::make_unique<fin::ReturnStatement>(std::move($2)); }
    | KW_RETURN SEMICOLON { $$ = std::make_unique<fin::ReturnStatement>(nullptr); }
    ;

/* ========================================================================== */
/*                                EXPRESSIONS                                 */
/* ========================================================================== */

expression_statement:
    expression SEMICOLON { $$ = std::make_unique<fin::ExpressionStatement>(std::move($1)); }
    ;

expression: assignment_expression { $$ = std::move($1); } ;

assignment_expression:
    conditional_expression { $$ = std::move($1); }
    | unary EQUAL assignment_expression {
        $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::EQUAL, std::move($3));
    }
    | unary PLUSEQUAL assignment_expression {
        $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::PLUSEQUAL, std::move($3));
    }
    ;

conditional_expression: logical_or { $$ = std::move($1); } ;

logical_or:
    logical_and { $$ = std::move($1); }
    | logical_or OR logical_and {
        $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::OR, std::move($3));
    }
    ;

logical_and:
    equality { $$ = std::move($1); }
    | logical_and AND equality {
        $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::AND, std::move($3));
    }
    ;

equality:
    comparison { $$ = std::move($1); }
    | equality EQEQ comparison { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::EQEQ, std::move($3)); }
    | equality NOTEQ comparison { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::NOTEQ, std::move($3)); }
    ;

comparison:
    additive { $$ = std::move($1); }
    | comparison LT additive { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::LT, std::move($3)); }
    | comparison GT additive { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::GT, std::move($3)); }
    ;

additive:
    multiplicative { $$ = std::move($1); }
    | additive PLUS multiplicative { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::PLUS, std::move($3)); }
    | additive MINUS multiplicative { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::MINUS, std::move($3)); }
    ;

multiplicative:
    unary { $$ = std::move($1); }
    | multiplicative MULT unary { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::MULT, std::move($3)); }
    | multiplicative DIV unary { $$ = std::make_unique<fin::BinaryOp>(std::move($1), fin::TokenKind::DIV, std::move($3)); }
    ;

unary:
    postfix { $$ = std::move($1); }
    | MINUS unary %prec UMINUS { $$ = std::make_unique<fin::UnaryOp>(fin::TokenKind::MINUS, std::move($2)); }
    | NOT unary { $$ = std::make_unique<fin::UnaryOp>(fin::TokenKind::NOT, std::move($2)); }
    | AMPERSAND unary %prec ADDRESSOF_PREC { $$ = std::make_unique<fin::UnaryOp>(fin::TokenKind::AMPERSAND, std::move($2)); }
    | MULT unary %prec DEREFERENCE_PREC { $$ = std::make_unique<fin::UnaryOp>(fin::TokenKind::MULT, std::move($2)); }
    ;

postfix:
    primary { $$ = std::move($1); }
    | postfix LPAREN arguments RPAREN {
        // Function Call
        if (auto* id = dynamic_cast<fin::Identifier*>($1.get())) {
            $$ = std::make_unique<fin::FunctionCall>(id->name, std::move($3));
        } else {
            // Handle generic call or other expr call
            // For now, assume identifier
            $$ = std::make_unique<fin::FunctionCall>("unknown", std::move($3));
        }
    }
    | postfix DOT IDENTIFIER {
        $$ = std::make_unique<fin::MemberAccess>(std::move($1), $3);
    }
    ;

primary:
    literal { $$ = std::move($1); }
    | IDENTIFIER { $$ = std::make_unique<fin::Identifier>($1); }
    | LPAREN expression RPAREN { $$ = std::move($2); }
    | DOLLAR IDENTIFIER LPAREN arguments RPAREN {
        $$ = std::make_unique<fin::MacroCall>($2, std::move($4));
    }
    /* Struct Instantiation: Name { x: 1 } */
    | IDENTIFIER LBRACE field_assignments RBRACE {
        $$ = std::make_unique<fin::StructInstantiation>($1, std::move($3));
    }
    /* Array Literal: [1, 2] */
    | LBRACKET arguments RBRACKET {
        $$ = std::make_unique<fin::ArrayLiteral>(std::move($2));
    }
    ;

literal:
    INTEGER { $$ = std::make_unique<fin::Literal>($1, fin::TokenKind::INTEGER); }
    | FLOAT { $$ = std::make_unique<fin::Literal>($1, fin::TokenKind::FLOAT); }
    | STRING_LITERAL { $$ = std::make_unique<fin::Literal>($1, fin::TokenKind::STRING_LITERAL); }
    | KW_NULL { $$ = std::make_unique<fin::Literal>("null", fin::TokenKind::KW_NULL); }
    ;

arguments:
    expression_list { $$ = std::move($1); }
    | %empty { $$ = std::vector<std::unique_ptr<fin::Expression>>(); }
    ;

expression_list:
    expression_list COMMA expression { $1.push_back(std::move($3)); $$ = std::move($1); }
    | expression { std::vector<std::unique_ptr<fin::Expression>> v; v.push_back(std::move($1)); $$ = std::move(v); }
    ;

field_assignments:
    field_assignments COMMA IDENTIFIER COLON expression {
        $1.push_back({$3, std::move($5)}); $$ = std::move($1);
    }
    | IDENTIFIER COLON expression {
        std::vector<std::pair<std::string, std::unique_ptr<fin::Expression>>> v;
        v.push_back({$1, std::move($3)}); $$ = std::move(v);
    }
    | %empty { $$ = std::vector<std::pair<std::string, std::unique_ptr<fin::Expression>>>(); }
    ;

/* ========================================================================== */
/*                                  HELPERS                                   */
/* ========================================================================== */

visibility_opt:
    KW_PUB { $$ = true; }
    | KW_PRIV { $$ = false; }
    | %empty { $$ = false; }
    ;

enum_declaration:
    KW_ENUM IDENTIFIER LBRACE RBRACE {
        // Placeholder for enum
        std::vector<std::pair<std::string, std::unique_ptr<fin::Expression>>> empty;
        $$ = std::make_unique<fin::EnumDeclaration>($2, std::move(empty));
    }
    ;

%%

void fin::parser::error(const location_type& l, const std::string& m) {
    std::cerr << "Parser Error at " << l << ": " << m << std::endl;
}