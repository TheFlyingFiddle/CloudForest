module gui;

import graphics.texture;
import graphics.enums;
import SpriteBuffer;
import font;
import math.vector;
import frame;
import graphics.context;
import graphics.color;
import std.traits;
import math.matrix;
import math.helper;
import std.conv;
import input;
import window;


struct TintedFrame
{
	Frame frame;
	Color color;

	alias frame this;
}

class ButtonStyle
{
	TintedFrame down;
	TintedFrame normal;
	TintedFrame highlight;

	Color textColor;
	Font font;
	float4 textPadding;

	float4 iconDim;
	Color	 iconColor;

	float4 iconRect(float4 rect) 
	{
		return float4(rect.x + rect.w * iconDim.x,
						  rect.y + rect.w * iconDim.y,
						  rect.z * iconDim.z,
						  rect.w * iconDim.w);
	}

}

class ToggleStyle
{
	Frame toggleFrame;
	Frame untoggleFrame;

	Color color;
	Color textColor;
	Font font;
	
	float4 textPadding;

	Frame frame(bool isToggled)
	{		
		return isToggled ? toggleFrame : untoggleFrame;
	}	
}

class TextfieldStyle
{
	TintedFrame background;
	TintedFrame	cursor;

	Color textColor;
	Font  font;

	float4 textPadding;
}	

class SliderStyle
{
	TintedFrame active;
	TintedFrame inactive;
	TintedFrame normal;
	TintedFrame highlight;
}

class LabelStyle
{
	Font font;
	Color textColor;
}

class ListboxStyle
{
	Font font;
	Color textColor;

	TintedFrame background;
	TintedFrame stripe0;
	TintedFrame stripe1;
	TintedFrame selected;

	float4 textPadding;

	float  sliderSize;
	SliderStyle slider;
}

struct GUIStyle
{
	ButtonStyle		 button;
	ButtonStyle		 toolbar;
	ToggleStyle		 toggle;
	TextfieldStyle  textfield;
	SliderStyle		 vslider;
	SliderStyle		 hslider;
	LabelStyle		 label;
	ListboxStyle	 listbox;
	
	this(ButtonStyle    button, 
		  ButtonStyle    toolbar,
		  ToggleStyle    toggle,
		  TextfieldStyle textfield,
		  SliderStyle	  vslider,
		  SliderStyle	  hslider,
		  LabelStyle	  label,
		  ListboxStyle	  listbox)
	{
		this.button    = button;
		this.toolbar   = toolbar;
		this.toggle		= toggle;
		this.textfield	= textfield;
		this.vslider	= vslider;
		this.hslider	= hslider;
		this.label		= label;
		this.listbox   = listbox;
	}
}

struct TextEditor
{
	char[] text;
	uint2 cursor;
	uint2 selectedRange;

	bool hasSelection()
	{
		return this.selectedRange.y - this.selectedRange.x > 0;
	}

	char[] selectedText(char[] text)
	{
		import utils.string;
		return text[text.toUTFindex(selectedRange.x) .. text.toUTFindex(selectedRange.y)];
	}

	void select(Font font, in char[] text, float2 oldPos, float2 newPos, float2 offset)
	{
		int oldIndex = messureUntil(font, text, oldPos.x - offset.x);
		int newIndex	= messureUntil(font, text, newPos.x - offset.x); 

		selectedRange = uint2(min(oldIndex, newIndex), max(oldIndex, newIndex));
		cursor.x = newIndex;
	}

	private void remove()
	{
		import utils.string;
		if(hasSelection) {
			text.remove(selectedRange);
			cursor.x = selectedRange.x;
		} else { 
			text.remove(cursor.x);
		}

		selectedRange = cursor.xx;
	}


	private void insert(string toInsert)
	{
		import utils.string;
		if(hasSelection) {
			text.remove(selectedRange);
			cursor.x = selectedRange.x;
		}

		text.insert(toInsert, cursor.x);
		cursor.x += count(toInsert);

		selectedRange = cursor.xx;
	}

