module graphics.context;

import graphics.buffer;
import graphics.shader;
import graphics.program;
import graphics.texture;
import graphics.vertex;
import graphics.frameBuffer;
import graphics.color;
import graphics.errors;
import graphics.query;
import graphics.uniform;
import graphics.enums;
import derelict.opengl3.gl3;
import utils.assertions;
import math.vector;


import math.vector;
public import std.algorithm, std.typecons : Flag, Yes, No;


struct Context
{
	///These are used to track bound objects.
	private static Buffer[BufferTarget]		 _boundBuffers;
	private static BufferUniformBase[]      _bufferedUniforms;
	private static FrameBuffer				    _drawFrameBuffer;
	private static FrameBuffer					 _readFrameBuffer;
	private static Program						 _program;
	private static VertexArray					 _vertexArray;
	private static Texture[TextureTarget][] _textures;
	private static Sampler[]					 _samplers;

	//Blending 
	private static BlendEquation				 _colorBlendEquation;
	private static BlendEquation				 _alphaBlendEquation;
	private static BlendFactor					 _colorDstBlendFactor;
	private static BlendFactor					 _colorSrcBlendFactor;
	private static BlendFactor					 _alphaDstBlendFactor;
	private static BlendFactor					 _alphaSrcBlendFactor;
	private static Color							 _blendColor;
	
	//Depth
	private static CompareFunc					 _depthFunc;
	private static float							 _depthClearValue;
	private static float2						 _depthRange;
	private static bool							 _depthMask;
	
	//Stencil
	private static CompareFunc					 _stencilFuncFront;
	private static CompareFunc					 _stencilFuncBack;
	private static StencilOp					 _sfailBack;
	private static StencilOp					 _sfailFront;
	private static StencilOp					 _dfailBack;
	private static StencilOp					 _dfailFront;
	private static StencilOp					 _dppassBack;
	private static StencilOp					 _dppassFront;
	private static int						    _stencilFuncMaskFront;
	private static int							 _stencilFuncMaskBack;
	private static int							 _stencilMaskFront;
	private static int							 _stencilMaskBack;
	private static int							 _stencilRefFront;
	private static int							 _stencilRefBack;
	private static int							 _stencilClearMask;


	private static DrawBuffer[]				 _drawBuffers;
	private static DrawBuffer					 _readBuffer;

	private static Face							 _cullFace;
	private static FrontFace					 _frontFace;
	private static float						    _lineWidth;
	private static float							 _pointSize;
	private static float							 _pointFadeThreshold;
	private static PointSpriteOrigin			 _pointSpriteOrigin;
	private static LogicOp						 _logicOp;
	private static PolygonMode					 _polygonFillMode;
	private static float2						 _polygonOffset;
	private static uint							 _primitiveRestartIndex;
	private static ProvokingMode				 _provokingVertex;

	private static Color							 _clearColor;
	private static bool[4]						 _colorMask;
	private static bool							 _isClampColor;

	private static float							 _sampleCoverage;
	private static bool							 _sampleCoverageInvert;
	private static uint4							 _scissorRect;
	private static uint4							 _viewportRect;
	private static uint							 _sampleMask;
	private static uint[]						 _vertexAttributeDivisors;

	private static uint[PixelStoreParam]	 _pixelStoreParams;




	//This has to be called or stuff will not work.
	static void initialize() 
	{
		_bufferedUniforms.length = getInteger(GL_MAX_UNIFORM_BUFFER_BINDINGS);
		_textures.length = getInteger(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS);
		_samplers.length = getInteger(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS);
	}
	
	package static void bindBuffer(BufferTarget target, Buffer buffer)
		out { assertNoGLError(); }
	body
	{
		if(!buffer) {
			glBindBuffer(buffer.target, 0);
		} else {
			Buffer current = _boundBuffers.get(buffer.target, null);
			if(buffer != current) {
				glBindBuffer(buffer.target, buffer.glName);
			}
		}

		_boundBuffers[buffer.target] = buffer;
	}

	package static void bindTransformFeedback(VertexBuffer buffer, uint index)
		out { assertNoGLError(); }
	body
	{
		if(!buffer) {
			glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, index, 0);
			return;
		}

		if(_boundBuffers[buffer.target] == buffer)
			bindBuffer(buffer.target, null);

