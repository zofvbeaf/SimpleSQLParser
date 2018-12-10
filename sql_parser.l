%{
#include "nodes/keywords.h"
#include "parser/scanner.h"
#include "parser/gramparse.h"

#include <string.h>
#include <stdio.h>

#define startlit()	( yyextra->literallen = 0 )

#define YYSTYPE core_YYSTYPE

#define YY_EXTRA_TYPE core_yy_extra_type *

#define SET_YYLLOC() 

#define yyerror(msg)  scanner_yyerror(msg, NULL)

static void addlit(char *ytext, int yleng, core_yyscan_t yyscanner);
static char *litbufdup(core_yyscan_t yyscanner);
static void addlitchar(unsigned char ychar, core_yyscan_t yyscanner);

%}

%option reentrant nodefault 
%option noyywrap case-insensitive
%option bison-bridge 

%x xd
%x xq

space			[ \t\n\r\f]
horiz_space		[ \t\f]
newline			[\n\r]
non_newline		[^\n\r]

comment			("--"{non_newline}*)

whitespace		({space}+|{comment})

digit			[0-9]
ident_start		[A-Za-z\200-\377_]
ident_cont		[A-Za-z\200-\377_0-9\$]
identifier		{ident_start}{ident_cont}*

special_whitespace		({space}+|{comment}{newline})
horiz_whitespace		({horiz_space}|{comment})
whitespace_with_newline	({horiz_whitespace}*{newline}{special_whitespace}*)

quote			'
quotestop		{quote}{whitespace}*
quotecontinue	{quote}{whitespace_with_newline}{quote}
quotefail		{quote}{whitespace}*"-"

