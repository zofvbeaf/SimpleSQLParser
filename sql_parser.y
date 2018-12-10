%{
#include "nodes/list.h"
#include "nodes/nodes.h"
#include "nodes/parsenodes.h"
#include "nodes/primnodes.h"
#include "nodes/makefuncs.h"
#include "parser/gramparse.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define base_yyerror(msg)  scanner_yyerror(msg, yyscanner)
#define yyerror(yyscanner, msg) scanner_yyerror(msg, yyscanner)

static RawStmt *makeRawStmt(Node *stmt);

static Node *makeColumnRef(char *colname,  List *indirection, core_yyscan_t yyscanner);
static Node *makeTypeCast(Node *arg, TypeName *typename);
static Node *makeStringConst(char *str);
static Node *makeStringConstCast(char *str, TypeName *typename);
static Node *makeIntConst(int val);
static Node *makeFloatConst(char *str);
static Node *makeBitStringConst(char *str);
static Node *makeNullAConst();
static Node *makeAConst(Value *v);
static Node *makeBoolAConst(bool state);
static void insertSelectOptions(SelectStmt *stmt,
								List *sortClause, 
								Node *limitOffset, Node *limitCount,
								WithClause *withClause,
								core_yyscan_t yyscanner);
static Node *makeSetOp(SetOperation op, bool all, Node *larg, Node *rarg);
static List *check_indirection(List *indirection, core_yyscan_t yyscanner);
static Node *doNegate(Node *n);
static void doNegateFloat(Value *v);
static Node *makeAndExpr(Node *lexpr, Node *rexpr);
static Node *makeOrExpr(Node *lexpr, Node *rexpr);
static Node *makeNotExpr(Node *expr);
static TypeName *SystemTypeName(char *name);
static List *SystemFuncName(char *name);

char *psprintf(const char *fmt,...);

%}

%pure-parser
%expect 0

%parse-param {core_yyscan_t yyscanner}
%lex-param   {core_yyscan_t yyscanner}

%union
{
	core_YYSTYPE		core_yystype;
	int					ival;
	char				*str;
	const char			*keyword;

	bool				boolean;
	JoinType			jtype;
	List				*list;
	ObjectType			objtype;
	Node				*node;
	TypeName			*typnam;
	SortBy				*sortby;
	WindowDef			*windef;
	JoinExpr			*jexpr;
  Alias				*alias;
	RangeVar			*range;
	WithClause			*with;
	ResTarget			*target;
}

%type <node>	stmt SelectStmt PreparableStmt ViewStmt DropStmt

%type <node>  select_no_parens select_with_parens select_clause simple_select 

%type <ival>	opt_asc_desc 
%type <str>		name attr_name 

%type <list>	func_name qual_Op subquery_Op

%type <range>	qualified_name 

%type <objtype>	drop_type_any_name 

%type <str>		all_Op MathOp

%type <list>	stmtblock stmtmulti distinct_clause opt_all_clause opt_name_list
				      sort_clause opt_sort_clause sortby_list name_list 
				      from_clause from_list expr_list attrs indirection 
              opt_target_list target_list group_clause select_limit
              group_by_list opt_type_modifiers opt_column_list columnList 
              any_name any_name_list

%type <node>	group_by_item empty_grouping_set rollup_clause cube_clause
              grouping_sets_clause

%type <boolean>	all_or_distinct

%type <node>	join_outer join_qual
%type <jtype>	join_type

%type <list>	extract_list substr_list opt_interval interval_second
%type <node>	substr_from substr_for limit_clause select_limit_value columnElem 
              offset_clause select_offset_value where_clause a_expr b_expr 
              c_expr indirection_el AexprConst columnref in_expr having_clause

%type <list>	func_arg_list
%type <node>	func_arg_expr

%type <node>	case_expr case_arg when_clause case_default
%type <list>	when_clause_list
%type <ival>	sub_type
%type <alias>	alias_clause opt_alias_clause
%type <sortby>	sortby
%type <node>	table_ref
%type <jexpr>	joined_table
%type <range>	relation_expr
%type <target>  target_el

%type <typnam>	Typename SimpleTypename ConstTypename
				        GenericType Numeric ConstInterval

%type <str>		extract_arg

%type <ival>	Iconst 
%type <str>		Sconst 
%type <str>		ColId ColLabel type_function_name param_name

%type <keyword> unreserved_keyword type_func_name_keyword
%type <keyword> col_name_keyword reserved_keyword

%type <node>	func_application func_expr_common_subexpr
%type <node>	func_expr 
%type <node>	common_table_expr
%type <with>	with_clause 
%type <list>	cte_list

%type <list>	within_group_clause
%type <node>	filter_clause
%type <list>	opt_partition_clause
%type <windef>	over_clause window_specification
				        opt_frame_clause frame_extent frame_bound
%type <ival>	opt_window_exclusion_clause
%type <str>		opt_existing_window_name

%token <str>	IDENT FCONST SCONST Op
%token <ival>	ICONST 
%token			TYPECAST  DOT_DOT COLON_EQUALS EQUALS_GREATER
%token			LESS_EQUALS GREATER_EQUALS NOT_EQUALS

%token <keyword> ALL ALSO AND ANY AS ASC AT 

	BETWEEN BIGINT BOOLEAN_P BY

	CASE CAST 
	CHARACTERISTICS CHECK CHECKPOINT CLASS CLOSE
	CLUSTER COALESCE COLLATE COLLATION COLUMN COLUMNS COMMENT COMMENTS COMMIT
	COMMITTED CONCURRENTLY CONFIGURATION CONFLICT CONNECTION CONSTRAINT
	CONSTRAINTS CONTENT_P CONTINUE_P CONVERSION_P COPY COST CREATE
	CROSS CSV CUBE CURRENT_P
	CURRENT_CATALOG CURRENT_DATE CURRENT_ROLE CURRENT_SCHEMA
	CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURSOR CYCLE

	DATA_P DATABASE DAY_P DEALLOCATE DEC DECIMAL_P DECLARE DEFAULT DEFAULTS
	DEFERRABLE DEFERRED DEFINER DELETE_P DELIMITER DELIMITERS DEPENDS DESC
	DETACH DICTIONARY DISABLE_P DISCARD DISTINCT DO DOCUMENT_P DOMAIN_P
	DOUBLE_P DROP

	EACH ELSE ENABLE_P ENCODING ENCRYPTED END_P ENUM_P ESCAPE EVENT EXCEPT
	EXCLUDE EXCLUDING EXCLUSIVE EXECUTE EXISTS EXPLAIN
	EXTENSION EXTERNAL EXTRACT

	FALSE_P FAMILY FETCH FILTER FIRST_P FLOAT_P FOLLOWING FOR
	FORCE FOREIGN FORWARD FREEZE FROM FULL FUNCTION FUNCTIONS

	GENERATED GLOBAL GRANT GRANTED GREATEST GROUP_P GROUPING GROUPS

	HANDLER HAVING HEADER_P HOLD HOUR_P

	IDENTITY_P IF_P ILIKE IMMEDIATE IMMUTABLE IMPLICIT_P IMPORT_P IN_P INCLUDE
	INCLUDING INCREMENT INDEX INDEXES INHERIT INHERITS INITIALLY INLINE_P
	INNER_P INOUT INPUT_P INSENSITIVE INSERT INSTEAD INT_P INTEGER
	INTERSECT INTERVAL INTO INVOKER IS ISNULL ISOLATION

	JOIN

	KEY

	LABEL LANGUAGE LARGE_P LAST_P LATERAL_P
	LEADING LEAKPROOF LEAST LEFT LEVEL LIKE LIMIT LISTEN LOAD LOCAL
	LOCALTIME LOCALTIMESTAMP LOCATION LOCK_P LOCKED LOGGED

	MAPPING MATCH MATERIALIZED MAXVALUE METHOD MINUTE_P MINVALUE MODE MONTH_P MOVE

	NAME_P NAMES NATIONAL NATURAL NCHAR NEW NEXT NO NONE
	NOT NOTHING NOTIFY NOTNULL NOWAIT NULL_P NULLIF
	NULLS_P NUMERIC

	OBJECT_P OF OFF OFFSET OIDS OLD ON ONLY OPERATOR OPTION OPTIONS OR
	ORDER ORDINALITY OTHERS OUT_P OUTER_P
	OVER OVERLAPS OVERLAY OVERRIDING OWNED OWNER

	PARALLEL PARSER PARTIAL PARTITION PASSING PASSWORD PLACING PLANS POLICY
	POSITION PRECEDING PRECISION PRESERVE PREPARE PREPARED PRIMARY
	PRIOR PRIVILEGES PROCEDURAL PROCEDURE PROCEDURES PROGRAM PUBLICATION

	QUOTE

	RANGE READ REAL REASSIGN RECHECK RECURSIVE REF REFERENCES REFERENCING
	REFRESH REINDEX RELATIVE_P RELEASE RENAME REPEATABLE REPLACE REPLICA
	RESET RESTART RESTRICT RETURNING REVOKE RIGHT ROLE ROLLBACK ROLLUP
	ROUTINE ROUTINES ROW ROWS RULE

	SAVEPOINT SCHEMA SCHEMAS SCROLL SEARCH SECOND_P SECURITY SELECT SEQUENCE SEQUENCES
	SERIALIZABLE SERVER SESSION SESSION_USER SET SETS SETOF SHARE SHOW
	SIMILAR SIMPLE SKIP SMALLINT SNAPSHOT SOME SQL_P STABLE STANDALONE_P
	START STATEMENT STATISTICS STDIN STDOUT STORAGE STRICT_P STRIP_P
	SUBSCRIPTION SUBSTRING SYMMETRIC SYSID SYSTEM_P

	TABLE TABLES TABLESAMPLE TABLESPACE TEMP TEMPLATE TEMPORARY TEXT_P THEN
	TIES TIME TIMESTAMP TO TRAILING TRANSACTION TRANSFORM
	TREAT TRIGGER TRIM TRUE_P
	TRUNCATE TRUSTED TYPE_P TYPES_P

	UNBOUNDED UNCOMMITTED UNENCRYPTED UNION UNIQUE UNKNOWN UNLISTEN UNLOGGED
	UNTIL UPDATE USER USING

	VACUUM VALID VALIDATE VALIDATOR VALUE_P VALUES VARCHAR VARIADIC VARYING
	VERBOSE VERSION_P VIEW VIEWS VOLATILE

	WHEN WHERE WHITESPACE_P WINDOW WITH WITHIN WITHOUT WORK WRAPPER WRITE

	XML_P XMLATTRIBUTES XMLCONCAT XMLELEMENT XMLEXISTS XMLFOREST XMLNAMESPACES
	XMLPARSE XMLPI XMLROOT XMLSERIALIZE XMLTABLE

	YEAR_P YES_P

	ZONE


