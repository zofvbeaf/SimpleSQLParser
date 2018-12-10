#pragma once

#include "nodes/keywords.h"

typedef void *core_yyscan_t;

typedef size_t Size;

typedef union core_YYSTYPE
{
	int			ival;			/* for integer literals */
	char	   *str;			/* for identifiers and non-integer literals */
	const char *keyword;		/* canonical spelling of keywords */
} core_YYSTYPE;


typedef struct core_yy_extra_type
{
	char	   *scanbuf;
	Size		scanbuflen;
	/*
	 * The keyword list to use.
	 */
	const ScanKeyword *keywords;
	int			num_keywords;

	/*
	 * literalbuf is used to accumulate literal values when multiple rules are
	 * needed to parse a single literal.  Call startlit() to reset buffer to
	 * empty, addlit() to add text.  NOTE: the string in literalbuf is NOT
	 * necessarily null-terminated, but there always IS room to add a trailing
	 * null at offset literallen.  We store a null only when we need it.
	 */
	char	   *literalbuf;		/* palloc'd expandable buffer */
	int			literallen;		/* actual current string length */
	int			literalalloc;	/* current allocated buffer size */

} core_yy_extra_type;

extern core_yyscan_t scanner_init(const char *str,
			 core_yy_extra_type *yyext,
			 const ScanKeyword *keywords,
			 int num_keywords);
extern void scanner_finish(core_yyscan_t yyscanner);
extern void scanner_yyerror(const char *message, core_yyscan_t yyscanner);
//extern int yylex(core_YYSTYPE *lvalp, core_yyscan_t yyscanner);

