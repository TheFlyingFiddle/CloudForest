module math.matrix;

alias Matrix2 mat2;
alias Matrix3 mat3;
alias Matrix4 mat4;

//Todo Add mat2x3 mat3x2 mat2x4 mat3x4 mat4x2 mat4x3 aswell (maby kinda annoying sometimes)
import math.vector;
import std.math;

struct Matrix2
{
	enum Matrix2 identity = Matrix2(1f,0f,0f,1f);

	float m00;
	float m10;
	float m01;
	float m11;

	this(float m00, float m10, float m01, float m11)
	{
		this.m00 = m00;
		this.m10 = m10;
		this.m01 = m01;
		this.m11 = m11;
	}

	Matrix2 transpose() @property
	{
		return Matrix2(m00, m01, m10, m11);
	}

	float determinant() @property
	{
		return m00*m11 - m10*m01;
	}

	Matrix2 inverse() @property
	{
		float invDet = 1.0f / determinant;
		return Matrix2(m11 * invDet, -m01* invDet, 
							-m10 * invDet, m11 * invDet);
	}

	Matrix2 opBinary(string op)(Matrix2 rhs) if(op == "*")
	{
		return Matrix2(m00 * rhs.m00 + m01 * rhs.m10,
							m10 * rhs.m00 + m11 * rhs.m10,

							m00 * rhs.m01 + m01 * rhs.m11,
							m10 * rhs.m01 + m11 * rhs.m11); 
	}

	Matrix2 opBinary(string op)(Matrix2 rhs) if(op == "+" || op == "-")
	{

		return Matrix2(mixin("m00" ~ op ~ "rhs.m00"), 
							mixin("m10" ~ op ~ "rhs.m10"), 
							mixin("m01" ~ op ~ "rhs.m01"), 
							mixin("m11" ~ op ~ "rhs.m11"));
	}

	Matrix2 opBinary(string op)(float value) if(s == "*")
	{
		return Matrix2(m00 * value, m10 * value, m01 * value, m11 * value);
	}

	float2 opBinary(string op)(float2 rhs) if(op == "*")
	{
		return float2(rhs.x * m00 + rhs.y * m01,
						  rhs.x * m10 + rhs.y * m11);
	}

	static Matrix2 rotation(float angle) 
	{
		float s = sin(angle), c = cos(angle);
		return Matrix2(c, -s, s, c);
	}

	static Matrix2 scale(float scale) 
	{
		return Matrix2(scale, 0, 0, scale);
	}

	unittest {
		auto result = Matrix2(1,3,2,4) * Matrix2(5,7,6,8);
		assert(result == Matrix2(19, 43, 22, 50));
	}
}


struct Matrix3 
{
	private float[9] _rep;
}

struct Matrix4
{
	private float[16] _rep;

	float* ptr() @property
	{
		return _rep.ptr;
	}
}