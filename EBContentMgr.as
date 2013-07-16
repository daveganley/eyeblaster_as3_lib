/**
 * class EBContentMgr
 * -----------------------------------------
 * This class is allows loading in of external content into the creative
 *
 * ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
 */
package
{
	import eyeblaster.core.Tracer;
	import eyeblaster.data.ContentQueue;
	import flash.display.DisplayObjectContainer;
	
	public class EBContentMgr
	{
		//private var ebBase:EBBase;
		private static var contentQueue:ContentQueue;
		//private static var initialized:Boolean;
		private static var numArray:Array = [];
		
		/**
		 * Class Initialization called by EBBase
		 */
		public static function Init():void
		{
			contentQueue = new ContentQueue();
			// TODO: Why 100 is the limit?
			//On the Init, this checks for the number of additional assets that have been specified in the flashvars and
			//stores that information for efficient retrieval later. Note - this loop starts at 1 because the additional
			//asset parameter starts at 1 not 0
			for (var i:int = 1; i <= 100; i++)
			{
				if (GetAssetURL(String(i)) != "")
					numArray.push(i);
			}
			//initialized = true;
		}
		
		// TODO: what are possible datatypes for asset attribute? If possible typeas are swf and bitmaps - it should be DisplayObject.
		// TODO: looks like targetClip will be an object extending Sprite.
		/**
		 * Loads specified content into the target DisplayObjectContainer, for instance, ActionScript 3.0 SWFs and images.<br>
		 *
		 * @param targetClip:MovieClip MovieClip to load external content into
		 * @param asset:* File to load into movie clip
		 * @param callback - Function to call when loading is complete
		 */
		public static function LoadContent(target:DisplayObjectContainer, asset:*, callback:Function = null):void
		{
			var url:String = GetAssetURL(asset);
			
			if (url != "")
				contentQueue.AddContent(target, url, callback);
			else
				Tracer.debugTrace("Error | EBContentMgr - no asset at given location or you are working locally", 0);
		}
		
		/**
		 * Unloads content from the target movieclip.
		 *
		 * @param targetClip:DisplayObjectConatiner DisplayObjectContainer to remove
		 */
		public static function UnloadContent(targetClip:DisplayObjectContainer):void
		{
			contentQueue.RemoveContent(targetClip);
		}
		
		/**
		 * Opens window that prompts the user to download a file.
		 *
		 * @param asset File to download, i.e., "mydocument.pdf" or ordinal number of asset
		 */
		public static function Download(asset:*):void
		{
			var url:String = GetAssetURL(asset);
			
			if (url != "")
				EBBase.OpenJumpURL(url, "_blank");
			else
				Tracer.debugTrace("Error | EBContentMgr Download - supplied file not valid, or you are working locally - cannot download", 0);
		}
		
		/**
		 * Returns the number of additional assets that are used by the creative. This property is available from the flashVars.
		 */
		public static function get NUM_ADDITIONAL_ASSETS():int
		{
			return numArray.length;
		}
		
		/**
		 * This function returns URL of a ordinal number of additional asset
		 *
		 * @param index:int - ordinal number of additional asset
		 */
		public static function GetAdditionalAsset(index:int):String
		{
			return GetAssetURL(String(index));
		}
		
		/**
		 * This function returns URL of a valid asset file, will return "" if asset was not located
		 *
		 * @param asset search urlparams for matching asset - will accept ordinal number, file name or http address
		 */
		public static function GetAssetURL(asset:String):String
		{
			//If asset is already a URL request, return string as is
			// only http and https are  possible - thus check for http is sufficient
			if (asset.toLowerCase().indexOf("http") == 0)
				return asset;
			
			//Check to see if asset is an ordinal number and in flashvars
			var ebMovie:String = EBBase.urlParams["ebMovie" + asset];
			// TODO: this logic doesn't make sense. If asset doesn't exist in FlashVars to begin with - it will not get into array - thus, what is the point in checking this array? In addition, loop checks agaist asset anyway.
			//If not in flashvars, check all assets for matching filename
			//if (!ebMovie || ebMovie == "")
			//{
				//if (initialized)
				//{
					//for (var i:int = 0; i < NUM_ADDITIONAL_ASSETS; i++)
					//{
						//ebMovie = EBBase.urlParams["ebMovie" + numArray[i]];
						//
						//if (ebMovie.indexOf(asset) > -1)
							//return ebMovie;
					//}
				//}
				//If neither ordinal search or filename search match, return ""
				//return "";
			//}
			
			return ebMovie ? ebMovie : "";
		}
		
		/**
		 * This function returns the ordinal asset number given the asset url
		 *
		 * @param url location of the asset that you want the ordinal number of
		 */
		public static function GetAssetOrdinal(url:String):Number
		{
			for each(var i:int in numArray) {
				if (EBBase.urlParams["ebMovie" + i] == url)
					return i;
			}
			
			return NaN;
		}
	}
}