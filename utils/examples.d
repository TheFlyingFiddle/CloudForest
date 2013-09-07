module utils.examples;

import utils.message;
import utils.pipeline;

unittest
{
	struct InterpipeMsgA
	{
		int id;
		bool valid;
	}

	struct InterpipeMsgB
	{
		int control;
		string name;
	}

	struct ProcessItem
	{
		string name;
	}

	auto msgBus = new MessageBus!(InterpipeMsgA, InterpipeMsgB);
	auto pipesline = pipeline!(ProcessItem)(
		  (ref x) { msgBus ~= InterpipeMsgA(10, false); },
		  (ref x) { msgBus ~= InterpipeMsgB(32, "Monkey"); },
		  (ref x) 
		  {
			  auto msg = msgBus.messages!InterpipeMsgB[0];
			  if(msg.control == 32)
				  x.name = msg.name;
		  });

	ProcessItem item;
	pipesline.process(item);

	assert(item.name == "Monkey");
}