	private void moveLeft(KeyboardEventState keyInput)
	{
		cursor.x = clamp!int(cursor.x - 1, 0, cursor.x);
		if(keyInput.modifier == KeyModifier.shift) {
			if(cursor.x + 1 == selectedRange.x) {
				selectedRange.x--;
			} else if(cursor.x + 1 == selectedRange.y) {
				selectedRange.y--;
			}
		} else {
			selectedRange = cursor.xx;
		}
	}

	private void moveRight(KeyboardEventState keyInput)
	{
		import utils.string;
		cursor.x = clamp!int(cursor.x + 1, 0, text.count);		
		if(keyInput.modifier == KeyModifier.shift) {
			if(cursor.x - 1 == selectedRange.y) {
				selectedRange.y++;
			} else if(cursor.x - 1 == selectedRange.x) {
				selectedRange.x++;
			}
		} else {
			selectedRange = cursor.xx;
		}
	}

	private void selectAll()
	{
		import utils.string;
		selectedRange = uint2(0, text.count);
		cursor.x  = selectedRange.y;
	}

	private bool editText(ref char[] text, KeyboardEventState keyInput, Clipboard clipboard)
	{
		cursor.x = clamp(cursor.x, 0u, text.count);

		this.text = text;
		bool changed = false;
		if(hasText(keyInput)) 
		{
			insert(keyInput.charInput);
			changed = true;
		} 
		else if(hasDelete(keyInput, text))
		{
			remove();
			changed = true;
		} 
		else if(hasMoveLeft(keyInput)) 
		{
			moveLeft(keyInput);
		} 
		else if(hasMoveRight(keyInput)) 
		{
			moveRight(keyInput);
		} 
		else if(hasSelectAll(keyInput))
		{
			selectAll();
		} 
		else if(hasCopy(keyInput))
		{
			clipboard.text = selectedText(text);
		} 
		else if(hasPaste(keyInput))
		{
			insert(clipboard.text);
			changed = true;
		} 

		text = this.text;
		return changed;
	}

	private bool hasDelete(KeyboardEventState state, in char[] text)
	{
		if(state.wasPressed(Key.backspace) && (cursor.x > 0 || hasSelection)) {
			cursor.x--;
			return true;
		} 	else if(state.wasPressed(Key.delete_) && (text.count > cursor.x || hasSelection)) {
			return true;
		}

		return false;
	}

	private bool hasMoveLeft(KeyboardEventState state)
	{
		return state.wasPressed(Key.left);
	}

	private bool hasMoveRight(KeyboardEventState state)
	{
		return state.wasPressed(Key.right);
	}

	private bool hasSelectAll(KeyboardEventState state)
	{
		return state.wasPressed(Key.A) && state.modifier == KeyModifier.control;
	}

	private bool hasCopy(KeyboardEventState state)
	{
		return state.wasPressed(Key.C) && state.modifier == KeyModifier.control;
	}

	private bool hasPaste(KeyboardEventState state)
	{
		return state.wasPressed(Key.V) && state.modifier == KeyModifier.control;
	}

	private bool hasText(KeyboardEventState state)
	{
		return state.charInput.length > 0;
	}

	private uint messureUntil(Font font, in char[] toMessure, float maxWidth)
	{
		float2 cursor = float2.zero;
		size_t i = 0;
		foreach(wchar c; toMessure) 
		{
			auto cc = cursor;
			if(c == '\n') {
				cursor.y -= font.lineHeight;
				cursor.x = 0;
				continue;
			} else if(c == '\t') {
				CharInfo spaceInfo = font[' '];
				cursor.x += spaceInfo.advance * font.tabSpaceCount;
				continue;
			}

			CharInfo info = font[c];
			cursor.x += (info.advance);

			if(cursor.x >= maxWidth)
				return i;

			i++;
		}

		return i;
	}
}
				
class GUI
{
	private static Sampler	sampler;
	private GUIStyle			styles;

