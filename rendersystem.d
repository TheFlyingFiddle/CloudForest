module entity.rendersystem;
import entity.system;

alias IRenderComponent rc;

interface IRenderComponent:IComponent
{
	void draw();
}

class RenderSystem : ISystem
{
	private rc[] comps;

	override void registerComponent(IComponent comp)
	{
		if(is(comp:IRenderComponent))
			comps ~= cast(rc)comp;
	}

	override void process()
	{
		foreach(comp;comps)
		{
			comp.draw();
		}
	}
}