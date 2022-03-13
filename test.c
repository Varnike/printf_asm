#include <stdio.h>

extern int Print(const char *str, ...);

int main()
{
	int a = 999;
	Print("%d\n", a);
}
