module graphics.buffer;

import derelict.opengl3.gl3;
import graphics.context;
import graphics.errors;
import graphics.common;
import utils.assertions;
import std.traits;
import std.typecons;
import graphics.enums;

class Buffer 
{
	package const uint glName;
	package BufferHint hint;
	package uint _size;
	
	uint size() @property
	{
		return this._size;
	}

	this(uint glName, BufferHint hint) 
	{
		this.glName = glName;
		this.hint = hint;
		this._size = 0;
	}

	package static uint createBuffer() 
	{
		uint glName;
		glGenBuffers(1, &glName);
		return glName;
	}

	abstract BufferTarget target() @property;

	override bool opEquals(Object obj)
	{
		return (is(typeof(obj) == Buffer)) && (cast(Buffer)obj).glName == this.glName;
	}

	void destroy() 		
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteBuffers(1, &glName);
	}

	bool deleted() 
	{
		return glIsBuffer(this.glName) == GL_FALSE;
	}

	static void copyBetween(From, To)(From from, To to,  uint fromOffset, uint toOffset,
										uint size)
		in { 
			assertBound(from);
			assertBound(to);
		}
		out { assertNoGLError();}
	body
	{
		glCopyBufferSubData(from.target, to.target, fromOffset, toOffset, size);
	}

	package static void bufferData(T)(Buffer buffer, T data) if(isArray!T)				
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		buffer._size = T.sizeof * data.length;
		glBufferData(buffer.target, buffer.size, data.ptr, buffer.hint);
	}

	package static void initialize(Buffer buffer, uint size)
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		buffer._size = size;
		glBufferData(buffer.target, size, null, buffer.hint);
	}

	package static void bufferSubData(T)(Buffer buffer, T data, uint unitOffset) if(isArray!T)
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		glBufferSubData(buffer.target, T.sizeof * unitOffset, T.sizeof * data.length, data.ptr);
	}

	package static T[] getBufferSubData(T)(Buffer buffer, uint offset, uint size, T[] output = null)		
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		if(output.length < size / T.sizeof) {
			output.length = size / T.sizeof + 1;
		}

		glGetBufferSubData(buffer.target, T.sizeof * output, size, ouptut.ptr);
		return output;
	}


	//The pointer here should be replaced by an output/input range
	//Since this is the standard and SAFE way of doing stuff in d. 
	package static T* mapRange(Buffer,T)(Buffer buffer, uint offset, uint length, BufferAccess access)
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		auto ptr = glMapBufferRange(Buffer.target, offset, length, access);
		if(!ptr) {
			throw new Exception("Mapping of buffer failed!");
		}
		return cast(T*)ptr;
	}

	package static void mapBuffer(T)(Buffer buffer, uint offset, uint length, BufferAccess access,
												void delegate(T* ptr) workWithPointer)
		in { assertBound(buffer); }
		out { assertNoGLError(); }
	body
	{
		auto ptr = cast(T*)glMapBufferRange(buffer.target, offset, length, access);
		workWithPointer(ptr);
		glUnmapBuffer(buffer.target);
	}

	void flushMappedBufferRange(uint offset, uint length)
		in { assertBound(this); }
		out { assertNoGLError(); }
	body
	{
		glFlushMappedBufferRange(this.target, offset, length);
	}

}

mixin template BufferData(BufferTarget bufferTarget, BufferType,  bool canBeStruct, LegalTypes...)
{
	override BufferTarget target() @property { return bufferTarget; }
	
	private this(uint glName, BufferHint hint) 
	{
		super(glName, hint);
	}

	static BufferType create(BufferHint hint)
	{
		auto buffer = new BufferType(Buffer.createBuffer(), hint);
		return buffer;
	}

	void initialize(uint size) {
		Buffer.initialize(this, size);
	}

	void bufferData(T)(T[] data)
	{
		static assert (isValidType!(T), assertMsg);
		Buffer.bufferData(this, data);
	}

	void bufferSubData(T)(T[] data, uint unitOffset)  
	{
		static assert (isValidType!(T),assertMsg);
		Buffer.bufferSubData(this, data, unitOffset);
	}

	T getBufferSubData(T)(uint offset, uint size, T[] output = null)  
	{
		static assert (isValidType!(T),assertMsg);
		Buffer.getBufferSubData(offset, size, output);
	}

	//The pointer here should be replaced by an output/input range
	//Since this is the standard and SAFE way of doing stuff in d. 
	T* mapRange(T)(uint offset, uint length, BufferAccess access)
	{
		static assert (isValidType!(T),assertMsg);
		return Buffer.mapRange!(T)(this, offset, length, access);
	}

	enum assertMsg = "Ileagal type for buffer. Legal types are " ~ LegalTypes.stringof 
		~ (canBeStruct ? " aswell as structs without indirection" : "");

	template isValidType(T) {
		enum isValidType = graphics.common.isAny!(T, LegalTypes)  || 
			(canBeStruct ? is(T == struct) : false) &&
			!hasIndirections!(T);
	}
}

alias TextureBuffer TBO;
final class TextureBuffer : Buffer 
{
	mixin BufferData!(BufferTarget.texture, TextureBuffer, false,  int);
}

alias PixelPackBuffer PPBO;
final class PixelPackBuffer : Buffer 
{
	mixin BufferData!(BufferTarget.pixelPack,PixelPackBuffer, false, int);
}

alias PixelUnpackBuffer PUBO;
final class PixelUnpackBuffer : Buffer 
{
	mixin BufferData!(BufferTarget.pixelUnpack,PixelUnpackBuffer, false, int);
} 

alias VertexBuffer VBO;
final class VertexBuffer : Buffer
{
	mixin BufferData!(BufferTarget.vertex,VertexBuffer,  true, uint, float, int, short, ushort);
}

alias IndexBuffer IBO;
final class IndexBuffer : Buffer 
{
	mixin BufferData!(BufferTarget.index,IndexBuffer,  false, ubyte, ushort, uint);
}