xqstart			{quote}
xqdouble		{quote}{quote}
xqinside		[^']+

dquote			\"
xdstart			{dquote}
xdstop			{dquote}
xddouble		{dquote}{dquote}
xdinside		[^"]+

typecast		"::"
dot_dot			\.\.
colon_equals	":="

equals_greater	"=>"
less_equals		"<="
greater_equals	">="
less_greater	"<>"
not_equals		"!="

self			[,()\[\].;\:\+\-\*\/\%\^\<\>\=]
op_chars		[\~\!\@\#\^\&\|\`\?\+\-\*\/\%\<\>\=]
operator		{op_chars}+

integer			{digit}+
decimal			(({digit}*\.{digit}+)|({digit}+\.{digit}*))

real			({integer}|{decimal})[Ee][-+]?{digit}+

other			.

%%

{whitespace}	{
					/* ignore */
				}

{xqstart}		{
					SET_YYLLOC();
					BEGIN(xq);
					startlit();
				}

{xdstart}		{
					SET_YYLLOC();
					BEGIN(xd);
					startlit();
				}

<xq>{xqinside}  {
					addlit(yytext, yyleng, yyscanner);
				}

<xq>{xqdouble} {
					addlitchar('\'', yyscanner);
				}

<xd>{xdinside}	{
					addlit(yytext, yyleng, yyscanner);
				}

<xd>{xddouble}	{
					addlitchar('"', yyscanner);
				}

<xq>{quotestop}	|
<xq>{quotefail} {
					yyless(1);
					BEGIN(INITIAL);
					yylval->str = litbufdup(yyscanner);
					return SCONST;
				}

<xd>{xdstop}	{
					char	   *ident;

					BEGIN(INITIAL);
          if (yyextra->literallen == 0)
            yyerror("zero-length delimited identifier");
					ident = litbufdup(yyscanner);
					/*if (yyextra->literallen >= NAMEDATALEN)*/
						/*truncate_identifier(ident, yyextra->literallen, true);*/
					yylval->str = ident;
					return IDENT;
				}

<xd><<EOF>>		{ yyerror("unterminated quoted identifier"); }

<xq><<EOF>>		{ yyerror("unterminated quoted string"); }

{typecast}		{
					SET_YYLLOC();
					return TYPECAST;
				}

{dot_dot}		{
					SET_YYLLOC();
					return DOT_DOT;
				}

{colon_equals}	{
					SET_YYLLOC();
					return COLON_EQUALS;
				}

{equals_greater} {
					SET_YYLLOC();
					return EQUALS_GREATER;
				}

{less_equals}	{
					SET_YYLLOC();
					return LESS_EQUALS;
				}

{greater_equals} {
					SET_YYLLOC();
					return GREATER_EQUALS;
				}

{less_greater}	{
					/* We accept both "<>" and "!=" as meaning NOT_EQUALS */
					SET_YYLLOC();
					return NOT_EQUALS;
				}

{not_equals}	{
					/* We accept both "<>" and "!=" as meaning NOT_EQUALS */
					SET_YYLLOC();
					return NOT_EQUALS;
				}

{self}			{
					SET_YYLLOC();
					return yytext[0];
				}

{operator}		{
					/*
					 * Check for embedded slash-star or dash-dash; those
					 * are comment starts, so operator must stop there.
					 * Note that slash-star or dash-dash at the first
					 * character will match a prior rule, not this one.
					 */
					int			nchars = yyleng;
					char	   *slashstar = strstr(yytext, "/*");
					char	   *dashdash = strstr(yytext, "--");

					if (slashstar && dashdash)
					{
						/* if both appear, take the first one */
						if (slashstar > dashdash)
							slashstar = dashdash;
					}
					else if (!slashstar)
						slashstar = dashdash;
					if (slashstar)
						nchars = slashstar - yytext;

					/*
					 * For SQL compatibility, '+' and '-' cannot be the
					 * last char of a multi-char operator unless the operator
					 * contains chars that are not in SQL operators.
					 * The idea is to lex '=-' as two operators, but not
					 * to forbid operator names like '?-' that could not be
					 * sequences of SQL operators.
					 */
					if (nchars > 1 &&
						(yytext[nchars - 1] == '+' ||
						 yytext[nchars - 1] == '-'))
					{
						int			ic;

						for (ic = nchars - 2; ic >= 0; ic--)
						{
							char c = yytext[ic];
							if (c == '~' || c == '!' || c == '@' ||
								c == '#' || c == '^' || c == '&' ||
								c == '|' || c == '`' || c == '?' ||
								c == '%')
								break;
						}
						if (ic < 0)
						{
							/*
							 * didn't find a qualifying character, so remove
							 * all trailing [+-]
							 */
							do {
								nchars--;
							} while (nchars > 1 &&
								 (yytext[nchars - 1] == '+' ||
								  yytext[nchars - 1] == '-'));
						}
					}

					SET_YYLLOC();

					if (nchars < yyleng)
					{
						/* Strip the unwanted chars from the token */
						yyless(nchars);
						/*
						 * If what we have left is only one char, and it's
						 * one of the characters matching "self", then
						 * return it as a character token the same way
						 * that the "self" rule would have.
						 */
						if (nchars == 1 &&
							strchr(",()[].;:+-*/%^<>=", yytext[0]))
							return yytext[0];
						/*
						 * Likewise, if what we have left is two chars, and
						 * those match the tokens ">=", "<=", "=>", "<>" or
						 * "!=", then we must return the appropriate token
						 * rather than the generic Op.
						 */
						if (nchars == 2)
						{
							if (yytext[0] == '=' && yytext[1] == '>')
								return EQUALS_GREATER;
							if (yytext[0] == '>' && yytext[1] == '=')
								return GREATER_EQUALS;
							if (yytext[0] == '<' && yytext[1] == '=')
								return LESS_EQUALS;
							if (yytext[0] == '<' && yytext[1] == '>')
								return NOT_EQUALS;
							if (yytext[0] == '!' && yytext[1] == '=')
								return NOT_EQUALS;
						}
					}

					/*
					 * Complain if operator is too long.  Unlike the case
					 * for identifiers, we make this an error not a notice-
					 * and-truncate, because the odds are we are looking at
					 * a syntactic mistake anyway.
					 */
					if (nchars >= NAMEDATALEN)
						yyerror("operator too long");

					yylval->str = strdup(yytext);
					return Op;
				}


{integer}		{
					SET_YYLLOC();
				  yylval->ival = atoi(yytext);	
					return ICONST;
				}

{decimal}		{
					SET_YYLLOC();
					yylval->str = strdup(yytext);
					return FCONST;
				}

{real}			{
					SET_YYLLOC();
					yylval->str = strdup(yytext);
					return FCONST;
				}

{identifier}	{
					const ScanKeyword *keyword;
					char	   *ident;

					SET_YYLLOC();

					/* Is it a keyword? */
					keyword = ScanKeywordLookup(yytext,
												yyextra->keywords,
												yyextra->num_keywords);
					if (keyword != NULL)
					{
						yylval->keyword = keyword->name;
						return keyword->value;
					}
          else {
            // TODO(aqp): tolower(yytext)
					  yylval->str = strdup(yytext);
					  return IDENT;
          }
				}

{other}			{
					SET_YYLLOC();
					return yytext[0];
				}

<<EOF>>			{
					SET_YYLLOC();
					yyterminate();
				}

%%

#undef yyextra
#define yyextra  (((struct yyguts_t *) yyscanner)->yyextra_r)
#undef yyleng
#define yyleng  (((struct yyguts_t *) yyscanner)->yyleng_r)


/*
 * Called before any actual parsing is done
 */
core_yyscan_t
scanner_init(const char *str,
			 core_yy_extra_type *yyext,
			 const ScanKeyword *keywords,
			 int num_keywords)
{
	Size		slen = strlen(str);
	yyscan_t	scanner;

	if (yylex_init(&scanner) != 0)
	  yyerror("yylex_init() failed");

	yyset_extra(yyext, scanner);

	yyext->keywords = keywords;
	yyext->num_keywords = num_keywords;

	/*
	 * Make a scan buffer with special termination needed by flex.
	 */
	yyext->scanbuf = (char *) malloc(slen + 2);
	yyext->scanbuflen = slen;
	memcpy(yyext->scanbuf, str, slen);
	yyext->scanbuf[slen] = yyext->scanbuf[slen + 1] = YY_END_OF_BUFFER_CHAR;
	yy_scan_buffer(yyext->scanbuf, slen + 2, scanner);

	/* initialize literal buffer to a reasonable but expansible size */
	yyext->literalalloc = 1024;
	yyext->literalbuf = (char *) malloc(yyext->literalalloc);
	yyext->literallen = 0;

	return scanner;
}


/*
 * Called after parsing is done to clean up after scanner_init()
 */
void
scanner_finish(core_yyscan_t yyscanner)
{
	/*
	 * We don't bother to call yylex_destroy(), because all it would do is
	 * pfree a small amount of control storage.  It's cheaper to leak the
	 * storage until the parsing context is destroyed.  The amount of space
	 * involved is usually negligible compared to the output parse tree
	 * anyway.
	 *
	 * We do bother to pfree the scanbuf and literal buffer, but only if they
	 * represent a nontrivial amount of space.  The 8K cutoff is arbitrary.
	 */
	if (yyextra->scanbuflen >= 8192)
		free(yyextra->scanbuf);
	if (yyextra->literalalloc >= 8192)
		free(yyextra->literalbuf);
}



static void
addlit(char *ytext, int yleng, core_yyscan_t yyscanner)
{
	/* enlarge buffer if needed */
	if ((yyextra->literallen + yleng) >= yyextra->literalalloc)
	{
		do
		{
			yyextra->literalalloc *= 2;
		} while ((yyextra->literallen + yleng) >= yyextra->literalalloc);
		yyextra->literalbuf = (char *) realloc(yyextra->literalbuf,
												yyextra->literalalloc);
	}
	/* append new data */
	memcpy(yyextra->literalbuf + yyextra->literallen, ytext, yleng);
	yyextra->literallen += yleng;
}

static char *
litbufdup(core_yyscan_t yyscanner)
{
	int			llen = yyextra->literallen;
	char	   *new;

	new = malloc(llen + 1);
	memcpy(new, yyextra->literalbuf, llen);
	new[llen] = '\0';
	return new;
}

static void
addlitchar(unsigned char ychar, core_yyscan_t yyscanner)
{
	/* enlarge buffer if needed */
	if ((yyextra->literallen + 1) >= yyextra->literalalloc)
	{
		yyextra->literalalloc *= 2;
		yyextra->literalbuf = (char *) realloc(yyextra->literalbuf,
												yyextra->literalalloc);
	}
	/* append new data */
	yyextra->literalbuf[yyextra->literallen] = ychar;
	yyextra->literallen += 1;
}

void
scanner_yyerror(const char *message, core_yyscan_t yyscanner)
{
  fprintf(stderr, "%s", message);
}


