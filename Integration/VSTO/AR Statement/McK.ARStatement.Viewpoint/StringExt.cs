using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace McK.ARStatement.Viewpoint
{

    /// <summary>
    /// These extention methods are internationally friendly and will pass the "Turkey test" (why use OrdinalIgnoreCase vs CurrentCultureIgnoreCase)
    /// See: http://www.moserware.com/2008/02/does-your-code-pass-turkey-test.html
    /// </summary>
    public static class StringExt
    {
        /// <summary>
        /// Case insensitive Compare
        /// </summary>
        /// <param name="lookIn">Text to search in</param>
        /// <param name="lookFor">Text to search for</param>
        /// <param name="comp">Optional compare type</param>
        /// <returns></returns>
        public static bool ContainsIgnoreCase(this string lookIn, string lookFor, System.StringComparison comp = StringComparison.OrdinalIgnoreCase) => lookIn.IndexOf(lookFor, comp) >= 0;

        /// <summary>
        /// Case insensitive Equals
        /// </summary>
        /// <param name="lookIn">Text to search in</param>
        /// <param name="lookFor">Text to search for</param>
        /// <param name="comp">Optional compare type</param>
        /// <returns></returns>
        public static  bool Equals(this string lookIn, string lookFor, System.StringComparison comp = StringComparison.OrdinalIgnoreCase) => string.Equals(lookIn, lookFor, comp);
        
    }
}
