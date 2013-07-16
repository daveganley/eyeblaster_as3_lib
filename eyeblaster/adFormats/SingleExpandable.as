//****************************************************************************
//class eyeblaster.adFormats.SingleExpandable
//------------------------------------
//This class is the flash side implementaion of the SingleExpandable ad format
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.adFormats
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.*;
	import eyeblaster.events.EBPageEvent;
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	public class SingleExpandable extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----UI------
		
		// UI-Expand Tab
		// Expand When ID: 0-rollover, 1-Expand(), 2-ad load
		[Inspectable(name="expandTriggerID",defaultValue=0,type=Number)]
		public var expandTriggerID:Number = 0;
		
		// After Expand ID: 0-gotoAndStop, 1-gotoAndPlay, 2-onExpand(), 3-Nothing
		[Inspectable(name="afterExpandID",defaultValue=0,type=Number)]
		public var afterExpandID:Number = 0;
		
		// After Expand Frame number or label (if afterExpandID = 0 or 1)
		[Inspectable(name="afterExpandFrame",defaultValue="Number / Label",type=String)]
		public var afterExpandFrame:String = "Number / Label";
		
		// Enable Expand Tween
		[Inspectable(name="enableExpandTween",defaultValue=false,type=Boolean)]
		public var enableExpandTween:Boolean = false;
		
		// Expand Tween Time
		[Inspectable(name="expandTweenTime",defaultValue=2,type=Number)]
		public var expandTweenTime:Number = 2;
		
		// Easing: 0-InOut, 1-In, 2-Out
		[Inspectable(name="expandEasingID",defaultValue=0,type=Number)]
		public var expandEasingID:Number = 0;
		
		// UI-Collapse Tab
		// Collapse When ID: 0-rollout, 1-Collapse()
		[Inspectable(name="collapseTriggerID",defaultValue=0,type=Number)]
		public var collapseTriggerID:Number = 0;
		
		// After Collapse ID: 0-gotoAndStop, 1-gotoAndPlay, 2-onBeforeCollapse, 3-Nothing
		[Inspectable(name="beforeCollapseID",defaultValue=0,type=Number)]
		public var beforeCollapseID:Number = 0;
		
		// After Collapse Frame number or label (if beforeCollapseID = 0 or 1)
		[Inspectable(name="beforeCollapseFrame",defaultValue="Number / Label",type=String)]
		public var beforeCollapseFrame:String = "Number / Label";
		
		// Enable Collapse Tween
		[Inspectable(name="enableCollapseTween",defaultValue=false,type=Boolean)]
		public var enableCollapseTween:Boolean = false;
		
		// Collapse Tween Time
		[Inspectable(name="collapseTweenTime",defaultValue=2,type=Number)]
		public var collapseTweenTime:Number = 2;
		
		// Easing: 0-InOut, 1-In, 2-Out
		[Inspectable(name="collapseEasingID",defaultValue=0,type=Number)]
		public var collapseEasingID:Number = 0;
		
		//----General------
		include "../core/compVersion.as"
		public var compName:String = "SingleExpandable"; //The component name to be used for components detection.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----Regular private parameters------
		private var _compLocAndSize; //Array for saving comp initial location and size
		private var _isExpanded; //a flag that indicates whether the comp is expanded	
		private var _easingExpand; //the easing function for the motion of the component for expand
		private var _easingCollapse; //the easing function for the motion of the component for collapse
		// private var _fElementsAreHidden;		//a flag that indicates whether the elements on the page are hidden or not (false - hidden)
		private var invoker = "user"; // used to define if expand/collapse was called by user interaction or automatically (frame script)
		private var mouseOutside:Boolean = true;
		private var waitingForDelayed = false;
		private var fDynamicComp:Boolean = false;
		
		//tween
		private var expandTweenW:Tween;
		private var expandTweenH:Tween;
		private var expandTweenX:Tween;
		private var expandTweenY:Tween;
		private var collapseTweenW:Tween;
		private var collapseTweenH:Tween;
		private var collapseTweenX:Tween;
		private var collapseTweenY:Tween;
		
		// Enums declaration
		private var expandTrigger = {OnRollOver: 0, ExpandFunctionCall: 1, AdLoad: 2}
		private var afterExpand = {GoToAndStop: 0, GoToAndPlay: 1, CallOnExpandFunction: 2, Nothing: 3}
		private var collapseTrigger = {OnRollOut: 0, CollapseFunctionCall: 1}
		private var beforeCollapse = {GoToAndStop: 0, GoToAndPlay: 1, CallOnBeforeCollapseFunction: 2, Nothing: 3}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function SingleExpandable()
		{
			Tracer.debugTrace("SingleExpandable: Constructor");
			Tracer.debugTrace("SingleExpandable version: " + compVersion, 0);
			
			//check if dynamic
			this.fDynamicComp = (root == null);
			if (!this.fDynamicComp)
			{
				if (!initComp())
					return;
			}
			//in AS3 the UI parameters get their value only on the next enter frame event
			addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			addEventListener(Event.REMOVED, removeComponent);
		}
		
		//==============================
		//	function initComp
		//==============================
		//This function initializes the component
		private function initComp():Boolean
		{
			
			// check that the component is on the Stage root and not inside a movie clip
			if (this.parent != root)
			{
				Tracer.debugTrace("Eyeblaster Workshop | The Single Expandable component must be placed on the second frame of the main timeline. The component may not function properly if placed elsewhere.", 0);
				return false;
			}
			
			// create a filled background to enable the root mask
			createMovieClip();
			
			//set the component as the mask of the main timeline
			root.mask = this;
			return true;
		}
		
		//==============================
		//	function initUponEnterFrame
		//==============================
		// Init component properties after first EnterFrame		
		private function initUponEnterFrame(event:Event):void
		{
			Tracer.debugTrace("SingleExpandable: initUponEnterFrame", 6);
			removeEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			
			//Admin component identification
			EBBase.ebSetComponentName(compName);
			
			// EBBase Notification Event
			EBBase.addEventListener(EBNotificationEvent.NOTIFICATION,onNotification);
			
			//init
			if (this.fDynamicComp)
			{
				if (!initComp())
					return;
			}
			
			// init private properties
			_compLocAndSize = [this.x, this.y, this.width, this.height];
			_isExpanded = false;
			_easingExpand = convertEasingToFunction(expandEasingID);
			_easingCollapse = convertEasingToFunction(collapseEasingID);
			
			// if expand or collapse time is 0 - disable expand / collapse
			if (expandTweenTime == 0 && enableExpandTween == true)
			{
				enableExpandTween = false
			}
			if (collapseTweenTime == 0 && enableCollapseTween == true)
			{
				enableCollapseTween = false
			}
			
			// add event listener to mouse move event
			root.addEventListener(MouseEvent.MOUSE_OVER, MouseOver); // Detect RollOver
			root.addEventListener(MouseEvent.MOUSE_MOVE, MouseMove); // Detect MouseMove (for RollOver, RollOn)
			stage.addEventListener(Event.MOUSE_LEAVE, MouseLeave); // Detect leaving Flash's Stage entirely
			
			// since afterExpandFrame supports both labels (string) and frame numbers (int) - Flash is
			// force-casting to int if a number is used. We are concating char 127 to force-cast
			// back to string. Char 127 is added at the beginning of the string and removed upon init.
			if (afterExpandFrame.substr(0, 1) == String.fromCharCode(127))
			{
				afterExpandFrame = afterExpandFrame.substring(1, afterExpandFrame.length).toString();
			}
			if (beforeCollapseFrame.substr(0, 1) == String.fromCharCode(127))
			{
				beforeCollapseFrame = beforeCollapseFrame.substring(1, beforeCollapseFrame.length).toString();
			}
			
			EBBase.Callback("handleSingleExpandable", JSAPIFunc);
			
			//set the _JSAPIFuncName in the JS
			EBBase.handleCommand("ebSetSEProxy", "handleSingleExpandable");
			
			// Notify the component position and size
			EBBase.handleCommand("ebInitSE", _compLocAndSize.toString());
			
			// add a filled MovieClip to the root to enable automatic rollover when wmode=transparent
			var t:Timer = new Timer(350, 1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, createMovieClip)
			t.start();
			// the timer is here to make sure the stage dimensions are recognized correctly
			var t2:Timer = new Timer(350, 1);
			t2.addEventListener(TimerEvent.TIMER_COMPLETE, regPageLoadEvent)
			t2.start();
		}
		
		//===========================
		//	function createMovieClip
		//===========================
		// Create a filled MovieClip and add it as child 0 of the root
		// used to ensure correct masking and enable automatic rollover when wmode=transparent
		private function createMovieClip(e:TimerEvent = null):void
		{
			var square:MovieClip = new MovieClip();
			square.graphics.beginFill(0xFFCC00, 0);
			square.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			square.x = 0;
			square.y = 0;
			(root as MovieClip).addChildAt(square, 0);
		}
		
		//========================
		//	function regPageLoadEvent
		//========================
		//This function registers the compoennt to the page load event
		private function regPageLoadEvent(e:TimerEvent = null):void
		{
			// register to the page load event and delegate the onPageLoad function
			EBBase.addEventListener(EBPageEvent.PAGE_LOAD, this.onPageLoad);
		
		}
		
		//========================
		//	function removeComponent
		//========================
		//This function removed the flag specifying a component alraedy exists in the memory
		private function removeComponent(e:Event):void
		{
			if(root != null){
				root["ebSingleExpInstNum"] = undefined;
				root.removeEventListener(MouseEvent.MOUSE_OVER, MouseOver); // Detect RollOver
				root.removeEventListener(MouseEvent.MOUSE_MOVE, MouseMove); // Detect MouseMove (for RollOver, RollOn)
			}
			
			if(stage != null){
				stage.removeEventListener(Event.MOUSE_LEAVE, MouseLeave); // Detect leaving Flash's Stage entirely
			}
		}
		
		//========================
		//	function onPageLoad
		//========================
		//This function is invoked when the page loads.
		//If the component is configued to expand on load - invokes expand.	
		private function onPageLoad(e:EBPageEvent):void
		{
			if (expandTriggerID == expandTrigger.AdLoad && EBBase.urlParams.ebShouldAutoExpand == "1")
			{
				invoker = "auto";
				doExpand();
			}
			// dispatch the PAGE_LOAD event so users can register for it
			dispatchEvent(new EBPageEvent(EBPageEvent.PAGE_LOAD, ""));
		}
		
		private function onNotification(e:EBNotificationEvent):void
		{
			if(e.subtype == EBNotificationEvent.CLOSE){
				parent.removeChild(this);
			}
		}
		
		
		//========================
		//	function MouseMove
		//========================
		//This function handles the mouse move event.
		//if the mouse is over the component - expand. If not - retract.
		private function MouseMove(e:MouseEvent = null):void
		{
			if (this._mouseOverComp())
			{
				if (expandTriggerID == expandTrigger.OnRollOver && mouseOutside)
				{
					mouseOutside = false;
					expand();
				}
			}
			else
			{
				if (collapseTriggerID == collapseTrigger.OnRollOut)
				{
					retract();
				}
			}
		}
		
		private function MouseLeave(e:Event):void
		{
			mouseOutside = true;
			
			if(collapseTriggerID == collapseTrigger.OnRollOut)
			{
				retract();
			}			
		}
		
		private function MouseOver(e:MouseEvent):void
		{
			if (expandTriggerID == expandTrigger.OnRollOver && mouseOutside)
			{
				mouseOutside = false;
				expand();
			}
		}
		
		//========================
		//	function _mouseOverComp
		//========================
		//check whether the mouse is on the component
		private function _mouseOverComp():Boolean
		{
			if ((root.mouseX <= (root as MovieClip).width) && (root.mouseX >= 0) && (root.mouseY <= (root as MovieClip).height) && (root.mouseY >= 0))
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		//==================
		//	function expand
		//==================
		//This function expands the component from its 
		//initial state to cover the whole movie 	
		private function expand():void
		{
			if (!_isExpanded)
			{
				if (EBBase.urlParams.ebDelayExp != "1")
				{
					doExpand();
				}
				else
				{
					Tracer.debugTrace("Sending fscommand ebSEMouseOver", 1);
					this.waitingForDelayed = true;
					EBBase.handleCommand("ebSEMouseOver");
				}
			}
		}
		
		//==================
		//	function doExpand
		//==================
		//Actual expand function to be also called by API				
		private function doExpand()
		{
			if (!_isExpanded)
			{
				if (collapseTweenW != null)
				{
					collapseTweenW.removeEventListener(TweenEvent.MOTION_STOP, collapseFinish);
					collapseTweenW.stop();
					collapseTweenH.stop();
					collapseTweenX.stop();
					collapseTweenY.stop();
				}
				//resize the component.
				if (enableExpandTween)
				{
					// this tween is saved to a variable in order to catch the tween finish event
					expandTweenW = new Tween(this, "width", this._easingExpand, this.width, stage.stageWidth, this.expandTweenTime, true);
					expandTweenW.addEventListener(TweenEvent.MOTION_STOP, expandFinished);
					expandTweenH = new Tween(this, "height", this._easingExpand, this.height, stage.stageHeight, this.expandTweenTime, true);
					expandTweenX = new Tween(this, "x", this._easingExpand, this.x, 0, this.expandTweenTime, true);
					expandTweenY = new Tween(this, "y", this._easingExpand, this.y, 0, this.expandTweenTime, true);
				}
				else
				{
					this.x = 0;
					this.y = 0;
					this.width = stage.stageWidth;
					this.height = stage.stageHeight;
					this.expandFinished();
				}
				_isExpanded = true;
				//hide elements on the page (if necessary) when the component is expanded
				//this._showHideElements(false);
				// Send the "ebSEExpanded" fscommand in order to report that the panel was opened
				Tracer.debugTrace("Sending fscommand ebSEExpandStarted", 1);
				EBBase.handleCommand("ebSEExpandStarted", invoker);
				
				var evt:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION,EBNotificationEvent.EXPAND);
				evt.isAuto = invoker == "auto";
				EBBase.dispatchEvent(evt);
					
				invoker = "user";
			}
		}
		
		//====================
		//	function retract
		//====================
		//check if the user chose to start collapse immidiatly or play animation first
		private function retract()
		{
			this.waitingForDelayed = false;
			if (_isExpanded && beforeCollapseID != beforeCollapse.GoToAndPlay)
			{
				doCollapse();
			}
			if (_isExpanded && beforeCollapseID == beforeCollapse.GoToAndPlay)
			{
				(root as MovieClip).gotoAndPlay(beforeCollapseFrame);
			}
		}
		
		//====================
		//	function doCollapse
		//====================
		//This function retracts the component from its current state ("retracted"), 
		//back to the initial state.		
		private function doCollapse()
		{
			//in case ad is in FS, dont collapse
			if (EBBase._stage != null && EBBase._stage.displayState == StageDisplayState.FULL_SCREEN) return;
			if (_isExpanded)
			{
				this.collapseStart();
				if (expandTweenW != null)
				{
					expandTweenW.removeEventListener(TweenEvent.MOTION_STOP, expandFinished);
					expandTweenW.stop();
					expandTweenH.stop();
					expandTweenX.stop();
					expandTweenY.stop();
				}
				// Send the "ebSEExpanded" fscommand in order to end the panel_duration timer 
				Tracer.debugTrace("Sending fscommand ebSERetractStarted", 1);
				EBBase.handleCommand("ebSERetractStarted", invoker);
				invoker = "user";
				
				if (enableCollapseTween)
				{
					// this tween is saved to a variable in order to catch the tween finish event
					collapseTweenW = new Tween(this, "width", this._easingCollapse, this.width, this._compLocAndSize[2], this.collapseTweenTime, true);
					collapseTweenW.addEventListener(TweenEvent.MOTION_STOP, collapseFinish);
					collapseTweenH = new Tween(this, "height", this._easingCollapse, this.height, this._compLocAndSize[3], this.collapseTweenTime, true);
					collapseTweenX = new Tween(this, "x", this._easingCollapse, this.x, this._compLocAndSize[0], this.collapseTweenTime, true);
					collapseTweenY = new Tween(this, "y", this._easingCollapse, this.y, this._compLocAndSize[1], this.collapseTweenTime, true);
				}
				else
				{
					this.x = this._compLocAndSize[0];
					this.y = this._compLocAndSize[1];
					this.width = this._compLocAndSize[2];
					this.height = this._compLocAndSize[3];
					dispatchEvent(new EBSingleExpandableEvent("AfterCollapsePanel"));
					EBBase.handleCommand("ebSERetractFinished");
					
					var evt:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION,EBNotificationEvent.COLLAPSE);
					evt.isAuto = invoker == "auto";
					EBBase.dispatchEvent(evt);
					
				}
				_isExpanded = false;
			}
		}
		
		//====================
		//	function expandFinished
		//====================
		//This function is called when expand is finished
		private function expandFinished(e:TweenEvent = null):void
		{
			dispatchEvent(new EBSingleExpandableEvent("ExpandPanel"));
			switch (afterExpandID)
			{
				case afterExpand.GoToAndStop: 
					if (afterExpandFrame != "Number / Label")
					{
						(root as MovieClip).gotoAndStop(afterExpandFrame);
					}
					break;
				case afterExpand.GoToAndPlay: 
					if (afterExpandFrame != "Number / Label")
					{
						(root as MovieClip).gotoAndPlay(afterExpandFrame);
					}
					break;
				case afterExpand.CallOnExpandFunction: 
					(root as MovieClip).onExpand();
					break;
				case afterExpand.Nothing: 
					break;
			}
		}
		
		//====================
		//	function collapseStart
		//====================
		//This function is called when retract is starting
		private function collapseStart()
		{
			dispatchEvent(new EBSingleExpandableEvent("BeforeCollapsePanel"));
			switch (beforeCollapseID)
			{
				case beforeCollapse.GoToAndStop: 
					if (beforeCollapseFrame != "Number / Label")
					{
						(root as MovieClip).gotoAndStop(beforeCollapseFrame);
					}
					break;
				case beforeCollapse.CallOnBeforeCollapseFunction: 
					(root as MovieClip).onBeforeCollapse();
					break;
				case beforeCollapse.Nothing: 
					break;
			}
		}
		
		//====================
		//	function collapseFinish
		//====================
		//This function is called when retract is finished
		private function collapseFinish(e:TweenEvent = null):void
		{
			//this._showHideElements(true);
			dispatchEvent(new EBSingleExpandableEvent("AfterCollapsePanel"));
			Tracer.debugTrace("Sending fscommand ebSERetractFinished", 1);
			EBBase.handleCommand("ebSERetractFinished");
			
			var evt:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION,EBNotificationEvent.COLLAPSE);
			evt.isAuto = invoker == "auto";
			EBBase.dispatchEvent(evt);
		}
		
		//========================================
		//	function convertEasingToFunction
		//========================================
		//The function transffer the user choices of easingStyle and translate them
		//to the adequate easing function
		private function convertEasingToFunction(id:int):Function
		{
			var easing:Function;
			switch (id)
			{
				case 0: 
					easing = Regular.easeInOut;
					break;
				case 1: 
					easing = Regular.easeIn;
					break;
				case 2: 
					easing = Regular.easeOut
					break;
			}
			return easing;
		}
		
		//------------ functions called from the JS -------------
		
		//============================
		//	function JSAPIFunc
		//============================
		//This function is used to recive calls from the javaScript
		public function JSAPIFunc(funcName:String, strParams:String):void
		{
			if (funcName == "retract")
			{
				mouseOutside = true;
				if (collapseTriggerID == collapseTrigger.OnRollOut)
				{
					retract();
				}
			}
			if (funcName == "delayedExp")
			{
				if (this.waitingForDelayed)
				{
					this.waitingForDelayed = false;
					doExpand();
				}
			}
		}
		
		//------------ Public API Functions -------------
		
		//============================
		//	function setExpandTween
		//============================
		//This function will set up the expand tween time and easing function
		//Calling this function without parameters will setup the default values
		public function setExpandTween(time, method)
		{
			enableExpandTween = true;
			if (time != undefined)
			{
				expandTweenTime = time;
			}
			else
			{
				expandTweenTime = 2;
			}
			if (method != undefined)
			{
				_easingExpand = method;
			}
			else
			{
				_easingExpand = Regular.easeInOut;
			}
		}
		
		//============================
		//	function setCollapseTween
		//============================
		//This function will set up the collapse tween time and easing function
		//Calling this function without parameters will setup the default values
		public function setCollapseTween(time, method)
		{
			enableCollapseTween = true;
			if (time != undefined)
			{
				collapseTweenTime = time;
			}
			else
			{
				collapseTweenTime = 2;
			}
			if (method != undefined)
			{
				_easingCollapse = method;
			}
			else
			{
				_easingCollapse = Regular.easeInOut;
			}
		}
		
		//============================
		//	function Expand
		//============================
		//This function will invoke component expand
		public function ExpandPanel(invokedBy:String = "user")
		{
			invoker = invokedBy.toLowerCase();
			if (invoker != "auto")
			{
				invoker = "user";
			}
			this.doExpand();
		}
		
		//============================
		//	function Collapse
		//============================
		//This function will invoke component collapse
		public function CollapsePanel(invokedBy:String = "user")
		{
			invoker = invokedBy.toLowerCase();
			if (invoker != "auto")
			{
				invoker = "user";
			}
			this.doCollapse();
		}
	
	}
}