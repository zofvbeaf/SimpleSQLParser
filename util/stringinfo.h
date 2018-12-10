#pragma once

#include <stdarg.h>

typedef struct StringInfoData
{
	char	   *data;
	int			len;
	int			maxlen;
	int			cursor;
} StringInfoData;

typedef StringInfoData *StringInfo;

extern void initStringInfo(StringInfo str);

extern void resetStringInfo(StringInfo str);

extern void appendStringInfoString(StringInfo str, const char *s);

extern void appendBinaryStringInfo(StringInfo str,
					   const char *data, int datalen);

extern void enlargeStringInfo(StringInfo str, int needed);

extern void appendStringInfoChar(StringInfo str, char ch);

extern void appendStringInfo(StringInfo str, const char *fmt,...);

extern int	appendStringInfoVA(StringInfo str, const char *fmt, va_list args);

#define appendStringInfoCharMacro(str,ch) \
	(((str)->len + 1 >= (str)->maxlen) ? \
	 appendStringInfoChar(str, ch) : \
	 (void)((str)->data[(str)->len] = (ch), (str)->data[++(str)->len] = '\0'))