	private SpriteBuffer		buffer;

	private MouseEventState		mouseState;
	private KeyboardEventState keyState;
	private Clipboard				clipboard;

	float4 bounds;

	uint focus = -1;
	uint numControl = 0;

	TextEditor editor;

	this(GUIStyle styles, MouseEventState mouseState, 
		  KeyboardEventState keyState, Clipboard clipboard, 
		  float4 bounds, SpriteBuffer buffer = null)
	{
		this.mouseState = mouseState;
		this.keyState   = keyState;
		this.clipboard  = clipboard;
		this.bounds		 = bounds;
		this.editor     = TextEditor(null, uint2.zero, uint2.zero);

		this.styles = styles;
		if(buffer)	
			this.buffer		   = buffer;
		else 
			this.buffer = new SpriteBuffer(512);

		sampler = new Sampler();
		sampler.minFilter = TextureMinFilter.nearest;
		sampler.magFilter = TextureMagFilter.nearest;
	}

	void label(float4 rect, const (char)[] text, LabelStyle style = null) 
	{
		style = selectStyle(style, this.styles.label);
		addText(style.font, text, rect, float4.zero, style.textColor);
	}

	bool button(float4 rect, const (char)[] text = null, 
					Frame icon = Frame.init, ButtonStyle style = null)
	{
		handleButton(rect, text, icon, style);
		return wasPressed(rect);
	}

	bool repeatButton(float4 rect, const (char)[] text = null, 
							Frame icon = Frame.init, ButtonStyle style = null)
	{
		handleButton(rect, text, icon, style);
		return isPressed(rect);
	}

	void handleButton(float4 rect, const (char)[] text = null, 
							Frame icon = Frame.init, ButtonStyle style = null)
	{
		style = selectStyle(style, this.styles.button);

		TintedFrame frame;
		if(isFocused() || isHover(rect)) {
			frame = style.highlight;
		} else if(isPressed(rect)) {
			frame = style.down;
		} else {
			frame = style.normal;
		}
		
		addFrame(frame, rect);

		if(icon.texture) 
			addFrame(TintedFrame(icon, style.iconColor), style.iconRect(rect));

		if(text)
			addText(style.font, text, rect, style.textPadding, style.textColor);

		handleFocus(rect);
	}


	bool toggle(float4 rect, ref bool isChecked, const (char)[] text = null, ToggleStyle style = null)
	{
		bool old = isChecked;
		style = selectStyle(style, this.styles.toggle);

		auto pressed = wasPressed(rect);
		isChecked	 = pressed ? !isChecked : isChecked;

		float4 buttonRect = rect.xyww;
		addFrame(TintedFrame(style.frame(isChecked), style.color), buttonRect);

		if(text)
			addText(style.font, text, rect + float4(buttonRect.z, 0,0,0), 
					  style.textPadding, style.textColor);

		handleFocus(rect);
		return old != isChecked;
	}


	bool vector2Field(T)(float4 rect, ref Vector2!(T) vec, 
							  TextfieldStyle style = null) if(isNumeric!T)
	{
		auto old = vec;
		numberField!T(float4(rect.xy, rect.z / 2 - 3, rect.w), vec.x, style);
		numberField!T(float4(rect.x + rect.z / 2 + 3, rect.y, rect.z / 2 - 3, rect.w), vec.y, style);
		return old != vec;
	}

	bool vector3Field(T)(float4 rect, ref Vector3!(T) vec, 
								TextfieldStyle style = null) if(isNumeric!T)
	{
		float space = rect.z / 15;

		auto old = vec;
		numberField!T(float4(rect.xy, rect.z / 3 - space / 3, rect.w), vec.x, style);
		numberField!T(float4(rect.x + rect.z / 3 + space / 6, rect.y, (rect.z / 3) - space / 3 , rect.w), vec.y, style);
		numberField!T(float4(rect.x + (rect.z / 3) * 2 + space / 3, rect.y, (rect.z / 3) - space / 3, rect.w), vec.z, style);
		return old != vec;
	}

