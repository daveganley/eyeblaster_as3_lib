//****************************************************************************
//      eyeblaster.Blocks class
//------------------------------
//
//This class adds versioning and update functionality to Eyeblaster Blocks.
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster
{
	import flash.net.SharedObject;
    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	
	public class Blocks
	{
		public function Blocks(){}
		
		//register
		public static function initBlock(id:int, version:int, displayName:String){
			if (EBBase._root.loaderInfo.parameters.ebDomain!=undefined){return;} // continue only if in editing mode - this variable is passed to the ad upon serving
			
			var blockID=String(id);
			var so:SharedObject=SharedObject.getLocal("EBblocks");
			
			var today_date:Date = new Date();
			var date_str:String = (today_date.getDate()+"/"+(today_date.getMonth()+1)+"/"+today_date.getFullYear());
	
			if (so.data[blockID]==undefined || so.data[blockID]!=date_str)
			{// check on server only if no check was made in the last 24 hours
				var loader:URLLoader;
				loader = new URLLoader();           
				try {
					loader.load(new URLRequest("http://platform.mediamind.com/Eyeblaster.ACM.Web/Creative/Workshop/Blocks/VersionCheck.aspx?ID="+id));
				}
				catch (error:SecurityError)
				{
					return;
            	}
            	loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            	loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			}
			
			function loaderCompleteHandler(event:Event):void {	// data was returned from server
				so.data[blockID]=date_str;
				so.flush();			
				// trim the result
				var resultFromServer:String=loader.data.replace(/^\s+|\s+$/gs, '');
				if (resultFromServer!=String(version)){
					trace("Eyeblaster Blocks | There is a newer version of Eyeblaster "+displayName+" Block you are using.\nPlease go to http://creativezone.eyeblaster.com/blocks.aspx and download the new version.");
				}
			}
	
			function errorHandler(e:IOErrorEvent):void {
				return;
			}			
			
		}
	}
}