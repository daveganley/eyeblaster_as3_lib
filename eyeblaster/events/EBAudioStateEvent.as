package eyeblaster.events
{
	import flash.events.Event;

	public class EBAudioStateEvent extends Event
	{
		public var isMuted:Boolean;
		public var volume:int;
		
		public static const AUDIOSTATE_CHANGE:String = "ebAudioStateChange";
		
		public function EBAudioStateEvent( name:String, isMuted:Boolean, volume:int )
		{
			this.isMuted = isMuted;
			this.volume = volume;
			super( name );
		}
	}
}