%token		NOT_LA NULLS_LA WITH_LA


/* Precedence: lowest to highest */
%nonassoc	SET				/* see relation_expr_opt_alias */
%left		UNION EXCEPT
%left		INTERSECT
%left		OR
%left		AND
%right		NOT
%nonassoc	IS ISNULL NOTNULL	/* IS sets precedence for IS NULL, etc */
%nonassoc	'<' '>' '=' LESS_EQUALS GREATER_EQUALS NOT_EQUALS
%nonassoc	BETWEEN IN_P LIKE ILIKE SIMILAR NOT_LA
%nonassoc	ESCAPE			/* ESCAPE must be just above LIKE/ILIKE/SIMILAR */
%left		POSTFIXOP		/* dummy for postfix Op rules */

%nonassoc	UNBOUNDED		/* ideally should have same precedence as IDENT */
%nonassoc	IDENT GENERATED NULL_P PARTITION RANGE ROWS GROUPS PRECEDING FOLLOWING CUBE ROLLUP
%left		Op OPERATOR		/* multi-character ops and user-defined operators */
%left		'+' '-'
%left		'*' '/' '%'
%left		'^'
%left		AT				/* sets precedence for AT TIME ZONE */
%left		COLLATE
%right		UMINUS
%left		'[' ']'
%left		'(' ')'
%left		TYPECAST
%left		'.'
%left		JOIN CROSS LEFT FULL RIGHT INNER_P NATURAL
%right		PRESERVE STRIP_P

%%

stmtblock:	stmtmulti
			{
				pg_yyget_extra(yyscanner)->parsetree = $1;
			}

stmtmulti:	stmtmulti ';' stmt
				{
					if ($3 != NULL)
						$$ = lappend($1, makeRawStmt($3));
					else
						$$ = $1;
				}
			| stmt
				{
					if ($1 != NULL)
						$$ = list_make1(makeRawStmt($1));
					else
						$$ = NIL;
				}
		;

stmt :
			SelectStmt
			| DropStmt
			| ViewStmt
			| /*EMPTY*/
				{ $$ = NULL; }
		;

/*****************************************************************************
 *
 *	QUERY:
 *		CREATE [ OR REPLACE ] [ TEMP ] VIEW <viewname> '('target-list ')'
 *			AS <query> [ WITH [ CASCADED | LOCAL ] CHECK OPTION ]
 *
 *****************************************************************************/


ViewStmt: CREATE VIEW qualified_name opt_column_list 
				AS SelectStmt 
				{
					ViewStmt *n = makeNode(ViewStmt);
					n->view = $3;
					n->aliases = $4;
					n->query = $6;
					$$ = (Node *) n;
				}
		;

opt_column_list:
			'(' columnList ')'						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

columnList:
			columnElem								{ $$ = list_make1($1); }
			| columnList ',' columnElem				{ $$ = lappend($1, $3); }
		;

columnElem: ColId
				{
					$$ = (Node *) makeString($1);
				}
		;

/*****************************************************************************
 *
 *		QUERY:
 *
 *		DROP itemtype [ IF EXISTS ] itemname [, itemname ...]
 *           [ RESTRICT | CASCADE ]
 *
 *****************************************************************************/

DropStmt:
  		 DROP drop_type_any_name any_name_list 
				{
					DropStmt *n = makeNode(DropStmt);
					n->removeType = $2;
					n->objects = $3;
					$$ = (Node *)n;
				}
		;

drop_type_any_name:
	 VIEW									{ $$ = OBJECT_VIEW; }
		;

any_name_list:
			any_name								{ $$ = list_make1($1); }
			| any_name_list ',' any_name			{ $$ = lappend($1, $3); }
		;

any_name:	ColId						{ $$ = list_make1(makeString($1)); }
			| ColId attrs				{ $$ = lcons(makeString($1), $2); }
		;


/*****************************************************************************
 *
 *		QUERY:
 *				SELECT STATEMENTS
 *
 *****************************************************************************/

SelectStmt: select_no_parens			%prec UMINUS
			| select_with_parens		%prec UMINUS
		;

select_with_parens:
			'(' select_no_parens ')'				{ $$ = $2; }
			| '(' select_with_parens ')'			{ $$ = $2; }
		;

select_no_parens:
			simple_select						{ $$ = $1; }
			| select_clause sort_clause
				{
					insertSelectOptions((SelectStmt *) $1, $2, 
										NULL, NULL, NULL,
										yyscanner);
					$$ = $1;
				}
			| select_clause opt_sort_clause select_limit 
				{
					insertSelectOptions((SelectStmt *) $1, $2,
										list_nth($3, 0), list_nth($3, 1),
										NULL,
										yyscanner);
					$$ = $1;
				}
			| with_clause select_clause
				{
					insertSelectOptions((SelectStmt *) $2, NULL, 
										NULL, NULL,
										$1,
										yyscanner);
					$$ = $2;
				}
			| with_clause select_clause sort_clause
				{
					insertSelectOptions((SelectStmt *) $2, $3, 
										NULL, NULL,
										$1,
										yyscanner);
					$$ = $2;
				}
			| with_clause select_clause opt_sort_clause select_limit 
				{
					insertSelectOptions((SelectStmt *) $2, $3, 
										list_nth($4, 0), list_nth($4, 1),
										$1,
										yyscanner);
					$$ = $2;
				}
		;

select_clause:
			simple_select							{ $$ = $1; }
			| select_with_parens					{ $$ = $1; }
		;

simple_select:
			SELECT opt_all_clause opt_target_list
	    from_clause where_clause group_clause having_clause 
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->targetList = $3;
					n->fromClause = $4;
					n->whereClause = $5;
					n->groupClause = $6;
					n->havingClause = $7;
					$$ = (Node *)n;
				}
			| SELECT distinct_clause target_list
			from_clause where_clause group_clause having_clause 
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->distinctClause = $2;
					n->targetList = $3;
					n->fromClause = $4;
					n->whereClause = $5;
					n->groupClause = $6;
					n->havingClause = $7;
					$$ = (Node *)n;
				}
			| select_clause UNION all_or_distinct select_clause
				{
					$$ = makeSetOp(SETOP_UNION, $3, $1, $4);
				}
			| select_clause INTERSECT all_or_distinct select_clause
				{
					$$ = makeSetOp(SETOP_INTERSECT, $3, $1, $4);
				}
			| select_clause EXCEPT all_or_distinct select_clause
				{
					$$ = makeSetOp(SETOP_EXCEPT, $3, $1, $4);
				}
		;

with_clause:
		WITH cte_list
			{
				$$ = makeNode(WithClause);
				$$->ctes = $2;
				$$->recursive = false;
			}
		;

cte_list:
		common_table_expr						{ $$ = list_make1($1); }
		| cte_list ',' common_table_expr		{ $$ = lappend($1, $3); }
		;