	bool vector4Field(T)(float4 rect, ref Vector4!(T) vec,
								TextfieldStyle style = null)
	{
		auto old = vec;
		numberField!T(float4(rect.xy, rect.z / 4 - 6, rect.w), vec.x, style);
		numberField!T(float4(rect.x + rect.z / 4 + 2, rect.y, (rect.z / 4) - 6 , rect.w), vec.y, style);
		numberField!T(float4(rect.x + (rect.z / 4) * 2 + 4, rect.y, (rect.z / 4) - 6, rect.w), vec.z, style);
		numberField!T(float4(rect.x + (rect.z / 4) * 3 + 6, rect.y, (rect.z / 4) - 6, rect.w), vec.w, style);
		return old != vec;
	}

	

	char[] numberText;
	int fIndex = 0;
	bool numberField(T)(float4 rect, ref T number, TextfieldStyle style = null)
	{
		T old = number;
		if(isFocused && fIndex != focus)
		{
			if(approxEqual(0, number)) {
				numberText = new char[0];
			} else {
				numberText = to!(char[])(number);
			}
			fIndex = focus;
			editor.selectedRange = uint2(0, numberText.length);
		} 

		if(!isFocused) {
			char[] text = to!(char[])(number);
			textField(rect, text, style);
		} else {
			uint oldLength = numberText.length;
			if(textField(rect, numberText, style))
			{
				try {
					number = to!T(numberText);
				} catch(Exception e) {
					adjustNumberString!T(numberText, oldLength);					
					number = 0;
				}
			}
		}

		return old != number;
	}

	void adjustNumberString(T)(ref char[] numberText, uint oldLength)
	{
		if(numberText.length < oldLength)
			return;

		auto toRemove = numberText[oldLength .. $];
		char prevChar = (numberText.length > 1) ? numberText[$ - toRemove.length - 1] : ' ';
		static if(isFloatingPoint!T) {
			if(toRemove == "e")
			{
				if(toRemove.length == numberText.length || prevChar == 'e' 
					|| prevChar == '-' || prevChar == '+' ) {
						numberText = numberText[0 .. oldLength];
					}
			} else if(toRemove == "-" || toRemove == "+") {
				if(toRemove.length != numberText.length && prevChar != 'e') {
					numberText = numberText[0 .. oldLength];
				}
			} else {
				numberText = numberText[0 .. oldLength];
			}					
		} else {
			if(toRemove != "-" || toRemove != "+") 
				numberText = numberText[0 .. oldLength];
		}
	}

	bool textField(float4 rect, ref char[] text, TextfieldStyle style = null)
	{
		import std.utf;

		bool changed = false;
		style = selectStyle(style, this.styles.textfield);

		if(mouseDownIn(rect)) 
		{
			editor.select(style.font, text, 
							  mouseState.down[MouseButton.left].loc, 
							  mouseState.newLoc, rect.xy);
			focus = numControl;
		}

		if(isFocused) 
		{
			changed = editor.editText(text, keyState, clipboard);

			float pos = style.font.messureString(text[0 ..  text.toUTFindex(editor.cursor.x)]).x + style.textPadding.x;

			addFrame(style.background, rect);
			if(editor.hasSelection)
			{
				float start  = style.font.messureString(text[0 .. text.toUTFindex(editor.selectedRange.x)]).x + rect.x + style.textPadding.x;
				float size   = style.font.messureString(text[text.toUTFindex(editor.selectedRange.x) .. text.toUTFindex(editor.selectedRange.y)]).x;

				if(pos >= rect.z - style.textPadding.z)
					start += rect.z - pos - style.textPadding.z;
	
						
				addFrame(TintedFrame(style.cursor.frame, Color(0x3900FF00)), 
							intersection(float4(start, rect.y, size, rect.y), shrink(rect, style.textPadding))); 
			} 


			if(pos >= rect.z - style.textPadding.z)
				addText(style.font, text, float4(rect.x - pos + rect.z - style.textPadding.z, rect.y, rect.z, rect.w), rect, style.textPadding, style.textColor);
			else 
				addText(style.font, text, rect, style.textPadding, style.textColor);


			pos = clamp(pos, style.textPadding.x, rect.z - style.textPadding.z);
			addFrame(style.cursor, float4(pos + rect.x, rect.y + style.textPadding.y, 1, rect.w - style.textPadding.y - style.textPadding.z));
		} 
		else 
		{
			addFrame(style.background, rect);
			addText(style.font, text, rect, style.textPadding, style.textColor);
		}

		numControl++;
		return changed;
	}



