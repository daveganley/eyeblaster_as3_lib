//****************************************************************************
//      EB class
//---------------------------
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package
{
	import flash.display.DisplayObjectContainer;
	import flash.display.DisplayObject;
	import flash.events.*;
	import eyeblaster.core.Tracer;
	import flash.utils.getDefinitionByName;
	
	/**
	 * This class combines APIs from several classes into a single API. This class doesn't have any internal logic implementation other than calling other classe APIs.
	 *
	 * <p>The following classes contain the APIs which are used by the <code>EB</code> class:</p>:
	 * <ul>
	 * <li>EBBase</li>
	 * <li>EBContentMgr</li>
	 * <li>EBPanel</li>
	 * <li>EBVideoMgr</li>
	 * </ul>
	 *
	 * @author Mehari
	 * @see EBBase
	 * @see EBContentMgr
	 * @see EBPanel
	 * @see EBVideoMgr
	 */
	public class EB
	{
		/**
		 * References to EBVideoMgr Class. 
		 * Reference is acquired at runtime.
		 */
		private static var VideoMgr:Class;
		
		/**
		 * @copy EBBase#urlParams
		 * @see EBBase#urlParams
		 */
		public static function get urlParams():Object
		{
			return EBBase.urlParams;
		}
		
		/**
		 * @copy EBBase#flashId
		 * @see EBBase#flashId
		 */
		public static function get flashId():String
		{
			return EBBase.flashId;
		}
		
		/**
		 * @copy EBBase#clickTag
		 * @see clickTAG
		 * @see EBBase#clickTag
		 */
		public static function get clickTag():String
		{
			return EBBase.clickTag;
		}
		
		/**
		 * @copy EBBase#clickTAG
		 * @see clickTag
		 * @see EBBase#clickTAG
		 */
		public static function get clickTAG():String
		{
			return EBBase.clickTAG;
		}
		
		/**
		 * @copy EBBase#clickTARGET
		 * @see EBBase#clickTARGET
		 */
		public static function get clickTARGET():String
		{
			return EBBase.clickTARGET;
		}
		
		/**
		 * @copy EBPanel#CustomVars
		 * @see EBPanel#CustomVars
		 */
		public static function get CustomVars():Object
		{
			return EBBase.CustomVars;
		}
		
		/**
		 * Creates EB object.
		 * <p>All <code>EB</code> class methods and attributes are static. Class shouldn't be instantiated.</p>
		 * @param	objRef reference to creative
		 */
		public function EB(objRef:DisplayObjectContainer):void
		{
			Tracer.debugTrace("EB constructor", 3);
			Init(objRef);
		}
		
		/**
		 * Performs initialization routine.
		 * @param	objRef reference to an object that uses EB services.
		 */
		public static function Init(objRef:DisplayObjectContainer, stateHandler:Boolean = false):void
		{
			Tracer.debugTrace("EB.Init new", 3);
			// attempt to acquire reference to EBVideoMgr
			try
			{
				VideoMgr = getDefinitionByName("EBVideoMgr") as Class;
			}
			catch (err:Error)
			{
			}
			EBBase.Init(objRef, stateHandler);
		}
		
		/**
		 * @copy EBPanel#OpenJumpURL()
		 * @see EBPanel#OpenJumpURL()
		 */
		public static function OpenJumpURL(url:String, window:String = null):Boolean
		{
			return EBBase.OpenJumpURL(url, window);
		}
		
		/**
		 * @copy EBPanel#CallJSFunction()
		 * @see EBPanel#CallJSFunction()
		 */
		public static function CallJSFunction(functionName:String, ... args:Array):Object
		{
			return EBBase.CallJSFunction(functionName, args);
		}
		
		/**
		 * @copy EBBase#GetVars()
		 * @see EBBase#GetVars()
		 */
		public static function GetVars(strVar:String):Number
		{
			return EBBase.GetVars(strVar);
		}
		
		/**
		 * @copy EBBase#Clickthrough()
		 * @see EBBase#Clickthrough()
		 */
		public static function Clickthrough(name:String = ""):void
		{
			EBBase.Clickthrough(name);
		}
		
		/**
		 * @copy EBBase#UserActionCounter()
		 * @see EBBase#UserActionCounter()
		 */
		public static function UserActionCounter(name:String):void
		{
			EBBase.UserActionCounter(name);
		}
		
		/**
		 * @copy EBBase#AutomaticEventCounter()
		 * @see EBBase#AutomaticEventCounter()
		 */
		public static function AutomaticEventCounter(name:String):void
		{
			EBBase.AutomaticEventCounter(name);
		}
		
		/**
		 * @copy EBBase#StartTimer()
		 * @see EBBase#StartTimer()
		 */
		public static function StartTimer(name:String):void
		{
			EBBase.StartTimer(name);
		}
		
		/**
		 * @copy EBBase#StopTimer()
		 * @see EBBase#StopTimer()
		 */
		public static function StopTimer(name:String):void
		{
			EBBase.StopTimer(name);
		}
		
		/**
		 * @copy EBBase#CloseAd()
		 * @see EBBase#CloseAd()
		 */
		public static function CloseAd(type:String = "User", kill:Boolean = false):void
		{
			EBBase.CloseAd(type, kill);
		}
		
		/**
		 * @copy EBBase#ReplayAd()
		 * @see EBBase#ReplayAd()
		 */
		public static function ReplayAd(type:String = "User"):void
		{
			EBBase.ReplayAd(type)
		}
		
		/**
		 * @copy EBBase#HideIntro()
		 * @see EBBase#HideIntro()
		 */
		public static function HideIntro():void
		{
			EBBase.HideIntro();
		}
		
		/**
		 * @copy EBPanel#CollapsePanel()
		 * @see EBPanel#CollapsePanel()
		 */
		public static function CollapsePanel(panelName:String, type:String = "User", kill:Boolean = false):void
		{
			EBPanel.CollapsePanel(panelName, type, kill);
		}
		
		/**
		 * @copy EBPanel#ExpandPanel()
		 * @see EBPanel#ExpandPanel()
		 */
		public static function ExpandPanel(panelName:String, type:String = "User"):void
		{
			EBPanel.ExpandPanel(panelName, type);
		}
		
		/**
		 * @copy EBBase#IntroFullPlay()
		 * @see EBBase#IntroFullPlay()
		 */
		public static function IntroFullPlay():void
		{
			EBBase.IntroFullPlay();
		}
		
		/**
		 * @copy EBBase#KeepAdOpen()
		 * @see EBBase#KeepAdOpen()
		 */
		public static function KeepAdOpen():void
		{
			EBBase.KeepAdOpen();
		}
		
		/**
		 * @copy EBBase#GoToMiniSite()
		 * @see EBBase#GoToMiniSite()
		 */
		public static function GoToMiniSite():void
		{
			EBBase.GoToMiniSite();
		}
		
		/**
		 * @copy EBBase#LoadRichBanner()
		 * @see EBBase#LoadRichBanner()
		 */
		public static function LoadRichBanner():void
		{
			EBBase.LoadRichBanner();
		}
		
		/**
		 * @copy EBBase#ShowRichBanner()
		 * @see EBBase#ShowRichBanner()
		 */
		public static function ShowRichBanner():void
		{
			EBBase.ShowRichBanner();
		}
		
		/**
		 * @copy EBBase#GetVar()
		 * @see EBBase#GetVar()
		 */
		public static function GetVar(varName:String):*
		{
			return EBBase.GetVar(varName);
		}
		
		/**
		 * @copy EBBase#GetAllVars()
		 * @see EBBase#GetAllVars()
		 */
		public static function GetAllVars():Object
		{
			return EBBase.GetAllVars();
		}
		
		/**
		 * @copy EBBase#SetVar()
		 * @see EBBase#SetVar()
		 */
		public static function SetVar(name:String, val:*):void
		{
			EBBase.SetVar(name, val);
		}
		
		/**
		 * @copy EBBase#addEventListener()
		 * @see EBBase#addEventListener()
		 */
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			EBBase.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			EBBase.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * @copy EBBase#CallHandler()
		 * @see EBBase#CallHandler()
		 */
		public static function CallHandler(handlerName:String, ...args):void
		{
			var functionArgs:Array = args;
			functionArgs.unshift(handlerName);
			EBBase.CallHandler.apply(null, functionArgs);
		}
		
		/**
		 * @copy EBBase#AddHandler()
		 * @see EBBase#AddHandler()
		 */
		public static function AddHandler(handlerName:String, callback:Function):void
		{
			EBBase.AddHandler(handlerName, callback);
		}
		
		/**
		 * @copy EBVideoMgr#RegisterVideo()
		 * @see EBVideoMgr#RegisterVideo()
		 */
		public static function RegisterVideo(compRef:*):void
		{
			if (VideoMgr) 
				Class(VideoMgr).RegisterVideo(compRef);
		}
		
		/**
		 * @copy EBVideoMgr#StopAll()
		 * @see EBVideoMgr#StopAll()
		 */
		public static function StopAll():void
		{
			if (VideoMgr) 
				Class(VideoMgr).StopAll();
		}
		
		/**
		 * @copy EBVideoMgr#SetAdVolume()
		 * @see EBVideoMgr#SetAdVolume()
		 */
		public static function SetAdVolume(volume:Number):void
		{
			if (VideoMgr) 
				Class(VideoMgr).SetAdVolume(volume);
		}
		
		/**
		 * @copy EBVideoMgr#ToggleAdAudio()
		 * @see EBVideoMgr#ToggleAdAudio()
		 */
		public static function ToggleAdAudio(value:Number = 2, isAuto:Number = 0):void
		{
			if (VideoMgr) 
				Class(VideoMgr).ToggleAdAudio(value, isAuto);
		}
		
		// TODO: what are possible datatypes for asset attribute? If possible typeas are swf and bitmaps - it should be DisplayObject.
		// TODO: looks like targetClip will be an object extending Sprite.
		/**
		 * @copy EBContentMgr#LoadContent()
		 * @see EBContentMgr#LoadContent()
		 */
		public static function LoadContent(targetClip:DisplayObjectContainer, asset:*, callback:Function = null):void
		{
			EBContentMgr.LoadContent(targetClip, asset, callback);
		}
		
		/**
		 * @copy EBContentMgr#UnloadContent()
		 * @see EBContentMgr#UnloadContent()
		 */
		public static function UnloadContent(targetClip:DisplayObjectContainer):void
		{
			EBContentMgr.UnloadContent(targetClip);
		}
		
		/**
		 * @copy EBContentMgr#Download()
		 * @see EBContentMgr#Download()
		 */
		public static function Download(asset:*):void
		{
			EBContentMgr.Download(asset);
		}
		
		/**
		 * @copy EBContentMgr#NUM_ADDITIONAL_ASSETS
		 * @see #EBContentMgr.NUM_ADDITIONAL_ASSETS
		 */
		public static function get NUM_ADDITIONAL_ASSETS():int
		{
			return EBContentMgr.NUM_ADDITIONAL_ASSETS;
		}
		
		/**
		 * @copy EBContentMgr#GetAdditionalAsset()
		 * @see EBContentMgr#GetAdditionalAsset()
		 */
		public static function GetAdditionalAsset(index:int):String
		{
			return EBContentMgr.GetAssetURL(String(index));
		}
		
		/**
		 * @copy EBContentMgr#GetAssetURL()
		 * @see EBContentMgr#GetAssetURL()
		 */
		public static function GetAssetURL(asset:String):String
		{
			return EBContentMgr.GetAssetURL(asset);
		}
		
		/**
		 * @copy EBContentMgr#GetAssetOrdinal()
		 * @see EBContentMgr#GetAssetOrdinal()
		 */
		public static function GetAssetOrdinal(assetURL:String):int
		{
			return EBContentMgr.GetAssetOrdinal(assetURL);
		}
		
		/**
		 * @copy EBBase#dispatchEvent()
		 * @see EBBase#dispatchEvent()
		 */
		public static function dispatchEvent(e:Event):void
		{
			EBBase.dispatchEvent(e);
		}
		
		/**
		 * @copy EBPanel#modifyPanel()
		 * @see EBPanel#modifyPanel()
		 */
		public static function ModifyPanel(panelId:Number, x:Number, y:Number, w:Number, h:Number):void
		{
			EBPanel.ModifyPanel(String(panelId), x, y, w, h);
		}
		
		/**
		 * @copy EBPanel#modifyPanelRelToOrig()
		 * @see EBPanel#modifyPanelRelToOrig()
		 */
		public static function ModifyPanelRelToOrig(panelId:Number, x:Number, y:Number, w:Number, h:Number):void
		{
			EBPanel.ModifyPanelRelToOrig(String(panelId), x, y, w, h);
		}
		
		/**
		 * @copy EBPanel#animatePanel()
		 * @see EBPanel#animatePanel()
		 */
		public static function AnimatePanel(panelId:Number, x:Number, y:Number, w:Number, h:Number, duration:Number, append:Boolean = false):void
		{
			EBPanel.AnimatePanel(String(panelId), x, y, w, h, duration, append);
		}
		
		/**
		 * @copy EBPanel#sendPing()
		 * @see EBPanel#sendPing()
		 */
		public static function SendPing(ping:String):void
		{
			EBBase.SendPing(ping);
		}

		/**
		 * @copy EBBase#handleCommand()
		 * @see EBBase#handleCommand()
		 */
		public static function handleCommand(cmd:String,args:String):Object
		{
			return EBBase.handleCommand(cmd,args);
		}
		
		public static function ebSetComponentName(name:String):void
		{
		}
	}
}