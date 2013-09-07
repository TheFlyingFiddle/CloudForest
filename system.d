module entity.system;

import entity.entity;
import entity.database;

interface ISystem
{
	/**********************************
	*	Runs an update on all registered
	*	objects in this system
	***********************************/
	void process();
	bool tryRegister(Entity entity);
	void register(Entity entity);
}