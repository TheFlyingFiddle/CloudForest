module ui.gui;

import ui.common;
import math.vector;
import input;

class GUI
{
	struct Controls
	{
		ubyte count;

		//Rarely changed data.
		Rect[]	    areas;
		ubyte[]	    parents;
		float2[]     offsets;
		bool[]		 enabled;
		bool[]		 visible;
		IControl[]	 controls;

		//Frequently updated data.
		Rect[]		globalAreas;
		Rect[]		intersections;

		this(Rect area)
		{
			count = 0;
			areas.length    = ubyte.max + 1;
			parents.length  = ubyte.max + 1;
			offsets.length  = ubyte.max + 1;
			enabled.length  = ubyte.max + 1;
			visible.length  = ubyte.max + 1;
			controls.length = ubyte.max + 1; 

			globalAreas.length   = ubyte.max + 1;
			intersections.length = ubyte.max + 1;

			add(null, area, 0, float2.zero, false, false);
			
			globalAreas[0]	= area;
			intersections[0] = area;
		}

		void calculateGlobalTransforms()
		{
			foreach(i; 1 .. count)
			{
				int p = parents[i];
				Rect parent   = globalAreas[parents[i]];
				Rect child    = areas[i];
				float2 offset = offsets[parents[i]];

				child.x += parent.x + offset.x;
				child.y += parent.y + offset.y;

				globalAreas[i] = child;
				intersections[i] = Rect.intersection(parent, child);
			}
		}

		auto add(IControl control, Rect area, ubyte parent, float2 offset = float2.zero, bool enabled = true, bool visible = true)
		{
			this.areas[count]   = area;
			this.parents[count] = parent;
			this.offsets[count] = offset;
			this.enabled[count] = enabled;
			this.visible[count] = visible;
			this.controls[count] = control;

			return count++;
		}

		void remove(ubyte index) 
		{
			import std.algorithm;
			auto toRemove = branch(index);
			foreach(i; std.range.retro(toRemove)) {
				areas.remove(i);
				parents.remove(i);
				offsets.remove(i);
				enabled.remove(i);
				visible.remove(i);
			}

			--this.count;
		}

		ubyte[] branch(ubyte root)
		{
			ubyte[] c;
			auto app = std.array.appender!(ubyte[])(c);
			app.put(root);

			foreach(i; root  .. parents.length) {
				for(size_t j = 0; j < c.length; j++) {
					ubyte parentIndex = c[j];
					if(parents[i] == parentIndex) {
						app.put(cast(ubyte)i);
						break;
					}
				}
			}
	
			return c;
		}
	}

	void setFocusIndex(size_t component, size_t index)
	{
		int item = std.algorithm.countUntil(focusQue, component);
		focusQue = std.algorithm.remove(focusQue, item);
		std.array.insertInPlace(focusQue, index, component);
	}

	int focus;
	int[] focusQue;

	Controls				  controls;

	IGUIRenderer		  renderer;
	MouseEventState     mouse;
	KeyboardEventState  keyboard;


	this(IGUIRenderer renderer, Rect bounds, MouseEventState mouse, KeyboardEventState keyboard)
	{
		controls				= Controls(bounds);
		this.mouse			= mouse;
		this.keyboard		= keyboard;
		this.renderer		= renderer;

		this.focus = 0;

	}

	void delegate()[ubyte] clicks;
	void click(ubyte id, void delegate() toCall)
	{
		clicks[id] = toCall;
	}

	void clickTest(ubyte id, Rect area) 
	{
		auto p = id in clicks;
		if(p) 
		{
			if(mouse.wasPressed(MouseButton.left) &&
				area.intersects(mouse.newLoc)   &&
				area.intersects(mouse.down[MouseButton.left].loc)) {
					(*p)();
			} else if(focusQue[focus] == id && keyboard.wasPressed(Key.enter))
				(*p)();
		}
	}

	void delegate()[ubyte] mouseEnters;
	void mouseEnter(ubyte id, void delegate() toCall)
	{
		mouseEnters[id] = toCall;	
	}

	void mouseEnterTest(ubyte id, Rect area)
	{
		auto p = id in mouseEnters;
		if(p) 
			if(area.intersects(mouse.newLoc) &&
				!area.intersects(mouse.oldLoc)) {
				(*p)();
			}
	}

	void delegate()[ubyte] mouseExits;
	void mouseExit(ubyte id, void delegate() toCall)
	{
		mouseExits[id] = toCall;	
	}

	void mouseExitTest(ubyte id, Rect area)
	{
		auto p = id in mouseExits;
		if(p) 
			if(!area.intersects(mouse.newLoc) &&
				area.intersects(mouse.oldLoc)) {
					(*p)();
				}
	}

