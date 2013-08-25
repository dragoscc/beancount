/* -*- mode: c -*- */
/* A flex lexer for Beancount. */

/*------------------------------------------------------------------------------------------------------------------------*/
/* Definitions */

/* Options */
%option noyywrap
%option nodefault
%option yylineno
%option never-interactive
%option warn
%option bison-bridge
%option bison-locations
/* %option reentrant */
/* %option debug */
/* %option stack */
/* %option 8bit */


/* Top Code. */
%top{

/* Includes. */
#include <math.h>
#include <stdlib.h>

#include "parser.h"
#include "grammar.h"


/* The filename being parsed. */
extern const char* yy_filename;
extern int yycolumn;



/* Handle detecting the beginning of line. */
extern int yy_line_tokens; /* Number of tokens since the bol */

#define YY_USER_ACTION  {                               \
    yy_line_tokens++;                                   \
    yylloc->first_line = yylloc->last_line = yylineno;  \
    yylloc->first_column = yycolumn;                    \
    yylloc->last_column = yycolumn+yyleng-1;            \
    yycolumn += yyleng;                                 \
  }


/* Skip the rest of the input line. */
void yy_skip_line(void);
void yy_skip_until_empty(void);


/* Error handlers. */
extern void yyerror(char const *s);
extern void yyerror2(char const *s, YYLTYPE* yylloc);


/* Utility functions. */
int strtonl(const char* buf, size_t nchars);

}


/*------------------------------------------------------------------------------------------------------------------------*/
/* Rules */
%%


 /* Newlines are output as explicit tokens, because lines matter in the syntax. */
\n		{
    yy_line_tokens = 0;
    yycolumn = 1;
    return EOL;
}

 /* Ignore whitespace, except when found at the beginning of a line and followed by a non-comment regular character.
    This is how we group indented postings. */
[ \t\r]+	{
    if ( yy_line_tokens == 1 ) {
        /* If the next character completes the line, skip it. */
        if ( yy_hold_char == '\n' || yy_hold_char == '\r' || yy_hold_char == '\0' || yy_hold_char == ';' ) {
            return SKIPPED;
        }
        else {
            return INDENT;
        }
    }
}

 /* Characters with special meanings have their own tokens. */
\|		{ return PIPE; }
@@		{ return ATAT; }
@		{ return AT; }
\{		{ return LCURL; }
\}		{ return RCURL; }
=		{ return EQUAL; }
,		{ return COMMA; }
\/		{ return SLASH; }

 /* Skip commented output (but not the accompanying newline). */
;+		{
    yy_skip_line();
    return COMMENT;
}

 /* Special characters which may be used in-lieu of a 'txn' keyword in a transaction declaration output as a token.
    Other lines are just skipped. This allows us to use org-mode or other separators in the input syntax. */
[*!&#?%]	{
    if ( yy_line_tokens != 1 ) {
        yylval->character = yytext[0];
        return FLAG;
    }
    else {
        yy_skip_line();
        return SKIPPED;
    }
}

 /* Keywords. */
txn		{ return TXN; }
check		{ return CHECK; }
open		{ return OPEN; }
close		{ return CLOSE; }
pad		{ return PAD; }
event		{ return EVENT; }
price		{ return PRICE; }
note		{ return NOTE; }
document	{ return DOCUMENT; }
pushtag	        { return PUSHTAG; }
poptag		{ return POPTAG; }
option		{ return OPTION; }

 /* Dates. */
[0-9][0-9][0-9][0-9][-/][0-9][0-9][-/][0-9][0-9]	{
    int year = strtonl(yytext, 4);
    int month = strtonl(yytext+5, 2);
    int day = strtonl(yytext+8, 2);
    yylval->pyobj = BUILD("DATE", "iii", year, month, day);
    return DATE;
}

 /* Account names. */
(Assets|Liabilities|Equity|Income|Expenses)(:[A-Z][A-Za-z0-9\-]+)+		{
    yylval->pyobj = BUILD("ACCOUNT", "s", yytext);
    return ACCOUNT;
}

 /* Currencies. These are defined as uppercase only in order to disambiguate the syntax. */
[A-Z][A-Z0-9\'\.]{1,10}		{
    yylval->pyobj = BUILD("CURRENCY", "s", yytext);
    return CURRENCY;
}

 /* String literals. */
\"[^\"]*\" 			{
    yytext[yyleng-1] = '\0';
    yylval->pyobj = BUILD("STRING", "s", &(yytext[1]));
    return STRING;
}

 /* Numbers */
[-+]?([0-9\.])+ 		{
    yylval->pyobj = BUILD("NUMBER", "s", yytext);
    return NUMBER;
}

 /* Tags */
#[A-Za-z0-9\-_/.]+ 		{
    yylval->pyobj = BUILD("TAG", "s", &(yytext[1]));
    return TAG;
}

 /* Links */
\^[A-Za-z0-9\-_/.]+ 		{
    yylval->pyobj = BUILD("LINK", "s", &(yytext[1]));
    return LINK;
}

 /* Default rule. This should never be reached. */
.	{
    yyerror2("Syntax error; lexer cannot parse token.", yylloc);
    yy_skip_line();
    yy_skip_until_empty();
    /* FIXME: I need to somehow tell the parser to abandon the current entry! */
}



%%
/*------------------------------------------------------------------------------------------------------------------------*/
/* User Code */

const char* yy_filename = 0;
int yy_line_tokens = 0;
int yycolumn = 1;

#define LEXEOF 0

void yy_skip_line()
{
    int c;
    while ( (c = input()) != LEXEOF ) {
        if ( c == '\n' ) {
            unput(c);
            break;
        }
    }
}

/* Skip tokens until we hit an empty line.
   This is used to recover from syntax errors. */
void yy_skip_until_empty()
{
/* FIXME: How do we pull all the tokens until we hit an empty line? */
/* I need to read about flex error handling here, maybe we have to call a function
   in the parser otherwise. */
    /* for ( ;; ) { */
    /*     int token = yylex(&yylval, &yylloc); */
    /*     if ( token == 0 ) { */
}

int strtonl(const char* buf, size_t nchars)
{
    int result = 0;
    int i;
    for ( i = 0; i < nchars; ++i ) {
        result *= 10;
        result += (buf[i] - '0');
    }
    return result;
}