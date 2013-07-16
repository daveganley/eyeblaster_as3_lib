package eyeblaster.videoPlayer.controls
{
	
	import eyeblaster.events.EBAudioStateEvent;
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoStateEvent;
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.Regular;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	import flash.display.StageDisplayState;
	
	public class ControlBar extends ControlBase
	{
		private var _availCtrlArr:Array = [1, 1, 0, 0, 0, 1, 1, 1, 1];
		private var _nControlsMode:int;
		private var _isLivePreview:Boolean;
		
		// Internal Control Buttons
		private var _bg_mc:MovieClip; // movieclip container for controls
		private var _vtoggle_btn:MovieClip;
		private var _stop_btn:MovieClip;
		private var _replay_btn:MovieClip;
		private var _rewind_btn:MovieClip;
		private var _ffwd_btn:MovieClip;
		private var _progress_slider:MovieClip;
		private var _atoggle_btn:MovieClip
		private var _audio_slider:MovieClip;
		private var _fs_btn:MovieClip;
		private var _lseparator_mc:MovieClip;
		private var _rseparator_mc:MovieClip;
		
		private var isRolledOver:Boolean;
		private var isAnimating:Boolean;
		
		private var _h:int;
		private var _rolloutTimer:int = -1;
		
		private var tween:Tween;
		
		private var isProgressScrubbing:Boolean;
		private var isAudioScrubbing:Boolean;
		
		private var haveShownControls:Boolean;
		
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
		public function get nControlsMode():int
		{
			return _nControlsMode;
		}
		
		public function set nControlsMode(dMode:int):void
		{
			_nControlsMode = (this._isLivePreview) ? 0 : dMode;
		}
		
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
		public function get availCtrlArr():Array
		{
			return _availCtrlArr;
		}
		
		public function set availCtrlArr(availCtrl:Array):void
		{
			_availCtrlArr = availCtrl;
			//in case of live preview, we need to update the
			//dispayed buttons
			if(this._isLivePreview)
			{
				ShowControls();
			}
		}
		
		[Inspectable(defaultValue=true)]
		public var turnAudioOnReplay:Boolean = true;
			
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "ControlBar";	//The component name.
		
		public function ControlBar()
		{
			enabled = false;
			
			EBBase.ebSetComponentName("ControlBar");
			
			// Check for live preview mode
			_isLivePreview = ((parent != null) && getQualifiedClassName(parent) == "fl.livepreview::LivePreviewParent");
			
			// Sets the variables for the various controls
			_bg_mc = getChildByName("bg_mc") as MovieClip;
			_vtoggle_btn = getChildByName("vtoggle_btn") as MovieClip;
			_stop_btn = getChildByName("stop_btn") as MovieClip;
			_replay_btn = getChildByName("replay_btn") as MovieClip;
			_rewind_btn = getChildByName("rewind_btn") as MovieClip;
			_ffwd_btn = getChildByName("ffwd_btn") as MovieClip;
			_progress_slider = getChildByName("progress_slider") as MovieClip;
			_atoggle_btn = getChildByName("atoggle_btn") as MovieClip;
			_audio_slider = getChildByName("audio_slider") as MovieClip;
			_fs_btn = getChildByName("fs_btn") as MovieClip;
			_lseparator_mc = getChildByName("lseparator_mc") as MovieClip;
			_rseparator_mc = getChildByName("rseparator_mc") as MovieClip;
			
			//hide the border:
			//	to avoid seeing the border in case "show on rollover"
			//	setting is selected (because we wait for the next frame before we
			//	can know whether this setting is used, by then it is 2 late)
			//	Please note that becuase we display the border before the buttons are arranged
			//	this is OK for the "show always" setting as well
			if(!_isLivePreview){
				_bg_mc.alpha = 0;
			}
			
		}
				
		/** @private */
		public override function initialize():void
		{
			super.initialize();
			vtoggle_btn.targetVideo = targetVideo;
			stop_btn.targetVideo = targetVideo;
			replay_btn.targetVideo = targetVideo;
			rewind_btn.targetVideo = targetVideo;
			ffwd_btn.targetVideo = targetVideo;
			progress_slider.targetVideo = targetVideo;
			atoggle_btn.targetVideo = targetVideo;
			audio_slider.targetVideo = targetVideo;
			fs_btn.targetVideo = targetVideo;
		}
		
		protected override function OnScreenSet():void
		{
			_h = height;
			
			if(!haveShownControls){
				ShowControls();
			}
			
			// Now that we have a VideoScreen, we can go ahead and make it visible again
			_bg_mc.alpha = 1;
			
			// Show On Rollover Enabled
			if(nControlsMode == 1 || nControlsMode == 2){
				height = 0; // Hide Component
				visible = false;
			}
			
			// Set up event listeners
			if(nControlsMode == 1 || nControlsMode == 2){
				_bg_mc.addEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				_bg_mc.addEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
				assignedScreen.addEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				assignedScreen.addEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
				
				stage.addEventListener(Event.MOUSE_LEAVE,OnMouseLeave);
			}
			
			if(nControlsMode == 2){
				parent["bg_mc"].addEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				parent["bg_mc"].addEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
			}
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			height = _h;
			
			// Remove event listeners
			if(nControlsMode == 1){
				_bg_mc.removeEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				_bg_mc.removeEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
				screen.removeEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				screen.removeEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
			}
			
			if(nControlsMode == 2){
				parent.removeEventListener(MouseEvent.MOUSE_OVER,OnRollOver);
				parent.removeEventListener(MouseEvent.MOUSE_OUT,OnRollOut);
			}
		}
		
		//mf/ Iterated through all controls and reffrences all availiable ones in arrays by left and right aligin, 
		//return an object containing both arrays
		private function assignCtrlsSide():Object {
			var lCtrls:Array = [];
			var rCtrls:Array = [];
			
			// Add Left-Aligned Buttons
			if(_availCtrlArr[0] == 0){
				_vtoggle_btn.visible = false;
			} else {
				lCtrls.push(_vtoggle_btn);
			}
			
			if(_availCtrlArr[1] == 0) {
				_stop_btn.visible = false;
			} else {
				lCtrls.push(_stop_btn);
			}
			
			if(_availCtrlArr[2] == 0){
				_replay_btn.visible = false;
			} else {
				lCtrls.push(_replay_btn);
			}
			
			if(_availCtrlArr[3] == 0){
				_rewind_btn.visible = false;
			} else {
				lCtrls.push(_rewind_btn);
			}
			
			if(_availCtrlArr[4] == 0){
				_ffwd_btn.visible = false;
			} else {
				lCtrls.push(_ffwd_btn);
			}
			
			if(_availCtrlArr[5] == 0){
				_progress_slider.visible = false;
			} else {
				lCtrls.push(_progress_slider);	
			}
			
			// Add Right-Aligned Buttons
			if(_availCtrlArr[8] == 0){
				_fs_btn.visible = false;
			} else {
				rCtrls.push(_fs_btn);
			}
			
			if(_availCtrlArr[7] == 0){
				_audio_slider.visible = false;
			} else {
				rCtrls.push(_audio_slider);
			}
			
			if(_availCtrlArr[6] == 0){
				_atoggle_btn.visible = false;
			} else {
				rCtrls.push(_atoggle_btn);
			}
			
			//mf/put both array's to an object and return it on request
			var returnObj:Object = new Object();
			returnObj.lCtrls = lCtrls;
			returnObj.rCtrls = rCtrls;
			
			return returnObj;
		}
		public function ShowControls():void//return to privater
		{
			var ctrlObj:Object = assignCtrlsSide();			
			// Position left-aligned buttons
			var lpos:Array = [];
			lpos[0] = _vtoggle_btn.x;
			lpos[1] = _stop_btn.x;
			lpos[2] = _replay_btn.x;
			lpos[3] = _rewind_btn.x;
			lpos[4] = _ffwd_btn.x;
			lpos[5] = _progress_slider.x;
			
			for(var i:int = 0; i < ctrlObj.lCtrls.length; i++){
				ctrlObj.lCtrls[i].x = lpos[i];
			}
			
			if(ctrlObj.lCtrls.length == 0 || ctrlObj.rCtrls.length == 0){
				_lseparator_mc.visible = false;	
			} else {
				ctrlObj.rCtrls.push(_lseparator_mc);
			}
			
			if(_fs_btn.visible == false || (_atoggle_btn.visible == false && _audio_slider.visible == false)){
				_rseparator_mc.visible = false;
			} else {
				ctrlObj.rCtrls.splice(1,0,_rseparator_mc);
			}
			
			// Position right-aligned buttons
			var rpos:int = _fs_btn.x + _fs_btn.width;
			
			for(var j:int = 0; j < ctrlObj.rCtrls.length; j++){
				ctrlObj.rCtrls[j].x = (rpos - ctrlObj.rCtrls[j].width);
				rpos -= (ctrlObj.rCtrls[j].width + 4);
			}
			
			//mf/clear object from memory
			ctrlObj.rCtrls.splice(0, ctrlObj.rCtrls.length);
			ctrlObj.lCtrls.splice(0, ctrlObj.lCtrls.length);
			ctrlObj = null;
		}
		
		public function resetCtlPositionFS(scaleRatio:Number ):void {
			this.height *= scaleRatio;//set control bar size by ratio
			_h = this.height;//store height for rolOver
			
			var deltaX:int = 0;//accumulate the amount of shift of each control that has been re positiond
			var operSign:int = 1;
			var operMul:int=1
			if (scaleRatio > 1) {
				operSign = -1;
				operMul = scaleRatio;
			}
			else
				this.y += this.height;
				
						
			 
			var ctrlObj:Object = assignCtrlsSide();		//get controls
			for each (var iCtrlL:MovieClip in ctrlObj.lCtrls) {				
				iCtrlL.x -= (deltaX *operSign);			
				iCtrlL.width *= scaleRatio;					
				deltaX += iCtrlL.width/operMul;				
			}
			
			deltaX = 0;
			
			for each (var iCtrlR:MovieClip in ctrlObj.rCtrls) {			
				iCtrlR.width *= scaleRatio;	
				deltaX += iCtrlR.width/operMul;										
				iCtrlR.x += (deltaX*operSign);				
			}
			var lastRCtrl:MovieClip = ctrlObj.rCtrls[ctrlObj.rCtrls.length - 1];			
			var firstRCtrl:MovieClip = ctrlObj.rCtrls[0];		
			
			_lseparator_mc.x = lastRCtrl.x - lastRCtrl.width/2;//position left seporator on left of last right control
			_rseparator_mc.x = firstRCtrl.x - firstRCtrl.width/2;//position right seporator to left of first right operator
			
		
		}
		private function OnRollOver(e:MouseEvent):void
		{
			if(_rolloutTimer != -1){
				clearTimeout(_rolloutTimer);
				_rolloutTimer = -1;
				return;
			}
			
			if(nControlsMode == 0 || isAnimating) return;
			_handleRollOver(true);
		}
		
		private function _doHitTest():Boolean
		{
			var val:Boolean = this.hitTestPoint(EBBase.currentAssetRef.mouseX,EBBase.currentAssetRef.mouseY,false);
			
			if(!val){
				val = assignedScreen["hitTestPoint"](EBBase.currentAssetRef.mouseX,EBBase.currentAssetRef.mouseY,false);
			}
			
			return val;
		}
		
		private function OnRollOut(e:MouseEvent):void
		{	
			var val:Boolean = _doHitTest();
			
			if(!val){
				if(nControlsMode == 0 || isAnimating) return;
				_rolloutTimer = setTimeout(_performRollOut,500);
			} else {
				if(_rolloutTimer != -1){
					clearTimeout(_rolloutTimer);
					_rolloutTimer = -1;
				}
			}
		}
		
		private function OnMouseLeave(e:Event):void
		{
			_rolloutTimer = -1;
			_handleRollOver(false);
		}
		
		private function _performRollOut():void
		{
			var val:Boolean = _doHitTest();
			
			_rolloutTimer = -1;
			
			if(!val){
				_handleRollOver(false);
			}
		}
		
		private function _handleRollOver(isOver:Boolean):void
		{
			if (EBBase._stage !=null && EBBase._stage.displayState == StageDisplayState.FULL_SCREEN) return;
			if(isOver && !isRolledOver)
			{
				isRolledOver = true;
				//change size - show
				_animate(0, _h);
			}
			else if(!isOver && isRolledOver)
			{
				isRolledOver = false;
				//change size - hide
				_animate(_h, 0);
			}
		}
		
		private function _animate(startHeight:int,endHeight:int):void
		{
			if(startHeight == 0){
				_bg_mc.alpha = 1;
				visible = true;
			}
			
			isAnimating = true;
			tween = new Tween(this, "height", Regular.easeInOut, startHeight, endHeight, 0.5, true);
			tween.addEventListener(TweenEvent.MOTION_STOP,OnAnimateComplete);
		}
		
		private function OnAnimateComplete(e:Event):void
		{
			isAnimating = false;
			if(height == 0){
				_bg_mc.alpha = 0;
				visible = false;
			}
		}
	
	}
}