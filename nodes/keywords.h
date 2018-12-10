#pragma once

#include <string.h>

#define NAMEDATALEN 64

#define UNRESERVED_KEYWORD		0
#define COL_NAME_KEYWORD		1
#define TYPE_FUNC_NAME_KEYWORD	2
#define RESERVED_KEYWORD		3

#define PG_KEYWORD(a,b,c) {a,b,c},
#define lengthof(array) (sizeof (array) / sizeof ((array)[0])) 

typedef struct ScanKeyword
{
	const char *name;			/* in lower case */
	int		value;			/* grammar's token code */
	int		category;		/* see codes above */
} ScanKeyword;


extern const ScanKeyword ScanKeywords[];
extern const int NumScanKeywords;

extern const ScanKeyword *ScanKeywordLookup(const char *text,
				  const ScanKeyword *keywords,
				  int num_keywords);

