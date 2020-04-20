using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace McK.POReport.Viewpoint
{
    public static class RegEx
    {
        private const string _phoneMatchPattern = @"(?'label'cell|p|\bphone+.|\btel+.)?(?'special'[-\d@#:\s+,\.]{0,3}?(\d{1}\s){0,2}?)?(?'areaCode'[(]?\d{3}[)]?)(?'delimiter1'[-\s./]{0,3}?)(?'prefix'\d{3})(?'delimiter2'[-\s./]?)(?'lineNumber'\d{4})";
        
        private const string _emailMatchPattern = @"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b";

        private const string _carriageReturnPattern = @"(\r?\n)(\r)?";


        /// <summary>
        /// Extract phone numbers from string
        /// <para>Captures prefixes: #, @, +, -, and a digit </para>
        /// </summary>
        /// <param name="input"></param>
        /// <returns>Regex.MatchCollection</returns>
        /// <remarks><see cref="MatchCollection"/></remarks>
        public static MatchCollection GetPhoneNumbers(string input, string phoneMatchPattern = _phoneMatchPattern)
        {
            Regex rx = new Regex(phoneMatchPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            return rx.Matches(input);
        }

        /// <summary>
        /// Extract email address from string
        /// </summary>
        /// <param name="input"></param>
        /// <returns>Regex.MatchCollection</returns>
        /// <remarks><see cref="MatchCollection"/></remarks>
        public static MatchCollection GetEmailAddress(string input, string emailMatchPattern = _emailMatchPattern)
        {
            Regex rx = new Regex(emailMatchPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            return rx.Matches(input);
        }

        public static int GetCarriageReturnCount(string input, string carriageReturnPattern = _carriageReturnPattern)
        {
            Regex rx = new Regex(carriageReturnPattern, RegexOptions.Compiled | RegexOptions.Multiline);
            return rx.Matches(input).Count;
        }
    }
}
