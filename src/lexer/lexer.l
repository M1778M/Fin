%{
#include <string>
#include <iostream>
#include "../parser/parser.hpp" // Include Bison's generated header

// Define the return type to match Bison's expectation
#define YY_DECL fin::parser::symbol_type yylex()

// Track location
int current_line = 1;
int current_col = 1;

// Helper to update location
void update_loc() {
    // Bison's location tracking is handled via the return value constructors usually,
    // but we maintain local state for error reporting.
}

%}

/* Flex Options */
%option noyywrap
%option nounput
%option noinput
%option nounistd
%option never-interactive

/* Regex Definitions */
DIGIT       [0-9]
ALPHA       [a-zA-Z_]
ID          {ALPHA}({ALPHA}|{DIGIT})*
WS          [ \t\r]+

%%

    /* ====================================================================== */
    /*                               WHITESPACE                               */
    /* ====================================================================== */

{WS}        { current_col += yyleng; }
\n          { current_line++; current_col = 1; }

    /* ====================================================================== */
    /*                                COMMENTS                                */
    /* ====================================================================== */

"//".*      { /* Ignore single line */ }
"/*"([^*]|(\*+[^*/]))*\*+"/" { 
    // Handle newlines inside block comments
    for(int i=0; i<yyleng; i++) {
        if(yytext[i] == '\n') { current_line++; current_col=1; }
        else current_col++;
    }
}

    /* ====================================================================== */
    /*                                KEYWORDS                                */
    /* ====================================================================== */

"let"       { current_col += yyleng; return fin::parser::make_KW_LET(); }
"bez"       { current_col += yyleng; return fin::parser::make_KW_BEZ(); }
"const"     { current_col += yyleng; return fin::parser::make_KW_CONST(); }
"beton"     { current_col += yyleng; return fin::parser::make_KW_BETON(); }
"auto"      { current_col += yyleng; return fin::parser::make_KW_AUTO(); }

"fun"       { current_col += yyleng; return fin::parser::make_KW_FUN(); }
"<noret>"   { current_col += yyleng; return fin::parser::make_KW_NORET(); }
"return"    { current_col += yyleng; return fin::parser::make_KW_RETURN(); }

"struct"    { current_col += yyleng; return fin::parser::make_KW_STRUCT(); }
"enum"      { current_col += yyleng; return fin::parser::make_KW_ENUM(); }
"interface" { current_col += yyleng; return fin::parser::make_KW_INTERFACE(); }

"macro"     { current_col += yyleng; return fin::parser::make_KW_MACRO(); }
"static"    { current_col += yyleng; return fin::parser::make_KW_STATIC(); }
"null"      { current_col += yyleng; return fin::parser::make_KW_NULL(); }

"while"     { current_col += yyleng; return fin::parser::make_KW_WHILE(); }
"for"       { current_col += yyleng; return fin::parser::make_KW_FOR(); }
"foreach"   { current_col += yyleng; return fin::parser::make_KW_FOREACH(); }
"break"     { current_col += yyleng; return fin::parser::make_KW_BREAK(); }
"continue"  { current_col += yyleng; return fin::parser::make_KW_CONTINUE(); }

"if"        { current_col += yyleng; return fin::parser::make_KW_IF(); }
"else"      { current_col += yyleng; return fin::parser::make_KW_ELSE(); }
"elseif"    { current_col += yyleng; return fin::parser::make_KW_ELSEIF(); }
"in"        { current_col += yyleng; return fin::parser::make_KW_IN(); }

"import"    { current_col += yyleng; return fin::parser::make_KW_IMPORT(); }
"as"        { current_col += yyleng; return fin::parser::make_KW_AS(); }
"from"      { current_col += yyleng; return fin::parser::make_KW_FROM(); }

"new"       { current_col += yyleng; return fin::parser::make_KW_NEW(); }
"delete"    { current_col += yyleng; return fin::parser::make_KW_DELETE(); }
"sizeof"    { current_col += yyleng; return fin::parser::make_KW_SIZEOF(); }
"typeof"    { current_col += yyleng; return fin::parser::make_KW_TYPEOF(); }
"as_ptr"    { current_col += yyleng; return fin::parser::make_KW_AS_PTR(); }
"std_conv"  { current_col += yyleng; return fin::parser::make_KW_STD_CONV(); }

"pub"       { current_col += yyleng; return fin::parser::make_KW_PUB(); }
"priv"      { current_col += yyleng; return fin::parser::make_KW_PRIV(); }

"operator"  { current_col += yyleng; return fin::parser::make_KW_OPERATOR(); }

"try"       { current_col += yyleng; return fin::parser::make_KW_TRY(); }
"catch"     { current_col += yyleng; return fin::parser::make_KW_CATCH(); }
"blame"     { current_col += yyleng; return fin::parser::make_KW_BLAME(); }
"super"     { current_col += yyleng; return fin::parser::make_KW_SUPER(); }
"Self"      { current_col += yyleng; return fin::parser::make_KW_SELF_TYPE(); }

"special"   { current_col += yyleng; return fin::parser::make_KW_SPECIAL(); }
"@return"   { current_col += yyleng; return fin::parser::make_KW_AT_RETURN(); }
"fn"        { current_col += yyleng; return fin::parser::make_KW_FN_TYPE(); }
"define"    { current_col += yyleng; return fin::parser::make_KW_DEFINE(); }