opt_name_list:
			'(' name_list ')'						{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

common_table_expr:  name opt_name_list AS '(' PreparableStmt ')'
			{
				CommonTableExpr *n = makeNode(CommonTableExpr);
				n->ctename = $1;
				n->aliascolnames = $2;
				n->ctequery = $5;
				$$ = (Node *) n;
			}
		;

PreparableStmt:
			SelectStmt
		;

all_or_distinct:
			ALL										{ $$ = true; }
			| DISTINCT								{ $$ = false; }
			| /*EMPTY*/								{ $$ = false; }
		;

distinct_clause:
			DISTINCT								{ $$ = list_make1(NIL); }
			| DISTINCT ON '(' expr_list ')'			{ $$ = $4; }
		;

opt_all_clause:
			ALL										{ $$ = NIL;}
			| /*EMPTY*/								{ $$ = NIL; }
		;

opt_sort_clause:
			sort_clause								{ $$ = $1;}
			| /*EMPTY*/								{ $$ = NIL; }
		;

sort_clause:
			ORDER BY sortby_list					{ $$ = $3; }
		;

sortby_list:
			sortby									{ $$ = list_make1($1); }
			| sortby_list ',' sortby				{ $$ = lappend($1, $3); }
		;

opt_asc_desc: ASC							{ $$ = SORTBY_ASC; }
			| DESC							{ $$ = SORTBY_DESC; }
			| /*EMPTY*/						{ $$ = SORTBY_DEFAULT; }
		;

sortby:		a_expr opt_asc_desc 
				{
					$$ = makeNode(SortBy);
					$$->node = $1;
					$$->sortby_dir = $2;
				}
		;

select_limit:
			limit_clause offset_clause			{ $$ = list_make2($2, $1); }
			| offset_clause limit_clause		{ $$ = list_make2($1, $2); }
			| limit_clause						{ $$ = list_make2(NULL, $1); }
			| offset_clause						{ $$ = list_make2($1, NULL); }
		;

limit_clause:
			LIMIT select_limit_value
				{ $$ = $2; }
		;

offset_clause:
			OFFSET select_offset_value
				{ $$ = $2; }
		;

select_limit_value:
			a_expr									{ $$ = $1; }
			| ALL
				{
					/* LIMIT ALL is represented as a NULL constant */
					$$ = makeNullAConst();
				}
		;

select_offset_value:
			a_expr									{ $$ = $1; }
		;

group_clause:
			GROUP_P BY group_by_list				{ $$ = $3; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

group_by_list:
			group_by_item							{ $$ = list_make1($1); }
			| group_by_list ',' group_by_item		{ $$ = lappend($1,$3); }
		;

group_by_item:
			a_expr									{ $$ = $1; }
			| empty_grouping_set					{ $$ = $1; }
			| cube_clause							{ $$ = $1; }
			| rollup_clause							{ $$ = $1; }
			| grouping_sets_clause					{ $$ = $1; }
		;

empty_grouping_set:
			'(' ')'
				{
					$$ = (Node *) makeGroupingSet(GROUPING_SET_EMPTY, NIL);
				}
		;

rollup_clause:
			ROLLUP '(' expr_list ')'
				{
					$$ = (Node *) makeGroupingSet(GROUPING_SET_ROLLUP, $3);
				}
		;

cube_clause:
			CUBE '(' expr_list ')'
				{
					$$ = (Node *) makeGroupingSet(GROUPING_SET_CUBE, $3);
				}
		;

grouping_sets_clause:
			GROUPING SETS '(' group_by_list ')'
				{
					$$ = (Node *) makeGroupingSet(GROUPING_SET_SETS, $4);
				}
		;

having_clause:
			HAVING a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

from_clause:
			FROM from_list							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

from_list:
			table_ref								{ $$ = list_make1($1); }
			| from_list ',' table_ref				{ $$ = lappend($1, $3); }
		;

/*
 * table_ref is where an alias clause can be attached.
 */
table_ref:	relation_expr opt_alias_clause
				{
					$1->alias = $2;
					$$ = (Node *) $1;
				}
			| select_with_parens opt_alias_clause
				{
					RangeSubselect *n = makeNode(RangeSubselect);
					n->lateral = false;
					n->subquery = $1;
					n->alias = $2;
					/*
					 * The SQL spec does not permit a subselect
					 * (<derived_table>) without an alias clause,
					 * so we don't either.  This avoids the problem
					 * of needing to invent a unique refname for it.
					 * That could be surmounted if there's sufficient
					 * popular demand, but for now let's just implement
					 * the spec and see if anyone complains.
					 * However, it does seem like a good idea to emit
					 * an error message that's better than "syntax error".
					 */
					if ($2 == NULL)
					{
						base_yyerror("subquery in FROM must have an alias");
					}
					$$ = (Node *) n;
				}
			| joined_table
				{
					$$ = (Node *) $1;
				}
			| '(' joined_table ')' alias_clause
				{
					$2->alias = $4;
					$$ = (Node *) $2;
				}
		;

joined_table:
			'(' joined_table ')'
				{
					$$ = $2;
				}
			| table_ref join_type JOIN table_ref join_qual
				{
					JoinExpr *n = makeNode(JoinExpr);
					n->jointype = $2;
					n->isNatural = false;
					n->larg = $1;
					n->rarg = $4;
					if ($5 != NULL && IsA($5, List))
						n->usingClause = (List *) $5; /* USING clause */
					else
						n->quals = $5; /* ON clause */
					$$ = n;
				}
			| table_ref JOIN table_ref join_qual
				{
					/* letting join_type reduce to empty doesn't work */
					JoinExpr *n = makeNode(JoinExpr);
					n->jointype = JOIN_INNER;
					n->isNatural = false;
					n->larg = $1;
					n->rarg = $3;
					if ($4 != NULL && IsA($4, List))
						n->usingClause = (List *) $4; /* USING clause */
					else
						n->quals = $4; /* ON clause */
					$$ = n;
				}
		;

alias_clause:
			AS ColId '(' name_list ')'
				{
					$$ = makeNode(Alias);
					$$->aliasname = $2;
					$$->colnames = $4;
				}
			| AS ColId
				{
					$$ = makeNode(Alias);
					$$->aliasname = $2;
				}
			| ColId '(' name_list ')'
				{
					$$ = makeNode(Alias);
					$$->aliasname = $1;
					$$->colnames = $3;
				}
			| ColId
				{
					$$ = makeNode(Alias);
					$$->aliasname = $1;
				}
		;


opt_alias_clause: alias_clause						{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;


join_type:	FULL join_outer							{ $$ = JOIN_FULL; }
			| LEFT join_outer						{ $$ = JOIN_LEFT; }
			| RIGHT join_outer						{ $$ = JOIN_RIGHT; }
			| INNER_P								{ $$ = JOIN_INNER; }
		;

/* OUTER is just noise... */
join_outer: OUTER_P									{ $$ = NULL; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

join_qual:	USING '(' name_list ')'					{ $$ = (Node *) $3; }
			| ON a_expr								{ $$ = $2; }
		;

relation_expr:
			qualified_name
				{
					/* inheritance query, implicitly */
					$$ = $1;
					$$->inh = true;
					$$->alias = NULL;
				}
			| qualified_name '*'
				{
					/* inheritance query, explicitly */
					$$ = $1;
					$$->inh = true;
					$$->alias = NULL;
				}
			| ONLY qualified_name
				{
					/* no inheritance */
					$$ = $2;
					$$->inh = false;
					$$->alias = NULL;
				}
			| ONLY '(' qualified_name ')'
				{
					/* no inheritance, SQL99-style syntax */
					$$ = $3;
					$$->inh = false;
					$$->alias = NULL;
				}
		;

where_clause:
			WHERE a_expr							{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

Typename:	SimpleTypename 
				{
					$$ = $1;
				}
		;

SimpleTypename:
			GenericType								{ $$ = $1; }
			| Numeric								{ $$ = $1; }
			| ConstInterval opt_interval
				{
					$$ = $1;
					$$->typmods = $2;
				}
		;

ConstTypename:
			Numeric									{ $$ = $1; }
		;

attr_name:	ColLabel								{ $$ = $1; };

attrs:		'.' attr_name
					{ $$ = list_make1(makeString($2)); }
			| attrs '.' attr_name
					{ $$ = lappend($1, makeString($3)); }
		;

GenericType:
			type_function_name opt_type_modifiers
				{
					$$ = makeTypeName($1);
					$$->typmods = $2;
				}
			| type_function_name attrs opt_type_modifiers
				{
					$$ = makeTypeNameFromNameList(lcons(makeString($1), $2));
					$$->typmods = $3;
				}
		;

opt_type_modifiers: '(' expr_list ')'				{ $$ = $2; }
					| /* EMPTY */					{ $$ = NIL; }
		;

Numeric:	INT_P
				{
					$$ = SystemTypeName("int4");
				}
			| INTEGER
				{
					$$ = SystemTypeName("int4");
				}
			| SMALLINT
				{
					$$ = SystemTypeName("int2");
				}
			| BIGINT
				{
					$$ = SystemTypeName("int8");
				}
			| REAL
				{
					$$ = SystemTypeName("float4");
				}
			| DOUBLE_P PRECISION
				{
					$$ = SystemTypeName("float8");
				}
			| DECIMAL_P opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
				}
			| DEC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
				}
			| NUMERIC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
				}
			| BOOLEAN_P
				{
					$$ = SystemTypeName("bool");
				}
		;

ConstInterval:
			INTERVAL
				{
					$$ = SystemTypeName("interval");
				}
		;

opt_interval:
			YEAR_P
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(YEAR))); }
			| MONTH_P
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MONTH))); }
			| DAY_P
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(DAY))); }
			| HOUR_P
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(HOUR))); }
			| MINUTE_P
				{ $$ = list_make1(makeIntConst(INTERVAL_MASK(MINUTE))); }
			| interval_second
				{ $$ = $1; }
			| YEAR_P TO MONTH_P
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(YEAR) |
												 INTERVAL_MASK(MONTH)));
				}
			| DAY_P TO HOUR_P
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(DAY) |
												 INTERVAL_MASK(HOUR)));
				}
			| DAY_P TO MINUTE_P
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(DAY) |
												 INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE)));
				}
			| DAY_P TO interval_second
				{
					$$ = $3;
					linitial($$) = makeIntConst(INTERVAL_MASK(DAY) |
												INTERVAL_MASK(HOUR) |
												INTERVAL_MASK(MINUTE) |
												INTERVAL_MASK(SECOND));
				}
			| HOUR_P TO MINUTE_P
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(HOUR) |
												 INTERVAL_MASK(MINUTE)));
				}
			| HOUR_P TO interval_second
				{
					$$ = $3;
					linitial($$) = makeIntConst(INTERVAL_MASK(HOUR) |
												INTERVAL_MASK(MINUTE) |
												INTERVAL_MASK(SECOND));
				}
			| MINUTE_P TO interval_second
				{
					$$ = $3;
					linitial($$) = makeIntConst(INTERVAL_MASK(MINUTE) |
												INTERVAL_MASK(SECOND));
				}
			| /*EMPTY*/
				{ $$ = NIL; }
		;

