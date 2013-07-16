//****************************************************************************
//class eyeblaster.utils.VideoStrip
//-------------------------------------------
// The VideoStrip component runs as a small video strip (banner) which,
//upon user initiation (usually mouse-over), expands outside of the banner space.
// The Flash movie plays in a loop within a standard banner position and is, by default, downloaded progressively.
//When run in Strip Mode it plays in an endless loop

//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************

package eyeblaster.utils
{
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	import flash.system.fscommand;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.external.ExternalInterface;
	import eyeblaster.core.Tracer;
	
	public class VideoStrip extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		public var onExpand:Function;			//callBack function that is triggered when the component is retracte
		public var onRetract:Function;			//callBack function that is triggered when the component is retracted
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----UI------
		//the time in seconds of the component expansion
		private var _nTweenTime:Number = 2;				
		
		//a flag that indicated whether the component should expand upon roll over the component
		private var _fAutoExpandRetract:Boolean = true;		
		
		//the number of seconds the video is playing until it starts from the beginning
		private var _nVideoStripLoopLen:Number = 0;
		
		//a flag that indicates whether sound is on/off when component is expanded/retracted
		private var _fAutoSoundToggle:Boolean = false;
		
		//the easing method chosen for the easing function type
		private var _easingMethod:String = "Regular.easeInOut"; 
		
		//----set / get functions for the UI parameters------
	
		//sets / gets the duration of the expansion/retraction in seconds.
		[Inspectable(defaultValue=2,type=Number)]
		public function set tweenTime(sec:Number):void
		{
			this._nTweenTime = sec;
		}
		public function get tweenTime():Number
		{
			return this._nTweenTime;
		}
		
		//sets / get whether the component should be auto expanded/retracted 
		//upon mouse roll over/roll out.
		[Inspectable(defaultValue=true, type=Boolean)]
		public function set autoExpandRetract(fExpand:Boolean):void
		{
			this._fAutoExpandRetract = fExpand;
		}
		public function get autoExpandRetract():Boolean
		{
			return this._fAutoExpandRetract;
		}
		
		//sets /gets the number of seconds that the video movie 
		//is to be played before looping when the component is in a "strip" mode.
		[Inspectable(defaultValue=0, type=Number)]
		public function set videoStripLoopLen(sec:Number):void
		{
			this._nVideoStripLoopLen = sec;
		}
		public function get videoStripLoopLen():Number
		{
			return this._nVideoStripLoopLen;
		}
		
		//sets / gets whether the sound will be auto muted/auto 
		//played upon expand and retract.
		[Inspectable(defaultValue=false, type=Boolean)]
		public function set autoSoundToggle(fMute:Boolean):void
		{
			this._fAutoSoundToggle = fMute;
		}
		public function get autoSoundToggle():Boolean
		{
			return this._fAutoSoundToggle;
		}
		
		//sets /gets the easing method to be used for the tween effect
		[Inspectable(name="easing",enumeration="Regular.easeIn,Regular.easeOut,Regular.easeInOut",defaultValue="Regular.easeInOut",type=String)]	
		public function set easingMethod(easing:String):void
		{
			this._easingMethod = easing;
			//in case there was a change in the settings of the easing method we need to update 
			//the attribute this._easing
			this._easing = _convertEasingToFunction();
		}
		public function get easingMethod():String
		{
			return this._easingMethod;
		}
	
		//sets /gets the easing function to be used for the component motion
		public function set easing(easing:Function):void
		{
			this._easing = easing;
		}
		public function get easing():Function
		{
			return this._easing;
		}
		
		//sets/gets the video component instance name
		[Inspectable(defaultValue="_videoLoaderInst",type=String)]	
		public function set videoComponentInstance(Inst:String):void
		{
			//update videoComp instance
			this._strVideoCompName = Inst;
		}
		
		//----Regular private parameters------
		private var _videoComp;					//the video component object
		private var _strVideoCompName:String = "_videoLoaderInst";		//the video component name
		private var _compBounds:Rectangle;		//video strip component boundaries
		private var _fExpand:Boolean;			//a flag that indicates whether the comp is expanded
		private var xTween:Tween;				//instance of the tween class
		private var _fElementsAreHidden:Boolean; //a flag that indicates whether the elements on the page are hidden or not (false - hidden)
		private var _easing:Function;			//the easing function for the motion of the component, combine already the style
		
		//----API----
		private var _nCompID:Number;	    		//id of the component
		private var _JSAPIFuncName:String;  		//the name of the function used to recieve calls from the JavaScript
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//				Private Static Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private static var _nInstCount:Number = 0;	//VideoStrip component instance count
		
		
		//----General------
		include "../core/compVersion.as"
		public var compName:String = "VideoStrip";	//The component name to be used for components detection.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function VideoStrip()
		{  
			Tracer.debugTrace("VideoStrip: Constructor", 6);
			Tracer.debugTrace("VideoStrip version: "+compVersion, 0);
			Tracer.debugTrace("Eyeblaster Workshop | VideoStrip | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			//set the component as the mask of the main timeline
			root.mask = this;
			//in AS3 the UI parameters get their value only on the next enter frame event
			addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
		}
		
		//====================================
		//	function enterFrameHandler
		//====================================
		// This function calls init function upon enter frame event to
		// allow the UI parameters to get their value before we init
		// the component
		function initUponEnterFrame(event:Event)
		{
			Tracer.debugTrace("VideoStrip: initUponEnterFrame", 6);
			removeEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			this._init();
			//in case a videoInstance was inserted in the UI we need to call to set videoComponentInstance function
			if (_strVideoCompName != "")
				setVideoComponent(parent[_strVideoCompName]);
		}
		
		//============================
		//	function JSAPIFunc
		//============================
		//This function is used to recive calls from the javaScript
		public function JSAPIFunc(funcName:String, strParams:String)
		{
			if (funcName == "retract")
				this._mouseOut();
		}
		
		//============================
		//	function handleEvent
		//============================
		//This function is called after receiving "ebReadyForVideoStrip" event from the video component
		//The event is fired after iniliazing all the attributes of the video component, otherwise parameters like _nVideoStripLoopLen
		//will be initialized to the default value after they were set in the video class
		public function handleEvent(evt:Object):void
		{
			//call to _setVideoComponent function
			_setVideoComponent();
		}
		
		//------API functions---------
		
		//=============================
		//	function setVideoComponent
		//=============================
		//This function trigger the event ENTER_FRAME.
		//There are parameters that are transferred from the videoStrip to the VideoLoader.
		//In teh videoLoader class we also have the  ENTER_FRAME event for init the attributes, so if
		//we want the event here the parameters will transfer to the VideoLoader but than will be set to the default values.
		//Parameters:
		//	videoMC:DisplayObject - Eyeblaster's video component reference.
		public function setVideoComponent(videoMC):void
		{
			Tracer.debugTrace("VideoStrip: setVideoComponent- " + videoMC, 1);
			
			try
			{
				if (!videoMC)
					return;
				
				this._videoComp = videoMC;
				
				//the function _setVideoComponent should be call in delay.
				//The function is called after receiving an event from the video component.
				if(this._videoComp.fReadyForVideoStrip)
					_setVideoComponent();
				else
					this._videoComp.addEventListener("ebReadyForVideoStrip", this.handleEvent);
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: setVideoComponent Error: "+ err.message, 1);
			}
		}
		
		//==================
		//	function expand
		//==================
		//This function expands the component from its 
		//initial state ("strip") to cover the whole movie 
		public function expand():void
		{
			Tracer.debugTrace("VideoStrip: expand", 4);
			try
			{
				//expand only if the component is not expanded yet
				if (_fExpand)
					return; 
				
				//cancel the motion stop event so the elements on the page will 
				//not be shown when the motion stopped after expanding
				if (this.xTween)
				{
					//check if the EventListener exists
					if (this.xTween.hasEventListener(TweenEvent.MOTION_STOP))
					{
						this.xTween.removeEventListener(TweenEvent.MOTION_STOP, _motionStopped);
					}
				}
				//a flag that indicates that the component is expanded
				this._fExpand = true;
				
				//hide elements on the page (if necessary) when the component is expanded
				this._showHideElements(false);
				
				//set the tween of the expansion of the component
				this._tweenExpand();
				
				//call to the function that handles teh video only if _videoComp is not null (meaning the user uses one of the eyeblaster's video components)		
				if(this._videoComp != null)
				{
					//handle all the behavior of the video component when the strip component is expanded
					_videoCompUponExpand();
				}
						
				// Send the "ebVideoStripExpanded" fscommand in order to report that the panel was opened
				Tracer.debugTrace("Sending fscommand ebVideoStripExpanded", 1);
				fscommand("ebVideoStripExpanded");
				
				//trigger the callBack onExpand which call to a function that is implemented by the creative
				if(this.onExpand != null)
					this.onExpand();
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: expand Error: "+ err.message, 1);
			}
		}
	
		//====================
		//	function retract
		//====================
		//This function retracts the component from its current state ("retracted"), 
		//back to the initial state ("strip").
		public function retract():void
		{
			Tracer.debugTrace("VideoStrip: retract", 3);
			try
			{
				//retract only if the component is not retracted yet
				if (!_fExpand)
					return;
				
				//a flag that indicates that the component is retracted when it is false
				this._fExpand = false;
				
				// Send the "ebVideoStripExpanded" fscommand in order to end the panel_duration timer 
				Tracer.debugTrace("Sending fscommand ebVideoStripRetracted", 1);
				fscommand("ebVideoStripRetracted");
				
				//trigger the callBack onRetract which call to a function that is implemented by the creative
				if(this.onRetract != null)
					this.onRetract();
				
				//call to the function that handles teh video only if _videoComp is not null (meaning the user uses one of the eyeblaster's video components)		
				if(this._videoComp != null)
				{
					_videoCompUponRetract();
				}
				
				//set the tween of the retraction of the component
				this._tweenRetract();
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: retract Error: "+ err.message, 1);
			}
		}
		
		//============================
		//	function setAutoSoundToggle
		//============================
		//This function determines whether the sound will be auto muted/auto 
		//played upon expand and retract.
		//Parameters:
		//	autoMute:Boolean - indicates whether the auto mute should be used
		public function setAutoSoundToggle(autoMute)
		{
			_fAutoSoundToggle = autoMute;
			if(_fAutoSoundToggle && _videoComp)
				_videoComp.videoSetMute(true);
		}
		
		//========================
		//	function setVideoStripLoopLen
		//========================
		//This function sets the number of seconds that the video movie 
		//is to be played before looping when the component is in a "strip" mode.
		//Parameters:
		//	sec:Boolean - number of seconds before the loop
		public function setVideoStripLoopLen(sec)
		{
			_nVideoStripLoopLen = sec;
			if(_videoComp)
				_videoComp.setVideoLoop(sec);
		}

		/********************************************/
		/*				private functions 			*/
		/********************************************/
	
		//========================
		//	function _init
		//========================
		//The function inits the component, the attributes,  add an API function to the JavaScript for communication
		//and addEventListener.
		private function _init():void
		{
			Tracer.debugTrace("VideoStrip: _init", 4);
			try
			{
				this._initComp();
				this._initAttr();
				//adding event to go to _mouseMove in case there was a movement with the mouse
				//To do: we can improve it by adding  the event only in case _fAutoExpandRetract is true
				//and the event not exist yet, and then in _mouseMove we won't need to check the value of
				//_fAutoExpandRetract and the event won't be added when we don't use it.
				root.addEventListener(MouseEvent.MOUSE_OVER,_mouseOverComp);
				root.addEventListener(MouseEvent.MOUSE_OUT,_mouseOutComp);
				
				//add an API function to the JavaScript for communication
				if(ExternalInterface.available)
				{
					//update the instance count
					this._nCompID = ++_nInstCount;
					//register the JS API function
					this._JSAPIFuncName = "handleVideoStrip" + this._nCompID;
					ExternalInterface.addCallback(_JSAPIFuncName, JSAPIFunc);
				} 
				//set the _JSAPIFuncName in the JS
				fscommand("ebSetStripProxy",this._JSAPIFuncName);
				
				//Show elements on the page
				this._showHideElements(true);
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: retract Error: "+ err.message, 1);
			}
		}
		
		//========================
		//	function _initAttr
		//========================
		//The function inits all the attributes of the VideoStrip class
		private function _initAttr():void
		{
			Tracer.debugTrace("VideoStrip: _initAttr", 4);
			this._compBounds = this.getBounds(root);			//videoStrip component boundaries
			
			this._videoComp = null;
			this.onExpand = null;
			this.onRetract = null;
			this.xTween = null;
			
			this._easing = _convertEasingToFunction();			//set the UI parameters: _easingStyle and _easing Method into one variable
			this._fElementsAreHidden = true;					//set to true in for _showHideElements in the first time so we will not get out from the function
		}
		
		//========================
		//	function _initComp
		//========================
		//The function inits all the things related to the component
		private function _initComp():void
		{
			Tracer.debugTrace("VideoStrip: _initComp", 4);
			ebGlobal.ebSetComponentName("VideoStrip");
			// Notify the component position and size
			fscommand("ebInitVideoStrip",_calcPosAndSize());
		}
		
		//=========================
		//	function _tweenExpand
		//=========================
		//This function responsible to set the tween of the component when it is expanded
		private function _tweenExpand():void
		{
			Tracer.debugTrace("VideoStrip: _tweenExpand", 4);
			//resize the component.
			//The component is expanded till the size of the stage
			new Tween(this, "width", this._easing, this.width, stage.stageWidth, this._nTweenTime, true);
			new Tween(this, "height", this._easing, this.height, stage.stageHeight, this._nTweenTime, true);
			//reposition the component
			new Tween(this, "x", this._easing, this.x, 0, this._nTweenTime, true);
			new Tween(this, "y", this._easing, this.y, 0, this._nTweenTime, true);
		}
		
		//==========================
		//	function _tweenRetract
		//==========================
		//This function responsible to set the tween of the component when it is retracted
		private function _tweenRetract():void
		{
			Tracer.debugTrace("VideoStrip: _tweenRetract", 4);
			//resize the component 
			//The component is retracted till the size of the original component
			new Tween(this, "width", this._easing, this.width, this._compBounds.width, this._nTweenTime, true);
			new Tween(this, "height", this._easing, this.height,this._compBounds.height, this._nTweenTime, true);
			
			//position the component
			this.xTween = new Tween(this, "x", this._easing, this.x, this._compBounds.x, this._nTweenTime, true);
			new Tween(this, "y", this._easing, this.y, this._compBounds.y, this._nTweenTime, true);
			
			//Show elements on the page (if necessary)
			this.xTween.addEventListener(TweenEvent.MOTION_STOP, _motionStopped);
		}
		
		//========================================
		//	function _convertEasingToFunction
		//========================================
		//The function transffer the user choices of _easingMethod and _easingStyle and translate them
		//to the adequate easing function
		private function _convertEasingToFunction():Function
		{
			Tracer.debugTrace("VideoStrip: _convertEasingToFunction", 4);
			
			switch (this._easingMethod)
			{
				case "Regular.easeIn":
					this._easing = Regular.easeIn;
				break;
				case "Regular.easeOut":
					this._easing = Regular.easeOut
				break;
				case "Regular.easeInOut":
					this._easing = Regular.easeInOut;
				break;
			}
			return this._easing;
		}
		
		//========================
		//	function _motionStopped
		//========================
		//The function is called by event listener. When the motion of the tween is stppoed 
		//the function is triggered.
		private function _motionStopped(tEvent:TweenEvent):void
		{
			this._showHideElements(true);
		}
		
		//========================
		//	function _mouseMove
		//========================
		//This function handles the mouse move event.
		//check if the mouse rolled over/out the component.
		private function _mouseMove(fOver:Boolean):void
		{
			Tracer.debugTrace("VideoStrip: _mouseMovve", 4);
			try
			{
				//do not expand/retract upon rollOver/rollOut if _fAutoExpandRetract is false
				if(!this._fAutoExpandRetract)
					return;
			
				//check if the mouse is over the video strip component
				if(fOver)
				{
					//when the mouse is over the video strip component it should be expanded only
					//if it was not already expanded (if _fExpand is false the component was not expanded yet)
					if(!this._fExpand)
					{
						//rollover
						Tracer.debugTrace("The mouse rolled over the component", 4);
						this.expand();
					}
				}
				else
				{
					//when the mouse is not on the video strip component it should be retracted only
					//if it was not already retracted (if _fExpand is true the component was not retracted yet)
					if(this._fExpand)
					{
						//rollout
						Tracer.debugTrace("The mouse rolled out of the component", 4);
						this.retract();
					}
				}
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: _mouseMove Error: "+ err.message, 1);
			}
		}
		
		//========================
		//	function _mouseMove
		//========================
		//This function is called when the mouse is over the component mask.
		//The function calls to _mouseMove with parameter true to indicate that the mouse is over
		//the component
		private function _mouseOverComp(mEvent:MouseEvent):void
		{
			this._mouseMove(true);
		}
		
		//========================
		//	function _mouseOutComp
		//========================
		//This function is called when the mouse is out of the component mask.
		//The function calls to _mouseMove with parameter false to indicate that the mouse is out of
		//the component
		private function _mouseOutComp(mEvent:MouseEvent):void
		{
			this._mouseMove(false);
		}
		
		//============================
		//	function _showHideElements
		//============================
		//This function sends an fscommand to the JavaScript to hide or show the page
		//elements.
		//Parameters:
		//	fShow:Boolean - indicates whether the page elements should be displayed or hidden
		private function _showHideElements(fShow):void
		{
			Tracer.debugTrace("VideoStrip: _showHideElements (" + fShow + ") _fElementsAreHidden=" + _fElementsAreHidden, 1);
			//if _fElementsAreHidden and fShow have the same value there is no need to tell the JS to hide/show elements since they are already hidden/shown
			if(this._fElementsAreHidden != fShow)
			{
				Tracer.debugTrace("_showHideElements - ignore", 1);
				return;
			}
			Tracer.debugTrace("_showHideElements - send Command", 1);
			this._fElementsAreHidden = !fShow;
			fscommand("ebShowHideElementsFromFlash",fShow);
		}
	
		//===========================
		//	function _calcPosAndSize
		//===========================
		//This function calculates the component size and position
		//in the main timeline.
		//Note: movie clip size and position is always relative to its 
		//timeline.
		//in order to know its "real" position and size, we need to climb 
		//through its parent timelines to the main timeline.
		//The size is calculated relative to  the parent objects scale 
		//and the position is calculated relative to the parent objects 
		//position
		function _calcPosAndSize()
		{
			Tracer.debugTrace("VideoStrip: _calcPosAndSize", 6);
	
			var mc:DisplayObject = this;
			var x:Number = mc.x;
			var y:Number = mc.y;
			var width:Number = mc.width;
			var height:Number = mc.height;
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
				width*=mc.scaleX;
				height*=mc.scaleY;
			}
			return (x+","+y+","+width+","+height);
		}
		
		//------------ video functions -------------
		
		//================================
		//	function _videoCompUponExpand
		//================================
		//This function handles the things relevant for video component when the strip 
		//component is expanded
		private function _videoCompUponExpand()
		{
			//play the video in case it is not playing
			if(!this._videoComp.isVideoPlaying())
				this._videoComp.videoPlay();
	
			//in case _fAutoSoundToggle is set to true sound should be on when the component expanded
			if(this._fAutoSoundToggle)
				this._videoComp.videoSetMute(false);
			
			//reset the play progress interactions reporting status upon expand
			this._videoComp.resetReportStatus();
			
			//cancel the loop when the component is expanded
			this._videoComp.setVideoLoop(-1);
		}
		
		//================================
		//	function _videoCompUponRetract
		//================================
		//This function handles the things relevant for video component when the strip 
		//component is retracted
		private function _videoCompUponRetract()
		{
			//in case _fAutoSoundToggle is set to true sound should be off when the component retract
			if(this._fAutoSoundToggle)
				this._videoComp.videoSetMute(true);
				
			// Disable playing progress interactions
			this._videoComp.disableReport();
	
			//set the loop - the loop is only when the component is not expanded
			this._videoComp.setVideoLoop(this._nVideoStripLoopLen);
			
			//check if the video is streaming (in case it is VideoLoader or VideoPlayback
			if(((this._videoComp.compName == "VideoLoader")||
				(this._videoComp.compName == "VideoPlayback"))&& 
				(this._videoComp.isStreaming()))		//streaming
			{
				this._handleStreamingVideo();
			}
			else
			{
				//play the movie in case the player is not playing.
				if(!this._videoComp.isVideoPlaying())
				{
					this._videoComp.videoPlay();
				}
			}
		}
		
		//==================================
		//	function _handleStreamingVideo
		//==================================
		//This function handle a case the video is streaming.
		//In streaming mode  the video should not be looped after the component was retracted.
		private function _handleStreamingVideo():void
		{
			Tracer.debugTrace("on streaming, the video should not be looped again", 2);
			//on streaming, the video should not be looped again
			//after the component was retracted.
			this._videoComp.disableLooping();
			//play the video again in 
			//case it was paused in "expanded" mode
			this._videoComp.resumePause();
		}
		
		//------------ functions called from the JS -------------
		
		//============================
		//	function _mouseOut
		//============================
		//This function will be called from the expandable banner template when 
		//the mouse is out of the panel
		private function _mouseOut()
		{
			Tracer.debugTrace("VideoStrip: _mouseOut", 4);
			//the component should retract if _fAutoExpandRetract is set to true and was not retracted yet
			if(this._fAutoExpandRetract && this._fExpand)
				this.retract();
		}
		//==================================
		//	function _setVideoUponEnterFrame
		//==================================
		//This function trigger the _setVideoComponent function
		private function _setVideoUponEnterFrame(event:Event)
		{
			Tracer.debugTrace("VideoStrip: _setVideoUponEnterFrame", 6);
			removeEventListener(Event.ENTER_FRAME, _setVideoUponEnterFrame);
			_setVideoComponent();
		}
		
		//=============================
		//	function _setVideoComponent
		//=============================
		//This function gets a reference to one of Eyeblaster’s video components 
		//and sets it for future control of the video.
		private function _setVideoComponent():void
		{
			Tracer.debugTrace("VideoStrip: setVideoComponent- " + this._videoComp, 1);
			try
			{
				
				if (this._videoComp == null) //_videoComp is null if compInst is "" and the API function setVideoComponent was not triggered or in the UI we gave a name that its instance doesn't exist
					Tracer.debugTrace("Eyeblaster VideoStrip component | The instance name you entered does not exist", 0);
				else
				{
				
					//check if the videoMC component is one of our video components
					if((this._videoComp.compName != "VideoLoader")&&
						(this._videoComp.compName != "VideoPlayback")&&
							(this._videoComp.compName != "SWFVideoLoader"))
					{
						Tracer.debugTrace("You are not using one of eyeblaster video components", 1);	
						return;
					}
					Tracer.debugTrace("setVideoComponent: the video component is instance of " + this._videoComp.compName + " component",5 );
					
					//mute the sound in case auto mute is used 
					//(sound off on strip mode, sound on on full mode).
					if(this._fAutoSoundToggle)
						this._videoComp.videoSetMute(true);
					
					this._videoComp.setVideoLoop(_nVideoStripLoopLen);	//set the default loop (full movie).
					this._videoComp.disableReport();					// Disable playing progress interactions (retracted)
																		//the function exist only in VideoLoader and VideoPlayback
					if((this._videoComp.compName == "VideoLoader")||
						(this._videoComp.compName == "VideoPlayback"))
					{
						this._videoComp.disableSyncWithFP();	
					}
				}
			}
			catch(err:Error)
			{
				Tracer.debugTrace("VideoStrip: setVideoComponent Error: "+ err.message, 1);
			}
		}
	}	
}