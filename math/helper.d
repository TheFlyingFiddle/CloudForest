module math.helper;

public import std.math;

static T clamp(T)(T value, T min, T max)
{
	if (value < min)
		return min;
	else if (value > max)
		return max;
	else
		return value;
}