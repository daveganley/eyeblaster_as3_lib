//****************************************************************************
//      EBVideoMgr class
//---------------------------
//
//This class contains the APIs related to controlling all the videos on stage
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package
{ 
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBNotificationEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoManagerEvent;
	import eyeblaster.videoPlayer.IVideoScreen;
	import eyeblaster.videoPlayer.controls.IVideoControl;
	import eyeblaster.videoPlayer.core.RunLoop;
	
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

    public class EBVideoMgr 
	{
		public static var isForcedStreaming:Boolean;
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private static var videos:Object;
		private static var tempFuncArray:Array;
		
		private static var checkInterval:Number;
		private static var _currId:int = 1;
		private static var initialized:Boolean = false;
		
		private static var _current:IVideoScreen;
		private static var _adVolume:int = 100;
		
		private static var dispatcher:EventDispatcher = new EventDispatcher();
				
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					public Methods 
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		public static function Init():void
		{	
			videos = new Array();
			initialized = true;
			
			if(typeof(EBBase.urlParams.ebForcePlayMode) != "undefined")
			{
				isForcedStreaming = Boolean(Number(EBBase.urlParams.ebForcePlayMode));
			}

			if(tempFuncArray != null){
				for( var i:int = 0; i < tempFuncArray.length; i++) tempFuncArray[i]();
			}
			
			EBBase.addEventListener(EBNotificationEvent.NOTIFICATION,_OnNotification);
		}
		
		/**
		 * Registers a video with the EBVideoMgr. Videos should already be registered automatically however.
		 */
		public static function RegisterVideo(screen:*):void
		{			
			if(screen is IVideoScreen){
				if(initialized){
					setTimeout( initializeView, 1, screen );
				} else initCall(EBVideoMgr.RegisterVideo, arguments);
			} else {
				
				var screenName:String = screen.name;
				
				if(screenName == "_videoLoader"){
					// _videoLoader is used by the private instance inside a VideoPlayback control. We instead register it using the VideoPlayback control name
					screenName = screen.parent.name;
				}
				
				videos[screenName] = screen;
				
				dispatchEvent(new EBVideoManagerEvent(EBVideoManagerEvent.VIDEO_REGISTERED, screen));
			}
		}
		
		/**
		 * Register a video control (implementor of IVideoControl) by its instance name.
		 * Once the video is available, the initialize function of the IVideoControl will be called.
		 * 
		 * @param displayObject:IVideoControl Video Control to associate a video with
		 * @return Whether or not video already existed. If not, control will be queued into video is available
		 * 
		 */
		public static function RegisterControlToScreen(control:IVideoControl ):Boolean
		{
			if(initialized){
				setTimeout(initializeControl,1, control);
				return true;
			} else initCall(EBVideoMgr.RegisterControlToScreen, arguments);
			
			return false;
		}
		
		private static function initializeView( screen:IVideoScreen ):void
		{	
			_current = screen; // Go ahead and set as current
			var _id:int = _currId++;
			videos[screen.name] = screen;
			screen.initialize(_id);
			screen.addEventListener(EBVideoEvent.PLAYBACK_START,_OnVideoStart);
			
			dispatchEvent(new EBVideoManagerEvent(EBVideoManagerEvent.VIDEO_REGISTERED, screen));
			dispatchEvent(new EBVideoManagerEvent(EBVideoManagerEvent.VIDEO_CHANGED, screen));
		}
		
		private static function initializeControl(control:IVideoControl):void
		{
			control.initialize();
		}
		
		private static function _OnVideoStart(event:EBVideoEvent):void
		{
			_current = event.target as IVideoScreen; // automatically set when playing
			
			dispatchEvent(new EBVideoManagerEvent(EBVideoManagerEvent.VIDEO_CHANGED, event.target));
		}
		
		private static function _OnNotification(event:EBNotificationEvent):void
		{
			if(event.subtype == EBNotificationEvent.CLOSE){
				StopAll();
			}
		}
		
		private static function initCall( func:Function, argref:Array ):void
		{
			var delayFunction:Function = function():void
			{
				func.apply( this, argref );
			};
			
			if(tempFuncArray == null){
				tempFuncArray = new Array();
			}
			
			tempFuncArray.push( delayFunction );
		}
		
		
		/**
		 * Stops all of the videos in the ad
		 */
		public static function StopAll():void
		{
			for each(var video:* in videos)
			{
				video.stop();
			}
		}
		
		/**
		 * Sets the volume to all videos in the ad.
		 * 
		 * @param nVolLevel:Number The volume to set all of the videos to, on a scale of 0-100
		 */
		public static function SetAdVolume(nVolLevel:Number):void
		{
			_adVolume = nVolLevel;
			
			for each(var video:* in videos)
			{
				video.volume = nVolLevel;
			}
		}
		
		/**
		 * Toggles the audio for all videos in the ad
		 * 
		 * @param nMuteVal:int 0 = unmute all , 1 = mute all, 2 = toggle all
		 * @param nAutoInit:int 0 = user-initiated, 1 = auto-initiated
		 */
		public static function ToggleAdAudio(nMuteVal:int = 2, nAutoInit:int = 0):void
		{
			for each(var video:* in videos)
			{
				if(video is IVideoScreen){
					
					if(nMuteVal == 2){
						if(video.isMuted){
							nMuteVal = 0;
						} else {
							nMuteVal = 1;
						}
					}
					
					switch(nMuteVal){
						case 0:
							video.unmute();
							
							if(nAutoInit == 0){
								video.track("ebVideoUnmute");
							}
							
							break;
						case 1:
							video.mute();
							
							if(nAutoInit == 1){
								video.track("VideoMute");
							}
							
							break;
					}
				} else {
					video.setMute(nMuteVal,nAutoInit);
				}
			}
		}
		
		/**
		 * Gets an instance of a IVideoScreen from anywhere.
		 * 
		 * @param screenName:String Instance name of video to get
		 * @return An instance of IVideoScreen with that name.
		 * 
		 */
		public static function GetScreen(screenName:String):IVideoScreen
		{
			return GetVideo(screenName) as IVideoScreen;
		}
		
		/**
		 * Gets an instance of a video object from anywhere. If you know that the video object will be IVideoScreen, use GetScreen()
		 * This will work automatically for any VideoScreen component instances, but will require that a VideoLoader be registered.
		 * 
		 * @param screenName:String instance name of video to get
		 * @return An instance of the video with that name
		 * @see #GetScreen()
		 */
		public static function GetVideo(screenName:String):*
		{
			var video:*;
			video = videos[screenName];
			if( videos[screenName] == undefined ) return null;
			return video;
		}
		
		/**
		 * Gets the current playing IVideoScreen. This does not work for VideoLoader
		 */
		public static function get Current():IVideoScreen
		{
			return _current;
		}
		
		/**
		 * Retrieves the current volume that the ad should use.
		 */
		public static function get AdVolume():int
		{
			return _adVolume;
		}
		
		/**
		* An array of the videos. If you know the name of the video already, you can use #GetVideo() instead.
		*/
		public static function get Videos():Array
		{
			var v:Array = new Array();
			
			for (var prop:String in videos) {
				v.push(videos[prop]);
			}
			
			return v;
		}
		
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public static function dispatchEvent(e:Event):void
		{
			dispatcher.dispatchEvent(e);
		}
    } 
}