interval_second:
			SECOND_P
				{
					$$ = list_make1(makeIntConst(INTERVAL_MASK(SECOND)));
				}
			| SECOND_P '(' Iconst ')'
				{
					$$ = list_make2(makeIntConst(INTERVAL_MASK(SECOND)),
									makeIntConst($3));
				}
		;

a_expr:		c_expr									{ $$ = $1; }
		/*
		 * These operators must be called out explicitly in order to make use
		 * of bison's automatic operator-precedence handling.  All other
		 * operator names are handled by the generic productions using "Op",
		 * below; and all those operators will have the same precedence.
		 *
		 * If you add more explicitly-known operators, be sure to add them
		 * also to b_expr and to the MathOp list below.
		 */
			| a_expr TYPECAST Typename
					{ $$ = makeTypeCast($1, $3); }
			| '+' a_expr					%prec UMINUS
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "+", NULL, $2); }
			| '-' a_expr					%prec UMINUS
				{ $$ = doNegate($2); }
			| a_expr '+' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "+", $1, $3); }
			| a_expr '-' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "-", $1, $3); }
			| a_expr '*' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "*", $1, $3); }
			| a_expr '/' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "/", $1, $3); }
			| a_expr '%' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "%", $1, $3); }
			| a_expr '^' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "^", $1, $3); }
			| a_expr '<' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<", $1, $3); }
			| a_expr '>' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, ">", $1, $3); }
			| a_expr '=' a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "=", $1, $3); }
			| a_expr qual_Op a_expr				%prec Op
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $2, $1, $3); }
			| qual_Op a_expr					%prec Op
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $1, NULL, $2); }
			| a_expr qual_Op					%prec POSTFIXOP
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $2, $1, NULL); }
			| a_expr LESS_EQUALS a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<=", $1, $3); }
			| a_expr GREATER_EQUALS a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, ">=", $1, $3); }
			| a_expr NOT_EQUALS a_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<>", $1, $3); }
			| a_expr AND a_expr
				{ $$ = makeAndExpr($1, $3); }
			| a_expr OR a_expr
				{ $$ = makeOrExpr($1, $3); }
			| NOT a_expr
				{ $$ = makeNotExpr($2); }
			| NOT_LA a_expr						%prec NOT
				{ $$ = makeNotExpr($2); }

			| a_expr LIKE a_expr
				{
					$$ = (Node *) makeSimpleA_Expr(AEXPR_LIKE, "~~",
												   $1, $3);
				}
			| a_expr NOT LIKE a_expr							%prec NOT_LA
				{
					$$ = (Node *) makeSimpleA_Expr(AEXPR_LIKE, "!~~",
												   $1, $4);
				}
			/* NullTest clause
			 * Define SQL-style Null test clause.
			 * Allow two forms described in the standard:
			 *	a IS NULL
			 *	a IS NOT NULL
			 * Allow two SQL extensions
			 *	a ISNULL
			 *	a NOTNULL
			 */
			| a_expr IS NULL_P							%prec IS
				{
					NullTest *n = makeNode(NullTest);
					n->arg = (Expr *) $1;
					n->nulltesttype = IS_NULL;
					$$ = (Node *)n;
				}
			| a_expr IS NOT NULL_P						%prec IS
				{
					NullTest *n = makeNode(NullTest);
					n->arg = (Expr *) $1;
					n->nulltesttype = IS_NOT_NULL;
					$$ = (Node *)n;
				}
			| a_expr BETWEEN b_expr AND a_expr		%prec BETWEEN
				{
					$$ = (Node *) makeSimpleA_Expr(AEXPR_BETWEEN,
												   "BETWEEN",
												   $1,
												   (Node *) list_make2($3, $5));
				}
			| a_expr NOT BETWEEN b_expr AND a_expr %prec NOT_LA
				{
					$$ = (Node *) makeSimpleA_Expr(AEXPR_NOT_BETWEEN,
												   "NOT BETWEEN",
												   $1,
												   (Node *) list_make2($4, $6));
				}
			| a_expr IN_P in_expr
				{
					/* in_expr returns a SubLink or a list of a_exprs */
					if (IsA($3, SubLink))
					{
						/* generate foo = ANY (subquery) */
						SubLink *n = (SubLink *) $3;
						n->subLinkType = ANY_SUBLINK;
						n->testexpr = $1;
						n->operName = NIL;		/* show it's IN not = ANY */
						$$ = (Node *)n;
					}
					else
					{
						/* generate scalar IN expression */
						$$ = (Node *) makeSimpleA_Expr(AEXPR_IN, "=", $1, $3);
					}
				}
			| a_expr NOT IN_P in_expr						%prec NOT_LA
				{
					/* in_expr returns a SubLink or a list of a_exprs */
					if (IsA($4, SubLink))
					{
						/* generate NOT (foo = ANY (subquery)) */
						/* Make an = ANY node */
						SubLink *n = (SubLink *) $4;
						n->subLinkType = ANY_SUBLINK;
						n->testexpr = $1;
						n->operName = NIL;		/* show it's IN not = ANY */
						/* Stick a NOT on top; must have same parse location */
						$$ = makeNotExpr((Node *) n);
					}
					else
					{
						/* generate scalar NOT IN expression */
						$$ = (Node *) makeSimpleA_Expr(AEXPR_IN, "<>", $1, $4);
					}
				}
			| a_expr subquery_Op sub_type select_with_parens	%prec Op
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = $3;
					n->testexpr = $1;
					n->operName = $2;
					n->subselect = $4;
					$$ = (Node *)n;
				}
			| a_expr subquery_Op sub_type '(' a_expr ')'		%prec Op
				{
					if ($3 == ANY_SUBLINK)
						$$ = (Node *) makeA_Expr(AEXPR_OP_ANY, $2, $1, $5);
					else
						$$ = (Node *) makeA_Expr(AEXPR_OP_ALL, $2, $1, $5);
				}
		;

/*
 * Restricted expressions
 *
 * b_expr is a subset of the complete expression syntax defined by a_expr.
 *
 * Presently, AND, NOT, IS, and IN are the a_expr keywords that would
 * cause trouble in the places where b_expr is used.  For simplicity, we
 * just eliminate all the boolean-keyword-operator productions from b_expr.
 */
b_expr:		c_expr
				{ $$ = $1; }
			| b_expr TYPECAST Typename
				{ $$ = makeTypeCast($1, $3); }
			| '+' b_expr					%prec UMINUS
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "+", NULL, $2); }
			| '-' b_expr					%prec UMINUS
				{ $$ = doNegate($2); }
			| b_expr '+' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "+", $1, $3); }
			| b_expr '-' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "-", $1, $3); }
			| b_expr '*' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "*", $1, $3); }
			| b_expr '/' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "/", $1, $3); }
			| b_expr '%' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "%", $1, $3); }
			| b_expr '^' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "^", $1, $3); }
			| b_expr '<' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<", $1, $3); }
			| b_expr '>' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, ">", $1, $3); }
			| b_expr '=' b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "=", $1, $3); }
			| b_expr LESS_EQUALS b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<=", $1, $3); }
			| b_expr GREATER_EQUALS b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, ">=", $1, $3); }
			| b_expr NOT_EQUALS b_expr
				{ $$ = (Node *) makeSimpleA_Expr(AEXPR_OP, "<>", $1, $3); }
			| b_expr qual_Op b_expr				%prec Op
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $2, $1, $3); }
			| qual_Op b_expr					%prec Op
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $1, NULL, $2); }
			| b_expr qual_Op					%prec POSTFIXOP
				{ $$ = (Node *) makeA_Expr(AEXPR_OP, $2, $1, NULL); }
		;

/*
 * Productions that can be used in both a_expr and b_expr.
 *
 * Note: productions that refer recursively to a_expr or b_expr mostly
 * cannot appear here.	However, it's OK to refer to a_exprs that occur
 * inside parentheses, such as function arguments; that cannot introduce
 * ambiguity to the b_expr syntax.
 */
