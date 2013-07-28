module graphics.program;

import graphics.shader;
import graphics.errors;
import graphics.common;
import graphics.vertex;
import graphics.context;
import graphics.color;
import std.traits : isArray;
import std.algorithm : find, remove, countUntil;
import math.vector;
import utils.assertions;
import derelict.opengl3.gl3;
import graphics.enums;


struct UniformBlockInfo
{
	Program program;
	string name;
	int index;
	uint size;
	BlockUniformInfo[] uniforms;
}

struct BlockUniformInfo
{
	string name;
	UniformType type;
	int size;
	int offset;
}

struct UniformInfo
{
	string name;
	UniformType type;
	int size;
	int loc;
}

struct Uniform
{
	Program program;
	UniformInfo info;

	void set(T)(T value) 
		in { 
			assertBound(program); 
			program.validateUniform!T(value, info);
		}
		out { assertNoGLError(); }
	body
	{
		program.flushUniform(info.loc, value);
	}
}

final class Program
{
	const uint glName;

	private VertexAttribute[string] attributes;
	private UniformBlockInfo[string] uniformBlocks;
	private UniformInfo[string] uniforms; //Only contains uniforms not in a uniform block.

	this()
		out { assertNoGLError(); }
	body
	{
		this.glName = glCreateProgram();
	}

	this(Shader[] shaders...) 
		out { assertNoGLError(); }
	body
	{
		this();
		this.link(shaders);
	}

