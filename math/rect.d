module math.rect;
import math.vector;
import std.math;


struct Rect
{
	enum Rect zero = Rect(0,0,0,0);

	float x,y,w,h;

	this(float x, float y, float w, float h)
	{
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}

	this(float2 bottomLeft, float2 topRight)
	{
		this.x = bottomLeft.x;
		this.y = bottomLeft.y;
		this.w = topRight.x - bottomLeft.x;
		this.h = topRight.y - bottomLeft.y;
	}

	float left() const @property
	{
		return x;
	}

	float right() const @property
	{
		return x + w;
	}

	float bottom() const @property
	{
		return y;
	}

	float top() const @property
	{
		return y + h;
	}

	float2 topLeft() const @property
	{
		return float2(left, top);
	}

	float2 topRight() const @property
	{
		return float2(right, top);
	}

	float2 bottomLeft() const @property
	{
		return float2(left, bottom);
	}

	float2 bottomRight() const @property
	{
		return float2(right, bottom);
	}

	bool intersects(float2 point) 
	{
		return point.x > left   && point.x < right 
			 && point.y > bottom && point.y < top;
	}

	static bool intersects(Rect a, Rect b)
	{

		return !(a.left   > b.right  ||
					a.right  < b.left   ||
					a.top    < b.bottom ||
					a.bottom > b.top);

	}

	static Rect intersection(Rect a, Rect b)
	{
		float left    = fmax(a.left, b.left);
		float bottom  = fmax(a.bottom, b.bottom);
		float top	  = fmin(a.top, b.top);
		float right	  = fmin(a.right, b.right);

		if(top < bottom || right < left)
			return Rect.zero;

		return Rect(left, bottom, right - left, top - bottom);
	}

	void shrink(Rect other)
	{
		x += other.x;
		y += other.y;
		w -= other.x + other.w;
		h -= other.y + other.h;
	}

	void displace(float2 pos)
	{
		x += pos.x;
		y += pos.y;
	}
}