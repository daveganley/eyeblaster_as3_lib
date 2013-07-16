package eyeblaster.videoPlayer
{
	import eyeblaster.events.EBBandwidthEvent;
	import eyeblaster.videoPlayer.core.VideoStreamConnector;
	import eyeblaster.videoPlayer.core.EBNetConnection;
	import eyeblaster.utils.SWFUtils;

	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	import eyeblaster.videoPlayer.events.VideoStreamConnectorEvent;
	import eyeblaster.videoPlayer.core.VideoStreamConnector;
	import eyeblaster.videoPlayer.core.EBNetConnection;
	

	/**
* Dispatched when the video screen determines the end-user's bandwidth
*
* @eventType eyeblaster.events.EBBandwidthEvent.BW_DETECT
*/
[Event(name="bwDetect", type="eyeblaster.events.EBBandwidthEvent")]

	/**
	 * The BandwidthDetect class can be used to detect the current bandwidth
	 * of the end-user's machine. It's used internally for determining the bandwidth
	 * of the video to play.
	 * 
	 * @example <listing version="3.0">var bwDetect:BandwidthDetect = new BandwidthDetect();
	 * bwDetect.addEventListener("bwDetect", myBandwidthListener );
	 * bwDetect.detectBandwidth()
	 * 
	 * function myBandwidthListener( event:BandwidthEvent ):void
	 * {
	 * 		var myBandwidth:int = event.bandwidth;
	 * }
	 * </listing>
	 * 
	 */
	public class BandwidthDetect extends EventDispatcher
	{
		private var startTime:Number;
		
		public var bandwidth:Number;
		public var streamBandwidth:Number;
		
		private var stream:EBNetConnection;
		private var streamHelper:VideoStreamConnector;
		
		public function BandwidthDetect()
		{
			streamBandwidth = -1;	
		}
		
		private function bandwidth_Start( event:Event ):void
		{
			startTime = getTimer();
		}
		
		private function bandwidth_Complete( event:Event ):void
		{
			var loaderInfo:LoaderInfo = (event.target as LoaderInfo);
			var bandwidth:int = bandwidth_Calculate( startTime, loaderInfo.bytesTotal );
			dispatchEvent( new EBBandwidthEvent( EBBandwidthEvent.BW_DETECT, bandwidth, streamBandwidth ));
		}
		
		private function bandwidth_Calculate( startTime:int, bytesTotal:int ):int
		{
			var elapsedTime:Number = ( getTimer() - startTime ) / 1000;
			var totalBits:Number = bytesTotal * 8;
			var totalKBits:Number = totalBits / 1024;
			var kbps:Number = (totalKBits / elapsedTime );	
			
			return Math.floor( kbps );
		}
		
		private function _detectBandwidth_Progressive():void
		{	
			var bwMovie:MovieClip = new MovieClip();
			bwMovie.height = 0;
			bwMovie.width = 0;
			bwMovie.visible = false;
			
			var bwMovieUri:String = (SWFUtils.IsRunningInSecureMode()) ? 
				"https://secure-ds.serving-sys.com/BurstingScript/bandwidthdetect.jpg?ewbust="+(new Date()).getTime() : 
				"http://ds.serving-sys.com/BurstingScript/bandwidthdetect.jpg?ewbust="+(new Date()).getTime();
				
			
			var bwLoader:Loader = new Loader();
			bwLoader.load(new URLRequest( bwMovieUri ));
			bwLoader.contentLoaderInfo.addEventListener( Event.OPEN, bandwidth_Start);
			bwLoader.contentLoaderInfo.addEventListener( Event.COMPLETE, bandwidth_Complete);
			bwMovie.addChild( bwLoader );
		}
		
		private function _detectBandwidth():void
		{
			if(!EBVideoMgr.isForcedStreaming) _detectBandwidth_Progressive();
			else _detectBandwidth_Streaming();
		}
		
		private function _detectBandwidth_Streaming():void
		{
			streamHelper = new VideoStreamConnector();
			streamHelper.addEventListener( VideoStreamConnectorEvent.STREAM_CONNECTED, stream_connected);
			streamHelper.addEventListener( EBBandwidthEvent.BW_DETECT, stream_bw);
		}
		
		private function _detectBandwidth_Local():void
		{
			bandwidth = 600;
			dispatchEvent( new EBBandwidthEvent( EBBandwidthEvent.BW_DETECT, bandwidth, streamBandwidth ));
		}
		
		private function stream_connected( event:VideoStreamConnectorEvent ):void
		{
			stream = event.stream;
		}
		
		private function stream_bw( event:EBBandwidthEvent ):void
		{
			stream.close();
			
			streamBandwidth = event.bandwidth;
			_detectBandwidth_Progressive();
		}
		
		/**
		 * Begins calculating the end user's bandwidth. Listen to the "bwDetect" event
		 * to determine the bandwidth.
		 */
		public function detectBandwidth():void
		{
			_detectBandwidth();
		}
	}
}