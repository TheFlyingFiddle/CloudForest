module ui.common;

public import graphics.color;
public import frame;
public import font;
public import input;
public import math.rect;
public import ui.renderer;

struct ControlState
{
	bool hover;
	bool focus;
	bool press;
}

struct ColoredFrame
{
	Color color;
	Frame frame;

}

struct TextStyle
{
	Color color;
	Font  font;
}

interface IControl
{
	void render(Rect bounds, Rect area, ControlState state, IGUIRenderer renderer);
}

interface IKeyboardUser
{
	bool consumesFocus();
	void keyDown(Key key);
	void keyUp(Key key);
}

Rect paddedArea(Rect area, Rect padding)
{
	return Rect(area.x + padding.x,
					area.y + padding.y,
					area.w - padding.x - padding.w,
					area.h - padding.y - padding.h);
}

Rect subArea(Rect area, Rect areaPercent)
{
	return Rect(area.x + area.w * areaPercent.x,
					area.y + area.h * areaPercent.y,
					area.w * areaPercent.w,
					area.h * areaPercent.h);
}


mixin template GUIComponent(Settings, Style) 
{
	Settings[]     settings;
	Style[]	      style;

	void add(Settings settings, Style style)
	{
		this.settings ~= settings;
		this.style    ~= style;
	}

	void remove(size_t index)
	{
		import std.algorithm;
		swap(settings, index, settings.last);
		swap(style, index, style.last);

		settings.length--;
		style.length--;
	}

	void processEvents(ControlState[] nState,
							 ControlState[] oState)
	{
		foreach(index; 0 .. nState.length)
			processEventItem(nState[index], 
								  oState[index],
								  settings[index]);
	}

	void render(Rect bounds, IGUIRenderer renderer)
	{
		foreach(index; 0 .. area.length)
			renderItem(bounds, 
						  area[index],
						  state[index],
						  renderer,
						  settings[index],
						  style[index]);
	}
}