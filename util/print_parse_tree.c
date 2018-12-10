#include "nodes/list.h"
#include "util/stringinfo.h"
#include "nodes/value.h"
#include "nodes/nodes.h"
#include "nodes/primnodes.h"
#include "nodes/parsenodes.h"

#include <stdlib.h>
#include <stdio.h>

static void _outNode(StringInfo str, const void *obj);

#define CppAsString(identifier) #identifier

#define booltostr(x)	((x) ? "true" : "false")

#ifndef NULL
#define NULL  ((void *) 0)
#endif

/* Write the label for the node type */
#define WRITE_NODE_TYPE(nodelabel) \
	appendStringInfoString(str, "\"" nodelabel "\": {")

/* Write an integer field */
#define WRITE_INT_FIELD(fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": %d, ", node->fldname); \
	}

#define WRITE_INT_VALUE(fldname, value) \
	if (value != 0) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": %d, ", value); \
	}

/* Write an unsigned integer field */
#define WRITE_UINT_FIELD(fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": %u, ", node->fldname); \
	}

/* Write a long-integer field */
#define WRITE_LONG_FIELD(fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": %ld, ", node->fldname); \
	}

/* Write a char field (ie, one ascii character) */
#define WRITE_CHAR_FIELD(fldname) \
	if (node->fldname != 0) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": \"%c\", ", node->fldname); \
	}

/* Write an enumerated-type field as an integer code */
#define WRITE_ENUM_FIELD(fldname) \
	appendStringInfo(str, "\"" CppAsString(fldname) "\": %d, ", \
					 (int) node->fldname)

/* Write a float field */
#define WRITE_FLOAT_FIELD(fldname) \
	appendStringInfo(str, "\"" CppAsString(fldname) "\": %f, ", node->fldname)

/* Write a boolean field */
#define WRITE_BOOL_FIELD(fldname) \
	if (node->fldname) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": %s, ", \
					 	booltostr(node->fldname)); \
	}

/* Write a character-string (possibly NULL) field */
#define WRITE_STRING_FIELD(fldname) \
	if (node->fldname != NULL) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": "); \
	 	_outToken(str, node->fldname); \
	 	appendStringInfo(str, ", "); \
	}

#define WRITE_STRING_VALUE(fldname, value) \
	if (true) { \
		appendStringInfo(str, "\"" CppAsString(fldname) "\": "); \
	 	_outToken(str, value); \
	 	appendStringInfo(str, ", "); \
	}


static void
removeTrailingDelimiter(StringInfo str)
{
	if (str->len >= 2 && str->data[str->len - 2] == ',' && str->data[str->len - 1] == ' ') {
		str->len -= 2;
		str->data[str->len] = '\0';
	} else if (str->len >= 1 && str->data[str->len - 1] == ',') {
		str->len -= 1;
		str->data[str->len] = '\0';
	}
}

static void
_outToken(StringInfo buf, const char *str)
{
	if (str == NULL)
	{
		appendStringInfoString(buf, "null");
		return;
	}

	const char *p;

	appendStringInfoCharMacro(buf, '"');
	for (p = str; *p; p++)
	{
		switch (*p)
		{
			case '\b':
				appendStringInfoString(buf, "\\b");
				break;
			case '\f':
				appendStringInfoString(buf, "\\f");
				break;
			case '\n':
				appendStringInfoString(buf, "\\n");
				break;
			case '\r':
				appendStringInfoString(buf, "\\r");
				break;
			case '\t':
				appendStringInfoString(buf, "\\t");
				break;
			case '"':
				appendStringInfoString(buf, "\\\"");
				break;
			case '\\':
				appendStringInfoString(buf, "\\\\");
				break;
			default:
				if ((unsigned char) *p < ' ')
					appendStringInfo(buf, "\\u%04x", (int) *p);
				else
					appendStringInfoCharMacro(buf, *p);
				break;
		}
	}
	appendStringInfoCharMacro(buf, '"');
}


#define WRITE_NODE_FIELD(fldname) \
	if (true) { \
		 appendStringInfo(str, "\"" CppAsString(fldname) "\": "); \
	     _outNode(str, &node->fldname); \
		 appendStringInfo(str, ", "); \
  	}

