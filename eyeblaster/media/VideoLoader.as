//****************************************************************************
//class eyeblaster.media.VideoLoader
//------------------------------------
//This class is a media controller and player, it wraps a "player" class to 
//create a unified API for all supported types of media and contain different
//functionalities like reporting, events and API.
//This class will support 2 media format: FLV Streaming and FLV Progressive 
//The format type will be decided according to the javascript decision on 
//runtime and/or the parameters set through the custom API.
//Accordingly an appropriate player instance will be created and controlled 
//by this class.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.players.IPlayer;
	import eyeblaster.media.players.STATE;
	import eyeblaster.media.players.StreamingPlayer;
	import eyeblaster.media.players.ProgressivePlayer;
	import eyeblaster.media.general.PlayerConstants;
	import eyeblaster.media.general.VideoEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBMetadataEvent;
	import eyeblaster.events.EBErrorEvent;
	import eyeblaster.media.controls.Buffering;
	import flash.display.*;
	import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.FullScreenEvent;
	import flash.utils.*;
	import flash.external.ExternalInterface;
	import flash.media.Video;
	import flash.geom.ColorTransform;
	
	[IconFile("Icons/VideoLoader.png")]
	//internal events - events under VideoEvent class which are dispatched to controls
	[Event("ebVLPlay", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLPause", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLMute", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLVolume", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLFullscreen", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLPlayProgress", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLLoadProgress", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLStatusChanged", type="eyeblaster.events.VideoEvent")]
	[Event("ebVLRollover", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLMouseover", type="eyeblaster.general.VideoEvent")]
	[Event("ebVLMouseOutOfFlash", type="eyeblaster.general.VideoEvent")]
	[Event("ebUpdatePlaybackSlider", type="mx.eyeblaster.General.VideoEvent")]
	//external events - events that are used by the users
	[Event(EBVideoEvent.MOVIE_END, type="eyeblaster.general.EBVideoEvent")]
	[Event(EBVideoEvent.PLAY_PROGRESS, type="eyeblaster.events.EBVideoEvent")]
	[Event(EBVideoEvent.BUFFER_PROGRESS, type="eyeblaster.events.EBVideoEvent")]
	[Event(EBVideoEvent.LOAD_PROGRESS, type="eyeblaster.events.EBVideoEvent")]
	[Event(EBVideoEvent.BUFFER_LOADED, type="eyeblaster.events.EBVideoEvent")]
	[Event(EBVideoEvent.STATUS_CHANGED, type="eyeblaster.events.EBVideoEvent")]
	[Event(EBErrorEvent.ERROR, type="eyeblaster.events.EBErrorEvent")]
	[Event(EBMetadataEvent.METADATA_RECEIVED, type="eyeblaster.events.EBMetadataEvent")]
	[Event(EBMetadataEvent.CUE_POINT, type="eyeblaster.events.EBMetadataEvent")]
	
	public class VideoLoader extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----Size and boundaries------
		private var __width:Number;		//the object width
		private var __height:Number;	//the object height
		private var _realVideoWidth:Number; // the original video size as recieved from the metadata
		private var _realVideoHeight:Number;// the original video size as recieved from the metadata
		private var _buffering_mc:MovieClip;	//buffering animation
		private var _bg_mc:MovieClip;			//component background
		private var _helpLoader_mc:MovieClip;	//mc to be dispalyed in the live preview of VL
		private var _helpPlayback_mc:MovieClip; //mc to be displayed in the live preview of playback
		//----Player------
		private var _video:Video;				//The video object
												//(the soound and video operates on)
		private var _playerInst:IPlayer;		//The player instance
		private var _nFullScreen:Number;	//Indicates whether the video is playing in fullscreen/page or not: Disabled(0) - defualt
											//Regular mode (1), FullScreen mode(2)	
		private var _fIsStreaming:Boolean;	//Indicates whether the protocol is streaming (true) or progressive (false)
		private var _fAutoPlay:Boolean;	//Indicates if the video should be auto played
		private var _fIsVideoActive:Boolean;;	//Indicates whether the video is active or not
		
		private var _nMovieNum:Number;	//Indicates the ordinal number of the video currently loaded, 1 for "ebMovie1",… (this private attribute prevents the user changing the movie # in runtime)
		private var _strMovieURL: String;		//holds the video URL currently loading/playing
		private var _nBufferSize:Number;	//The buffer size (set only in case the user set the buffer before the player was init)
		private var _fOfflineURL:Boolean;		//Indicates whether an offline URL is used
		private var _strExtFCSURL:String;		//external FCS URL. This attribute is set by VideoSetFCS function. the defualt value is _root.ebStreamingAppURL
		private var _strExtVideoUrl:String;		//An external video to be used
		
		private var _fIgnoreJSResponse:Boolean;		//indicates that the JavaScript call to load should be ignored
		
		//----Sound-----
		private var _nUnmutedReported:Number;	//Indicates whether the unmute interaction was reported. 0 - was not reported;1 - auto initiated unmute was reported(ebVideoUnmuted);2 - user initiated unmute was reported (ebVideoUnmuted + ebVideoUnmute)
		private var _fSendMuteEvent:Boolean;	//Indicates whether the mute event was send to init the mute status
		private var _initVolume:Number;		//Initial speaker volume level
		private var _fMuteState:Boolean;		//Indicates if the normal skin was mute/unmute before moving to full screen
		
		//----Loop------
		private var _nVideoLoopInSec:Number;	//Used for looping, the number of Secs to loop the video
		private var _stripedProgInterval:Number;	//Interavl for video strip loop (make sure that _stripedVideoProgress will be called when the video ends)
		private var _nLoopNum:Number;	//the number of the current loop in videoStrip, will be used to limit streaming to 2 loops.
		
		//Full screen/page
		private var _fRegisterFLVEvent:Boolean; //Event that listens to open/close Full Screen for FLV
		
		//----Reporting------
		private var _nReportedPlayProgress:Number;	//Indicates playing progress
													//-1: Not started; 0: Started; 1: 25% Played; 2: 50% Played; 3: 75% Played; 4: Fully played
		private var _fShouldReport:Boolean;		//Indicates if interactions should be reported.
												//Set by the dynamic mask component to prevent reporting when retracted
		private var _strInteractionPrefix;		//Interactions prefix
		private var _fDurationTimerStatus;		//Indicates the timer status (on/off)
		private var _fEnableReplay:Boolean;		//Indicates if replay can be reported
		private var _nMovieNumTimer:Number;		//the ordinal number of the movie the timer is set for 
		
		//----Events------
		private var _startMouseMoveTime:Number;	//Holds the start mouse movement time
		private var _fMouseOver:Boolean;	//Indicates the value the mouseover event was reported with 
		private var _nCurrPlayProgress:Number;	//the current play progress
		private var _nCurrLoadProgress:Number;	//the current load progress
		private var _nCurrBufferProgress:Number; //the current buffer progress
		private var _strStatusChanged:String;   //the current status of the video
		private var _videoEventInfo:Object;		//the object that holds all values of the attributes that exist in the EBVideoEvent class
		
		//----General----
		private var _fInVideoPlayback:Boolean = false;	//Indicates whether the component is in VideoPlayback
		private var _fShouldPauseOnLastFrame:Boolean = false; //Indicates whether the movie should paused on last frame
		private var _fPausedOnLastFrame:Boolean = false;	  //Indicates whether the movie ended and paused at last frame (and after that we arrived to load or play)
		private var _fShouldReplayOnMovieEnd:Boolean = false; //In whether the movie should replay when it ended
		private var _fVideoDisplay:Boolean = false;		  //Indicates whether the video is displayed 
		private var _fDynamicComp:Boolean;				  //Indicates whether the component is played dynamically or not
		private var _isLivePreview:Boolean;				//Indicates whether we are in live preview
		private var _originalWidth = 300;					//the width of the component
		private var _originalHeight = 234;					//the height of the component
		private var _instName:String = "_videoLoaderInst";  //the name of the component instance
		//----API----
		private var _JSAPIFuncName:String;			//the name of the function used to recieve calls from the JavaScript
		private var _nCompID:Number;					//id of the component
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//				Private Static Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private static var _nMaxLoopsForStreaming:Number = 2;	//max number of loops allowed for video strip with streaming
		private static var _nInstCount:Number = 0;				//VideoLoader component instance count
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----UI------
		[Inspectable(defaultValue="",type=String)]
		public var strName:String = "";	//the component name used for the automatic event Handlers
		
		[Inspectable(defaultValue="",type=String)]
		public var offlineVideoFile:String = "";	//Offline file URL for testing
		
		[Inspectable(defaultValue=true,type=Boolean)]
		 public var fAutoLoad:Boolean = true;	//Indicates whether loading the video should be done automatically
		
		[Inspectable(defaultValue=false,type=Boolean)]
		public var fAutoPlay:Boolean = false;	//Indicates whether loading and playing the video should be done automatically
		
		[Inspectable(defaultValue=true,type=Boolean)]
		public var muteOnVideoStart:Boolean = true;		//Indicates whether the sound should started muted or not
		
		[Inspectable(enumeration="0,1", defaultValue=0,type=Number)]
		public var displayMode:Number = 0;	//Indicates the display mode: Fit Component Size (0) - default; Original Video Size (1)	
		
		[Inspectable(defaultValue="1",type=Number)]
		public var nVideoFileNum:Number = 1;		//The ordinal number (1 for ebMovie1,..) of the video to load and play
												//0 is for external URL
		
		[Inspectable(defaultValue="1",type=Number)]
		public var nFSVideoFileNum:Number = 1;		//not used anymore but neccessary for backward compatability when replacing old component with new component

		[Inspectable(defaultValue="",type=String)]
		public var strExtVideoUrl:String = "";		//An external video to be used
		
		[Inspectable(defaultValue="1",type=Number)]
		public var nGoToFrame:Number = 1;	//Indicates the frame to go to, in case, nOnMovieEnd = 1
	 
		[Inspectable(enumeration="0,1,2,3,4,5", defaultValue=0,type=Number)]
		public var nOnMovieEnd:Number = 0;		//Indicates which functionality the movie end event will trigger:
											//None(0); Replay (1); Stop on last frame(2); Goto frame (3);Custom (4); Close (5); 0 is the default
		
		[Inspectable(defaultValue="0,0,0", type=Array)]		//Indicates which functionality the rollover event will trigger: 
		public var onRolloverArr:Array = new Array(0,0,0);//Play/Pause (0); Mute/Unmute (1); Custom (2); none is the default
	
		[Inspectable(defaultValue="1,0,0", type=Array)]		//Indicates which functionality the click event will trigger: 
		public var onClickArr:Array = new Array(1,0,0);	//Goto default click thru URL (0); Pause/Play (1) ; Custom (2); 0 is the default	
		
		//----General------
		include "../core/compVersion.as"
		public var compName:String = "VideoLoader";	//The component name to be used for components detection.
		public var initComponentProperties:Function;	//a callBack function for the UI properties that the user has to implement when using dynamic component
		//------PlayBack------
		// fInVideoPlayback - Indicates whether the component is in VideoPlayback
		public function get fInVideoPlayback():Boolean{return this._fInVideoPlayback;}
		public function set fInVideoPlayback(flag:Boolean):void{this._fInVideoPlayback = flag;}	
		public function get videoEventInfo():Object{return this._videoEventInfo;}
		//----Events------
		public var fShouldReportMouseMove:Boolean;	//Indicates whether the mousemove event should be reported
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function VideoLoader()	
		{
			Tracer.debugTrace("VideoLoader: Constructor", 6);
			try
			{
				//determine if we are in live preview mode
				this._isLivePreview = ((parent != null) && getQualifiedClassName(parent) == "fl.livepreview::LivePreviewParent");
				if(!this._isLivePreview)
					Tracer.debugTrace("VideoLoader version: " + compVersion, 0);
				
				//when the compoenent is compiled and have also open class after the enter frame 
				//event the values of teh component: numChildren, width and height are set to 0 therefore, we save them 
				//before the event
				if (this.numChildren > 0)
				{
					_fDynamicComp = false;
					//save the size for later phase
					_originalWidth = super.width;
					_originalHeight = super.height;
					//save the _bg_mc for later phase
					this._bg_mc = this.getChildAt(0) as MovieClip;
					//hide the help movie clip here for plaback case since we hide it after enterFrame it will be visible in plaback case for a second (because of the enterFrame)
					this._helpLoader_mc = this.getChildAt(1) as MovieClip;
					_helpLoader_mc.visible = false;
					
				}
				else
				{
					_fDynamicComp = true;
				}
		
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: Constructor: "+ error, 1);
			} 
		}
		
		//----Getter/Setter------
		//====================
		//	function set name
		//====================
		public override function set name(strName:String):void
		{
			//set the name as the instance name. can be called also from the user and therefore we  
			super.name = strName;
			_instName = strName;
		}
		
		//====================================
		//	function set/get pauseOnLastFrame
		//====================================
		public function set pauseOnLastFrame(val:Boolean)
		{
			_fShouldPauseOnLastFrame = val;
			if (val)
				this.nOnMovieEnd = 2;
		}
		public function get pauseOnLastFrame(){return this._fShouldPauseOnLastFrame;}
		
		//====================================
		//	function set/get replayOnMovieEnd
		//====================================
		public function set replayOnMovieEnd(val:Boolean)
		{
			_fShouldReplayOnMovieEnd = val;
			if (val)
				this.nOnMovieEnd = 1;
		}
		public function get replayOnMovieEnd(){return this._fShouldReplayOnMovieEnd;}

		//====================================
		//	function get netStream
		//====================================
		public function get netStream()
		{
			if (this._playerInst)
				return this._playerInst.netStreamVideo;
			return this._playerInst;
		}
		
		//====================================
		//	function get video
		//====================================
		public function get video():Video
		{
			if (!this._video)
			{
				this._video = new Video(0,0);
				this.addChild(this._video);
			}
			return this._video;
		}

		//============================
		//	function get mute
		//============================
		//This function retrun the speaker mute flag
		public function get isMute():Boolean
		{
			if(this._playerInst)
				return this._playerInst.getMute();
			return this.muteOnVideoStart;
		}
		
		//============================
		//	function set/get volume
		//============================
		public function set volume(nVolLevel:Number):void
		{
			//set volume
			if(this._playerInst)
				this._setVolume(nVolLevel);
			else	//no video was loaded, set the init value
				this._initVolume = nVolLevel;
		}
		public function get volume():Number
		{
			if(this._playerInst)
				return this._playerInst.getVolume();
			return this._initVolume;
		}
		
		//============================
		//	function get length
		//============================
		//This function return the video length
		public function get length():Number
		{
			if(this._playerInst)
				return this._playerInst.videoLength;
			return -1;
		}
		
		//============================
		//	function get status
		//============================
		//This function return the video status
		public function get status():String
		{
			var nStatus:Number = (this._playerInst) ? this._playerInst.getStatus() : 0;
			return this._getStatus(nStatus);
		}
		
		//================================
		//	function set transparency
		//================================
		//This function sets the transparency mode of the buffering animation
		//Parameters:
		//	nMode:Number - the desired transparency mode, default value is the setting in the UI 
		public function set transparency(nMode:Number):void
		{
			//set mode
			if(nMode == PlayerConstants.ebTransparentMode)	//transparent mode
			{
				//set background to be transparent
				_bg_mc.alpha = 0;
			}
			else if(nMode == PlayerConstants.ebSolidMode)	//solid mode upon play
			{
				_bg_mc.alpha = 1;
			}
			else	//nMode is not an appropriate value for this function
			{
				Tracer.debugTrace("VideoSetTransparency: "+nMode +"is not an appropriate parameter for this function",6);
				return;
			}
		}
		public function get transparency()
		{ 
			if (_bg_mc)
				return _bg_mc.alpha;
			return null;
		}
		//=========================
		//	function set setFMS
		//=========================
		//This function sets FCS URL for the use of external FLV streaming files.
		//The function should be called before VideoLoadExt/VideoLoadAndPlayExt
		//Parameters:
		//	strFCSURL:String - FCS URL
		public function set setFMS(strFMSURL:String):void
		{
			this._strExtFCSURL = strFMSURL;
		}
		
		//============================
		//	function set/get buffer
		//============================
		public function set buffer(nBuffer:Number):void
		{
			//play back mode
			var strPlayBack:String = this._fIsStreaming?"Buffer":"Risk"
			
			//real buffer/risk size
			var nBufferSize:Number = nBuffer;
			//high
			if(nBuffer == PlayerConstants.ebHigh)
				nBufferSize = PlayerConstants["eb" + strPlayBack + "High"];
			//mid
			else if(nBuffer == PlayerConstants.ebMed)
				nBufferSize = PlayerConstants["eb" + strPlayBack + "Med"];
			//low
			else if(nBuffer == PlayerConstants.ebLow)
				nBufferSize = PlayerConstants["eb" + strPlayBack + "Low"];
			else if(nBuffer < 0)
				Tracer.debugTrace("VideoLoader: Error - setBuffer: "+nBuffer +" is not an appropriate value for this function",6);
			
			//set buffer
			if(this._playerInst)
				this._playerInst.setBuffer(nBufferSize);
			//set the init value 
			//(we will use this value in case
			//the function was called before the load - as should)					  
			this._nBufferSize = nBufferSize;
		}
		public function get buffer():Number
		{
			if(this._playerInst)
				return this._playerInst.bufferSize;
			else	//no video was loaded, return the defualt value
				return -1;
		}

		//====================================
		//	function get/set fIsLivePreview
		//====================================
		// live preview - used when the VideoLoader is inside a VideoPlayback
		public function get fIsLivePreview():Boolean{return this._isLivePreview;}
		public function set fIsLivePreview(flag:Boolean):void{this._isLivePreview = flag;}	

		//----UI-----

		//====================================
		//	function get/set playbackMode
		//====================================
		//These functions implements playbackMode UI parameter
		//which indicates the Playback mode: 
		//Progressive Download Only(0); Streaming Only(1); Automatic(2)
		//Note: we use getter/setter functions to restrict the values
		//set to this attribute
		[Inspectable(enumeration="0,1,2", defaultValue=2,type=Number)]
		public function get playbackMode():Number
		{
			var playbackMode = (this._fIsStreaming) ? 1 : 0;
			return playbackMode;
		}	
		public function set playbackMode(nMode:Number):void
		{
			this._fIsStreaming = (nMode != 1) ? false : true;
		}

		//----Size------
		
		//=======================
		//	function setSize
		//=======================
		//This function handles resize
		//Parameters:
		//	width:Number - new width
		//	height:Number - new height
		public function setSize(w:Number=-1, h:Number = -1):void
		{
			try
			{
				//check if the parameters are defined
				if(w != -1){
					this.__width = w;
					if(!_fInVideoPlayback)
						_originalWidth = w;
				}
				if(h != -1)	{
					this.__height = h;
					if(!_fInVideoPlayback)
						_originalHeight = h;					
				}
				if(!_fInVideoPlayback)
					_setVideoSize();
				//this check guarantee that when dragging the component it will enter to this function
				if (_bg_mc)
				{
					if (this.__width > 0)
						_bg_mc.width = w;
					if (this.__height > 0)
						_bg_mc.height = h;
					_bg_mc.x = 0;
					_bg_mc.y = 0
				}
				if (_helpLoader_mc)
				{
					if (this.__width > 0)
						_helpLoader_mc.width = w;
					if (this.__height > 0)
						_helpLoader_mc.height = h;
					_helpLoader_mc.x = 0;
					_helpLoader_mc.y = 0
				}
				if (_helpPlayback_mc)
				{
					if (this.__width > 0)
						_helpPlayback_mc.width = w;
					if (this.__height > 0)
						_helpPlayback_mc.height = h;
					_helpPlayback_mc.x = 0;
					_helpPlayback_mc.y = 0
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: setSize: "+ error, 1);
			} 
		}
		
		//========================
		//	function set width
		//========================
		//This function is a Setter function, set the width
		//of this object
		public override function set width(w:Number):void{setSize(w, this.__height);}
		
		//========================
		//	function set height
		//========================
		//This function is a Setter function, set the height
		//of this object
		public override function set height(h:Number):void{setSize(this.__width, h);}
		
		//----Init------
		
		//====================================
		//	function enterFrameHandler
		//====================================
		// This function calls init function upon enter frame event to
		// allow the UI parameters to get their value before we init
		// the component
		function initUponEnterFrame(event:Event)
		{
			Tracer.debugTrace("VideoLoader: initUponEnterFrame", 6);
			removeEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			this._init();
		}
		
		//-------General----
		
		//===================================
		//	function isVideoPlaying
		//===================================
		//This function checks whether the video is playing
		//The function is an Interface function to DynamicMask component
		public function isVideoPlaying():Boolean
		{
			try
			{
				var nStatus:Number = 0;
				if (this._playerInst)
				{
					nStatus = this._playerInst.getStatus();
					return((nStatus == 4) || (this._playerInst.state == STATE.PLAY && _fVideoDisplay));
				}
				return false;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: isVideoPlaying: "+ error, 1);
			} 
			return false;
		}
		
		//===================================
		//	function showVideo 
		//===================================
		//This function display the video
		public function showVideo()
		{
			if (this._playerInst.state != STATE.PLAY || !(_realVideoWidth > 0))
				return;
			//remove the animation
			//_buffering_mc has only child animation_mc
			if(_buffering_mc.numChildren > 0)
				_buffering_mc.removeChild(_buffering_mc.getChildAt(0));
			//display the video
			if(!this.video.visible)
			{
				_setVideoSize();
				this.video.visible = true;
				_fVideoDisplay = true;
				this._playerInst.status = 4;
			}
		}
	
		//===========================
		//	function setVideoEventInfo
		//===========================
		//set the values of the events in EBVideoEvent class into an object
		public function setVideoEventInfo(nPlayProgress,nLoadProgress,nBufferProgress,strStatusChanged)
		{
			this._videoEventInfo[EBVideoEvent.PLAY_PROGRESS] = nPlayProgress;
			this._videoEventInfo[EBVideoEvent.LOAD_PROGRESS] = nLoadProgress;
			this._videoEventInfo[EBVideoEvent.BUFFER_PROGRESS] = nBufferProgress;
			this._videoEventInfo[EBVideoEvent.STATUS_CHANGED] = strStatusChanged;
		}
		
		//----API(Control)-----
		
		//=======================
		//	function load
		//=======================
		//This function Download a media file
		//Parameters:
		//	nMovieNum:Number - the video ordinal number, for example 1 
		//					   for "ebMovie1"
		public function load(nMovieNum:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: load("+arguments+")",1);
				this._setVideoLoad(nMovieNum,false);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: load: "+ error, 1);
			}
		}
	
		//============================
		//	function loadAndPlay
		//============================
		//This function Download and play a media file
		//Parameters:
		//	nMovieNum:Number - the video ordinal number, for example 1 
		//					   for "ebMovie1"
		public function loadAndPlay(nMovieNum:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: loadAndPlay("+arguments+")",1);
				this._setVideoLoad(nMovieNum,true);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: loadAndPlay: "+ error, 1);
			}
		}
	
		//=========================
		//	function loadExt
		//=========================
		//This function Download an external media file
		//Parameters:
		//	strMovieURL:String - external media file URL
		public function loadExt(strMovieURL:String):void
		{
			Tracer.debugTrace("VideoLoader: loadExt("+arguments+")",1);
			this._setVideoLoadExt(strMovieURL,false);
		}
		
		//===============================
		//	function loadAndPlayExt
		//===============================
		//This function Download and play an external media file
		//Parameters:
		//	strMovieURL:String - external media file URL
		public function loadAndPlayExt(strMovieURL:String):void
		{
			
			Tracer.debugTrace("VideoLoader: loadAndPlayExt("+arguments+")",0);
			this._setVideoLoadExt(strMovieURL,true);
		}
		
		//============================
		//	function loadProxy
		//============================
		//This function is called by the proxy to start 
		//load/load and play the video.
		//Parameters:
		//	strMovie:String -  a string containing:
		//		Video URL - video URL
		public function loadProxy(strMovie:String,strMovieParams:String):void
		{
			Tracer.debugTrace("VideoLoader: loadProxy",2);
			try
			{
				//In case of request to internal video
				//was made before lodaing extenal media - ignore the response.
				if(this._fIgnoreJSResponse)
					return;
				this._startLoad(strMovie);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: loadProxy: "+ error, 1);
			}
		}
		
		//============================
		//	function play
		//============================
		//This function starts the video playback
		public override function play():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: play",1);
				if (!this._playerInst)
					return;
				this._play();
				//report replay
				if(this._fEnableReplay)
				{	
					//send interaction 
					EBBase.handleCommand("ebVideoInteraction","'ebVideoReplay','"+_nMovieNum+"'");
					this._fEnableReplay = false;
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: play: "+ error, 1);
			}
		}
		
		//============================
		//	function pause
		//============================
		//This function pause the video playback
		//Parameters:
		//	nAutoInit:Number - indicates whether it is a user or auto 
		//		initiated call, values:
		//		 	User = 0 (default),
		// 			Auto = 1 
		public function pause(nAutoInit:Number = 0):void
		{
			Tracer.debugTrace(" VideoLoader: pause",1);
			try
			{
				//should report
				var fShouldReport:Boolean = nAutoInit?false:true;
				this._pause(fShouldReport);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: pause: "+ error, 1);
			}
		}
		
		//============================
		//	function pauseForSlider
		//============================
		//This function will pause the video playback
		///without sending any interaction
		public function pauseForSlider():void
		{
			Tracer.debugTrace(" VideoLoader: pauseForSlider", 4);
			try
			{
				this._playerInst.pause();
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: pauseForSlider: "+ error, 1);
			}
		}
		
		//============================
		//	function playAfterPauseForSlider
		//============================
		//This function replay the video playback
		///without sending any interaction
		public function playAfterPauseForSlider():void
		{
			Tracer.debugTrace(" VideoLoader: playAfterPauseForSlider", 4);
			try
			{
				this._playerInst.play();
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: playAfterPauseForSlider: "+ error, 1);
			}
		}
		
		//============================
		//	function stop
		//============================
		//This function stop the video playback
		public override function stop():void
		{
			Tracer.debugTrace("VideoLoader: stop",1);
			try
			{
				super.stop();
				this._stop();	
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: stop: "+ error, 1);
			}
		}
		
		//============================
		//	function seek
		//============================
		//This function seek the video to nSec position
		//Parameters:
		//	nSec:Number - number of secs to seek the video forward or backward
		public function seek(nSec:Number = 5):void
		{
			Tracer.debugTrace("VideoLoader: seek(" + nSec + ")",1);
			try
			{
				//no player therefore there is no meaning for seek
				if (!this._playerInst)
					return;
				
				//video length
				var nLength:Number = this._playerInst.videoLength;
				
				//the position to seek the video to
				var nNewPos:Number = this._playerInst.position + nSec;
				
				if(nNewPos < 0)
					nNewPos = 0;
				else if(nNewPos > nLength)
					nNewPos = nLength;
				//seek video
				this._seek(nNewPos);	
				
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: seek: "+ error, 1);
			}
		}
		
		//====================================
		//	function startLoop
		//====================================
		//This function sets Number of seconds to loop the video 
		//according to Secs parameter
		//Parameters:
		//	nSecs:Number - number of seconds to loop the video 
		public function startLoop(nSecs:Number):void	
		{
			_nVideoLoopInSec = nSecs;
		}
		
		//====================================
		//	function stopLoop
		//====================================
		//This function stop looping the video the video 
		public function stopLoop():void	
		{
			_nVideoLoopInSec = -1;
		}
		
		//============================
		//	function setMute
		//============================
		//This function set or unset speaker mute according to 
		//nMuteVal value.
		//Parameters:
		//	nMuteVal:Number - the speaker mute state, values:
		//		ebUnMute = 0
		//		ebMute= 1
		//		ebToggle = 2 (default)
		//	nAutoInit:Number - indicates whether it is a user or auto 
		//		initiated call, values:
		//		 	User = 0 (default),
		// 			Auto = 1 
		public function setMute(nMuteVal:Number = 2,nAutoInit:Number = 0):void
		{
			Tracer.debugTrace("VideoLoader: VideoSetMute("+nMuteVal+")",1);
			try
			{
					//should report
					var fShouldReport:Boolean = nAutoInit?false:true;
					//set mute
					this._setMute(nMuteVal,fShouldReport);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: VideoSetMute: "+ error, 1);
			}
		}
		
		//----Events from the Controls----
		
		//============================
		//	function handleEvent
		//============================
		//Listen to events from the controller. The events are:
		//play, pause, stop, seek, mute, fullScreen, replay, volume, playBack
		//Parameters:
		//	ev:Object - an object containing the type of the event and value
		public function handleEvent(ev:Object):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: handling event type: " + ev.type + ", value: " + ev.value,4);
						
				if (ev.type == "ebVBPlay")
					this.play();
				else if (ev.type == "ebVBPause")
				{
					this.pause(0);
				}
				else if (ev.type == "ebVBStop")
				{
					this.stop();
				}
				else if (ev.type == "ebVBSeek")
				{
					/// seek the video only if video status is Playing (4)
					var nStatus:Number = this._playerInst.getStatus();
					if ( nStatus == 4 )
					{
						this.seek(Number(ev.value));
						/// send ebSliderDragged interaction
						EBBase.handleCommand("ebVideoInteraction","'ebSliderDragged','"+_nMovieNum+"'");
					}
				}
				else if(ev.type == "ebVBMute")
				{
					this.setMute(Number(ev.value), 0);
				}
				else if(ev.type == "ebVBFullscreen")
				{
					if(ev.value == 1)
						this.setFullScreen(true);
					else
						this.setFullScreen(false);
				}
				else if (ev.type == "ebVBReplay")
				{
					this.stop();
					this.play();
				}
				else if(ev.type == "ebVBVolume")
				{
					this.volume = ev.value;
				}
				else if(ev.type == "ebVBSendSliderDraggedInteraction")
				{
					/// send ebSliderDragged interaction  only if video status is Playing (4)
					var nStatus1:Number = this._playerInst.getStatus();
					if ( nStatus1 == 4 )
					{
						EBBase.handleCommand("ebVideoInteraction","'ebSliderDragged','"+_nMovieNum+"'");
					}
				}
				else if (ev.type == "ebVBPauseForSlider")
				{
					/// send ebSliderDragged interaction  only if video status is Playing (4)
					var nStatus2:Number = this._playerInst.getStatus();
					if ( nStatus2 == 4 )
					{
						EBBase.handleCommand("ebVideoInteraction","'ebSliderDragged','"+_nMovieNum+"'");
					}
					
					pauseForSlider();
				}
				else if (ev.type == "ebVBPlayAfterPauseForSlider")
				{
					playAfterPauseForSlider();
				}
				else if ((ev.type == "ebVBUpdatePlayhead") && (this._playerInst))
				{
					///calculate position
					var pos:Number = Number(ev.value)/100 * this._playerInst.videoLength;
					Tracer.debugTrace("VideoLoader: handling event type: ev.value=" + ev.value, 4);
					if(ev.value == 100)
					{
						//handle movie end
						_onMovieEnd();
						//fire ebUpdatePlaybackSlider event in order to remove dragging listeners
						var evUpdatePlaybackSlider:VideoEvent = new VideoEvent("ebUpdatePlaybackSlider","");
						dispatchEvent(evUpdatePlaybackSlider);
					}
					else
						this._seek(pos);
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: handleEvent: "+ error, 1);
			}
		}
	
		//----Events from the player----
		
		//====================================
		//	function playerEventsHandler
		//====================================
		//This function is an event handler to the player events
		//Parameters:
		//	event:String - the player event that trigger the handler, 
		//				   optional evetn: 
		//						playProgress, loadProgress, bufferProgress, bufferLoaded, statusChanged, MovieEnd
		//	eventParam:String - the event parameters
		public function playerEventsHandler(event:String,eventParam:Object):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: playerEventsHandler(" + arguments.join(',') + ")",6);
				//call the appropriate event handler 
				if (eventParam == "")
				{
					this[event+"Event"]();
				}
				else if(!isNaN(Number(eventParam)))
				{
					var nEventParam:Number = Number(eventParam);
					this[event+"Event"](nEventParam);
				}
				else
				{
					this[event+"Event"](eventParam);
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: playerEventsHandler: "+ error, 1);
			}
		}

		//====================================
		//	function playerEventsHandler2
		//====================================
		//This function is an event handler to the player events metaData and cuePoint.
		//Parameters:
		//	event:String - the player event that trigger the handler, 
		//				   optional evetn: 
		//						metaData and cuePoint.
		//	eventParam:Object - the event parameters
		public function playerEventsHandler2(event:String,eventParam:Object):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: playerEventsHandler2",6);
				//call the appripriate event handler
				this[event+"Event"](eventParam);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: playerEventsHandler2: "+ error, 1);
			}
		}
		
		//----Events from the javascript(proxy)----
		
		//============================
		//	function JSAPIFunc
		//============================
		//This function is used to recive calls from the javaScript
		public function JSAPIFunc(funcName:String, strParams:String)
		{
			try
			{
				var arr:Array;
				
				switch (funcName)
				{
					case "load":
						//in case of load call to function loadProxy
						funcName = funcName + "Proxy";
						arr = strParams.split(",");
						this[funcName](arr[0],arr[1]);
					break;
					default:
						//functions that the name in the JS is the same as the flash - change the name in the flash to be without the word Video ansd that will start with lower case 
						if (funcName.substr(0,5).toLowerCase() == "video")
						{
							var firstChar = funcName.substr(5,1).toLowerCase();
							funcName = firstChar + funcName.substr(6);
						}
						if (strParams != "") //functions that have one parameter which its type is Number i.e. function VideoLoadAndPlay, VideoSeek
							this[funcName](Number(strParams));
						else				//functions that don't have parameters
							this[funcName]();
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: JSAPIFunc: "+ error, 1);
			}
		}
		
		//============================
		//	function activate
		//============================
		//This function handles the video acitvate and deactivate event 
		//in case Streaming protocol is used.
		//This event is recieved from the Javascript through the proxy.
		//Parameters:
		//	nActive:Number - the video mode: 0 - deactive, 1 - active
		public function activate(nActive:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoActivate("+nActive+")",6);
				if (!this._playerInst)
					return;
				//deactivate
				if(!nActive)
				{
					//Video status
					var nStatus:Number = this._playerInst.getStatus();
					//play (including buffering)
					if((nStatus == 4) || (nStatus == 1) || (nStatus == 2))
					{
						//pause the video
						this._playerInst.pause();
						this._fIsVideoActive = false;
					}
				}
				//activate
				else
				{
					//Video is not active
					if(!this._fIsVideoActive)
					{
						//play the video
						this._play();
						this._fIsVideoActive = true;
					}
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: VideoActivate: "+ error, 1);
			}
		}
		
		//===========================
		//	function mouseOutOfFlash
		//===========================
		//This function reports the mouseOutOfFlash event and updates
		//_fMouseOver.
		//This function is used for hidding/displaying the 
		//VideoControls on rollover/out. 
		//It is called from the javaScript in case the mouse moved out of
		//the flash
		public function mouseOutOfFlash():void
		{
			try
			{
				//update _fMouseOver
				_fMouseOver = false;
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVLMouseOutOfFlash","");
				// Dispatch the event
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: mouseOutOfFlash: "+ error, 1);
			}
		}
		
		//----Event Handlers – called by the javascript(proxy) or player-----
		
		//============================
		//	function onErrorEvent
		//============================
		//This function handles the onError event received from 
		//the player
		//Parameters:
		//	description:String - the error description
		public function onErrorEvent(description:String):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: onErrorEvent("+description+")",1);
				
				//Error occured clear the player
				this._stop();
				this._clearVideo();
				//fire error event
				if ((root) && (strName + "_OnError" in root))
					root[strName + "_OnError"](description);
				var ev:EBErrorEvent = new EBErrorEvent(EBErrorEvent.ERROR,description);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: onErrorEvent: "+ error, 1);
			} 
		}
		
		
		//============================
		//	function playProgressEvent
		//============================
		//This function handles the playProgress event received from 
		//the player or proxy
		//Parameters:
		//	nPerPlayProgress:Number - play progress in percentage
		public function playProgressEvent(nPerPlayProgress:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: playProgressEvent("+nPerPlayProgress+")",4);
				this._nCurrPlayProgress = nPerPlayProgress;
				
				//report the play progress
				this._reportPlayProgress(nPerPlayProgress);
				
				//handle video loop if needed (for video strip).
				var nStatus:Number = this._playerInst.getStatus();
				if (nStatus == 4)
				{
					this._stripedVideoProgress(nPerPlayProgress);
				}
				//fire progress event for the users
				if ((root) && (strName + "_OnPlayProgress" in root))
					root[strName + "_OnPlayProgress"](nPerPlayProgress);
				Tracer.debugTrace("VideoLoader: playProgressEvent: Fire event onPlayProgress("+nPerPlayProgress+")",6);
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.PLAY_PROGRESS,_videoEventInfo);
				dispatchEvent(ev);
				//fire progress event for the control
				var evCtr:VideoEvent = new VideoEvent("ebVLPlayProgress",nPerPlayProgress);
				dispatchEvent(evCtr);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: playProgressEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function loadProgressEvent
		//============================
		//This function handles the loadProgress event received from 
		//the player or proxy
		//Parameters:
		//	nPerLoadProgress:Number - load progress in percentage
		public function loadProgressEvent(nPerLoadProgress:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: loadProgressEvent("+nPerLoadProgress+")",4);
				this._nCurrLoadProgress = nPerLoadProgress;
				//fire progress event
				if ((root) && (strName + "_OnLoadProgress" in root))
					root[strName + "_OnLoadProgress"](nPerLoadProgress);
				Tracer.debugTrace("VideoLoader: loadProgressEvent: Fire event onLoadProgress("+nPerLoadProgress+")",4);
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.LOAD_PROGRESS,_videoEventInfo);
				dispatchEvent(ev);
				//fire progress event for the control
				var evCtr:VideoEvent = new VideoEvent("ebVLLoadProgress",nPerLoadProgress);
				dispatchEvent(evCtr);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: loadProgressEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function bufferProgressEvent
		//============================
		//This function handles the bufferProgress event received from 
		//the player or proxy
		//Note: for progressive download, sent only before playing
		//Parameters:
		//	nPerBufferProgress:Number - buffer progress in percentage
		public function bufferProgressEvent(nPerBufferProgress:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: bufferProgressEvent("+nPerBufferProgress+")",4);
				this._nCurrBufferProgress = nPerBufferProgress;
				//fire bugger progress event
				if ((root) && (strName + "_OnBufferProgress" in root))
					root[strName + "_OnBufferProgress"](nPerBufferProgress);
				Tracer.debugTrace("VideoLoader: bufferProgressEvent: Fire event onBufferProgress("+nPerBufferProgress+")",4);
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.BUFFER_PROGRESS,_videoEventInfo);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: bufferProgressEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function bufferLoadedEvent
		//============================
		//This function handles the buffer loaded event received from 
		//the player or proxy
		//Note: the event is sent only once before playing
		public function bufferLoadedEvent():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: bufferLoadedEvent",4);
				//fire event
				if ((root) && (strName + "_OnBufferLoaded" in root))
					root[strName + "_OnBufferLoaded"]();
				Tracer.debugTrace("VideoLoader: bufferLoadedEvent: Fire event onBufferLoaded",4);
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.BUFFER_LOADED,_videoEventInfo);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: bufferLoadedEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function statusChangedEvent
		//============================
		//This function handles the statusChanged event received from 
		//the player or proxy
		//	nStatus:Number - the new video status
		//		Statuses:
		//			Error: -1
		//			Idle: 0 (default)
		//			Loading:1
		//			Buffering:2
		//			Ready:3
		//			Playing:4
		//			Paused:5
		//			Stopped:6
		//			Ended:8
		public function statusChangedEvent(nStatus:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: statusChangedEvent("+nStatus + ")",4);				
				var evCtr:VideoEvent = null;
				
				// Start/End the playing progress timer 
				//if started/stopped playing
				if (nStatus == 4)
				{
					
					//start duration timer
					this._startVideoPlayDuration();
					
					//----fire events-----
					//play
					evCtr = new VideoEvent("ebVLPlay","");
					dispatchEvent(evCtr);
					
					//mute
					//Note - this event is sent in "buffering" staus, in case it wasn't 
					//sent, we will send it upon play
					if(!this._fSendMuteEvent)
					{
						this._initMuteState();
						this._fSendMuteEvent = true;
					}
					
					//update video active mode in the javascript
					this._setActiveMode(true);
				}
				else
				{
					//end duration timer
					this._endVideoPlayDuration();
				}
				
				//buffering
				if((nStatus == 1) || (nStatus == 2))
				{
					//mute
					if(!this._fSendMuteEvent)
					{
						this._initMuteState();
						this._fSendMuteEvent = true;
					}
					
					//set buffering animation
					if(!isVideoPlaying())
					{
						_setBufferingAnimation();
					}
				}
	
				//playing/fullscreen
				if(nStatus == 4)
				{
					//fullScreen
					evCtr = new VideoEvent("ebVLFullscreen",this._nFullScreen);
					dispatchEvent(evCtr);
				}
				
				//pause
				if(nStatus == 5)
				{
					evCtr = new VideoEvent("ebVLPause","");
					// Dispatch the event
					dispatchEvent(evCtr);
				}
				
				//fire status event for the users
				_strStatusChanged = this._getStatus(nStatus);
				Tracer.debugTrace("VideoLoader: statusChangedEvent: Fire event onStatusChanged(" + _strStatusChanged + ")",4);
				if ((root) && (strName + "_OnStatusChanged" in root))
					root[strName + "_OnStatusChanged"](_strStatusChanged);
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.STATUS_CHANGED,_videoEventInfo);
				dispatchEvent(ev);
				//fire progress event for the control
				evCtr = new VideoEvent("ebVLStatusChanged",_strStatusChanged);
				dispatchEvent(evCtr);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: statusChangedEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function movieEndEvent
		//============================
		//This function handles movie end event received from 
		//the player or proxy
		public function movieEndEvent():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: movieEndEvent: nOnMovieEnd = " + this.nOnMovieEnd,1);
						
				//no player
				if (!this._playerInst)
					return;
				//The triggered function is called in an interval
				//as a result, the exact moment the movie ends can be missed.
				//to avoid it, we take 0.5 sec gap.
				//we set interval to handle the 
				//video loop, when the video "really" ends
				if(this._nVideoLoopInSec > -1)
				{
					var length = this._playerInst.videoLength;
					var currPosition = this._playerInst.position;
					var timeToTheEnd =  (length - currPosition);
					//reset video to the start
					this._resetPlayer();
					this._reset();
					if(timeToTheEnd > 0)
						this._stripedProgInterval = setInterval(_stripedVideoProgress,timeToTheEnd*1000,100);
				}
				else	//handle movie end
				{
					_onMovieEnd();
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: movieEndEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function initVideoSizeEvent
		//============================
		//This function init the video size
		public function initVideoSizeEvent()
		{
			this._setVideoSize();
		}
		
		//============================
		//	function cuePointEvent
		//============================
		//This function handles cuePoint event received  
		public function cuePointEvent(info:Object):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: cuePointEvent("+info+")",1);
				//fire meta data event
				if ((root) && (strName + "_OnCuePoint" in root))
					root[strName + "_OnCuePoint"](info);
				var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.CUE_POINT,info);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: cuePointEvent: "+ error, 1);
			} 
		}
		
		//============================
		//	function metaDataEvent
		//============================
		//This function handles the metadata of the netstream
		public function metaDataEvent(info:Object):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: metaDataEvent("+info+")",1);
				_realVideoWidth = info.width;
				_realVideoHeight = info.height;
				 showVideo();
				//fire meta data event
				if ((root) && (strName + "_OnMetaData" in root))
					root[strName + "_OnMetaData"](info);
				var ev:EBMetadataEvent = new EBMetadataEvent(EBMetadataEvent.METADATA_RECEIVED,info);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: metaDataEvent: "+ error, 1);
			} 
		}
		
		//----mouse events-----
		
		//================================
		//	function shouldReportMouseMove
		//================================
		//This function set by the Controls component to indicate whether
		//the mouse move should be reported
		//Parameters:
		//	flag:Boolean
		public function shouldReportMouseMove(flag:Boolean)
		{
			try
			{
				this.fShouldReportMouseMove = flag;
				
				//set the onRollover/mouse move event handlers
				//if needed
				if(flag)	//should report
				{
					//we use the rollover/out events to identify
					//whether the mouse is over the component
					//(over -> track the mouse move, 
					//out -> retract the VideoControls) 
					this.addEventListener(MouseEvent.MOUSE_OVER, onRollOverHandler);//rollover
					this.addEventListener(MouseEvent.MOUSE_OUT, onRollOutHandler);//rollout
					
					//we use the mouse move to identify whether
					//the mouse was moved 
					//(no move in 5 secs -> retract the VideoControls)
					EBBase._stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveHandler); //mouse move
				}
			} 
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: shouldReportMouseMove: "+ error, 1);
			} 
		}
		
		//==============================
		//	function onRollOverHandler
		//==============================
		//This function handles MouseEvent.MOUSE_OVER event and trigger the correct 
		//behavior according to onRolloverArr
		public function onRollOverHandler(event:MouseEvent):void
		{
			Tracer.debugTrace("VideoLoader: onRollOver: onRolloverArr = " + this.onRolloverArr,1);
			this._onRollover(true);
		}
		
		//============================
		//	function onRollOutHandler
		//============================
		//This function handles MouseEvent.MOUSE_OUT event and trigger the correct 
		//behavior according to onRolloverArr
		// Parameters:
		//	event:MouseEvent: event object
		public function onRollOutHandler(event:MouseEvent):void
		{
			Tracer.debugTrace("VideoLoader: onRollOut: onRolloverArr = " + this.onRolloverArr,1);
			this._onRollover(false);
		}
		
		//==============================
		//	function onMouseMoveHandler
		//==============================
		//This function handles MouseEvent.MOUSE_MOVE event, used to 
		//display/hide the VideoControls.
		//It uses the rollover/out events to identify whether 
		//the mouse is over the component.
		// Parameters:
		//	event:MouseEvent: event object
		public function onMouseMoveHandler(event:MouseEvent):void
		{
			try
			{
				Tracer.debugTrace("onMouseMoveHandler: _fMouseOver = "+_fMouseOver, 6);
				
				//check if the mouse is over/out of the component
				var isMouseOver:Boolean = this.isOverComp(EBBase._stage.mouseX, EBBase._stage.mouseY);
				//check if the mouse is over the component
				//and its move should be tracked 
				if(isMouseOver)
				{
					//report mouseover
					//start mouse move - if the mouse doesn't move 
					//for 5 sec, report "mouseover: false"
					//(retract the VideoControls)
					if(this._startMouseMoveTime == -1)
					{
						this._startMouseMoveTime = getTimer();
						setInterval(this._checkMouseMove,500);
					}
					else
					{
						//The mouse moved before the 5 sec interval 
						//was eneded -> update time
						this._startMouseMoveTime = getTimer();
					}
					//mouse moved - report over
					if(!_fMouseOver)
						_reportMouseOver(true);
				}
				else
				{
					//mouse moved out - report off
					if(_fMouseOver)
					{
						_reportMouseOver(false);
					}
				}
			} 
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: onMouseMoveHandler: "+ error, 1);
			} 
		}
		
		//============================
		//	function onReleaseHandler
		//============================
		//This function handles MouseEvent.CLICK event trigger the correct 
		//behavior according to onClickArr
		// Parameters:
		//	event:MouseEvent: event object
		public function onReleaseHandler(event:MouseEvent):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: onRelease: onClickArr = " + this.onClickArr,1);
				_mouseClickHandler();
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: onReleaseHandler: "+ error, 1);
			} 
		}
		
		//-----Full Screen----	
		
		//============================
		//	function setFullScreen
		//============================
		public function setFullScreen(fullScreen:Boolean)
		{
			Tracer.debugTrace("VideoLoader: setFullScreen(" + fullScreen + ")",4);	
			//open fullScreen/page
			if(fullScreen)
				this.fSOpen();
			//close fullScreen/page
			else
				this.fSClose(0);
		}
		
		//============================
		//	function fSOpen
		//============================
		//This function set video to play in fullScreen. 
		//This function is called in the regular window
		public function fSOpen():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: fSOpen",4);
				//no player or the full screen is disabled or already open
				if ((!this._playerInst) || (this._nFullScreen != 1))
					return;
				//end timer before moving to full screen
				this._endVideoPlayDuration();
				
				//the values for the fscommand have no meaning (are stayed only for backward compatability) and therefore are set to default values instead of calculate it.
				var param = this._JSAPIFuncName + "," + 0 + "," + false + "," + 0 + "," + this._nReportedPlayProgress + "," + this._nUnmutedReported;
				EBBase.handleCommand("ebVideoFSOpen",param);
				//update attributes
				this._strInteractionPrefix = "ebFS";
				//start duration timer for full screen/page
				this._startVideoPlayDuration();
				//set _nFullScreen to 2 (full screen mode) 
				this._nFullScreen = 2;	
				//attatch the event to the listener in order to 
				// detect when the full screen is closed not by button of closing the full screen,
				// i.e. ESC.
				if (!_fRegisterFLVEvent)
				{
					EBBase._stage.addEventListener(FullScreenEvent.FULL_SCREEN, _fullScreenHandler);
				}
				//opening the full screen
				EBBase._stage.displayState = StageDisplayState.FULL_SCREEN	
				
				//In case of FLV or WMV full screen the "full screen" event 
				//is fired upon status 7 in "statusChangedEvent" function.
				//- For FLV upon changing the player status, "statusChangedEvent"
				//is called with the new status.
				//- For the WMV full screen (and only for full screen) the 
				//status is changed upon the JavaScript in order to notify 
				//the flash that the report prefix should be changed and the 
				//timer should be started, as mentioned above, we also take 
				//advantage of the situation and fire the "full screen" event.
				//- For WMV full page, starting the timer is not desired, and
				//because we still don't know to identify between full, we 
				//don't want the "statusChangedEvent" function to be called
				//with status 7. As a result in case of WMV full page,
				//"full screen" event is not fired and thus we need to fire
				//the event here. 
				//Note: because we still don't know to identify between full
				//screen and page, for full screen the event will be fired twice, 
				//here and in "statusChangedEvent" function.
				//fire fullScreen event
				var ev:VideoEvent = new VideoEvent("ebVLFullscreen",this._nFullScreen);
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: fSOpen: "+ error, 1);
			} 
		}
		
		//============================
		//	function fSClose
		//============================
		//This function set video back to regular screen
		//This function is called in the Full Page/Screen window
		//Parameters:
		//	nFullScreen:Number - the screen status, values:
		//		ebFSClose = 0 (default),
		// 		ebFSAutoClose = 1
		public function fSClose(nFullScreen:Number = 0):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: fSClose",3);
				if (_fRegisterFLVEvent)
				{
					EBBase._stage.removeEventListener(FullScreenEvent.FULL_SCREEN, this._fullScreenHandler);
					this._fRegisterFLVEvent = false;
				}

				//the full screen is disabled or already is regular mode
				if(_nFullScreen != 2)
					return;
					
				//fire fullScreen event
				var ev:VideoEvent = new VideoEvent("ebVLFullscreen",this._nFullScreen);
				dispatchEvent(ev);
				
				this._handleCloseFLVFS(Boolean(nFullScreen));
				this._videoFSEnd(-2, this._playerInst.getMute(), this._playerInst.getVolume(), this._nReportedPlayProgress, this._nUnmutedReported, false);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: fSClose: "+ error, 1);
			} 
		}
		
		//----General----
		
		//=========================
		//	function isOverComp
		//=========================
		//This function checks whether the mouse is over the component
		//Parameters:
		//	mouseX:Number - mouse x position
		//	mouseY:Number - mouse y position
		public function isOverComp(mouseX:Number, mouseY:Number)
		{
			try
			{
				//in case of videoPlayback the correct position is the position of the playBack 
				//and not the videoLoader
				var xPos = (_fInVideoPlayback)?this.parent.x:this.x;
				var yPos = (_fInVideoPlayback)?this.parent.y:this.y;
				
				var xInBoundaries = (xPos <= mouseX) && (xPos +__width >= mouseX);
				var yInBoundaries = (yPos <= mouseY) && (yPos +__height >= mouseY);
				return (xInBoundaries && yInBoundaries);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: isOverComp: "+ error, 1);
			} 
		}

		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----Reporting------
		
		//====================================
		//	function _reportPlayProgress
		//====================================
		//This function reports the playing progress interactions
		//The interactions:
		//	Started (ebVideoStarted fscommand)
		//	25% Played(eb25Per_Played fscommand)
		//	50% Played(eb50Per_Played fscommand)
		//	75% Played(eb75Per_Played fscommand)
		//	Fully played(ebVideoFullPlay fscommand)
		//Parameters:
		//	nPlayProgress:Number - the play progress percentage	
		private function _reportPlayProgress(nPlayProgress:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _reportPlayProgress("+nPlayProgress+")",4);
				
				// Check if reporting is enabled
				if (!_fShouldReport || !this._playerInst || _nReportedPlayProgress == 4 || !_fVideoDisplay)
					return;
				
				// Report the playing progress.
				// Note that no report should be "skipped".
				if ((this._playerInst.state == STATE.PLAY) && (_nReportedPlayProgress == -1))
				{
					EBBase.handleCommand("ebVideoInteraction","'ebVideoStarted','"+_nMovieNum+"'");
					_nReportedPlayProgress = 0;
				}
				if ((nPlayProgress >= 25) && (_nReportedPlayProgress < 1))
				{
					EBBase.handleCommand("ebVideoInteraction","'eb25Per_Played','"+_nMovieNum+"'");
					_nReportedPlayProgress = 1;
				}
				if ((nPlayProgress >= 50) && (_nReportedPlayProgress < 2))
				{
					EBBase.handleCommand("ebVideoInteraction","'eb50Per_Played','"+_nMovieNum+"'");
					_nReportedPlayProgress = 2;
				}
				if ((nPlayProgress >= 75) && (_nReportedPlayProgress < 3))
				{
					EBBase.handleCommand("ebVideoInteraction","'eb75Per_Played','"+_nMovieNum+"'");
					_nReportedPlayProgress = 3;
				}

				//playing is completed
				var fIsPlayingComplete:Boolean = 
									(this._playerInst.isPlayingComplete())
													|| (nPlayProgress == 100);
				// We garentee that the fscommand ebVideoFullPlay will be sent only when 
				// the movie reached to its end (fixing bug 11982).
				if (fIsPlayingComplete && (_nReportedPlayProgress == 3))
				{	
					EBBase.handleCommand("ebVideoInteraction","'ebVideoFullPlay','"+_nMovieNum+"'");
					_nReportedPlayProgress = 4;
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _reportPlayProgress: "+ error, 1);
			} 
		}
		
		//====================================
		//	function _startVideoPlayDuration
		//====================================
		//This function starts the playing progress timer
		//(trigger ebStartTimer fscommand)
		//Note: there are different reporting names for fullScreen/page and regular screen.
		private function _startVideoPlayDuration():void
		{
			try
			{
				// Check if reporting is enabled
				if (_fShouldReport && !this._fDurationTimerStatus)
				{
					var strTimer:String = _strInteractionPrefix + "VideoPlayDuration";
					Tracer.debugTrace("VideoLoader: _startVideoPlayDuration: Starting " + strTimer + " timer",4);
					EBBase.handleCommand("ebStartVideoTimer","'"+strTimer+"','"+_nMovieNum+"'");
					//Save the movie num the timer is started for
					//Note: In case we load an a new movie while playing another, the timer for the old movie should be stopped.
					//		Although we stop the old movie before updating the _nMovieNum parameter, in case of WMV we recieve the stop status which triggers
					//		ending the timer after updating the _nMovieNum, as a result we will try to end the timer of the new movie.
					_nMovieNumTimer = _nMovieNum;
					this._fDurationTimerStatus = true;
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _startVideoPlayDuration: "+ error, 1);
			} 
		}
	
		//====================================
		//	function _endVideoPlayDuration
		//====================================
		//This function ends the playing progress timer
		//(trigger ebEndTimer fscommand)
		//Note: there are different reporting names for fullScreen/page and regular screen.
		private function _endVideoPlayDuration():void
		{
			try
			{
				// Check if reporting is enabled
				if (_fShouldReport && this._fDurationTimerStatus)
				{
					var strTimer:String = _strInteractionPrefix + "VideoPlayDuration";
					Tracer.debugTrace("VideoLoader: _endVideoPlayDuration: End " + strTimer + " timer",4);
					EBBase.handleCommand("ebEndVideoTimer","'"+strTimer+"','"+_nMovieNumTimer+"'");
					this._fDurationTimerStatus = false;
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _endVideoPlayDuration: "+ error, 1);
			}
			
		}
		
		//==============================
		//	function _reportUnmute
		//==============================
		//This function reports the unmute interaction
		//Parameters:
		//	nInitiated:Number - indicates whether this is a user or auto initiated. 0 - auto;1 - user
		private function _reportUnmute(nInitiated:Number):void
		{
			try
			{
				//user initiated
				if(nInitiated)	
					EBBase.handleCommand("ebVideoInteraction","'ebVideoUnmute','"+_nMovieNum+"'");
						
				//unmuted is reported only once
				if(!this._nUnmutedReported)
				{
					this._nUnmutedReported = 1;
					EBBase.handleCommand("ebVideoInteraction","'ebVideoUnmuted','"+_nMovieNum+"'");
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _reportUnmute: "+ error, 1);
			} 
		}
	
		//----Init------
		
		//====================================
		//	function _initPlayer
		//====================================
		//This function initializes the player object 
		private function _initPlayer():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _initPlayer()", 6);
				EBVideoMgr.RegisterVideo(this);
				//protocol: streaming or progressive
				var fIsStreaming:Boolean = this._fIsStreaming;	
				//for offline URL - only progressive is used
				if(this._fOfflineURL)
					fIsStreaming = false;
				//Init _playerInst
				if(fIsStreaming)
				{
					//set external FCS - 
					//Note: in case of internal URL the value is empty string
					var strFCSURL:String = "";
					//external URL - send the FCS URL to the player constructor
					if(this._strExtVideoUrl != "")	
						strFCSURL = this._strExtFCSURL;
					
					this._playerInst = new StreamingPlayer(this.video,this.muteOnVideoStart,this._initVolume,this._nBufferSize, strFCSURL);
				}
				//	FLV progressive
				else
					this._playerInst = new ProgressivePlayer(this.video,this.muteOnVideoStart,this._initVolume,this._nBufferSize);
				//Register to the player events 
				//(progress/bufferProgress /changeStatus/videoEnded…)
				this._playerInst.addListener(this);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _initPlayer: "+ error, 1);
			} 
		}
	
		//====================================
		//	function _init
		//====================================
		//This function initializes the class attributes and set the size
		//(including scale).
		//This function is called from init function
		private function _init():void	
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _init",6);
				//update the instance count
				this._nCompID = ++_nInstCount;
				//register the JS API function
				this._JSAPIFuncName = "handleVideoLoader" + this._nCompID;
				EBBase.Callback(_JSAPIFuncName, JSAPIFunc)
				//call to the callBack function that th user implemented
				if (initComponentProperties != null)
					initComponentProperties();
				//init the component 
				this._initComp();
				
				//init class attributes
				this._initAttr();
				//Player
				//Send fscommand "ebInitVideoLoader"
				var strFSParam:String = this._JSAPIFuncName + "," 				//path
										+ Boolean(this.displayMode) + ","	//display mode 
										+ this._fIsStreaming + "," 	//playback mode
										+ this.fAutoPlay;	//auto play		
				//add position and size
				strFSParam = strFSParam + this._calcPosAndSize();
				//check if no event was attached to the onClick event
				var fHandleClick = (this.onClickArr.join() != "0,0,0");
				strFSParam += "," + fHandleClick; 
				strFSParam += "," + true;					//indicates that the component is new meaning not supporting WMV
				EBBase.handleCommand("ebInitVideoLoader",strFSParam);
				//Load/Play
				if (!this._fDynamicComp)
				{
					//Load/Play
					if(this.fAutoPlay) //auto play
					{
						//internal file
						if(!this._strExtVideoUrl)
							this.loadAndPlay(this._nMovieNum);
						else	//external file
							this.loadAndPlayExt(this._strExtVideoUrl);
					}
					else if (this.fAutoLoad)	//auto load
					{ 
						//internal file
						if(!this._strExtVideoUrl)
							this.load(this._nMovieNum);
						else	//external file
							this.loadExt(this._strExtVideoUrl);
					}
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _init: "+ error, 1);
			} 
		}
		
		//====================================
		//	function _initComp
		//====================================
		//This function initializes the component
		private function _initComp():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader _initComp", 6);
				//Admin component identification
				EBBase.ebSetComponentName("VideoLoader");
				super.scaleX = 1;
				super.scaleY = 1;

				//component background (the only component child that is not added dynamically)
				//set background to be transparent
				if (!this._fDynamicComp)
				{
					//when reopen an asset the component comes back to its original size unless changing the values again of the setSize function parameters
					if(__width && __height)
					{
						_originalWidth = __width;
						_originalHeight = __height;
					}
					
					this._bg_mc = this.getChildAt(0) as MovieClip;
					_setHelp_mc();
				}
				else
				{
					_createBg_mc();
				}
				this._bg_mc.alpha = 0;
				//buffering
				this._buffering_mc = new MovieClip();
				this._buffering_mc.name = "_buffering_mc";
				this._buffering_mc.x = 0;
				this._buffering_mc.y = 0;
				this.addChild(this._buffering_mc);
				
				//set size attributes
				this.setSize(_originalWidth, _originalHeight);
				//set init video container size
				this.video.width = _originalWidth;
				this.video.height = _originalHeight;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _initComp: "+ error, 1);
			} 
		}
		
		//====================================
		//	function _setHelp_mc
		//====================================
		//This function set the mc of the help of live preview
		//====================================
		//	function _setHelp_mc
		//====================================
		//This function set the mc of the help of live preview
		private function _setHelp_mc()
		{
			this._helpLoader_mc = this.getChildAt(1) as MovieClip;
			this._helpPlayback_mc = this.getChildAt(2) as MovieClip;

			//handle live preview
			if(_isLivePreview)
			{
				if(_fInVideoPlayback)
				{
					this._helpPlayback_mc.alpha = 1;
					this._helpPlayback_mc.visible = true;
					this._helpLoader_mc.visible = false;
				}
				else	
				{
					this._helpLoader_mc.visible = true;
				}
			}
			else
			{
				this._helpLoader_mc.visible = false;
				this._helpPlayback_mc.visible = false;
			}
		}
		
		//====================================
		//	function _createBg_mc
		//====================================
		//This function create the _bg_mc when it is dynamic component
		private function _createBg_mc()
		{
			this._bg_mc = new MovieClip();
			addChild(this._bg_mc);
			this._bg_mc.graphics.beginFill(0x000000);
			if(this.__width)
				_originalWidth = this.__width;
			if (this.__height)
				_originalHeight = this.__height;
			this._bg_mc.graphics.drawRect(0,0,_originalWidth,_originalHeight);
			this._bg_mc.graphics.endFill();
			this._bg_mc.x = _bg_mc.y = 0;
		}
		
		//====================================
		//	function _initAttr
		//====================================
		//This function initializes the class attributes
		private function _initAttr():void
		{
			try
			{
				//set the name of the component. This property can be set only when the component is dynamic. the property can not be set for an object that was placed on the timeline in the Flash authoring tool
				if (_fDynamicComp)
					this.name = _instName;
				//init the component memebers
				this._strMovieURL = "";		//holds the video URL currently loading/playing
				this._nMovieNum = this.nVideoFileNum;		//Indicates the ordinal number of the video currently loaded, 1 for "ebMovie1",…
				this._nBufferSize = -1;		//Buffer size
				this._strExtFCSURL = "";	//External FCS URL.
				this._strExtVideoUrl = this.strExtVideoUrl; //the externla video URL
				this._fRegisterFLVEvent = false;
				this._playerInst = null;
				this._initVolume = 100;	//speaker volume
				this._fSendMuteEvent = false;		//Indicates whether the mute event was send to init the mute status
				
				//----Dynamic mask------
				this._nVideoLoopInSec = -1;	//Used by DynamicMask component, the number of Secs to loop the video
				this._stripedProgInterval = -1;	//Interavl for video strip loop (make sure that _stripedVideoProgress will be called when the video ends)
				this._nLoopNum = 1;			//first play of the video is first loop.
		
				//----Reporting------
				this._fShouldReport = true;			//Indicates if interactions should be reported.
													//Set by the dynamic mask component to prevent reporting when retracted
				this._fEnableReplay = false;			//Indicates whether replay can be reported
						
				this._fDurationTimerStatus = false;		//Indicates the timer status (on/off)
				//----General------
				//Set _fIsStreaming, the javascript setting override the 
				//user selection
				if(typeof(EBBase.urlParams.ebForcePlayMode) != "undefined")
				{
					this._fIsStreaming = Boolean(Number(EBBase.urlParams.ebForcePlayMode));
				}
								
				//-----Events-----
				this.fShouldReportMouseMove = false;	//Indicates whether the mousemove event should be reported
				this._fMouseOver = false;		//indicates the value reported in mouseover event
				this._startMouseMoveTime = -1;	//holds the start mouse movement time
				this._nCurrPlayProgress = 0;
				this._nCurrLoadProgress = 0;
				this._nCurrBufferProgress = 0;
				this._strStatusChanged = "";
				this._videoEventInfo = new Object();
				//set the onRollover event handler
				//if needed
				if(this.onRolloverArr.toString() != "0,0,0")	//none
				{
					//we use these 2 events to trigger the
					//appropriate behvior set by the user
					this.addEventListener(MouseEvent.MOUSE_OUT, onRollOutHandler);
					this.addEventListener(MouseEvent.MOUSE_OVER, onRollOverHandler);
				}
				
				//set the onRelease event handler
				//if needed
				if(this.onClickArr.toString() != "0,0,0") //none
				{
					//we use this event to trigger the
					//appropriate behvior set by the user
					this.addEventListener(MouseEvent.CLICK,onReleaseHandler);
					//allow the movie clip to behaves as a button, which means that it 
					//triggers the display of the hand cursor when the mouse passes over
					//the  movie clip 
					this._bg_mc.buttonMode = true;
				}
				//init attributes for playing
				this._reset();
				
				//report unmute
				if(!this.muteOnVideoStart)
					this._reportUnmute(0);
					
				//fire event
				var evVol:VideoEvent = new VideoEvent("ebVLVolume", this._initVolume);
				// Dispatch the event
				dispatchEvent(evVol);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _initAttr: "+ error, 1);
			} 
		}
		
		//-----General------
		
		//===========================
		//	function _clearVideo
		//===========================
		//This function clears the player object and the video object  
		//[Incompletely releasing the video leads to problems.
		// If the same FLV is subsequently reloaded and its video or audio
		// is already attached to the movie, the NetStream.play() call will fail].
		private function _clearVideo():void
		{
			Tracer.debugTrace("VideoLoader: _clearVideo: releaseVideo",6);
			try
			{
				this._playerInst.close();
				this._playerInst = null;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _clearVideo: "+ error, 1);
			}
			
		}
		
		//===========================
		//	function _initMuteState
		//===========================
		//This function send "mute" event to init the mute state
		private function _initMuteState():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _initMuteState",6);
				//mute state
				var fMute:Boolean = this.muteOnVideoStart;
				if(this._playerInst)
					fMute = this._playerInst.getMute();
				var ev:VideoEvent = new VideoEvent("ebVLMute",fMute);
				// Dispatch the event
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _initMuteState: "+ error, 1);
			} 
		}
		
		//===========================
		//	function _setActiveMode
		//===========================
		//This function updates the javascript with the video mode (active or not)
		//Parameters:
		//	fMode:Boolean - indicates the video mode
		private function _setActiveMode(fMode:Boolean):void
		{
			Tracer.debugTrace("VideoLoader: _setActiveMode",6);
			try
			{
				EBBase.handleCommand("ebVideoActiveMode", this._JSAPIFuncName + "," + fMode);
				this._fIsVideoActive = fMode;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setActiveMode: "+ error, 1);
			} 
		}
		
		//==================
		//	function _reset
		//==================
		//This function reset the class attributes for replay
		private function _reset()
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _reset",6);
				
				//not in full page
				if(this._nFullScreen != 2)
				{
					this._nFullScreen = 0;		//fullScreen/page state - disabled
					//Interactions prefix
					this._strInteractionPrefix = "eb";		//regular window
					Tracer.debugTrace("VideoLoader: _reset disable full page",6);
				}
				
				this._fAutoPlay = false;	//Indicates if the video should be auto played
				
				this._fIsVideoActive = true;	//Indicates whether the video is active or not
					
				//----Reporting------
				this._nReportedPlayProgress = -1;	//Indicates playing progress
													//-1: Not started; 0: Started; 1: 25% Played; 2: 50% Played; 3: 75% Played; 4: Fully played
				
				//----Events------	
				//fullScreen
				var fsEv:VideoEvent = new VideoEvent("ebVLFullscreen", this._nFullScreen);
				// Dispatch the event
				dispatchEvent(fsEv);
				
				//pause (change the button state)
				var playEv:VideoEvent = new VideoEvent("ebVLPause", "");
				// Dispatch the event
				dispatchEvent(playEv);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _reset: "+ error, 1);
			} 
			
		}
		
		//=======================
		//	function _getStatus
		//=======================
		//This function convert the status number to string
		//Parameters:
		//	nStatus:Number - the video status, defualt value is 0
		private function _getStatus(nStatus:Number = 0)
		{
			try
			{
				var strStatus:String = "";
				switch(nStatus)
				{
					//Error
					case -1:
						strStatus = "Error";
					break;
					//Idle
					case 0:
						strStatus = "Idle";
					break;
					//Loading
					case 1:
						strStatus = "Loading";
					break;
					//Buffering
					case 2:
						strStatus = "Buffering";
					break;
					//Ready
					case 3:
						strStatus = "Ready";
					break;
					//Playing
					case 4:
						strStatus = "Playing";
					break;
					//Paused
					case 5:
						strStatus = "Paused";
					break;
					//Stopped
					case 6:
						strStatus = "Stopped";
					break;
					default:
						strStatus = "Idle";
					break;
				}
				return strStatus;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _getStatus: "+ error, 1);
			} 
		}
		
		//===================================
		//	function _setBufferingAnimation
		//===================================
		//This function set the buffering animation
		private function _setBufferingAnimation()
		{
			try
			{
				Tracer.debugTrace("_setBufferingAnimation", 6);
		
				//show buffering animation
				if(_buffering_mc.numChildren == 0)
				{
					//add animation
					var animation_mc:Buffering = new Buffering();
					_buffering_mc.addChild(animation_mc);
					_buffering_mc.width = this.__width;
					_buffering_mc.height = this.__height;
				}
			} 
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setBufferingAnimation: "+ error, 1);
			} 
			
		}
		
		//====================================
		//	function _resetPlayer
		//====================================
		//The function reset the player and set _fPauseOnLastFrame back to false 
		//The function is triggered when loading or playing video and before that the movie paused at last frame
		private function _resetPlayer()
		{
			Tracer.debugTrace("_resetPlayer", 6);
			this._playerInst.reset();
			this._fPausedOnLastFrame = false;
		}
		
		//=======================
		//	function _resetVideo
		//=======================
		//reset the video and hide the video
		private function _resetVideo():void
		{
			//reset video to the start
			this._resetPlayer();
			this._reset();
			//hide the video
			this.video.visible = false;
		}
		
		//=======================
		//	function _replayVideo
		//=======================
		//replay the video: reset the player and then play
		private function _replayVideo():void
		{
			//we send parameter with value false, so in replay the video will play smoothly (the video will not be cleared)
			this._playerInst.setClearVideoFlag(false);
			this._resetPlayer();
			this._reset();
			if(this._fIsStreaming && this.fAutoPlay)
				this.nOnMovieEnd = 0;
			this._play();
		}
		
		//----Loop------
		
		//====================================
		//	function _stripedVideoProgress
		//====================================
		//This function handles the video strip loop (jump to the start) if needed
		//Called from playProgressEvent
		//	Parameters:
		//		Number:risk - time till the end of the movie
		private function _stripedVideoProgress(playProgress:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _stripedVideoProgress(" + playProgress + ")" ,6);
				
				//Indicating if the video should loop:
				//looping in streaming is limited to 2 loops.
				//in progressive itis not limited.
				var fShouldLoop:Boolean = ((!this._fIsStreaming) || (this._nLoopNum <_nMaxLoopsForStreaming));
		
				Tracer.debugTrace("VideoLoader: _stripedVideoProgress: fShouldLoop=" + fShouldLoop ,6);

				if(this._nVideoLoopInSec > -1)
				{
					//looping the whole movie
					if(this._nVideoLoopInSec == 0)
					{
						if(100 <= playProgress)
							this.handleVideoLoop(fShouldLoop);
					}
					//looping _nVideoLoopInSec sec
					if(_nVideoLoopInSec > 0)
					{
						var videoPos:Number = this._playerInst.videoLength * playProgress/100;
						Tracer.debugTrace("VideoLoader: _stripedVideoProgress(videoPos="+videoPos+", _nVideoLoopInSec="+this._nVideoLoopInSec,6); 
						if(this._nVideoLoopInSec <= videoPos)
							this.handleVideoLoop(fShouldLoop);
					}
				}
				//reset interval
				if(this._stripedProgInterval != -1)
				{
				   clearInterval(this._stripedProgInterval);
				   this._stripedProgInterval = -1;
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _stripedVideoProgress: "+ error, 1);
			} 
		}
	
		//====================================
		//	function handleVideoLoop
		//====================================
		//This function handles the video strip loop (jump to the start) if needed
		//Called from _stripedVideoProgress
		//	Parameters:
		//		fShouldLoop:Boolean - indicates whether the video should be looped
		function handleVideoLoop(fShouldLoop:Boolean):void
		{
			try
			{
				if(fShouldLoop)
				{
					Tracer.debugTrace("VideoLoader: handleVideoLoop: replaying the video",6);
					//loop
					this._stop();
					this._play();
					/********
					//right now there is a bug that it flickers in the loop. check if we can change to
					
					this._playerInst.setClearVideoFlag(false);
					this._resetPlayer();
					this._reset();
					this._play();
					*******************/
					//increase the loop counter
					this._nLoopNum++;
				}
				else
				{
					//stop the video
					this._stop();					
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: handleVideoLoop: "+ error, 1);
			} 
		}
	
		//----Control - called by the API-----
		
		//==================
		//	function _play
		//==================
		//This function starts the video playback
		//called by VideoPlay API function
		private function _play():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _play",6);
				if (!this._playerInst)
					return;
				//check if we arrived to play video after the video paused at last frame. 
				//In this case we should reset the video (so it will start from the beginning)
				if (_fPausedOnLastFrame)
					_resetPlayer();
				
				var nStatus:Number = this._playerInst.getStatus();
				//Play only when not playing
				if(!this.isVideoPlaying())
				{
					//Idle/Stopped status -> the user tries to replay
					if((nStatus == 0) || (nStatus == 6))
					{
						//the video URL is availble
						if( _strMovieURL != "")
						{
							//In case a movie was changed and the movie was already loaded before we need to set value again according the JS about the state of the 
							//state of the full screen button
							if (this._nFullScreen != 2)
							{
								var FSIndex = _strMovieURL.lastIndexOf("::") - 1;
								this._nFullScreen = Number(_strMovieURL.substring(FSIndex,FSIndex+1));
							}
						}
						else
						{
							Tracer.debugTrace("VideoLoader: No video to display",1);
							return;
						}
					}
					this._playerInst.play();
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _play: "+ error, 1);
			} 
		}
		
		//==================
		//	function _stop
		//==================
		//This function stop the video playback
		//called by VideoStop API function
		private function _stop():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _stop",6);
				//no player
				if (!this._playerInst)
					return;
				this._playerInst.stop();
				this._reset();
				this._fEnableReplay = true;		//enable replay
				//hide the video
				this.video.visible = false;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _stop: "+ error, 1);
			} 
		}
		
		//==================
		//	function _pause
		//==================
		//This function pause the video playback
		//called by VideoPause API function
		//Parameters:
		//	fShouldReport:Boolean [optional] - indicates whether the interaction should be reported
		private function _pause(fShouldReport:Boolean = true):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _pause",6);
				
				//no player
				if (!this._playerInst)
					return;
					
				//pause
				this._playerInst.pause();
				
				//send interaction 
				if(fShouldReport)
					EBBase.handleCommand("ebVideoInteraction","'"+this._strInteractionPrefix + "VideoPause','"+_nMovieNum+"'");
				
				//reset flag
				this._fIsVideoActive = true;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _pause: "+ error, 1);
			} 
		}
		
		//==================
		//	function _seek
		//==================
		//This function seek the video to nSec position
		//called by VideoSeek API function
		//Parameters:
		//	nSec:Number - The time value, in seconds, to move to in 
		//				  the video
		private function _seek(nSec:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _seek("+nSec+")",6);
				this._playerInst.seek(nSec);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _seek: "+ error, 1);
			} 
		}
		
		//====================================
		//	function _initBeforeLoad
		//====================================
		function _initBeforeLoad()
		{
			this._realVideoWidth = 0;
			this._realVideoHeight = 0;
			this._fVideoDisplay = false;
			this._fEnableReplay = false;
		}
		
		//====================================
		//	function _setVideoLoad
		//====================================
		//This function is called by VideoLoad and VideoLoadAndPlay
		//To set the video to download /download and and play.
		//This function calls _startLoad function to load/load and play 
		//the video if the video URL is available or sends an fscommand 
		//to the javascript to recieve the URL.
		//Parameters:
		//	nMovieNum:Number - the video ordinal number, for example 1 
		//					   for "ebMovie1"
		//	fShouldPlay:Boolean -  indicates it the video should be played
		//	nFSMovieNum:Number - the video ordinal number to be loaded in full page, for example 1 
		//					   	 for "ebMovie1"
		function _setVideoLoad(nMovieNum:Number,fShouldPlay:Boolean):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setVideoLoad("+ nMovieNum + "," + fShouldPlay + ")",6);
				//no need to load and play the movie if it livePreview
				if(_isLivePreview)
					return;

				//check if the video is playing	already
				if(isVideoPlaying() || this._playerInst)
				{
					//check if we arrived to play video after the video paused at last frame. 
					//In this case we also call to _changeStatus (what we don't do in the else part in _stop function)
					if (_fPausedOnLastFrame)
					{
						_resetPlayer();
					}
					else
					{
						this.muteOnVideoStart = this._playerInst.getMute();	//mute
						this._initVolume = this._playerInst.getVolume();	//volume
						//stop the video
						_stop();
					}
				}
				_initBeforeLoad();
				//set attributes
				this._fAutoPlay = fShouldPlay;	//auto play indication 
				this._nMovieNum = nMovieNum;	//main page video 
				this._strExtVideoUrl = "";		//reset external URL
				this._fIgnoreJSResponse = false;	//reset flag
				//fscommand params
				var param:String = "";
				//running "offline"
				if(typeof(EBBase.urlParams.ebDomain) == "undefined")
				{
					//check if an offline file is available
					if((typeof(this.offlineVideoFile) != "undefined")
							   && (this.offlineVideoFile != ""))
					{
						Tracer.debugTrace("VideoLoader: offline",1);
						//set an indication that an offline URL is used 
						this._fOfflineURL = true;	
						//build the video string (including video URL, video format [FLV] and full screen mode [disabled])
						//for _startLoad function
						//Note that an equivalent string is sent by the JavaScript for online internal URL
						param = this.offlineVideoFile + "::" + "1::0::0";
						//load
						this._startLoad(param);
					}
				}
				else	
				{	
					//set indication that online URL is used 
					this._fOfflineURL = false;
					//build the fscommand parameter string
					param = this._JSAPIFuncName +"," 
									   + "ebMovie" + nMovieNum	+ "," //movie num to load
									   + this.muteOnVideoStart + "," 	//mute
									   + this._initVolume + ","		//volume
									   + this._nBufferSize + ","	//buffer size
									   + "ebMovie" + nMovieNum + ","	//movie num to be loaded in full page
									   + true + ","				//indicates that it the component supports FLV full screen
									   
					EBBase.handleCommand("ebVideoLoad", param);
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setVideoLoad: "+ error, 1);
			} 
		}
		
		//====================================
		//	function _setVideoLoadExt
		//====================================
		//This function is called by VideoLoadExt and VideoLoadAndPlayExt
		//To set an external video to download /download and and play.
		//This function calls _startLoad function to load/load and play 
		//the video.
		//Parameters:
		//	strMovieURL:String - external media file URL
		//	fShouldPlay:Boolean -  indicates it the video should be played
		function _setVideoLoadExt(strMovieURL:String, fShouldPlay:Boolean):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setVideoLoadExt("+ arguments + ")",6);
				//check if the video is playing	already
				if(isVideoPlaying() || this._playerInst)
				{
					//check if we arrived to play video after the video paused at last frame. 
					//In this case we also call to _changeStatus (what we don't do in the else part in _stop function)
					if (_fPausedOnLastFrame)
					{
						_resetPlayer();
					}
					else
					{
						this.muteOnVideoStart = this._playerInst.getMute();	//mute
						this._initVolume = this._playerInst.getVolume();	//volume
						//stop the video
						_stop();
					}
				}
				_initBeforeLoad();
				//indicate that in case of request to internal video
				//was made before lodaing this media - ignore the response.
				this._fIgnoreJSResponse = true;	
				//set attributes
				this._fAutoPlay = fShouldPlay;		//auto play indication 
				this._strExtVideoUrl = strMovieURL;		//external video url
				this._fOfflineURL = false;		//indicates that an online URL is used

				//if FCS URL was not set, we can't load the file
				if((this._strExtFCSURL == "") && this._fIsStreaming)
				{
					Tracer.debugTrace("VideoLoader: _setVideoLoadExt: can't load the file, there is no FCS URL",2);
					return;
				}
				
				//build the video string (including video URL, video format [FLV] and full screen mode [disabled])
				//for _startLoad function.
				//Note that an equivalent string is sent by the JavaScript for online internal URL
				var param:String = this._strExtVideoUrl + "::" + "1::0::0";
				//load
				this._startLoad(param);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setVideoLoad: "+ error, 1);
			} 
		}
			
		//====================================
		//	function _startLoad
		//====================================
		//This function downloads a video file, and start playing 
		//the video automatically, if _fAutoPlay is true.
		//Parameters:
		//	strMovie:String -  a string containing:
		//		Video URL - video URL
		//		Video format - WMV(0), FLV(1)
		//		FullScreen flag - disabled(0), regular mode(1), full screen/page mode(2)
		//		The different values are seperated by double colon.
		private function _startLoad(strMovie:String):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _startLoad(" + strMovie + ")",6);
				
				//loading and playing the video is not synchronic
				//because we wait for the JavaScript response.
				//This is the place syncing the different requests to play media
				//thus if we need to switch media we will do it here
				if(this._playerInst)
				{
					//stop and clear media
					this._playerInst.stop();
					this._clearVideo();
				}
				
				//save strMovie
				_strMovieURL = strMovie;
				
				//Split strMovie to URL, Format and FullScreen
				var MovieParams:Array = strMovie.split("::");
				
				//Save the different values in the appropraite class attributes
				var strURL:String = MovieParams[0];		//video URL
				var nMediaType = parseInt(MovieParams[1]);               //media type
				if (this._nFullScreen != 2)
					this._nFullScreen = parseInt(MovieParams[2]);	//full screen mode
				//In case the movie is WMV playerIns should not be created and the movie should not be played
				if (nMediaType == 0)
					return;
				
				//Init _playerInst
				this._initPlayer();
				//set buffering animation
				_setBufferingAnimation();
				//Start load
				this._playerInst.load(strURL, this._fAutoPlay);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _startLoad: "+ error, 1);
			} 
		}
		
		//=======================
		//	function _setMute
		//=======================
		//This function set or unset speaker mute according to 
		//nMuteVal value.
		//this function called by VideoSetMute
		//Parameters:
		//	nMuteVal:Number - the speaker mute state, values:
		//		ebUnMute = 0
		//		ebMute= 1
		//		ebToggle = 2 (default)	
		//	fShouldReport:Boolean - indicates whether the mute interaction should be reported
		private function _setMute(nMuteVal:Number,fShouldReport:Boolean):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setMute("+nMuteVal+")",6);
				if(!this._playerInst)
					return;
				//current Mute state
				var fMute:Boolean = this._getMuteState(nMuteVal);
				
				//illegal value
				if((nMuteVal > 2) || (nMuteVal < 0))
				{
					Tracer.debugTrace("VideoLoader: Error - VideoSetMute: "+nMuteVal +" is not an appropriate value for this function",1);
					return;
				}
				
				//set speaker mute state and fire the "mute" event
				this._setMuteState(fMute);
					
				//send mute interaction
				if(fMute && fShouldReport)
					EBBase.handleCommand("ebVideoInteraction","'"+this._strInteractionPrefix + "VideoMute','"+_nMovieNum+"'");
				
				//user/auto initiated (1/0)
				//[In case of user initiated fShouldReport will be true
				//and vice versa]
				var nInitiated:Number = fShouldReport?1:0;
				
				//report unmute
				if(!fMute)
					this._reportUnmute(nInitiated);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setMute: "+ error, 1);
			} 
		}
		
		//=======================
		//	function _getMuteState
		//=======================
		//This function get the speaker mute state according to 
		//nMuteVal value.
		//this function called by _setMute
		//Parameters:
		//	nMuteVal:Number - the speaker mute state, values:
		//		ebUnMute = 0
		//		ebMute= 1
		//		ebToggle = 2 (default)	
		private function _getMuteState(nMuteVal:Number):Boolean
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _getMuteState("+nMuteVal+")",6);
				
				//current mute state
				var fMute:Boolean = this.muteOnVideoStart;
				//if no video was loaded, use the init value
				if(this._playerInst)
					fMute = this._playerInst.getMute();
					
				//toggle
				if(nMuteVal == PlayerConstants.ebToggle)
				{
					fMute = !fMute;
				}
				//set/unset
				else if((nMuteVal == PlayerConstants.ebMute) || 
									(nMuteVal == PlayerConstants.ebUnMute))
				{
		
					fMute = Boolean(nMuteVal);	
				}
				return fMute;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _getMuteState: "+ error, 1);
			} 
			return false;
		}
		
		//=======================
		//	function _setMuteState
		//=======================
		//This function set the speaker mute state.
		//this function called by _setMute
		//Parameters:
		//	fMute:Boolean - speaker mute state	
		private function _setMuteState(fMute:Boolean):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setMuteState("+fMute+")",6);
				
				//set speaker mute state
				if(this._playerInst)
					this._playerInst.setMute(fMute);
				else	//no video was loaded,set the init value
					this.muteOnVideoStart = fMute;
					
				//fire the "mute" event
				var ev:VideoEvent = new VideoEvent("ebVLMute",fMute);
				// Dispatch the event
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setMuteState: "+ error, 1);
			} 
		}
		
		//============================
		//	function _setVolume
		//============================
		//This function set the speaker volume for the video
		//This function is called by VideoSetVolume API function
		//Parameter:
		//	nVolLevel:Number - volume level (0-100)
		private function _setVolume(nVolLevel:Number):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setVolume("+nVolLevel+")",6);
				
				if (!this._playerInst)
					return;
				//set volume
				if(nVolLevel < 0)
					nVolLevel = 0;
				if(nVolLevel > 100)
					nVolLevel = 100;
				this._playerInst.setVolume(nVolLevel);
				
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVLVolume",nVolLevel);
				// Dispatch the event
				dispatchEvent(ev);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setVolume: "+ error, 1);
			} 
		}
		
		//-----Events------
		
		//==============================
		//	function _mouseClickHandler
		//==============================
		//This function handlers the MouseEvent.CLICK event recieved from the JS or component
		function _mouseClickHandler()
		{
			try
			{
				//video status - used to toggle play/pause.
				var nStatus:Number = 0;
				if (this._playerInst)
					nStatus = this._playerInst.getStatus();
				
				//Triggers the correct behavior according to onClickArr
				//click thru URL (0); Pause/Play (1) ; Custom (2); - the default is 0
				for(var i=0;i<this.onClickArr.length;i++)
				{
					//selected option
					if(this.onClickArr[i])
					{
						switch(i)
						{
							//click thru URL
							case 0:
								EBBase.Clickthrough();
							break;
							//Pause/Play
							case 1:
								//play
								if(nStatus == 4)
									this._pause(true);
								//pause
								else if(nStatus == 5)	
									this._play();
							break;
							//Custom
							case 2:
								//fire event
								Tracer.debugTrace("VideoLoader: onRelease: Fire event onClick",6);
								if ((root) && (strName + "_OnClick" in root))
									root[strName + "_OnClick"]();
							break;
						}
					}
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _mouseClickHandler: "+ error, 1);
			} 
		}
		
		//===========================
		//	function _checkMouseMove
		//===========================
		//This function checks wheteher the mouse moved
		//in the last 5 sec, if it didn't, it reports mouse off
		//This function is used for hidding/displaying the 
		//VideoControls on rollover/out
		function _checkMouseMove():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _checkMouseMove",4);
				var timePassed:Number = 0;	//time passed till the mouse move started
				var currTime:Number = getTimer();
				timePassed = currTime - this._startMouseMoveTime;
	
				//check the time passed since the last mouse move
				var fIsOver = (timePassed > 5000);
							
				//5 secs passed - report mouse off
				if(fIsOver && _fMouseOver)
				{
					_reportMouseOver(false);
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _checkMouseMove: "+ error, 1);
			} 
		}
		
		//=======================
		//	function _onRollover
		//=======================
		//This function handles onrollover event
		//Triggers the correct behavior according to onRolloverArr
		//this function is called by onRollover/out events
		//Parametes:
		//	fIsOver:Boolean - indicates if the event is rollover or rollout 
		private function _onRollover(fIsOver:Boolean):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _onRollover(" + fIsOver + ")",4);
				
				//video status - used to toggle play/pause.
				var nStatus:Number = 0;
				if (this._playerInst)
					nStatus = this._playerInst.getStatus();
					
				//Triggers the correct behavior according to onRolloverArr
				//Play/Pause (0); Mute/Unmute (1); Custom (2); - the default is none
				for(var i=0;i<this.onRolloverArr.length;i++)
				{
					//selected option
					if(this.onRolloverArr[i])
					{
						switch(i)
						{
							//Pause/Play
							case 0:
								//play
								if(nStatus == 4)
									this._pause(true);
								//pause
								else if(nStatus == 5)	
									this._play();
							break;
							//Mute/Unmute
							case 1:
									this._setMute(PlayerConstants.ebToggle,true);
							break;
							//Custom
							case 2:
								//fire event
								Tracer.debugTrace("VideoLoader: _onRollover: Fire event onRollover",6);
								if ((root) && (strName + "_OnRollover" in root))
									root[strName + "_OnRollover"](fIsOver);
							break;
						}
					}
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVLRollover",fIsOver);
				// Dispatch the event
				dispatchEvent(ev);
			} 
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _onRollover: "+ error, 1);
			} 
		}
		
		//===========================
		//	function _reportMouseOver
		//===========================
		//This function reports the mouseover event and updates
		//_fMouseOver.
		//This function is used for hidding/displaying the 
		//VideoControls on rollover/out. 
		//It is called from _checkMouseMove
		//to hide the VideoControls and from onMouseMoveHandler 
		//to display it.
		private function _reportMouseOver(fIsOver:Boolean):void
		{
			try
			{
				//update _fMouseOver
				_fMouseOver = fIsOver;
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVLMouseover",fIsOver);
				// Dispatch the event
				dispatchEvent(ev);
			} 
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _reportMouseOver: "+ error, 1);
			} 
		}
		
		//===========================
		//	function _onMovieEnd
		//===========================
		//This function handles the movie end event
		//It is called from movieEndEvent
		private function _onMovieEnd():void
		{
			try
			{
				//no player
				if (!this._playerInst)
					return;
				
				//verify that ebVideoFullPlay is reported
				this._reportPlayProgress(100);
				//Triggers the correct behavior according to _nOnMovieEnd
				//None (0) - default; Replay (1); Stop on last frame(2); Goto frame (3); Custom (4); Close (5); 
				switch(this.nOnMovieEnd)
				{
					//None
					case 0:
						this._resetVideo();	
					break;
					//Replay
					case 1:
						this._replayVideo();
					break;
					//Stop on last frame
					case 2:
						this._playerInst.pause();
						this._reset();
						this._fPausedOnLastFrame = true;
					break;
					//GoToFrame
					case 3:
					this._resetVideo();	
						var mainT = root as DisplayObject;
						mainT.gotoAndPlay(this.nGoToFrame);
					break;
					//Custom
					case 4:
						this._resetVideo();	
						//fire event
						if ((root) && (strName + "_OnMovieEnd" in root))
							root[strName + "_OnMovieEnd"]();
					break;
					//Close
					case 5:
						this._resetVideo();	
						EBBase.CloseAd("Auto");
					break;
				}
				
				//fire event
				setVideoEventInfo(_nCurrPlayProgress,_nCurrLoadProgress,_nCurrBufferProgress,_strStatusChanged)
				var ev:EBVideoEvent = new EBVideoEvent(EBVideoEvent.MOVIE_END,_videoEventInfo);
				dispatchEvent(ev);
				
				//reset attributes for replay
				this._fEnableReplay = true;		//enable replay
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _onMovieEnd: "+ error, 1);
			} 
		}
		
		//-----Size------
		
		//=========================
		//	function _resetSize
		//=========================
		//This function reset the video size to its original size
		private function _resetSize():void
		{
			//save width and height and set scale
			//to 100 otherwise the component and its content
			//will be scaled.
			var tmpWidth:Number = _originalWidth;
			var tmpHeight:Number = _originalHeight;
			super.scaleX = 1;
			super.scaleY = 1;
			//set size
			this.setSize(tmpWidth, tmpHeight);
			//set init video container size
			this.video.width = tmpWidth;
			this.video.height = tmpHeight;
			//reset position
			this.video.x = this.video.y = 0;
		}
		
		//=========================
		//	function _setVideoSize
		//=========================
		private function _setVideoSize():void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _setVideoSize",3);
				//when the movie is stopped we should reset the size of the component to its original size, otherwise the size will
				//not be correct when the movie will play again (upon play we calc the video size using the component size)
				if(_fInVideoPlayback)
					this._resetSize();
				//video original size
				var videoWidth:Number = _realVideoWidth;
				var videoHeight:Number = _realVideoHeight;
				
				//the video object init size
				var videoOrgWidth:Number = this.video.width;
				var videoOrgHeight:Number = this.video.height;
				
				//component scale
				var xscale:Number = scaleX;
				var yscale:Number = scaleY;

				//the component is inside VideoPlayback,
				//we should take into account the VideoPlayback scale
				//as movie clip size is scaled by its container scale automatically
				if(_fInVideoPlayback)
				{
					//VideoPlayback scale
					xscale = parent.scaleX;
					yscale = parent.scaleY;
					
					//saving component size with the VideoPlayback scale (need to add the scale in case of videoPlayBack in order to get the real size)
					this.__width = (this.__width * xscale);
					this.__height = (this.__height * yscale);
				}
				
				//size difference between the component and the video
				var widthDiff:Number = (_realVideoWidth - __width);
				var heightDiff:Number = (_realVideoHeight - __height);
				
				//the desired width and height (scale wasn't take into account)
				var desiredHeight = videoHeight;
				var desiredWidth = videoWidth;
				
				//fit component size 
				//		or 
				//component size is samller than video size 
				if(!this.displayMode 
								|| ((widthDiff > 0) || (heightDiff > 0)))
				{
					// maintain the video aspect ratio
					// Note: _width and _height are the "real" size of the component
					// even if it was scaled, and not the original size.
					// i.e., if the component size by defualt is 300x235 and it was
					// scaled by 200%, _width = 600 and _height = 235.
					var scale:Number = Math.min( this.__width / videoWidth, this.__height / videoHeight );
					
					//the desired width and height (scale wasn't take into account)
					desiredHeight = scale * videoHeight;
					desiredWidth = scale * videoWidth;
					
					//the desired width and height (scale wasn't take into account)
					this.video.height = desiredHeight/yscale;
					this.video.width = desiredWidth/xscale;
				}
				else
				{
					this.video.height = videoHeight/yscale;
					this.video.width = videoWidth/xscale;
				}
				
				//center the video
				var xPos = (__width - desiredWidth)/2;
				var yPos = (__height - desiredHeight)/2;
				this.video.x = xPos/xscale;
				this.video.y = yPos/yscale;
				//set with of the background after resizing
				this._bg_mc.width = __width/xscale;
				this._bg_mc.height = __height/yscale;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _setVideoSize: "+ error, 1);
			}
		}
		
		//===========================
		//	function _calcPosAndSize
		//===========================
		//This function calculates the component size and position
		//in the main timeline.
		//Note: movie clip size and position is always relative to its 
		//timeline.
		//in order to know its "real" position and size, we need to climb 
		//throught its parent timelines to the main timeline.
		//The size is calculated relative to  the parent objects scale 
		//and the position is calculated relative to the parent objects 
		//position
		private function _calcPosAndSize():String
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _calcPosAndSize",6);
				
				var mc:DisplayObject = this;
				var x:Number = mc.x;
				var y:Number = mc.y;
				var w:Number = __width;
				var h:Number = __height;
				//loop till the main timeline to retrieve the
				//position and size in the main timeline.
				while(mc.parent != root)
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
				return (","+x+","+y+","+w+","+h);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _calcPosAndSize: "+ error, 1);
			}
			return "";
		}

		//-----Full Screen----	
		
		//============================
		//	function _videoFSEnd
		//============================
		//This function handles closing the FullScreen/FullPage, 
		//and setting the regular screen to play again.
		//this function is called in the regular window, from the _lc 
		//(fullPage) or the JavaScript (WMV fullScreen), in the latter, 
		//no parameters will be sent.
		//Flow:
		//Full page: VideoFSClose
		//Regular window: videoFSEnd
		//Parameters:
		//	nPosition:Number - video position
		//	fMute:Boolean - the mute speaker state
		// 	nVolume:Number - the volume level
		//	nReportedPlayProgress:Number - nReportedPlayProgress value
		//	nUnmuteReported:Number - indicates whether the unmute interaction was reported. 0 - was not reported;1 - auto initiated unmute was reported(ebVideoUnmuted);2 - user initiated unmute was reported (ebVideoUnmuted + ebVideoUnmute)
		//	fAutoClose:Bollean - indicates whether full page close event should be reported
		private function _videoFSEnd(nPosition:Number, fMute:Boolean, nVolume:Number, nReportedPlayProgress:Number, nUnmuteReported:Number, fAutoClose:Boolean=false):void
		{
			try
			{
				Tracer.debugTrace("VideoLoader: _videoFSEnd("+arguments+")",4);
				this._nFullScreen = 1;		//fullScreen enabled(regular mode)
				if (!this._playerInst)
					return;
				//end full screen duration timer
				this._endVideoPlayDuration();
				//Interactions prefix
				this._strInteractionPrefix = "eb";	//regular window
				//fullScreen
				var ev:VideoEvent = new VideoEvent("ebVLFullscreen",this._nFullScreen);
				dispatchEvent(ev);
			}
			catch(error:Error)
			{
				Tracer.debugTrace("error in _videoFSEnd: " + error, 1);
			}
		}
		
		//==============================
		//	function _handleCloseFLVFS
		//==============================
		//This function handle the things relevant when closing FLV full screen
		//Parameters:
		//	fAutoClose:Boolean - indicates which fscommand should be sent 
		//	"ebVideoFSAutoClose" when fAutoClose is true, ebVideoFSClose otherwise.
		private function _handleCloseFLVFS(fAutoClose:Boolean):void
		{
			try
			{
				//closing the full screen
				if (EBBase._stage.displayState == StageDisplayState.FULL_SCREEN)
					EBBase._stage.displayState = StageDisplayState.NORMAL;
				if(fAutoClose)
					EBBase.handleCommand("ebVideoFSAutoClose");
				else
					EBBase.handleCommand("ebVideoFSClose");
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Exception in VideoLoader: _handleCloseFLVFS: "+ error, 1);
			} 
		}
		
		//==============================
		//	function _fullScreenHandler
		//==============================
		// This function handles the FullScreenEvent
		// Parameters:
		//	event:FullScreenEvent: event object
		private function _fullScreenHandler(event:FullScreenEvent):void
		{
			//When opening full screen the event is triggered with value true of event.fullScreen
			//When closing full screen the event is triggered with value false of event.fullScreen
			if (!event.fullScreen)
			{
				this.fSClose(0);
			}
		}
	}
}