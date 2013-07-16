package eyeblaster.videoPlayer
{
	import eyeblaster.events.EBAudioStateEvent;
	import eyeblaster.events.EBBandwidthEvent;
	import eyeblaster.events.EBMetadataEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoStateEvent;
	import eyeblaster.events.EBNotificationEvent;
	import eyeblaster.videoPlayer.controls.Buffering;
	import eyeblaster.videoPlayer.controls.ControlBar;
	import eyeblaster.videoPlayer.core.Utils;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.display.StageDisplayState;
	import flash.geom.Point;

	public class VideoScreenPlayer extends Sprite implements IVideoScreen
	{
		[Inspectable]
		public var videoEvents:Array;
		[Inspectable]
		public var videoEventTimes:Array;
		[Inspectable]
		public var videoFileID:Array;
		
		[Inspectable(type=String)]
		public var offlineVideoFile:String;
		
		[Inspectable(type=Boolean,defaultValue=false)]
		public var fAutoPlay:Boolean = false;
		
		[Inspectable(type=Boolean,defaultValue=true)]
		public var muteOnVideoStart:Boolean = true;
		
		[Inspectable(enumeration="0,1,2" ,defaultValue=0, type=Number)]
		public var displayMode:Number = 0;
		
		[Inspectable (defaultValue=1, type=Number)]
		public var nVideoFileNum:Number = 1;
		
		[Inspectable(defaultValue="",type=String)]
		public var strExtVideoUrl:String = "";
		
		[Inspectable(defaultValue=1,type=Number)]
		public var nGoToFrame:Number = 1;
		
		[Inspectable(defaultValue=0,type=Number)]
		public var nOnMovieEnd:Number = 0;
		
		[Inspectable(defaultValue="0,0,0", type=Array)]
		public var onRolloverArr:Array = new Array(0,0,0);
		
		[Inspectable(defaultValue="1,0,0", type=Array)]
		public var onClickArr:Array =  new Array(1,0,0);
		
		[Inspectable(defaultValue=false,type=Boolean)]
		public var isStreaming:Boolean = false;
		
		/**
		 * The display mode of the controls
		 * 
		 * <ul>
		 * 	<li><strong>0<strong> - Always</li>
		 *  <li><strong>1</strong> - Only On Rollover of Control Bar or Video</li>
		 *  <li><strong>2</strong> - Only On Rollover of Control Bar's parent</li>
		 * </ul>
		 */
		[Inspectable(enumeration="0,1,2", defaultValue=0, type=Number)]
		public var nControlsMode:Number = 0;
		
		/**
		 * The controls to display. For each array index below, a value of 1 in that index means the
		 * given control will be displayed, while a value of 2 means the control will not be displayed.
		 * 
		 * The given controls <strong>MUST</strong> be in the library in order for this control to function
		 * 
		 * <ul>
		 * 	<li><strong>0</strong> - Video Toggle</li>
		 *  <li><strong>1</strong> - Stop</li>
		 *  <li><strong>2</strong> - Replay</li>
		 *  <li><strong>3</strong> - Rewind</li>
		 *  <li><strong>4</strong> - Fast Forward</li>
		 *  <li><strong>5</strong> - Progress Bar</li>
		 *  <li><strong>6</strong> - Audio Toggle</li>
		 *  <li><strong>7</strong> - Volume Slider</li>
		 *  <li><strong>8</strong> - Full Screen</li>
		 * </ul>
		 */
		[Inspectable(defaultValue="1, 1, 0, 0, 0, 1, 1, 1, 1")] 
		public var availCtrlArr:Array = [1, 1, 0, 0, 0, 1, 1, 1, 1];
		
		[Inspectable(defaultValue=true)]
		public var turnAudioOnReplay:Boolean = true;
		
		[Inspectable(defaultValue=true)]
		public var showBufferingAnimation:Boolean = true;
		
		private var _screen:VideoScreen;
		private var _controlBar:ControlBar;
		private var _buffer:Buffering;
		//mf//
		private var saveWidthBeforeFS: Number;
		private var saveHeightBeforeFS: Number;	
		private var saveXPosBeforeFS: Number;
		private var saveYPosBeforeFS: Number;
		private var saveIndexBeforeFS: Number;

		public var compName:String = "VideoScreenPlayer";	//The component name.
		
		public function VideoScreenPlayer()
		{
			_screen = getChildByName("screen") as VideoScreen;
			_buffer = getChildByName("buffer") as Buffering;
			_controlBar = getChildByName("controlBar") as ControlBar;
			
			addEventListener(Event.ADDED_TO_STAGE,OnAddedToStage);
		}
		
		private function OnAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,OnAddedToStage);
			EBVideoMgr.RegisterVideo(this);
		}
		
		//********************************************************
		// This function updates VideoScreen member 
		// with parameters that were setted to VideoScreenPlayer
		//********************************************************
		public function UpdateScreenParameters()
		{
			_screen.muteOnVideoStart = muteOnVideoStart;
			if (!muteOnVideoStart)
				_screen.unmute();
			_screen.fAutoPlay = fAutoPlay;	
			
			_screen.nOnMovieEnd = nOnMovieEnd; // Custom event handler			
			
			// set custom clicktrough handle
			_screen.onClickArr[0] = onClickArr[0];
			_screen.onClickArr[1] = onClickArr[1];
			_screen.onClickArr[2] = onClickArr[2];
			_screen.setOnClickBehaviour();
		}
		public function InitScreen():void
		{
			_screen.videoEvents = videoEvents;
			_screen.videoEventTimes = videoEventTimes;
			_screen.videoFileID = videoFileID;
			_screen.offlineVideoFile = offlineVideoFile;
			_screen.fAutoPlay = fAutoPlay;
			_screen.muteOnVideoStart = muteOnVideoStart;
			_screen.displayMode = displayMode;
			_screen.nVideoFileNum = nVideoFileNum;
			_screen.strExtVideoUrl = strExtVideoUrl;
			_screen.nGoToFrame = nGoToFrame;			
			_screen.nOnMovieEnd = nOnMovieEnd;
			_screen.onRolloverArr = onRolloverArr;
			_screen.onClickArr = onClickArr;
			_screen.isStreaming = isStreaming;
		}
		
		public function initialize(id:int):void
		{
			dispatchEvent(new Event(Event.INIT));
			
			
			// Set Properties for VideoScreen
			InitScreen();
			
			// Set Properties for ControlBar
			_controlBar.targetVideo = name;
			_controlBar.nControlsMode = nControlsMode;
			_controlBar.availCtrlArr = availCtrlArr;
			_controlBar.turnAudioOnReplay = turnAudioOnReplay;
			
			// Set Properties for Buffering
			_buffer.targetVideo = name;
			_buffer.visible = showBufferingAnimation;
			
			// Setup Event Listeners
			_screen.addEventListener(EBBandwidthEvent.BW_DETECT,_handleBWEvent);
			_screen.addEventListener(EBVideoEvent.PLAYBACK_STOP,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.PLAYBACK_START,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.MOVIE_START,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.MOVIE_END,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.MOVIE_SEEK,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.PLAY_PROGRESS,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.LOAD_PROGRESS,_handleVideoEvent);
			_screen.addEventListener(EBVideoEvent.BUFFER_LOADED,_handleVideoEvent);
			_screen.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE,_handleVideoStateEvent);
			_screen.addEventListener(EBAudioStateEvent.AUDIOSTATE_CHANGE,_handleAudioStateEvent);
			_screen.addEventListener(EBMetadataEvent.CUE_POINT,_handleMetadataEvent);
			_screen.addEventListener(EBMetadataEvent.METADATA_RECEIVED,_handleMetadataEvent);
			_screen.addEventListener(EBMetadataEvent.XMPDATA_RECEIVED, _handleMetadataEvent);
			
			// Initialize Controls
			_screen.initialize(id);
			_controlBar.initialize();
			_buffer.initialize();
		}
		
		private function _handleBWEvent(e:EBBandwidthEvent):void
		{
			var evt:EBBandwidthEvent = new EBBandwidthEvent(e.type,e.bandwidth,e.streamBandwidth);
			dispatchEvent(evt);
		}
		
		private function _handleVideoEvent(e:EBVideoEvent):void
		{
			var val:Object = { ebPlayProgress: e.playProgress, ebLoadProgress: e.loadProgress };
			
			var evt:EBVideoEvent = new EBVideoEvent(e.type,val);
			dispatchEvent(evt);
		}
		
		private function _handleVideoStateEvent(e:EBVideoStateEvent):void
		{
			var evt:EBVideoStateEvent = new EBVideoStateEvent(e.type, e.isPlaying, e.isPaused, e.isStopped, e.isFullScreen);
			dispatchEvent(evt);
		}
		
		private function _handleAudioStateEvent(e:EBAudioStateEvent):void
		{
			var evt:EBAudioStateEvent = new EBAudioStateEvent(e.type, e.isMuted, e.volume);
			dispatchEvent(evt);
		}
		
		private function _handleMetadataEvent(e:EBMetadataEvent):void
		{
			var evt:EBMetadataEvent = new EBMetadataEvent(e.type,e.info);
			dispatchEvent(evt);
		}
		
		// PUBLIC API		
		public function get bytesLoaded():Number
		{
			return _screen.bytesLoaded;
		}
		
		public function get bytesTotal():Number
		{
			return _screen.bytesTotal;
		}
		
		public function get isBuffering():Boolean
		{
			return _screen.isBuffering;
		}
		
		public function get isFullScreen():Boolean
		{
			return _screen.isFullScreen;
		}
		
		public function get isMuted():Boolean
		{
			return _screen.isMuted;
		}
		
		public function get isPaused():Boolean
		{
			return _screen.isPaused;
		}
		
		public function get isPlaying():Boolean
		{
			return _screen.isPlaying;
		}
		
		public function get isStopped():Boolean
		{
			return _screen.isStopped;
		}
		
		public function set length(value:Number):void
		{
			_screen.length = value;
		}
		
		public function get length():Number
		{
			return _screen.length;
		}
		
		public function get netStream():NetStream
		{
			return _screen.netStream;
		}
		
		public function set pauseOnLastFrame(value:Boolean):void
		{
			_screen.pauseOnLastFrame = value;
		}
		
		public function get pauseOnLastFrame():Boolean
		{
			return _screen.pauseOnLastFrame;
		}
		
		public function set isPausedOnLastFrame(value:Boolean):void
		{
			_screen.isPausedOnLastFrame = value;
		}
		
		public function get isPausedOnLastFrame():Boolean
		{
			return _screen.isPausedOnLastFrame;
		}
		
		public function get time():Number
		{
			return _screen.time;
		}
		
		public function get video():Video
		{
			return _screen.video;
		}
		
		public function set volume(value:int):void
		{
			_screen.volume = value;
		}
		
		public function get volume():int
		{
			return _screen.volume;	
		}
		
		public function audioToggle():void
		{
			_screen.audioToggle();
		}
		
		public function load(movieNum:Number = -1):void
		{
			_screen.load(movieNum);
		}
		
		public function loadAndPlay(movieNum:Number = -1):void
		{
			_screen.loadAndPlay(movieNum);
		}
		
		public function loadExt(movieURL:String):void
		{
			_screen.loadExt(movieURL);
		}
		
		public function loadAndPlayExt(movieURL:String):void
		{
			_screen.loadAndPlayExt(movieURL);	
		}
		
		public function mute():void
		{
			_screen.mute();
		}
		
		public function pause():void
		{
			_screen.pause();
		}
		
		///Pauses the video while video scrubbar is dragged
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#pauseForSlider()
		 */
		public function pauseForSlider():void
		{
			_screen.pauseForSlider();
		}
		
		///Resumes the video after the video scrubbar has been released
		/**
		 * @copy eyeblaster.videoPlayer.IVideoScreen#playAfterPauseForSlider()
		 */
		public function playAfterPauseForSlider():void
		{
			_screen.playAfterPauseForSlider();
		}
		
		public function play():void
		{
			_screen.play();
		}
		
		public function replay(turnAudioOn:Boolean = true):void
		{
			_screen.replay(turnAudioOn);
		}
		
		public function seek(timeInSecs:Number):void
		{
			_screen.seek(timeInSecs);
		}
		
		public function setFMS(fmsUrl:String):void
		{
			_screen.setFMS(fmsUrl);
		}
		
		//=====================================================
		//	FS Functions - All function relating to fs handling
		//=====================================================		
		/**
		 * @private
		 * 
		 * Called from setFullScreen() and from the JS proxy to enter full screen
		 */
		private function fsOpen(e:Event=null):void {			
			
			if (EBBase.isInstream()) return;					
			storeMyCoor();																				
			Utils.scaleToContainer(Utils.EXACT_FIT, this, true);	//fit this player on the stage exectly		
			
			this.x = 0;	this.y = 0;	//set components for fs
			this.parent.setChildIndex(this, this.parent.numChildren - 1);
			
			_controlBar.resetCtlPositionFS(0.5);//reduce the control bar size by 50%
			
			_screen.height += _controlBar.height;	// stretch screen to cover the diffrence in the control bar resize
			_screen.fSOpenInit();						
			_screen.initBG();	//place backround
			
			//mf/trigger full screen
			EBBase._stage.scaleMode = StageScaleMode.EXACT_FIT;
			EBBase._stage.displayState = StageDisplayState.FULL_SCREEN;		
				
		
			
		}
		/**
		 * @private
		 * 
		 * Called from setFullScreen() and from the JS proxy to exit full screen
		 */
		public function fsClose(nFullScreen:Number = 0):void {				
			
			if (EBBase.isInstream()) return;
			_controlBar.resetCtlPositionFS(2);						
			_screen.fSCloseInit(nFullScreen);//return screen to original state				
			EBBase._stage.displayState = StageDisplayState.NORMAL;				
							
			_screen.clearBG();//clear the bg image						
			reStoreMyCoor();										
		}		
		
		public function setFullScreen(fullScreen:Boolean):void
		{
			if ( EBBase.isInstream())
				return;
			if (EBBase._stage.displayState == StageDisplayState.NORMAL)
				fsOpen();
			else if(EBBase._stage.displayState == StageDisplayState.FULL_SCREEN)
				fsClose();						
		}
		//mf/save current x,y, height & width position		
		private function storeMyCoor():void {
				
			this.saveWidthBeforeFS = this.width;
			this.saveHeightBeforeFS = this.height;				
			this.saveXPosBeforeFS = this.x;
			this.saveYPosBeforeFS = this.y;		
			this.saveIndexBeforeFS = this.parent.getChildIndex(this);
				
		}	
		//mf/ restore this panel to its original size, useally after fs
		private function reStoreMyCoor():void {			
			
			this.width = this.saveWidthBeforeFS;
			this.height = this.saveHeightBeforeFS;			
			this.x = this.saveXPosBeforeFS;
			this.y = this.saveYPosBeforeFS;		
			this.parent.setChildIndex(this, saveIndexBeforeFS);
			
		}		
		
		public function setSize(width:Number, height:Number):void
		{
			this.width = width;
			this.height = height;
			
			_screen.setSize(width, height - _controlBar.height);
		}
		
		public function stop():void
		{
			_screen.stop();
		}
		
		public function stopAndClear():void
		{
			_screen.stopAndClear();
		}
		
		public function track(name:String,isAuto:Boolean = false):void
		{
			_screen.track(name,isAuto);
		}
		
		public function unmute():void
		{
			_screen.unmute();
		}
		
		public function videoToggle():void
		{
			_screen.videoToggle();
		}
		
		public function get smoothing():Boolean
		{
			return _screen.smoothing;
		}
		
		public function set smoothing(value:Boolean):void
		{
			_screen.smoothing = value;
		}
	}
}
