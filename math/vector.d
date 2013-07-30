module math.vector;
import std.stdio;
import std.conv: to;
import std.range: iota;
import std.algorithm;
import std.traits;
import std.string : join, format;
import core.exception : RangeError, AssertError;
import std.regex;

alias Vector!(2,float) float2;
alias Vector!(3,float) float3;
alias Vector!(4,float) float4;

alias Vector!(2,short) short2;
alias Vector!(3,short) short3;
alias Vector!(4,short) short4;

alias Vector!(2,ushort) ushort2;
alias Vector!(3,ushort) ushort3;
alias Vector!(4,ushort) ushort4;

alias Vector!(2,double) double2;
alias Vector!(3,double) double3;
alias Vector!(4,double) double4;

alias Vector!(2,int) int2;
alias Vector!(3,int) int3;
alias Vector!(4,int) int4;

alias Vector!(2,uint) uint2;
alias Vector!(3,uint) uint3;
alias Vector!(4,uint) uint4;

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
	auto opDispatch(string s, Args...)(Args args) if(s.length == numElements)
	in
	{
		assert(match(s, "["~xyzw[0..numElements]~"]*"));
	}
	body
	{
		mixin(buildOpDispatch(numElements));
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
		   .join()[0..$-1]/*Remove last comma*/
		   ~");", numElements);
}

private static string buildOpDot(int numElements)
{
	return "return "~iota(numElements).map!(i =>""~xyzw[i]~"*rhs."~xyzw[i]~"+")
				  .join()[0..$-1]/*Remove last plus*/
				  ~";";
}

private static string buildOpSliceAssign(int numElements)
{
	return iota(numElements).map!(i =>"this."~xyzw[i]~",")
		.join()[0..$-1]/*Remove last comma*/
		~"=val;";
}




unittest{
	try{
		auto a = int3(2,2,1);
		assert(a == a[]);
		a[] = 2;
		assert(a == int3(2,2,2));
		auto b = int3(3,4,5);
		assert(a*b==24);
		assert(a+b==int3(5,6,7));
		assert(b.zyx == int3(5,4,3));
		auto c = float3(1f,0f,0f);
		auto d = float3(0f,1f,0f);
		assert(c%d == float3(0f,0f,1f));
		c[2] = 5f;
		assert(c ==float3(1f,0f,5f));
	}catch (AssertError e) {
		writeln(e);			
	}
}