#pragma once

#include "nodes/nodes.h"
#include "nodes/list.h"
#include "nodes/value.h"
#include "nodes/primnodes.h"

typedef struct A_Star
{
	NodeTag		type;
} A_Star;

typedef struct FuncCall
{
	NodeTag		type;
	List	   *funcname;		/* qualified name of function */
	List	   *args;			/* the arguments (list of exprs) */
	List	   *agg_order;		/* ORDER BY (list of SortBy) */
	Node	   *agg_filter;		/* FILTER clause, if any */
	bool		agg_within_group;	/* ORDER BY appeared in WITHIN GROUP */
	bool		agg_star;		/* argument was really '*' */
	bool		agg_distinct;	/* arguments were labeled DISTINCT */
	struct WindowDef *over;		/* OVER clause, if any */
} FuncCall;



typedef struct TypeName
{
	NodeTag		type;
	List	   *names;			/* qualified name (list of Value strings) */
	List	   *typmods;		/* type modifier expression(s) */
} TypeName;

typedef struct ColumnRef
{
	NodeTag		type;
	List	   *fields;			/* field names (Value strings) or A_Star */
} ColumnRef;

typedef enum A_Expr_Kind
{
	AEXPR_OP,					/* normal operator */
	AEXPR_OP_ANY,				/* scalar op ANY (array) */
	AEXPR_OP_ALL,				/* scalar op ALL (array) */
	AEXPR_DISTINCT,				/* IS DISTINCT FROM - name must be "=" */
	AEXPR_NOT_DISTINCT,			/* IS NOT DISTINCT FROM - name must be "=" */
	AEXPR_NULLIF,				/* NULLIF - name must be "=" */
	AEXPR_OF,					/* IS [NOT] OF - name must be "=" or "<>" */
	AEXPR_IN,					/* [NOT] IN - name must be "=" or "<>" */
	AEXPR_LIKE,					/* [NOT] LIKE - name must be "~~" or "!~~" */
	AEXPR_ILIKE,				/* [NOT] ILIKE - name must be "~~*" or "!~~*" */
	AEXPR_SIMILAR,				/* [NOT] SIMILAR - name must be "~" or "!~" */
	AEXPR_BETWEEN,				/* name must be "BETWEEN" */
	AEXPR_NOT_BETWEEN,			/* name must be "NOT BETWEEN" */
	AEXPR_BETWEEN_SYM,			/* name must be "BETWEEN SYMMETRIC" */
	AEXPR_NOT_BETWEEN_SYM,		/* name must be "NOT BETWEEN SYMMETRIC" */
	AEXPR_PAREN					/* nameless dummy node for parentheses */
} A_Expr_Kind;

typedef struct A_Expr
{
	NodeTag		type;
	A_Expr_Kind kind;			/* see above */
	List	   *name;			/* possibly-qualified name of operator */
	Node	   *lexpr;			/* left argument, or NULL if none */
	Node	   *rexpr;			/* right argument, or NULL if none */
} A_Expr;

typedef enum SortByDir
{
	SORTBY_DEFAULT,
	SORTBY_ASC,
	SORTBY_DESC
} SortByDir;

typedef struct SortBy
{
	NodeTag		type;
	Node	   *node;			/* expression to sort on */
	SortByDir	sortby_dir;		/* ASC/DESC/USING/default */
} SortBy;

/*
 * WindowDef - raw representation of WINDOW and OVER clauses
 *
 * For entries in a WINDOW list, "name" is the window name being defined.
 * For OVER clauses, we use "name" for the "OVER window" syntax, or "refname"
 * for the "OVER (window)" syntax, which is subtly different --- the latter
 * implies overriding the window frame clause.
 */
typedef struct WindowDef
{
	NodeTag		type;
	char	   *name;			/* window's own name */
	char	   *refname;		/* referenced window name, if any */
	List	   *partitionClause;	/* PARTITION BY expression list */
	List	   *orderClause;	/* ORDER BY (list of SortBy) */
	int			frameOptions;	/* frame_clause options, see below */
	Node	   *startOffset;	/* expression for starting bound, if any */
	Node	   *endOffset;		/* expression for ending bound, if any */
} WindowDef;

/*
 * frameOptions is an OR of these bits.  The NONDEFAULT and BETWEEN bits are
 * used so that ruleutils.c can tell which properties were specified and
 * which were defaulted; the correct behavioral bits must be set either way.
 * The START_foo and END_foo options must come in pairs of adjacent bits for
 * the convenience of gram.y, even though some of them are useless/invalid.
 */