#define WRITE_NODE_FIELD_WITH_TYPE(fldname, typename) \
	if (true) { \
		 appendStringInfo(str, "\"" CppAsString(fldname) "\": {"); \
	   	 _out##typename(str, (const typename *) &node->fldname); \
		 removeTrailingDelimiter(str); \
 		 appendStringInfo(str, "}}, "); \
	}

#define WRITE_NODE_PTR_FIELD(fldname) \
	if (node->fldname != NULL) { \
		 appendStringInfo(str, "\"" CppAsString(fldname) "\": "); \
		 _outNode(str, node->fldname); \
		 appendStringInfo(str, ", "); \
	}

static void
_outList(StringInfo str, const List *node)
{
	const ListCell *lc;

	// Simple lists are frequent structures - we don't make them into full nodes to avoid super-verbose output
	appendStringInfoChar(str, '[');

	foreach(lc, node)
	{
		_outNode(str, lfirst(lc));

		if (lnext(lc))
			appendStringInfoString(str, ", ");
	}

	appendStringInfoChar(str, ']');
}

static void
_outIntList(StringInfo str, const List *node)
{
	const ListCell *lc;

	WRITE_NODE_TYPE("IntList");
	appendStringInfo(str, "\"items\": ");
	appendStringInfoChar(str, '[');

	foreach(lc, node)
	{
		appendStringInfo(str, " %d", lfirst_int(lc));

		if (lnext(lc))
			appendStringInfoString(str, ", ");
	}

	appendStringInfoChar(str, ']');
	appendStringInfo(str, ", ");
}

static void
_outOidList(StringInfo str, const List *node)
{
	const ListCell *lc;

	WRITE_NODE_TYPE("OidList");
	appendStringInfo(str, "\"items\": ");
	appendStringInfoChar(str, '[');

	foreach(lc, node)
	{
		appendStringInfo(str, " %u", lfirst_oid(lc));

		if (lnext(lc))
			appendStringInfoString(str, ", ");
	}

	appendStringInfoChar(str, ']');
	appendStringInfo(str, ", ");
}

static void
_outInteger(StringInfo str, const Value *node)
{
	WRITE_NODE_TYPE("Integer");
	appendStringInfo(str, "\"ival\": %ld, ", node->val.ival);
}

static void
_outFloat(StringInfo str, const Value *node)
{
	WRITE_NODE_TYPE("Float");
	appendStringInfo(str, "\"str\": ");
	_outToken(str, node->val.str);
	appendStringInfo(str, ", ");
}

static void
_outString(StringInfo str, const Value *node)
{
	WRITE_NODE_TYPE("String");
	appendStringInfo(str, "\"str\": ");
	_outToken(str, node->val.str);
	appendStringInfo(str, ", ");
}

static void
_outBitString(StringInfo str, const Value *node)
{
	WRITE_NODE_TYPE("BitString");
	appendStringInfo(str, "\"str\": ");
	_outToken(str, node->val.str);
	appendStringInfo(str, ", ");
}

static void
_outNull(StringInfo str, const Value *node)
{
	WRITE_NODE_TYPE("Null");
}

static void
_outA_Star(StringInfo str, const A_Star *node)
{
  WRITE_NODE_TYPE("A_Star");
}

static void
_outFuncCall(StringInfo str, const FuncCall *node)
{
  WRITE_NODE_TYPE("FuncCall");

  WRITE_NODE_PTR_FIELD(funcname);
  WRITE_NODE_PTR_FIELD(args);
  WRITE_NODE_PTR_FIELD(agg_order);
  WRITE_NODE_PTR_FIELD(agg_filter);
  WRITE_BOOL_FIELD(agg_within_group);
  WRITE_BOOL_FIELD(agg_star);
  WRITE_BOOL_FIELD(agg_distinct);
  WRITE_NODE_PTR_FIELD(over);
}

static void
_outTypeName(StringInfo str, const TypeName *node)
{
  WRITE_NODE_TYPE("TypeName");
  WRITE_NODE_PTR_FIELD(names);
  WRITE_NODE_PTR_FIELD(typmods);
}

static void
_outColumnRef(StringInfo str, const ColumnRef *node)
{
  WRITE_NODE_TYPE("ColumnRef");

  WRITE_NODE_PTR_FIELD(fields);
}