c_expr:		columnref								{ $$ = $1; }
			| AexprConst							{ $$ = $1; }
			| '(' a_expr ')' 
				{
					$$ = $2;
				}

			| case_expr
				{ $$ = $1; }
			| func_expr
				{ $$ = $1; }
			| select_with_parens			%prec UMINUS
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = EXPR_SUBLINK;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $1;
					$$ = (Node *)n;
				}
			| EXISTS select_with_parens
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = EXISTS_SUBLINK;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $2;
					$$ = (Node *)n;
				}
			| GROUPING '(' expr_list ')'
			  {
				  GroupingFunc *g = makeNode(GroupingFunc);
				  g->args = $3;
				  $$ = (Node *)g;
			  }
		;

func_application: func_name '(' ')'
				{
					$$ = (Node *) makeFuncCall($1, NIL);
				}
			| func_name '(' func_arg_list opt_sort_clause ')'
				{
					FuncCall *n = makeFuncCall($1, $3);
					n->agg_order = $4;
					$$ = (Node *)n;
				}
			| func_name '(' ALL func_arg_list opt_sort_clause ')'
				{
					FuncCall *n = makeFuncCall($1, $4);
					n->agg_order = $5;
					/* Ideally we'd mark the FuncCall node to indicate
					 * "must be an aggregate", but there's no provision
					 * for that in FuncCall at the moment.
					 */
					$$ = (Node *)n;
				}
			| func_name '(' DISTINCT func_arg_list opt_sort_clause ')'
				{
					FuncCall *n = makeFuncCall($1, $4);
					n->agg_order = $5;
					n->agg_distinct = true;
					$$ = (Node *)n;
				}
			| func_name '(' '*' ')'
				{
					/*
					 * We consider AGGREGATE(*) to invoke a parameterless
					 * aggregate.  This does the right thing for COUNT(*),
					 * and there are no other aggregates in SQL that accept
					 * '*' as parameter.
					 *
					 * The FuncCall node is also marked agg_star = true,
					 * so that later processing can detect what the argument
					 * really was.
					 */
					FuncCall *n = makeFuncCall($1, NIL);
					n->agg_star = true;
					$$ = (Node *)n;
				}
		;



func_expr: func_application within_group_clause filter_clause over_clause
				{
					FuncCall *n = (FuncCall *) $1;
					/*
					 * The order clause for WITHIN GROUP and the one for
					 * plain-aggregate ORDER BY share a field, so we have to
					 * check here that at most one is present.  We also check
					 * for DISTINCT and VARIADIC here to give a better error
					 * location.  Other consistency checks are deferred to
					 * parse analysis.
					 */
					if ($2 != NIL)
					{
						if (n->agg_order != NIL)
						  base_yyerror("cannot use multiple ORDER BY clauses with WITHIN GROUP");
						if (n->agg_distinct)
						  base_yyerror("cannot use DISTINCT with WITHIN GROUP");
						n->agg_order = $2;
						n->agg_within_group = true;
					}
					n->agg_filter = $3;
					n->over = $4;
					$$ = (Node *) n;
				}
			| func_expr_common_subexpr
				{ $$ = $1; }
		;

func_expr_common_subexpr:
			 CAST '(' a_expr AS Typename ')'
				{ $$ = makeTypeCast($3, $5); }
			| EXTRACT '(' extract_list ')'
				{
					$$ = (Node *) makeFuncCall(SystemFuncName("date_part"), $3);
				}
			| SUBSTRING '(' substr_list ')'
				{
					/* substring(A from B for C) is converted to
					 * substring(A, B, C) - thomas 2000-11-28
					 */
					$$ = (Node *) makeFuncCall(SystemFuncName("substring"), $3);
				}
			| COALESCE '(' expr_list ')'
				{
					CoalesceExpr *c = makeNode(CoalesceExpr);
					c->args = $3;
					$$ = (Node *)c;
				}
		;

