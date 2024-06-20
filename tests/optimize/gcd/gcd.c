#include <stdio.h>

int main()
{
	int a = 32;
	int b = 48;

	while (a != b)
	{
		if (a > b)
		{
			a = a - b;
		} else
		{
			b = b - a;
		}
	}

	printf("%i\n", a);
}