static void
_outA_Expr(StringInfo str, const A_Expr *node)
{
  WRITE_NODE_TYPE("A_Expr");

  WRITE_ENUM_FIELD(kind);
  WRITE_NODE_PTR_FIELD(name);
  WRITE_NODE_PTR_FIELD(lexpr);
  WRITE_NODE_PTR_FIELD(rexpr);
}

static void
_outSortBy(StringInfo str, const SortBy *node)
{
  WRITE_NODE_TYPE("SortBy");

  WRITE_NODE_PTR_FIELD(node);
  WRITE_ENUM_FIELD(sortby_dir);
}

static void
_outWindowDef(StringInfo str, const WindowDef *node)
{
  WRITE_NODE_TYPE("WindowDef");

  WRITE_STRING_FIELD(name);
  WRITE_STRING_FIELD(refname);
  WRITE_NODE_PTR_FIELD(partitionClause);
  WRITE_NODE_PTR_FIELD(orderClause);
  WRITE_INT_FIELD(frameOptions);
  WRITE_NODE_PTR_FIELD(startOffset);
  WRITE_NODE_PTR_FIELD(endOffset);
}

static void
_outA_Const(StringInfo str, const A_Const *node)
{
  WRITE_NODE_TYPE("A_Const");

  WRITE_NODE_FIELD(val);
}

static void
_outTypeCast(StringInfo str, const TypeCast *node)
{
  WRITE_NODE_TYPE("TypeCast");

  WRITE_NODE_PTR_FIELD(arg);
  WRITE_NODE_PTR_FIELD(typeName);
}

static void
_outResTarget(StringInfo str, const ResTarget *node)
{
  WRITE_NODE_TYPE("ResTarget");

  WRITE_STRING_FIELD(name);
  WRITE_NODE_PTR_FIELD(val);
}

static void
_outWithClause(StringInfo str, const WithClause *node)
{
  WRITE_NODE_TYPE("WithClause");

  WRITE_NODE_PTR_FIELD(ctes);
  WRITE_BOOL_FIELD(recursive);
}

static void
_outRawStmt(StringInfo str, const RawStmt *node)
{
  WRITE_NODE_TYPE("RawStmt");

  WRITE_NODE_PTR_FIELD(stmt);
}



static void
_outSelectStmt(StringInfo str, const SelectStmt *node)
{
  WRITE_NODE_TYPE("SelectStmt");

  WRITE_NODE_PTR_FIELD(distinctClause);
  WRITE_NODE_PTR_FIELD(targetList);
  WRITE_NODE_PTR_FIELD(fromClause);
  WRITE_NODE_PTR_FIELD(whereClause);
  WRITE_NODE_PTR_FIELD(groupClause);
  WRITE_NODE_PTR_FIELD(havingClause);
  WRITE_NODE_PTR_FIELD(sortClause);
  WRITE_NODE_PTR_FIELD(limitOffset);
  WRITE_NODE_PTR_FIELD(limitCount);
  WRITE_NODE_PTR_FIELD(withClause);
  WRITE_ENUM_FIELD(op);
  WRITE_BOOL_FIELD(all);
  WRITE_NODE_PTR_FIELD(larg);
  WRITE_NODE_PTR_FIELD(rarg);
}

static void
_outRangeSubselect(StringInfo str, const RangeSubselect *node)
{
  WRITE_NODE_TYPE("RangeSubselect");

  WRITE_BOOL_FIELD(lateral);
  WRITE_NODE_PTR_FIELD(subquery);
  WRITE_NODE_PTR_FIELD(alias);
}

static void
_outGroupingSet(StringInfo str, const GroupingSet *node)
{
  WRITE_NODE_TYPE("GroupingSet");

  WRITE_ENUM_FIELD(kind);
  WRITE_NODE_PTR_FIELD(content);
}

