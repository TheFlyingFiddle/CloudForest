module graphics.errors;

import derelict.opengl3.gl3;
import std.conv : to;
import std.string : text, format;
import graphics.all;

enum GLError : GLuint
{
	noError = GL_NO_ERROR,
	invalidEnum = GL_INVALID_ENUM,
	invalidValue = GL_INVALID_VALUE,
	invalidOperation = GL_INVALID_OPERATION,
	invalidFramebufferOperation = GL_INVALID_FRAMEBUFFER_OPERATION,
	outOfMemory = GL_OUT_OF_MEMORY,
}

public class GLErrorException : Exception 
{
	GLError error;

	this(GLError error, string message = null) 
	{
		this.error = error;
		if(message == null)
			super(to!string(error));
		else
			super(message);
	}
}

void assertNoGLError(string file = __FILE__, size_t line = __LINE__) 
{
	auto errorCode = cast(GLError)glGetError();
	if(errorCode == GLError.noError) return;

	throw new GLErrorException(errorCode, 
										text("\nGLError: ", errorCode,
											  " in file ", file ,
								  			  " on line : ", line));
}

void assertNotDeleted(T)(T obj, string file = __FILE__, size_t line = __LINE__)
{
	assert(!obj.deleted, format("\nGL object of type %s \nhas already been deleted!", T.stringof));
}

void assertBound(T)(T glObject, string file = __FILE__, size_t line = __LINE__) 
{
	static if(is(T == Program)) {
		assert(Context.program == glObject,
				 format("\nIllegal to operate on non bound program!\nin file %s on line %s",
						  file, line));	
	} else static if(is(T == VertexArray)) {
		assert(Context.vertexArray == glObject,
				 format("\nIllegal to operate on non bound vertex array!\nin file %s on line %s",
						  file, line));	
	} else static if(is(object : Buffer)) {
		assert(Context.boundBuffer(T.targetType) == buffer,
				 format("\nIllegal to operate on buffer if it is not bound!s\nin file %s on line %s",
						  file, line));	
	}

}


public class ShaderCompileException : Exception
{
	this(string compileErrors) {
		super("\nShader Compilation Failed! \n\n" ~ compileErrors);
	}
}

class ProgramLinkException : Exception 
{
	this(string infoLog) {
		super("Program Link Failed! \n\n" ~ infoLog);
	}
}

class ProgramValidationException : Exception
{
	this(string infoLog) {
		super("Program Validation Failed! \n\n" ~ infoLog);
	}
}

class AttributeMissmatchException : Exception
{
	this(string message) { super(message); }
}