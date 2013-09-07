module ui.pannel;

import ui.common;
import ui.renderer;


class Pannel : IControl
{
	ColoredFrame bg;

	this(ColoredFrame bg)
	{
		this.bg = bg;
	}

	void stateChange(ControlState o, ControlState n)
	{
		//Do nothing. Since i have atleas 1 occurance of this stateChange will hencefourth be 
		//Removed!!)!_!+_)E# o=0oq2-=0-= omg omgomgom
	}

	void render(Rect bounds, Rect area, ControlState state, IGUIRenderer renderer)
	{
		renderer.addFrame(bounds, area, bg);
	}
}