#define FRAMEOPTION_NONDEFAULT					0x00001 /* any specified? */
#define FRAMEOPTION_RANGE						0x00002 /* RANGE behavior */
#define FRAMEOPTION_ROWS						0x00004 /* ROWS behavior */
#define FRAMEOPTION_GROUPS						0x00008 /* GROUPS behavior */
#define FRAMEOPTION_BETWEEN						0x00010 /* BETWEEN given? */
#define FRAMEOPTION_START_UNBOUNDED_PRECEDING	0x00020 /* start is U. P. */
#define FRAMEOPTION_END_UNBOUNDED_PRECEDING		0x00040 /* (disallowed) */
#define FRAMEOPTION_START_UNBOUNDED_FOLLOWING	0x00080 /* (disallowed) */
#define FRAMEOPTION_END_UNBOUNDED_FOLLOWING		0x00100 /* end is U. F. */
#define FRAMEOPTION_START_CURRENT_ROW			0x00200 /* start is C. R. */
#define FRAMEOPTION_END_CURRENT_ROW				0x00400 /* end is C. R. */
#define FRAMEOPTION_START_OFFSET_PRECEDING		0x00800 /* start is O. P. */
#define FRAMEOPTION_END_OFFSET_PRECEDING		0x01000 /* end is O. P. */
#define FRAMEOPTION_START_OFFSET_FOLLOWING		0x02000 /* start is O. F. */
#define FRAMEOPTION_END_OFFSET_FOLLOWING		0x04000 /* end is O. F. */
#define FRAMEOPTION_EXCLUDE_CURRENT_ROW			0x08000 /* omit C.R. */
#define FRAMEOPTION_EXCLUDE_GROUP				0x10000 /* omit C.R. & peers */
#define FRAMEOPTION_EXCLUDE_TIES				0x20000 /* omit C.R.'s peers */

#define FRAMEOPTION_START_OFFSET \
	(FRAMEOPTION_START_OFFSET_PRECEDING | FRAMEOPTION_START_OFFSET_FOLLOWING)
#define FRAMEOPTION_END_OFFSET \
	(FRAMEOPTION_END_OFFSET_PRECEDING | FRAMEOPTION_END_OFFSET_FOLLOWING)
#define FRAMEOPTION_EXCLUSION \
	(FRAMEOPTION_EXCLUDE_CURRENT_ROW | FRAMEOPTION_EXCLUDE_GROUP | \
	 FRAMEOPTION_EXCLUDE_TIES)

#define FRAMEOPTION_DEFAULTS \
	(FRAMEOPTION_RANGE | FRAMEOPTION_START_UNBOUNDED_PRECEDING | \
	 FRAMEOPTION_END_CURRENT_ROW)

typedef struct A_Const
{
	NodeTag		type;
	Value		val;			/* value (includes type info, see value.h) */
} A_Const;

typedef struct TypeCast
{
	NodeTag		type;
	Node	   *arg;			/* the expression being casted */
	TypeName   *typeName;		/* the target type */
} TypeCast;

typedef struct ResTarget
{
	NodeTag		type;
	char	   *name;			/* column name or NULL */
	Node	   *val;			/* the value expression to compute or assign */
} ResTarget;

typedef struct WithClause
{
	NodeTag		type;
	List	   *ctes;			/* list of CommonTableExprs */
	bool		recursive;		/* true = WITH RECURSIVE */
} WithClause;

typedef enum SetOperation
{
	SETOP_NONE = 0,
	SETOP_UNION,
	SETOP_INTERSECT,
	SETOP_EXCEPT
} SetOperation;

