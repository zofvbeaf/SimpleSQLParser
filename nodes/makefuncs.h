#ifndef MAKEFUNC_H
#define MAKEFUNC_H

#include "nodes/nodes.h"
#include "nodes/list.h"
#include "nodes/parsenodes.h"
#include "nodes/primnodes.h"

extern A_Expr *makeA_Expr(A_Expr_Kind kind, List *name,
		   Node *lexpr, Node *rexpr);

extern A_Expr *makeSimpleA_Expr(A_Expr_Kind kind, char *name,
				 Node *lexpr, Node *rexpr);

extern TypeName *makeTypeName(char *typnam);
extern TypeName *makeTypeNameFromNameList(List *names);
extern FuncCall *makeFuncCall(List *name, List *args);
extern Expr *makeBoolExpr(BoolExprType boolop, List *args);
extern RangeVar *makeRangeVar(char *schemaname, char *relname);
extern GroupingSet *makeGroupingSet(GroupingSetKind kind, List *content);

#endif							/* MAKEFUNC_H */