	void destroy() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteProgram(this.glName);
	}

	void bindAttributeLocation(const(char)[] name, uint loc)
		out { assertNoGLError(); }
	body
	{
		glBindAttribLocation(glName, loc, name.toCString());
	}

	void bindFragDataLocation(const(char)[] name, uint loc)
		out { assertNoGLError(); }
	body 
	{
		glBindFragDataLocation(glName, loc, name.toCString());
	}

	void bindFragDataLocationIndex(const(char)[] name, uint loc, uint index)
		out { assertNoGLError(); }
	body 
	{
		glBindFragDataLocationIndexed(glName, loc, index, name.toCString());
	}

	Program link(Shader[] shaders...) 
		out { assertNoGLError(); }
	body
	{
		foreach(shader; shaders)
			glAttachShader(glName, shader.glName);

		glLinkProgram(glName);
		if(!linked) {
			throw new ProgramLinkException(infoLog);
		}

		cacheVertexAttributes();
		cacheUniforms();

		foreach(shader; shaders)
			glDetachShader(glName, shader.glName);

		return this;
	}

	Program validate() 
		out { assertNoGLError(); }
	body
	{
		glValidateProgram(glName);
		if(!valid) {
			throw new ProgramValidationException(infoLog);
		}
		return this;
	}

	string infoLog() @property
		out { assertNoGLError(); }
	body
	{
		int length;
		glGetProgramInfoLog(glName,
								  c_buffer.length,
								  &length,
								  c_buffer.ptr);
		return c_buffer[0 .. length].idup;
	}

	void feedbackVaryings(FeedbackMode mode, string[] varyings) 
	{
		import std.string;
		immutable (char)*[] v; 
		foreach(s; varyings) {
			v ~= s.toStringz();
		}

		glTransformFeedbackVaryings(glName, varyings.length, cast(char**)v.ptr, mode);
	}


	auto uniform() 
	{
		struct UniformIndexer {
			Program prog;
			auto opIndex(string index) {
				auto uniformInfo = prog.uniforms[index];
				return Uniform(prog, uniformInfo);
			}

			void opIndexAssign(T)(T value, string name) 
				in { assertBound(prog); } body {

				auto uniformInfo = prog.uniforms[name];
				prog.validateUniform!T(value, uniformInfo);
				prog.flushUniform(uniformInfo.loc, value);
			}
		}
		return UniformIndexer(this);
	}

	UniformBlockInfo block(string name) 
	{
		return uniformBlocks[name];
	}
	
	auto attribute()  
	{
		auto prog = this;
		struct AttributeIndexer	{
			VertexAttribute opIndex(string index) {
				return prog.attributes[index];
			}
		}
		return AttributeIndexer();
	}

	private UniformInfo uniformInfo(uint activeIndex)
	{
		int size, length, loc;
		uint type;
		glGetActiveUniform(glName, activeIndex, c_buffer.length, 
								 &length, &size, &type,
								 c_buffer.ptr);
		loc = glGetUniformLocation(glName, c_buffer.ptr);

		return  UniformInfo(c_buffer[0 .. length].idup, cast(UniformType)type, size, loc);
	}

	private BlockUniformInfo uniformBlockInfo(uint activeIndex, int offset)
	{
		int size, length;
		uint type;
		glGetActiveUniform(glName, activeIndex, c_buffer.length, 
								 &length, &size, &type,
								 c_buffer.ptr);
		return BlockUniformInfo(c_buffer[0 .. length].idup, cast(UniformType)type, size, offset);
	}

	bool deleted() @property
		out { assertNoGLError(); }
	body
	{
		return cast(bool)getProgramParameter(ProgramProperty.deleted);
	}

	bool linked() @property
		out { assertNoGLError(); }
	body
	{
		return cast(bool)getProgramParameter(ProgramProperty.linked);
	}

	bool valid() @property
		out { assertNoGLError(); }
	body
	{
		return cast(bool)getProgramParameter(ProgramProperty.valid);
	}

	int infoLogLength() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.infoLogLength);
	}

	int activeAttributes() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.activeAttributes);
	}

	int numTransformFeedbackVaryings() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.transformFeedbackVaryings);
	}

	int transformFeedbackVaryingMaxLength() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.transformFeedbackVaryingMaxLength);
	}

	int geometryVerticesOut() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.geometryVerticesOut);
	}

	int activeUniforms() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.activeUniforms);
	}

	int activeUniformBlocks() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.activeUniformBlocks); 
	}

	int numAttachedShaders() @property
		out { assertNoGLError(); }
	body
	{
		return getProgramParameter(ProgramProperty.numAttachedShaders);
	}

	PrimitiveType geometryInputType() @property
		out { assertNoGLError(); }
	body
	{
		return cast(PrimitiveType)getProgramParameter(ProgramProperty.geometryInputType);
	}

	PrimitiveType geometryOutputType() @property
		out { assertNoGLError(); }
	body
	{
		return cast(PrimitiveType)getProgramParameter(ProgramProperty.geometryOutputType);
	}

	FeedbackMode feedbackMode() @property
		out { assertNoGLError(); }
	body
	{
		return cast(FeedbackMode)getProgramParameter(ProgramProperty.transformFeedbackBufferMode);
	}

	private int activeAttributesMaxLength() @property
	{
		return getProgramParameter(ProgramProperty.activeAttributesMaxLength);
	}

	private int activeUniformsMaxLength() @property
	{
		return getProgramParameter(ProgramProperty.activeUniformsMaxLength);
	}

	private int getProgramParameter(ProgramProperty pp) 
	{
		int data;
		glGetProgramiv(glName, pp, &data);
		return data;
	}

	private void cacheVertexAttributes()
	{
		int numAttribs = this.activeAttributes;
		int length;
		int size;
		int loc;
		uint type;
		string name;

		foreach(i; 0 .. numAttribs) {
			glGetActiveAttrib(glName, i, c_buffer.length, &length,
									&size, &type, c_buffer.ptr);
			loc = glGetAttribLocation(glName, c_buffer.ptr);
			name = c_buffer[0 .. length].idup;
			attributes[name] = VertexAttribute(loc,
														 size, 
														 cast(VertexAttributeType)type, 
														 name);
		}
	}

	private void cacheUniforms() 
	{
		int numBlocks = this.activeUniformBlocks;
		int activeUniformsInBlock;
		int activeBlockNameLength;
		int blockSize;
		auto usedIndecies = new int[0];
		foreach(i; 0 .. numBlocks) {
			glGetActiveUniformBlockiv(glName, i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &activeUniformsInBlock);
			glGetActiveUniformBlockName(glName,i, c_buffer.length, &activeBlockNameLength, c_buffer.ptr);
			glGetActiveUniformBlockiv(glName, i, GL_UNIFORM_BLOCK_DATA_SIZE, &blockSize);
			auto blockName = c_buffer[0 .. activeBlockNameLength].idup;
			auto activeIndices = new int[activeUniformsInBlock];
			auto activeOffsets = new int[activeUniformsInBlock];

			glGetActiveUniformBlockiv(glName, i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, activeIndices.ptr);
			glGetActiveUniformsiv(glName, activeUniformsInBlock, cast(uint*)activeIndices.ptr,
										 GL_UNIFORM_OFFSET, activeOffsets.ptr);

			usedIndecies ~= activeIndices;

			UniformBlockInfo block;
			block.size = blockSize;
			block.name = blockName;
			block.index = glGetUniformBlockIndex(glName, c_buffer.ptr);
			block.uniforms = new BlockUniformInfo[activeUniformsInBlock];
			block.program = this;
			foreach(j; 0 .. activeUniformsInBlock) {
				auto blockUniformInfo = uniformBlockInfo(activeIndices[j], activeOffsets[j]);
				block.uniforms[j] = blockUniformInfo;
			}

			uniformBlocks[blockName] = block;
		}

		foreach(i;0 .. activeUniforms) {
			if(usedIndecies.find(i).length != 0) continue;
			auto uniform = uniformInfo(i);
			uniforms[uniform.name] = uniform;
		}
	}

	private void validateUniform(T)(T value, UniformInfo uniform)
	{
		debug
		{
			static if(isArray!T) {
				assert(value.length == uniform.size);
				alias typeof(value[0]) type;
			} else {
				alias T type;
			}

			void validate(U)()
			{
				enum msg = "Wrong type for the uniform %s in program %s expected %s was %s.";
				auto msgParams = std.typecons.tuple(uniform.name, this, uniform.type, type.stringof);
				assert(is(type == U), format(msg, msgParams.expand));
			}

			alias UniformType UT;
			switch(uniform.type)
			{
				case UT.float_ : validate!(float ); break;
				case UT.float2 : validate!(float2); break;
				case UT.float3 : validate!(float3); break;
				case UT.float4 : validate!(float4); break;
				case UT.int_   : validate!(int   ); break;
				case UT.int2   : validate!(int2  ); break;
				case UT.int3   : validate!(int3  ); break;
				case UT.int4   : validate!(int4  ); break;
				case UT.uint_  : validate!(uint  ); break;
				case UT.uint2  : validate!(uint2 ); break;
				case UT.uint3  : validate!(uint3 ); break;
				case UT.uint4  : validate!(uint4 ); break;

				case UT.mat2   : assertNotImplemented("mat2   vertex attribute arrays"); break;
				case UT.mat3   : assertNotImplemented("mat3   vertex attribute arrays"); break;
				case UT.mat4   : assertNotImplemented("mat4   vertex attribute arrays"); break;
				case UT.mat2x3 : assertNotImplemented("mat2x3 vertex attribute arrays"); break;
				case UT.mat2x4 : assertNotImplemented("mat2x4 vertex attribute arrays"); break;
				case UT.mat3x2 : assertNotImplemented("mat3x2 vertex attribute arrays"); break;
				case UT.mat3x4 : assertNotImplemented("mat3x4 vertex attribute arrays"); break;
				case UT.mat4x2 : assertNotImplemented("mat4x2 vertex attribute arrays"); break;
				case UT.mat4x3 : assertNotImplemented("mat4x3 vertex attribute arrays"); break;

				//Can only be of sampler type otherwise
				default : 
					validate!(int);
					return;
			}
		}
	}

	private void flushUniform(int loc, int value)
	{
		glUniform1i(loc, value);
	}

	private void flushUniform(int loc,  int[] value) 
	{
		glUniform1iv(loc, value.length, cast(int*)value.ptr);
	}

	private void flushUniform(int loc,  int2 value) 
	{
		glUniform2i(loc, value.x, value.y);
	}
	
	private void flushUniform(int loc, int2[] value) 
	{
		glUniform2iv(loc, value.length, cast(int*)value.ptr);
	}

	private void flushUniform(int loc, int3 value)
	{
		glUniform3i(loc, value.x, value.y, value.z);
	}

	private void flushUniform(int loc, int3[] value) 
	{
		glUniform3iv(loc, value.length, cast(int*)value.ptr);
	}

	private void flushUniform(int loc, int4 value) 
	{
		glUniform4i(loc, value.x, value.y, value.z, value.w);
	}

	private void flushUniform(int loc, int4[] value)
	{
		glUniform4iv(loc, value.length, cast(int*)value.ptr);
	}

	private void flushUniform(int loc, uint value)
	{
		glUniform1ui(loc, value);
	}

	private void flushUniform(int loc, uint[] value) 
	{
		glUniform1uiv(loc, value.length, cast(float*)value.ptr);
	}

	private void flushUniform(int loc, uint2 value)
	{
		glUniform2ui(loc, value.x, value.y);
	}

	private void flushUniform(int loc, uint2[] value)
	{
		glUniform2uiv(loc, value.length, cast(uint*)value.ptr);
	}

	private void flushUniform(int loc, uint3 value)
	{
		glUniform3ui(loc, value.x, value.y, value.z);
	}

	private void flushUniform(int loc, uint3[] value)
	{
		glUniform3uiv(loc, value.length, cast(uint*)value.ptr);
	}

	private void flushUniform(int loc, uint4 value)
	{
		glUniform4ui(loc, value.x, value.y, value.z, value.w);
	}

	private void flushUniform(int loc, uint4[] value)
	{
		glUniform4uiv(loc, value.length, cast(uint*)value.ptr);
	}

	private void flushUniform(int loc, float value)
	{
		glUniform1f(loc, value);
	}
	
	private void flushUniform(int loc, float[] value)
	{
		glUniform1fv(loc, value.length, cast(float*)value.ptr);
	}
	
	private void flushUniform(int loc, float2 value)
	{
		glUniform2f(loc, value.x, value.y);
	}

	private void flushUniform(int loc, float2[] value)
	{
		glUniform2fv(loc, value.length, cast(float*)value.ptr);
	}
	
	private void flushUniform(int loc, float3 value)
	{
		glUniform3f(loc, value.x, value.y, value.z);
	}

	private void flushUniform(int loc, float3[] value)
	{
		glUniform3fv(loc, value.length, cast(float*)value.ptr);
	}
	
	private void flushUniform(int loc, float4 value)
	{
		glUniform4f(loc, value.x, value.y, value.z, value.w);
	}

	private void flushUniform(int loc, float4[] value)
	{
		glUniform4fv(loc, value.length, cast(float*)value.ptr);
	}
}


