module math.matrix;

alias Matrix2 mat2;
alias Matrix3 mat3;
alias Matrix4!float mat4;

//Todo Add mat2x3 mat3x2 mat2x4 mat3x4 mat4x2 mat4x3 aswell (maby kinda annoying sometimes)
import math.vector;
import std.math;
import std.traits;




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
struct Matrix4(T) if (isNumeric!(T))
{
	public enum Matrix4!(T) identity 
		= Matrix4!(T)(1,0,0,0,
						  0,1,0,0,
						  0,0,1,0,
						  0,0,0,1);

	public Vector!(4,T) row0;
	public Vector!(4,T) row1;
	public Vector!(4,T) row2;
	public Vector!(4,T) row3;

	@property ref T m00() { return row0.x; }
	@property ref T m01() { return row0.y; }
	@property ref T m02() { return row0.z; }
	@property ref T m03() { return row0.w; }

	@property ref T m10() { return row1.x; }
	@property ref T m11() { return row1.y; }
	@property ref T m12() { return row1.z; }
	@property ref T m13() { return row1.w; }

	@property ref T m20() { return row2.x; }
	@property ref T m21() { return row2.y; }
	@property ref T m22() { return row2.z; }
	@property ref T m23() { return row2.w; }

	@property ref T m30() { return row3.x; }
	@property ref T m31() { return row3.y; }
	@property ref T m32() { return row3.z; }
	@property ref T m33() { return row3.w; }

	@property const(T)* ptr() const
	{
		return cast(const(T)*)&row0.x;
	}

	@property Matrix4!(T) transpose() 
	{
		return Matrix4(m00, m10, m20, m30,
							m01, m11, m21, m31,
							m02, m12, m22, m32,
							m03, m13, m23, m33);
	}

	@property T determinant()
	{          
		return row0.x * row1.y * row2.z * row3.w - row0.x * row1.y * row2.w * row3.z + row0.x * row1.z * row2.w * row3.y - row0.x * row1.z * row2.y * row3.w
			+ row0.x * row1.w * row2.y * row3.z - row0.x * row1.w * row2.z * row3.y - row0.y * row1.z * row2.w * row3.x + row0.y * row1.z * row2.x * row3.w
			- row0.y * row1.w * row2.x * row3.z + row0.y * row1.w * row2.z * row3.x - row0.y * row1.x * row2.z * row3.w + row0.y * row1.x * row2.w * row3.z
			+ row0.z * row1.w * row2.x * row3.y - row0.z * row1.w * row2.y * row3.x + row0.z * row1.x * row2.y * row3.w - row0.z * row1.x * row2.w * row3.y
			+ row0.z * row1.y * row2.w * row3.x - row0.z * row1.y * row2.x * row3.w - row0.w * row1.x * row2.y * row3.z + row0.w * row1.x * row2.z * row3.y
			- row0.w * row1.y * row2.z * row3.x + row0.w * row1.y * row2.x * row3.z - row0.w * row1.z * row2.x * row3.y + row0.w * row1.z * row2.y * row3.x;
	}

	this(Vector!(4,T) row0, Vector!(4,T) row1, Vector!(4,T) row2, Vector!(4,T) row3)
	{
		this.row0 = row0;
		this.row1 = row1;
		this.row2 = row2;
		this.row3 = row3;
	}

	this(T m00, T m01, T m02, T m03,
		  T m10, T m11, T m12, T m13,
		  T m20, T m21, T m22, T m23,
		  T m30, T m31, T m32, T m33)
	{
		row0 = Vector!(4,T)(m00, m01, m02, m03);
		row1 = Vector!(4,T)(m10, m11, m12, m13);
		row2 = Vector!(4,T)(m20, m21, m22, m23);
		row3 = Vector!(4,T)(m30, m31, m32, m33);
	}



