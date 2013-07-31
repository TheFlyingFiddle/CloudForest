module math.vector;
import std.stdio;
import std.conv: to;
import std.range: iota;
import std.algorithm;
import std.traits;
import std.string : join, format;
import core.exception : RangeError, AssertError;
import std.regex;

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

	static if (T.sizeof > 2)
	Vector3!T cross(Vector3!T rhs)
	{
		return Vector3!T(
												y*rhs.z - z*rhs.y,
												z*rhs.x - x*rhs.z,
												x*rhs.y - y*rhs.x
												);
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
}


/*
struct Vector(int numElements, T)
{
	mixin(buildFields(numElements));
	static if(isNumeric!T){
		mixin(buildZero(numElements));
		mixin(buildOne(numElements));
	}
	mixin buildCommonMethods!(numElements);
}


//******************
// Building
//******************

private enum xyzw = "xyzw";
private enum rgba = "rgba";

private static string buildOne(int numElements)
{
	return "enum Vector!(numElements, T) one  = Vector!(numElements, T)("~iota(numElements).map!(i => "1").join(",")~");";
}

private static string buildZero(int numElements)
{
	return "enum Vector!(numElements, T) zero = Vector!(numElements, T)("~iota(numElements).map!(i => "0").join(",")~");";
}

private static string buildFields(int numElements)
{
	return "T "~iota(numElements).map!(i => xyzw[i]~",").join()[0..$-1]~";";
}


private mixin template buildCommonMethods(alias numElements)
{
	private static bool validIndex(int index)
	{
		return 0<=index && index<numElements;
	}

	T opIndex(int index)
	in
	{
		assert(validIndex(index));
	}
	body
	{
		mixin(buildOpIndex(numElements));
	}

	void opIndexAssign(T newVal, int index)
	in
	{
		assert(validIndex(index));
	}
	body
	{
		mixin(buildOpIndexAssign(numElements));
	}

	auto opSlice()
	{
		return this;
	}

	void opSliceAssign(T val)
	{
		mixin(buildOpSliceAssign(numElements));
	}

	///Dot product
	T opBinary(string op)(Vector!(numElements,T) rhs) if(op == "*")
	{
		mixin(buildOpDot(numElements));
	}

	Vector!(numElements,T) opBinary(string op)(Vector!(numElements,T) rhs) if(op == "+")
	{
		mixin(buildOpAddition(numElements));
	}

	///Swizzles only. Use myvec3.zxy() or similar (property syntax crashes my dmd...).
	template opDispatch(string s)
	{
		enum Vector!(s.length, T) vec = buildVec!(s, s.length);
	}

	auto buildVec(string s, int n)()
	{
		Vector!(s.length, T) vec;
		mixin(iota(s.length).map!(i => "vec["~to!string(i)~"] = "~s[i]~";").join());
		return vec;
	}

	///Cross product: Percent looks kind of like a cross?
	Vector!(numElements,T) opBinary(string op)(Vector!(numElements,T) rhs) if(op == "%" && numElements==3)
	{
		return Vector!(numElements,T)(
						 y*rhs.z - z*rhs.y,
						 z*rhs.x - x*rhs.z,
						 x*rhs.y - y*rhs.x
						 );
	}
}

private static string buildOpIndexAssign(int numElements)
{
	return iota(numElements).map!(i => format(
									"if(index == %1$d) 
									{ "~xyzw[i]~" = newVal;}
									else ", i))
									.join()[0..$-"else ".length];
}

private static string buildOpIndex(int numElements)
{
	return iota(numElements).map!(i => format(
									"if(index == %1$d) 
									{ return "~xyzw[i]~";}
									else ", i))
									.join()
									~ "throw new RangeError();";
}

private static string buildOpDispatch(int numElements)
{
	return format(
			"auto vec = Vector!(%1$d,T)();
			mixin(iota(numElements).map!(i => format(\"vec[%2$s] = \"~s[i]~\";\", i)).join());
			return vec;", 
		numElements, "%1$d");
}

private static string buildOpAddition(int numElements)
{
	return format("return Vector!(%1$d,T)("~iota(numElements).map!(i =>""~xyzw[i]~"+rhs."~xyzw[i]~",")
		   .join()[0..$-1]
		   ~");", numElements);
}

private static string buildOpDot(int numElements)
{
	return "return "~iota(numElements).map!(i =>""~xyzw[i]~"*rhs."~xyzw[i]~"+")
				  .join()[0..$-1]
				  ~";";
}

private static string buildOpSliceAssign(int numElements)
{
	return iota(numElements).map!(i =>"this."~xyzw[i]~",")
		.join()[0..$-1]
		~"=val;";
}

private static bool validSwizzle(string s)
{
	import std.string;
	auto dimensions = xyzw[0..s.length];
	auto colors = rgba[0..s.length];

	if(dimensions.indexOf(s[0])>=0)
	{
		foreach(c;s)
		{
			if(dimensions.indexOf(c)<0)
				return false;
		}
	}
	else if(colors.indexOf(s[0])>=0)
	{
		foreach(c;s)
		{
			if(colors.indexOf(c)<0)
				return false;
		}
	}
	else
	{
		return true;
	}
	return false;
}

*/

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