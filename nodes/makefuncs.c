#include "nodes/makefuncs.h"

A_Expr *
makeA_Expr(A_Expr_Kind kind, List *name,
		   Node *lexpr, Node *rexpr)
{
	A_Expr	   *a = makeNode(A_Expr);

	a->kind = kind;
	a->name = name;
	a->lexpr = lexpr;
	a->rexpr = rexpr;
	return a;
}

TypeName *
makeTypeName(char *typnam)
{
	return makeTypeNameFromNameList(list_make1(makeString(typnam)));
}

TypeName *
makeTypeNameFromNameList(List *names)
{
	TypeName   *n = makeNode(TypeName);
	n->names = names;
	return n;
}

FuncCall *
makeFuncCall(List *name, List *args)
{
	FuncCall   *n = makeNode(FuncCall);

	n->funcname = name;
	n->args = args;
	n->agg_order = NIL;
	n->agg_filter = NULL;
	n->agg_within_group = false;
	n->agg_star = false;
	n->agg_distinct = false;
	n->over = NULL;
	return n;
}

A_Expr *
makeSimpleA_Expr(A_Expr_Kind kind, char *name,
				 Node *lexpr, Node *rexpr)
{
	A_Expr	   *a = makeNode(A_Expr);

	a->kind = kind;
	a->name = list_make1(makeString((char *) name));
	a->lexpr = lexpr;
	a->rexpr = rexpr;
	return a;
}

Expr *
makeBoolExpr(BoolExprType boolop, List *args)
{
	BoolExpr   *b = makeNode(BoolExpr);

	b->boolop = boolop;
	b->args = args;

	return (Expr *) b;
}

RangeVar *
makeRangeVar(char *schemaname, char *relname)
{
	RangeVar   *r = makeNode(RangeVar);

	r->catalogname = NULL;
	r->schemaname = schemaname;
	r->relname = relname;
	r->inh = true;
	r->alias = NULL;

	return r;
}

GroupingSet *
makeGroupingSet(GroupingSetKind kind, List *content)
{
	GroupingSet *n = makeNode(GroupingSet);

	n->kind = kind;
	n->content = content;
	return n;
}
