module graphics.color;

import math.helper;
import std.string : format;

struct Color
{
	private uint packedValue;

	@property float r() 
	{
		return (packedValue & 0xFF) / cast(float)0xFF; 
	}

	@property void r(float value) 
	{ 
		this.packedValue = (packedValue & 0xFFFFFF00) | cast(uint)(value * 0xFF); 
	}

	@property float g()
	{ 
		return ((packedValue >> 8) & 0xFF) / cast(float)0xFF; 
	}

	@property void g(float value)
	{ 
		this.packedValue = (packedValue & 0xFFFF00FF) | (cast(uint)(value * 0xFF) << 8); 
	}

	@property float b() 
	{
		return ((packedValue >> 16) & 0xFF) / cast(float)0xFF;
	}

	@property void b(float value) 
	{
		this.packedValue = (packedValue & 0xFF00FFFF) | (cast(uint)(value * 0xFF) << 16);
	}

	@property float a() 
	{
		return ((packedValue >> 24) & 0xFF) /  cast(float)0xFF;
	}

	@property void a(float value) 
	{
		this.packedValue = (packedValue & 0x00FFFFFF) | (cast(uint)(value * 0xFF) << 24);
	}

	this(uint hexColor) 
	{
		this.packedValue = hexColor;
	}

	this(uint r, uint g, uint b, uint a) 
	{
		this(cast(float)r / 255f, cast(float)g / 255f,cast(float)b / 255f,cast(float)a / 255f);
	}

	this(float r, float g, float b, float a)
	{
		uint red = cast(uint)(clamp(r,0f,1f) * 0xFF) << 0;
		uint green = cast(uint)(clamp(g,0f,1f) * 0xFF) << 8;
		uint blue = cast(uint)(clamp(b,0f,1f) * 0xFF) << 16;
		uint alpha = (cast(uint)(clamp(a,0f,1f) * 0xFF) << 24);

		this.packedValue = red | green | blue | alpha;
	}

	Color opBinary(string op)(float scalar) if(op == "*") 
	{
		scalar = clamp(scalar, 0f, 1f);
		return Color(this.r * scalar, this.g * scalar, this.b * scalar, scalar);
	}

	string toString() 
	{
		return format("r:%f, g:%f, b:%f, a:%f", r,g,b,a);
	}


	//Implicit conversion to vector4.
	math.vector.float4 toVector4() @property
	{
		return math.vector.float4(r,g,b,a);
	}


	enum Color transparent = Color(0);
	enum Color black = Color(0xFF000000);
	enum Color white = Color(0xFFFFFFFF);
	enum Color blue = Color(0xFFFF0000);
	enum Color green = Color(0xFF00FF00);
	enum Color red = Color(0xFF0000FF);
}