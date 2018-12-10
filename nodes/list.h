#ifndef PG_LIST_H
#define PG_LIST_H

#include "nodes/nodes.h"

#define NIL						((List *) NULL)

typedef struct ListCell ListCell;

typedef struct List
{
	NodeTag		type;			/* T_List, T_IntList, or T_OidList */
	int			length;
	ListCell   *head;
	ListCell   *tail;
} List;

struct ListCell
{
	union
	{
		void	   *ptr_value;
		int			int_value;
		Oid			oid_value;
	}			data;
	ListCell   *next;
};

/*
 * These routines are used frequently. However, we can't implement
 * them as macros, since we want to avoid double-evaluation of macro
 * arguments.
 */
static inline ListCell *
list_head(const List *l)
{
	return l ? l->head : NULL;
}

static inline ListCell *
list_tail(List *l)
{
	return l ? l->tail : NULL;
}

static inline int
list_length(const List *l)
{
	return l ? l->length : 0;
}

/*
 * NB: There is an unfortunate legacy from a previous incarnation of
 * the List API: the macro lfirst() was used to mean "the data in this
 * cons cell". To avoid changing every usage of lfirst(), that meaning
 * has been kept. As a result, lfirst() takes a ListCell and returns
 * the data it contains; to get the data in the first cell of a
 * List, use linitial(). Worse, lsecond() is more closely related to
 * linitial() than lfirst(): given a List, lsecond() returns the data
 * in the second cons cell.
 */

#define lnext(lc)				((lc)->next)
#define lfirst(lc)				((lc)->data.ptr_value)
#define lfirst_int(lc)			((lc)->data.int_value)
#define lfirst_oid(lc)			((lc)->data.oid_value)
#define lfirst_node(type,lc)	castNode(type, lfirst(lc))

#define linitial(l)				lfirst(list_head(l))
#define linitial_int(l)			lfirst_int(list_head(l))
#define linitial_oid(l)			lfirst_oid(list_head(l))
#define linitial_node(type,l)	castNode(type, linitial(l))

#define lsecond(l)				lfirst(lnext(list_head(l)))
#define lsecond_int(l)			lfirst_int(lnext(list_head(l)))
#define lsecond_oid(l)			lfirst_oid(lnext(list_head(l)))
#define lsecond_node(type,l)	castNode(type, lsecond(l))

#define lthird(l)				lfirst(lnext(lnext(list_head(l))))
#define lthird_int(l)			lfirst_int(lnext(lnext(list_head(l))))
#define lthird_oid(l)			lfirst_oid(lnext(lnext(list_head(l))))
#define lthird_node(type,l)		castNode(type, lthird(l))

#define lfourth(l)				lfirst(lnext(lnext(lnext(list_head(l)))))
#define lfourth_int(l)			lfirst_int(lnext(lnext(lnext(list_head(l)))))
#define lfourth_oid(l)			lfirst_oid(lnext(lnext(lnext(list_head(l)))))
#define lfourth_node(type,l)	castNode(type, lfourth(l))

#define llast(l)				lfirst(list_tail(l))
#define llast_int(l)			lfirst_int(list_tail(l))
#define llast_oid(l)			lfirst_oid(list_tail(l))
#define llast_node(type,l)		castNode(type, llast(l))

/*
 * Convenience macros for building fixed-length lists
 */
#define list_make1(x1)				lcons(x1, NIL)
#define list_make2(x1,x2)			lcons(x1, list_make1(x2))
#define list_make3(x1,x2,x3)		lcons(x1, list_make2(x2, x3))
#define list_make4(x1,x2,x3,x4)		lcons(x1, list_make3(x2, x3, x4))
#define list_make5(x1,x2,x3,x4,x5)	lcons(x1, list_make4(x2, x3, x4, x5))

#define list_make1_int(x1)			lcons_int(x1, NIL)
#define list_make2_int(x1,x2)		lcons_int(x1, list_make1_int(x2))
#define list_make3_int(x1,x2,x3)	lcons_int(x1, list_make2_int(x2, x3))
#define list_make4_int(x1,x2,x3,x4) lcons_int(x1, list_make3_int(x2, x3, x4))
#define list_make5_int(x1,x2,x3,x4,x5)	lcons_int(x1, list_make4_int(x2, x3, x4, x5))

#define list_make1_oid(x1)			lcons_oid(x1, NIL)
#define list_make2_oid(x1,x2)		lcons_oid(x1, list_make1_oid(x2))
#define list_make3_oid(x1,x2,x3)	lcons_oid(x1, list_make2_oid(x2, x3))
#define list_make4_oid(x1,x2,x3,x4) lcons_oid(x1, list_make3_oid(x2, x3, x4))
#define list_make5_oid(x1,x2,x3,x4,x5)	lcons_oid(x1, list_make4_oid(x2, x3, x4, x5))

/*
 * foreach -
 *	  a convenience macro which loops through the list
 */
#define foreach(cell, l)	\
	for ((cell) = list_head(l); (cell) != NULL; (cell) = lnext(cell))

