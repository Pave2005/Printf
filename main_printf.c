#include <stdio.h>
#include <stdlib.h>

extern void MyPrintf(char * str, ...);

int main()
{
    MyPrintf ("\n\n%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n\n", -20,
                                                                  -1, "love", 3802, 100, 33, 127,
                                                                  -1, "love", 3802, 100, 33, 127);
}