static void
_outCommonTableExpr(StringInfo str, const CommonTableExpr *node)
{
  WRITE_NODE_TYPE("CommonTableExpr");

  WRITE_STRING_FIELD(ctename);
  WRITE_NODE_PTR_FIELD(aliascolnames);
  WRITE_NODE_PTR_FIELD(ctequery);
  WRITE_BOOL_FIELD(cterecursive);
  WRITE_INT_FIELD(cterefcount);
  WRITE_NODE_PTR_FIELD(ctecolnames);
  WRITE_NODE_PTR_FIELD(ctecoltypes);
  WRITE_NODE_PTR_FIELD(ctecoltypmods);
  WRITE_NODE_PTR_FIELD(ctecolcollations);
}

static void
_outViewStmt(StringInfo str, const ViewStmt *node)
{
  WRITE_NODE_TYPE("ViewStmt");

  WRITE_NODE_PTR_FIELD(view);
  WRITE_NODE_PTR_FIELD(aliases);
  WRITE_NODE_PTR_FIELD(query);
}

static void
_outDropStmt(StringInfo str, const DropStmt *node)
{
  WRITE_NODE_TYPE("DropStmt");

  WRITE_NODE_PTR_FIELD(objects);
  WRITE_ENUM_FIELD(removeType);
}



static void
_outNamedArgExpr(StringInfo str, const NamedArgExpr *node)
{
  WRITE_NODE_TYPE("NamedArgExpr");

  WRITE_NODE_PTR_FIELD(arg);
  WRITE_STRING_FIELD(name);
}

static void
_outCaseExpr(StringInfo str, const CaseExpr *node)
{
  WRITE_NODE_TYPE("CaseExpr");

  WRITE_NODE_PTR_FIELD(arg);
  WRITE_NODE_PTR_FIELD(args);
  WRITE_NODE_PTR_FIELD(defresult);
}

static void
_outCaseWhen(StringInfo str, const CaseWhen *node)
{
  WRITE_NODE_TYPE("CaseWhen");

  WRITE_NODE_PTR_FIELD(expr);
  WRITE_NODE_PTR_FIELD(result);
}

static void
_outCoalesceExpr(StringInfo str, const CoalesceExpr *node)
{
  WRITE_NODE_TYPE("CoalesceExpr");

  WRITE_NODE_PTR_FIELD(args);
}

static void
_outBoolExpr(StringInfo str, const BoolExpr *node)
{
  WRITE_NODE_TYPE("BoolExpr");

  WRITE_ENUM_FIELD(boolop);
  WRITE_NODE_PTR_FIELD(args);
}

static void
_outSubLink(StringInfo str, const SubLink *node)
{
  WRITE_NODE_TYPE("SubLink");

  WRITE_ENUM_FIELD(subLinkType);
  WRITE_NODE_PTR_FIELD(testexpr);
  WRITE_NODE_PTR_FIELD(operName);
  WRITE_NODE_PTR_FIELD(subselect);
}

static void
_outGroupingFunc(StringInfo str, const GroupingFunc *node)
{
  WRITE_NODE_TYPE("GroupingFunc");

  WRITE_NODE_PTR_FIELD(args);
  WRITE_NODE_PTR_FIELD(refs);
  WRITE_NODE_PTR_FIELD(cols);
}

static void
_outNullTest(StringInfo str, const NullTest *node)
{
  WRITE_NODE_TYPE("NullTest");

  WRITE_NODE_PTR_FIELD(arg);
  WRITE_ENUM_FIELD(nulltesttype);
}

static void
_outAlias(StringInfo str, const Alias *node)
{
  WRITE_NODE_TYPE("Alias");

  WRITE_STRING_FIELD(aliasname);
  WRITE_NODE_PTR_FIELD(colnames);
}

static void
_outRangeVar(StringInfo str, const RangeVar *node)
{
  WRITE_NODE_TYPE("RangeVar");

  WRITE_STRING_FIELD(schemaname);
  WRITE_STRING_FIELD(relname);
  WRITE_NODE_PTR_FIELD(alias);
}

static void
_outFromExpr(StringInfo str, const FromExpr *node)
{
  WRITE_NODE_TYPE("FromExpr");

  WRITE_NODE_PTR_FIELD(fromlist);
  WRITE_NODE_PTR_FIELD(quals);
}

