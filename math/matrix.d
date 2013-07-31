module math.matrix;

alias Matrix2 mat2;
alias Matrix3 mat3;
alias Matrix4 mat4;

//Todo Add mat2x3 mat3x2 mat2x4 mat3x4 mat4x2 mat4x3 aswell (maby kinda annoying sometimes)
import math.vector;
import std.math;
import std.traits;




struct Matrix2
{
	enum Matrix2 identity = Matrix2(1f,0f,0f,1f);

	float[4] _rep;

	this(float f00, float f01, float f10, float f11)
	{
		this._rep[0] = f00;
		this._rep[2] = f01;
		this._rep[1] = f10;
		this._rep[3] = f11;
	}

	Matrix2 transpose() @property
	{
		return Matrix2(_rep[0], _rep[2], _rep[1], _rep[3]);
	}

	float determinant() @property
	{
		return _rep[0]*_rep[3] - _rep[2]*_rep[1];
	}

	Matrix2 inverse() @property
	{
		float invDet = 1.0f / determinant;
		return Matrix2(_rep[3] * invDet, -_rep[1]* invDet, 
							-_rep[2] * invDet, _rep[3] * invDet);
	}

	Matrix2 opBinary(string op)(Matrix2 rhs) if(op == "*")
	{
		return Matrix2(	_rep[0] * rhs._rep[0] + _rep[1] * rhs._rep[2],
							_rep[2] * rhs._rep[0] + _rep[3] * rhs._rep[2],

							_rep[0] * rhs._rep[1] + _rep[1] * rhs._rep[3],
							_rep[2] * rhs._rep[1] + _rep[3] * rhs._rep[3]); 
	}

	Matrix2 opBinary(string op)(Matrix2 rhs) if(op == "+" || op == "-")
	{

		return Matrix2(mixin("_rep[0]" ~ op ~ "rhs._rep[0]"), 
							mixin("_rep[2]" ~ op ~ "rhs._rep[2]"), 
							mixin("_rep[1]" ~ op ~ "rhs._rep[1]"), 
							mixin("_rep[3]" ~ op ~ "rhs._rep[3]"));
	}

	Matrix2 opBinary(string op)(float value) if(s == "*")
	{
		return Matrix2(_rep[0] * value, _rep[2] * value, _rep[1] * value, _rep[3] * value);
	}

