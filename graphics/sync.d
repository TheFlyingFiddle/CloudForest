module graphics.sync;

import graphics.errors;
import derelict.opengl3.gl3;

enum SyncComplete
{
	alreadySignaled    = GL_ALREADY_SIGNALED,
	timeoutExpired     = GL_TIMEOUT_EXPIRED,
	conditionSatisfied = GL_CONDITION_SATISFIED,
	waitFailed			 = GL_WAIT_FAILED
}

struct Fence
{
	GLsync name;

	static Fence create() 
		out { assertNoGLError(); }
	body
	{
		return Fence(glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0));
	}

	void gpuWait() 
		out { assertNoGLError(); }
	body
	{
		glWaitSync(name, 0, GL_TIMEOUT_IGNORED);
	}

	SyncComplete clientWait(ulong nanoTimeout) 
		out { assertNoGLError(); }
	body
	{
		return cast(SyncComplete)(name, GL_SYNC_FLUSH_COMMANDS_BIT, nanoTimeout);
	}

	bool signaled() @property 
		out { assertNoGLError(); }
	body
	{
		int result;
		glGetSynciv(name, GL_SYNC_STATUS, int.sizeof, null, &result);
		return result == GL_SIGNALED;
	}

	bool deleted() @property
	{
		return glIsSync(name) == GL_FALSE;
	}

	void destroy()
		in { assertNotDeleted(this); }
		out { assertNoGLError(); }
	body
	{
		glDeleteSync(this.name);
	}
}