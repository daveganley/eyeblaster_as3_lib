package eyeblaster.videoPlayer.core
{
	import eyeblaster.events.EBBandwidthEvent;
	import eyeblaster.events.EBLiveStreamEvent;
	import flash.events.EventDispatcher;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	
/**
* Dispatched when the streaming server determins the bandwidth
*
* @eventType com.eyewonder.events.BandwidthEvent
*/
[Event(name="bwDetect", type="eyeblaster.events.EBBandwidthEvent")]	

	/** @private This class is an implementation detail for VideoScreen */
	public class EBNetConnection extends flash.net.NetConnection
	{
		public var type:String;
		public var bandwidth:int;
		
		private var _closed:Boolean;
		
		public function EBNetConnection( type:String )
		{
			bandwidth = -1;	
			this.type = type;
			this.objectEncoding = ObjectEncoding.AMF0; // FMS2 uses AMF0, not the default AMF3
			super();
		}
		
		/** @private */
		public function onBWCheck( ... rest ):Number
		{
			return 0;
		}

		/** @private */	
		public function onBWDone( bandwidth:Number, ... rest ):void
		{			
			this.bandwidth = bandwidth;
			dispatchEvent( new EBBandwidthEvent( EBBandwidthEvent.BW_DETECT, bandwidth) );
		}
		
		public function onFCSubscribe( info:Object ):void
		{	
			dispatchEvent( new EBLiveStreamEvent(EBLiveStreamEvent.FC_SUBSCRIBE,info));
		}
		
		public function onFCUnsubscribe( info:Object ):void
		{
			dispatchEvent( new EBLiveStreamEvent(EBLiveStreamEvent.FC_UNSUBSCRIBE,info));
		}
		
		public override function get connected():Boolean
		{
			if(_closed) return false;
			else return super.connected;
		}
		
		public override function close():void
		{
			_closed = true;
			super.close();
		}
	}
}