within_group_clause:
			WITHIN GROUP_P '(' sort_clause ')'		{ $$ = $4; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

filter_clause:
			FILTER '(' WHERE a_expr ')'				{ $$ = $4; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

over_clause: OVER window_specification
				{ $$ = $2; }
			| OVER ColId
				{
					WindowDef *n = makeNode(WindowDef);
					n->name = $2;
					n->refname = NULL;
					n->partitionClause = NIL;
					n->orderClause = NIL;
					n->frameOptions = FRAMEOPTION_DEFAULTS;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| /*EMPTY*/
				{ $$ = NULL; }
		;

window_specification: '(' opt_existing_window_name opt_partition_clause
						opt_sort_clause opt_frame_clause ')'
				{
					WindowDef *n = makeNode(WindowDef);
					n->name = NULL;
					n->refname = $2;
					n->partitionClause = $3;
					n->orderClause = $4;
					n->frameOptions = $5->frameOptions;
					n->startOffset = $5->startOffset;
					n->endOffset = $5->endOffset;
					$$ = n;
				}
		;

opt_existing_window_name: ColId						{ $$ = $1; }
			| /*EMPTY*/				%prec Op		{ $$ = NULL; }
		;

opt_partition_clause: PARTITION BY expr_list		{ $$ = $3; }
			| /*EMPTY*/								{ $$ = NIL; }
		;

opt_frame_clause:
			RANGE frame_extent opt_window_exclusion_clause
				{
					WindowDef *n = $2;
					n->frameOptions |= FRAMEOPTION_NONDEFAULT | FRAMEOPTION_RANGE;
					n->frameOptions |= $3;
					$$ = n;
				}
			| ROWS frame_extent opt_window_exclusion_clause
				{
					WindowDef *n = $2;
					n->frameOptions |= FRAMEOPTION_NONDEFAULT | FRAMEOPTION_ROWS;
					n->frameOptions |= $3;
					$$ = n;
				}
			| GROUPS frame_extent opt_window_exclusion_clause
				{
					WindowDef *n = $2;
					n->frameOptions |= FRAMEOPTION_NONDEFAULT | FRAMEOPTION_GROUPS;
					n->frameOptions |= $3;
					$$ = n;
				}
			| /*EMPTY*/
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_DEFAULTS;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
		;

frame_extent: frame_bound
				{
					WindowDef *n = $1;
					/* reject invalid cases */
					if (n->frameOptions & FRAMEOPTION_START_UNBOUNDED_FOLLOWING)
					  base_yyerror("frame start cannot be UNBOUNDED FOLLOWING");
					if (n->frameOptions & FRAMEOPTION_START_OFFSET_FOLLOWING)
					  base_yyerror("frame starting from following row cannot end with current row");
					n->frameOptions |= FRAMEOPTION_END_CURRENT_ROW;
					$$ = n;
				}
			| BETWEEN frame_bound AND frame_bound
				{
					WindowDef *n1 = $2;
					WindowDef *n2 = $4;
					/* form merged options */
					int		frameOptions = n1->frameOptions;
					/* shift converts START_ options to END_ options */
					frameOptions |= n2->frameOptions << 1;
					frameOptions |= FRAMEOPTION_BETWEEN;
					/* reject invalid cases */
					if (frameOptions & FRAMEOPTION_START_UNBOUNDED_FOLLOWING)
					 base_yyerror("frame start cannot be UNBOUNDED FOLLOWING");
					if (frameOptions & FRAMEOPTION_END_UNBOUNDED_PRECEDING)
					 base_yyerror("frame end cannot be UNBOUNDED PRECEDING");
					if ((frameOptions & FRAMEOPTION_START_CURRENT_ROW) &&
						(frameOptions & FRAMEOPTION_END_OFFSET_PRECEDING))
					 base_yyerror("frame starting from current row cannot have preceding rows");
					if ((frameOptions & FRAMEOPTION_START_OFFSET_FOLLOWING) &&
						(frameOptions & (FRAMEOPTION_END_OFFSET_PRECEDING |
										 FRAMEOPTION_END_CURRENT_ROW)))
					 base_yyerror("frame starting from following row cannot have preceding rows");
					n1->frameOptions = frameOptions;
					n1->endOffset = n2->startOffset;
					$$ = n1;
				}
		;

/*
 * This is used for both frame start and frame end, with output set up on
 * the assumption it's frame start; the frame_extent productions must reject
 * invalid cases.
 */
frame_bound:
			UNBOUNDED PRECEDING
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_START_UNBOUNDED_PRECEDING;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| UNBOUNDED FOLLOWING
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_START_UNBOUNDED_FOLLOWING;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| CURRENT_P ROW
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_START_CURRENT_ROW;
					n->startOffset = NULL;
					n->endOffset = NULL;
					$$ = n;
				}
			| a_expr PRECEDING
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_START_OFFSET_PRECEDING;
					n->startOffset = $1;
					n->endOffset = NULL;
					$$ = n;
				}
			| a_expr FOLLOWING
				{
					WindowDef *n = makeNode(WindowDef);
					n->frameOptions = FRAMEOPTION_START_OFFSET_FOLLOWING;
					n->startOffset = $1;
					n->endOffset = NULL;
					$$ = n;
				}
		;

opt_window_exclusion_clause:
			EXCLUDE CURRENT_P ROW	{ $$ = FRAMEOPTION_EXCLUDE_CURRENT_ROW; }
			| EXCLUDE GROUP_P		{ $$ = FRAMEOPTION_EXCLUDE_GROUP; }
			| EXCLUDE TIES			{ $$ = FRAMEOPTION_EXCLUDE_TIES; }
			| EXCLUDE NO OTHERS		{ $$ = 0; }
			| /*EMPTY*/				{ $$ = 0; }
		;



sub_type:	ANY										{ $$ = ANY_SUBLINK; }
			| SOME									{ $$ = ANY_SUBLINK; }
			| ALL									{ $$ = ALL_SUBLINK; }
		;

all_Op:		Op										{ $$ = $1; }
			| MathOp								{ $$ = $1; }
		;

MathOp:		 '+'									{ $$ = "+"; }
			| '-'									{ $$ = "-"; }
			| '*'									{ $$ = "*"; }
			| '/'									{ $$ = "/"; }
			| '%'									{ $$ = "%"; }
			| '^'									{ $$ = "^"; }
			| '<'									{ $$ = "<"; }
			| '>'									{ $$ = ">"; }
			| '='									{ $$ = "="; }
			| LESS_EQUALS							{ $$ = "<="; }
			| GREATER_EQUALS						{ $$ = ">="; }
			| NOT_EQUALS							{ $$ = "<>"; }
		;

qual_Op:	Op
					{ $$ = list_make1(makeString($1)); }
		;

subquery_Op:
			all_Op
					{ $$ = list_make1(makeString($1)); }
			| LIKE
					{ $$ = list_make1(makeString("~~")); }
			| NOT LIKE
					{ $$ = list_make1(makeString("!~~")); }
			| ILIKE
					{ $$ = list_make1(makeString("~~*")); }
			| NOT ILIKE
					{ $$ = list_make1(makeString("!~~*")); }
			;

expr_list:	a_expr
				{
					$$ = list_make1($1);
				}
			| expr_list ',' a_expr
				{
					$$ = lappend($1, $3);
				}
		;

param_name:	type_function_name
		;

func_arg_list:  func_arg_expr
				{
					$$ = list_make1($1);
				}
			| func_arg_list ',' func_arg_expr
				{
					$$ = lappend($1, $3);
				}
		;

func_arg_expr:  a_expr
				{
					$$ = $1;
				}
			| param_name COLON_EQUALS a_expr
				{
					NamedArgExpr *na = makeNode(NamedArgExpr);
					na->name = $1;
					na->arg = (Expr *) $3;
					$$ = (Node *) na;
				}
			| param_name EQUALS_GREATER a_expr
				{
					NamedArgExpr *na = makeNode(NamedArgExpr);
					na->name = $1;
					na->arg = (Expr *) $3;
					$$ = (Node *) na;
				}
		;

extract_list:
			extract_arg FROM a_expr
				{
					$$ = list_make2(makeStringConst($1), $3);
				}
			| /*EMPTY*/								{ $$ = NIL; }
		;

/* Allow delimited string Sconst in extract_arg as an SQL extension.
 * - thomas 2001-04-12
 */
extract_arg:
			IDENT									{ $$ = $1; }
			| YEAR_P								{ $$ = "year"; }
			| MONTH_P								{ $$ = "month"; }
			| DAY_P									{ $$ = "day"; }
			| HOUR_P								{ $$ = "hour"; }
			| MINUTE_P								{ $$ = "minute"; }
			| SECOND_P								{ $$ = "second"; }
		;

substr_list:
			a_expr substr_from substr_for
				{
					$$ = list_make3($1, $2, $3);
				}
			| a_expr substr_for substr_from
				{
					/* not legal per SQL99, but might as well allow it */
					$$ = list_make3($1, $3, $2);
				}
			| a_expr substr_from
				{
					$$ = list_make2($1, $2);
				}
			| a_expr substr_for
				{
					/*
					 * Since there are no cases where this syntax allows
					 * a textual FOR value, we forcibly cast the argument
					 * to int4.  The possible matches in pg_proc are
					 * substring(text,int4) and substring(text,text),
					 * and we don't want the parser to choose the latter,
					 * which it is likely to do if the second argument
					 * is unknown or doesn't have an implicit cast to int4.
					 */
					$$ = list_make3($1, makeIntConst(1),
									makeTypeCast($2,
												 SystemTypeName("int4")));
				}
			| expr_list
				{
					$$ = $1;
				}
			| /*EMPTY*/
				{ $$ = NIL; }
		;

substr_from:
			FROM a_expr								{ $$ = $2; }
		;

substr_for: FOR a_expr								{ $$ = $2; }
		;

in_expr:	select_with_parens
				{
					SubLink *n = makeNode(SubLink);
					n->subselect = $1;
					/* other fields will be filled later */
					$$ = (Node *)n;
				}
			| '(' expr_list ')'						{ $$ = (Node *)$2; }
		;

/*
 * Define SQL-style CASE clause.
 * - Full specification
 *	CASE WHEN a = b THEN c ... ELSE d END
 * - Implicit argument
 *	CASE a WHEN b THEN c ... ELSE d END
 */
case_expr:	CASE case_arg when_clause_list case_default END_P
				{
					CaseExpr *c = makeNode(CaseExpr);
					c->arg = (Expr *) $2;
					c->args = $3;
					c->defresult = (Expr *) $4;
					$$ = (Node *)c;
				}
		;

when_clause_list:
			/* There must be at least one */
			when_clause								{ $$ = list_make1($1); }
			| when_clause_list when_clause			{ $$ = lappend($1, $2); }
		;

when_clause:
			WHEN a_expr THEN a_expr
				{
					CaseWhen *w = makeNode(CaseWhen);
					w->expr = (Expr *) $2;
					w->result = (Expr *) $4;
					$$ = (Node *)w;
				}
		;

case_default:
			ELSE a_expr								{ $$ = $2; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

case_arg:	a_expr									{ $$ = $1; }
			| /*EMPTY*/								{ $$ = NULL; }
		;

columnref:	ColId
				{
					$$ = makeColumnRef($1, NIL, yyscanner);
				}
			| ColId indirection
				{
					$$ = makeColumnRef($1, $2, yyscanner);
				}
		;


indirection:
			indirection_el							{ $$ = list_make1($1); }
			| indirection indirection_el			{ $$ = lappend($1, $2); }
		;

indirection_el:
			'.' attr_name
				{
					$$ = (Node *) makeString($2);
				}
			| '.' '*'
				{
					$$ = (Node *) makeNode(A_Star);
				}
		;



opt_target_list: target_list						{ $$ = $1; }
			| /* EMPTY */							{ $$ = NIL; }
		;

target_list:
			target_el								{ $$ = list_make1($1); }
			| target_list ',' target_el				{ $$ = lappend($1, $3); }
		;

target_el:	a_expr AS ColLabel
				{
					$$ = makeNode(ResTarget);
					$$->name = $3;
					$$->val = (Node *)$1;
				}
			| a_expr IDENT
				{
					$$ = makeNode(ResTarget);
					$$->name = $2;
					$$->val = (Node *)$1;
				}
			| a_expr
				{
					$$ = makeNode(ResTarget);
					$$->name = NULL;
					$$->val = (Node *)$1;
				}
			| '*'
				{
					ColumnRef *n = makeNode(ColumnRef);
					n->fields = list_make1(makeNode(A_Star));

					$$ = makeNode(ResTarget);
					$$->name = NULL;
					$$->val = (Node *)n;
				}
		;

func_name:	type_function_name
					{ $$ = list_make1(makeString($1)); }
		;

/*
 * The production for a qualified relation name has to exactly match the
 * production for a qualified func_name, because in a FROM clause we cannot
 * tell which we are parsing until we see what comes after it ('(' for a
 * func_name, something else for a relation). Therefore we allow 'indirection'
 * which may contain subscripts, and reject that case in the C code.
 */
qualified_name:
			ColId
				{
					$$ = makeRangeVar(NULL, $1);
				}
			;

name_list:	name
					{ $$ = list_make1(makeString($1)); }
			| name_list ',' name
					{ $$ = lappend($1, makeString($3)); }
		;


name:		ColId									{ $$ = $1; };



AexprConst: Iconst
				{
					$$ = makeIntConst($1);
				}
			| FCONST
				{
					$$ = makeFloatConst($1);
				}
			| Sconst
				{
					$$ = makeStringConst($1);
				}
			| func_name Sconst
				{
					/* generic type 'literal' syntax */
					TypeName *t = makeTypeNameFromNameList($1);
					$$ = makeStringConstCast($2, t);
				}
			| func_name '(' func_arg_list opt_sort_clause ')' Sconst
				{
					/* generic syntax with a type modifier */
					TypeName *t = makeTypeNameFromNameList($1);
					ListCell *lc;

					/*
					 * We must use func_arg_list and opt_sort_clause in the
					 * production to avoid reduce/reduce conflicts, but we
					 * don't actually wish to allow NamedArgExpr in this
					 * context, nor ORDER BY.
					 */
					foreach(lc, $3)
					{
						NamedArgExpr *arg = (NamedArgExpr *) lfirst(lc);

						if (IsA(arg, NamedArgExpr))
						  base_yyerror("type modifier cannot have parameter name");
					}
					if ($4 != NIL)
						  base_yyerror("type modifier cannot have ORDER BY");

					t->typmods = $3;
					$$ = makeStringConstCast($6, t);
				}
			| ConstTypename Sconst
				{
					$$ = makeStringConstCast($2, $1);
				}
			| ConstInterval Sconst opt_interval
				{
					TypeName *t = $1;
					t->typmods = $3;
					$$ = makeStringConstCast($2, t);
				}
			| ConstInterval '(' Iconst ')' Sconst
				{
					TypeName *t = $1;
					t->typmods = list_make2(makeIntConst(INTERVAL_FULL_RANGE),
											makeIntConst($3));
					$$ = makeStringConstCast($5, t);
				}
			| TRUE_P
				{
					$$ = makeBoolAConst(true);
				}
			| FALSE_P
				{
					$$ = makeBoolAConst(false);
				}
			| NULL_P
				{
					$$ = makeNullAConst();
				}
		;

Iconst:		ICONST									{ $$ = $1; };
Sconst:		SCONST									{ $$ = $1; };

ColId:		IDENT									{ $$ = $1; }
			| unreserved_keyword					{ $$ = strdup($1); }
			| col_name_keyword						{ $$ = strdup($1); }
		;

type_function_name:	IDENT							{ $$ = $1; }
			| unreserved_keyword					{ $$ = strdup($1); }
			| type_func_name_keyword				{ $$ = strdup($1); }
		;


ColLabel:	IDENT									{ $$ = $1; }
			| unreserved_keyword					{ $$ = strdup($1); }
			| col_name_keyword						{ $$ = strdup($1); }
			| type_func_name_keyword				{ $$ = strdup($1); }
			| reserved_keyword						{ $$ = strdup($1); }
		;

unreserved_keyword:
			 ALSO
			| AT
			| BY
			| CHARACTERISTICS
			| CHECKPOINT
			| CLASS
			| CLOSE
			| CLUSTER
			| COLUMNS
			| COMMENT
			| COMMENTS
			| COMMIT
			| COMMITTED
			| CONFIGURATION
			| CONFLICT
			| CONNECTION
			| CONSTRAINTS
			| CONTENT_P
			| CONTINUE_P
			| CONVERSION_P
			| COPY
			| COST
			| CSV
			| CUBE
			| CURRENT_P
			| CURSOR
			| CYCLE
			| DATA_P
			| DATABASE
			| DAY_P
			| DEALLOCATE
			| DECLARE
			| DEFAULTS
			| DEFERRED
			| DEFINER
			| DELETE_P
			| DELIMITER
			| DELIMITERS
			| DEPENDS
			| DETACH
			| DICTIONARY
			| DISABLE_P
			| DISCARD
			| DOCUMENT_P
			| DOMAIN_P
			| DOUBLE_P
			| DROP
			| EACH
			| ENABLE_P
			| ENCODING
			| ENCRYPTED
			| ENUM_P
			| ESCAPE
			| EVENT
			| EXCLUDE
			| EXCLUDING
			| EXCLUSIVE
			| EXECUTE
			| EXPLAIN
			| EXTENSION
			| EXTERNAL
			| FAMILY
			| FILTER
			| FIRST_P
			| FOLLOWING
			| FORCE
			| FORWARD
			| FUNCTION
			| FUNCTIONS
			| GENERATED
			| GLOBAL
			| GRANTED
			| GROUPS
			| HANDLER
			| HEADER_P
			| HOLD
			| HOUR_P
			| IDENTITY_P
			| IF_P
			| IMMEDIATE
			| IMMUTABLE
			| IMPLICIT_P
			| IMPORT_P
			| INCLUDE
			| INCLUDING
			| INCREMENT
			| INDEX
			| INDEXES
			| INHERIT
			| INHERITS
			| INLINE_P
			| INPUT_P
			| INSENSITIVE
			| INSERT
			| INSTEAD
			| INVOKER
			| ISOLATION
			| KEY
			| LABEL
			| LANGUAGE
			| LARGE_P
			| LAST_P
			| LEAKPROOF
			| LEVEL
			| LISTEN
			| LOAD
			| LOCAL
			| LOCATION
			| LOCK_P
			| LOCKED
			| LOGGED
			| MAPPING
			| MATCH
			| MATERIALIZED
			| MAXVALUE
			| METHOD
			| MINUTE_P
			| MINVALUE
			| MODE
			| MONTH_P
			| MOVE
			| NAME_P
			| NAMES
			| NEW
			| NEXT
			| NO
			| NOTHING
			| NOTIFY
			| NOWAIT
			| NULLS_P
			| OBJECT_P
			| OF
			| OFF
			| OIDS
			| OLD
			| OPERATOR
			| OPTION
			| OPTIONS
			| ORDINALITY
			| OTHERS
			| OVER
			| OVERRIDING
			| OWNED
			| OWNER
			| PARALLEL
			| PARSER
			| PARTIAL
			| PARTITION
			| PASSING
			| PASSWORD
			| PLANS
			| POLICY
			| PRECEDING
			| PREPARE
			| PREPARED
			| PRESERVE
			| PRIOR
			| PRIVILEGES
			| PROCEDURAL
			| PROCEDURE
			| PROCEDURES
			| PROGRAM
			| PUBLICATION
			| QUOTE
			| RANGE
			| READ
			| REASSIGN
			| RECHECK
			| RECURSIVE
			| REF
			| REFERENCING
			| REFRESH
			| REINDEX
			| RELATIVE_P
			| RELEASE
			| RENAME
			| REPEATABLE
			| REPLACE
			| REPLICA
			| RESET
			| RESTART
			| RESTRICT
			| REVOKE
			| ROLE
			| ROLLBACK
			| ROLLUP
			| ROUTINE
			| ROUTINES
			| ROWS
			| RULE
			| SAVEPOINT
			| SCHEMA
			| SCHEMAS
			| SCROLL
			| SEARCH
			| SECOND_P
			| SECURITY
			| SEQUENCE
			| SEQUENCES
			| SERIALIZABLE
			| SERVER
			| SESSION
			| SET
			| SETS
			| SHARE
			| SHOW
			| SIMPLE
			| SKIP
			| SNAPSHOT
			| SQL_P
			| STABLE
			| STANDALONE_P
			| START
			| STATEMENT
			| STATISTICS
			| STDIN
			| STDOUT
			| STORAGE
			| STRICT_P
			| STRIP_P
			| SUBSCRIPTION
			| SYSID
			| SYSTEM_P
			| TABLES
			| TABLESPACE
			| TEMP
			| TEMPLATE
			| TEMPORARY
			| TEXT_P
			| TIES
			| TRANSACTION
			| TRANSFORM
			| TRIGGER
			| TRUNCATE
			| TRUSTED
			| TYPE_P
			| TYPES_P
			| UNBOUNDED
			| UNCOMMITTED
			| UNENCRYPTED
			| UNKNOWN
			| UNLISTEN
			| UNLOGGED
			| UNTIL
			| UPDATE
			| VACUUM
			| VALID
			| VALIDATE
			| VALIDATOR
			| VALUE_P
			| VARYING
			| VERSION_P
			| VIEW
			| VIEWS
			| VOLATILE
			| WHITESPACE_P
			| WITHIN
			| WITHOUT
			| WORK
			| WRAPPER
			| WRITE
			| XML_P
			| YEAR_P
			| YES_P
			| ZONE
		;

col_name_keyword:
			  BETWEEN
			| BIGINT
			| BOOLEAN_P
			| COALESCE
			| DEC
			| DECIMAL_P
			| EXISTS
			| EXTRACT
			| FLOAT_P
			| GREATEST
			| GROUPING
			| INOUT
			| INT_P
			| INTEGER
			| INTERVAL
			| LEAST
			| NATIONAL
			| NCHAR
			| NONE
			| NULLIF
			| NUMERIC
			| OUT_P
			| OVERLAY
			| POSITION
			| PRECISION
			| REAL
			| ROW
			| SETOF
			| SMALLINT
			| SUBSTRING
			| TIME
			| TIMESTAMP
			| TREAT
			| TRIM
			| VALUES
			| VARCHAR
			| XMLATTRIBUTES
			| XMLCONCAT
			| XMLELEMENT
			| XMLEXISTS
			| XMLFOREST
			| XMLNAMESPACES
			| XMLPARSE
			| XMLPI
			| XMLROOT
			| XMLSERIALIZE
			| XMLTABLE
		;

/* Type/function identifier --- keywords that can be type or function names.
 *
 * Most of these are keywords that are used as operators in expressions;
 * in general such keywords can't be column names because they would be
 * ambiguous with variables, but they are unambiguous as function identifiers.
 *
 * Do not include POSITION, SUBSTRING, etc here since they have explicit
 * productions in a_expr to support the goofy SQL9x argument syntax.
 * - thomas 2000-11-28
 */
type_func_name_keyword:
			 COLLATION
			| CONCURRENTLY
			| CROSS
			| CURRENT_SCHEMA
			| FREEZE
			| FULL
			| ILIKE
			| INNER_P
			| IS
			| ISNULL
			| JOIN
			| LEFT
			| LIKE
			| NATURAL
			| NOTNULL
			| OUTER_P
			| OVERLAPS
			| RIGHT
			| SIMILAR
			| TABLESAMPLE
			| VERBOSE
		;

/* Reserved keyword --- these keywords are usable only as a ColLabel.
 *
 * Keywords appear here if they could not be distinguished from variable,
 * type, or function names in some contexts.  Don't put things here unless
 * forced to.
 */
reserved_keyword:
			  ALL
			| AND
			| ANY
			| AS
			| ASC
			| CASE
			| CAST
			| CHECK
			| COLLATE
			| COLUMN
			| CONSTRAINT
			| CREATE
			| CURRENT_CATALOG
			| CURRENT_DATE
			| CURRENT_ROLE
			| CURRENT_TIME
			| CURRENT_TIMESTAMP
			| CURRENT_USER
			| DEFAULT
			| DEFERRABLE
			| DESC
			| DISTINCT
			| DO
			| ELSE
			| END_P
			| EXCEPT
			| FALSE_P
			| FETCH
			| FOR
			| FOREIGN
			| FROM
			| GRANT
			| GROUP_P
			| HAVING
			| IN_P
			| INITIALLY
			| INTERSECT
			| INTO
			| LATERAL_P
			| LEADING
			| LIMIT
			| LOCALTIME
			| LOCALTIMESTAMP
			| NOT
			| NULL_P
			| OFFSET
			| ON
			| ONLY
			| OR
			| ORDER
			| PLACING
			| PRIMARY
			| REFERENCES
			| RETURNING
			| SELECT
			| SESSION_USER
			| SOME
			| SYMMETRIC
			| TABLE
			| THEN
			| TO
			| TRAILING
			| TRUE_P
			| UNION
			| UNIQUE
			| USER
			| USING
			| VARIADIC
			| WHEN
			| WHERE
			| WINDOW
			| WITH
		;


%%

static RawStmt *
makeRawStmt(Node *stmt)
{
	RawStmt    *rs = makeNode(RawStmt);
	rs->stmt = stmt;
	return rs;
}

static Node *
makeColumnRef(char *colname,  List *indirection, core_yyscan_t yyscanner)
{
	ColumnRef  *c = makeNode(ColumnRef);
	int		nfields = 0;
	ListCell *l;

	foreach(l, indirection)
	{
		if (IsA(lfirst(l), A_Star))
		{
			/* We only allow '*' at the end of a ColumnRef */
			if (lnext(l) != NULL)
				base_yyerror("improper use of \"*\"");
		}
		nfields++;
	}
	/* No subscripting, so all indirection gets added to field list */
	c->fields = lcons(makeString(colname), indirection);
	return (Node *) c;


	c->fields = list_make1(makeString(colname));
	return (Node *) c;
}

static Node *
makeIntConst(int val)
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_Integer;
	n->val.val.ival = val;

	return (Node *)n;
}

static Node *
makeFloatConst(char *str)
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_Float;
	n->val.val.str = str;

	return (Node *)n;
}