	Matrix4!(T) opBinary(string op)(Matrix4!(T) rhs) if(op == "+" || op == "-")
	{
		return Matrix4!(T)(mixin("m00" ~ op ~ "rhs.m00"),
								 mixin("m01" ~ op ~ "rhs.m01"),
								 mixin("m02" ~ op ~ "rhs.m02"),
								 mixin("m03" ~ op ~ "rhs.m03"),
								 mixin("m10" ~ op ~ "rhs.m10"),
								 mixin("m11" ~ op ~ "rhs.m11"),
								 mixin("m12" ~ op ~ "rhs.m12"),
								 mixin("m13" ~ op ~ "rhs.m13"),
								 mixin("m20" ~ op ~ "rhs.m20"),
								 mixin("m21" ~ op ~ "rhs.m21"),
								 mixin("m22" ~ op ~ "rhs.m22"),
								 mixin("m23" ~ op ~ "rhs.m23"),
								 mixin("m30" ~ op ~ "rhs.m30"),
								 mixin("m31" ~ op ~ "rhs.m31"),
								 mixin("m32" ~ op ~ "rhs.m32"),
								 mixin("m33" ~ op ~ "rhs.m33"));
	}
	Matrix4!(T) opBinary(string op)(T rhs) if(op == "*")
	{
		return Matrix4!(T)(m00 * rhs, m01 * rhs, m02 * rhs, m03 * rhs,
								 m10 * rhs, m11 * rhs, m12 * rhs, m13 * rhs,
								 m20 * rhs, m21 * rhs, m22 * rhs, m23 * rhs,
								 m30 * rhs, m31 * rhs, m32 * rhs, m33 * rhs);
	}
	Matrix4!(T) opBinary(string op)(Matrix4!(T) rhs) if (op == "*") 
	{
		Matrix4!(T) result;
		Mult(this, rhs, result);
		return result;
	}
	Vector!(2,T) opBinaryRight(string op)(Vector!(2,T) rhs) if (op == "*")
	{
		return Vector!(2,T)(m00 * rhs.x + m01 * rhs.y + m03,
								 m10 * rhs.x + m11 * rhs.y + m13);
	}

	public static Matrix4!(T) CreateRotationZ(T angle)
	{
		T s = sin(angle);
		T c = cos(angle);

		return Matrix4!(T)(c, -s, 0, 0,
								 s,  c, 0, 0,
								 0,  0, 1, 0,
								 0,  0, 0, 1);
	}

	public static Matrix4!(T) CreateRotationX(T angle)
	{
		T s = sin(angle);
		T c = cos(angle);

		return Matrix4!(T)(1, 0,  0, 0,
								 0, c, -s, 0,
								 0, s,  c, 0,
								 0, 0,  0, 1);
	}

	public static Matrix4!(T) CreateRotationY(T angle)
	{
		T s = sin(angle);
		T c = cos(angle);

		return Matrix4!(T)( c, 0, s, 0,
								 0, 1, 0, 0,
								 -s, 0, c, 0,
								 0, 0, 0, 1);
	}

	public static Matrix4!(T) CreateRotation(T x, T y, T z)
	{
		T Cx = cos(x), Sx = sin(x);
		T Cy = cos(y), Sy = sin(y);
		T Cz = cos(z), Sz = sin(z);

		return Matrix4!(T)(		Cy*Cz,				-Cy*Sz,			   Sy,	0,
								 Sx*Sy*Cz + Cx*Sz,  -Sx*Sy*Sz + Cx*Cz, -Sx*Cy,	0,
								 -Cx*Sy*Cz + Sx*Sz,   Cx*Sy*Sz + Sx*Cz,  Cx*Cy, 0,
								 0,							0,					0,		1);

	}

	public static Matrix4!(T) CreateScale(T x, T y, T z)
	{
		return Matrix4!(T)( x, 0, 0, 0,
								 0, y, 0, 0,
								 0, 0, z, 0,
								 0, 0, 0, 1);
	}

	public static Matrix4!(T) CreateOrthographic(T left, T right, T top, T bottom, T near, T far)
	{
		return Matrix4!(T)(2 / (right - left), 0, 0, -(right + left) / (right - left),
								 0, 2 / (top - bottom), 0 , -(top + bottom) / (top - bottom),
								 0, 0, -2 / (far - near), -(far + near) / (far - near),
								 0, 0, 0, 1);
	}
}