/++ Used to generate code.
unittest 
{
	std.file.write("Generated.txt", generateUniformValues(["int", "uint","float"],["i","ui","f"], 4));
}

template getExt(T)
{
	static if(isFloatVec!T || is(T == float[])) {
		enum getExt = "fv";
	} else static if(isIntVec!T || is(T == int[])) {
		enum getExt = "iv";
	} else static if(isUintVec!T || is(T == unit[])) {
		enum getExt = "uiv";
	}
}

template getUnderlyingType(T)
{
	static if(isFloatVec!T || is(T == float[])) {
		alias getUnderlyingType = float;
	} else static if(isIntVec!T || is(T == int)) {
		alias getUnderlyingType = int;
	} else static if(isUintVec!T || is(T == uint)) {
		alias getUnderlyingType = uint;
	}
}


string generateUniformValues(string[] types, string[] typeID, int count)
{
	string s;
	foreach(i; 0 .. types.length) {
		foreach(j; 1 .. count + 1) {
			s ~= createUniform(types[i], typeID[i], j);		
			s ~= createVectorUniform(types[i], typeID[i], j);
		}
	}
	return s;
}

string createVectorUniform(string type, string typeID, int size) {
	import std.string : format;
	string header = 
"


/** Sets a uniform or a uniform array in the program. 
*	If it is not an array the length of the slice should be 1
*	otherwize it can be 1 or greater up to uniform array length - 1
*/
Program uniform(string name,%s" ~ (size != 1 ? to!string(size) : "") ~ "[] value)
	in { assert(Context.program == this); }
	out { assertNoGLError(\"Program.uniform\"); } 
body
{
	auto uniform = uniforms[name];
	validateUniform!%s(uniform);
	glUniform%s" ~  typeID ~ "v(uniform.loc, value.length, cast(" ~ type ~ "*)value);
	return this;
}";

	return format(header, type, type, size);
}

string createUniform(string type, string typeID, int size) {
	import std.string : format;
	string header = 
"

/** Sets a uniform of the program object.
*/
Program uniform(string name,%s)
	in { assert(Context.program == this); }
	out { assertNoGLError(\"Program.uniform\"); } 
body
{
	auto uniform = uniforms[name];
	validateUniform!%s(uniform);
	glUniform%s%s(uniform.loc, %s);
	return this;
}";

	if(size == 1)
		return format(header, type ~ " value", type, size, typeID, "value");
	else if(size == 2)
		return format(header, type ~ to!string(size) ~ " value", type, size, typeID, "value.x, value.y")
			~   format(header, type ~ " value0, " ~ type ~ " value1", type, size, typeID, "value0, value1");
	else if(size == 3)
		return format(header, type ~ to!string(size) ~ " value", type, size, typeID, "value.x, value.y, value.z")
			~   format(header, type ~ " value0, " ~ type ~ " value1," ~ type ~ " value2", type, size, typeID, "value0, value1, value2");
	else if(size == 4)
		return format(header, type ~ to!string(size) ~ " value", type, size, typeID, "value.x, value.y, value.z, value.w")
			~   format(header, type ~ " value0, " ~ type ~ " value1," ~ type ~ " value2," ~ type ~ " value3", type, size, typeID, "value0, value1, value2, value3");

	assert(false);
}
+/