module cloudy;


import graphics.all;
import SpriteBuffer;
import font, frame;
import math.rect, math.vector, math.helper;
import input, window;
import guiRenderer;


struct TextStyle
{
	Rect padding;
	Color color;
	Font font;
}

struct ControlState
{
	bool focused;
	bool hover;
	bool mouseDownIn;

	bool pressed()
	{
		return mouseDownIn && hover;
	}
}


final class ButtonStyle
{
	ColoredFrame pressed;
	ColoredFrame focused;
	ColoredFrame hover;
	ColoredFrame idle;

	TextStyle textStyle;

	Rect iconRect;	
	Color iconColor;

	Rect calcIconRect(Rect buttonBounds)
	{
		return Rect(rect.x + rect.w * iconDim.x,
						rect.y + rect.h * iconDim.h,
						rect.w * iconDim.w,
						rect.h * iconDim.h);
	}

	void draw(ControlState state, Rect rect, Rect bounds, Frame icon, const char[] text, IGUIRenderer guiRenderer)
	{
		ColoredFrame toDraw;

		if(state.pressed) {
			toDraw = pressed;
		} else if(state.focused) {
			toDraw = focused;
		} else if(state.hover) {
			toDraw = hover;
		} else {
			toDraw = idle;
		}

		guiRenderer.addFrame(toDraw, rect, bounds);
		guiRenderer.addText (textStyle, rect, bounds);

		if(icon.texture) {
			Rect iconRect = this.calcIconRect(rect);
			guiRenderer(ColoredFrame(icon, iconColor), iconRect, bounds);
		}
	}
}

final class ToggleStyle
{
	ColoredFrame toggle;
	ColoredFrame untoggle;
	TextStyle style;

	void draw(Rect rect, Rect bounds, const char[] text, bool toggled, IGUIRenderer guiRenderer)
	{
		Rect toggleButtonRect = Rect(rect.x, rect.y, rect.h, rect.h);
		Rect textRect			 = Rect(rect.x + rect.w, rect.w - rect.h, rect.h);
		ColoredFrame frame = toggled ? toggle : untoggle;

		guiRenderer.addFrame(frame, toggleButtonRect, bounds);
		guiRenderer.addText(textStyle, text, textRect, bounds);
	}
}

final class SliderStyle
{
	ColoredFrame active;
	ColoredFrame inactive;
	ColoredFrame idle;
	ColoredFrame highlight;

	Rect calcButtonRect(bool vertical, Rect rect)
	{
		if(vertical) 
			return Rect(rect.x, 
					    clamp(rect.y + rect.h * value - rect.w / 2, rect.bottom, rect.top - rect.w / 2),
					    rect.w, rect.w);
		else 
			return Rect(clamp(rect.x * rect.w * value - rect.h / 2, rect.left, rect.right - rect.w / 2),
							rect.y, rect.w, rect.w);
	}

	Rect calcActiveRect(bool vertical, Rect buttonRect, Rect rect)
	{
		if(vertical)
			return activeRect = Rect(rect.x, rect,y, rect.w, buttonRect.y - rect.y);
		else  
			return activeRect = Rect(rect.x, rect.y, buttonRect.left - rect.left, rect.h);
	}

	Rect calcInactiveRect(bool vertical, Rect buttonRect, Rect rect)
	{
		if(vertical)
			return Rect(rect.x, buttonRect.y, rect.w, rect.top - buttonRect.bottom);
		else 
			return Rect(buttonRect.x, rect.y, rect.right - buttonRect.left, rect.h);
	}	

	void draw(ControlState state, Rect rect, Rect bounds, float value, bool vertical,  IGUIRenderer guiRenderer)
	{
		Rect buttonRect   = calcButtonRect(vertical, rect);
		Rect activeRect	= calcActiveRect(vertical, buttonRect, rect);
		Rect inactiveRect = calcInactiveRect(vertical, buttonRect, rect);

		ColoredFrame buttonFrame = (state.mouseDownIn || state.hover) ? highlight : idle;

		guiRenderer.addFrame(active, activeRect, bounds);
		guiRenderer.addFrame(inactive, inactiveRect, bounds);
		guiRenderer.addFrame(buttonFrame, buttonRect, bounds);
	}
}

final class Textfield
{
	ColoredFrame background;
	ColoredFrame cursor;

	Color selectColor;
	Color selectedTextColor;
	TextStyle textStyle;

	void draw(ControlState state, Rect rect, const char[] text, uint2 selectedRange, uint cursor, IGUIRenderer guiRenderer)
	{
		if(selectedRange.x != selectedRange.y)
			drawSelected(rect, text, selectedRange, cursor, guiRenderer);
		else if(state.focused)
			drawFocused(rect, text, cursor, guiRenderer);
		else 
			drawIdle(rect, text, guiRenderer);
	}

	void drawSelected(Rect rect, const char[] text, uint2 selectedRange, uint cursor, IGUIRenderer renderer)
	{
		renderer.addFrame(background, rect);
		
		uint startIndex = text.toUTFindex(selectedRange.x);
		uint endIndex   = text.toUTFindex(selectedRange.y);

		float start = textStyle.font.messureString(text[0 .. startIndex]).x + rect.x + textStyle.padding.x;
		float size  = textStyle.font.messureString(text[startIndex .. endIndex]).x;


	}
}

final class Cloudy
{




}