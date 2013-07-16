//****************************************************************************
//      EBExp class
//---------------------------
//
//This class containing the Exp banners family (Exp banners, Push down banners, Single expandable)
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBNotificationEvent;
	import eyeblaster.utils.JSMethodMap;
	import flash.display.StageDisplayState;
	
	import flash.events.*;

	/**
	 * Rpvides APIs for panels manipulations.
	 */
	public class EBPanel
	{
		/**
		 * Constructor. Only static methods are used - constructor shouldn't be called.
		 */
		public function EBPanel()
		{
			Tracer.debugTrace("EBPanel constructor", 3);
			Init();
		}

		/**
		 * Inititalizes internal properties and logic.
		 */
		public static function Init():void
		{
				Tracer.debugTrace("EBPanel.Init", 3);
		}

		/**
		 * Hides panel.
		 * <p>Replaces "ebHide" and "ebAutoHide" fscommands.</p>
		 * 
		 * @param	panelName panel name
		 * @param	type action type. Possible values: "Auto" and "User".
		 * @param	kill indicates if panel must be removed from DOM.
		 */
		public static function CollapsePanel(panelName:String, type:String = "User", kill:Boolean=false):void
		{
			// if we are in fullscreen - exit to normal view before collapsing to avoid IE getting stack
			if (!EBBase.urlParams.isInStream && EBBase._stage.displayState == StageDisplayState.FULL_SCREEN) 
				EBBase._stage.displayState=StageDisplayState.NORMAL;

			EBBase.reportTypedCmd("CollapsePanel", panelName, type);
			
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION,EBNotificationEvent.COLLAPSE);
			e.isAuto = type == "Auto";
			EBBase.dispatchEvent(e);
		}
		
		/**
		 * Shows a panel.
		 * <p>Replaces "ebShow", "ebAutoShow" and "ebShowWhenReady" fscommands.</p>
		 *
		 * @param	panelName
		 * @param	type possible valuse: "Auto", "User", "WhenReady"
		 * @see #EBPanel.ExpandPanel()
		 */
		public static function ExpandPanel(panelName:String, type:String = "User"):void
		{
			EBBase.reportTypedCmd("ExpandPanel", panelName, type);
			
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION,EBNotificationEvent.EXPAND);
			e.isAuto = type == "Auto";
			EBBase.dispatchEvent(e);
		}
		
		/**
		 * Moves and resizes the panel relative to the upper-left corner of the ad placement.
		 * @param	panelName The panel name in the platform.
		 * @param	x Target x position of the upper-left corner of the panel. Pass null for no change.
		 * @param	y Target y position of the upper-left corner of the panel. Pass null for no change
		 * @param	w Target width of the panel. Pass null for no change.
		 * @param	h Target height of the panel. Pass null for no change.
		 */
		public static function ModifyPanel(panelName:String, x:Number, y:Number, w:Number, h:Number):void
		{
			// does not have an equivalent in mdmd javascript offering
			EBBase.CallJSFunction(JSMethodMap.JS_MODFIY_PANEL + "(" + EBBase.adId + "," + panelName + "," + isNaN(x) ? "VwC" : String(x) + "," + isNaN(y) ? "VwC" : String(y) + "," + isNaN(w) ? "VwC" : String(w) + "," + isNaN(h) ? "VwC" : String(h) + ")");
		
		}
		
		/**
		 * Moves and resizes the panel relative to the upper-left corner of its original position in the ad placement.
		 * @param	panelName The panel name in the platform.
		 * @param	x Target x position of the upper-left corner of the panel. Pass null for no change.
		 * @param	y Target y position of the upper-left corner of the panel. Pass null for no change
		 * @param	w Target width of the panel. Pass null for no change.
		 * @param	h Target height of the panel. Pass null for no change.
		 */
		public static function ModifyPanelRelToOrig(panelName:String, x:Number, y:Number, w:Number, h:Number):void
		{
			// does not have an equivalent in mdmd javascript offering
			EBBase.CallJSFunction(JSMethodMap.JS_MODIFY_PANEL_REL_TO_ORIG + "(" + EBBase.adId + "," + panelName + "," + isNaN(x) ? "VwC" : String(x) + "," + isNaN(y) ? "VwC" : String(y) + "," + isNaN(w) ? "VwC" : String(w) + "," + isNaN(h) ? "VwC" : String(h) + ")");
		}
		
		/**
		 * Animates a panel to a new size and position via JavaScript.
		 * @param	panelName The panel name in the platform.
		 * @param	x Target x position of the upper-left corner of the panel. Pass null for no change.
		 * @param	y Target y position of the upper-left corner of the panel. Pass null for no change
		 * @param	h Target height of the panel. Pass null for no change.
		 * @param	w Target width of the panel. Pass null for no change.
		 * @param	duration Length of the animation in seconds.
		 * @param	append Optional. If true, flash will wait for a previous panel animation to complete before starting this one.
		 */
		public static function AnimatePanel(panelName:String, x:Number, y:Number, w:Number, h:Number, duration:Number, append:Boolean = false):void
		{
			// does not have an equivalent in mdmd javascript offering
			EBBase.CallJSFunction(JSMethodMap.JS_ANIMATE_PANEL + "(" + EBBase.adId + "," + panelName + ",VwC,VwC,VwC,VwC," + isNaN(x) ? "VwC" : String(x) + "," + isNaN(y) ? "VwC" : String(y) + "," + isNaN(w) ? "VwC" : String(w) + "," + isNaN(h) ? "VwC" : String(h) + "," + (duration < .1 ? 1 : Math.ceil(duration * 10)) + (append ? ",'append'" : "") + ")");
		}
	}
}
