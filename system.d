module entity.system;


interface ISystem(T)
{
	/**********************************
	*	Runs an update on all registered
	*	objects in this system
	***********************************/
	void process();
	void registerComponent(T obj);
}