module graphics.uniform;

import graphics.all;
import math.vector;
import utils.assertions;
import graphics.enums;
import derelict.opengl3.gl3;


alias UniformBuffer UBO;
final class UniformBuffer : Buffer 
{ 
	override BufferTarget target() @property { return BufferTarget.uniform; }

	this(BufferHint hint) 
	{ 
		super(hint);
	}

	void initialize(uint size) 
	{
		Buffer.initialize(this, size);
	}

	private void bindBlock(T)(Program program, string blockName, uint bindingIndex, uint offset = 0)
		in {  }
		out { assertNoGLError(); }
	body
	{
		auto block = program.getUniformBlock(blockName);
		this.bindBlock(program, info, bindingIndex, offset);
	}

	BufferUniform!(T) uniform(T)(uint offset, T data) 
		 in { 
			 assert(T.sizeof + offset <= size); 
			 assert(isAligned(offset));
		}
	body
	{
			return new BufferUniform!T(this, offset, data);
	}


	uint alignment() @property
	{
		return Context.getInteger(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT);
	}

	void bufferSubData(T)(T data, uint unitOffset) if(isArray!T)
	{
		graphics.buffer.bufferData(this, data, unitOffset);
	}

	void bufferSubData(T)(T data, const uint byteOffset = 0) if(!isArray!(T))
	{
		glBufferSubData(target, byteOffset, T.sizeof, &data);
	}

	T getBufferSubData(T)(uint offset, uint size, T[] output = null)  
	{
		Buffer.getBufferSubData(offset, size, output);
	}

   private void bindBlock(T)(UniformBlockInfo info, uint bindingIndex)
		out { assertNoGLError(); }
	body
	{
		glUniformBlockBinding(info.program.glName, info.index, bindingIndex);
	}

	private bool isAligned(uint offset) {
		return offset % alignment == 0;
	}
}


class BufferUniformBase 
{
	private uint _index;
	package const uint offset, size;
	package UniformBuffer buffer;

	private this(UniformBuffer buffer, uint offset, uint size)
	{
		this.buffer = buffer;
		this.offset = offset;
		this.size = size;
		this._index = -1;
	}

	package void index(uint value) @property
	{
		this._index = value;
	}

	package uint index() @property
	{
		return this._index;
	}
}

final class BufferUniform(T) if(isStd140Aligned!T) : BufferUniformBase
{
	private T _data;
	
	private this(UniformBuffer buffer, uint offset, T data)
	{
		super(buffer, offset, T.sizeof);
		if(data != T.init) {
			this.data = data;
		}
	}

	void data(T data) @property
	{
		if(_data != data) {
			_data = data;
			Context.ubo = buffer;
			buffer.bufferSubData!T(data, offset);
		}
	}

	T data() @property
	{
		return _data;
	}

	
	void bindBlock(Program program, string blockName)
	{
		bindBlock(program.block(blockName));
	}

	void bindBlock(UniformBlockInfo info)
		in { validateBlock(info); }
	body
	{
		if(index == -1)
			throw new Exception("Cannot bind a UniformBlock to an unbound uniform index bind first");

		buffer.bindBlock!T(info, index);
	}

	void validateBlock(UniformBlockInfo info) 
	{
		assert(info.size == T.sizeof);
	}
}





template isStd140Aligned(T) {
	enum isStd140Aligned = true; //TODO: Fix this
}