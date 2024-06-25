#include <stdio.h>

int gcd(int a, int b)
{
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
}

int main()
{
	printf("%i\n", gcd(32, 48));
}
