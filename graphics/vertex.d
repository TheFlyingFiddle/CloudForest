module graphics.vertex;

import math.vector;
import derelict.opengl3.gl3;
import graphics.program;
import graphics.common;
import graphics.context;
import graphics.errors;
import graphics.color;
import graphics.buffer;
import graphics.enums;


import std.traits;

struct VertexAttribute
{
	uint loc;
	int size;
	VertexAttributeType type;
	string name;
}

alias VertexArray VAO;
class VertexArray
{
	uint glName;

	this()
		out { assertNoGLError(); }
	body
	{
		glGenVertexArrays(1, &glName);
	}

	void destroy() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteVertexArrays(1, &glName);
	}

	VertexArray bindConstantAttribute(T)(Program prog, string name, T value) 
		out { assertNoGLError(); }
	body
	{
		auto attrib = prog.getAttribute(name);
		glEnableVertexAttribArray(attrib.loc);
		Constant.vertexAttrib(attrib.loc, value);
	}

	//Fix for non-normalized integer types.
	VertexArray bindAttribute(T)(VertexAttribute attrib, int stride, int offset) 
		in { 
			assertBound(this); 
			assert(Context.vertexBuffer);
			assertValidAttib!T(attrib);
		}
		out { assertNoGLError(); } 
	body
	{
		glEnableVertexAttribArray(attrib.loc);
		glVertexAttribPointer(attrib.loc, glUnitSize!T, glType!T, 
									 glNormalized!T, stride, 
									 cast(void*)offset);
		return this;
	}

	VertexArray disableAttrib(VertexAttribute attrib)
		in { assertBound(this); }
		out { assertNoGLError(); } 
	body
	{
		glDisableVertexAttribArray(attrib.loc);
		return this;
	}

	/** Enables all vertex attributes arrays corresponding to a specific vertex type.
	*   Use this if you use an interleaved vertex buffer object that only contains
	*	 vertices of a specific type.
	*
	*	Example:
	*
	*	struct VertT 
	*	{
	*		float2 position, texCoords;
	*		Color tint;
	*	}
	*
	*	Context.vertexArrays = myVertexArrays;
	*	Context.vertexBuffer = myVertexBuffer; //Containts vertices of type VertT
	*	enableTypeAttribArrays!VertT(myProgram); //This will enable VertexAttributeArrays position, texCoords and tint in the program.
	*														  //And assign appropriate values coorisponding to float2 and Color.
	*
	*/
	void bindAttributesOfType(T)(Program program) if(is(T == struct))
	in { 
		assert(Context.vertexArray == this);
		assert(Context.vertexBuffer);
	}
	out { assertNoGLError(); }
	body
	{
		uint offset = 0;
		foreach(i, trait; FieldTypeTuple!T) {
			enum name = __traits(allMembers, T)[i];
			bindAttribute!trait(program.attribute[name], T.sizeof, offset);
			offset += trait.sizeof;
		}
	}

	bool deleted() @property
	{
		return glIsVertexArray(glName) == GL_FALSE;
	}

	void free() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteVertexArrays(1, &glName);
	}

	private void assertValidAttib(T)(VertexAttribute attrib) 
	{
		debug
		{
			void validTypes(U...)()
			{
				enum msg = "\nWrong attribute type for attribute %s,\nExpected %s \nActual %s.";
				assert(isAny!(T,U), std.string.format(msg, attrib.name, U.stringof, T.stringof));
			}

			alias VertexAttributeType VT;
			switch(attrib.type) 
			{
				case VT.float_ : validTypes!(uint , float , int ); break;
				case VT.float2 : validTypes!(uint2, float2, int2); break; 
				case VT.float3 : validTypes!(uint3, float3, int3); break;
				case VT.float4 : validTypes!(uint4, float4, int4, Color);	break;
				case VT.int_   : validTypes!(int  ); break;
				case VT.int2   : validTypes!(int2 ); break;
				case VT.int3   : validTypes!(int3 ); break;
				case VT.int4   : validTypes!(int4 ); break;
				case VT.uint_  : validTypes!(uint ); break;
				case VT.uint2  : validTypes!(uint2); break;
				case VT.uint3  : validTypes!(uint3); break;
				case VT.uint4  : validTypes!(uint4); break;

				default :
					assert(false, "Not yet implemented!");
			}
		}
	}

}

//I do not know if i am going to use this... we will see.
private static struct Constant
{
	void vertexAttrib(uint loc, float value0)
	{
		glVertexAttrib1f(loc, value0);
	}

	void vertexAttrib(uint loc, short value0)
	{
		glVertexAttrib1s(loc, value0);
	}

	void vertexAttrib(uint loc, double value0)
	{
		glVertexAttrib1d(loc, value0);
	}

	void vertexAttrib(uint loc, int value0)
	{
		glVertexAttribI1i(loc, value0);
	}

	void vertexAttrib(uint loc, uint value0)
	{
		glVertexAttribI1ui(loc, value0);
	}

	void vertexAttrib(uint loc, float[] value)
	{
		glVertexAttrib1fv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, short[] value)
	{
		glVertexAttrib1sv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, double[] value)
	{
		glVertexAttrib1dv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, int[] value)
	{
		glVertexAttribI1iv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, uint[] value)
	{
		glVertexAttribI1uiv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, float value0,float value1)
	{
		glVertexAttrib2f(loc, value0, value1);
	}

