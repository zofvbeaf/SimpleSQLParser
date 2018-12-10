#include "util/stringinfo.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#ifndef Size
typedef size_t Size;
#endif

#define MaxAllocSize	((Size) 0x3fffffff)		/* 1 gigabyte - 1 */

void
initStringInfo(StringInfo str)
{
	int			size = 1024;	/* initial default buffer size */

	str->data = (char *) malloc(size);
	str->maxlen = size;
	resetStringInfo(str);
}

void
resetStringInfo(StringInfo str)
{
	str->data[0] = '\0';
	str->len = 0;
	str->cursor = 0;
}

void
appendStringInfoString(StringInfo str, const char *s)
{
	appendBinaryStringInfo(str, s, strlen(s));
}

void
appendBinaryStringInfo(StringInfo str, const char *data, int datalen)
{

	/* Make more room if needed */
	enlargeStringInfo(str, datalen);

	/* OK, append the data */
	memcpy(str->data + str->len, data, datalen);
	str->len += datalen;

	/*
	 * Keep a trailing null in place, even though it's probably useless for
	 * binary data.  (Some callers are dealing with text but call this because
	 * their input isn't null-terminated.)
	 */
	str->data[str->len] = '\0';
}

void
enlargeStringInfo(StringInfo str, int needed)
{
	int			newlen;

	/*
	 * Guard against out-of-range "needed" values.  Without this, we can get
	 * an overflow or infinite loop in the following.
	 */
	if (needed < 0)				/* should not happen */
		fprintf(stderr, "invalid string enlargement request size: %d", needed);
	if (((Size) needed) >= (MaxAllocSize - (Size) str->len))
	  fprintf(stderr, "Cannot enlarge string buffer containing %d bytes by %d more bytes.", str->len, needed);

	needed += str->len + 1;		/* total space required now */

	/* Because of the above test, we now have needed <= MaxAllocSize */

	if (needed <= str->maxlen)
		return;					/* got enough space already */

	/*
	 * We don't want to allocate just a little more space with each append;
	 * for efficiency, double the buffer size each time it overflows.
	 * Actually, we might need to more than double it if 'needed' is big...
	 */
	newlen = 2 * str->maxlen;
	while (needed > newlen)
		newlen = 2 * newlen;

	/*
	 * Clamp to MaxAllocSize in case we went past it.  Note we are assuming
	 * here that MaxAllocSize <= INT_MAX/2, else the above loop could
	 * overflow.  We will still have newlen >= needed.
	 */
	if (newlen > (int) MaxAllocSize)
		newlen = (int) MaxAllocSize;

	str->data = (char *) realloc(str->data, newlen);

	str->maxlen = newlen;
}

void
appendStringInfoChar(StringInfo str, char ch)
{
	/* Make more room if needed */
	if (str->len + 1 >= str->maxlen)
		enlargeStringInfo(str, 1);

	/* OK, append the character */
	str->data[str->len] = ch;
	str->len++;
	str->data[str->len] = '\0';
}

void
appendStringInfo(StringInfo str, const char *fmt,...)
{
	for (;;)
	{
		va_list		args;
		int			needed;

		/* Try to format the data. */
		va_start(args, fmt);
		needed = appendStringInfoVA(str, fmt, args);
		va_end(args);

		if (needed == 0)
			break;				/* success */

		/* Increase the buffer size and try again. */
		enlargeStringInfo(str, needed);
	}
}

int
appendStringInfoVA(StringInfo str, const char *fmt, va_list args)
{
	int			avail;
	size_t		nprinted;


	/*
	 * If there's hardly any space, don't bother trying, just fail to make the
	 * caller enlarge the buffer first.  We have to guess at how much to
	 * enlarge, since we're skipping the formatting work.
	 */
	avail = str->maxlen - str->len;
	if (avail < 16)
		return 32;

	nprinted = vsnprintf(str->data + str->len, (size_t) avail, fmt, args);

	if (nprinted < (size_t) avail)
	{
		/* Success.  Note nprinted does not include trailing null. */
		str->len += (int) nprinted;
		return 0;
	}

	/* Restore the trailing null so that str is unmodified. */
	str->data[str->len] = '\0';

	/*
	 * Return pvsnprintf's estimate of the space needed.  (Although this is
	 * given as a size_t, we know it will fit in int because it's not more
	 * than MaxAllocSize.)
	 */
	return (int) nprinted;
}


