module test;

export extern(C) int testFunction(double a, float b)
{
	return cast(int)(a + b);
}