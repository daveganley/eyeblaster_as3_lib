package eyeblaster.videoPlayer
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBAudioStateEvent;
	import eyeblaster.events.EBBandwidthEvent;
	import eyeblaster.events.EBErrorEvent;
	import eyeblaster.events.EBMetadataEvent;
	import eyeblaster.events.EBNotificationEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoStateEvent;
	import eyeblaster.videoPlayer.BandwidthDetect;
	import eyeblaster.videoPlayer.core.EBNetConnection;
	import eyeblaster.videoPlayer.core.RunLoop;
	import eyeblaster.videoPlayer.core.Utils;
	import eyeblaster.videoPlayer.core.VideoStreamConnector;
	import eyeblaster.videoPlayer.core.VideoStreamURL;
	import eyeblaster.videoPlayer.events.VideoStreamConnectorEvent;
	import flash.system.Capabilities;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
/**
 * Dispatched when the video screen begins initialization. If you create the VideoScreen dynamically, you must set the component parameters here.
 *
 * @eventType flash.events.Event.INIT
 */
[Event(name="init", type="flash.events.Event")]
	
/**
* Dispatched when the video screen determines the end-user's bandwidth
*
* @eventType eyeblaster.events.EBBandwidthEvent.BW_DETECT
*/
[Event(name="ebBandwidthDetect", type="eyeblaster.events.EBBandwidthEvent")]

/**
* Dispatched when the video stops playing
*
* @eventType eyeblaster.events.EBVideoEvent.PLAYBACK_STOP
*/
[Event(name="ebPlaybackStop", type="eyeblaster.events.EBVideoEvent")]

/**
* Dispatched when the video starts playing
*
* @eventType eyeblaster.events.EBVideoEvent.PLAYBACK_START
*/
[Event(name="ebPlaybackStart", type="eyeblaster.events.EBVideoEvent")]

/**
* Dispatched when a video begins playback (0% played)
*
* @eventType eyeblaster.events.EBVideoEvent.MOVIE_START
*/
[Event(name="ebMovieStart", type="eyeblaster.events.EBVideoEvent")]

/**
* Dispatched when the video ends (100% played)
*
* @eventType eyeblaster.events.EBVideoEvent.MOVIE_END
*/
[Event(name="ebMovieEnd", type="eyeblaster.events.EBVideoEvent")]

/**
 * Dispatched when the volume changes. This includes when mute is toggled
 * 
 * @eventType eyeblaster.events.EBAudioStateEvent.AUDIOSTATE_CHANGE
 */
[Event(name="ebAudioStateChange", type="eyeblaster.events.EBAudioStateEvent")]

/**
 * Dispatched when a video is stopped, paused, or played.
 * 
 * @eventType eyeblaster.events.EBVideoStateEvent.VIDEOSTATE_CHANGE
 */ 
[Event(name="ebVideoStateChange", type="eyeblaster.events.EBVideoStateEvent")]

/**
 * Dispatched approximately every 100ms while the video is playing to update video playback progress
 * 
 * @eventType eyeblaster.events.EBVideoEvent.PLAY_PROGRESS
 */
[Event(name="ebPlayProgress", type="eyeblaster.events.EBVideoEvent")]

/**
 * Dispatched approximately every 100ms while the video is loading to update video load progress
 * 
 * @eventType eyeblaster.events.EBVideoEvent.LOAD_PROGRESS
 */
[Event(name="ebLoadProgress", type="eyeblaster.events.EBVideoEvent")]

/**
 * Dispatched when the metadata is receieved from the underlying stream
 * 
 * @eventType eyeblaster.events.EBMetadataEvent.METADATA_RECEIVED
 */
[Event(name="ebMetadataReceived", type="eyeblaster.events.EBMetadataEvent")]

/**
 * Dispatched when the XMP information is receieved from the underlying stream
 * 
 * @eventType eyeblaster.events.EBMetadataEvent.XMPDATA_RECEIVED
 */
[Event(name="ebXMPDataReceived", type="eyeblaster.events.EBMetadataEvent")]

/**
 * Dispatched when the stream or video component reaches a cuepoint. You can specify cuepoints either in the video file
 * or at runtime via the 'cuepoints' tab in the component inspector
 * 
 * @eventType eyeblaster.events.EBMetadataEvent.CUE_POINT
 */
[Event(name="ebCuePoint", type="eyeblaster.events.EBMetadataEvent")]

/**
 * Dispatched when the video has finished its initial buffer
 * 
 * @eventType eyeblaster.events.EBVideoEvent.BUFFER_LOADED
 */
[Event(name="ebBufferLoaded", type="eyeblaster.events.EBVideoEvent")]

/**
 * Dispatched when the video has reached an error.
 * 
 * @eventType eyeblaster.events.EBErrorEvent.ERROR
 */
