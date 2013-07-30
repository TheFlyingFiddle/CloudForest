module math.vector;

alias Vector2!(float) float2;
alias Vector3!(float) float3;
alias Vector4!(float) float4;

alias Vector2!(short) short2;
alias Vector3!(short) short3;
alias Vector4!(short) short4;

alias Vector2!(double) double2;
alias Vector3!(double) double3;
alias Vector4!(double) double4;

alias Vector2!(int) int2;
alias Vector3!(int) int3;
alias Vector4!(int) int4;

alias Vector2!(uint) uint2;
alias Vector3!(uint) uint3;
alias Vector4!(uint) uint4;


struct Vector2(T)
{
	T x,y;

	enum Vector2!T one  = Vector2!T(1,1);
	enum Vector2!T zero = Vector2!T(0,0); 
}

struct Vector3(T)
{
	T x,y,z;

	enum Vector3!T one  = Vector3!T(1,1,1);
	enum Vector3!T zero = Vector3!T(0,0,0); 
}

struct Vector4(T)
{
	T x,y,z,w;

	enum Vector4!T one  = Vector4!T(1,1,1,1);
	enum Vector4!T zero = Vector4!T(0,0,0,0); 
}