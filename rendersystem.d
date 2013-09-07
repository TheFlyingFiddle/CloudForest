module entity.rendersystem;
import entity.system;
import entity.entity;

alias RenderComponent rc;

struct RenderComponent
{
	void draw();
}

class RenderSystem : ISystem
{
	private Entity[] entities;

	override void register(Entity entity)
	{
		if(entity.hasComponent!(RenderComponent))
			entities ~= entity;
	}

	override void process()
	{
		foreach(entity;entities)
		{
			entity.draw();
		}
	}
}