package eyeblaster.events
{
	import flash.events.Event;
	
	public class EBBandwidthEvent extends Event
	{
		public static var BW_DETECT:String = "ebBandwidthDetect";
		
		public var bandwidth:int = -1;
		public var streamBandwidth:int = -1;
		
		public function EBBandwidthEvent(type:String, bandwidth:int, streamBandwidth:int = -1)
		{
			super(type);
			this.bandwidth = bandwidth;
			this.streamBandwidth = streamBandwidth;
		}
	
	}
}