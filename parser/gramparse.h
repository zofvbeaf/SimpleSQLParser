#ifndef GRAMPARSE_H
#define GRAMPARSE_H

#include "nodes/parsenodes.h"
#include "nodes/datetime.h"
#include "parser/scanner.h"
#include "nodes/makefuncs.h"
#include "nodes/nodes.h"

#include "sql_parser.tab.h"

/*
 * The YY_EXTRA data that a flex scanner allows us to pass around.  Private
 * state needed for raw parsing/lexing goes here.
 */
typedef struct base_yy_extra_type
{
	/*
	 * Fields used by the core scanner.
	 */
	core_yy_extra_type core_yy_extra;
  core_YYSTYPE lookahead_yylval;
	/*
	 * State variables that belong to the grammar.
	 */
	List	   *parsetree;		/* final parse result is delivered here */
} base_yy_extra_type;

/*
 * In principle we should use yyget_extra() to fetch the yyextra field
 * from a yyscanner struct.  However, flex always puts that field first,
 * and this is sufficiently performance-critical to make it seem worth
 * cheating a bit to use an inline macro.
 */
#define pg_yyget_extra(yyscanner) (*((base_yy_extra_type **) (yyscanner)))


/* from parser.c */
extern int base_yylex(YYSTYPE *lvalp, core_yyscan_t yyscanner);

/* from gram.y */
extern void parser_init(base_yy_extra_type *yyext);
extern int	yyparse(core_yyscan_t yyscanner);

#endif							/* GRAMPARSE_H */