[Event(name="Error", type="eyeblaster.events.EBErrorEvent")]

	/**
	 * A VideoScreen is MediaMind's video component for Flash. Use it to play videos. It features
	 * automatic bandwidth detection, easy to use scriptability, and video controls designed
	 * specifically to work with it. The easiest way to create one is via drag-and-drop.
	 */
	public class VideoScreen extends Sprite implements IVideoScreen
	{
		/** @private */ public var initialized:Boolean = false;
		/** @private */ public var trackInitialized:Boolean = false;
		
		private var _isPlaying:Boolean = false;
		private var _isPaused:Boolean = false;
		private var _isStopped:Boolean = true;
		private var _isPausedForScrubbing:Boolean = false;
		private var _isPausedOnLastFrame:Boolean = false;
		private var _isWaitingForSeek:Boolean = false;
		
		/** Whether or not the video is buffering */
		private var _isBuffering:Boolean = false;

		private var trackThreshold:int = 0;
		
		private var doPlayVideo:Boolean = false;
		private var doPlayAudio:Boolean = false;
		private var videoEventCalled:Array;
		
		private var _isOffLine:int = -1;
		private var currentVideoTime:Number = 0;
		private var lastSavedTime:Number = 0; //new implementation of updateDuration algorithm
		
		private var _stream:NetStream = null;
		
		private var connectSuccess:Boolean = false;
		private var connection:EBNetConnection = null;
		private var connectStream:EBNetConnection;
		private var connectProgressive:EBNetConnection;
		
		private var streamHelper:VideoStreamConnector;
		private var waitForExternalPackage:Boolean = false;
		
		
		/** Bandwidth of the video */
		private var _bandwidth:int = -1;
		
		/** The buffer length, in seconds. Set automatically for internal videos */
		public var buffer:int;
		
		/** If using an additional asset, this represents the current asset id */
		private var _currentAssetId:int = -1;
		
		private var _currentAssetIdForTimer:int = -1;
		
		/** The URL of the currently playing video file */
		private var _videoUrl:String;
		
		private var _length:Number;
		
		private var _video:Video;
		
		private var waitForInit:int = 0;
		/** The current percentage of the video that has been played */
		public var percentViewed:Number = 0;
		
		[Inspectable]
		public var videoEvents:Array;
		[Inspectable]
		public var videoEventTimes:Array;
		[Inspectable]
		public var videoFileID:Array;
		
		private var _netstreamStop:Boolean;
		
		private var _volume:int = -1;
		private var _prevVolume:int; // Stores the original volume if audioOff() is called.
		
		
		private var _streamIdle:Number;
		private var STREAM_IDLE_TIME:Number = 30;
		
		private var _isBufferEmpty:Boolean;
		private var _isBufferFlushed:Boolean;
		private var ns_isStopped:Boolean;
		
		private var _initCallback:Function;
		private var _skipInitVideoUrl:Boolean = false;
		
		private var _w:int;
		private var _h:int;
		
		// MEDIAMIND PRIVATE PARAMS
		private var _id:int;
		private var _JSAPIFuncName:String;
		private var _externalFMS:String;
		private var _isExternalVideo:Boolean;
		private var _isFullScreen:Boolean;
		private var _prevStatus:int;
		private var _hasFullyLoaded:Boolean = false;
		private var _unmutedReported:Boolean = false;
		private var _isStreaming:Boolean = false;
		
		private var _videoWidth:Number;
		private var _videoHeight:Number;
		
		private var saveWidthBeforeFS: Number;
		private var saveHeightBeforeFS: Number;
		
		//mf//
		private var saveXPosBeforeFS: Number;
		private var saveYPosBeforeFS: Number;
		private var saveIndexBeforeFS: Number;
		
		
		private var default_bg_color:uint = 0x000000;
		private var bgshape:Sprite;
		
		public var triggerFsBg:Boolean = true;
		[Inspectable(type=String)]
		public var offlineVideoFile:String = "";
		
		/**
		 * Represents the component inspector's "Play Automatically" property
		 */
		[Inspectable(type=Boolean,defaultValue=false)]
		public var fAutoPlay:Boolean = false;
		
		/**
		 * Represents the component inspector's "Start video with sound on" property
		 */
		[Inspectable(type=Boolean,defaultValue=true)]
		public var muteOnVideoStart:Boolean = true;
		
		/**
		 * Represents the component inspector's "Display Size" property
		 * 
		 * Possible values are:
		 * 
		 * <ul>
		 * 	<li><strong>0</strong> - 'Stretch video to fit, preserving aspect ratio'</li>
		 *  <li><strong>1</strong> - 'Stretch video to fit exactly</li>
		 *  <li><strong>2</strong> - 'Play in original video size'</li>
		 * </ul>
		 */
		[Inspectable(enumeration="0,1,2" ,defaultValue=0, type=Number)]
		public var displayMode:int = 0;
		
		[Inspectable (defaultValue=1, type=Number)]
		public var nVideoFileNum:int = 1;
		
		[Inspectable(defaultValue="",type=String)]
		public var strExtVideoUrl:String = "";
		
		[Inspectable(defaultValue=1,type=Number)]
		public var nGoToFrame:int = 1;
		
		[Inspectable(defaultValue=0,type=Number)]
		public var nOnMovieEnd:int = 0;
		
		[Inspectable(defaultValue="0,0,0", type=Array)]
		public var onRolloverArr:Array = new Array(0,0,0);
		
		[Inspectable(defaultValue="1,0,0", type=Array)]
		public var onClickArr:Array = new Array(1,0,0);
	
		[Inspectable(defaultValue=false,type=Boolean)]
		public function set isStreaming(value:Boolean):void
		{
			_isStreaming = value;
		}
		
		/** @private */
		public function get isStreaming():Boolean
		{
			if(!EBVideoMgr.isForcedStreaming)
			{
				if ( isOffLine )
					return false;
				if(currentAssetId != 0){
					return _isStreaming;
				}
				
				return _externalFMS != null;	
			}
			
			return true;
		}

		
		//----General------
		include "../core/compVersion.as"
		
		/** @private */
		public var compName:String = "VideoScreen";	//The component name.
		
		/**
		 * Creates an instance of a VideoScreen. Preferred method is via drag-and-drop.
		 */
		public function VideoScreen()
		{
			EBBase.ebSetComponentName("VideoScreen");
			addEventListener(Event.ADDED_TO_STAGE,OnAddedToStage);
			EBBase.addEventListener(EBNotificationEvent.NOTIFICATION, OnEBNotification);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			if(parent is IVideoScreen == false){
				EBVideoMgr.RegisterVideo(this);
			}
		}

		private function OnEBNotification(e:Event):void
		{
			var notificationEvent:EBNotificationEvent = e as EBNotificationEvent;
			if (notificationEvent != null && notificationEvent.subtype == EBNotificationEvent.EXIT_FULLSCREEN_MODE && !this.parent.hasOwnProperty("compName"))
				setFullScreen(false);
		}
		
		/** @private
		 *
		 * Called from EBVideoMgr when we are ready to be used 
		 **/
		public function initialize(id:int):void
		{
			dispatchEvent(new Event(Event.INIT));
			
			drawFSrectangle();//mf/draw a fs rectangle to maintain aspect ration on fs		
			_id = id;
			
			if(_w == 0) _w = width;
			if(_h == 0) _h = height;
			
			if(!_skipInitVideoUrl){
				_currentAssetId = nVideoFileNum;
				
				if(currentAssetId == 0){
					_videoUrl = strExtVideoUrl;
				}
			}
			
			this._JSAPIFuncName = "handleVideoLoader" + _id;
			EBBase.Callback(_JSAPIFuncName, JSAPIFunc);
			
			videoEventCalled = new Array();
			if( initialized ) return;
			RunLoop.addFunction(trackVideo);
			if( videoEvents == null ) videoEvents = new Array();
			if( videoEventTimes == null ) videoEventTimes = new Array();
			if( videoFileID == null ) videoFileID = new Array();
			initialized = true;
									
			/// Ensure default audio volume if volume has not been set yet
			if(_volume == -1 && !muteOnVideoStart) 
				_volume = EBVideoMgr.AdVolume; // We should use the volume set by EBVideoMgr.SetAdVolume()
			

			// Params for ebInitVideoLoader command
			var initParams:Array = [_JSAPIFuncName,Boolean(displayMode),isStreaming,fAutoPlay,_calcPosAndSize(),(onClickArr.join() != "0,0,0"),true];
			EBBase.handleCommand("ebInitVideoLoader",initParams.join(","));
			
			if(onRolloverArr.toString() != "0,0,0"){
				addEventListener(MouseEvent.MOUSE_OVER,_OnRolloverHandler);
				addEventListener(MouseEvent.MOUSE_OUT, _OnRolloverHandler);
			}
			
			setOnClickBehaviour();						
				
		
		
			
			if(!_skipInitVideoUrl && fAutoPlay){
				_isBuffering = true;
				_startLoad();
			}
			
			if(_skipInitVideoUrl && (fAutoPlay || doPlayVideo)){
				_isBuffering = true;
				_startPlay();
			}
		}
		
		/***
		 * Initilize class members 
		 */
		private function initMembers():void {
		
			_isExternalVideo = false;
		}
		
		//===========================================
		//	function _reportUnmuted
		//============================================
		//This function reports the unmuted interaction		
		// if video was started with "Start video with sound on" 
		// checked.		 
		private function _reportUnmuted():void
		{			
			if(!_unmutedReported) {
			   _unmutedReported = true;
			   track("ebVideoUnmuted", true);			
			}			
		}
		
		/***
		 * Calculates the position and size of the VideoScreen to send to JS with ebInitVideoLoader command
		 */
		private function _calcPosAndSize():String
		{
			var mc:DisplayObject = this;
			var x:Number = mc.x;
			var y:Number = mc.y;
			var w:Number = _w;
			var h:Number = _h;
			
			//loop till the main timeline to retrieve the
			//position and size in the main timeline.
			while(mc.parent != EBBase.currentAssetRef)
			{
				//move to the parent object
				mc = mc.parent;
				//update position
				x += mc.x;
				y += mc.y;
				//update size
				w*=mc.scaleX;
				h*=mc.scaleY;
			}
				
			var posAndSize:String = [x,y,w,h].join(",");
			return posAndSize;
		}

		/**
		 * @private
		 * Callback used by JavaScript (or instream loader) to call back to the video
		 */
		public function JSAPIFunc(funcName:String, strParams:String):void
		{
			var arr:Array;
			
			switch (funcName)
			{
				case "load":
					arr = strParams.split(",");
					
					//in case of external package In-Stream SHELL will use "load" function with additional parameter: 
					//url + "::1::0::0,0,1" - *1* as third parameter will indicate external package
					///in case of load *external* url call function loadAndPlayExt 
					//AS3 only [In-Stream]
					if (arr.length == 3 && arr[arr.length-1] == 1)
					{
						var url:String = splitUrlInfo(arr[0]);
						waitForExternalPackage = true;
						loadAndPlayExt(url);
					}
					else
					{
						//in case of load asset call to function loadProxy
						funcName = funcName + "Proxy";
						this[funcName](arr[0],arr[1]);
					}
					break;
				default:
					//functions that the name in the JS is the same as the flash - change the name in the flash to be without the word Video ansd that will start with lower case 
					if (funcName.substr(0,5).toLowerCase() == "video")
					{
						var firstChar:String = funcName.substr(5,1).toLowerCase();
						funcName = firstChar + funcName.substr(6);
					}
					if (strParams != "") //functions that have one parameter which its type is Number i.e. function VideoLoadAndPlay, VideoSeek
						this[funcName](Number(strParams));
					else				//functions that don't have parameters
						this[funcName]();
			}
		}
		
		/**
		 * Called when the "Play Automatically" option is selected. This will play either an external URL or an additional asset from a video package.
		 */
		private function _startLoad():void
		{
			if(nVideoFileNum == 0 && strExtVideoUrl != ""){
				// If playing an external url, and the external url is set
				loadAndPlayExt(strExtVideoUrl);
			} else if(nVideoFileNum != 0) {
				// play additional asset url
				_currentAssetId = -1;
				loadAndPlay(nVideoFileNum);
			}
		}
		
		/**
		 * Initializes the NetConnection option for streaming and progressive
		 */
		private function initNetConnection(callback:Function):void
		{
			_initCallback = callback;
			
			connectSuccess = false;
			connection = null;
			
			if( _currentAssetIdForTimer != -1 && currentAssetId != _currentAssetIdForTimer )
				_videoUrl = null; /// reset _videoUrl for a case a deferent video should be loaded into the same video component (asset after external link)
			
			if(isStreaming)
			{
				if(currentAssetId == 0){
					streamHelper = new VideoStreamConnector(_externalFMS);
				} else {
					streamHelper = new VideoStreamConnector();
				}
				
				streamHelper.addEventListener( VideoStreamConnectorEvent.STREAM_CONNECTED,stream_complete);
				streamHelper.addEventListener(EBBandwidthEvent.BW_DETECT,fmsBandwidth_Callback);				
				
			} else
			{   
			    connection = connectProgressive = new EBNetConnection("progresive");
                connectProgressive.connect( null );
                setupStream();
                
				if( bandwidth != -1)
                {
                	startPlayer();
                }
                else 
				{
					// progressive offline
					if ( isOffLine )  
					{
						startPlayer();
					}
					else // progressive on-line
					{   
						var bwDetect:BandwidthDetect = new BandwidthDetect();
						bwDetect.addEventListener( EBBandwidthEvent.BW_DETECT, bandwidth_Callback );
						bwDetect.detectBandwidth();                                                   
					}
				}
            }// progressive
		}
		
		private function stream_complete(event:VideoStreamConnectorEvent):void
		{
			connection = connectStream = event.stream;
		}
		
		private function setupStream():Boolean
		{	
			if(waitForExternalPackage) return false;
			///prevent attachNetStream(_stream) twice
			if(isPlaying) return true;
			
			if(connection)
			{
				if(!connection.connected && isStreaming)
				{
					connection = null;
					initNetConnection(null);
					return false;
				}
				
				if( _stream != null ) _stream = null;
				_stream = new NetStream( this.connection );
				_stream.client = this;
				_stream.addEventListener("netStatus", stream_Status);
				
				_video = getChildByName("ebVideo") as Video;
				
				if(_video == null){
					_video = new Video();
					_video.name = "ebVideo";
					addChild(_video);
				}
	
				_video.attachNetStream( _stream );
				
				return true;
			}
			
			return false;
		}
		
		private function bandwidth_Callback( event:EBBandwidthEvent ):void
		{
			if(!checkIfVideoIsCurrentOrAlive()) return;
			bandwidth = event.bandwidth;
			dispatchEvent(new EBBandwidthEvent( EBBandwidthEvent.BW_DETECT, bandwidth));
			
			startPlayer();
		}
		
		private function fmsBandwidth_Callback(event:EBBandwidthEvent):void
		{
			if(!checkIfVideoIsCurrentOrAlive()) return;
			bandwidth = event.bandwidth;
			dispatchEvent(new EBBandwidthEvent( EBBandwidthEvent.BW_DETECT, bandwidth));
			
			startPlayer();
		}
		
		private function _OnRolloverHandler(e:MouseEvent):void
		{
			if (isFullScreen)return;
			if(onRolloverArr[0] == "1"){ // Video Toggle
				videoToggle();
				if(isPaused){
					track("VideoPause");
				}
			}
			
			if(onRolloverArr[1] == "1"){ // Audio Toggle
				
				if(isMuted) track("ebVideoUnmute");
				else track("VideoMute");
				
				audioToggle();
			}
			
			if(onRolloverArr[2] == "1"){ // Custom
				_invokeHandler("Rollover",e.type == MouseEvent.MOUSE_OVER);	
			}
		}
		
		private function _OnClickHandler(e:MouseEvent):void
		{
			if(onClickArr[0] == "1"){ // Default Clickthru
				fSClose();
				EBBase.Clickthrough();
			}
			
			if(onClickArr[1] == "1"){ // Video Toggle
				videoToggle();
				if(isPaused){
					track("VideoPause");
				}
			}
			
			if(onClickArr[2] == "1"){ // Custom
				_invokeHandler("Click");
			}
		}
		
		private function startPlayer():void
		{
			if(_initCallback != null) _initCallback();
			
			if(!muteOnVideoStart) doPlayAudio = true;
			
			if(_initCallback == null){
				if(doPlayVideo == true){
					if(waitForExternalPackage)
					{
						waitForExternalPackage = false;
						_isPlaying = false;
						_isPausedOnLastFrame = false;
					}
					_startPlay();
				}
			}
		}
		
		private function setupBuffer():void
		{			
			Tracer.debugTrace("Detected Bandwidth: " + _bandwidth, 4);
			
			if( _bandwidth < 56 ) _bandwidth = 56;
			
			var tempBandwidth:Number = _bandwidth;
		
			var bwArray:Array = [56,90,135,300,450,600,1200,4000];
			var bufArray:Array = [5,4,3,2,2,2,1,0.5];
			
			for( var i:int = 0; i < bwArray.length; i++)
			{	
				var bwVar:Number = Number(bwArray[i] );
				if( bwVar <= _bandwidth )
				{
					tempBandwidth = bwVar;
					buffer = Number(bufArray[i]);
				}
			}
		}
		
		private function loadVideoFromJS():void
		{
			var params:Array;
			if (currentAssetId == 0)
				params = [_JSAPIFuncName,"ebMovie" + currentAssetId,muteOnVideoStart,volume,buffer,"ebMovie" + _videoUrl,true];
			else	
				params = [_JSAPIFuncName,"ebMovie" + currentAssetId,muteOnVideoStart,volume,buffer,"ebMovie" + currentAssetId,true];
			EBBase.handleCommand("ebVideoLoad", params.join(","));
		}
		
		/** @private
		 *
		 * Handles the NetStream onMetaData event and dispatches it. We also check what the length was in the FLV, and dispatch an error if it needs to be set.
		 **/
		public function onMetaData( infoObject:Object ):void
		{
			var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.METADATA_RECEIVED,infoObject);
			dispatchEvent(ev);
			
			_invokeHandler("MetaData",infoObject);
			
			_videoWidth = infoObject["width"];
			_videoHeight = infoObject["height"];
			
			_setVideoSize();
			
			// Ensure that the duration is present
			if( infoObject["duration"] != undefined )
			{
				var _videoLength:Number = infoObject["duration"];
				
				// Only accept lengths from FLV metadata that are longer than 1 second, but shorter than 1 day
				if( _videoLength > 1 && _videoLength < 86400 )
				{
					length = _videoLength;
					return;
				}
			}
			
			Tracer.debugTrace("[Info] Video Duration from Metadata Invalid -- Please set manually",1);
		}
		
		/** @private
		 * 
		 * Handles the NetStream onPlayStatus event by doing absolutely nothing.
		 **/
		public function onPlayStatus( ...args ):void
		{
			// Prompty Ignore.. I don't think we use anything in here.
		}
		
		/** @private
		 *
		 * Handles the NetStream onXMPData event, and dispatches an EBMetadataEvent.XMPDATA_RECEIVED event when called. 
		 **/
		public function onXMPData(infoObject:Object):void
		{
			var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.XMPDATA_RECEIVED,infoObject);
			dispatchEvent(ev);
		}
		
		/** @private
		 * 
		 * Handles the NetStream onCuePoint event, and dispatches an EBMetadataEvent.CUE_POINT event when called. 
		 **/
		public function onCuePoint( event:Object ):void
		{
			event.isRuntime = false;
			var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.CUE_POINT, event);
			dispatchEvent(ev);
			
			_invokeHandler("CuePoint",event);
		}
		
		/** @private
		 * 
		 * Handles the NetStream onLastSecond event by doing absolutely nothing
		 */
		public function onLastSecond( ...args ):void
		{
			// Prompty Ignore.. I don't think we use anything in here.
		}
		
		/**
		 * Sets the video size based on the displayMode parameter
		 */
		private function _setVideoSize():void
		{			
			if (isFullScreen || EBBase._stage != null && EBBase._stage.displayState == StageDisplayState.FULL_SCREEN) return;	
			
			if(isPlaying)
			{
				width = _w;
				height = _h;
			}
			
			//size difference between the component and the video
			var widthDiff:Number = (_videoWidth - _w);
			var heightDiff:Number = (_videoHeight - _h);
			
			//the desired width and height (scale wasn't take into account)
			var desiredHeight:Number = _videoHeight;
			var desiredWidth:Number = _videoWidth;
			
			//fit component size or component size is smaller than video size
			if(displayMode == 0 || (displayMode == 2 && ((widthDiff > 0) || (heightDiff > 0))))
			{
				// maintain the video aspect ratio
				// Note: _width and _height are the "real" size of the component
				// even if it was scaled, and not the original size.
				// i.e., if the component size by defualt is 300x235 and it was
				// scaled by 200%, _width = 600 and _height = 235.
				var scale:Number = Math.min( _w / _videoWidth, _h / _videoHeight );
				
				//the desired width and height (scale wasn't take into account)
				desiredHeight = scale * _videoHeight;
				desiredWidth = scale * _videoWidth;
				
				//the desired width and height (scale wasn't take into account)
				_video.height = desiredHeight/scaleY;
				_video.width = desiredWidth/scaleX;
			}
			else if (displayMode == 2) // regular size
			{
				_video.height = _videoHeight/scaleY;
				_video.width = _videoWidth/scaleX;
			}
			else if (displayMode == 1){
				_video.height = _h/scaleY;
				_video.width = _w/scaleX;
			}
			
			//center the video
			if(displayMode != 1){
				var xPos:Number = (_w - desiredWidth)/2;
				var yPos:Number = (_h - desiredHeight)/2;
				video.x = xPos/scaleX;
				video.y = yPos/scaleY;
			}
		}
		
		private function stream_Status( status:NetStatusEvent ):void
		{
			var code:String = status.info.code;
			var evInfo:Object = getEventInfo();
			var ev:EBVideoEvent;

			Tracer.debugTrace("Stream Status: " + code, 2);	
			
			switch( code )
			{
				case "NetStream.Play.Start":
				{		
					/// Return in case of scrubbar is dragged
					if( _isPausedForScrubbing )
						return;
					trackInitialized = true;
					
					volume = _volume;
					
										
					isPlaying = true;
					isPausedOnLastFrame = false;
					_netstreamStop = false;
					ns_isStopped = false;
		
					if(time == 0){
						this._startVideoTimer();
						
						_isBuffering = true;
						
						ev = new EBVideoEvent(EBVideoEvent.MOVIE_START,evInfo);
						dispatchEvent(ev);
					}
					
					dispatchEvent(new EBVideoEvent(EBVideoEvent.PLAYBACK_START,evInfo));
					
					break;
				}
				
				case "NetStream.Buffer.Full":
				{					
					_isBufferEmpty = false;
					_isBufferFlushed = false;
					
					if (_isBuffering)
					{
						_isBuffering = false;
					
						ev = new EBVideoEvent(EBVideoEvent.BUFFER_LOADED,evInfo);
						dispatchEvent(ev);
					}
					
					_invokeHandler("BufferLoaded");
					
					break;
				}
				
				case "NetStream.Buffer.Empty":
				{
					_isBufferEmpty = true;
					
					break;
				}
				
				case "NetStream.Play.Stop":
				{
					ns_isStopped = true;
					
					// Don't do anything here
					break;
				}
				
				case "NetStream.Play.StreamNotFound":
				{
					var evErr:EBErrorEvent = new EBErrorEvent(EBErrorEvent.ERROR,"Video Not Found");
					dispatchEvent(evErr);
					
					isStopped = true;
					
					break;
				}
				
				case "NetStream.Seek.Notify":
				{
					ev = new EBVideoEvent(EBVideoEvent.PLAY_PROGRESS,evInfo);
					dispatchEvent(ev);
					
					break;
				}
				
				case "NetStream.Buffer.Flush":
				{
					_isBuffering = false;
					_isBufferFlushed = true;
					if(!isStreaming) _isBufferEmpty = true;
					break;
				}
				
			}
			
			if(_isBufferEmpty && _isBufferFlushed && ns_isStopped && percentViewed > 0)
			{
				Tracer.debugTrace("Buffer Stopped Empty and Flushed. Dispatching endOfVideo.",4);
				length = time;
			}
		}
		
		/**
		 * Reports progress -- name required by FileReaderWriter
		 */
		private function _reportPlayProgress(nPlayProgress:Number):void
		{
			Tracer.debugTrace("VideoLoader: _reportPlayProgress("+nPlayProgress+")",4);
			
			var interactionName:String = "";
			
			switch(nPlayProgress){
				case 0:
					interactionName = "ebVideoStarted";
					break;
				case 25:
					interactionName = "eb25Per_Played";
					break;
				case 50:
					interactionName = "eb50Per_Played";
					break;
				case 75:
					interactionName = "eb75Per_Played";
					break;
				case 100:
					interactionName = "ebVideoFullPlay";
					break;
					
			}
			if (currentAssetId == 0)
				EBBase.handleCommand("ebVideoInteraction","'" + interactionName + "','" + _videoUrl +"'");
			else
				EBBase.handleCommand("ebVideoInteraction","'" + interactionName + "','" + currentAssetId +"'");
		}
		
		private function _invokeHandler(evt:String,arg:* = null):void
		{
			var instName:String = name;
			
			if(parent is IVideoScreen){
				instName = parent.name;
			}
			
			var f:Function = EBBase.currentAssetRef[instName + "_On" + evt] as Function;
			
			if(f != null)
			{
				arg != null ? f(arg) : f();
			}
		}
		
		/**
		 * Creates the event object used by EBVideoEvent. We currently only populate PLAY_PROGRESS and LOAD_PROGRESS
		 */
		private function getEventInfo():Object
		{
			return {
				ebPlayProgress: percentViewed,
				ebLoadProgress: bytesLoaded/bytesTotal
			};
		}
		
		/**
		 * Main handler -- dispatches progress, etc. This is ran every 150ms, so if you need to do anything on a regular basis, perform the function here.
		 */
		private function trackVideo():void
		{
			// Only continue if we are in the correct state
			if(!trackInitialized || !_stream || !isPlaying) return;
			
			// If VideoScreen is no longer present on stage, close the connection to prevent audio blip issues
			if(!checkIfVideoIsCurrentOrAlive())
			{
				KillConnection();
				return;
			}
						
			// Reset runtime cuepoint handlers if we went backwards in time
			if( currentVideoTime > time ) _resetCustomEvents();
			currentVideoTime = time;

			// Calculate Percent Viewed
			percentViewed = (currentVideoTime / length ) * 100;
			
			if(currentVideoTime > 0){
				_isBuffering = false;
			}
			
			///new implementation of updateDuration algorithm
			if(!_isBuffering) // in case of Buffering (streaming mode) we shouldn't update timer for duration calculations 
				tUpdateDuration();
			
			// Create objects for EBVideoEvent's that we dispatch
			var evInfo:Object = getEventInfo();
			var ev:EBVideoEvent = null;
			
			// If we have runtime cuepoint handlers, call them
			if( videoEvents.length > 0 ) customVideoEvents();
			
			// Dispatch Play Progress Event
			ev = new EBVideoEvent(EBVideoEvent.PLAY_PROGRESS,evInfo);
			dispatchEvent(ev);
			
			_invokeHandler("PlayProgress",percentViewed);
			
			// If we are still loading, calculate load progress and dispatch event
			if(bytesLoaded < bytesTotal) _hasFullyLoaded = false;
			
			if(bytesTotal > 0 && !_hasFullyLoaded){
				ev = new EBVideoEvent(EBVideoEvent.LOAD_PROGRESS,evInfo);
				dispatchEvent(ev);
				
				_invokeHandler("LoadProgress",evInfo.ebLoadProgress);
			}
			
			// If we have played more than 0% of the video, and we crossed the next percent threshold to track progress, then track progress
			if(percentViewed > 0 && percentViewed >= trackThreshold && trackThreshold <= 100 )
			{
				_reportPlayProgress(trackThreshold);
				trackThreshold += 25; // MediaMind tracks in 25% intervals
			}
			
			// Calculate End Of Video
			var isEndOfVideo:Boolean = false;
			if(( percentViewed >= 100 && trackThreshold > 100) || (!isStreaming && ns_isStopped == true)) ///ns_isStopped can be used only in progressive mode since in streaming mode the stream sometimes stopped in order to wait for the next chunk ("NetStream.Play.Stop")
			{
				isEndOfVideo = true;
				trackThreshold = 125;
				percentViewed = 100;
			}
		
			if(isEndOfVideo)
			{			
				if ( pauseOnLastFrame ){
					pause();
					isPausedOnLastFrame = true;
				}
				else if( nOnMovieEnd != 1 ) // 1=Replay
				{
					stop();
					clear();
					// Do some cleanup of statuses
					doPlayAudio = false;
				}
				
				if( nOnMovieEnd != 1 ) // 1=Replay
				{
					ev = new EBVideoEvent(EBVideoEvent.MOVIE_END,evInfo);
					dispatchEvent(ev);
				}
				
				// Handle "On Movie End" events from component inspector
				switch(nOnMovieEnd){
					case 0: // None
						//if in fs and this is a standAlone player, close fs
						fSClose();
						break;
					case 1: // Replay
						if(isStreaming){
							nOnMovieEnd = 0;
						}
						replay(false);
						return;
						break;
					case 3: // Goto Frame
						fSClose();
						var root_mc:MovieClip = EBBase.currentAssetRef as MovieClip;
						if(root_mc != null){
							root_mc.gotoAndPlay(nGoToFrame);
						} else {
							var ebError:EBErrorEvent = new EBErrorEvent(EBErrorEvent.ERROR,"Root is not a MovieClip");
							dispatchEvent(ebError);
						}
						break;
					case 4: // Custom
						_invokeHandler("MovieEnd");
						break;
					case 5: // Close
						EBBase.CloseAd("Auto");
						break;
				}
			}
		}
		///t for new implementation of updateDuration algorithm
		private function tUpdateDuration():void
		{
			if (currentAssetId == _currentAssetIdForTimer)
			{
				if(_isWaitingForSeek && time != lastSavedTime)
				{
					lastSavedTime = time;
					_isWaitingForSeek = false;
				}
				
				if ( !_isWaitingForSeek )
				{
					var strTimer:String = getInteractionPrefix() + "VideoPlayDuration";
					var tDelta:int = (time - lastSavedTime) * 1000;
					
					if( tDelta > 0 )
						EBBase.handleCommand("ebtUpdateVideoDuration","'" + strTimer + "','" + tDelta.toString() + "','" + _currentAssetIdForTimer + "'");
					lastSavedTime = time;
				}
			}
		}
		
		/**
		 * Dispatches runtime cuepoints
		 */
		private function customVideoEvents():void
		{
			// Round current time to nearest 10th of a second
			var currentTime:Number = (Math.round( time * 100))/100;
			
			var i:int;
			
			// Initialize videoEventCalled array -- make it same length as video event time and default value to "false"
			if( videoEventCalled.length != videoEventTimes.length )
				for( i = 0; i < videoEventTimes.length; i++) videoEventCalled[i] = false;

			// Loop through events and see if any should be fired
			for( i = 0; i < videoEventTimes.length; i++ )
			{
				// If current time has passed a time in the array, and the asset is the asset we are playing, and it has not been called, call it
				if(( videoEventTimes[i] < currentTime ) && ( videoFileID[i] == currentAssetId ) && videoEventCalled[i] == false )
				{
					videoEventCalled[i] = true;
					
					// Dispatch a EBMetadataEvent.CUE_POINT event
					var cpInfo:Object = { name: videoEvents[i], time: currentTime, type: "event", parameters: null, isRuntime: true };
					var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.CUE_POINT, cpInfo);
					dispatchEvent(ev);
					
					_invokeHandler("CuePoint",cpInfo);
					
					break;
				}
			}
		}
		
		/**
		 * Reset the runtime cuepoint handlers
		 */
		private function _resetCustomEvents():void
		{					
			for( var i:int = 0; i < videoEventTimes.length; i++)
			{
				if ( videoEventTimes[i] > time) videoEventCalled[i] = false; 
			}
		}
		
		/**
		 * Cleanup method for when video is stopped
		 */
		private function resetReporting():void
		{
			percentViewed = 0;
			trackThreshold = 0;
			currentVideoTime = 0;
			lastSavedTime = 0;
			ns_isStopped = false;
			for( var i:int = 0; i < videoEventCalled.length; i++) videoEventCalled[i] = false;
		}
		
		/** @private */
		public override function toString():String
		{
			return this.name;
		}
		
		/**
		 * Clears the video
		 */
		public function clear():void
		{
			_video.clear();
		}
		
		/**
		 * Loads the given asset by id
		 */
		private function _loadAsset( newAssetId:int ):void
		{
			// Default asset means current asset			
			if( newAssetId == -1 ) newAssetId = currentAssetId;
			_currentAssetId = newAssetId;
			
			// Offline
			if(typeof(EBBase.urlParams.ebDomain) == "undefined")
			{
				// Configure Offline
				_videoUrl = offlineVideoFile;
				initNetConnection(null);
				if(doPlayVideo) _startPlay();
			} else {
				// Setup NetConnection and call ebVideoLoad
				initNetConnection(loadVideoFromJS);
			}	
		}
		
		/**
		 * Invoked by JavaScript -- provides URL for the requested asset
		 */
		private function loadProxy(urlInfo:String, params:String):void
		{
			var url:String = splitUrlInfo(urlInfo);
		
			if(isStreaming){
				// If we are streaming, we need to convert the HTTP URL to an RTMP URL
				var _file:String = url.substr(url.lastIndexOf("/")+1);
				var _ebStreamVirtualPath:String = EBBase.urlParams.ebStreamVirtualPath;
				
				if( EBBase.urlParams.isInStream == true && _ebStreamVirtualPath.lastIndexOf("/") != _ebStreamVirtualPath.length )
					_ebStreamVirtualPath = _ebStreamVirtualPath + "/";
				
				_videoUrl = _ebStreamVirtualPath + _file.substring(0,_file.length-4);
			} else {
				_videoUrl = url;
			}
			
			if(doPlayVideo) _startPlay();
		}
		
		private function splitUrlInfo(urlInfo:String):String
		{
			var info:Array = urlInfo.split("::");
			return info[0];
		}
		
		/**
		 * Play the selected asset
		 */
		private function _startPlay():void
		{	
			//ER Chrome 27 fix (replay, stop-play, double loading)
			if(isPlaying) return;
			
			var e:Error = new Error();
			// send unmuted if video was with Start with sound on checked.
			// should be send only when video starts playing.
			if(!muteOnVideoStart)
			{				
				_reportUnmuted();
			}
			
			if(setupStream())
			{
				Tracer.debugTrace("Playing URL: " + videoUrl);
				_stream.bufferTime = buffer;
				//setTimeout(_stream.play, 2,  videoUrl, 0 );//mf// this is to fix an ioError that thrown, this will delay the play funciton for a bit until the load is done
				if( videoUrl == null) return; //ER Chrome 27 fix (replay, stop-play, double loading) 
				_stream.play( videoUrl, 0 );
				isPlaying = true;
				isPausedOnLastFrame = false;
			} else doPlayVideo = true;
		}
		
		/**
		 * Replays the video from the beginning, and optionally, turns the audio on
		 * 
		 * @param turnAudioOn:Boolean Turns the audio on optionally
		 */
		public function replay( turnAudioOn:Boolean = true ):void
		{
			resetReporting();
			
			if( !isStopped )
			{
				if( turnAudioOn ) unmute();
				if(isStreaming) doPlayAudio = turnAudioOn;
				seek( 0 );
			} else {
				doPlayAudio = turnAudioOn;
			}
			//ER Chrome 27 fix (replay, stop-play, double loading)
			if (_videoUrl != "" && _stream != null)
				_startPlay();
			else
				loadAndPlay();
		}
		
		/** Turns the audio on */
		public function unmute():void
		{
			if(volume > 0)
			{
				dispatchAudioEvent();
				return;
			}
			
			if(_prevVolume == 0) volume = 100;
			else volume = _prevVolume;
			
			_prevVolume = 0;
			
			_reportUnmuted();		
						
		}
		
		/** Turns the audio off */
		public function mute():void
		{
			if(volume == 0)
			{
				dispatchAudioEvent();
				return;
			}
			
			_prevVolume = volume;
			volume = 0;
		}
		
		/** Toggles the audio's muted state */
		public function audioToggle():void
		{
			if( isMuted ) unmute();
			else mute();
		}
		
		/** Toggles the video's play/pause state */
		public function videoToggle():void
		{
			if(isPlaying)
				pause();
			else 
				play();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#seek()
		 */
		public function seek( timeInSecs:Number ):void
		{	
			if(isStopped) return;
			
			var _paused:Boolean = isPaused;
			
			if( timeInSecs >= length - 0.5 ) timeInSecs = length - 0.5;
			if( timeInSecs < 0 ) timeInSecs = 0;
			
			if(timeInSecs == 0){
				resetReporting();
			}
			
			if (isStreaming && _paused) 
				_isPausedForScrubbing = true;
			_stream.seek( timeInSecs );
			var evtInfo:Object = getEventInfo();
			var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.MOVIE_SEEK,evtInfo);
			dispatchEvent(ev);
			
			isPaused = _paused;

			_isWaitingForSeek = true;
			lastSavedTime = time; /// lock tUpdateDuration while seeking
		}
		
		/**
		 * Tracks user interaction with the video
		 * 
		 * @param interactionName:String name of interaction to track
		 * 
		 */
		public function track(interactionName:String, isAuto:Boolean = false):void
		{	
			if(interactionName.indexOf("eb") != 0){
				interactionName = getInteractionPrefix() + interactionName;
			}
			if (currentAssetId == 0)
				EBBase.handleCommand("ebVideoInteraction","'" + interactionName + "','" + _videoUrl +"'");
			else
				EBBase.handleCommand("ebVideoInteraction","'" + interactionName + "','" + currentAssetId + "'");
			
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.TRACK);
			e.isAuto = isAuto;
			e.label = interactionName;
			
			EBBase.dispatchEvent(e); 
		}
		
		/** @private */
		public function get volume():int
		{
			if( _stream != null && connection.connected && !isStopped) 
			{
				if(_volume == -1) 
					return 0;
				else
					_volume = _stream.soundTransform.volume * 100;
			}
			
			return _volume;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#volume
		 */
		public function set volume( value:int ):void
		{
			if(_volume == -1)
				_volume = 0;
			else
				_volume = value;
			
			if( _stream != null && connection.connected )
			{
				var soundTransform:SoundTransform = new SoundTransform();
				soundTransform.volume = (_volume / 100 ); // SoundTransform is 0..1, we are 0..100
				_stream.soundTransform = soundTransform;
				
				dispatchAudioEvent();
				
			} else if(_volume > 0) doPlayAudio = true;
			
			
			
			if(_volume > 0){
				_prevVolume = _volume;
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isMuted
		 */
		public function get isMuted():Boolean
		{
			if(volume == 0) return true;
			else return false;
		}
		
		private function dispatchAudioEvent():void
		{
			dispatchEvent( new EBAudioStateEvent(EBAudioStateEvent.AUDIOSTATE_CHANGE, isMuted, volume) );
		}
		
		/**
		 * @private
		 */
		public function get length():Number
		{
			return _length;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#length
		 */
		public function set length(value:Number):void
		{
			_length = value;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#time
		 */
		public function get time():Number
		{
			if( _stream == null ) return 0;
			else return _stream.time;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#bytesTotal
		 */
		public function get bytesTotal():Number
		{
			if( _stream == null ) return 0;
			else return _stream.bytesTotal;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#bytesLoaded
		 */
		public function get bytesLoaded():Number
		{
			if( _stream == null ) return 0;
			else return _stream.bytesLoaded;
		}
		
		private function playbackChange_dispatch():void
		{
			var status:String;
			
			if(isPlaying) status = "Playing";
			if(isPaused) status = "Paused";
			if(isStopped) status = "Stopped";
			
			_invokeHandler("StatusChanged",status);
			
			dispatchEvent( new EBVideoStateEvent(EBVideoStateEvent.VIDEOSTATE_CHANGE, isPlaying, isPaused, isStopped, isFullScreen) );
		}
		
		/** @private */
		public function set isStopped( value:Boolean ):void
		{
			_isStopped = value;
			
			if( value )
			{
				_isPaused = false;
				_isPlaying = false;
				
				if(_streamIdle) clearTimeout(_streamIdle);
				
				// Setup timeout to close the connection if we don't replay before STREAM_IDLE_TIME seconds is up.
				_streamIdle = setTimeout(KillConnection,STREAM_IDLE_TIME * 1000);
				
				_endVideoTimer();
			}
			

			playbackChange_dispatch();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isStopped
		 */
		public function get isStopped():Boolean
		{
			return _isStopped;
		}
		
		/** @private */
		public function set isPaused( value:Boolean ):void
		{
			_isPaused = value;
			
			if( value )
			{
				_isStopped = false;
				_isPlaying = false;
				
				if(_streamIdle) clearTimeout(_streamIdle);
				_streamIdle = setTimeout(KillConnection,STREAM_IDLE_TIME * 1000);
			}
				
			playbackChange_dispatch();
		}
		
		/**
		 * Kill the NetConnection -- called if we've been idle or if we were removed from the stage
		 */
		private function KillConnection():void
		{
			if(isStreaming)
			{
				clearTimeout(_streamIdle);
				if(checkIfVideoIsCurrentOrAlive()) Tracer.debugTrace("[Info] Refreshing NetConnection after " + STREAM_IDLE_TIME + "s pause",4);
				if(!isStopped) stop();
				streamHelper.killAllConnections();
			}
		}
		
		/**
		 * Checks to see if the VideoScreen is still on stage
		 */
		private function checkIfVideoIsCurrentOrAlive():Boolean
		{
			var isAlive:Boolean = true;
			if(stage == null || parent == null) isAlive = false;
			return isAlive;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isPaused
		 */
		public function get isPaused():Boolean
		{
			return _isPaused;	
		}
		
		/** @private */
		public function set isPlaying( value:Boolean ):void
		{
			_isPlaying = value;
			
			if( value )
			{
				_isPausedForScrubbing = false;
				_isPaused = false;
				_isStopped = false;
				_isPausedOnLastFrame = false;
				if(_streamIdle) clearTimeout(_streamIdle);
				EBBase.handleCommand("ebVideoActiveMode", this._JSAPIFuncName + "," + true);
			}
			
			playbackChange_dispatch();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isPlaying
		 */
		public function get isPlaying():Boolean
		{
			return _isPlaying;	
		}
		
		/**
		 * The bandwidth that was detected that is used in determining which video to play, and the default buffer length.
		 */
		public function set bandwidth( value:int ):void
		{
			_bandwidth = value;
			setupBuffer();
		}
		
		/** @private */
		public function get bandwidth():int
		{
			return _bandwidth;
		}
		
		public function set smoothing(value:Boolean):void
		{
			if(_video != null)
				_video.smoothing = value;
		}
		
		public function get smoothing():Boolean
		{
			if(_video == null) return false;
			return _video.smoothing;
		}
		
		// MEDIAMIND API
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#load()
		 */
		public function load(movieNum:Number = -1):void
		{
			_skipInitVideoUrl = true;
			doPlayVideo = false;
			
			// Is video default?
			if( movieNum == -1 )
			{
				// use nVideoFileNum (from component inspector) 
				if( currentAssetId == -1 ) movieNum = nVideoFileNum;
				else movieNum = currentAssetId; // else use last played video
			}
			
			// Stop only if the proposed video is different from current video
			if( movieNum != currentAssetId ) stop();
			
			// If we are currently playing, that means we proposed the playing video
			if(isPlaying) return;
			
			// if we are not paused, and the proposed video is internal, load it
			if(!isPaused && movieNum != 0){
				_loadAsset(movieNum);
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#loadAndPlay()
		 */
		public function loadAndPlay(movieNum:Number = -1):void
		{
			if(initialized){
			// propose new video
			//initMembers();
			load(movieNum);
			
			if(isPaused){ // if paused.. resume
				_stream.resume();
				isPlaying = true;
				isPausedOnLastFrame = false;
				return;
			}
			
			doPlayVideo = true;
			
		
				_startPlay();
			}
			// if for some reason video was not yet initialized, we will wait and call this function again,
			// no more than 3 times, otherwise we let the component to fail, probably some serious problem.
			else if (waitForInit < 3) {
				setTimeout( loadAndPlay, 1, movieNum );
				++waitForInit;
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#loadExt()
		 */
		public function loadExt(movieURL:String):void
		{
			_skipInitVideoUrl = true;
			
			_currentAssetId = 0;
			_currentAssetIdForTimer = -1; //reset _currentAssetIdForTimer;
			doPlayVideo = false;
			_isExternalVideo = true;
			
			if (movieURL.toLowerCase().indexOf("http://") == 0) //progressive http url
			{
				setFMS(null);
				_videoUrl = movieURL;
			}
			else //streaming rtmp url
			{
				var urlHelper:VideoStreamURL = new VideoStreamURL(_externalFMS, movieURL);
				
				setFMS(urlHelper.vsFMS);
				_videoUrl = urlHelper.vsFileName;
			}
			initNetConnection(null);
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#loadAndPlayExt()
		 */
		public function loadAndPlayExt(movieURL:String):void
		{
			//initMembers();
			if(_stream != null)
				stop();
			loadExt(movieURL);
			doPlayVideo = true;
			
			if(initialized){
				_startPlay();
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#play()
		 */
		public function play():void
		{
			if(isPaused){ // resume if paused
				_stream.resume();
				isPlaying = true;
				isPausedOnLastFrame = false;
			} else {
				if(currentAssetId == 0){ // load and play current external asset if stopped
					loadAndPlayExt(videoUrl);
				} else {
					loadAndPlay(); // load and play current asset if stopped
				}
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#pause()
		 */
		public function pause():void
		{
			if(!isPlaying) return;
			
			_stream.pause();
			isPaused = true;
		}
		
		///Pauses the video while video scrubbar is dragged
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#pauseForSlider()
		 */
		public function pauseForSlider():void
		{
			_isPausedForScrubbing = true;
			_stream.pause();
		}
		
		///Resumes the video after the video scrubbar has been released
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#playAfterPauseForSlider()
		 */
		public function playAfterPauseForSlider():void
		{
			_isPausedForScrubbing = false;
			_stream.resume();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#stop()
		 */
		public function stop():void
		{
			if( isStopped ) return;
			resetReporting();
			if( _stream != null ) 
			{
				_stream.soundTransform = new SoundTransform(0);
				_stream.close();
			}
			isStopped = true;
			dispatchEvent(new EBVideoEvent(EBVideoEvent.PLAYBACK_STOP, getEventInfo()));
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#stopAndClear()
		 */
		public function stopAndClear():void
		{
			stop();
			clear();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#setFullScreen()
		 */
		public function setFullScreen(fullScreen:Boolean):void
		{
			if (EBBase.isInstream()) return;
			if (fullScreen && EBBase._stage.displayState == StageDisplayState.NORMAL ) 
				fSOpen();
			else if(!fullScreen && EBBase._stage.displayState == StageDisplayState.FULL_SCREEN)
				fSClose();
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#setFMS()
		 */
		public function setFMS(strFMSURL:String):void
		{
			_externalFMS = strFMSURL;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#setSize()
		 */
		public function setSize(width:Number, height:Number):void
		{
			this.width = _w = width;
			this.height = _h = height;
			
			if(_video != null){
				_setVideoSize();
			}
		}
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#netStream
		 */
		public function get netStream():NetStream
		{
			return _stream;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#video
		 */
		public function get video():Video
		{
			return _video;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isFullScreen
		 */
		public function get isFullScreen():Boolean
		{
			return _isFullScreen;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isBuffering
		 */
		public function get isBuffering():Boolean
		{
			return _isBuffering;
		}
		
		/**
		 * Returns the prefix ebFS when in fullscreen, and eb when not in fullscreen
		 */
		private function getInteractionPrefix():String
		{
			if(_isFullScreen) return "ebFS";
			return "eb";
		}
		
		// VIDEO TIMERS
		
		/**
		 * Starts the video timer for tracking
		 */
		private function _startVideoTimer():void
		{
			var strTimer:String = getInteractionPrefix() + "VideoPlayDuration";
			if (currentAssetId == 0)
				EBBase.handleCommand("ebtStartVideo","'" + strTimer + "','" + _videoUrl + "'");				
			else
				EBBase.handleCommand("ebtStartVideo","'" + strTimer + "','" + currentAssetId + "'");
			_currentAssetIdForTimer = currentAssetId;
		}
		
		/**
		 * Ends the video timer for tracking
		 */
		private function _endVideoTimer():void
		{
			if( _currentAssetIdForTimer != -1 )
			{	
				var strTimer:String = getInteractionPrefix() + "VideoPlayDuration";
				EBBase.handleCommand("ebtStopVideo","'" + strTimer + "','" + _currentAssetIdForTimer + "'");
			}
		}
		
		// MEDIAMIND JS HANDLERS
		
		private function _fullScreenHandler(event:FullScreenEvent):void
		{
			if(!event.fullScreen){
				fSClose(0);
			}
		}		
		//===========================================
		//	FS Functions - All function relating to fs handling
		//============================================
		
		//mf/
		/* 
		 * This function draws an invisible rectangle around the player, this preserves the aspect ration so the player diregards it scale when going to FS
		 */
        private function drawFSrectangle():void 
		{ 
			this.graphics.lineStyle(1, 0,0 );
			this.graphics.moveTo(0, 0);
			this.graphics.lineTo(this.width / this.scaleX, 0);
			this.graphics.lineTo(this.width / this.scaleX, this.height / this.scaleY);
			this.graphics.lineTo(0, this.height/this.scaleY);
			this.graphics.lineTo(0, 0);
		}
		
        
		/**
		 * @private
		 * 
		 * Called from setFullScreen() and from the JS proxy to enter full screen
		 */
		public function fSOpen():void
		{
			
			if(_stream == null || !connection.connected || _isFullScreen == true || EBBase.isInstream()) return;				
					
			storeMyCoor();						
			fSOpenInit();				
					
			Utils.scaleToContainer(Utils.EXACT_FIT, this, true);	//fit the videoscreen to fit exacly on stage
			
			this.x = 0; this.y = 0;			//position to top left
			this.parent.setChildIndex(this, this.parent.numChildren - 1);
			
			EBBase._stage.scaleMode = StageScaleMode.EXACT_FIT;
			EBBase._stage.align = StageAlign.TOP_LEFT;
			EBBase._stage.displayState = StageDisplayState.FULL_SCREEN;								
			
			initBG();//place backround
		}		
			
		//mf/
		 /* @private
		 * 
		 * Called from videoScreen container before going to full screen
		 */
		public function fSOpenInit():void{			
			if (EBBase.isInstream()) return;
			// Pause Before Entering FullScreen
			if(isPlaying){
				_stream.pause();
			}
			
			_endVideoTimer();
			
			var playProgress:Number = Math.floor(time/25);
			var unmuteReported:Boolean = false;
			
			//the values for the fscommand have no meaning (are stayed only for backward compatability) and therefore are set to default values instead of calculate it.
			var param:String = _JSAPIFuncName + "," + 0 + "," + false + "," + 0 + "," + playProgress + "," + unmuteReported;
			EBBase.handleCommand("ebVideoFSOpen",param);
			
			_isFullScreen = true;
			EBBase._stage.addEventListener(FullScreenEvent.FULL_SCREEN, _fullScreenHandler);
			
			playbackChange_dispatch();
			
			// Now.. resume
			_startVideoTimer();
			
			if(isPlaying){
				_stream.resume();
			}		
			}
		//mf/
		 /* @private
		 * 
		 * Set a backround color on video and place behind video
		 */		
		public function initBG(color:int = -1):void
		{
			if (!triggerFsBg || EBBase.isInstream()) return;
			
			if (color != -1)//if no color requested, set to defualt (black)
				default_bg_color = color;
				
			bgshape = new Sprite();
			bgshape.graphics.beginFill(default_bg_color);
			bgshape.graphics.drawRect(0, 0, Capabilities.screenResolutionX, Capabilities.screenResolutionY);			
			this.parent.addChildAt(bgshape, this.parent.getChildIndex(this));	
			
		}
		//mf/
		 /* @private
		 * 
		 * Remove video bg
		 */		
		public function clearBG():void {
			if (bgshape != null && this.parent.contains(bgshape))
				this.parent.removeChild(bgshape);
				
			bgshape = null;
		
		}
		//mf/
		 /* @private
		 * 
		 * Change bg color on the fly
		 */		
		private function changeBGColor(color:uint) :void
		{
			if (bgshape == null) return;
			
			bgshape.graphics.beginFill(color);
			bgshape.graphics.drawRect(0,0,stage.stageWidth, stage.stageHeight);
		}
		
		//mf/
		 /* @private
		 * 
		 * Called from videoScreen container before going out of full screen
		 */
		public function fSCloseInit(nFullScreen:Number = 0):Boolean	{
			if (EBBase.isInstream()) return false;
			EBBase._stage.removeEventListener(FullScreenEvent.FULL_SCREEN, _fullScreenHandler);
			
			if(!_isFullScreen) return false;
			
			if(isPlaying){
				_stream.pause();
			}
			
			_endVideoTimer();
			
			_isFullScreen = false;			
			
			playbackChange_dispatch();		
				
			
			_startVideoTimer();
			
			if(isPlaying){
				_stream.resume();
			}
				
			if(nFullScreen == 1)
				EBBase.handleCommand("ebVideoFSAutoClose");
			else
				EBBase.handleCommand("ebVideoFSClose");
			return true;
		}
		 /* @private
		 * 
		 * Called from setFullScreen() and from the JS proxy to exit full screen
		 */
		public function fSClose(nFullScreen:Number = 0):void
		{
			if (!_isFullScreen || EBBase.isInstream())return;
			
			if (this.parent.hasOwnProperty("fsClose")) {		//if this is part of the video screen player component, trigger the parent fsClose and not this one						
				(this.parent as Object).fsClose(nFullScreen);						
				return;
			}
			//closing the full screen
			EBBase._stage.displayState = StageDisplayState.NORMAL;			
			
			fSCloseInit(nFullScreen);
			clearBG();//clear the bg image		
			reStoreMyCoor();//restore position
	
			
		}
			//mf/save current x,y, height & width position		
		private function storeMyCoor():void {
				
			this.saveXPosBeforeFS = this.x;
			this.saveYPosBeforeFS = this.y;
			this.saveWidthBeforeFS = this.width;
			this.saveHeightBeforeFS = this.height;	
			this.saveIndexBeforeFS = this.parent.getChildIndex(this);
		}
		
		//mf/save current x,y, height & width position		
		private function reStoreMyCoor():void {
				
			//mf/return to previous x,y position
			this.width = this.saveWidthBeforeFS;
			this.height = this.saveHeightBeforeFS;			
			this.x = this.saveXPosBeforeFS;
			this.y = this.saveYPosBeforeFS;
			this.parent.setChildIndex(this, saveIndexBeforeFS);
		}		
		
		/**
		 * @private
		 * 
		 * This function handles the video activate and deactivate events from the JavaScript when streaming video is used.
		 * This method is called from the JavaScript
		 * 
		 * @param nActive:Number 0 - Deactivate, 1 - Activate
		 */
		public function activate(nActive:Number):void
		{
			if(_stream == null || !connection.connected) return;
			
			if(nActive == 0){
				if(isPlaying){ // Only pause if we are playing
					pause();
				}
			} else {
				if(isPaused){ // only play is we are paused
					play();
				}
			}
		}
		
		public function set pauseOnLastFrame(value:Boolean):void
		{
			if(value){
				nOnMovieEnd = 2;
			} else if (nOnMovieEnd == 2){
				nOnMovieEnd = 0;
			}
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#pauseOnLastFrame
		 */
		public function get pauseOnLastFrame():Boolean
		{
			return nOnMovieEnd == 2;
		}
		
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isPausedOnLastFrame
		 * this will not apply if current vidoe is not paused first
		 */
		public function set isPausedOnLastFrame(value:Boolean):void
		{
			if (value && !isPaused) return;
			
			_isPausedOnLastFrame = value;
		}
		
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#isPausedOnLastFrame
		 * * this will return flase if video is no paused regardless of previous setting
		 */
		public function get isPausedOnLastFrame():Boolean
		{	
			if (!isPaused)
				return false;
				
			return _isPausedOnLastFrame;
		}
		/** If using an additional asset, this represents the current asset id */
		public function get currentAssetId():int
		{
			return _currentAssetId;
		}
		
		/** The URL of the currently playing video file */
		public function get videoUrl():String
		{
			return _videoUrl;
		}
		
		/** Set behaviour according onClick attributes*/
		public function setOnClickBehaviour():void
		{		
			if(onClickArr.toString() != "0,0,0")
			{		
				addEventListener(MouseEvent.CLICK,_OnClickHandler);
				buttonMode = true;			
			}
		}
		
		///check for Local Preview / offline
		private function get isOffLine():Boolean
		{
			if ( _isOffLine == -1 )
			{
				if ((typeof (EBBase.urlParams.ebDomain) == "undefined") || ( (typeof (EBBase.urlParams.ebDomain) != "undefined") &&  EBBase.urlParams.ebDomain == "") )  
					_isOffLine = 1;
				else
					_isOffLine = 0;
			}
			return (_isOffLine == 1);
		}
	}
}