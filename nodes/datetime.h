#pragma once

#define MONTH	1
#define YEAR	2
#define DAY		3

#define HOUR	10
#define MINUTE	11
#define SECOND	12
#define MILLISECOND 13
#define MICROSECOND 14
#define WEEK		24

#define INTERVAL_FULL_RANGE (0x7FFF)
#define INTERVAL_MASK(b) (1 << (b))
