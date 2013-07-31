module gui;

import graphics.texture;
import graphics.enums;
import SpriteBuffer;
import font;
import derelict.glfw3.glfw3;
import math.vector;
import frame;
import graphics.context;
import graphics.color;
import std.traits;
import math.matrix;
import math.helper;

struct ButtonState
{
	float2 loc;
	bool inState;
}

enum MouseButton
{	
	left	  = GLFW_MOUSE_BUTTON_1,
	rigth   = GLFW_MOUSE_BUTTON_2,
	middle  = GLFW_MOUSE_BUTTON_3,
	x0		  = GLFW_MOUSE_BUTTON_4,
	x1		  = GLFW_MOUSE_BUTTON_5,
	x2		  = GLFW_MOUSE_BUTTON_6,
	x3		  = GLFW_MOUSE_BUTTON_7,
	x4		  = GLFW_MOUSE_BUTTON_8
}

class MouseEventState
{
	ButtonState[GLFW_MOUSE_BUTTON_LAST] down;
	ButtonState[GLFW_MOUSE_BUTTON_LAST] up;
	bool[GLFW_MOUSE_BUTTON_LAST]				  changed;

	float2 oldLoc;
	float2 newLoc;
	float2 scrollDelta;

	this()
	{
		down[] = ButtonState(float2.zero, false);
		up[]	 = ButtonState(float2.zero, true);
		changed[] = false;
		oldLoc = float2.zero;
		newLoc = float2.zero;
		scrollDelta = float2.zero;
	}

	bool wasReleased(MouseButton button) 
	{
		return changed[button] && down[button].inState;
	}

	bool wasPressed(MouseButton button)
	{
		return changed[button] && up[button].inState;
	}

	bool isDown(MouseButton button) 
	{
		return down[button].inState;
	}

	bool isUp(MouseButton button) 
	{
		return up[button].inState;
	}
}

struct GUIProperty
{
	Color normalColor0;
	Color normalColor1;
	Color focusColor0;
	Color focusColor1;
	Color activeColor0;
	Color activeColor1;

	enum defaultButton = 
		GUIProperty(Color(0xFFaaaaFF),
						Color.black,
						Color(0xFFccccFF),
						Color.black,
						Color(0xFF8888FF),
						Color.black);
}





class GUI
{
	private static Frame		pixel;
	private static Sampler	sampler;
	private SpriteBuffer		buffer;
	private Font				font;

	private Frame checkBoxFrame;
	private Frame unCheckBoxFrame;

	private MouseEventState		mouseState;

	this(Font font, SpriteBuffer buffer = null)
	{
		if(pixel.texture is null) {
			Color[1] color = [Color.white];
			pixel = Frame(Texture2D.create(ColorFormat.rgba,
											 ColorType.ubyte_,
											 InternalFormat.rgba8,
											 1,1, cast(void[])color, Flag!"generateMipMaps".no ));
		}

		this.font	   = font;
		if(buffer)	
			this.buffer = buffer;
		else 
			this.buffer = new SpriteBuffer(512);
	}

	void mouseEventState(MouseEventState state) @property
	{
		this.mouseState = state;
	}

	void label(float4 rect, const (char)[] text = null) 
	{
		this.buffer.addText(font, text, float2(rect.x, rect.y), Color.black);
	}

	bool button(float4 rect, const (char)[] text = null, GUIProperty property = GUIProperty.defaultButton)
	{
		auto bColor = selectColor(rect, property);
		this.buffer.addFrame(pixel, rect, bColor);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7, rect.y + 7), Color.black);

		return wasPressed(rect);
	}

	bool repeatButton(float4 rect, const (char)[] text = null, GUIProperty property = GUIProperty.defaultButton)
	{
		auto bColor = selectColor(rect, property);
		this.buffer.addFrame(pixel, rect, bColor);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7, rect.y + 7), Color.black);


		ButtonState down = mouseState.down[MouseButton.left];
		return down.inState && pointInRect(rect, mouseState.newLoc) && pointInRect(rect, down.loc);
	}

	bool toggle(float4 rect, bool isChecked, const (char)[] text = null)
	{
		auto pressed = wasPressed(rect);
		isChecked	 = pressed ? !isChecked : isChecked;
		auto image   = isChecked ? checkBoxFrame : unCheckBoxFrame;

		this.buffer.addFrame(image, rect);
		if(text)
			this.buffer.addText(font, text, float2(rect.x + 7, rect.y + 7), Color.black);

		return wasPressed(rect);
	}

	float hslider(float4 rect, float value, float min = 0, float max = 100)
	{
		auto box			= Color(0xFF5577FF),
			  innerBox	= Color(0xFFFF7755);

		this.buffer.addFrame(pixel, float2(rect.x, rect.y), box, float2(rect.z, rect.w));

		value = setSliderValue(rect, mouseState.newLoc.x - rect.x, rect.z, value, min, max);
		float4 innerRect = 
				 float4(clamp(rect.x + rect.z * ((value - min) / (max - min)) - rect.w / 2, rect.x, rect.x + rect.z - rect.w),
						  rect.y,
						  rect.w,
						  rect.w);
		
		this.buffer.addFrame(pixel,  innerRect, innerBox);

		return value;
	}

	float vslider(float4 rect, float value, float min = 0, float max = 100)
	{
		auto box			= Color(0xFF5577FF),
			  innerBox	= Color(0xFFFF7755);

		this.buffer.addFrame(pixel, float2(rect.x, rect.y), box, float2(rect.z, rect.w));

		value = setSliderValue(rect, mouseState.newLoc.y - rect.y, rect.w, value, min, max);
		float4 innerRect = 
			float4(rect.x,
					 clamp(rect.y + rect.w * ((value - min) / (max - min)) - rect.z / 2, rect.y, rect.y + rect.w - rect.z),
					 rect.z,
					 rect.z);

		this.buffer.addFrame(pixel,  innerRect, innerBox);
		return value;
	}


	float setSliderValue(float4 rect, float pos, float width, float value, float min, float max)
	{
		if(mouseState.isDown(MouseButton.left))
		{
			ButtonState down = mouseState.down[MouseButton.left];
			if(pointInRect(rect, down.loc))
			{
				float tmp = pos;
				tmp /= width;
				tmp *= (max - min) + min;
				
				value = clamp(tmp, min, max);
			}
		}

		return value;
	}


	Color selectColor(float4 loc, GUIProperty property) 
	{
		ButtonState down = mouseState.down[MouseButton.left];
		if(mouseState.isDown(MouseButton.left))
		{
			if(pointInRect(loc, down.loc)) 
			{
				return property.activeColor0;
			}
		} 
		else if(pointInRect(loc, mouseState.newLoc))
		{
			return property.focusColor0;
		}

		return property.normalColor0;
	}

	public void draw(ref mat4 transform)
	{
		gl.sampler[0] = sampler;
		this.buffer.flush();
		this.buffer.draw(transform);
		this.buffer.clear();
	}


	private bool wasPressed(float4 rect) 
	{
		if(mouseState.wasPressed(MouseButton.left))
		{
			ButtonState up   = mouseState.up[MouseButton.left];
			ButtonState down = mouseState.down[MouseButton.left];

			return pointInRect(rect, up.loc) 
				&&  pointInRect(rect, down.loc);
		}
		return false;
	}

	private bool pointInRect(float4 rect, float2 point) 
	{
		return rect.x < point.x && rect.x + rect.z > point.x &&
				 rect.y < point.y && rect.y + rect.w > point.y;
	}
}