	void delegate()[ubyte] mouseStays;
	void mouseStay(ubyte id, void delegate() toCall)
	{
		mouseStays[id] = toCall;	
	}

	void mouseStayTest(ubyte id, Rect area)
	{
		auto p = id in mouseStays;
		if(p) 
			if(area.intersects(mouse.newLoc) &&
				area.intersects(mouse.oldLoc)) {
					(*p)();
				}
	}

	void delegate(Key key)[ubyte] keyPresses;
	void keyPress(ubyte id, void delegate(Key) toCall) 
	{
		keyPresses[id] = toCall;
	}

	void keyPressTest(ubyte id)
	{
		auto p = id in keyPresses;
		if(p && focusQue[focus] == id)
		{
			foreach(key; std.traits.EnumMembers!(Key)) {
				if(keyboard.wasPressed(key)) {
					(*p)(key);
				}
			}
		}
	}

	void delegate(Key,KeyModifier)[ubyte] keyReleases;
	void keyRelease(ubyte id, void delegate(Key, KeyModifier) toCall) 
	{
		keyReleases[id] = toCall;
	}

	void keyReleaseTest(ubyte id)
	{
		auto p = id in keyPresses;
		if(p && focusQue[focus] == id)
		{
			foreach(key; std.traits.EnumMembers!(Key)) {
				if(keyboard.wasReleased(key)) {
					(*p)(key);
				}
			}
		}
	}


	//size_t opDispatch(string m, Set, Style)(Rect rect, Set settings, Style style)
	//{
	//   return opDispatch!(m, Set, Style)(0, rect, settings, style);
	//}
	//
	//size_t opDispatch(string m, Set, Style)(ubyte parent, Rect rect, Set settings, Style style)
	//{
	//   assert(parent < controlCount, "Can only be the child of an existing component!");
	//
	//   transform.localArea ~= rect;
	//   transform.parents   ~= parent;
	//   transform.offsets   ~= float2.zero;
	//   transform.globalArea ~= Rect.zero;
	//
	//   state	   ~= ControlState.init;
	//   focusQue ~= controlCount;
	//
	//   import std.string;
	//   controls ~= settings.create(style);
	//
	//   return ++controlCount;
	//}

	ubyte c(T, U...)(Rect area, U params) if(is(T : IControl))
	{
		return c!(T, U)(0, area, params);
	}

	ubyte c(T, U...)(ubyte parent, Rect area, U params) if(is(T : IControl))
	{
		focusQue ~= controls.count;
		controls.add(new T(params), area, parent);

		return cast(ubyte)(controls.count - 1);
	}

	void process()
	{
		controls.calculateGlobalTransforms();
		calculateFocus();

		//Process Events. (That is mouse and keyboard events)
		//processEvents();
		


		foreach(index; 1 .. controls.count)
		{	
			auto area = controls.intersections[index];
			auto state = calculateState(index, area);
		   //controls[index].stateChange(nState, state[index]);
			//Insert Event management and stuff here.
			processEvents(cast(ubyte)index);
			controls.controls[index].render(area,
													  controls.globalAreas[index],
													  state, renderer);
		}
	}

	void processEvents(ubyte id)
	{
		auto area = controls.intersections[id];

		clickTest(id, area);
		mouseEnterTest(id, area);
		mouseStayTest(id, area);
		mouseExitTest(id, area);

		keyPressTest(id);
		keyReleaseTest(id);

		//focusGainedTest(id);
		//focusLostTest(id);
	}

	void render(ref math.matrix.Matrix4 matrix)
	{
		renderer.render(matrix);
	}

	auto calculateState(size_t index, Rect area)
	{
		ControlState state;
		if(area.intersects(mouse.newLoc))
			state.hover = true;
		if(mouse.isDown(MouseButton.left) &&
			area.intersects(mouse.down[MouseButton.left].loc))
			state.press = true;

		if(focusQue[focus] == index)
			state.focus = true;

		return state;
	}

	auto calculateFocus()
	{
		if(mouse.changed[MouseButton.left]) {
			ButtonState state = mouse.down[MouseButton.left];
			if(state.inState)
			{
				foreach(index; 1 .. controls.count) {
					if(controls.globalAreas[index].intersects(state.loc)) {
						focus = std.algorithm.countUntil(focusQue, index);
						break;
					}
				}
			}
		} 

		if(keyboard.wasPressed(Key.tab)) {
			if(keyboard.modifier == KeyModifier.shift)
				if(focus == 0) focus = focusQue.length - 1;
				else focus = focus - 1;
			else 
				focus = (focus + 1) % focusQue.length;
		}
	}
}