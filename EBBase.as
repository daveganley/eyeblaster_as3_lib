//****************************************************************************
//      EBBase class
//---------------------------
//
//This class containing the base code that is common to ExpBanner, Polite banners and OOB families. 
//The class supports code related to instream as well
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package
{
	import eyeblaster.core.IntDuration;
	import eyeblaster.core.Tracer;
	import eyeblaster.events.*;
	import eyeblaster.events.EBPageEvent;
	import eyeblaster.utils.AutomationVarsMap;
	import eyeblaster.utils.JSMethodMap;
	import flash.utils.setTimeout;
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.getDefinitionByName;
	
	/**
	 * close event notification. For instream, make sure to cleanup listeners and timers
	 * so that errors don't happen in player after ad is gone.
	 *
	 * @eventType eyeblaster.events.EBNotificationEvent
	 */
	[Event(name="Close",type="eyeblaster.events.EBNotificationEvent")]
	
	public class EBBase
	{
		/**
		 * prefix for EB classes
		 */
		private static var browserEngine:String = "internal"; //browser engine provided by flashvars
		private static var intDurationObj:IntDuration; //instance of the ebInteractionDurationAS3 class
		private static var evDispatcher:EventDispatcher;
		private static var closureMap:Object = {};
		private static var _customVars:Object = {};
		private static var handlers:Object = {};
		
		/**
		 * Indicates whether initializations was done.
		 */
		private static var isInit:Boolean = false;

		/**
		 * Indicates whether we are running inside instream player.
		 */
		private static var isInStream:Boolean = false;
		
		/**
		 * Holds reference to <code>Stage</code> instance.
		 */
		public static var _stage:Stage;
		/**
		 * Holds reference to root.
		 */
		public static var _root:DisplayObject;
		/**
		 * A collection of parameters that are passed as FlashVars.
		 */
		private static var _urlParams:Object = {};
		/**
		 * The ID of the Flash object. This property is  passed as the following: FlashVar ebFlashID.
		 */
		public static var flashId:String;
		/**
		 * Tells the Flash banner where it should link to.
		 * It works by tracking the code that is assigned to an individual ad by the ad serving network.
		 * The clickTag thus allows the network to register where the ad was displayed when it was clicked on.
		 * The clickthrough data is then reported back to the ad server to determine the effectiveness of the campaign.
		 * The clickTag is passed as the following: FlashVar clickTag.
		 *
		 * @see clickTAG
		 */
		public static var clickTag:String;
		/**
		 * Tells the Flash banner where it should link to.
		 * It works by tracking the code that is assigned to an individual ad by the ad serving network.
		 * The clickTAG thus allows the network to register where the ad was displayed when it was clicked on.
		 * The clickthrough data is then reported back to the ad server to determine the effectiveness of the campaign.
		 * The clickTAG is passed as the following:  FlashVar clickTAG.
		 *
		 * @see clickTag
		 */
		public static var clickTAG:String;
		/**
		 * Set from FlashVars.
		 */
		public static var clickTARGET:String;
		/**
		 * Reference to current asset.
		 */
		public static var currentAssetRef:DisplayObjectContainer;
		/**
		 * <code>MovieClip</code> attached to the calling asset. Functions as a dynamic objects with runtime added functions.
		 */
		public static var AssetRefMC:MovieClip;
		/**
		 * Indicates version.
		 */
		public static var SVversionCT:String = "";
		/**
		 * Holds the ad id on the platform received via JavaScript.
		 */
		public static var adId:int = -1;
		/**
		 * Holds panel Id.
		 */
		private static var panelId:int = -1;
		//uniqueChar is a non-printable character used as string delimiter to ensure no conflict with passed in characters
		static private var uniqueChar:String = String.fromCharCode(127);
		
		/**
		 * holds the Custom Variables
		 */
		public static function get CustomVars():Object
		{
			return _customVars;
		}
		
		/**
		 * Setting value to an object writes properties and values iteratively.
		 * Value of urlParams object is npot overridden - each subsequent call to set value preserves previously set properties.
		 */
		static public function get urlParams():Object
		{
			return _urlParams;
		}
		
		static public function set urlParams(value:Object):void
		{
			if (value)
			{
				for (var prop:String in value)
				{
					_urlParams[prop] = value[prop];
				}
			}
		
		}
		
		//----version------
		include "eyeblaster/core/compVersion.as"
		include "eyeblaster/core/ebVersion.as"
		
		/**
		 * Constructor. All APIs are static - constructor shouldn't be called.
		 *
		 * @param	creative
		 */
		public function EBBase(creative:DisplayObjectContainer)
		{
			Init(creative);
		}
		
		// TODO: confirm that Init can be called many times atr different stages of application. For now any time it is called - routine will be done again.
		/**
		 * Performs initialization routine.
		 */ /**
		 * Performs initialization routine.
		 *
		 * @param	creative
		 * @param	config - additional configuration properties. These properties are set on urlparams object.
		 *
		 * @see urlParams
		 */
		public static function Init(creative:DisplayObjectContainer, ...args):void
		{		
			//*** Temporary for instream, since loader/creative are on different domains
			//Security.allowDomain("*");
			//Security.allowInsecureDomain("*");
			
			// is initialized only once
			if (creative && !isInit)
			{
				//When user calls Init(this) with class document
				// check for AssetRefMC assures that this is done once.
				if (creative.parent is Stage || (creative.parent && creative.parent.name == "ebInStreamLoader") && !AssetRefMC || String(creative) == "[object MainTimeline]")
				{
					if (creative.parent && creative.parent.name == "ebInStreamLoader")
					{
						isInStream = true; // loader parent will be called ebInStreamLoader
					}
					
					currentAssetRef = creative;
					//set to currentAssetRef a movieclip that to it attached a method that will be called from the container in order to communicate between the container and the asset
					//The function invokes the methods that were registered by Callback function.
					//The function is called from the container in case of in stream
					AssetRefMC = new MovieClip();
					currentAssetRef.addChild(AssetRefMC);
					AssetRefMC.name = "ebAssetRefMC";
					AssetRefMC["invokeFunc"] = function(funcPath:String, funcToInvoke:String = "", params:String = ""):void
					{
						if ((params != "") && (funcToInvoke != ""))
							closureMap[funcPath](funcToInvoke, params);
						else if (funcToInvoke != "")
							closureMap[funcPath](funcToInvoke);
						else
							closureMap[funcPath]();
					}
					
					AssetRefMC.ebModuleCapable = true;
				}
				// for backward compatibility: sometimes reference to Stage instance is passed.
				_stage = creative is Stage ? creative as Stage : creative.stage;
				_root = creative.root;
				_urlParams.stateHandler = Boolean(args[0]);
				urlParams = _root.loaderInfo.parameters;
				
				Security.allowDomain(urlParams.ebDomain);
				//add to closureMap hashtable the setAttrInStream in order to set attributes from the container in instream case
				closureMap["setAttrInStream"] = setAttrInStream;
				setStaticParams();
				// make sure we are not in InStream
				// registration() removed - it was called only once
				if (ExternalInterface.available && !isInStream)
				{
					try{
						ExternalInterface.addCallback("ebOpenJumpURL", OpenJumpURL);
						ExternalInterface.addCallback("ebGetVars", GetVars);
					}
					catch(error:Error){
						setTimeout(Init, 150, creative);
						return;
					}
				}
				initModules();
				//set _customVars with values
				GetAllVars();
				//start measure the int duration - private method removed
				intDurationObj = new IntDuration(creative);
				
				//Register handlers for JS/loader to call callHandler on creative
				Callback("ebCreativeCallHandler", handleCallHandlerFromJS);
				
				loadExternalModules();
				isInit = true;
			}
		
		}
		
		/**
		 * The function is called from the JavaScrip to open the click-thru URL.
		 * <p><code>OpenJumpURL</code> is designed to be used on Safari on Mac in which the popup blocker blocks a new window opened from the JavaScript.</p>
		 * @param	url
		 * @param	window
		 * @return
		 */
		public static function OpenJumpURL(url:String, window:String = null):Boolean
		{
			Tracer.debugTrace("OpenJumpURL in EBBase: " + url + ", " + window, 0);
			// RegExp matches whole word not case sensitive
			if (window != "_self" && ExternalInterface.available && !browserEngine.match(/^\bwebkit\b|\bopera\b|\binternal\b|\bunknown\b|\baim\b/))
				ExternalInterface.call("window.open", url, window, "");
			else
				navigateToURL(new URLRequest(url), window);
			return true;
		}
		
		/**
		 * The function is called from the JavaScript. Allows for checking mouse position over SWF object in DOM and use an indication for the JS if it is AS2 or AS3.
		 *
		 * <p><b>Important!</b> Only numerical values are returned. If parameter is a name of variable that is not related to mouse position or ActionScript version - <code>NaN</code> returned.</p>
		 *
		 * @param	vars String containing values delimited by ":" (colon). Only last string is read. Accepted and processed values: "xmouse", "ymouse";
		 * @return
		 */
		public static function GetVars(vars:String):Number
		{
			
			var n:Number;
			switch (String(vars.match(/(?<=:)\w+$/)))
			{
				//for delayed expansion feature
				//the mouse x position
				case "xmouse": 
					n = EBBase._stage.mouseX;
					break;
				//the mouse y position
				case "ymouse": 
					n = EBBase._stage.mouseY;
					break;
			}
			return n;
		}
		
		/**
		 * Enables reporting of a click interaction (eyeblaster or custom interaction). A Clickthrough measures clicks and opens a new window when clicked.
		 * <p>This function replaces "ebInteraction" fscommand.</p>
		 *
		 * @param	name The interaction name. An empty string indicates an _eyeblaster interaction.
		 * @see EB#Clickthrough();
		 */
		public static function Clickthrough(name:String = ""):void
		{
			Tracer.debugTrace("Clickthrough " + name + " tracked", -1);
			
			if (!isInStream)
				// This fix some bugs related to click through when ad is in full screen mode
				dispatchEvent(new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.EXIT_FULLSCREEN_MODE));
			//check for SV2 version
			handleCommand("ebClickthrough", (name == "" && SVversionCT != "") ? SVversionCT : name);
			//dispatch a an event notifying template of the click
			dispatchEvent(new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.CLICK));
		}
		
		/**
		 * Enables reporting of a custom user interaction.
		 * <p>Replaces "ebInteraction" fscommand.</p>
		 * @param	name interaction name.
		 * @see EB#UserActionCounter()
		 */
		public static function UserActionCounter(name:String):void
		{
			validateAndReportCI("UserActionCounter", name);
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.TRACK);
			e.label = name;
			e.isAuto = false;
			dispatchEvent(e);
		}
		
		/**
		 * Enables reporting of a custom timeline event interaction. An Automatic Event Counter interaction measures ad timeline events, like having a video watched until the end.
		 *
		 * <p>Replaces "ebInteraction" fscommand.</p>
		 * @param	name interaction name.
		 */
		public static function AutomaticEventCounter(name:String):void
		{
			validateAndReportCI("AutomaticEventCounter", name);
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.TRACK);
			e.label = name;
			e.isAuto = true;
			dispatchEvent(e);
		}
		
		/**
		 * Allows user to start custom timer interaction.
		 * <p>Replaces fscommand "ebStartTimer".</p>
		 * @param	name interaction name.
		 * @see EB#StartTimer()
		 */
		public static function StartTimer(name:String):void
		{
			validateAndReportCI("StartTimer", name);
		}
		
		/**
		 * Allows user to stop a custom timer interaction.
		 * <p>Replaces fscommand "ebEndTimer"</p>
		 * @param	name interaction name.
		 * @see EB#StopTimer()
		 */
		public static function StopTimer(name:String):void
		{
			validateAndReportCI("StopTimer", name);
		}
		
		/**
		 * Closes the ad via calling JavaScript <code>CloseAd</code> function.
		 * <p>Replaces "ebClose", "ebQuit" and "ebAutoClose" fscommands.</p>
		 *
		 * @param	type  identifies who initiates close. Possible values: "Auto" and "User".
		 * @param   kill  optional boolean flag signalling whether ad should be unloaded
		 * @see EB#CloseAd()
		 */
		public static function CloseAd(type:String = "User", kill:Boolean = false):void
		{
			reportTypedCmd("CloseAd", "", type);
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.NOTIFICATION, EBNotificationEvent.CLOSE);
			e.isAuto = type == "Auto";
			dispatchEvent(e);
		}
		
		/**
		 * Calls a JavaScript function on page. Uses ExternalInterface if available.
		 *
		 * @example
		 * <listing version="3.0">
		 * EB.CallJSFunction('somefunction','argument1','argument2');
		 * </listing>
		 *
		 * @param	functionName The name of JavaScript function.
		 * @param	... args The parameter or parameters to be passed to the function.
		 * @return	Object returned by JavaScript function if applicable.
		 */
		public static function CallJSFunction(functionName:String, ... args):Object
		{
			if (EI_Compatible())
			{
				// ...rest becomes array in function body.
				args.unshift(functionName);
				return ExternalInterface.call.apply(EBBase, args);
			}
			else
			{
				//External Interface is either not available or compatible with current browser version
				//This code builds out a javascript url request that will be passed to the navigateToURL method
				//instead of using the ExternalInterface
				OpenJumpURL("javascript:" + functionName + "('" + args.join(",").replace(/\,/g, "','") + "')", "_self");
			}
			return null;
		}
		
		/**
		 * Checks the browserEngine string provided by flashvars and ensures that it is compatbile with ExternalInterface
		 *
		 * Example: EI_Compatible();
		 * @example
		 * <listing version="3.0">
		 * EI_Compatible();
		 * </listing>
		 *
		 */
		public static function EI_Compatible():Boolean
		{
			return browserEngine.match(/(opera)|(unknown)/i) ? false : ExternalInterface.available;
		}
		
		/**
		 * Initiates ad replay.
		 * <p>Replaces "ebReplay" and "ebAutoReplay" fscommands.</p>
		 *
		 * @param	type identifies how replay is initiated. Possible values: "Auto" and "User"
		 * @see EB#ReplayAd()
		 */
		public static function ReplayAd(type:String = "User"):void
		{
			reportTypedCmd("ReplayAd", "", type);
		}
		
		/**
		 * Closes intro and displays the remainder of ad.
		 * <p>Replaces "ebHide" fscommand.</p>
		 *
		 * @see EB#HideIntro()
		 */
		public static function HideIntro():void
		{
			reportCmd("HideIntro", "", "");
		}
		
		/**
		 * Switches from the intro movie to the remainder ad.
		 * <p>Replaces "ebEndOfMovie".</p>
		 *
		 * @see EB#IntroFullPlay()
		 */
		public static function IntroFullPlay():void
		{
			reportCmd("IntroFullPlay", "", "");
		}
		
		/**
		 * Allows to ignore ad display period.
		 * <p>Replaces "ebKeepAdOpen" fscommand.</p>
		 *
		 * @see EB#KeepAdOpen()
		 */
		public static function KeepAdOpen():void
		{
			reportCmd("KeepAdOpen", "", "");
		}
		
		/**
		 * Shows Mini site.
		 * <p>Replaces "ebClick" fscommand.</p>
		 *
		 * @see EB#GoToMiniSite()
		 */
		public static function GoToMiniSite():void
		{
			reportCmd("GoToMiniSite", "", "");
		}
		
		/**
		 * Loads Rich Flash asset of Polite Banner.
		 * <p>Replaces "ebLoadRichFlash" fscommand.</p>
		 *
		 * @see EB#LoadRichBanner()
		 */
		public static function LoadRichBanner():void
		{
			reportCmd("LoadRichBanner", "", "");
		}
		
		/**
		 * Starts playing rich flash asset of Polite Banner.
		 * <p>Replaces "ebStartRichFlash" fscommand.</p>
		 *
		 * @see EB#ShowRichBanner()
		 */
		public static function ShowRichBanner():void
		{
			reportCmd("ShowRichBanner", "", "");
		}
		
		/**
		 * Receives a command and sends it to the JS or the container (depending on the ad format)
		 * @param	cmd
		 * @param	args
		 * @return
		 */
		public static function handleCommand(cmd:String, args:String = ""):Object
		{
			try
			{
				if (urlParams.isInStream == true) //instream case - send the command to the container
				{
					return urlParams.parentClass["handleCommand"](cmd, args);
				}
				//not instrem case - send the command to the JS
				else if (ExternalInterface.available && flashId && ExternalInterface.call("ebIsFlashExtInterfaceExist"))
				{
					Tracer.debugTrace(cmd + ": use ExternalInterface: " + flashId + "_DoFSCommand" + "," + args, 3);
					return ExternalInterface.call(flashId + "_DoFSCommand", cmd, args);
				}
				else
				{
					Tracer.debugTrace(cmd + ": use fscommand", 3);
					fscommand(cmd, args);
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Error | Exception in handleCommand function in EBBase: " + error, 0);
			}
			
			return null;
		}
		
		/**
		 * Registers an ActionScript method. After an invocation of the given method, the registered function in Flash Player can be called by JavaScript or by the container in case of instream.
		 * @param	functionName
		 * @param	closure
		 */
		public static function Callback(functionName:String, closure:Function):void
		{
			//in instream register by update closureMap
			if (urlParams.isInStream == true)
				closureMap[functionName] = closure;
			//not in intream- register by addCallback
			else if (ExternalInterface.available)
				ExternalInterface.addCallback(functionName, closure);
		}
		
		/**
		 * Returns value of custom variable from the JavaScript client.
		 *
		 * @param	varName name of custom variable's value to return
		 * @return
		 *
		 * @see EB#GetVar()
		 */
		public static function GetVar(varName:String):*
		{
			var val:*;
			if (urlParams.isInStream == true) //instream case - send the command to the container
				val = urlParams.parentClass["handleCommand"]("ebGetJSVar", varName);
			else if (ExternalInterface.available)
				val = ExternalInterface.call(flashId + "_DoFSCommand", "ebGetJSVar", varName);
				
			// even if val is not defined - it will not be String
			if (val is String)
				val = unescape(val);
			return val;
		}
		
		/**
		 * Returns values of all custom variables from the JavaScript client.
		 *
		 * @return
		 *
		 * @see EB#GetAllVars()
		 */
		public static function GetAllVars():Object
		{
			if (urlParams.isInStream == true)
				_customVars = urlParams.parentClass["handleCommand"]("ebGetAllJSVars");
			else if (ExternalInterface.available)
				_customVars = ExternalInterface.call(flashId + "_DoFSCommand", "ebGetAllJSVars");
			
			if (_customVars)
			{
				for (var prop:String in _customVars)
					if (_customVars[prop] is String)
						_customVars[prop] = unescape(_customVars[prop]);
			}
			return _customVars;
		}
		
		/**
		 * Sets value of custom variable in JavaScript client.
		 *
		 * @param	name name of custom variable to be set
		 * @param	val
		 * @see EB#SetVar()
		 */
		public static function SetVar(name:String, val:*):void
		{
			// arguments passed as string
			handleCommand("ebSetJSVar", name + String.fromCharCode(127) + String(val) + (val is String ? String.fromCharCode(127) + "true" : ""));
		}
		
		/**
		 * Registers an event listener object with an EventDispatcher object.
		 * <p>For more information, see <a href="http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/events/EventDispatcher.html" target="_blank">http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/events/EventDispatcher.html</a></p>
		 *
		 * @param	type
		 * @param	listener
		 * @param	useCapture
		 * @param	priority
		 * @param	useWeakReference
		 *
		 * @see EB#addEventListener()
		 */
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			checkED();
			evDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			if (ExternalInterface.available && (urlParams.isInStream != true))
			{
				ExternalInterface.addCallback("handle" + type, DispatchEvent);
				handleCommand(type, "handle" + type);
			}
		}
		
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			checkED();
			evDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		
		/**
		 * Implements static IEventDispatcher method.
		 * <p>There is <code>DisapatchEvent</code> (with capital D) method as well.</p>
		 *
		 * @param	e
		 * @see DispatchEvent()
		 */
		public static function dispatchEvent(e:Event):void
		{
			checkED();
			evDispatcher.dispatchEvent(e);
		}
		
		/**
		 * Dospatches <code>EBPageEvent</code> <b>only</b>.
		 *
		 * @param	eventName
		 * @param	args
		 * @see dispatchEvent()
		 */
		public static function DispatchEvent(eventName:String, args:String):void
		{
			checkED();
			evDispatcher.dispatchEvent(new EBPageEvent(eventName, args));
		}
		
		/**
		 * Instantiates EventDispatcher if it was not created previously.
		 */
		private static function checkED():void
		{
			if (!evDispatcher)
				evDispatcher = new EventDispatcher();
		}
		
		/**
		 * Reports a command  that has different types.
		 *
		 * @param	cmd command to report
		 * @param	param command paramaters
		 * @param	type command type. Possible values: "Auto", "User", or "WhenReady".
		 */
		public static function reportTypedCmd(cmd:String, param:String, type:String):void
		{
			type = type.toLowerCase();
			if (type == "user" || type == "auto" || (cmd == "ExpandPanel" && type == "whenready"))
				reportCmd(cmd, param, (type == "whenready") ? "WhenReady" : type.replace(/^\w/, type.substr(0, 1).toUpperCase()));
			else
				Tracer.debugTrace("Error | Exception in " + cmd + ": one or more of the parameters has inappropriate value or type", 0);
		}
		
		/**
		 * TODO: mute/unmute workaround.
		 * but there is an existing event to that each videoscreen dispatches as ewll
		   [4:49:45 PM] Justin Haygood: that has volume and isMuted state
		   [5:08:07 PM] Justin Haygood: EBVideoMgr.Current.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE,OnVideoStateChange)
		 [5:08:29 PM] Justin Haygood: function OnVideoStateChange(e:EBVideoStateChangeEvent):void { trace(e.isMuted + ": "  + e.volume); }**/ /**
		 * Sends a ping via flash sendToURL
		 * @param	ping string to be sent as a ping
		 */
		public static function SendPing(ping:String):void
		{
			if (ping)
			{
				var ur:URLRequest = new URLRequest(ping);
				ur.method = URLRequestMethod.GET;
				sendToURL(ur);
			}
		}
		
		/**
		 * Reports command.
		 *
		 * @param	cmd command to report
		 * @param	param command paramaters
		 * @param	type
		 */
		public static function reportCmd(cmd:String, param:String, type:String):void
		{
			type = type.replace(/^\s+|\s+$/g, "");
			param = param.replace(/^\s+|\s+$/g, "");
			//only ExpandPanel and collapsePanel has 2 parameters
			handleCommand("eb" + cmd, ((type == "" || param == "") && !cmd.match(/Panel/)) ? param + type : param + "," + type);
			Tracer.debugTrace(type + " " + cmd + " " + param + " tracked", -1);
		}
		
		/**
		 * Returns if current mode is instream
		 *
		 * 
		 */
		public static function isInstream():Boolean
		{
			var returnCode:Boolean  = false;
			if (urlParams != null && urlParams.isInStream == true)
				returnCode = true;
			Tracer.debugTrace( "urlParams.isInStream = " + urlParams.isInStream, -1);
			return returnCode;
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods 
		
		/**
		 * Calls Init method of each module that is used in addition to the EBBase
		 */
		private static function initModules():void
		{
			for each (var m:String in["EBPanel", "EBVideoMgr", "EBContentMgr"])
			{
				//check for each class if was loaded and if loaded call to Init method there.
				var CL:Class = getClassByName(m);
				if (CL)
					CL["Init"]();
			}
		}
		
		/**
		 * Returns requested Class.
		 * @param	ebModule
		 * @return
		 */
		private static function getClassByName(ebModule:String):Class
		{
			try
			{
				return getDefinitionByName(ebModule) as Class;
			}
			catch (e:ReferenceError)
			{
				// do nothing
			}
			return null;
		}
		
		/**
		 * Checks if the CI is valid and reports it.
		 *
		 * @param	type interaction name
		 * @param	name interaction type: StartTimer, StopTimer, UserActionCounter, AutomaticEventCounter.
		 */
		private static function validateAndReportCI(type:String, name:String):void
		{
			if (name && name != "")
			{
				Tracer.debugTrace(type + " \"" + name + "\" tracked", -1);
				handleCommand("ebCI" + type, name);
			}
			else
			{
				Tracer.debugTrace("Error | Exception in " + type + ": no interaction name was given to the function", 0);
			}
		}
		
		// TODO: review the necessity of try...catch
		/**
		 * Sets the values that were set by the container in case of inastream
		 */
		private static function setAttrInStream():void
		{
			try
			{
				if (currentAssetRef && !urlParams.parentClass)
				{
					//set all the adiitional assets
					for (var i:*in currentAssetRef)
						urlParams[i] = currentAssetRef[i];
					setStaticParams();
					
					Tracer.debugTrace("External Modules Count: " + urlParams["ebModulesCount"], 3);
					
					// For instream, we wouldn't of loaded in modules yet.
					loadExternalModules();
				}
			}
			catch (error:Error)
			{
				Tracer.debugTrace("Error | Exception in setAttrInStream function in EBBase: " + error, 0);
			}
		}
		
		/**
		 * Sets the static parameters of clickTag (both versions) and ebMovie (from 1 to 10) according the values transferred from the JS.
		 */
		private static function setStaticParams():void
		{
			if (urlParams.browserEngine && urlParams.browserEngine != "")
				browserEngine = urlParams.browserEngine;
			clickTag = urlParams.clickTag;
			clickTAG = urlParams.clickTAG;
			clickTARGET = urlParams.clickTARGET;
			flashId = urlParams.ebFlashID;
			// set the ad id
			adId = urlParams["QAID"] ? int(urlParams["QAID"]) : adId;
			// set the panel id
			panelId = urlParams["QPAN"] ? int(EBBase.urlParams["QPAN"]) : panelId;
		}
		
		/**
		 * Serves as a marker for compiled application validation.
		 * FileReaderWriter (server-side component in the platform) scans the compiled SWF for all classes that call it, and stores the results in the database.
		 * It uses it to figure out what components are in the ad.
		 * @param	name component name.
		 * @private
		 */
		public static function ebSetComponentName(name:String):void
		{
		}
		
		/**
		 * Loads external modules passed in via url parameters
		 */
		private static function loadExternalModules():void
		{
			if (currentAssetRef is MovieClip && typeof urlParams["ebModule0"] != "undefined")
			{
				(currentAssetRef as MovieClip).stop();
			}
			
			var i:int = -1;
			var hasNext:Boolean = true;
			
			while (hasNext)
			{
				i++;
				
				var name:String = "ebModule" + i;
				hasNext = typeof urlParams[name] != "undefined";
				
				Tracer.debugTrace("Has Module: " + name + ": " + hasNext);
				
				if (hasNext)
				{
					var module:String = urlParams[name];
					
					Tracer.debugTrace("Loading module: " + name + ": " + module);
					
					var l:Loader = new Loader();
					l.name = name;
					l.contentLoaderInfo.addEventListener(Event.COMPLETE, onModulesComplete);
					l.load(new URLRequest(module), new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
					currentAssetRef[name] = l;
					currentAssetRef.addChild(l);
				}
			}
		}
		
		private static function onModulesComplete(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE, onModulesComplete);
			var c:* = e.target.content;
			c.init();
		}
		
		/**
		 * Calls a handler previously added via the EB.AddHandler method
		 * @param handlerName name of handler to call
		 * @param args a comma-delimited list of parameters that should match the handler functions parameters list.
		 */
		public static function CallHandler(handlerName:String, ... args):void
		{
			if (handlers[handlerName])
			{
				var method:Function = handlers[handlerName] as Function;
				
				if (args.indexOf(uniqueChar) > -1)
					args.pop();
				
				method.apply(currentAssetRef, args);
			}
			else if (args.indexOf(uniqueChar) == -1) //if handlerName was set up on a different SWF of multi-SWF expandable and call to CallHandler did not come from Javascript
			{
				args.unshift(handlerName);
				// Call on another creative through JS. Note that only string, number, boolean. References, arrays, objects and functions can't be passed.
				handleCommand("ebCreativeCallHdr", args.join(uniqueChar)); // turns into ebCreativeCallHdrHandler in JS
			}
		}
		
		/**
		 * Adds a function to the handlers that will be available for calling via the EB.CallHandler function.
		 * These methods can be reached anywhere in the creative without worrying about display list hierarchy, etc.
		 * @param handlerName name of handler to add to the handler list
		 * @param callback reference to the function to callback
		 */
		public static function AddHandler(handlerName:String, callback:Function):void
		{
			handlers[handlerName] = callback;
			// Add to JS for this creative
			handleCommand("ebCreativeAddHdr", handlerName + String.fromCharCode(127) + flashId); // turns into ebCreativeAddHdrHandler in JS
		}
		
		/**
		 * This is a callback from Javascript and the loader
		 * @param	args char 127 delimited list of args (strings, numbers, or booleans)
		 */
		private static function handleCallHandlerFromJS(args:String):void
		{
			var argsArray:Array = args.split(uniqueChar);
			for (var i:int = 1; i < argsArray.length; i++)
			{
				if (!isNaN(argsArray[i]))
					argsArray[i] = parseFloat(argsArray[i]);
				else if (argsArray[i] == "true" || argsArray[i] == "false")
					argsArray[i] = argsArray[i] == "true";
			}
			argsArray.push(uniqueChar);
			CallHandler.apply(null, argsArray);
		}
		
		/**
		 * In order to overcome IE popup blocker issues,
		 * use ExternalInterface if available to
		 * open the new window with clickTag url
		 */
		
		public static function OpenClickTag():void
		{
			if (clickTag != null && clickTag != "")
				if (EI_Compatible())
					ExternalInterface.call("window.open", clickTag, "_blank");
				else
					navigateToURL(new URLRequest(clickTag), "_blank");
		
		}
	}
}
