module math.vector;
import std.stdio;
import std.conv;
import std.range: iota;
import std.algorithm;
import std.traits;
import std.string;
import core.exception : RangeError, AssertError;
import std.regex;
import utils.assertions;

alias Vector2!(float) float2;
alias Vector3!(float) float3;
alias Vector4!(float) float4;

alias Vector2!(short) short2;
alias Vector3!(short) short3;
alias Vector4!(short) short4;

alias Vector2!(ushort) ushort2;
alias Vector3!(ushort) ushort3;
alias Vector4!(ushort) ushort4;

alias Vector2!(double) double2;
alias Vector3!(double) double3;
alias Vector4!(double) double4;

alias Vector2!(int) int2;
alias Vector3!(int) int3;
alias Vector4!(int) int4;

alias Vector2!(uint) uint2;
alias Vector3!(uint) uint3;
alias Vector4!(uint) uint4;

struct Vector2(T) if(isNumeric!T)
{
	
	enum zero = Vector2!T(0,0);
	enum one  = Vector2!T(1,1);

	T x,y;

	Vector2!T opBinary(string op)(Vector2!T rhs) if (op == "+" ||
																	 op == "-" ||
																	 op == "*") 
	{
		mixin("auto vec = Vector2!T;
				vec.x = x"~op~"rhs.x;
				vec.y = y"~op~"rhs.y;
				return vec;");
	}

	Vector2!T opBinary(string op)(T rhs) if (op == "*") 
	{
		mixin("auto vec = Vector3!T;
				vec.x = x"~op~"rhs;
				vec.y = y"~op~"rhs;
				return vec;");
	}

	auto dot(Vector2!T rhs)
	{
		return x*rhs.x + y*rhs.y;
	}

	void opAssign(Vector2!T rhs)
	{
		this.x = rhs.x;
		this.y = rhs.y;
	}

	void opAssign(T rhs)
	{
		this.x = rhs;
		this.y = rhs;
	}

	T opIndex(uint index)
	in
	{
		assert(index<2);
	}
	body
	{
		if(index)
			return y;
		else
			return x;
	}

	void opIndexAssign(T val, uint index)
	in
	{
		assert(index<2);
	}
	body
	{
		if(val)
			y = val;
		else
			x = val;
	}	
	
	ref Vector2 opOpAssign(string op)(Vector2!T vec)
	{
		mixin("this.x "~op~"= vec.x");
		mixin("this.y "~op~"= vec.y");
	}


	auto opDispatch(string m)() if(validSwizzle!(m,2)()
											 && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = "Vector"~to!string(length)~"!T("
			~iota(length).map!(i => "this."~xyzwOnly[i]).join(",")//Generates this.x,... and so forth
			~")";
		return mixin(str);
	}

	unittest
	{
		auto a = int2(1,2);
		assertEquals(a.yxyx, int4(2,1,2,1));
		assertEquals(a.rgr, int3(1,2,1));
	}

	@property void opDispatch(string m, Vector)(Vector vec) if(validSwizzle!(m,2)()
																				  && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = iota(length).map!(i => text("this.",xyzwOnly[i],"= vec[",i,"];")).join();//Generates this.x = vec,this.y... and so forth
		mixin(str);
	}

	unittest
	{
		auto a = int2(1,2);
		a.xy = int2(6,7);
		assertEquals(a, int2(6,7));
		a.rg = a.xx;
		assertEquals(a, int2(6,6));
	}
}

struct Vector3(T) if(isNumeric!T)
{
	enum zero = Vector3!T(0,0,0);
	enum one  = Vector3!T(1,1,1);

	T x, y, z;

	Vector3!T opBinary(string op)(Vector3!T rhs) if (op == "+" ||
																	 op == "-" ||
																	 op == "*") 
	{
		mixin("auto vec = Vector3!T();
				vec.x = x"~op~"rhs.x;
				vec.y = y"~op~"rhs.y;
				vec.z = z"~op~"rhs.z;
				return vec;");
	}

	Vector3!T opBinary(string op)(T rhs) if (op == "*") 
	{
		mixin("auto vec = Vector3!T;
				vec.x = x"~op~"rhs;
				vec.y = y"~op~"rhs;
				vec.z = z"~op~"rhs;
				return vec;");
	}

	auto dot(Vector3!T rhs)
	{
		return x*rhs.x + y*rhs.y + z*rhs.z;
	}

	void opAssign(Vector3!T rhs)
	{
		this.x = rhs.x;
		this.y = rhs.y;
		this.z = rhs.z;
	}

	void opAssign(T rhs)
	{
		this.x = rhs;
		this.y = rhs;
		this.z = rhs;
	}

	T opIndex(uint index)
	in
	{
		assert(index<3);
	}
	body
	{
		switch (index)
		{
			case 0:
				return x;
			case 1:
				return y;
			default:
				return z;
		}
	}

	void opIndexAssign(T val, uint index)
	in
	{
		assert(index<3);
	}
	body
	{
		switch (index)
		{
			case 0:
				x = val;
				break;
			case 1:
				y = val;
				break;
			default:
				z = val;
				break;
		}
	}

	Vector3!T cross(Vector3!T rhs)
	{
		return Vector3!T(
												cast(T)(y*rhs.z - z*rhs.y),
												cast(T)(z*rhs.x - x*rhs.z),
												cast(T)(x*rhs.y - y*rhs.x)
												);
	}

	ref Vector3 opOpAssign(string op)(Vector3!T vec)
	{
		mixin("this.x "~op~"= vec.x");
		mixin("this.y "~op~"= vec.y");
		mixin("this.z "~op~"= vec.z");
		return this;
	}

	auto opDispatch(string m)() if(validSwizzle!(m,3)()
											 && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = "Vector"~to!string(length)~"!T("
			~iota(length).map!(i => "this."~xyzwOnly[i]).join(",")//Generates this.x,... and so forth
			~")";
		return mixin(str);
	}

	unittest
	{
		auto a = int3(1,2,3);
		assertEquals(a.zxyz, int4(3,1,2,3));
		assertEquals(a.rgr, int3(1,2,1));
	}

	@property void opDispatch(string m, Vector)(Vector vec) if(validSwizzle!(m,3)()
																				  && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = iota(length).map!(i => text("this.",xyzwOnly[i],"= vec[",i,"];")).join();//Generates this.x = vec,this.y... and so forth
		mixin(str);
	}


	unittest
	{
		auto a = int3(1,2,3);
		a.xyz = int3(6,7,8);
		assertEquals(a, int3(6,7,8));
		a.rbr = a.xxx;
		assertEquals(a, int3(6,7,6));
	}
}

struct Vector4(T) if(isNumeric!T)
{
	enum zero = Vector4!T(0,0,0,0);
	enum one  = Vector4!T(1,1,1,1);

	T x, y, z, w;

	Vector4!T opBinary(string op)(Vector4!T rhs) if (op == "+" ||
																	 op == "-" ||
																	 op == "*") 
	{
		mixin("auto vec = Vector4!T;
				vec.x = x"~op~"rhs.x;
				vec.y = y"~op~"rhs.y;
				vec.z = z"~op~"rhs.z;
				vec.w = w"~op~"rhs.w;
				return vec;");
	}

	Vector4!T opBinary(string op)(T rhs) if (op == "*") 
	{
		mixin("auto vec = Vector4!T;
				vec.x = x"~op~"rhs;
				vec.y = y"~op~"rhs;
				vec.z = z"~op~"rhs;
				vec.w = w"~op~"rhs;
				return vec;");
	}

	auto dot(Vector4!T rhs)
	{
		return x*rhs.x + y*rhs.y + z*rhs.z + w*rhs.w;
	}

	void opAssign(Vector4!T rhs)
	{
		this.x = rhs.x;
		this.y = rhs.y;
		this.z = rhs.z;
		this.w = rhs.w;
	}

	void opAssign(T rhs)
	{
		this.x = rhs;
		this.y = rhs;
		this.z = rhs;
		this.w = rhs;
	}

	T opIndex(uint index)
	in
	{
		assert(index<4);
	}
	body
	{
		switch (index)
		{
			case 0:
				return x;
			case 1:
				return y;
			case 2:
				return z;
			default:
				return w;
		}
	}

	void opIndexAssign(T val, uint index)
	in
	{
		assert(index<4);
	}
	body
	{
		switch (index)
		{
			case 0:
				x = val;
				break;
			case 1:
				y = val;
				break;
			case 2:
				z = val;
				break;
			default:
				w = val;
				break;
		}
	}

	auto opDispatch(string m)() if(validSwizzle!(m,4)()
															  && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = "Vector"~to!string(length)~"!T("
							~iota(length).map!(i => "this."~xyzwOnly[i]).join(",")//Generates this.x,this.z,... and so forth
							~")";
		return mixin(str);
	}

	unittest
	{
		auto a = int4(1,2,3,4);
		assertEquals(a.wxyz, int4(4,1,2,3));
		assertEquals(a.xyx, int3(1,2,1));
	}

	@property void opDispatch(string m, Vector)(Vector vec) if(validSwizzle!(m,4)()
																	 && m.length<=4)
	{
		enum length = m.length;
		enum xyzwOnly = translateRGBA(m);
		enum str = iota(length).map!(i => text("this.",xyzwOnly[i],"= vec[",i,"];")).join();//Generates this.x = vec,this.y... and so forth
		mixin(str);
	}


	unittest
	{
		auto a = int4(1,2,3,4);
		a.wxyz = int4(5,6,7,8);
		assertEquals(a, int4(6,7,8,5));
		a.rar = a.xxx;
		assertEquals(a, int4(6,7,8,6));
	}
}

//////////////////////////////////////////////////
//		Helper functions
//////////////////////////////////////////////////
private static bool validSwizzle(string str, int numElements)()
{
	enum validChars = contains("xyzw", str[0])?
		"xyzw"[0..numElements]:
	"rgba"[0..numElements];


	for(int i; i<str.length;i++)
	{
		if(!contains(validChars, str[i]))
			return false;
	}
	return true;
}

private static bool contains(string str, char val)
{
	for(int i; i<str.length; i++)
	{
		if(str[i] == val)
			return true;
	}
	return false;
}

private static string translateRGBA(string str)
{
	auto res = "";
	enum toXyzw = ['r':'x','g':'y','b':'z','a':'w'];
	char* cptr;
	foreach(c;str)
	{
		cptr = (c in toXyzw);
		if(cptr)
			res~=*cptr;
		else
			res~=c;
	}
	return res;
}


///Old generic tests
unittest{
	try{
		auto a = int3(2,2,1);
		assert(a == int3(2,2,1));
		auto b = int3(3,4,5);
		//assert(a.dot(b)==24);
		assert(a+b==int3(5,6,6));
		//int3 q = b.zyx(2);
		auto c = float3(1f,0f,0f);
		auto d = float3(0f,1f,0f);
		assert(c.cross(d) == float3(0f,0f,1f));
		assert(c ==float3(1f,0f,0f));
	}catch (AssertError e) {
		writeln(e);			
	}
}