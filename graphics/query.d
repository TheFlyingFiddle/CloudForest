module graphics.query;

import derelict.opengl3.gl3;
import std.algorithm : remove, countUntil;
import graphics.errors;
import graphics.enums;

final class Query
{
	package uint glName;

	this(uint glName) 
	{
		this.glName = glName;
	}

	static Query create() 		
		out { assertNoGLError(); }
	body
	{
		uint glName;
		glGenQueries(1, &glName);
		auto query = new Query(glName);
		return query;
	}


	void destroy()
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