static Node *
makeStringConst(char *str)
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_String;
	n->val.val.str = str;

	return (Node *)n;
}

static Node *
makeNullAConst()
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_Null;

	return (Node *)n;
}

static Node *
makeAConst(Value *v)
{
	Node *n;

	switch (v->type)
	{
		case T_Float:
			n = makeFloatConst(v->val.str);
			break;

		case T_Integer:
			n = makeIntConst(v->val.ival);
			break;

		case T_String:
		default:
			n = makeStringConst(v->val.str);
			break;
	}

	return n;
}

/* makeBoolAConst()
 * Create an A_Const string node and put it inside a boolean cast.
 */
static Node *
makeBoolAConst(bool state)
{
	A_Const *n = makeNode(A_Const);

	n->val.type = T_String;
	n->val.val.str = (state ? "t" : "f");

	return makeTypeCast((Node *)n, SystemTypeName("bool"));
}


static Node *
makeTypeCast(Node *arg, TypeName *typename)
{
	TypeCast *n = makeNode(TypeCast);
	n->arg = arg;
	n->typeName = typename;
	return (Node *) n;
}

static Node *
makeStringConstCast(char *str, TypeName *typename)
{
	Node *s = makeStringConst(str);

	return makeTypeCast(s, typename);
}

List *
SystemFuncName(char *name)
{
	return list_make2(makeString("pg_catalog"), makeString(name));
}

