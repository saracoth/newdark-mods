class J4FDebugger extends SqRootScript
{
	function OnMessage()
	{
		local currentMessage = message();
		
		print(format("Debug %s (%s) %i: %s %s %i -> %s %i [%i]", Object.GetName(Object.Archetype(self)), Object.GetName(self), self, currentMessage.message, Object.GetName(Object.Archetype(currentMessage.from)), currentMessage.from, Object.GetName(Object.Archetype(currentMessage.to)), currentMessage.to, currentMessage.flags));
		
		if (currentMessage.data != null)
		{
			print("With data:");
			print(currentMessage.data);
		}
		if (currentMessage.data2 != null)
		{
			print("With data2:");
			print(currentMessage.data2);
		}
		if (currentMessage.data3 != null)
		{
			print("With data3:");
			print(currentMessage.data3);
		}
		
		if (currentMessage instanceof ::sFrobMsg)
		{
			print(format("\tFrobber %s %i: [%s] %s %i -> [%s] %s %i (sec %g%s)", Object.GetName(Object.Archetype(currentMessage.Frobber)), currentMessage.Frobber, currentMessage.SrcLoc.tostring(), Object.GetName(Object.Archetype(currentMessage.SrcObjId)), currentMessage.SrcObjId, currentMessage.DstLoc.tostring(), Object.GetName(Object.Archetype(currentMessage.DstObjId)), currentMessage.DstObjId, currentMessage.Sec, currentMessage.Abort ? ", Aborted" : ""));
		}
		
		if (currentMessage instanceof ::sScrTimerMsg)
		{
			print(format("\tTimer %s", currentMessage.name));
		}
		
		if ("sDarkGameModeScrMsg" in getroottable() && currentMessage instanceof ::sDarkGameModeScrMsg)
		{
			print(format("\tGameMode { resuming = %s, suspending = %s }", currentMessage.resuming.tostring(), currentMessage.suspending.tostring()));
		}
		
		if (currentMessage instanceof ::sContainedScrMsg)
		{
			print(format("\tContained by %s %i (event %s)", Object.GetName(Object.Archetype(currentMessage.container)), currentMessage.container, currentMessage.event.tostring()));
		}
		
		// TODO: handling of other specific message types?
	}
	
}