typedef enum ObjectType
{
	OBJECT_ACCESS_METHOD,
	OBJECT_AGGREGATE,
	OBJECT_AMOP,
	OBJECT_AMPROC,
	OBJECT_ATTRIBUTE,			/* type's attribute, when distinct from column */
	OBJECT_CAST,
	OBJECT_COLUMN,
	OBJECT_COLLATION,
	OBJECT_CONVERSION,
	OBJECT_DATABASE,
	OBJECT_DEFAULT,
	OBJECT_DEFACL,
	OBJECT_DOMAIN,
	OBJECT_DOMCONSTRAINT,
	OBJECT_EVENT_TRIGGER,
	OBJECT_EXTENSION,
	OBJECT_FDW,
	OBJECT_FOREIGN_SERVER,
	OBJECT_FOREIGN_TABLE,
	OBJECT_FUNCTION,
	OBJECT_INDEX,
	OBJECT_LANGUAGE,
	OBJECT_LARGEOBJECT,
	OBJECT_MATVIEW,
	OBJECT_OPCLASS,
	OBJECT_OPERATOR,
	OBJECT_OPFAMILY,
	OBJECT_POLICY,
	OBJECT_PROCEDURE,
	OBJECT_PUBLICATION,
	OBJECT_PUBLICATION_REL,
	OBJECT_ROLE,
	OBJECT_ROUTINE,
	OBJECT_RULE,
	OBJECT_SCHEMA,
	OBJECT_SEQUENCE,
	OBJECT_SUBSCRIPTION,
	OBJECT_STATISTIC_EXT,
	OBJECT_TABCONSTRAINT,
	OBJECT_TABLE,
	OBJECT_TABLESPACE,
	OBJECT_TRANSFORM,
	OBJECT_TRIGGER,
	OBJECT_TSCONFIGURATION,
	OBJECT_TSDICTIONARY,
	OBJECT_TSPARSER,
	OBJECT_TSTEMPLATE,
	OBJECT_TYPE,
	OBJECT_USER_MAPPING,
	OBJECT_VIEW
} ObjectType;



typedef struct RawStmt
{
	NodeTag		type;
	Node	   *stmt;			/* raw parse tree */
} RawStmt;


typedef struct ViewStmt
{
	NodeTag		type;
	RangeVar   *view;			/* the view to be created */
	List	   *aliases;		/* target column names */
	Node	   *query;			/* the SELECT query (as a raw parse tree) */
} ViewStmt;

typedef struct DropStmt
{
	NodeTag		type;
	List	   *objects;		/* list of names */
	ObjectType	removeType;		/* object type */
} DropStmt;


typedef struct SelectStmt
{
	NodeTag		type;

	/*
	 * These fields are used only in "leaf" SelectStmts.
	 */
	List	   *distinctClause; /* NULL, list of DISTINCT ON exprs, or
								 * lcons(NIL,NIL) for all (SELECT DISTINCT) */
	List	   *targetList;		/* the target list (of ResTarget) */
	List	   *fromClause;		/* the FROM clause */
	Node	   *whereClause;	/* WHERE qualification */
	List	   *groupClause;	/* GROUP BY clauses */
	Node	   *havingClause;	/* HAVING conditional-expression */

	/*
	 * These fields are used in both "leaf" SelectStmts and upper-level
	 * SelectStmts.
	 */
	List	   *sortClause;		/* sort clause (a list of SortBy's) */
	Node	   *limitOffset;	/* # of result tuples to skip */
	Node	   *limitCount;		/* # of result tuples to return */
	WithClause *withClause;		/* WITH clause */

	/*
	 * These fields are used only in upper-level SelectStmts.
	 */
	SetOperation op;			/* type of set op */
	bool		all;			/* ALL specified? */
	struct SelectStmt *larg;	/* left child */
	struct SelectStmt *rarg;	/* right child */
	/* Eventually add fields for CORRESPONDING spec here */
} SelectStmt;

typedef struct RangeSubselect
{
	NodeTag		type;
	bool		lateral;		/* does it have LATERAL prefix? */
	Node	   *subquery;		/* the untransformed sub-select clause */
	Alias	   *alias;			/* table alias & optional column aliases */
} RangeSubselect;

typedef enum
{
	GROUPING_SET_EMPTY,
	GROUPING_SET_SIMPLE,
	GROUPING_SET_ROLLUP,
	GROUPING_SET_CUBE,
	GROUPING_SET_SETS
} GroupingSetKind;

typedef struct GroupingSet
{
	NodeTag		type;
	GroupingSetKind kind;
	List	   *content;
} GroupingSet;

typedef struct CommonTableExpr
{
	NodeTag		type;
	char	   *ctename;		/* query name (never qualified) */
	List	   *aliascolnames;	/* optional list of column names */
	/* SelectStmt/InsertStmt/etc before parse analysis, Query afterwards: */
	Node	   *ctequery;		/* the CTE's subquery */
	/* These fields are set during parse analysis: */
	bool		cterecursive;	/* is this CTE actually recursive? */
	int			cterefcount;	/* number of RTEs referencing this CTE
								 * (excluding internal self-references) */
	List	   *ctecolnames;	/* list of output column names */
	List	   *ctecoltypes;	/* OID list of output column type OIDs */
	List	   *ctecoltypmods;	/* integer list of output column typmods */
	List	   *ctecolcollations;	/* OID list of column collation OIDs */
} CommonTableExpr;


