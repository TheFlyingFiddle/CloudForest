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
}

struct Vector3(T)
{
	T x,y,z;
}

struct Vector4(T)
{
	T x,y,z,w;
}