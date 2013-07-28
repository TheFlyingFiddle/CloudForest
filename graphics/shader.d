module graphics.shader;

import graphics.errors;
import derelict.opengl3.gl3;
import graphics.common;
import graphics.enums;
import std.algorithm : remove, countUntil;

/**
* Authors: Lukas K
* Date: June 22, 2013
* Examples:
*-----------------------------------------------------------------------------
*	auto shader = Shader(ShaderType.vertex); 
*	shader.source = myShaderSource;  
*	shader.compile(); //In debug mode failiure will cause an assertion error. 
*	writeln(shader.infoLog); //Prints information of the shader compile process.
* ----------------------------------------------------------------------------
* NOTE: Error checking is done via contract programing so 
*       in release builds errors will not be detected.
*/
final class Shader
{
	//The name that the opengl driver gave for this shader.
	package const uint glName;
	
	//Creates a shader from a shader name given by the opengl driver.
	this(ShaderType type, const(char)[] source)
		out { assertNoGLError(); }
	body
	{
		this.glName = glCreateShader(type);
		this.source = source;
		this.compile();
	}

	void destroy() 
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteShader(this.glName);
	}

	/// The type of shader.
	ShaderType type() @property
		out { assertNoGLError(); }
	body
	{
		return cast(ShaderType)getShaderParameter(ShaderParameter.shaderType);
	}

	///True if the shader has been deleted by a call to free()
	bool deleted() @property
		out { assertNoGLError(); }
	body
	{
		return getShaderParameter(ShaderParameter.deleteStatus) == GL_TRUE;
	}
	
	///Gets the source of the shader.
	string source() @property
		in { assert(shaderSourceLength <= c_buffer.length); }
		out { assertNoGLError(); }
	body
	{ 
		int length;
		glGetShaderSource(glName,
								c_buffer.length,
								&length,
								c_buffer.ptr);
		return c_buffer[0 .. length].idup;
	}

	///Gets the info log of the shader.
	string infoLog() @property
		in { assert(infoLogLength <= c_buffer.length); }
		out { assertNoGLError(); }
	body
	{
		int length;
		glGetShaderInfoLog(glName,
								 c_buffer.length,
								 &length,
								 c_buffer.ptr);
		return c_buffer[0 .. length].idup;
	}
	
	package void compile()
	{
		glCompileShader(glName);
		if(!compiled) {
			throw new ShaderCompileException(infoLog);
		}
	}

	package void source(const(char)[] source) @property
	{
		int length = source.length;
		auto c_source = cast(char*)source.ptr;
		glShaderSource(glName, 1, &c_source, &length);
	}

	private int shaderSourceLength() @property
	{
		return getShaderParameter(ShaderParameter.shaderSourceLength);
	}

	private int infoLogLength() @property
	{
		return getShaderParameter(ShaderParameter.infoLogLength);
	}

	private bool compiled() @property
	{
		return getShaderParameter(ShaderParameter.compileStatus) == GL_TRUE;
	}

	private int getShaderParameter(ShaderParameter param) 
	{
		int data;
		glGetShaderiv(glName, param, &data);
		return data;
	}

	///Releases resources used by the shader compiler.
	///Shaders can still be compiled after this operation is done.
	///NOTE: Depending on the opengl driver this might do nothing. 
	///		it is more of a hint then an actuall commmand.
	public static nothrow void releaseCompiler() 
	{
		glReleaseShaderCompiler();
	}
}