		//TEMPORARY SOLUTION DO NOT KNOW IF I WILL KEEP THIS BUT IT IS SIMPLE!
		glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, index, buffer.glName);
	}

	static auto transformFeedback()
	{
		struct FeedbackIndexer {
			void opIndexAssign(VertexBuffer buffer, uint index) {
				bindTransformFeedback(buffer, index);
			}
		}
		return FeedbackIndexer();
	}

	package static void bindTexture(Texture texture, uint imageUnit) 		
		in { assert(imageUnit <= _textures.length); }
		out { assertNoGLError(); }
	body
	{
		glActiveTexture(GL_TEXTURE0 + imageUnit);
		if(!texture) {
			glBindTexture(texture.target, 0);
		} else {
			Texture current = _textures[imageUnit].get(texture.target, null);
			if(texture != current) {
				glBindTexture(texture.target, texture.glName);
			}
		}
		
		_textures[imageUnit][texture.target] = texture;
	}

	static auto textures()
	{
		struct TextureIndexer {
			void opIndexAssign(Texture texture, uint index) {
				Context.bindTexture(texture, index);
			}

			Texture opIndex(TextureTarget target, uint index) {
				return Context._textures[index][target];
			}
		}
		return TextureIndexer();
	}

	package static void useProgram(Program program)
		out { assertNoGLError(); }
	body
	{
		if(!program) {
			glUseProgram(0);
		} else {

			if(program != _program)
				glUseProgram(program.glName);
		}

		_program = program;
	}

	package static void bindVertexArray(VertexArray array)		
		out { assertNoGLError(); }
	body
	{
		if(!array) {
			glBindVertexArray(0);
		} else {
			if(_vertexArray != array)
				glBindVertexArray(array.glName);
		}

		_vertexArray = array;
	}

	package static void bindReadFrameBuffer(FrameBuffer buffer) 
		out { assertNoGLError(); }
	body
	{
		if(!buffer) {
			glBindFramebuffer(FrameBufferTarget.read, 0);
		} else {
			if(buffer != _readFrameBuffer)
				glBindFramebuffer(FrameBufferTarget.read, buffer.glName);
		}

		_readFrameBuffer = buffer;
	}

	package static void bindDrawFrameBuffer(FrameBuffer buffer) 
		out { assertNoGLError(); }
	body
	{
		if(!buffer) {
			glBindFramebuffer(FrameBufferTarget.draw, 0);
		} else {

			if(buffer != _drawFrameBuffer)
				glBindFramebuffer(FrameBufferTarget.draw, buffer.glName);
		}

		_drawFrameBuffer = buffer;
	}

	package static void bindDrawReadFrameBuffer(FrameBuffer buffer) 
		out { assertNoGLError(); }
	body
	{
		if(!buffer) {
			glBindFramebuffer(FrameBufferTarget.drawRead, 0);
		} else {
			if(buffer != _readFrameBuffer || buffer != _drawFrameBuffer)
				glBindFramebuffer(FrameBufferTarget.drawRead, buffer.glName);
		}

		_drawFrameBuffer = buffer;
		_readFrameBuffer = buffer;
	}

	static auto frameBuffer() {
		struct FrameBufferHelper {
				void opAssign(FrameBuffer buffer) {
					bindDrawReadFrameBuffer(buffer);
				}
				
				void draw(FrameBuffer buffer) @property
				{
					bindDrawFrameBuffer(buffer);
				}

				void read(FrameBuffer buffer) @property
				{
					bindReadFrameBuffer(buffer);
				}
		}
		return FrameBufferHelper();
	}

	package static void bindSampler(Sampler sampler, uint index)
		out { assertNoGLError(); }
	body
	{
		if(!sampler) {
			glBindSampler(index, 0);
		} else {
			if(sampler != _samplers[index])
				glBindSampler(index, sampler.glName);

		}
		_samplers[index] = sampler;
	}

	static auto sampler() 
	{
		struct SamplerIndexer {
			void opIndexAssign(Sampler sampler, uint index) {
				Context.bindSampler(sampler, index);
			}

			Sampler opIndex(uint index) {
				return Context._samplers[index];
			}
		}
		return SamplerIndexer();
	}

	package static void bindBufferUniform(BufferUniformBase uniform, uint index)
		out { assertNoGLError(); }
	body
	{
		auto current = _bufferedUniforms[index];
		if(!uniform) {
			glBindBufferRange(BufferTarget.uniform, uniform.index, 0, 0, 0);
			//If a uniform was at that location we make it aware that it was unbound.
			if(current) current.index = -1;
		} else {
			if(current != uniform) {
				glBindBufferRange(BufferTarget.uniform, index, uniform.buffer.glName, uniform.offset, uniform.size);
				uniform.index = index;
				if(current) current.index = -1;
			}
		}
		_bufferedUniforms[index] = uniform;
	}
	
	static auto bufferUniform() @property
	{
		struct BufferUniformIndexer	{
			void opIndexAssign(BufferUniformBase uniform, uint index) {
				Context.bindBufferUniform(uniform, index);
			}

			BufferUniformBase opIndex(uint index) {
				return Context._bufferedUniforms[index];
			}
		}
		return BufferUniformIndexer();
	}

	static Buffer boundBuffer(BufferTarget target) 
	{
		return (target in _boundBuffers) ? _boundBuffers[target] : null;
	}

	static VertexBuffer vertexBuffer() @property
	{
		return cast(VertexBuffer)_boundBuffers[BufferTarget.vertex];
	}

	static void vertexBuffer(VertexBuffer buffer) @property
	{
		bindBuffer(BufferTarget.vertex, buffer);
	}

	static IndexBuffer indexBuffer() @property
	{
		return cast(IndexBuffer)_boundBuffers[BufferTarget.index];
	}

	static void indexBuffer(IndexBuffer buffer) @property
	{
		bindBuffer(BufferTarget.index, buffer);
	}

	static PixelPackBuffer pixelPackBuffer() @property
	{
		return cast(PixelPackBuffer)_boundBuffers[BufferTarget.pixelPack];
	}

	static void pixelPackBuffer(PixelPackBuffer buffer) @property
	{
		bindBuffer(BufferTarget.pixelPack, buffer);
	}

	static PixelUnpackBuffer pixelUnpackBuffer() @property
	{
		return cast(PixelUnpackBuffer)_boundBuffers[BufferTarget.pixelUnpack];
	}

	static void pixelUnpackBuffer(PixelUnpackBuffer buffer) @property
	{
		bindBuffer(BufferTarget.pixelUnpack, buffer);
	}

	static TextureBuffer textureBuffer() @property
	{
		return cast(TextureBuffer)_boundBuffers[BufferTarget.texture];
	}

	static void textureBuffer(TextureBuffer buffer) @property
	{
		bindBuffer(BufferTarget.texture, buffer);
	}

	static UniformBuffer uniformBuffer() @property
	{
		return cast(UniformBuffer)_boundBuffers[BufferTarget.uniform];
	}

	static void uniformBuffer(UniformBuffer buffer) @property
	{
		bindBuffer(BufferTarget.uniform, buffer);
	}

	static Program program() @property
	{
		return _program;
	}

	static void program(Program program) @property
	{
		useProgram(program);
	}

	static VertexArray vertexArray() @property
	{
		return _vertexArray;
	}

	static void vertexArray(VertexArray array) @property
	{
		bindVertexArray(array);
	}

	static int getInteger(uint pname)
		out { assertNoGLError(); }
	body
	{
		int data;
		glGetIntegerv(pname, &data);
		return data;
	}

	static Color clearColor() @property
	{
		return _clearColor;
	}

	static void clearColor(Color color) @property 
		out { assertNoGLError(); }
	body
	{
		if(_clearColor != color) {
			_clearColor = color;
			glClearColor(color.r, color.g, color.b, color.a);
		}
	}

	static Color blendColor() @property
	{
		return _blendColor;
	}

	static void blendColor(Color color) @property 
		out { assertNoGLError(); }
	body
	{
		if(_blendColor != color) {
			_blendColor = color;
			glBlendColor(color.r, color.g, color.b, color.a);
		}
	}

	static bool clampColor() @property
	{
		return _isClampColor;
	}

	static void hint(HintTarget target, HintQuality hint) @property
	{
		glHint(target, hint);
	}

	static void clampColor(bool shouldClamp) @property 
		out { assertNoGLError(); }
	body
	{
		if(_isClampColor != shouldClamp) {
			_isClampColor = shouldClamp;
			glClampColor(GL_CLAMP_READ_COLOR, shouldClamp ? GL_TRUE : GL_FALSE);
		}
	}

	static void colorMask(bool red, bool green, bool blue, bool alpha)
		out { assertNoGLError(); }
	body
	{
		if(red != _colorMask[0] || green != _colorMask[1]
		|| blue != _colorMask[2] || alpha != _colorMask[3])
		{
			_colorMask[0] = red; _colorMask[1] = green;
			_colorMask[2] = blue; _colorMask[3] = green;
			glColorMask(red ? GL_TRUE : GL_FALSE,
							green ? GL_TRUE : GL_FALSE,
							blue ? GL_TRUE : GL_FALSE,
							alpha ? GL_TRUE : GL_FALSE);
		}
	}

	static void cullFace(Face face) @property
		out { assertNoGLError(); }
	body
	{
		if(face != _cullFace) {
			_cullFace = face;
			glCullFace(face);
		}
	}

	static Face cullFace() @property
	{
		return _cullFace;
	}

	static void frontFace(FrontFace face) @property
		out { assertNoGLError(); }
	body
	{
		if(face != _frontFace) {
			_frontFace = face;
			glCullFace(face);
		}
	}

	static FrontFace frontFace() @property
	{
		return _frontFace;
	}

	static void lineWidth(float lineWidth) @property
		out { assertNoGLError(); }
	body
	{
		if(_lineWidth != lineWidth) {
			_lineWidth = lineWidth;
			glLineWidth(lineWidth);
		}
	}

	static float lineWidth() @property
	{
		return _lineWidth;
	}		

	static void pointSize(float pointSize) @property
		out { assertNoGLError(); }
	body
	{
		if(_pointSize != pointSize) {
			_pointSize = pointSize;
			glPointSize(pointSize);
		}
	}

	static float pointSize() @property
	{
		return _pointSize;
	}

	static void pointFadeThresholdSize(float threshold) @property
		out { assertNoGLError(); }
	body
	{
		if(_pointFadeThreshold != threshold) {
			_pointFadeThreshold = threshold;
			glPointParameterf(PointParam.pointFadeThresholdSize, threshold);
		}
	}

	static auto vertexAttribDivisor() 
		out { assertNoGLError(); }
	body
	{
		struct VertexDivisorHelper {
				void opIndexAssign(uint vertexDivisor, uint index) {
					if(_vertexAttributeDivisors[index] != vertexDivisor) {
						_vertexAttributeDivisors[index] = vertexDivisor;
						glVertexAttribDivisor(index, vertexDivisor);
					}	
				} 
					
				uint opIndex(uint index) {
					return _vertexAttributeDivisors[index];
				}
		}
		return VertexDivisorHelper();
	}

	static float pointFadeThresholdSize() @property
	{
		return _pointFadeThreshold;
	}

	static void pointSpriteCoordOrigin(PointSpriteOrigin origin) @property
	{
		if(_pointSpriteOrigin != origin) {
			_pointSpriteOrigin = origin;
			glPointParameteri(PointParam.pointSpriteCoordOrigin, origin);
		}
	}

	static void polygonOffset(float2 polygonOffset)  @property
		out { assertNoGLError(); }
	body
	{
			if(_polygonOffset != polygonOffset) {
				_polygonOffset = polygonOffset;
				glPolygonOffset(polygonOffset.x, polygonOffset.y);
			}
	}

	static void primitiveRestartIndex(uint index) @property
	{
		if(_primitiveRestartIndex != index) {
			_primitiveRestartIndex = index;
			glPrimitiveRestartIndex(index);
		}
	}

	static uint primitiveRestartIndex() @property
	{
		return _primitiveRestartIndex;
	}

	static void provokingVertex(ProvokingMode vertex) @property
	{
		if(_provokingVertex != vertex) {
			_provokingVertex = vertex;
			glProvokingVertex(vertex);
		}
	}

	static ProvokingMode provokingVertex() @property
	{
		return _provokingVertex;
	}

	static float2 polygonOffset() @property
	{
		return _polygonOffset;
	}

	static void logicOp(LogicOp op) @property
		out { assertNoGLError(); }
	body
	{
		if(_logicOp != op) {
			_logicOp = op;
			glLogicOp(op);
		}
	}

	static LogicOp logicOp() @property
	{
		return _logicOp;
	}

	static void pixelStore(PixelStoreParam param, uint value) 
		out { assertNoGLError(); }
	body
	{
		if(_pixelStoreParams[param] != value) {
			_pixelStoreParams[param] = value;
			glPixelStorei(param, value);
		}
	}

	static uint pixelStore(PixelStoreParam param) 
	{
		return _pixelStoreParams[param];		
	}
	

	static float pointSize(float pointSize) @property
	{
		return _pointSize;
	}

	static void depthFunc(CompareFunc depthFunc) @property
	{
		if(_depthFunc != depthFunc) {
			_depthFunc = depthFunc;
			glDepthFunc(depthFunc);
		}
	}

	static CompareFunc depthFunc() @property
	{
		return _depthFunc;
	}

	static void depthMask(bool mask) 
		out { assertNoGLError(); }
	body
	{
		if(_depthMask != mask) {
			_depthMask = mask;
			glDepthMask(mask);
		}
	}

	static void depthRange(float2 range) @property
		out { assertNoGLError(); }
	body
	{
		if(_depthRange != range) {
			_depthRange = range;
			glDepthRange(range.x, range.y);
		}
	}

	static float2 depthRange() @property
	{
		return _depthRange;
	}

	static void blendEquation(BlendEquation equation) @property
		out { assertNoGLError(); }
	body
	{
		if(_alphaBlendEquation != equation || _colorBlendEquation != equation) {
			_alphaBlendEquation = equation;
			_colorBlendEquation = equation;

			glBlendEquation(equation);
		}
	}

	static void blendEquation(BlendEquation colorEqu, BlendEquation alphaEqu) @property
		out { assertNoGLError(); }
	body
	{
		if(_alphaBlendEquation != alphaEqu || _colorBlendEquation != colorEqu) {
			_alphaBlendEquation = alphaEqu;
			_colorBlendEquation = colorEqu;

			glBlendEquationSeparate(colorEqu, alphaEqu);
		}
	}

	static BlendEquation colorBlendEquation() @property
	{
		return _colorBlendEquation;
	}

	static BlendEquation alphaBlendEquation() @property
	{
		return _alphaBlendEquation;
	}
	
	static void blendFunc(BlendFactor src, BlendFactor dst) 
		out { assertNoGLError(); }
	body
	{
		if(_colorSrcBlendFactor != src || _alphaSrcBlendFactor != src
		|| _colorDstBlendFactor != dst || _alphaDstBlendFactor != dst) {
			_colorSrcBlendFactor = src;
			_alphaSrcBlendFactor = src;
			_colorDstBlendFactor = dst;
			_alphaDstBlendFactor = dst;
			
			glBlendFunc(src, dst);
		}
	}

	static void polygonMode(PolygonMode mode) @property
		out { assertNoGLError(); }
	body
	{
		if(_polygonFillMode != mode) {
			_polygonFillMode = mode;
			glPolygonMode(GL_FRONT_AND_BACK, mode);
		}
	}

	static PolygonMode polygonMode() @property
	{
		return _polygonFillMode;
	}

	//Have to store these someware
	static void enable(Capability cap)
		out { assertNoGLError(); }
	body
	{
		glEnable(cap);
	}

	static void disable(Capability cap)
		out { assertNoGLError(); }
	body
	{
		glDisable(cap);
	}

	static void scissor(uint4 scissorRect) @property
		out { assertNoGLError(); }
	body
	{
		if(_scissorRect != scissorRect) {
			_scissorRect = scissorRect;
			glScissor(scissorRect.x, scissorRect.y,
						 scissorRect.z, scissorRect.w);
		}
	}

	static uint4 scissor() @property
		out { assertNoGLError(); }
	body
	{
		return _scissorRect;
	}

	static void viewport(uint4 viewportRect) @property
		out { assertNoGLError(); }
	body
	{
		if(_viewportRect != viewportRect) {
			_viewportRect = viewportRect;
			glViewport(viewportRect.x, viewportRect.y,
						 viewportRect.z, viewportRect.w);
		}
	}


	static uint4 viewport() @property
		out { assertNoGLError(); }
	body
	{
		return _viewportRect;
	}

	static void blendFuncSeparate(BlendFactor colorSrc,BlendFactor alphaSrc,
											BlendFactor colorDst, BlendFactor alphaDst) 
	out { assertNoGLError(); }
	body
	{
		if(_colorSrcBlendFactor != colorSrc || _alphaSrcBlendFactor != alphaSrc
			|| _colorDstBlendFactor != colorDst || _alphaDstBlendFactor != alphaDst) {
				_colorSrcBlendFactor = colorSrc;
				_alphaSrcBlendFactor = alphaSrc;
				_colorDstBlendFactor = colorDst;
				_alphaDstBlendFactor = alphaDst;

				glBlendFuncSeparate(colorSrc, colorDst, alphaSrc, alphaDst);
			}
	}

	static BlendFactor colorSrcBlendFactor() @property
	{
		return _colorSrcBlendFactor;
	}

	static BlendFactor alphaSrcBlendFactor() @property
	{
		return _alphaSrcBlendFactor;
	}

	static BlendFactor colorDstBlendFactor() @property
	{
		return _colorDstBlendFactor;
	}

	static BlendFactor alphaDstBlendFactor() @property
	{
		return _alphaDstBlendFactor;
	}

	static float depthClearValue() @property
	{
		return _depthClearValue;
	}

	static void depthClearValue(float f) @property
		out { assertNoGLError(); }
	body
	{
		if(_depthClearValue != f) {
			_depthClearValue = f;
			glClearDepth(f);
		}
	}


	static void stencilFunc(CompareFunc func,
									int refVal,
									uint mask) 
		out { assertNoGLError(); }
	body
	{
		if(_stencilFuncBack	    != func   || 
			_stencilFuncFront     != func   || 
			_stencilRefBack       != refVal ||
			_stencilRefFront      != refVal ||
			_stencilFuncMaskBack  != mask   ||
			_stencilFuncMaskFront != mask) 
		{
			_stencilFuncBack		 = func;
			_stencilFuncFront		 = func;
			_stencilRefBack		 = refVal;
			_stencilRefFront		 = refVal;
			_stencilFuncMaskBack  = mask;
			_stencilFuncMaskFront = mask;

			glStencilFunc(func, refVal, mask);
		}
	}

	static void stencilFuncSeparate(Face face,
											  CompareFunc func,
											  int refVal,
											  uint mask)
		out { assertNoGLError(); }
	body
	{
		if(face == Face.front) {
			if(_stencilFuncFront     != func   || 
				_stencilRefFront      != refVal ||
				_stencilFuncMaskFront != mask) 
{
				_stencilFuncFront		 = func;
				_stencilRefFront		 = refVal;
				_stencilFuncMaskFront = mask;
				glStencilFuncSeparate(face, func, refVal, mask);
			}
		} else {
			if(_stencilFuncBack	    != func   || 
				_stencilRefBack       != refVal ||
				_stencilFuncMaskBack  != mask)
			{
				_stencilFuncBack		 = func;
				_stencilRefBack		 = refVal;
				_stencilFuncMaskBack  = mask;

				glStencilFuncSeparate(face, func, refVal, mask);
			}
		}
	}

	static void stencilOp(StencilOp sfail,
								 StencilOp dfail,
								 StencilOp dppass) 
	{
		if(_sfailBack   != sfail  ||
			_sfailFront  != sfail  ||
			_dfailBack	 != dfail  ||
			_dfailFront  != dfail  ||
			_dppassBack  != dppass ||
			_dppassFront != dppass) 
		{
			_sfailBack = sfail;
			_sfailFront = sfail;
			_dfailBack = dfail;
			_dfailFront = dfail;
			_dppassBack = dppass;
			_dppassFront = dppass;
			glStencilOp(sfail, dfail, dppass);		
		}
	}

	static void stencilOpSaparate(Face face,
										   StencilOp sfail,
											StencilOp dfail,
											StencilOp dppass) 
	{
		if(face == Face.front) {
			if(_sfailFront  != sfail  ||
				_dfailFront  != dfail  ||
				_dppassFront != dppass) 
			{
				_sfailFront = sfail;
				_dfailFront = dfail;
				_dppassFront = dppass;
				glStencilOpSeparate(face, sfail, dfail, dppass);		
			}
		} else {
			if(_sfailBack   != sfail  ||
				_dfailBack	 != dfail  ||
				_dppassBack  != dppass) 
			{
				_sfailBack = sfail;
				_dfailBack = dfail;
				_dppassBack = dppass;
				glStencilOpSeparate(face, sfail, dfail, dppass);	
			}
		}
	}


	static void stencilMask(uint mask) @property
		out { assertNoGLError(); }
	body
	{
		if(_stencilMaskBack  != mask ||
			_stencilMaskFront != mask) {
				_stencilMaskBack = mask;
				_stencilMaskFront = mask;
				glStencilMask(mask);
			}
	}

	static void stencilMaskSeparate(Face face, uint mask) @property
		out { assertNoGLError(); }
	body
	{
		if(face == Face.front) {
			if(_stencilMaskFront != mask) {
				_stencilMaskFront = mask;
				glStencilMaskSeparate(face, mask);
			}
		} else {
			if(_stencilMaskBack != mask) {
				_stencilMaskBack = mask;
				glStencilMaskSeparate(face, mask);
			}
		}
	}

	static StencilOp sfailBack() @property
	{
		return _sfailBack;
	}

	static StencilOp sfailFront() @property
	{
		return _sfailFront;
	}

	static StencilOp dfailBack() @property
	{
		return _dfailBack;
	}

	static StencilOp dfailFront() @property
	{
		return _dfailBack;
	}

	static StencilOp dppassBack() @property
	{
		return _dppassBack;
	}

	static StencilOp dppassFront() @property
	{
		return _dppassFront;
	}




	static CompareFunc stencilFuncBack() @property
	{
		return _stencilFuncBack;
	}
	
	static CompareFunc stencilFuncFront() @property
	{
		return _stencilFuncFront;
	}

	static int stencilRefBack() @property
	{
		return _stencilRefBack;
	}

	static int stencilRefFront() @property
	{
		return _stencilRefFront;
	}

	static uint stencilFuncMaskBack() @property
	{
		return _stencilFuncMaskBack;
	}

	static uint stencilFuncMaskFront() @property
	{
		return _stencilFuncMaskFront;
	}

	static uint stencilMaskBack() @property 
	{
		return _stencilMaskBack;
	}

	static uint stencilMaskFront() @property
	{
		return _stencilMaskFront;
	}

	static int stencilClearMask() @property
	{
		return _stencilClearMask;	
	}
	
	static void stencilClearMask(int mask) @property
		out { assertNoGLError(); }
	body
	{
		if(_stencilClearMask != mask) {
			_stencilClearMask = mask;
			glClearStencil(mask);
		}
	}

	static void clearDrawBuffer(uint index, Color color) 
		out { assertNoGLError(); }
	body
	{
		float[4] f = [color.r, color.g, color.b, color.a];
		glClearBufferfv(GL_COLOR, GL_DRAW_BUFFER0 + index, f.ptr); 
	}

	static void clearDepthBuffer(float depth)
		out { assertNoGLError(); }
	body
	{
		glClearBufferfv(GL_DEPTH, 0, &depth); 
	}

	static void clearStencilBuffer(int stencil)
		out { assertNoGLError(); }
	body
	{
		glClearBufferiv(GL_STENCIL, 0, &stencil);
	}

	static void clearDepthStencilBuffer(float depth, int stencil)
		out { assertNoGLError(); }
	body
	{
		glClearBufferfi(GL_DEPTH_STENCIL, 0, depth, stencil);
	}

	static void clear(ClearFlags flags) 	
		out { assertNoGLError(); }
	body
	{
		glClear(flags);
	}

	static void sampleCoverage(float value, bool invert)
		out { assertNoGLError(); }
	body
	{
		if(_sampleCoverage != value || _sampleCoverageInvert != invert) {
			_sampleCoverage = value;
			_sampleCoverageInvert = invert;
			glSampleCoverage(value, invert ? GL_TRUE : GL_FALSE);
		}
	}

	static float sampleCoverage() @property
	{
		return _sampleCoverage;
	}

	static bool sampleCoverageInvert() @property
	{
		return _sampleCoverageInvert;
	}

	static sampleMaski(uint sampleMask) @property
		out { assertNoGLError(); }
	body
	{
		if(_sampleMask != sampleMask) {
			_sampleMask = sampleMask;
			glSampleMaski(1, sampleMask);
		}
	}

	static uint samplerMask(uint samplerMask) @property
	{
		return _sampleMask;	
	}

	static void drawBuffers(DrawBuffer[] drawBuffers)
		out {assertNoGLError(); }
	body
	{
		if(_drawBuffers != drawBuffers) {
			_drawBuffers = drawBuffers.dup;
			glDrawBuffers(drawBuffers.length, cast(uint*)drawBuffers.ptr);
		}
	}

	static DrawBuffer[] drawBuffers() @property
	{
		return _drawBuffers.dup;
	}

	static void readBuffer(DrawBuffer read) 
		out {assertNoGLError(); }
	body
	{
		if(_readBuffer != read) {
			_readBuffer = read;
			glReadBuffer(read);
		}
	}

	static void[] readPixels(uint2 bottomLeft,
								    uint2 dim,
								    ColorFormat format,
								    ColorType type,
									 void[] output = null) 
		out {assertNoGLError(); }
	body
	{
		assert(0); //Need to be able to determine output format. 
		glReadPixels(bottomLeft.x, bottomLeft.y, dim.x, dim.y, format, type, output.ptr);
		return output;
	}


	static DrawBuffer readBuffer() @property
	{
		return _readBuffer;
	}

	void transformFeedback(PrimitiveType type, void delegate() doRendering) 
		out { assertNoGLError(); }
	body
	{
		enable(Capability.rasterizerDiscard);
		glBeginTransformFeedback(type);
		
		doRendering();
		
		glEndTransformFeedback();
		disable(Capability.rasterizerDiscard);
	}

	static void conditonalRender(Query query, ConditionalRenderMode mode,  void delegate() render)
		out { assertNoGLError(); }
	body
	{
		glBeginConditionalRender(query.glName, mode);
		render();
		glEndConditionalRender();
	}

	static void drawArrays(PrimitiveType type, uint offset, uint count) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(program.validate().valid, program.infoLog);
		}
		out { assertNoGLError(); }
	body
	{
		glDrawArrays(type, offset, count);
	}

	static void multiDrawArrays(PrimitiveType type, int[] first, int[] count) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(program.validate().valid, program.infoLog);
			assert(first.length == count.length);
		}
		out { assertNoGLError(); }
	body
	{
		glMultiDrawArrays(type, first.ptr, count.ptr, first.length);
	}

	static void drawElements(T)(PrimitiveType type, uint offset, uint count) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
		out { assertNoGLError(); }
	body
	{
		glDrawElements(type, count, glIndexType!T , offset * T.sizeof);
	}

	static void multiDrawElements(T)(PrimitiveType type, uint[] offset, uint[] count) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(offset.length == count.length);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		offset[] *= T.sizeof;
		glMultiDrawElements(type, count.ptr, glIndexType!T, cast(void**)offset.ptr, offset.length);
	}

	static void multiDrawElementsBaseVertex(T)(PrimitiveType type, uint[] offset, uint[] count, uint[] baseVertex) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(offset.length == count.length && count.length == baseVertex.length);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		offset[] *= T.sizeof;
		glMultiDrawElementsBaseVertex(type, count.ptr, glIndexType!T, cast(void**)offset.ptr, offset.length, baseVertex.ptr);
	}



	static void drawRangeElements(T)(PrimitiveType type, uint offset, uint count, uint minIndex, uint maxIndex) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		glDrawRangeElements(type, minIndex, maxIndex, count, glIndexType!T , offset * T.sizeof);
	}

	static void drawRangeElements(T)(PrimitiveType type, uint offset, uint count, uint minIndex, uint maxIndex, uint baseVertex) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		glDrawRangeElementsBaseVertex(type, minIndex, maxIndex, count, glIndexType!T , offset * T.sizeof, baseVertex);
	}



	static void drawElementsBaseVertex(T)(PrimitiveType type, uint offset, uint count, uint baseVertex) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		glDrawElements(type, count, glIndexType!T , offset * T.sizeof, baseVertex);
	}

	static void drawElementsInstanced(T)(PrimitiveType type, uint offset, uint count, uint instanceCount) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		glDrawElementsInstanced(type, count, glIndexType!T , offset * T.sizeof, instanceCount);
	}

	static void drawElementsInstancedBaseVertex(T)(PrimitiveType type, 
																  uint offset, 
																  uint count, 
																  uint instanceCount,
																  uint baseVertex) 
		if(is(T == ubyte) || is(T == ushort) || is(T == uint)) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(indexBuffer);
			assert(program.validate().valid, program.infoLog);
		}
	out { assertNoGLError(); }
	body
	{
		glDrawElementsInstancedBaseVertex(type, count, glIndexType!T , offset * T.sizeof, instanceCount, baseVertex);
	}

	static void drawArraysInstanced(PrimitiveType type, uint offset, uint count, uint instanceCount) 
		in { 
			assert(program); 
			assert(vertexArray); 
			assert(program.validate().valid, program.infoLog);
		}
		out { assertNoGLError(); }
	body
	{
		glDrawArraysInstanced(type, offset, count, instanceCount);
	}


	template glIndexType(T) {
		static if(is(T == uint)) {
			enum glIndexType = GL_UNSIGNED_INT;
		} else static if(is(T == ushort)) {
			enum glIndexType = GL_UNSIGNED_SHORT;
		} else static if(is(T == ubyte)) {
			enum glIndexType = GL_UNSIGNED_BYTE;
		} else {
			static assert(0);
		}
	}


	static void finish() 
	{
		glFinish();
	}

	static void flush()
	{
		glFlush();
	}

}