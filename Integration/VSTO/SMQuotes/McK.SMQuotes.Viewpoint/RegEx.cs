using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace McK.SMQuotes.Viewpoint
{
    public static class RegEx
    {
        private const string _emailMatchPattern = @"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b";
        private const string _carriageReturnPattern = @"(\r?\n)(\r)?";

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
        /// Contains case insensitive search
        /// </summary>
        /// <param name="input"></param>
        /// <param name="lookfor"></param>
        /// <returns></returns>
        public static bool ContainsWord(string input, string lookfor)
        {
            //var match = Regex.Match(input, @"/\b" + lookfor + "\b/");
            Regex rx = new Regex(@"/\b" + lookfor + "\b/", RegexOptions.Compiled | RegexOptions.IgnoreCase);
            return rx.Matches(input).Count > 0;
        }

        public static int GetCarriageReturnCount(string input, string carriageReturnPattern = _carriageReturnPattern)
        {
            Regex rx = new Regex(carriageReturnPattern, RegexOptions.Compiled | RegexOptions.Multiline);
            return rx.Matches(input).Count;
        }
    }
}