"m1778"     { current_col += yyleng; return fin::parser::make_KW_M1778(); }

    /* ====================================================================== */
    /*                                  TYPES                                 */
    /* ====================================================================== */

"int"       { current_col += yyleng; return fin::parser::make_TYPE_INT(); }
"long"      { current_col += yyleng; return fin::parser::make_TYPE_LONG(); }
"float"     { current_col += yyleng; return fin::parser::make_TYPE_FLOAT(); }
"double"    { current_col += yyleng; return fin::parser::make_TYPE_DOUBLE(); }
"bool"      { current_col += yyleng; return fin::parser::make_TYPE_BOOL(); }
"string"    { current_col += yyleng; return fin::parser::make_TYPE_STRING(); }
"char"      { current_col += yyleng; return fin::parser::make_TYPE_CHAR(); }
"void"      { current_col += yyleng; return fin::parser::make_TYPE_VOID(); }
"noret"     { current_col += yyleng; return fin::parser::make_TYPE_VOID(); } /* Map noret to void */

    /* ====================================================================== */
    /*                        OPERATORS & PUNCTUATION                         */
    /* ====================================================================== */

"=>"        { current_col += yyleng; return fin::parser::make_ARROW(); }
"::"        { current_col += yyleng; return fin::parser::make_DOUBLE_COLON(); }
"..."       { current_col += yyleng; return fin::parser::make_ELLIPSIS(); }

"++"        { current_col += yyleng; return fin::parser::make_INCREMENT(); }
"--"        { current_col += yyleng; return fin::parser::make_DECREMENT(); }

"+="        { current_col += yyleng; return fin::parser::make_PLUSEQUAL(); }
"-="        { current_col += yyleng; return fin::parser::make_MINUSEQUAL(); }
"*="        { current_col += yyleng; return fin::parser::make_MULTEQUAL(); }
"/="        { current_col += yyleng; return fin::parser::make_DIVEQUAL(); }

"=="        { current_col += yyleng; return fin::parser::make_EQEQ(); }
"!="        { current_col += yyleng; return fin::parser::make_NOTEQ(); }
"<="        { current_col += yyleng; return fin::parser::make_LTEQ(); }
">="        { current_col += yyleng; return fin::parser::make_GTEQ(); }
"&&"        { current_col += yyleng; return fin::parser::make_AND(); }
"||"        { current_col += yyleng; return fin::parser::make_OR(); }

"("         { current_col += yyleng; return fin::parser::make_LPAREN(); }
")"         { current_col += yyleng; return fin::parser::make_RPAREN(); }
"{"         { current_col += yyleng; return fin::parser::make_LBRACE(); }
"}"         { current_col += yyleng; return fin::parser::make_RBRACE(); }
"["         { current_col += yyleng; return fin::parser::make_LBRACKET(); }
"]"         { current_col += yyleng; return fin::parser::make_RBRACKET(); }

";"         { current_col += yyleng; return fin::parser::make_SEMICOLON(); }
":"         { current_col += yyleng; return fin::parser::make_COLON(); }
","         { current_col += yyleng; return fin::parser::make_COMMA(); }
"."         { current_col += yyleng; return fin::parser::make_DOT(); }
"@"         { current_col += yyleng; return fin::parser::make_AT(); }
"$"         { current_col += yyleng; return fin::parser::make_DOLLAR(); }
"#"         { current_col += yyleng; return fin::parser::make_HASH(); }

"="         { current_col += yyleng; return fin::parser::make_EQUAL(); }
"+"         { current_col += yyleng; return fin::parser::make_PLUS(); }
"-"         { current_col += yyleng; return fin::parser::make_MINUS(); }
"*"         { current_col += yyleng; return fin::parser::make_MULT(); }
"/"         { current_col += yyleng; return fin::parser::make_DIV(); }
"%"         { current_col += yyleng; return fin::parser::make_MOD(); }
"<"         { current_col += yyleng; return fin::parser::make_LT(); }
">"         { current_col += yyleng; return fin::parser::make_GT(); }
"!"         { current_col += yyleng; return fin::parser::make_NOT(); }
"&"         { current_col += yyleng; return fin::parser::make_AMPERSAND(); }

    /* ====================================================================== */
    /*                                LITERALS                                */
    /* ====================================================================== */

{DIGIT}+"."{DIGIT}+ { current_col += yyleng; return fin::parser::make_FLOAT(yytext); }
{DIGIT}+            { current_col += yyleng; return fin::parser::make_INTEGER(yytext); }
\"([^\\\"]|\\.)*\"  { current_col += yyleng; return fin::parser::make_STRING_LITERAL(yytext); }
\'([^\\\']|\\.)\'   { current_col += yyleng; return fin::parser::make_CHAR_LITERAL(yytext); }

    /* ====================================================================== */
    /*                               IDENTIFIERS                              */
    /* ====================================================================== */

{ID}                { current_col += yyleng; return fin::parser::make_IDENTIFIER(yytext); }

    /* ====================================================================== */
    /*                                 ERROR                                  */
    /* ====================================================================== */

.           { std::cerr << "Lexer Error: Unexpected character '" << yytext << "' at line " << current_line << std::endl; }
<<EOF>>     { return fin::parser::make_END(); }

%%