static TypeName *
SystemTypeName(char *name)
{
	return makeTypeNameFromNameList(list_make2(makeString("pg_catalog"),
											   makeString(name)));
}

static Node *
doNegate(Node *n)
{
	if (IsA(n, A_Const))
	{
		A_Const *con = (A_Const *)n;

		if (con->val.type == T_Integer)
		{
			con->val.val.ival = -con->val.val.ival;
			return n;
		}
		if (con->val.type == T_Float)
		{
			doNegateFloat(&con->val);
			return n;
		}
	}

	return (Node *) makeSimpleA_Expr(AEXPR_OP, "-", NULL, n);
}

static void
doNegateFloat(Value *v)
{
	char   *oldval = v->val.str;

	if (*oldval == '+')
		oldval++;
	if (*oldval == '-')
		v->val.str = oldval+1;	/* just strip the '-' */
	else
		v->val.str = psprintf("-%s", oldval);
}

static Node *
makeAndExpr(Node *lexpr, Node *rexpr)
{
	Node	   *lexp = lexpr;

	/* Look through AEXPR_PAREN nodes so they don't affect flattening */
	while (IsA(lexp, A_Expr) &&
		   ((A_Expr *) lexp)->kind == AEXPR_PAREN)
		lexp = ((A_Expr *) lexp)->lexpr;
	/* Flatten "a AND b AND c ..." to a single BoolExpr on sight */
	if (IsA(lexp, BoolExpr))
	{
		BoolExpr *blexpr = (BoolExpr *) lexp;

		if (blexpr->boolop == AND_EXPR)
		{
			blexpr->args = lappend(blexpr->args, rexpr);
			return (Node *) blexpr;
		}
	}
	return (Node *) makeBoolExpr(AND_EXPR, list_make2(lexpr, rexpr));
}

static Node *
makeOrExpr(Node *lexpr, Node *rexpr)
{
	Node	   *lexp = lexpr;

	/* Look through AEXPR_PAREN nodes so they don't affect flattening */
	while (IsA(lexp, A_Expr) &&
		   ((A_Expr *) lexp)->kind == AEXPR_PAREN)
		lexp = ((A_Expr *) lexp)->lexpr;
	/* Flatten "a OR b OR c ..." to a single BoolExpr on sight */
	if (IsA(lexp, BoolExpr))
	{
		BoolExpr *blexpr = (BoolExpr *) lexp;

		if (blexpr->boolop == OR_EXPR)
		{
			blexpr->args = lappend(blexpr->args, rexpr);
			return (Node *) blexpr;
		}
	}
	return (Node *) makeBoolExpr(OR_EXPR, list_make2(lexpr, rexpr));
}

static List *
check_indirection(List *indirection, core_yyscan_t yyscanner)
{
	ListCell *l;

	foreach(l, indirection)
	{
		if (IsA(lfirst(l), A_Star))
		{
			if (lnext(l) != NULL)
				base_yyerror("improper use of \"*\"");
		}
	}
	return indirection;
}


static Node *
makeNotExpr(Node *expr)
{
	return (Node *) makeBoolExpr(NOT_EXPR, list_make1(expr));
}

static Node *
makeSetOp(SetOperation op, bool all, Node *larg, Node *rarg)
{
	SelectStmt *n = makeNode(SelectStmt);

	n->op = op;
	n->all = all;
	n->larg = (SelectStmt *) larg;
	n->rarg = (SelectStmt *) rarg;
	return (Node *) n;
}

static void
insertSelectOptions(SelectStmt *stmt,
					List *sortClause, 
					Node *limitOffset, Node *limitCount,
					WithClause *withClause,
					core_yyscan_t yyscanner)
{
	/*
	 * Tests here are to reject constructs like
	 *	(SELECT foo ORDER BY bar) ORDER BY baz
	 */
	if (sortClause)
	{
		if (stmt->sortClause)
		  base_yyerror("multiple ORDER BY clauses not allowed");
		stmt->sortClause = sortClause;
	}
	/* We can handle multiple locking clauses, though */
	if (limitOffset)
	{
		if (stmt->limitOffset)
		  base_yyerror("multiple OFFSET clauses not allowed");
		stmt->limitOffset = limitOffset;
	}
	if (limitCount)
	{
		if (stmt->limitCount)
		  base_yyerror("multiple LIMIT clauses not allowed");
		stmt->limitCount = limitCount;
	}
	if (withClause)
	{
		if (stmt->withClause)
		  base_yyerror("multiple WITH clauses not allowed");
		stmt->withClause = withClause;
	}
}

void
parser_init(base_yy_extra_type *yyext)
{
	yyext->parsetree = NIL;		/* in case grammar forgets to set it */
}

char *
psprintf(const char *fmt,...)
{
	size_t		len = 128;		/* initial assumption about buffer size */

	for (;;)
	{
		char	   *result;
		va_list		args;
		size_t		newlen;

		/*
		 * Allocate result buffer.  Note that in frontend this maps to malloc
		 * with exit-on-error.
		 */
		result = (char *) malloc(len);

		/* Try to format the data. */
		va_start(args, fmt);
		newlen = vsnprintf(result, len, fmt, args);
		va_end(args);

		if (newlen < len)
			return result;		/* success */

		/* Release buffer and loop around to try again with larger len. */
		free(result);
		len = newlen;
	}
}



