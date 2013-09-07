module ui.renderer;

import ui.common;
import SpriteBuffer;


interface IGUIRenderer
{
	void addFrame(Rect bounds, Rect area, ColoredFrame frame);
	void addText(Rect bounds, Rect area, TextStyle style, const char[] text);
	void render(ref math.matrix.Matrix4 matrix);
}


class GUIRenderer : IGUIRenderer
{
	SpriteBuffer buffer;

	this(SpriteBuffer buffer = null) 
	{
		if(!buffer)
			buffer = new SpriteBuffer(512);
			
		this.buffer = buffer;
	}

	void addFrame(Rect bounds, Rect area, ColoredFrame frame)
	{
		buffer.addFrame(frame.frame, area, bounds, frame.color);
	}

	void addText(Rect bounds, Rect area, TextStyle style, const char[] text)
	{
		buffer.addText(style.font, text, area.bottomLeft, 
							Rect.intersection(bounds, area), style.color);
	}

	void render(ref math.matrix.Matrix4 matrix)
	{
		buffer.flush();
		buffer.draw(matrix);
		buffer.clear();
	}
}