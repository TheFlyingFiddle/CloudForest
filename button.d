module ui.button;
import ui.common;

struct ButtonSettings
{
	string			 text;
	ColoredFrame    icon;
}

struct ButtonStyle
{
	ColoredFrame normal;
	ColoredFrame hover;
	ColoredFrame focused;
	ColoredFrame pressed;
	Rect			 iconSubArea;
	TextStyle	 textStyle;
}

class Button : IControl
{	
	ButtonSettings settings;
	ButtonStyle	   style;

	this(ButtonSettings settings,
		  ButtonStyle style)
	{
		this.settings = settings;
		this.style	  = style;
	}

	auto selectFrame(ControlState cState, ButtonStyle style)
	{
		if(cState.press && cState.hover)
			return style.pressed;
		if(cState.hover)
			return style.hover;
		if(cState.focus)
			return style.focused;
		return style.normal;
	}

	void render(Rect bounds, 
					Rect area, 
					ControlState state,
					IGUIRenderer renderer)
	{
		auto frame = selectFrame(state, style);		
		renderer.addFrame(bounds, area, frame);
		if(settings.icon != ColoredFrame.init)
			renderer.addFrame(bounds, area.subArea(style.iconSubArea), settings.icon);

		renderer.addText(bounds, area, style.textStyle, settings.text);
	}
}