	float2 opBinary(string op)(float2 rhs) if(op == "*")
	{
		return float2(rhs.x * _rep[0] + rhs.y * _rep[1],
						  rhs.x * _rep[2] + rhs.y * _rep[3]);
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
	public enum Matrix4 identity 
		= Matrix4(1f,0f,0f,0f,
					 0f,1f,0f,0f,
					 0f,0f,1f,0f,
					 0f,0f,0f,1f);

	///Unexposed representation
	private float[16] _rep;

	@property const(float)* ptr() const
	{
		return _rep.ptr;
	}

	@property Matrix4 transpose() 
	{
		auto ptr = _rep.ptr;
		return Matrix4(*ptr++, *ptr++, *ptr++, *ptr++, 
						  *ptr++, *ptr++, *ptr++, *ptr++, 
						  *ptr++, *ptr++, *ptr++, *ptr++, 
						  *ptr++, *ptr++, *ptr++, *ptr++); 
	}

	@property float determinant()
	{          
		return 1f;//return _rep[0] * _rep[5] * _rep[10] * _rep[15] - _rep[0] * _rep[5] * _rep[14] * _rep[11] + _rep[0] * _rep[9] * _rep[14] * _rep[7] - _rep[0] * _rep[9] * _rep[6] * _rep[15]
		//+ _rep[0] * _rep[13] * _rep[6] * _rep[11] - _rep[0] * _rep[13] * _rep[10] * _rep[7] - _rep[4] * _rep[9] * _rep[14] * _rep[3] + _rep[4] * _rep[9] * _rep[2] * _rep[15]
		//- _rep[4] * _rep[13] * _rep[2] * _rep[11] + _rep[4] * _rep[13] * _rep[10] * _rep[3] - _rep[4] * _rep[1] * _rep[10] * _rep[15] + _rep[4] * _rep[1] * _rep[14] * _rep[11]
		//+ _rep[8] * _rep[13] * _rep[2] * _rep[7] - _rep[8] * _rep[13] * _rep[6] * _rep[3] + _rep[8] * _rep[1] * _rep[6] * _rep[15] - _rep[8] * _rep[1] * _rep[14] * _rep[7]
		//+ _rep[8] * _rep[5] * _rep[14] * _rep[3] - _rep[8] * _rep[5] * _rep[2] * _rep[15] - _rep[12] * _rep[1] * _rep[6] * _rep[11] + _rep[12] * _rep[1] * _rep[10] * _rep[7]
		//- _rep[12] * _rep[5] * _rep[10] * _rep[3] + _rep[12] * _rep[5] * _rep[2] * _rep[11] - _rep[12] * _rep[9] * _rep[2] * _rep[7] + _rep[12] * _rep[9] * _rep[6] * _rep[3];
	}



	///Constructor using column major arrays
	this(float[16] arr)
	{
		//_rep = arr;
	}

	this(float f00, float f01, float f02, float f03,
		  float f10, float f11, float f12, float f13,
		  float f20, float f21, float f22, float f23,
		  float f30, float f31, float f32, float f33)
	{
		_rep[0] = f00;  _rep[4] = f01; _rep[8]  = f02; _rep[12] = f03;
		_rep[1] = f10;  _rep[5] = f11; _rep[9]  = f12; _rep[13] = f13;
		_rep[2] = f20;  _rep[6] = f21; _rep[10] = f22; _rep[14] = f23;
		_rep[3] = f30;  _rep[7] = f31; _rep[11] = f32; _rep[15] = f33;
	}

	float opIndex(int m, int n)
	{
		return _rep[m + n*4];
	}

	void opIndexAssign(float f, int m, int n)
	{
		_rep[m + n*4] = f;
	}

	Matrix4 opBinary(string op)(Matrix4 rhs) if(op == "+" || op == "-")
	{
		return identity;//return Matrix4(mixin("_rep[]"~op~"rhs._rep[]"));
	}

	Matrix4 opBinary(string op)(float rhs) if(op == "*")
	{
		return identity;//Matrix4(_rep[]*rhs);
	}

	Matrix4 opBinary(string op)(Matrix4 rhs) if (op == "*") 
	{
		Matrix4 result;
		//Mult(this, rhs, result);
		return result;
	}

	Vector!(n,T) opBinaryRight(string op)(Vector!(n,T) rhs) if (op == "*")
	{
		Vector!(n,t) vec;
		foreach(i;0..n)
		{
			foreach(j;0..n)
			{
				vec[i] += vec[j]*_rep[i,j];
			}
		}
		return vec;
		//return mixin(iota(n).map!(i =>("vec[i] = "~
		//				iota(n).map!(j =>("_rep[i,j] 																	
	}


	public static Matrix4 CreateRotationZ(float angle)
	{
		float s = sin(angle);
		float c = cos(angle);

		return Matrix4(c, -s, 0, 0,
							s,  c, 0, 0,
							0,  0, 1, 0,
							0,  0, 0, 1);
	}

	public static Matrix4 CreateRotationX(float angle)
	{
		float s = sin(angle);
		float c = cos(angle);

		return Matrix4(1, 0,  0, 0,
							0, c, -s, 0,
							0, s,  c, 0,
							0, 0,  0, 1);
	}

	public static Matrix4 CreateRotationY(float angle)
	{
		float s = sin(angle);
		float c = cos(angle);

		return Matrix4( c, 0, s, 0,
							0, 1, 0, 0,
							-s, 0, c, 0,
							0, 0, 0, 1);
	}

	public static Matrix4 CreateRotation(float x, float y, float z)
	{
		float Cx = cos(x), Sx = sin(x);
		float Cy = cos(y), Sy = sin(y);
		float Cz = cos(z), Sz = sin(z);

		return Matrix4(		Cy*Cz,				-Cy*Sz,			   Sy,	0,
							Sx*Sy*Cz + Cx*Sz,  -Sx*Sy*Sz + Cx*Cz, -Sx*Cy,	0,
							-Cx*Sy*Cz + Sx*Sz,   Cx*Sy*Sz + Sx*Cz,  Cx*Cy, 0,
							0,							0,					0,		1);

	}

	public static Matrix4 CreateScale(float x, float y, float z)
	{
		return Matrix4( x, 0, 0, 0,
							0, y, 0, 0,
							0, 0, z, 0,
							0, 0, 0, 1);
	}

	public static Matrix4 CreateOrthographic(float left, float right, float top, float bottom, float near, float far)
	{
		return Matrix4(2 / (right - left), 0, 0, -(right + left) / (right - left),
							0, 2 / (top - bottom), 0 , -(top + bottom) / (top - bottom),
							0, 0, -2 / (far - near), -(far + near) / (far - near),
							0, 0, 0, 1);
	}
}