	bool toolbar(float4 rect, ref uint selected, string[] tools, ButtonStyle style = null)
	{
		uint old = selected;
		style = selectStyle(style, this.styles.toolbar);

		uint spacing = 4;

		foreach(i, tool;tools)
		{
			TintedFrame frame;
			if(i == selected) {
				frame = style.down;
			} else if(isHover(rect))  {
				frame = style.highlight;
			} else {
				frame = style.normal;
			}

			addFrame(frame, rect);
			addText(style.font, tool, rect, style.textPadding, style.textColor);


			if(wasPressed(rect)) {
				selected = i;
			}

			handleFocus(rect);
			rect.x += rect.z + spacing;
		}
		

		return old != selected;
	}

	bool hslider(float4 rect, ref float value, float min = 0, float max = 100, SliderStyle style = null)
	{
		float old = value;
		style = selectStyle(style, this.styles.hslider);

		addFrame(style.active, rect);

		value = setSliderValue(rect, mouseState.newLoc.x - rect.x - bounds.x, rect.z, value, min, max);
		float4 innerRect = 
				 float4(clamp(rect.x + rect.z * ((value - min) / (max - min)) - rect.w / 2, rect.x, rect.x + rect.z - rect.w),
						  rect.y,
						  rect.w,
						  rect.w);
		
		if(isHover(innerRect) || mouseDownIn(rect)) {
			addFrame(style.highlight,  innerRect);
		} else {
			addFrame(style.normal,  innerRect);
		}

		handleFocus(rect);
		return !std.math.approxEqual(old,value);
	}

	bool vslider(float4 rect, ref float value, float min = 0, float max = 100, SliderStyle style = null)
	{
		float old = value;
		style = selectStyle(style, this.styles.vslider);

		addFrame(style.active, rect);

		value = setSliderValue(rect, mouseState.newLoc.y - rect.y - bounds.y, rect.w, value, min, max);
		float4 innerRect = 
			float4(rect.x,
					 clamp(rect.y + rect.w * ((value - min) / (max - min)) - rect.z / 2, rect.y, rect.y + rect.w - rect.z),
					 rect.z,
					 rect.z);

		if(isHover(innerRect) || mouseDownIn(rect)) {
			addFrame(style.highlight,  innerRect);
		} else {
			addFrame(style.normal,  innerRect);
		}

		handleFocus(rect);
		return !std.math.approxEqual(old,value);
	}

	bool listbox(float4 rect, ref uint selected, ref float offset, string[] items, ListboxStyle style = null)
	{
		uint old = selected;
		style = selectStyle(style, this.styles.listbox);


		float4 outerRect = rect;
		bool pressed = wasPressed(rect);
		bool sliderDisplayed = items.length * style.font.size > rect.w;
		float sliderMax = items.length * style.font.size - rect.w;
		addFrame(style.background, outerRect);

		if(sliderDisplayed) 
		{
			outerRect.z -= style.sliderSize;
			float off = sliderMax - offset;
			vslider(float4(rect.x + rect.z - style.sliderSize,
									  rect.y, style.sliderSize, rect.w), 
							off, 0, sliderMax);
			offset = sliderMax - off;
		}

		foreach(i, item; items)
		{
			float4 itemRect = float4(rect.x, rect.w + rect.y + offset - style.font.size, rect.z, style.font.size);
			if(sliderDisplayed)
				itemRect.z -= style.sliderSize;

			
			TintedFrame frame = (i % 2 == 0) ? style.stripe0 : style.stripe1;	
			if(i == selected)
				frame = style.selected;

			addFrame(frame, intersection(itemRect, outerRect));
			addText(style.font, item, itemRect, outerRect, style.textPadding, style.textColor);

			if(pressed && wasPressed(itemRect))
			{
				selected = i;
			}


			rect.y -= itemRect.w;
		}

		return old != selected;
	}