static void
_outJoinExpr(StringInfo str, const JoinExpr *node)
{
  WRITE_NODE_TYPE("JoinExpr");

  WRITE_ENUM_FIELD(jointype);
  WRITE_BOOL_FIELD(isNatural);
  WRITE_NODE_PTR_FIELD(larg);
  WRITE_NODE_PTR_FIELD(rarg);
  WRITE_NODE_PTR_FIELD(usingClause);
  WRITE_NODE_PTR_FIELD(quals);
  WRITE_NODE_PTR_FIELD(alias);
  WRITE_INT_FIELD(rtindex);
}

static void
_outNode(StringInfo str, const void *obj)
{
	if (obj == NULL)
	{
		appendStringInfoString(str, "null");
	}
	else if (IsA(obj, List))
	{
		_outList(str, obj);
	}
	else
	{
		appendStringInfoChar(str, '{');
		switch (nodeTag(obj))
		{
			case T_Integer:
				_outInteger(str, obj);
				break;
			case T_Float:
				_outFloat(str, obj);
				break;
			case T_String:
				_outString(str, obj);
				break;
			case T_BitString:
				_outBitString(str, obj);
				break;
			case T_Null:
				_outNull(str, obj);
				break;
			case T_IntList:
				_outIntList(str, obj);
				break;
			case T_OidList:
				_outOidList(str, obj);
				break;
      case T_A_Star:
        _outA_Star(str, obj);
        break;
      case T_FuncCall:
        _outFuncCall(str, obj);
        break;
      case T_TypeName:
        _outTypeName(str, obj);
        break;
      case T_ColumnRef:
        _outColumnRef(str, obj);
        break;
      case T_A_Expr:
        _outA_Expr(str, obj);
        break;
      case T_SortBy:
        _outSortBy(str, obj);
        break;
      case T_WindowDef:
        _outWindowDef(str, obj);
        break;
      case T_A_Const:
        _outA_Const(str, obj);
        break;
      case T_TypeCast:
        _outTypeCast(str, obj);
        break;
      case T_ResTarget:
        _outResTarget(str, obj);
        break;
      case T_WithClause:
        _outWithClause(str, obj);
        break;
      case T_RawStmt:
        _outRawStmt(str, obj);
        break;
      case T_SelectStmt:
        _outSelectStmt(str, obj);
        break;
      case T_ViewStmt:
        _outViewStmt(str, obj);
        break;
      case T_DropStmt:
        _outDropStmt(str, obj);
        break;
      case T_RangeSubselect:
        _outRangeSubselect(str, obj);
        break;
      case T_GroupingSet:
        _outGroupingSet(str, obj);
        break;
      case T_CommonTableExpr:
        _outCommonTableExpr(str, obj);
        break;
      case T_NamedArgExpr:
        _outNamedArgExpr(str, obj);
        break;
      case T_CaseExpr:
        _outCaseExpr(str, obj);
        break;
      case T_CaseWhen:
        _outCaseWhen(str, obj);
        break;
      case T_CoalesceExpr:
        _outCoalesceExpr(str, obj);
        break;
      case T_BoolExpr:
        _outBoolExpr(str, obj);
        break;
      case T_SubLink:
        _outSubLink(str, obj);
        break;
      case T_GroupingFunc:
        _outGroupingFunc(str, obj);
        break;
      case T_NullTest:
        _outNullTest(str, obj);
        break;
      case T_Alias:
        _outAlias(str, obj);
        break;
      case T_RangeVar:
        _outRangeVar(str, obj);
        break;
      case T_FromExpr:
        _outFromExpr(str, obj);
        break;
      case T_JoinExpr:
        _outJoinExpr(str, obj);
        break;
			default:
			  fprintf(stderr, "could not dump unrecognized node type: %d", (int) nodeTag(obj));

				appendStringInfo(str, "}");
				return;
		}
		removeTrailingDelimiter(str);
		appendStringInfo(str, "}}");
	}
}

char *pg_query_nodes_to_json(const void *obj)
{
	StringInfoData str;

	initStringInfo(&str);

	if (obj == NULL) /* Make sure we generate valid JSON for empty queries */
		appendStringInfoString(&str, "[]");
	else
		_outNode(&str, obj);

	return str.data;
}

void print_pg_parse_tree(List* tree) {
  char* tree_json = pg_query_nodes_to_json(tree);
  printf("%s\n", tree_json);
  free(tree_json);
}

