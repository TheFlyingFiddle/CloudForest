module graphics.frameBuffer;

import math.vector;
import std.algorithm : remove, countUntil;
import graphics.errors;
import graphics.enums;
import graphics.context;
import graphics.texture;
import derelict.opengl3.gl3;

final class Renderbuffer
{
	package const uint glName, width, height;

	this(uint glName, uint width, uint height)
	{
		this.glName = glName;
		this.width = width;
		this.height = height;
	}

	static Renderbuffer create(InternalFormat format, uint width, uint height, uint samples = 0) 
	{
		uint glName;
		glGenRenderbuffers(1, &glName);
		auto rb = new Renderbuffer(glName, width, height);

		if(samples > 0) {
			glRenderbufferStorageMultisample(GL_RENDERBUFFER, samples, format, width, height);
		} else {
			glRenderbufferStorage(GL_RENDERBUFFER, format, width, height);			
		}

		return rb;
	}

	bool deleted() @property
	{
		return glIsRenderbuffer(glName) == GL_FALSE;
	}

	void destroy()
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteRenderbuffers(1, &glName);
	}
}

enum FrameBufferTarget
{
	draw,
	read,
	drawRead
}

enum BlitMode
{
	color = GL_COLOR_BUFFER_BIT,
	depth = GL_DEPTH_BUFFER_BIT, 
	stencil = GL_STENCIL_BUFFER_BIT,
	colorDepth = color | depth,
	colorStencil = color | stencil,
	depthStencil = depth | stencil,
	all = color | depth | stencil
}

enum BlitFilter 
{
	nearest = GL_NEAREST,
	linear = GL_LINEAR
}

final class FrameBuffer 
{
	package const uint glName;

	this(uint glName)
	{
		this.glName = glName;
	}

	static FrameBuffer[] frameBuffers;
	static FrameBuffer create() 
	{
		uint glName;
		glGenFramebuffers(1, &glName);
		auto fb = new FrameBuffer(glName);
		frameBuffers ~= fb;

		return fb;
	}

	bool deleted() @property
	{
		return glIsFramebuffer(glName) == GL_FALSE;
	}

	void destroy()
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteFramebuffers(1, &glName);
		frameBuffers.remove(frameBuffers.countUntil(this));
	}

	static void destroyAll()
	{
		foreach(buffer; frameBuffers) 
			buffer.destroy();
	}

	void attachRenderBuffer(FrameBufferAttachement attachement,
							      Renderbuffer buffer)
		in { assertBound(this); }
		out { assertNoGLError(); }
	body
	{
		glFramebufferRenderbuffer(FrameBufferTarget.draw, attachement, GL_RENDERBUFFER, buffer.glName);
	}

	void attachTexture(FrameBufferAttachement attachement,
							 Texture texture, uint mipLevel)
		in { assertBound(this); }
		out { assertNoGLError(); }
	body
	{
		glFramebufferTexture(FrameBufferTarget.draw, attachement, texture.glName, mipLevel);
	}


	void attachCubeFace(FrameBufferAttachement attachement,
							 TextureCube texture, TextureCubeFace cubeFace, uint mipLevel)
	in { assertBound(this); }
	out { assertNoGLError(); }
	body
	{
		glFramebufferTexture2D(FrameBufferTarget.draw, attachement, cubeFace, texture.glName, mipLevel);
	}

	void attachLayeredTexture(FrameBufferAttachement attachement,
							 Texture texture, uint mipLevel, uint layer)	
		in { assertBound(this); }
		out { assertNoGLError(); }
	body
	{
		glFramebufferTextureLayer(FrameBufferTarget.draw, attachement, texture.glName, mipLevel, layer);
	}


	static void blit(FrameBuffer from, FrameBuffer to,
						  uint4 fromRect, uint4 toRect, 
						  BlitMode mode, BlitFilter filter)
	out { assertNoGLError(); }
	body
	{
		Context.frameBuffer.read = from;
		Context.frameBuffer.draw = to;
		
		glBlitFramebuffer(fromRect.x, fromRect.y, fromRect.z, fromRect.w,
								toRect.x, toRect.y, toRect.z, toRect.w,
								mode, filter);
	}

}