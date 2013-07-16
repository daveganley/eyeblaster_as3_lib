
package eyeblaster.utils 
{
	import eyeblaster.core.Tracer;

	/**
	 * SWF general utility class
	 */
	public class SWFUtils 
	{
		
		public static function IsRunningInSecureMode() : Boolean
		{
			var res:Boolean = false;
			
			try
			{	
				res = (EBBase._root.loaderInfo.url.toLowerCase().indexOf("https") == 0);
			}
			catch (e:Error)
			{
				Tracer.debugTrace("SWFUtils::IsRunningInSucureMode: " + e, 0);
			}
			
			return res;
		}
		
	}

}