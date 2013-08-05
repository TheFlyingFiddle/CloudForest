module math.rect;
import math.vector;
import std.math;

alias float4 Rect;


auto left(float4 vec) @property
{
	return vec.x;
}

auto right(float4 vec) @property
{
	return vec.x + vec.z;
}

auto bottom(float4 vec) @property
{
	return vec.y;
}

auto top(float4 vec) @property
{
	return vec.y + vec.w;
}

auto width(float4 vec) @property
{
	return vec.z;
}

auto height(float4 vec) @property
{
	return vec.w;
}


bool pointInRect(float4 rect, float2 point)
{
	return rect.x < point.x && rect.x + rect.z > point.x &&
			 rect.y < point.y && rect.y + rect.w > point.y;
}