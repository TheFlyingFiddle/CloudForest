module entity.system;


interface IComponent {}

interface ISystem
{
	/**********************************
	*	Runs an update on all registered
	*	objects in this system
	***********************************/
	void process();
	void registerComponent(IComponent comp);
}