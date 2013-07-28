module graphics.query;

import derelict.opengl3.gl3;
import std.algorithm : remove, countUntil;
import graphics.errors;
import graphics.enums;

final class Query
{
	package uint glName;

	this() 
	{
		glGenQueries(1, &glName);
	}

	bool deleted() @property
	{
		return glIsQuery(glName) == GL_FALSE;
	}

	void destroy()
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteQueries(1, &glName);
	}

	void startQuery(QueryTarget target, void delegate() queryScope) 
		out { assertNoGLError(); }
	body
	{
		glBeginQuery(target, glName);
		queryScope();
		glEndQuery(target);
	}

	void queryCounter() 
		out { assertNoGLError(); }
	body
	{
		glQueryCounter(glName, QueryTarget.timeStamp);
	}
	
	bool queryComplete() @property
		out { assertNoGLError(); }
	body
	{
		uint result;
		glGetQueryObjectuiv(glName, GL_QUERY_RESULT_AVAILABLE, &result);
		return result == GL_TRUE;
	}

	uint result() 
		out { assertNoGLError(); }
	body
	{
		uint result;
		glGetQueryObjectuiv(glName, GL_QUERY_RESULT, &result);
		return result;
	}

	ulong result64() 
		out { assertNoGLError(); }
	body
	{
		ulong result;
		glGetQueryObjectui64v(glName, GL_QUERY_RESULT, &result);
		return result;
	}
}