/*
 * for_each_cell -
 *	  a convenience macro which loops through a list starting from a
 *	  specified cell
 */
#define for_each_cell(cell, initcell)	\
	for ((cell) = (initcell); (cell) != NULL; (cell) = lnext(cell))

/*
 * forboth -
 *	  a convenience macro for advancing through two linked lists
 *	  simultaneously. This macro loops through both lists at the same
 *	  time, stopping when either list runs out of elements. Depending
 *	  on the requirements of the call site, it may also be wise to
 *	  assert that the lengths of the two lists are equal.
 */
#define forboth(cell1, list1, cell2, list2)							\
	for ((cell1) = list_head(list1), (cell2) = list_head(list2);	\
		 (cell1) != NULL && (cell2) != NULL;						\
		 (cell1) = lnext(cell1), (cell2) = lnext(cell2))

/*
 * for_both_cell -
 *	  a convenience macro which loops through two lists starting from the
 *	  specified cells of each. This macro loops through both lists at the same
 *	  time, stopping when either list runs out of elements.  Depending on the
 *	  requirements of the call site, it may also be wise to assert that the
 *	  lengths of the two lists are equal, and initcell1 and initcell2 are at
 *	  the same position in the respective lists.
 */
#define for_both_cell(cell1, initcell1, cell2, initcell2)	\
	for ((cell1) = (initcell1), (cell2) = (initcell2);		\
		 (cell1) != NULL && (cell2) != NULL;				\
		 (cell1) = lnext(cell1), (cell2) = lnext(cell2))

/*
 * forthree -
 *	  the same for three lists
 */
#define forthree(cell1, list1, cell2, list2, cell3, list3)			\
	for ((cell1) = list_head(list1), (cell2) = list_head(list2), (cell3) = list_head(list3); \
		 (cell1) != NULL && (cell2) != NULL && (cell3) != NULL;		\
		 (cell1) = lnext(cell1), (cell2) = lnext(cell2), (cell3) = lnext(cell3))

extern List *lappend(List *list, void *datum);
extern List *lappend_int(List *list, int datum);
extern List *lappend_oid(List *list, Oid datum);

extern ListCell *lappend_cell(List *list, ListCell *prev, void *datum);
extern ListCell *lappend_cell_int(List *list, ListCell *prev, int datum);
extern ListCell *lappend_cell_oid(List *list, ListCell *prev, Oid datum);

extern List *lcons(void *datum, List *list);
extern List *lcons_int(int datum, List *list);
extern List *lcons_oid(Oid datum, List *list);

extern List *list_concat(List *list1, List *list2);
extern List *list_truncate(List *list, int new_size);

extern ListCell *list_nth_cell(const List *list, int n);
extern void *list_nth(const List *list, int n);
extern int	list_nth_int(const List *list, int n);
extern Oid	list_nth_oid(const List *list, int n);
#define list_nth_node(type,list,n)	castNode(type, list_nth(list, n))

extern bool list_member(const List *list, const void *datum);
extern bool list_member_ptr(const List *list, const void *datum);
extern bool list_member_int(const List *list, int datum);
extern bool list_member_oid(const List *list, Oid datum);

//extern List *list_delete(List *list, void *datum);
extern List *list_delete_ptr(List *list, void *datum);
extern List *list_delete_int(List *list, int datum);
extern List *list_delete_oid(List *list, Oid datum);
extern List *list_delete_first(List *list);
extern List *list_delete_cell(List *list, ListCell *cell, ListCell *prev);

//extern List *list_union(const List *list1, const List *list2);
extern List *list_union_ptr(const List *list1, const List *list2);
extern List *list_union_int(const List *list1, const List *list2);
extern List *list_union_oid(const List *list1, const List *list2);

extern List *list_intersection(const List *list1, const List *list2);
extern List *list_intersection_int(const List *list1, const List *list2);

/* currently, there's no need for list_intersection_ptr etc */

//extern List *list_difference(const List *list1, const List *list2);
extern List *list_difference_ptr(const List *list1, const List *list2);
extern List *list_difference_int(const List *list1, const List *list2);
extern List *list_difference_oid(const List *list1, const List *list2);

//extern List *list_append_unique(List *list, void *datum);
extern List *list_append_unique_ptr(List *list, void *datum);
extern List *list_append_unique_int(List *list, int datum);
extern List *list_append_unique_oid(List *list, Oid datum);

//extern List *list_concat_unique(List *list1, List *list2);
extern List *list_concat_unique_ptr(List *list1, List *list2);
extern List *list_concat_unique_int(List *list1, List *list2);
extern List *list_concat_unique_oid(List *list1, List *list2);

extern void list_free(List *list);
extern void list_free_deep(List *list);

extern List *list_copy(const List *list);
extern List *list_copy_tail(const List *list, int nskip);

typedef int (*list_qsort_comparator) (const void *a, const void *b);
extern List *list_qsort(const List *list, list_qsort_comparator cmp);

#endif							/* PG_LIST_H */
