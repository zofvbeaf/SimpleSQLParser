#pragma once

typedef struct Expr
{
	NodeTag		type;
} Expr;

typedef struct NamedArgExpr
{
	Expr		xpr;
	Expr	   *arg;			/* the argument expression */
	char	   *name;			/* the name */
} NamedArgExpr;

typedef struct CaseExpr
{
	Expr		xpr;
	Expr	   *arg;			/* implicit equality comparison argument */
	List	   *args;			/* the arguments (list of WHEN clauses) */
	Expr	   *defresult;		/* the default result (ELSE clause) */
} CaseExpr;

/*
 * CaseWhen - one arm of a CASE expression
 */
typedef struct CaseWhen
{
	Expr		xpr;
	Expr	   *expr;			/* condition expression */
	Expr	   *result;			/* substitution result */
} CaseWhen;

typedef struct CoalesceExpr
{
	Expr		xpr;
	List	   *args;			/* the arguments */
} CoalesceExpr;

typedef enum BoolExprType
{
	AND_EXPR, OR_EXPR, NOT_EXPR
} BoolExprType;

typedef struct BoolExpr
{
	Expr		xpr;
	BoolExprType boolop;
	List	   *args;			/* arguments to this expression */
} BoolExpr;

typedef enum SubLinkType
{
	EXISTS_SUBLINK,
	ALL_SUBLINK,
	ANY_SUBLINK,
	ROWCOMPARE_SUBLINK,
	EXPR_SUBLINK,
	MULTIEXPR_SUBLINK,
	ARRAY_SUBLINK,
	CTE_SUBLINK					/* for SubPlans only */
} SubLinkType;


typedef struct SubLink
{
	Expr		xpr;
	SubLinkType subLinkType;	/* see above */
	Node	   *testexpr;		/* outer-query test for ALL/ANY/ROWCOMPARE */
	List	   *operName;		/* originally specified operator name */
	Node	   *subselect;		/* subselect as Query* or raw parsetree */
} SubLink;

typedef struct GroupingFunc
{
	Expr		xpr;
	List	   *args;			/* arguments, not evaluated but kept for
								 * benefit of EXPLAIN etc. */
	List	   *refs;			/* ressortgrouprefs of arguments */
	List	   *cols;			/* actual column positions set by planner */
} GroupingFunc;

typedef enum NullTestType
{
	IS_NULL, IS_NOT_NULL
} NullTestType;

typedef struct NullTest
{
	Expr		xpr;
	Expr	   *arg;			/* input expression */
	NullTestType nulltesttype;	/* IS NULL, IS NOT NULL */
} NullTest;

typedef struct Alias
{
	NodeTag		type;
	char	   *aliasname;		/* aliased rel name (never qualified) */
	List	   *colnames;		/* optional list of column aliases */
} Alias;

typedef struct RangeVar
{
	NodeTag		type;
	char	   *catalogname;	/* the catalog (database) name, or NULL */
	char	   *schemaname;		/* the schema name, or NULL */
	char	   *relname;		/* the relation/sequence name */
	bool		inh;			/* expand rel by inheritance? recursively act
								 * on children? */
	Alias	   *alias;			/* table alias & optional column aliases */
} RangeVar;

typedef struct FromExpr
{
	NodeTag		type;
	List	   *fromlist;		/* List of join subtrees */
	Node	   *quals;			/* qualifiers on join, if any */
} FromExpr;

typedef struct JoinExpr
{
	NodeTag		type;
	JoinType	jointype;		/* type of join */
	bool		isNatural;		/* Natural join? Will need to shape table */
	Node	   *larg;			/* left subtree */
	Node	   *rarg;			/* right subtree */
	List	   *usingClause;	/* USING clause, if any (list of String) */
	Node	   *quals;			/* qualifiers on join, if any */
	Alias	   *alias;			/* user-written alias clause, if any */
	int			rtindex;		/* RT index assigned for join, or 0 */
} JoinExpr;