	void vertexAttrib(uint loc, float2 value)
	{
		glVertexAttrib2f(loc, value.x, value.y);
	}

	void vertexAttrib(uint loc, short value0,short value1)
	{
		glVertexAttrib2s(loc, value0, value1);
	}

	void vertexAttrib(uint loc, short2 value)
	{
		glVertexAttrib2s(loc, value.x, value.y);
	}

	void vertexAttrib(uint loc, double value0,double value1)
	{
		glVertexAttrib2d(loc, value0, value1);
	}

	void vertexAttrib(uint loc, double2 value)
	{
		glVertexAttrib2d(loc, value.x, value.y);
	}

	void vertexAttrib(uint loc, int value0,int value1)
	{
		glVertexAttribI2i(loc, value0, value1);
	}

	void vertexAttrib(uint loc, int2 value)
	{
		glVertexAttribI2i(loc, value.x, value.y);
	}

	void vertexAttrib(uint loc, uint value0,uint value1)
	{
		glVertexAttribI2ui(loc, value0, value1);
	}

	void vertexAttrib(uint loc, uint2 value)
	{
		glVertexAttribI2ui(loc, value.x, value.y);
	}

	void vertexAttrib(uint loc, float value0, float value1, float value2)
	{
		glVertexAttrib3f(loc, value0, value1, value2);
	}

	void vertexAttrib(uint loc, float3 value)
	{
		glVertexAttrib3f(loc, value.x, value.y, value.z);
	}

	void vertexAttrib(uint loc, short value0, short value1, short value2)
	{
		glVertexAttrib3s(loc, value0, value1, value2);
	}

	void vertexAttrib(uint loc, short3 value)
	{
		glVertexAttrib3s(loc, value.x, value.y, value.z);
	}

	void vertexAttrib(uint loc, double value0, double value1, double value2)
	{
		glVertexAttrib3d(loc, value0, value1, value2);
	}

	void vertexAttrib(uint loc, double3 value)
	{
		glVertexAttrib3d(loc, value.x, value.y, value.z);
	}

	void vertexAttrib(uint loc, int value0, int value1, int value2)
	{
		glVertexAttribI3i(loc, value0, value1, value2);
	}

	void vertexAttrib(uint loc, int3 value)
	{
		glVertexAttribI3i(loc, value.x, value.y, value.z);
	}

	void vertexAttrib(uint loc, uint value0, uint value1, uint value2)
	{
		glVertexAttribI3ui(loc, value0, value1, value2);
	}

	void vertexAttrib(uint loc, uint3 value)
	{
		glVertexAttribI3ui(loc, value.x, value.y, value.z);
	}

	void vertexAttrib3(uint loc, float[] value)
	{
		glVertexAttrib3fv(loc, value.ptr);
	}

	void vertexAttrib3(uint loc, short[] value)
	{
		glVertexAttrib3sv(loc, value.ptr);
	}

	void vertexAttrib3(uint loc, double[] value)
	{
		glVertexAttrib3dv(loc, value.ptr);
	}

	void vertexAttrib3(uint loc, int[] value)
	{
		glVertexAttribI3iv(loc, value.ptr);
	}

	void vertexAttrib3(uint loc, uint[] value)
	{
		glVertexAttribI3uiv(loc, value.ptr);
	}

	void vertexAttrib(uint loc, float value0, float value1, float value2, float value3)
	{
		glVertexAttrib4f(loc, value0, value1, value2, value3);
	}

	void vertexAttrib(uint loc, float4 value)
	{
		glVertexAttrib4f(loc, value.x, value.y, value.z, value.w);
	}

	void vertexAttrib(uint loc, short value0, short value1, short value2, short value3)
	{
		glVertexAttrib4s(loc, value0, value1, value2, value3);
	}

	void vertexAttrib(uint loc, short4 value)
	{
		glVertexAttrib4s(loc, value.x, value.y, value.z, value.w);
	}

	void vertexAttrib(uint loc, double value0, double value1, double value2, double value3)
	{
		glVertexAttrib4d(loc, value0, value1, value2, value3);
	}

	void vertexAttrib(uint loc, double4 value)
	{
		glVertexAttrib4d(loc, value.x, value.y, value.z, value.w);
	}

	void vertexAttrib(uint loc, int value0, int value1, int value2, int value3)
	{
		glVertexAttribI4i(loc, value0, value1, value2, value3);
	}

	void vertexAttrib(uint loc, int4 value)
	{
		glVertexAttribI4i(loc, value.x, value.y, value.z, value.w);
	}

	void vertexAttrib(uint loc, uint value0, uint value1, uint value2, uint value3)
	{
		glVertexAttribI4ui(loc, value0, value1, value2, value3);
	}

	void vertexAttrib(uint loc, uint4 value)
	{
		glVertexAttribI4ui(loc, value.x, value.y, value.z, value.w);
	}

	void vertexAttrib4(uint loc, float[] value)
	{
		glVertexAttrib4fv(loc, value.ptr);
	}

	void vertexAttrib4(uint loc, short[] value)
	{
		glVertexAttrib4sv(loc, value.ptr);
	}

	void vertexAttrib4(uint loc, double[] value)
	{
		glVertexAttrib4dv(loc, value.ptr);
	}

	void vertexAttrib4(uint loc, int[] value)
	{
		glVertexAttrib4iv(loc, value.ptr);
	}

	void vertexAttrib4(uint loc, uint[] value)
	{
		glVertexAttrib4uiv(loc, value.ptr);
	}
}