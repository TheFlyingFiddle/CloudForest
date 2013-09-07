module utils.pipeline;

final class Pipeline(T) if(is(T == struct))
{
	enum defaultNumPipes = 4;

	void delegate(ref T)[] pipes;

	this(void delegate(ref T)[] pipes) 
	{
		this.pipes = pipes;
	}
	
	void opAssing(string op)(void delegate(ref T) pipe) if(op == "~")
	{
		pipes ~= pipe;
	}
	
	void process(ref T msg)
	{
		foreach(pipe; pipes)
			pipe(msg);
	}
}

Pipeline!(T) pipeline(T)(void delegate(ref T)[] pipes...) if(is(T == struct))
{
	auto pipeline = new Pipeline!T(pipes);
	return pipeline;
}

unittest
{
	struct Message
	{
		string name;
		int lifeTime;
		bool delegate() callback;
	}

	auto pipeline = pipeline!(Message)(
								(ref x) { x.name = "Sir Frog"; }, 
								(ref x) { x.lifeTime = 32; }, 
								(ref x) { if(x.callback()) x.lifeTime = 12; });

	auto msg = Message("Mr prince", 21, () => false);
	pipeline.process(msg);

	assert(msg.name == "Sir Frog");
	assert(msg.lifeTime == 32);

	msg.callback = () => true;
	pipeline.process(msg);
	
	assert(msg.name == "Sir Frog");
	assert(msg.lifeTime == 12);
}