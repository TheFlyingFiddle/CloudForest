module graphics.common;

import derelict.opengl3.gl3;
import math.vector;
import graphics.color;

//Does not work with shader souces > 512 should fix.
static char[1024] c_buffer;

char* toCString(const char[] str, char[] output = c_buffer) 
{
	output[0 .. str.length] = str[];
	output[str.length] = '\0';
	return output.ptr;
}

import math.vector;
import std.traits;

template isAny(U, T...) {
	static if(T.length > 0) {
		static if(is(T[0] == U))
			enum isAny = true;
		else 
			enum isAny = isAny!(U, T[1 .. $]);
	} else {
		enum isAny = false;
	}
}	

template isFloatVec(T) {
	enum isFloatVec = isAny!(T, float, float2, float3, float4);
}

template isIntVec(T) {
	enum isIntVec = isAny!(T, int, int2, int3, int4);
}

template isUintVec(T) {
	enum isUnitVec = isAny!(T, uint, uint2, uint3, uint4);
}

template glUnitSize(T) {
	static if(isNumeric!T) {
		enum glUnitSize = 1;
	} else static if(is(T t == Vector!(2, U), U...)) {
		enum glUnitSize = 2;
	} else static if(is(T t == Vector!(3, U), U...)) {
		enum glUnitSize = 3;
	} else static if(is(T t == Vector!(4, U), U...) || is(T == Color)) {
		enum glUnitSize = 4;
	} else {
		static assert(false, "Not Yet implemented");
	}
}

unittest{
	assert(glUnitSize!float3==3);
	assert(glUnitSize!uint4==4);
	assert(glUnitSize!float2==2);
}

template glNormalized(T) 
{
	static static if(isAny!(T, int, uint, int2, uint2, 
									int3, uint3, int4, uint4, Color)) {
		enum glNormalized = true;
   } else {
		enum glNormalized = false;
	}
}

template glType(T)
{
	static if(isFloatVec!T) {
		enum glType = GL_FLOAT;
	} else static if(isIntVec!T) {
		enum glType = GL_INT;
   } else static if(is(T == Color)) {
		enum glType = GL_UNSIGNED_BYTE;
	} else static if(isUintVec!T) {
		enum glType = GL_UNSIGNED_INT;
	} else  {
		static assert(false, "Not Yet implemented");
	}
}