	public void draw(ref mat4 transform)
	{
		gl.sampler[0] = sampler;
		this.buffer.flush();
		this.buffer.draw(transform);
		this.buffer.clear();

		this.numControl = 0;
	}

	private void addFrame(TintedFrame frame, float4 rect)
	{
		rect.xy = bounds.xy + rect.xy;
		this.buffer.addFrame(frame, rect, bounds, frame.color);
	}


	private void addText(T)(Font font, const (T)[] text, float4 rect, float4 padding, Color color)
	{
	   auto paddedRect =  float4(rect.xy + padding.xy,
										  rect.zw - padding.xy - padding.zw);

		paddedRect.xy = bounds.xy + paddedRect.xy;
		paddedRect = intersection(this.bounds, paddedRect);


		this.buffer.addText(font, text, paddedRect.xy, paddedRect, color);
	}

	private void addText(T)(Font font, const (T)[] text, float4 rect, float4 bounds, float4 padding, Color color)
	{
		auto paddedBounds =  float4(bounds.xy + padding.xy,
											 bounds.zw - padding.xy - padding.zw);

		paddedBounds.xy = this.bounds.xy + paddedBounds.xy;
		paddedBounds = intersection(this.bounds, paddedBounds);

		this.buffer.addText(font, text, rect.xy + this.bounds.xy + padding.xy, paddedBounds, color);
	}

	private float setSliderValue(float4 rect, float pos, float width, float value, float min, float max)
	{
		if(mouseDownIn(rect))
		{
			float tmp = pos;
			tmp /= width;
			tmp *= (max - min) + min;

			value = clamp(tmp, min, max);
		}
		return value;
	}


	private void handleFocus(float4 rect)
	{
		focus = wasPressed(rect) ? numControl : focus;
		numControl++;
	}

	private bool isFocused()
	{
		return focus == numControl;
	}

	private bool isHover(float4 rect)
	{
		return pointInRect(rect, mouseState.newLoc);
	}

	private T selectStyle(T)(T style0, T style1)
	{
		return (style0) ? style0 : style1;
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

	private bool isPressed(float4 rect)
	{
		return mouseDownIn(rect) && isHover(rect);
	}

	private bool mouseDownIn(float4 rect) 
	{
		return mouseState.down[MouseButton.left].inState && 
				 pointInRect(rect, mouseState.down[MouseButton.left].loc);
	}

	private bool pointInRect(float4 rect, float2 point) 
	{
		rect.xy = bounds.xy + rect.xy;
		rect = intersection(rect, bounds);
		return rect.x < point.x && rect.x + rect.z > point.x &&
				 rect.y < point.y && rect.y + rect.w > point.y;
	}

	private float4 shrink(float4 rect, float4 padding)
	{
		return float4(rect.xy + padding.xy, 
						  rect.zw - padding.xy - padding.zw);
	}

	private float4 intersection(float4 rect0, float4 rect1)
	{
		auto x = fmax(rect0.x, rect1.x);
		auto y = fmax(rect0.y, rect1.y);
		auto width = fmin(rect0.x + rect0.z, rect1.x + rect1.z) - x;
		auto height = fmin(rect0.y + rect0.w, rect1.y + rect1.w) - y;

		if(width < 0 || height < 0)
			return float4.zero;

		return float4(x,y,width,height);
	}
}