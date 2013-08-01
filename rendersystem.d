module entity.rendersystem;
import entity.system;

interface IRenderComponent
{
	void draw();
}

class RenderSystem : ISystem!IRenderComponent
{
	private IRenderComponent[] comps;

	override void registerComponent(IRenderComponent comp)
	{
		comps ~= comp;
	}

	override void process()
	{
		foreach(comp;comps)
		{
			comp.draw();
		}
	}
}