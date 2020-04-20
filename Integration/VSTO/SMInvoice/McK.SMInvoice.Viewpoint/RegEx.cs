using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace McK.SMInvoice.Viewpoint
{
    public static class RegEx
    {
        private const string _emailMatchPattern = @"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b";

        /// <summary>
        /// Extract valid email address from string
        /// </summary>
        /// <param name="input"></param>
        /// <returns>True if valid, otherwise false</returns>
        public static bool IsValidEmailAddress(string input, string emailMatchPattern = _emailMatchPattern)
        {
            Regex rx = new Regex(emailMatchPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            return rx.Matches(input).Count > 0;
        }

        /// <summary>
        /// Contains case sensitive
        /// </summary>
        /// <param name="input"></param>
        /// <param name="lookfor"></param>
        /// <returns></returns>
        public static bool ContainsWord(string input, string lookfor)
        {
            //var match = Regex.Match(input, @"/\b" + lookfor + "\b/");
            Regex rx = new Regex(@"\b(\w*" + lookfor + @"\w*)\b", RegexOptions.Compiled);
            return rx.Matches(input).Count > 0;
        }
    }
}
