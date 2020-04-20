using Microsoft.VisualBasic;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.IO;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using BaseClasses.Configuration;
using System.Text;
using System.Web;
using System.Net;
using System.Xml.XPath;
using System.Xml;



namespace VPLookup.Data
{
	/// <summary>
	/// The FormulaUtils class contains a set of functions that are available
	/// in the Formula editor. You can specify any of these functions after
	/// the = sign.
	/// For example, you can say:
	/// = IsEven(32)
	/// These functions throw an exception on an error. The formula evaluator
	/// catches this exception and returns the error string to the user interface.
	///
	/// All of the functions operate as a Decimal. The Decimal data type is better
	/// then Double or Single since it provides a more accurate value as compared to
	/// Double, and a larger value as compared to a Single. All integers, doubles, etc.
	/// are converted to Decimals as part of these functions.
	///
	/// Function names are not case sensitive. So you can use ROUND, Round, round, etc.
	///
	/// </summary>
	/// <remarks></remarks>
	public class BaseFormulaUtils
	{
		#region "DataSource Lookup Functions"
		public static object Lookup(DataSource dataSourceName, object rowNumber, object id, object idColumn, object valueColumn)
		{
			return dataSourceName.Lookup(rowNumber, id, idColumn, valueColumn);

		}

		public static string Lookup(DataSource dataSourceName, object id, string format)
		{
			object val = dataSourceName.Lookup(null, id, null, null);
			if (val == null) {
				val = "";
			}
			return BaseFormulaUtils.Format(val, format);

		}

		public static string Lookup(DataSource dataSourceName, object id)
		{
			object val = dataSourceName.Lookup(null, id, null, null);
			if (val == null) {
				val = "";
			}
			return BaseFormulaUtils.Format(val, "");

		}

		#endregion

		#region "Information Functions"

		/// <summary>
		/// Check if the number is Even or not. 
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">Number to be checked</param>
		/// <returns>True if the input is even, False otherwise.</returns>
		public static bool IsEven(object val)
		{
			decimal valDecimal = 0;
			try {
				valDecimal = StringUtils.ParseDecimal(val);
				return (valDecimal % 2 == 0);
			} catch (Exception ex) {
				throw new Exception("ISEVEN(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Check if the input is odd or not
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">Number to be checked</param>
		/// <returns>True if the input is odd, False otherwise.</returns>
		public static bool IsOdd(object val)
		{
			decimal valDecimal = 0;
			try {
				valDecimal = StringUtils.ParseDecimal(val);
				return (valDecimal % 2 != 0);
			} catch (Exception ex) {
				throw new Exception("ISODD(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Check if the input is a number or not
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">Number to be checked</param>
		/// <returns>True if the input is a number, False otherwise.</returns>
		public static bool IsNumber(object val)
		{
			decimal valDecimal = 0;
			try {
				valDecimal = StringUtils.ParseDecimal(val);
				// If we are successfully parsing the number, then return True
				return true;
			// Ignore exception, just fall through and return false
			} catch {
			}
			return false;
		}

		/// <summary>
		/// Check if the input is logical or not
		/// The value can be specified as a decimal value (e.g., 37.48), 
		/// as a string (“True”), as a Boolean (e.g., True), as an expression (e.g., 1+1=2), 
		/// or as the value of a variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">Value to be checked</param>
		/// <returns>True if the input is a boolean, False otherwise.</returns>
		public static bool IsLogical(object val)
		{
			bool valBoolean = false;
			try {
				valBoolean = Convert.ToBoolean(val);
				// If we are able to successfully convert the value, then return True
				return true;
			// Ignore exception, just fall through and return false
			} catch {
			}
			return false;
		}

		/// <summary>
		/// Check if the input is null or not
		/// The value can be specified as a decimal value (e.g., 37.48), as a string (“True”),
		/// as an expression (e.g., 1+1=2), or as the value of a variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">Value to be checked</param>
		/// <returns>True if the input is null</returns>
		public static bool IsNull(object val)
		{
			// If val is nothing, then return True
			if (val == null) {
				return true;
			} else {
				return false;
			}
		}

		/// <summary>
		/// Check if the value entered is blank or not. A NULL value is considered blank too.
		/// The value can be specified as a decimal value (e.g., 37.48), as a string (“  ”), 
		/// as an expression (e.g., 1+1=2), or as the value of a variable (e.g, ShippedDate).
		/// </summary>
		/// <param name="val">Value to be checked</param>
		/// <returns>True if the input is blank</returns>
		public static bool IsBlank(object val)
		{
			if (val == null) {
				return true;
			}

			if (object.ReferenceEquals(val.GetType(), typeof(string)) && ((string)val).Trim().Length == 0) {
				return true;
			}

			return false;
		}

		/// <summary>
		/// Check if the value entered is a text or not
		/// The value can be specified as a decimal value (e.g., 37.48), as a string (“  ”), 
		/// as an expression (e.g., 1+1=2), or as the value of a variable (e.g, ShippedDate).
		/// </summary>
		/// <param name="val">Value to be checked</param>
		/// <returns>True if the input is text</returns>
		public static bool IsText(object val)
		{
			if (val == null) {
				return false;
			}

			if (object.ReferenceEquals(val.GetType(), typeof(string))) {
				return true;
			}

			return false;
		}

		#endregion

		#region "Mathematical Functions"

		/// <summary>
		/// Calculate the absolute value of the argument passed
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The input whose absolute value is to be found.</param>
		/// <returns>The absolute value of the number.</returns>
		public static decimal Abs(object val)
		{
			try {
				return Math.Abs(StringUtils.ParseDecimal(val));
			} catch (Exception ex) {
				throw new Exception("ABS(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the ceiling value of the argument passed
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The input whose ceiling value is to be calculated.</param>
		/// <returns>The ceiling value of the number.</returns>
		public static decimal Ceiling(object val)
		{
			try {
				return Math.Ceiling(StringUtils.ParseDecimal(val));
			} catch (Exception ex) {
				throw new Exception("CEILING(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculates the exponential value of the input
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The input whose exponential value is to be calculated</param>
		/// <returns>
		/// The exponential value of the input
		/// </returns>
		public static decimal Exp(object val)
		{
			Double valDouble = 0;
			try {
				valDouble = Convert.ToDouble(StringUtils.ParseDecimal(val));
				return Convert.ToDecimal(Math.Exp(valDouble));
			} catch (Exception ex) {
				throw new Exception("EXP(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculates the floor value of the input
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The input whose floor value is to be calculated</param>
		/// <returns>
		/// The floor value of the input
		/// </returns>
		public static decimal Floor(object val)
		{
			try {
				return Math.Floor(StringUtils.ParseDecimal(val));
			} catch (Exception ex) {
				throw new Exception("FLOOR(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculates the mod value of the division 
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="dividend">The dividend</param>
		/// <param name="divisor">The divisor</param>
		/// <returns>
		/// The mod value of the division.
		/// </returns>
		public static decimal Modulus(object dividend, object divisor)
		{
			decimal dividendDecimal = 0;
			decimal divisorDecimal = 0;
			try {
				dividendDecimal = StringUtils.ParseDecimal(dividend);
				divisorDecimal = StringUtils.ParseDecimal(divisor);
				return dividendDecimal % divisorDecimal;
			} catch (Exception ex) {
				throw new Exception("MODULUS(" + GetStr(dividendDecimal) + ", " + GetStr(divisorDecimal) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the value of a variable raised to the power of the other.
		/// The number can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val1">The base</param>
		/// <param name="val2">The power</param>
		/// <returns>
		/// The val1 raised to the power of val2
		/// </returns>
		public static decimal Power(object val1, object val2)
		{
			Double val1Double = 0;
			Double val2Double = 0;
			try {
				val1Double = Convert.ToDouble(StringUtils.ParseDecimal(val1));
				val2Double = Convert.ToDouble(StringUtils.ParseDecimal(val2));
				return Convert.ToDecimal(Math.Pow(val1Double, val2Double));
			} catch (Exception ex) {
				throw new Exception("POWER(" + GetStr(val1) + ", " + GetStr(val2) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Return the value of PI as a Decimal.
		/// </summary>
		public static decimal Pi()
		{
			return Convert.ToDecimal(Math.PI);
		}

		/// <summary>
		/// Calculate the quotient of the division 
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val1">The dividend of the division</param>
		/// <param name="val2">The divisor of the division</param>
		/// <returns>
		/// The quotient of the division.
		/// </returns>
		public static decimal Quotient(object dividend, object divisor)
		{
			try {
				return Convert.ToDecimal(Math.Ceiling(StringUtils.ParseDecimal(dividend) / StringUtils.ParseDecimal(divisor)));
			} catch (Exception ex) {
				throw new Exception("QUOTIENT(" + GetStr(dividend) + ", " + GetStr(divisor) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Round value up to the specified number of decimal places
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="number">Number to be rounded</param>
		/// <param name="numberOfDigits">Number of decimals to be rounded upto</param>
		/// <returns>The rounded up value.</returns>
		public static decimal Round(object number, object numberOfDigits)
		{
			try {
				return Math.Round(StringUtils.ParseDecimal(number), Convert.ToInt32(numberOfDigits));
			} catch (Exception ex) {
				throw new Exception("ROUND(" + GetStr(number) + ", " + GetStr(numberOfDigits) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the square root value of the input
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The argument whose square root is to be calculated</param>
		/// <returns>The square root.</returns>
		public static decimal Sqrt(object val)
		{
			Double valDouble = 0;
			try {
				valDouble = Convert.ToDouble(StringUtils.ParseDecimal(val));
				return Convert.ToDecimal(Math.Sqrt(valDouble));
			} catch (Exception ex) {
				throw new Exception("SQRT(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the truncated value of the input
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The argument whose truncated value is to be calculated</param>
		/// <returns>The truncated value.</returns>
		public static decimal Trunc(object val)
		{
			try {
				return Convert.ToDecimal(Math.Truncate(StringUtils.ParseDecimal(val)));
			} catch (Exception ex) {
				throw new Exception("TRUNC(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the logarithmic value to the specified base
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val1">The argument whose log value is to be calculated</param>
		/// <param name="val2">The value which would act as a base</param>
		/// <returns>The log value</returns>
		public static decimal Log(object val1, object val2)
		{
			Double val1Double = 0;
			Double val2Double = 0;
			try {
				val1Double = Convert.ToDouble(StringUtils.ParseDecimal(val1));
				val2Double = Convert.ToDouble(StringUtils.ParseDecimal(val2));
				return Convert.ToDecimal(Math.Log(val1Double, val2Double));
			} catch (Exception ex) {
				throw new Exception("LOG(" + GetStr(val1) + ", " + GetStr(val2) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Calculate the logarithmic value to the base 10
		/// The number(s) can be specified as an integer (e.g., 37), a decimal 
		/// value (e.g., 37.48), as a string with an optional currency symbol and 
		/// separators ("1,234.56", "$1,234.56"), or as the value of a 
		/// variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="val">The argument whose log value is to be calculated</param>
		/// <returns>The log value.</returns>
		public static decimal Log(object val)
		{
			Double valDouble = 0;
			try {
				valDouble = Convert.ToDouble(StringUtils.ParseDecimal(val));
				return Convert.ToDecimal(Math.Log10(valDouble));
			} catch (Exception ex) {
				throw new Exception("LOG(" + GetStr(val) + "): " + ex.Message);
			}
		}

		#endregion

		#region "Boolean Functions"

		/// <summary>
		/// Calculate the AND value of the input array
		/// The value(s) can be specified as a decimal value (e.g., 37.48), 
		/// as a string (“True”), as a Boolean (e.g., True), as an expression (e.g., 1+1=2), 
		/// or as the value of a variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="args">The array of booleans whose AND value is to be calculated</param>
		/// <returns>The and value.</returns>
		public static bool And1(params object[] args)
		{
			bool andValue = true;
			// Iterate the loop to get the individual values from the group of parameters
			foreach (object booleanValue in args) {
				if (booleanValue != null) {
					try {
						andValue = andValue && Convert.ToBoolean(booleanValue.ToString());
						if (andValue == false) {
							return andValue;
						}
					//if a value is non-boolean, we will ignore this value.
					} catch {
					}
				}
			}
			return andValue;
		}

		/// <summary>
		/// Calculate the OR value of the input array
		/// The value(s) can be specified as a decimal value (e.g., 37.48), 
		/// as a string (“True”), as a Boolean (e.g., True), as an expression (e.g., 1+1=2), 
		/// or as the value of a variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="args">The array of booleans whose OR value is to be calculated</param>
		/// <returns>The or value.</returns>
		public static bool Or1(params object[] args)
		{
			bool orValue = false;
			// Iterate the loop to get the individual values from the group of parameters
			foreach (object booleanValue in args) {
				if (booleanValue != null) {
					try {
						orValue = orValue || Convert.ToBoolean(booleanValue);
						if (orValue == true) {
							return orValue;
						}
					//if a value is non-boolean, we will ignore this value.
					} catch {
					}
				}
			}
			return orValue;
		}

		/// <summary>
		/// Calculate the NOT value of the specified boolean value
		/// The value(s) can be specified as a decimal value (e.g., 37.48), 
		/// as a string (“True”), as a Boolean (e.g., True), as an expression (e.g., 1+1=2), 
		/// or as the value of a variable (e.g, UnitPrice).
		/// </summary>
		/// <param name="value">The boolean value whose NOT is to be determined</param>
		/// <returns>The not value.</returns>
		public static bool Not1(object value)
		{
			try {
				return !Convert.ToBoolean(value);
			} catch (Exception ex) {
				throw new Exception("NOT1(" + GetStr(value) + "): " + ex.Message);
			}
		}
		#endregion

		#region "String Functions"

		/// <summary>
		/// Return a character for the corresponding ascii value
		/// </summary>
		/// <param name="val">Ascii Value</param>
		/// <returns>Charcter for the corresponding ascii value</returns>
		public static char Character(object val)
		{
			try {
				return Convert.ToChar(val);
			} catch (Exception ex) {
				throw new Exception("CHARACTER(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Check if two strings are exactly same or not
		/// </summary>
		/// <param name="val1">1st String</param>
		/// <param name="val2">2nd String</param>
		/// <returns>True if the two strings are exactly same else returns false</returns>
		public static bool Exact(object val1, object val2)
		{
			try {
				val1 = GetStr(val1);
				val2 = GetStr(val2);
				if (val1.Equals(val2)) {
					return true;
				} else {
					return false;
				}
			} catch (Exception ex) {
				throw new Exception("EXACT(" + GetStr(val1) + ", " + GetStr(val2) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Finds the index of the occurrence of the 1st string in the 2nd string specified
		/// </summary>
		/// <param name="val1">String to be searched</param>
		/// <param name="val2">String to be searched in</param>
		/// <returns>The index of the occurrence of the 1st string in the 2nd string and -1 if the string not found</returns>
		public static int Find(object val1, object val2)
		{
			string val1String = string.Empty;
			string val2String = string.Empty;
			try {
				if (val1 != null) {
					val1String = val1.ToString();
				}
				if (val2 != null) {
					val2String = val2.ToString();
				}

				return val2String.IndexOf(val1String, 0);
			} catch (Exception ex) {
				throw new Exception("FIND(" + GetStr(val1) + ", " + GetStr(val2) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Find the index of the occurrence of the 1st string in the 2nd string,
		/// the search starts after a specified start position
		/// </summary>
		/// <param name="val1">String to be searched</param>
		/// <param name="val2">String to be searched in</param>
		/// <param name="index">The position after which the search should start</param>
		/// <returns>The index of the occurrence of the 1st string in the 2nd string and -1 if the string is not found</returns>
		public static int Find(object val1, object val2, int index)
		{
			string val1String = string.Empty;
			string val2String = string.Empty;
			try {
				if (val1 != null) {
					val1String = val1.ToString();
				}
				if (val2 != null) {
					val2String = val2.ToString();
				}

				return val2String.IndexOf(val1String, index);
			} catch (Exception ex) {
				throw new Exception("FIND(" + GetStr(val1) + ", " + GetStr(val2) + ", " + index + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns the string from left till the index mentioned
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <param name="length">The length of string to be returned</param>
		/// <returns>The string of specified length from the start</returns>
		public static string Left(object str, int length)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}

				return inputString.Substring(0, length);
			} catch (Exception ex) {
				throw new Exception("LEFT(" + GetStr(str) + ", " + length + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns the string from right till the index mentioned
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <param name="length">The length of string to be returned</param>
		/// <returns>The string of specified length from the end</returns>
		public static string Right(object str, int length)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}

				return inputString.Substring(inputString.Length - length, length);
			} catch (Exception ex) {
				throw new Exception("RIGHT(" + GetStr(str) + ", " + length + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns the left most character of the string
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The first character of string</returns>
		public static string Left(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.Substring(0, 1);
			} catch (Exception ex) {
				throw new Exception("LEFT(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns the right most character of the string
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The last character of a string</returns>
		public static string Right(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.Substring(inputString.Length - 1, 1);
			} catch (Exception ex) {
				throw new Exception("RIGHT(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns the length of the string
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The length of the string</returns>
		public static int Len(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.Length;
			} catch (Exception ex) {
				throw new Exception("LEN(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Converts the string to lower case 
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The string which is lower case</returns>
		public static string Lower(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.ToLower();
			} catch (Exception ex) {
				throw new Exception("LOWER(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Converts the string to upper case
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The string which is upper case</returns>
		public static string Upper(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.ToUpper();
			} catch (Exception ex) {
				throw new Exception("UPPER(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the substring from the specified index and of specified length
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <param name="startIndex">The start index of retrieval</param>
		/// <param name="length">Length of the string to be retrieved</param>
		/// <returns>The substring</returns>
		public static string Mid(object str, int startIndex, int length)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.Substring(startIndex, length);
			} catch (Exception ex) {
				throw new Exception("MID(" + GetStr(str) + ", " + startIndex + ", " + length + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the substring from the specified index and of specified length
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <param name="startIndex">The start index of retrieval</param>
		/// <param name="length">Length of the string to be retrieved</param>
		/// <returns>The substring</returns>
		public static string Substring(object str, int startIndex, int length)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				return inputString.Substring(startIndex, length);
			} catch (Exception ex) {
				throw new Exception("SUBSTRING(" + GetStr(str) + ", " + startIndex + ", " + length + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the substring from the specified index till the end of the string
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <param name="startIndex">The start index of retrieval</param>
		/// <returns>The substring</returns>
		public static string Substring(object str, int startIndex)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				// As we are using a 1 based indexing we are using .Length 
				// which returns the exact length
				return inputString.Substring(startIndex, inputString.Length - startIndex);
			} catch (Exception ex) {
				throw new Exception("SUBSTRING(" + GetStr(str) + ", " + startIndex + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the substring from the specified index till the end of the string
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>The Capitalized string</returns>
		public static string Capitalize(object str)
		{
			string inputString = string.Empty;
			try {
				if (str != null) {
					inputString = str.ToString();
				}
				// As we are using a 1 based indexing we are using .Length 
				// which returns the exact length
				return inputString.Substring(0, 1).ToUpper() + inputString.Substring(1, inputString.Length - 1);
			} catch (Exception ex) {
				throw new Exception("CAPITALIZE(" + GetStr(str) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Replaces the specified part of a string with a new string
		/// </summary>
		/// <param name="oldString">String to be operated upon</param>
		/// <param name="startIndex">The start index of the part to be replaced</param>
		/// <param name="length">The length of the part be replaced</param>
		/// <param name="newString">The new string which replaces the old string.</param>
		/// <returns>The string which is upper case</returns>
		public static string Replace(object oldString, int startIndex, int length, object newString)
		{
			string inputString = string.Empty;
			try {
				if (oldString != null) {
					inputString = oldString.ToString();
				}
				// We are using a 1 based indexing in this function
				return inputString.Substring(0, startIndex) + newString.ToString() + inputString.Substring(startIndex + length);
			} catch (Exception ex) {
				throw new Exception("REPLACE(" + GetStr(oldString) + ", " + startIndex + ", " + length + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Repeats the text specified number of times the specified part of a string with a new string
		/// </summary>
		/// <param name="text">Text to be operated</param>
		/// <param name="numberOfTimes">The number of times text is to be repeated</param>
		/// <returns>The string with repeatetive text in it</returns>
		public static string Rept(object text, int numberOfTimes)
		{
			string textStr = string.Empty;
			string finalString = string.Empty;
			int i = 0;
			// We are using a 1 based indexing in this function
			if (text != null) {
				textStr = text.ToString();
			}
			try {
				for (i = 0; i <= numberOfTimes - 1; i++) {
					finalString = finalString + textStr;
				}
				return finalString;
			} catch (Exception ex) {
				throw new Exception("REPT(" + GetStr(text) + ", " + numberOfTimes + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Concatenates the arguments in the array
		/// </summary>
		/// <param name="args">Array of arguments</param>
		/// <returns>Concatenated string</returns>
		public static string Concatenate(params object[] args)
		{
			string finalString = string.Empty;
			// We are using a 1 based indexing in this function
			try {
				foreach (object str in args) {
					if (str != null) {
						finalString = finalString + str.ToString();
					}
				}
				return finalString;
			} catch (Exception ex) {
				throw new Exception("CONCATENATE(" + GetStr(args) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Trims the leading and trailing spaces
		/// </summary>
		/// <param name="str">String to be operated upon</param>
		/// <returns>Trimmed string</returns>
		public static string Trim(object str)
		{
			try {
				string finalString = string.Empty;
				if (str != null) {
					finalString = str.ToString().Trim();
				}
				return finalString;
			} catch (Exception ex) {
				throw new Exception("TRIM(" + GetStr(str) + "): " + ex.Message);
			}
		}
		#endregion

		#region "DateTime Functions"

		/// <summary>
		/// Retrieves the hours from the date
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The hour part of the date and if date is empty string then returns now's hours</returns>
		public static decimal Hour(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Hour;
				}
				return finalDate.Hour;
			} catch (Exception ex) {
				throw new Exception("HOUR(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the minutes from the date
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The minutes part of the date and if date is empty string then returns now's minute</returns>
		public static decimal Minute(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Minute;
				}
				return finalDate.Minute;
			} catch (Exception ex) {
				throw new Exception("MINUTE(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the years from the date
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The years part of the date and if date is empty string then returns today's year</returns>
		public static decimal Year(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Year;
				}
				return finalDate.Year;
			} catch (Exception ex) {
				throw new Exception("MINUTE(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the month from the date
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The month part of the date and if date is empty string then returns this month</returns>
		public static decimal Month(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Month;
				}
				return finalDate.Month;
			} catch (Exception ex) {
				throw new Exception("MONTH(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the day from the date
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The day of the date and if date is empty string then returns today's day</returns>
		public static decimal Day(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Day;
				}
				return finalDate.Day;
			} catch (Exception ex) {
				throw new Exception("Day(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Retrieves the seconds from the date
		/// </summary>
		/// <param name="val">The date to be operated upon</param>
		/// <returns>The seconds part of the date and if date is empty string then returns seconds now</returns>
		public static decimal Second(object valDate)
		{
			DateTime finalDate = new DateTime();
			try {
				if (!DateTime.TryParse(valDate.ToString(), out finalDate)) {
					return DateTime.Now.Second;
				}
				return finalDate.Second;
			} catch (Exception ex) {
				throw new Exception("SECOND(" + GetStr(valDate) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns a datevalue specifying the hours minutes and seconds
		/// </summary>
		/// <param name="val">The date to be operated upon</param>
		/// <returns>The seconds part of the date and if date is empty string then returns seconds now</returns>
		public static DateTime Time1(object valHour, object valMinute, object valSecond)
		{

			DateTime finalDate = default(DateTime);
			finalDate = DateTime.Today;

			try {
				finalDate = finalDate.AddHours(Convert.ToInt32(valHour));
				finalDate = finalDate.AddMinutes(Convert.ToInt32(valMinute));
				finalDate = finalDate.AddSeconds(Convert.ToInt32(valSecond));

				return finalDate;
			} catch (Exception ex) {
				throw new Exception("TIME1(" + GetStr(valHour) + ", " + GetStr(valMinute) + ", " + GetStr(valSecond) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Returns today's date
		/// </summary>
		/// <returns>Today's date</returns>
		public static DateTime Now()
		{
			return DateTime.Now;
		}

		/// <summary>
		/// Returns today's date
		/// </summary>
		/// <returns>Today's date</returns>
		public static DateTime Today()
		{
			return DateTime.Today;
		}

		/// <summary>
		/// Retrieves yesterday's date
		/// </summary>
		/// <returns>Yesterday's date</returns>
		public static DateTime Yesterday()
		{
			return DateTime.Today.AddDays(-1);
		}

		/// <summary>
		/// Retrieve the date of start of the week
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The start date of the week</returns>
		public static DateTime StartOfWeek(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			inputDate = inputDate.AddDays(0 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 0, 0, 0);
		}

		/// <summary>
		/// Retrieve the date of end of the week
		/// </summary>
		/// <param name="valDate">The date to be operated upon</param>
		/// <returns>The end date of the week</returns>
		public static DateTime EndOfWeek(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			inputDate = inputDate.AddDays(6 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 23, 59, 59);
		}

		/// <summary>
		/// Retrieve the start date of the current week
		/// </summary>
		/// <returns>The start date of the current week</returns>
		public static DateTime StartOfCurrentWeek()
		{
			DateTime inputDate = DateTime.Today;
			inputDate = inputDate.AddDays(0 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 0, 0, 0);
		}

		/// <summary>
		/// Retrieve the end date of the current week
		/// </summary>
		/// <returns>The end date of the current week</returns>
		public static DateTime EndOfCurrentWeek()
		{
			DateTime inputDate = DateTime.Today;
			inputDate = inputDate.AddDays(6 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 23, 59, 59);
		}

		/// <summary>
		/// Retrieve the start date of the previous week
		/// </summary>
		/// <returns>The start date of the previous week</returns>
		public static DateTime StartOfLastWeek()
		{
			DateTime inputDate = DateTime.Today;
			inputDate = inputDate.AddDays(-7 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 0, 0, 0);
		}

		/// <summary>
		/// Retrieve the end date of the previous week
		/// </summary>
		/// <returns>The end date of the previous week</returns>
		public static DateTime EndOfLastWeek()
		{
			DateTime inputDate = DateTime.Today;
			inputDate = inputDate.AddDays(-1 - Convert.ToDouble(inputDate.DayOfWeek));
			return new DateTime(inputDate.Year, inputDate.Month, inputDate.Day, 23, 59, 59);
		}

		/// <summary>
		/// Retrieve the start date of the month for the date passed
		/// </summary>
		/// <param name="valDate">The date whose start date of month is to be found</param>
		/// <returns>The start date of the month</returns>
		public static DateTime StartOfMonth(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			DateTime startDate = new DateTime(inputDate.Year, inputDate.Month, 1);
			return startDate;
		}

		/// <summary>
		/// Retrieve the end date of the month for the date passed
		/// </summary>
		/// <param name="valDate">The date whose end date of month is to be found</param>
		/// <returns>The end date of the month</returns>
		public static DateTime EndOfMonth(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			DateTime endDate = inputDate.AddMonths(1);
			endDate = new DateTime(endDate.Year, endDate.Month, 1, 23, 59, 59).AddDays(-1);
			return endDate;
		}

		/// <summary>
		/// Retrieve the start date of the current month
		/// </summary>
		/// <returns>The start date of the current month</returns>
		public static DateTime StartOfCurrentMonth()
		{
			DateTime startDate = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1);
			return startDate;
		}

		/// <summary>
		/// Retrieve the end date of the current month
		/// </summary>
		/// <returns>The end date of the current month</returns>
		public static DateTime EndOfCurrentMonth()
		{
			DateTime endDate = DateTime.Today.AddMonths(1);
			endDate = new DateTime(endDate.Year, endDate.Month, 1, 23, 59, 59).AddDays(-1);
			return endDate;
		}

		/// <summary>
		/// Retrieve the start date of the last month
		/// </summary>
		/// <returns>The start date of the last month</returns>
		public static DateTime StartOfLastMonth()
		{
			DateTime prevMonthDate = DateTime.Today.AddMonths(-1);
			return new DateTime(prevMonthDate.Year, prevMonthDate.Month, 1);
		}

		/// <summary>
		/// Retrieve the end date of the last month
		/// </summary>
		/// <returns>The end date of the last month</returns>
		public static DateTime EndOfLastMonth()
		{
			DateTime endDate = DateTime.Today;
			endDate = new DateTime(DateTime.Today.Year, DateTime.Today.Month, 1, 23, 59, 59);
			endDate = endDate.AddDays(-1);
			return endDate;
		}

		/// <summary>
		/// Retrieve the start date of the quarter for the date passed
		/// </summary>
		/// <param name="valDate">The date whose start date of quarter is to be found</param>
		/// <returns>The end date of the quarter</returns>
		public static DateTime StartOfQuarter(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			int quarter = (inputDate.Month - 1) / 3 + 1;
			DateTime startQuarterDate = new DateTime(inputDate.Year, 3 * quarter - 2, 1);
			return startQuarterDate;
		}

		/// <summary>
		/// Retrieve the end date of the quarter for the date passed
		/// </summary>
		/// <param name="valDate">The date whose end date of quarter is to be found</param>
		/// <returns>The end date of the quarter</returns>
		public static DateTime EndOfQuarter(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			int quarter = (inputDate.Month - 1) / 3 + 1;
			DateTime quarterLastDate = new DateTime(inputDate.Year, 3 * quarter, 1, 23, 59, 59).AddMonths(1).AddDays(-1);
			return quarterLastDate;
		}

		/// <summary>
		/// Retrieve the start date of the current quarter
		/// </summary>
		/// <returns>The start date of the current quarter</returns>
		public static DateTime StartOfCurrentQuarter()
		{
			DateTime dateToday = DateTime.Today;
			int currQuarter = (DateTime.Today.Month - 1) / 3 + 1;
			DateTime dtFirstDay = new DateTime(DateTime.Today.Year, 3 * currQuarter - 2, 1);
			return dtFirstDay;
		}

		/// <summary>
		/// Retrieve the end date of the current quarter
		/// </summary>
		/// <returns>The end date of the current quarter</returns>
		public static DateTime EndOfCurrentQuarter()
		{
			DateTime dateToday = DateTime.Today;
			int currQuarter = (DateTime.Today.Month - 1) / 3 + 1;
			DateTime quarterLastDate = new DateTime(DateTime.Today.Year, 3 * currQuarter, 1, 23, 59, 59).AddMonths(1).AddDays(-1);
			return quarterLastDate;
		}

		/// <summary>
		/// Retrieve the start date of the last quarter
		/// </summary>
		/// <returns>The start date of the last quarter</returns>
		public static DateTime StartOfLastQuarter()
		{
			int currQuarter = (DateTime.Today.Month - 1) / 3 + 1;
			DateTime lastQuarterStartDate = new DateTime(DateTime.Today.Year, 3 * currQuarter - 2, 1).AddMonths(-3);
			return lastQuarterStartDate;
		}

		/// <summary>
		/// Retrieve the end date of the last quarter
		/// </summary>
		/// <returns>The end date of the last quarter</returns>
		public static DateTime EndOfLastQuarter()
		{
			int currQuarter = (DateTime.Today.Month - 1) / 3 + 1;
			DateTime lastQuarterEndDate = new DateTime(DateTime.Today.Year, 3 * currQuarter - 2, 1, 23, 59, 59).AddDays(-1);
			return lastQuarterEndDate;
		}

		/// <summary>
		/// Retrieve the start date of the year for the date passed
		/// </summary>
		/// <param name="valDate">The date whose start date of year is to be found</param>
		/// <returns>The start date of the year</returns>
		public static DateTime StartOfYear(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			DateTime dtFirstDate = new DateTime(inputDate.Year, 1, 1);
			return dtFirstDate;
		}

		/// <summary>
		/// Retrieve the end date of the year for the date passed
		/// </summary>
		/// <returns>The end date of the year</returns>
		public static DateTime EndOfYear(object valDate)
		{
			DateTime inputDate = DateTime.Today;
			if (!DateTime.TryParse(valDate.ToString(), out inputDate)) {
				inputDate = DateTime.Today;
			}
			DateTime dtLastDate = new DateTime(inputDate.Year, 12, 31, 23, 59, 59);
			return dtLastDate;
		}

		/// <summary>
		/// Retrieve the start date of the current year
		/// </summary>
		/// <returns>The start date of the current year</returns>
		public static DateTime StartOfCurrentYear()
		{
			DateTime dtFirstDay = new DateTime(DateTime.Today.Year, 1, 1);
			return dtFirstDay;
		}

		/// <summary>
		/// Retrieve the end date of the current year
		/// </summary>
		/// <returns>The end date of the current year</returns>
		public static DateTime EndOfCurrentYear()
		{
			DateTime dtLastDay = new DateTime(DateTime.Today.Year, 12, 31, 23, 59, 59);
			return dtLastDay;
		}

		/// <summary>
		/// Retrieve the start date of the last year
		/// </summary>
		/// <returns>The start date of the last year</returns>
		public static DateTime StartOfLastYear()
		{
			DateTime dtFirstDay = new DateTime(DateTime.Today.Year - 1, 1, 1);
			return dtFirstDay;
		}

		/// <summary>
		/// Retrieve the end date of the last year
		/// </summary>
		/// <returns>The end date of the last year</returns>
		public static DateTime EndOfLastYear()
		{
			DateTime dtFirstDay = new DateTime(DateTime.Today.Year - 1, 12, 31, 23, 59, 59);
			return dtFirstDay;
		}

		#endregion

		#region "Format Functions"

		/// <summary>
		/// Formats the arguments according to the format string
		/// </summary>
		/// <param name="val">The value to be formatted</param>
		/// <param name="formatString">The format string needed to specify the format type</param>
		/// <returns>The formatted string</returns>
		public static string Format(object val, string formatString)
		{
			decimal valDecimal = 0;
			DateTime valDate = DateTime.Today;
			if (val == null) {
				return string.Empty;
			}


			try {
				try {
					valDecimal = StringUtils.ParseDecimal(val);
					return valDecimal.ToString(formatString);
				// Ignore
				} catch {
				}

				if (DateTime.TryParse(val.ToString(), out valDate)) {
					return valDate.ToString(formatString);
				}

				return StringUtils.ParseDecimal(val).ToString(formatString);
			} catch {
				return val.ToString();
			}
		}
		#endregion

		#region "Parse Functions"
		/// <summary>
		/// Converts the object to its Decimal equivalent.
		/// </summary>
		/// <param name="val">The value to be converted</param>
		/// <returns>The converted value</returns>
		public static decimal ParseDecimal(object val)
		{
			decimal valDecimal = 0;
			try {
				valDecimal = StringUtils.ParseDecimal(val);
				return valDecimal;
			} catch (Exception ex) {
				throw new Exception("PARSEDECIMAL(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Converts the object to its integer equivalent.
		/// </summary>
		/// <param name="val">The value to be converted</param>
		/// <returns>The converted value</returns>
		public static int ParseInteger(object val)
		{
			int valDecimal = 0;
			try {
				valDecimal = Convert.ToInt32(StringUtils.ParseDecimal(val));
				return valDecimal;
			} catch (Exception ex) {
				throw new Exception("PARSEINTEGER(" + GetStr(val) + "): " + ex.Message);
			}
		}

		/// <summary>
		/// Converts the object to its date equivalent.
		/// </summary>
		/// <param name="val">The value to be converted</param>
		/// <returns>The converted value.</returns>
		public static DateTime ParseDate(object val)
		{
			DateTime valDate = DateTime.Today;
			try {
				valDate = DateTime.Parse(val.ToString());
				return valDate;
			} catch (Exception ex) {
				throw new Exception("PARSEDATE(" + GetStr(val) + "): " + ex.Message);
			}
		}
		#endregion

		#region "Geolocation Functions"

		#region "Browser Location"

        /// <summary>
		/// Gets the current browser location
		/// </summary>
		/// <returns>Returns an XML string that is of the user’s location</returns>
		public static string GetBrowserLocation()
		{
			string unit = GetDistanceUnit();

			return GetBrowserLocation(unit);
		}


        /// <summary>
		/// Clears the browser location from session memory
		/// </summary>
		public static string ClearBrowserLocation()
		{
			string value = "";

			if (System.Web.HttpContext.Current.Request.HttpMethod.ToUpperInvariant() == "POST") {
				return "";
			}

			System.Web.HttpContext.Current.Session[session_var_geo_location] = value;

			System.Web.HttpContext.Current.Session[session_var_geo_clear_browser_location] = "True";

			return value;
		}

        /// <summary>
		/// Gets the default location from session variable
		/// </summary>
        /// <returns>Returns an XML string that is of the user’s location</returns>
		public static string GetDefaultLocation()
		{
			string sessionVar = Session(session_var_geo_default_location);

			if (sessionVar == null || string.IsNullOrEmpty(sessionVar)) {
				sessionVar = BuildLocation(BaseClasses.Configuration.ApplicationSettings.Current.DefaultLatitude, BaseClasses.Configuration.ApplicationSettings.Current.DefaultLongitude);

				System.Web.HttpContext.Current.Session[session_var_geo_default_location] = sessionVar;
			}

			return sessionVar;
		}


        /// <summary>
		/// Sets the default location in session variable
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
		public static string SetDefaultLocation(object location)
		{
			string locationStr = "";

			try {
				locationStr = GetStr(location);

				System.Web.HttpContext.Current.Session[session_var_geo_default_location] = locationStr;

				return locationStr;
			} catch (Exception ex) {
				throw new Exception("SetDefaultLocation(" + location + "): " + ex.Message);
			}
		}


        /// <summary>
		/// Gets the browser location from a hidden field "isd_geo_location". This field is present on a master page.
		/// </summary>
		/// <returns>Returns an XML string with location</returns>
		public static string GetBrowserLocationForHiddenField()
		{
			string value = GetBrowserLocation("meters");

			System.Web.HttpContext.Current.Session[session_var_geo_location] = value;

			System.Web.HttpContext.Current.Session[session_var_geo_clear_browser_location] = "False";

			return value;
		}

		#endregion

		#region "Map Display"

        /// <summary>
		/// Provides a string of HTML for adding a hyperlink that gets a Google directions popup. Clicking on the map image will popup a window with Google maps.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address</param>
        /// <returns>Returns a string of HTML</returns>
		public static string GoogleDirections(object startLocation, object endLocation)
		{
			return GoogleDirections(startLocation, endLocation, -1, -1, "");
		}


        /// <summary>
		/// Provides a string of HTML for adding a generated interactive map to a web page. The interactive map can be zoomed, etc., but clicking on it does not popup anything.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address</param>
        /// <returns>Returns a string of HTML for adding a generated interactive map to a web page.</returns>
		public static string GoogleInteractiveMap(object location)
		{
			return CreateMap("interactive", location, -1, -1, -1, -1, GeoProviderType.Provider_Google, "", "");
		}

        /// <summary>
		/// Provides a string of HTML for adding a generated interactive map to a web page. 
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address</param>
        /// <returns>Returns a string of HTML for adding a generated map to a web page</returns>
		public static string GoogleMap(object location)
		{
			return CreateMap("staticimagewithpopup", location, -1, -1, -1, -1, GeoProviderType.Provider_Google, "", "");
		}


        /// <summary>
		/// Provides a string of HTML for adding a hyperlink that gets a Google directions popup. Inside the hyperlink is an image that is a static map of the endLocation.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <returns>Returns a string of HTML for adding a hyperlink that gets a Google directions popup</returns>
		public static string GoogleMapWithDirections(object startLocation, object endLocation)
		{
			return GoogleMapWithDirections(startLocation, endLocation, -1, -1, -1, -1, "", "");
		}

		#endregion

		#region "Advanced Map Display"

        /// <summary>
		/// Provides a string of HTML for adding a hyperlink that gets a Google directions popup. Clicking on the map image will popup a window with Google maps.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="popupWidth"> Width of a popup window.</param>
        /// <param name="popupHeight"> Height of a popup window.</param>
        /// <param name="googleDirectionsParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns>Returns a string of HTML for adding a hyperlink that gets a Google directions popup. Clicking on the map image will popup a window with Google maps.</returns>
		public static string GoogleDirections(object startLocation, object endLocation, object popupWidth, object popupHeight, object googleDirectionsParameters)
		{
			return CreateDirections(startLocation, endLocation, popupWidth, popupHeight, googleDirectionsParameters, "");
		}

        /// <summary>
		/// Provides a string of HTML for adding a generated interactive map to a web page.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <param name="googleDirectionsParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns> Returns a string of HTML for adding a generated interactive map to a web page.</returns>
		public static string GoogleMap(object location, object width, object height, object googleMapParameters, object googlePopupMapParameters)
		{
			return CreateMap("staticimagewithpopup", location, width, height, -1, -1, GeoProviderType.Provider_Google, googleMapParameters, googlePopupMapParameters);
		}

         /// <summary>
        /// Provides a string of HTML for adding a generated interactive map to a web page. 
        /// </summary>
        /// <param name="latitude"> A latitude value</param>
        /// <param name="longitude"> A longitude value </param>
        /// <returns>Returns a string of HTML for adding a generated map to a web page</returns>
        public static string GoogleMap(object latitude,object longitude)
        {
            String latlng = latitude.ToString() + ";" + longitude.ToString();
            return GoogleMap((Object)latlng);
        }
        /// <summary>
		/// Provides a URL for adding a generated map to a web page.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
       /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns> Returns a URL for adding a generated map to a web page.</returns>
		public static string GoogleMapURL(object location, object width, object height, object googleMapParameters)
		{
			return CreateMap("staticimageurl", location, width, height, -1, -1, GeoProviderType.Provider_Google, googleMapParameters, "");
		}

        /// <summary>
		/// Provides a string of HTML for adding a generated interactive map to a web page. The interactive map can be zoomed, etc., but clicking on it does not popup anything.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns> Returns a string of HTML for adding a generated interactive map to a web page. </returns>
		public static string GoogleInteractiveMap(object location, object width, object height, object googleMapParameters)
		{
			return CreateMap("interactive", location, width, height, -1, -1, GeoProviderType.Provider_Google, googleMapParameters, "");
		}

        /// <summary>
		/// Provides a string of HTML for adding a generated interactive map to a web page. The interactive map can be zoomed, etc., but clicking on it does not popup anything.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
       /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns> Returns a string of HTML for adding a generated interactive map to a web page. </returns>
		public static string GoogleInteractiveMapURL(object location, object width, object height, object googleMapParameters)
		{
			return CreateMap("interactiveurl", location, width, height, -1, -1, GeoProviderType.Provider_Google, googleMapParameters, "");
		}


        /// <summary>
		/// Provides HTML string for adding a popup map to a web page.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="popupWidth"> Width of a popup window.</param>
        /// <param name="popupHeight"> Height of a popup window.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <param name="googlePopupMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns>Returns HTML string for adding a popup map to a web page.</returns>
		public static string GooglePopupMapURL(object location, object width, object height, object popupWidth, object popupHeight, object googleMapParameters, object googlePopupMapParameters)
		{
			return CreateMap("popupurl", location, width, height, popupWidth, popupHeight, GeoProviderType.Provider_Google, googleMapParameters, googlePopupMapParameters);
		}


        /// <summary>
		/// Provides HTML string for adding a popup map including directions to a web page.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="width"> Integer width of map image or iframe. -1 will use the default value.</param>
        /// <param name="height"> Integer height of map image or iframe. -1 will use the default value.</param>
        /// <param name="popupWidth"> Width of a popup window.</param>
        /// <param name="popupHeight"> Height of a popup window.</param>
        /// <param name="googleMapParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <param name="googleDirectionsParameters"> These are additional direction parameters. Values can be separated using ampersand character. Please check the following url for additional parameters https://developers.google.com/maps/documentation/staticmaps/</param>
        /// <returns>Returns HTML string for adding a popup map including directions to a web page.</returns>
		public static string GoogleMapWithDirections(object startLocation, object endLocation, object width, object height, object popupWidth, object popupHeight, object googleMapParameters, object googleDirectionsParameters)
		{
			string mapHTML = CreateMap("staticimage", endLocation, width, height, popupWidth, popupHeight, GeoProviderType.Provider_Google, googleMapParameters, "");

			return CreateDirections(startLocation, endLocation, popupWidth, popupHeight, googleDirectionsParameters, mapHTML);
		}


		#endregion

		#region "Distance"

         /// <summary>
		/// Provides the decimal distance between two geographic points.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <returns>Returns the decimal distance between two geographic points.</returns>
		public static decimal DistanceBetween(object startLocation, object endLocation)
		{
			string startLocationStr = "";
			string endLocationStr = "";

			try {
				startLocationStr = GetStr(startLocation);
				endLocationStr = GetStr(endLocation);

				startLocationStr = BuildLocation(startLocationStr);
				endLocationStr = BuildLocation(endLocationStr);

				decimal latitude1 = LocationToLatitude(startLocationStr);

				if (IsInvalidOrdinate(latitude1)) {
					return latitude1;
				}

				decimal longitude1 = LocationToLongitude(startLocationStr);

				if (IsInvalidOrdinate(longitude1)) {
					return longitude1;
				}

				decimal latitude2 = LocationToLatitude(endLocationStr);

				if (IsInvalidOrdinate(latitude2)) {
					return latitude2;
				}

				decimal longitude2 = LocationToLongitude(endLocationStr);

				if (IsInvalidOrdinate(longitude2)) {
					return longitude2;
				}

				FixUpLatitude(ref latitude1);
				FixUpLatitude(ref latitude2);

				FixUpLongitude(ref longitude1);
				FixUpLongitude(ref longitude2);

				double earthRadius = GetEarthRadius();

				decimal degreesToRadians = Pi() / 180m;
				decimal radianToDegrees = 180 / Pi();

				double doubleLat1 = Convert.ToDouble(latitude1) * Convert.ToDouble(degreesToRadians);
				double doubleLon1 = Convert.ToDouble(longitude1) * Convert.ToDouble(degreesToRadians);
				double doubleLat2 = Convert.ToDouble(latitude2) * Convert.ToDouble(degreesToRadians);
				double doubleLon2 = Convert.ToDouble(longitude2) * Convert.ToDouble(degreesToRadians);

				double distance = Math.Sqrt(Math.Pow((doubleLon2 - doubleLon1) * Math.Cos((doubleLat1 + doubleLat2) / 2), 2) + Math.Pow(doubleLat2 - doubleLat1, 2)) * earthRadius;

				return Convert.ToDecimal(distance);

			// Dim distance As Double = Math.Sqrt(Math.Pow(dLat, 2) + Math.Pow(dLon, 2)) * earthRadius

			//Dim dLat As Double = (doubleLat2 - doubleLat1)
			//Dim dLon As Double = (doubleLon2 - doubleLon1)

			// uses haversine formula to calculate distance
			//Dim a As Double = Math.Pow(Math.Sin(dLat / 2.0), 2.0) + (Math.Cos(doubleLat1) * Math.Cos(doubleLat2)) * Math.Pow(Math.Sin(dLon / 2.0), 2.0)
			//Dim c As Double = 2.0 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1.0 - a))
			//Dim d As Double = earthRadius * c

			//Return Convert.ToDecimal(d)
			} catch (Exception ex) {
				throw new Exception("DistanceBetween(" + startLocation + ", " + endLocation + "): " + ex.Message);
			}
		}

        /// <summary>
		/// Provides the decimal latitude or longitude of the edges of a 2-dimensional square that circumscribes a circle of a given radius from a given origin (altitude, speed, and bearing are ignored). This is useful for quickly approximating whether a group of points are within a distance of an origin. If direction parameter is set to south or north then a decimal latitude is returned. If the direction parameter is set to east or west then a decimal longitude is returned.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="radius"> Decimal distance from the origin. </param>
        /// <param name="direction"> String direction (north, south, east, west) of the edge of the bounding box to be returned. </param>
        /// <returns>Returns the decimal latitude or longitude of the edges of a 2-dimensional square.</returns>
		public static decimal BoundingBoxEdge(object location, object radius, object direction)
		{
			string locationStr = "";
			decimal radiusDecimal = 0m;
			string directionStr = "";

			try {
				locationStr = GetStr(location);
				radiusDecimal = StringUtils.ParseDecimal(radius);
				directionStr = GetStr(direction);

				locationStr = BuildLocation(locationStr);

				if (radiusDecimal < 0m) {
					radiusDecimal = 0m;
				}

				string unit = GetDistanceUnit();
				string lowerDirection = directionStr.ToLowerInvariant();
				double earthRadius = GetEarthRadius();
				decimal latitude = LocationToLatitude(locationStr);
				decimal longitude = LocationToLongitude(locationStr);

				FixUpLatitude(ref latitude);
				FixUpLongitude(ref longitude);

				double changeInLatitude = (Convert.ToDouble(radiusDecimal) / earthRadius) * radiansToDegrees;
				double radiusOfCircleAtLatitude = earthRadius * Math.Cos(Convert.ToDouble(latitude) * degreesToRadians);
				double changeInLongitude = (Convert.ToDouble(radiusDecimal) / radiusOfCircleAtLatitude) * radiansToDegrees;

				double result = 0.0;

				if (lowerDirection.StartsWith("north")) {
					result = Convert.ToDouble(latitude) + changeInLatitude;
					if (result > 90.0) {
						result = 90.0;
					}
				} else if (lowerDirection.StartsWith("south")) {
					result = Convert.ToDouble(latitude) - changeInLatitude;
					if (result < -90.0) {
						result = -90.0;
					}
				} else if (lowerDirection.StartsWith("east")) {
					result = Convert.ToDouble(longitude) + changeInLongitude;
					if (result > 180.0) {
						result = 180.0;
					}
				} else if (lowerDirection.StartsWith("west")) {
					result = Convert.ToDouble(longitude) - changeInLongitude;
					if (result < -180.0) {
						result = -180.0;
					}
				} else {
					throw new Exception("BoundingBoxEdge has invalid direction parameter");
				}

				return Convert.ToDecimal(result);
			} catch (Exception ex) {
				throw new Exception("BoundingBoxEdge(" + location + ", " + radius + ", " + direction + "): " + ex.Message);
			}
		}


         /// <summary>
		/// Provides a boolean based on whether two geographic points are within a given radius.
		/// </summary>
        /// <param name="startLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="endLocation"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="radius"> Decimal distance from the origin. </param>
        /// <returns>Returns a boolean based on whether two geographic points are within a given radius.</returns>
		public static bool IsWithinRadius(object startLocation, object endLocation, object radius)
		{
			string startLocationStr = "";
			string endLocationStr = "";
			decimal radiusDecimal = 0m;

			try {
				startLocationStr = GetStr(startLocation);
				endLocationStr = GetStr(endLocation);
				radiusDecimal = StringUtils.ParseDecimal(radius);

				if (radiusDecimal < 0m) {
					throw new Exception("Negative radius in IsWithinRadius(" + startLocation + ", " + endLocation + ", " + radius + "): ");
				}

				startLocationStr = BuildLocation(startLocationStr);
				endLocationStr = BuildLocation(endLocationStr);

				decimal dist = DistanceBetween(startLocationStr, endLocationStr);

				if (dist < 0m) {
					return false;
				}

				return (dist <= radiusDecimal);
			} catch (Exception ex) {
				throw new Exception("IsWithinRadius(" + startLocation + ", " + endLocation + ", " + radius + "): " + ex.Message);
			}

		}
		#endregion

		#region "Conversion"

         /// <summary>
		/// Provides a boolean based on whether location string contains a specified address component
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="componentToCheck"> String specifying the component to check like latitude, longitude or address within xml string. </param>
        /// <returns>Returns a boolean based on whether location string contains a specified address component.</returns>
		public static bool IsInLocation(object location, object componentToCheck)
		{
			string locationStr = "";
			string componentToCheckStr = "";

			try {
				locationStr = GetStr(location);
				componentToCheckStr = GetStr(componentToCheck);

				locationStr = BuildLocation(locationStr);

				string componentLower = componentToCheckStr.ToLowerInvariant();
				XmlDocument xDoc = new XmlDocument();

				if (locationStr.Trim().Length > 0) {
					xDoc.LoadXml(locationStr);

					XmlNodeList name = xDoc.GetElementsByTagName(componentLower);

					if (name != null && name.Count > 0) {
						return true;
					}
				}

				return false;
			} catch (Exception ex) {
				throw new Exception("IsInLocation(" + location + ", " + componentToCheck + "): " + ex.Message);
			}

		}

        
        /// <summary>
		/// Provides the address component as a string. Reverse geocodes as necessary.
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <returns>Returns the address component as a string.</returns>
		public static string LocationToAddress(object location)
		{
			return LocationToOther(location, "address");
		}

        /// <summary>
		/// Provides the latitude component as a string. 
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <returns>Returns the latitude component as a string.</returns>
		public static decimal LocationToLatitude(object location)
		{
			return LocationToOtherNumber(location, "latitude");
		}

        /// <summary>
		/// Provides the longitude component as a string. 
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <returns>Returns the longitude component as a string.</returns>
		public static decimal LocationToLongitude(object location)
		{
			return LocationToOtherNumber(location, "longitude");
		}

         /// <summary>
		/// Provides a specified address component as a string. 
		/// </summary>
        /// <param name="location"> String containing the location in any of 3 formats: an XML location string , a latitude and longitude separated by a semicolon, or a street address.</param>
        /// <param name="componentToExtract"> String specifying the component to check like latitude, longitude or address within xml string. </param>
        /// <returns>Returns a specified address component as a string.</returns>
		public static string LocationToOther(object location, object componentToExtract)
		{
			string locationStr = "";
			string componentToExtractStr = "";

			try {
				locationStr = GetStr(location);
				componentToExtractStr = GetStr(componentToExtract);

				locationStr = BuildLocation(locationStr);

				string returnValue = "";
				string componentLower = componentToExtractStr.ToLowerInvariant();
				XmlDocument xDoc = new XmlDocument();

				if (locationStr.Trim().Length > 0) {
					xDoc.LoadXml(locationStr);

					XmlNodeList name = xDoc.GetElementsByTagName(componentLower);

					if (name != null && name.Count > 0) {
						XmlNode itm = name.Item(0);

						returnValue = HttpUtility.UrlDecode(itm.InnerXml);
					} else if (componentLower == "latitude" || componentLower == "longitude" || componentLower == "address") {
						if ((IsInLocation(locationStr, "latitude") && IsInLocation(locationStr, "longitude")) || IsInLocation(locationStr, "address")) {
							// Geocode to add missing component
							locationStr = GoogleGeocode(locationStr);
							xDoc.LoadXml(locationStr);

							name = xDoc.GetElementsByTagName(componentLower);

							if (name != null && name.Count > 0) {
								XmlNode itm = name.Item(0);

								returnValue = HttpUtility.UrlDecode(itm.InnerXml);
							} else {
								return LocationToOther(locationStr, "error");
							}
						}
					}
				}

				return returnValue;
			} catch (Exception ex) {
				throw new Exception("LocationToOther(" + location + ", " + componentToExtract + "): " + ex.Message);
			}

		}


		public static decimal LocationToOtherNumber(object location, object componentToExtract)
		{
			string locationStr = "";
			string componentToExtractStr = "";

			try {
				locationStr = GetStr(location);
				componentToExtractStr = GetStr(componentToExtract);

				locationStr = BuildLocation(locationStr);

				decimal returnValue = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				string componentLower = componentToExtractStr.ToLowerInvariant();
				string value = LocationToOther(locationStr, componentToExtractStr);

				if (componentLower.StartsWith("unit")) {
					GeoUnitType kindOfUnit = GetUnitType(value);

					switch (kindOfUnit) {
						case GeoUnitType.Unit_NauticalMiles:
							returnValue = 1m;
							break;
						case GeoUnitType.Unit_Miles:
							returnValue = 2m;
							break;
						case GeoUnitType.Unit_Yards:
							returnValue = 3m;
							break;
						case GeoUnitType.Unit_Feet:
							returnValue = 4m;
							break;
						case GeoUnitType.Unit_Kilometers:
							returnValue = 10m;
							break;
						case GeoUnitType.Unit_Meters:
							returnValue = 11m;
							break;
					}
				} else {
					try {
						if (string.IsNullOrEmpty(value.Trim()) || value.StartsWith("LOCATION_ERROR_")) {
							returnValue = BaseClasses.Web.UI.BasePage.GEO_LOCATION_CANNOT_GEOCODE;
						} else {
							returnValue = StringUtils.ParseDecimal(value.Trim());
						}
					} catch {
					}
				}

				return returnValue;
			} catch (Exception ex) {
				throw new Exception("LocationToOtherNumber(" + location + ", " + componentToExtract + "): " + ex.Message);
			}

		}

         /// <summary>
		///  Converts from degrees-minutes-seconds format into decimal degrees format. Applies to both latitude and longitude. Returns a decimal value.
		/// </summary>
        /// <param name="degrees"> Decimal value, should only be integer.</param>
        /// <param name="minutes"> Decimal value, should only be integer.</param>
        /// <param name="seconds"> Decimal value. </param>
        /// <returns>Returns decimal degrees from degrees-minutes-seconds format.</returns>
		public static decimal DegreesMinSecToDecimal(object degrees, object minutes, object seconds)
		{
			decimal degreesDecimal = 0m;
			decimal minutesDecimal = 0m;
			decimal secondsDecimal = 0m;

			try {
				degreesDecimal = StringUtils.ParseDecimal(degrees);
				minutesDecimal = StringUtils.ParseDecimal(minutes);
				secondsDecimal = StringUtils.ParseDecimal(seconds);

				decimal ordinate = degreesDecimal;

				ordinate = ordinate + minutesDecimal / 60m;
				ordinate = ordinate + secondsDecimal / 3600m;

				return ordinate;
			} catch (Exception ex) {
				throw new Exception("DegreesMinSecToDecimal(" + degrees + ", " + minutes + ", " + seconds + "): " + ex.Message);
			}

		}


         /// <summary>
		///  Converts decimal ordinate to degrees from degrees-minutes-seconds format. Works for both longitude and latitude.
		/// </summary>
        /// <param name="ordinate"> Decimal value, either a latitude or longitude.</param>
        /// <returns>Returns decimal ordinate to degrees from degrees-minutes-seconds format.</returns>
		public static decimal DecimalToDegrees(object ordinate)
		{
			return DecimalToDegreesMinSec(ordinate, "degrees");
		}

         /// <summary>
		///  Converts decimal ordinate to minutes from degrees-minutes-seconds format. Works for both longitude and latitude.
		/// </summary>
        /// <param name="ordinate"> Decimal value, either a latitude or longitude.</param>
        /// <returns>Returns decimal ordinate to minutes from degrees-minutes-seconds format..</returns>
		public static decimal DecimalToMinutes(object ordinate)
		{
			return DecimalToDegreesMinSec(ordinate, "minutes");
		}

         /// <summary>
		///  Converts decimal ordinate to seconds from degrees-minutes-seconds format. Works for both longitude and latitude.
		/// </summary>
        /// <param name="ordinate"> Decimal value, either a latitude or longitude.</param>
        /// <returns>Returns decimal ordinate to seconds from degrees-minutes-seconds format.</returns>
		public static decimal DecimalToSeconds(object ordinate)
		{
			return DecimalToDegreesMinSec(ordinate, "seconds");
		}

        /// <summary>
		///  Provides a string representation of the default distance unit: (nautical miles, miles, yards, feet, kilometers, or meters). The value initially comes from web.config but is stored in session. Note that for the hidden field with the geolocation in web pages, the unit used is always meters regardless of the distance unit.
        /// </summary>
        /// <returns>Returns  a string representation of the default distance unit: (nautical miles, miles, yards, feet, kilometers, or meters).</returns>
		public static string GetDistanceUnit()
		{
			string sessionVar = Session(session_var_geo_unit);

			if (sessionVar == null || string.IsNullOrEmpty(sessionVar)) {
				sessionVar = BaseClasses.Configuration.ApplicationSettings.Current.DefaultDistanceUnit;

				if (string.IsNullOrEmpty(sessionVar)) {
					sessionVar = "kilometers";
				}

				// Validate unit
				GeoUnitType kindOfUnit = GetUnitType(sessionVar);

				System.Web.HttpContext.Current.Session[session_var_geo_unit] = sessionVar;
			}

			return sessionVar;
		}

        /// <summary>
		///  Sets the default distance unit in session memory.
        /// </summary>
        /// <param name="unit"> String containing the new default distance unit (nautical miles, miles, yards, feet, kilometers, or meters) </param>
        /// <returns>Returns a string representation of the default distance unit: (nautical miles, miles, yards, feet, kilometers, or meters).</returns>
		public static string SetDistanceUnit(object unit)
		{
			string unitStr = "";

			try {
				unitStr = GetStr(unit);

				// Validate unit
				GeoUnitType kindOfUnit = GetUnitType(unitStr);

				System.Web.HttpContext.Current.Session[session_var_geo_unit] = unit;

				return unitStr;
			} catch (Exception ex) {
				throw new Exception("SetDistanceUnit(" + unit + "): " + ex.Message);
			}

		}


        /// <summary>
		///  Performs geocoding or reverse geocoding and returns latitude, longitude, address values in xml format as a string
        /// </summary>
        /// <param name="location"> String as a location in xml format. </param>
        /// <returns>Returns geocoding values as a string in xml format. </returns>
		public static string GoogleGeocode(object location)
		{
			string locationStr = "";

			try {
				locationStr = GetStr(location);

				locationStr = BuildLocation(locationStr);

				return Geocode(locationStr, GeoProviderType.Provider_Google);
			} catch (Exception ex) {
				throw new Exception("GoogleGeocode(" + location + "): " + ex.Message);
			}

		}

        /// <summary>
		///  Builds a location string.
        /// </summary>
        /// <param name="addressOrLatLong"> String containing address or latitude and longitude </param>
        /// <returns> Returns xml structure for address as a string. </returns>
		public static string BuildLocation(object addressOrLatLong)
		{
			string addressOrLatLongStr = "";

			try {
				addressOrLatLongStr = GetStr(addressOrLatLong);

				StringBuilder location = new StringBuilder("", 300);
				string lowerAddressOrLatLong = addressOrLatLongStr.ToLowerInvariant();
				char[] lettersArray = "abcdefghijklmnopqrstuvwxyz".ToCharArray();

				if (lowerAddressOrLatLong.Contains("<location>")) {
					return addressOrLatLongStr;
				} else if (lowerAddressOrLatLong.IndexOfAny(lettersArray) >= 0) {
					SetLocationTag(ref location, "address", addressOrLatLongStr);

					return location.ToString();
				} else {
					string[] pieces = addressOrLatLongStr.Split(';');

					if (pieces.Length >= 2) {
						try {
							decimal latitude = StringUtils.ParseDecimal(pieces[0]);
							decimal longitude = StringUtils.ParseDecimal(pieces[1]);

							SetLocationTag(ref location, "latitude", latitude.ToString());
							SetLocationTag(ref location, "longitude", longitude.ToString());
						} catch (Exception ex) {
							throw new Exception("Invalid lat/long for BuildLocation: " + ex.Message);
						}
					}

					return location.ToString();
				}
			} catch (Exception ex) {
				throw new Exception("BuildLocation(" + addressOrLatLong + "): " + ex.Message);
			}

		}

        /// <summary>
		///  Builds a location string.
        /// </summary>
        /// <param name="street"> String containing street </param>
        /// <param name="city"> String containing city </param>
        /// <param name="region"> String containing region </param>
        /// <param name="postalCode"> String containing postalCode </param>
        /// <param name="country"> String containing country </param>
        /// <returns> Returns xml structure for address as a string. </returns>
		public static string BuildLocation(object street, object city, object region, object postalCode, object country)
		{
			string streetStr = "";
			string cityStr = "";
			string regionStr = "";
			string postalCodeStr = "";
			string countryStr = "";

			try {
				streetStr = GetStr(street);
				cityStr = GetStr(city);
				regionStr = GetStr(region);
				postalCodeStr = GetStr(postalCode);
				countryStr = GetStr(country);

				StringBuilder location = new StringBuilder("", 300);
				StringBuilder str = new StringBuilder("", 300);

				if (!string.IsNullOrEmpty(streetStr)) {
					if (str.Length > 0) {
						str.Append(" ");
					}
					str.Append(streetStr);
				}

				if (!string.IsNullOrEmpty(cityStr)) {
					if (str.Length > 0) {
						str.Append(", ");
					}
					str.Append(cityStr);
				}

				if (!string.IsNullOrEmpty(regionStr)) {
					if (str.Length > 0) {
						str.Append(", ");
					}
					str.Append(regionStr);
				}

				if (!string.IsNullOrEmpty(postalCodeStr)) {
					if (str.Length > 0) {
						str.Append(" ");
					}
					str.Append(postalCodeStr);
				}

				if (!string.IsNullOrEmpty(countryStr)) {
					if (str.Length > 0) {
						str.Append(", ");
					}
					str.Append(countryStr);
				}

				SetLocationTag(ref location, "address", str.ToString());

				return str.ToString();
			} catch (Exception ex) {
				throw new Exception("BuildLocation(" + street + ", " + city + ", " + region + ", " + postalCode + ", " + country + "): " + ex.Message);
			}

		}

         /// <summary>
		///  Builds a location string.
        /// </summary>
        /// <param name="latitude"> String containing latitude </param>
        /// <param name="longitude"> String containing longitude </param>
        /// <returns> Returns xml structure for address as a string. </returns>
		public static string BuildLocation(object latitude, object longitude)
		{
			return BuildLocation(latitude, longitude, BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE, BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE, BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE, BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE, BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE);
		}

        /// <summary>
		///  Builds a location string.
        /// </summary>
        /// <param name="latitude"> String containing latitude </param>
        /// <param name="longitude"> String containing longitude </param>
        /// <param name="altitude"> String containing altitude </param>
        /// <param name="speed"> String containing speed </param>
        /// <param name="heading"> String containing heading </param>
        /// <param name="accuracy"> String containing accuracy </param>
        /// <param name="altitudeAccuracy"> String containing altitudeAccuracy </param>
        /// <returns> Returns xml structure for address as a string. </returns>
		public static string BuildLocation(object latitude, object longitude, object altitude, object speed, object heading, object accuracy, object altitudeAccuracy)
		{
			decimal latitudeDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal longitudeDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal altitudeDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal speedDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal headingDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal accuracyDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal altitudeAccuracyDecimal = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;

			try {
				latitudeDecimal = StringUtils.ParseDecimal(latitude);
				longitudeDecimal = StringUtils.ParseDecimal(longitude);
				altitudeDecimal = StringUtils.ParseDecimal(altitude);
				speedDecimal = StringUtils.ParseDecimal(speed);
				headingDecimal = StringUtils.ParseDecimal(heading);
				accuracyDecimal = StringUtils.ParseDecimal(accuracy);
				altitudeAccuracyDecimal = StringUtils.ParseDecimal(altitudeAccuracy);

				string unit = GetDistanceUnit();
				StringBuilder location = new StringBuilder("", 300);

				if (!IsInvalidOrdinate(latitudeDecimal)) {
					SetLocationTag(ref location, "latitude", latitudeDecimal.ToString());
				}

				if (!IsInvalidOrdinate(longitudeDecimal)) {
					SetLocationTag(ref location, "longitude", longitudeDecimal.ToString());
				}

				if (!IsInvalidOrdinate(altitudeDecimal)) {
					SetLocationTag(ref location, "altitude", altitudeDecimal.ToString());
				}

				if (!IsInvalidOrdinate(speedDecimal)) {
					SetLocationTag(ref location, "speed", speedDecimal.ToString());
				}

				if (!IsInvalidOrdinate(headingDecimal)) {
					SetLocationTag(ref location, "heading", headingDecimal.ToString());
				}

				if (!IsInvalidOrdinate(accuracyDecimal)) {
					SetLocationTag(ref location, "accuracy", accuracyDecimal.ToString());
				}

				if (!IsInvalidOrdinate(altitudeAccuracyDecimal)) {
					SetLocationTag(ref location, "altitudeaccuracy", altitudeAccuracyDecimal.ToString());
					if (location.ToString().Length > 0 && !string.IsNullOrEmpty(unit)) {
						GeoUnitType kindOfUnit = GetUnitType(unit);
						SetLocationTag(ref location, "unit", GetUnitString(kindOfUnit));
					}
				}

				return location.ToString();
			} catch (Exception ex) {
				throw new Exception("BuildLocation(" + latitude + ", " + longitude + ", " + altitude + ", " + speed + ", " + heading + ", " + accuracy + ", " + altitudeAccuracy + "): " + ex.Message);
			}

		}


		#endregion

		#endregion

		#region "Session, Cookie, URL and other Functions"

        /// <summary>
        /// Return the value of the variable from the session.
        /// </summary>
        /// <param name="toBeEncoded">URL to be encoded</param>
        /// <returns>Encoded URL.</returns>
        public static string UrlEncode(string toBeEncoded)
        {
            if(ApplicationSettings.Current.URLParametersEncrypted) toBeEncoded = Encrypt(toBeEncoded);
            return System.Web.HttpUtility.UrlEncode(toBeEncoded);
        }

		/// <summary>
		/// Return the value of the variable from the session.
		/// </summary>
		/// <param name="var">The name of the session variable</param>
		/// <returns>The session variable value.</returns>
		public static string Session(string var)
		{
			if (var == null || System.Web.HttpContext.Current.Session[var] == null) {
				return string.Empty;
			}
			return System.Web.HttpContext.Current.Session[var].ToString();
		}

		/// <summary>
		/// Return the value of the variable from the cookie.
		/// </summary>
		/// <param name="var">The name of the cookie variable</param>
		/// <returns>The cookie variable value.</returns>
		public static string Cookie(string var)
		{
			if (var == null || System.Web.HttpContext.Current.Request.Cookies[var] == null) {
				return string.Empty;
			}
			return System.Web.HttpContext.Current.Request.Cookies[var].Value;
		}

		/// <summary>
		/// Return the value of the variable from the cache.
		/// </summary>
		/// <param name="var">The name of the cache variable</param>
		/// <returns>The cache variable value.</returns>
		public static string Cache(string var)
		{
			if (var == null || System.Web.HttpContext.Current.Cache[var] == null) {
				return string.Empty;
			}
			return System.Web.HttpContext.Current.Cache[var].ToString();
		}

		/// <summary>
		/// Return the value of the URL parameter passed to the current page.
		/// </summary>
		/// <param name="var">The name of the URL variable</param>
		/// <returns>The URL variable value.</returns>
		public static string URL(string var)
		{
			string val = String.Empty;
			if (var == null) {
				return string.Empty;
			}

			val = System.Web.HttpContext.Current.Request.QueryString[var];
			if(string.IsNullOrEmpty(val)) return "";
			// It is possible that the URL value is encrypted - so try to
			// decrypt. If we do not get an exception, then we know it was
			// encrypted - otherwise if we get an exception, then the value was
			// not encrypted in the first place, so return the actual value.
			try {
				val = Decrypt(val);
			// Ignore exception and return original value
			} catch {
                if(ApplicationSettings.Current.URLParametersEncrypted) return "";
			}


			if (KeyValue.IsXmlKey(val)) {
				// URL values are typically passed as XML structures to handle composite keys.
				// If XML, then we will see if there is one element in the XML. If there is only one
				// element, we will return that element. Otherwise we will return the full XML.
				KeyValue key = KeyValue.XmlToKey(val);
				if (key.Count == 1) {
					val = key.ColumnValue(0);
				}
			}

			return val;
		}

		/// <summary>
		/// Return the value of the URL parameter passed to the current page.
		/// If the URL is a Key Value pair, return the column value of the XML structure
		/// </summary>
		/// <param name="var">The name of the URL variable</param>
		/// <returns>The URL variable value.</returns>
		public static string URL(string var, string column)
		{
			string val = String.Empty;
			if (var == null) {
				return string.Empty;
			}

			val = System.Web.HttpContext.Current.Request.QueryString[var];
           if(string.IsNullOrEmpty(val)) return "";
			// It is possible that the URL value is encrypted - so try to
			// decrypt. If we do not get an exception, then we know it was
			// encrypted - otherwise if we get an exception, then the value was
			// not encrypted in the first place, so return the actual value.
			try {
				val = Decrypt(val);
			// Ignore exception and return original value
			} catch {
                if(ApplicationSettings.Current.URLParametersEncrypted) return "";
			}

			if (KeyValue.IsXmlKey(val)) {
				// URL values are typically passed as XML structures to handle composite keys.
				// If XML, then we will see if retrieve the value for the column name passed in
				// to the function.
				KeyValue key = KeyValue.XmlToKey(val);
				val = key.ColumnValueByName(column);
			}

			return val;
		}

		/// <summary>
		/// Return the value of the resource key. Only the application resources
		/// are returned by this function. Resources in the BaseClasses.resx file
		/// are not accessible through this function.
		/// </summary>
		/// <param name="var">The name of the resource key</param>
		/// <returns>The resource value.</returns>
		public static string Resource(string var)
		{
			if (var == null) {
				return string.Empty;
			}
			try {
				string appname = BaseClasses.Configuration.ApplicationSettings.Current.GetAppSetting(BaseClasses.Configuration.ApplicationSettings.ConfigurationKey.ApplicationName);
				object resObj = System.Web.HttpContext.GetGlobalResourceObject(appname, var);
				if (resObj != null) {
					return resObj.ToString();
				}
			// If we cannot find the resource, simply return the variable that was passed-in.
			} catch {
			}
			return var;
		}

		/// <summary>
		/// Return the encrypted value of the string passed in.
		/// </summary>
		/// <param name="str">The string to encrypt</param>
		/// <returns>The encrypted value of the string.</returns>
		public static string Encrypt(string str)
		{
			if (str == null) {
				return string.Empty;
			}
			Crypto CheckCrypto = new Crypto();
			return CheckCrypto.Encrypt(str);
		}

		/// <summary>
		/// Return the decrypted value of the string passed in.
		/// </summary>
		/// <param name="str">The string to decrypt</param>
		/// <returns>The decrypted value of the string.</returns>
		public static string Decrypt(string str)
		{
			if (str == null) {
				return string.Empty;
			}
			Crypto CheckCrypto = new Crypto();
			return CheckCrypto.Decrypt(str);
		}

		/// <summary>
		/// Return the encrypted value of the string passed in.
		/// </summary>
		/// <param name="str">The string to encrypt</param>
		/// <returns>The encrypted value of the string.</returns>
		public static string EncryptData(string str)
		{
			if (str == null) {
				return string.Empty;
			}
			Crypto CheckCrypto = new Crypto();
			return CheckCrypto.Encrypt(str, false);
		}

		/// <summary>
		/// Return the decrypted value of the string passed in.
		/// </summary>
		/// <param name="str">The string to decrypt</param>
		/// <returns>The decrypted value of the string.</returns>
		public static string DecryptData(string str)
		{
			if (str == null) {
				return string.Empty;
			}
			Crypto CheckCrypto = new Crypto();
			string result = null;
			try {
				result = CheckCrypto.Decrypt(str, false);
			} catch {
			}
			try {
				if (result == str || result == null || string.IsNullOrEmpty(result)) {
					result = CheckCrypto.Decrypt(str, true);
				}
			} catch {
				result = str;
			}
			return result;
		}

		/// <summary>
		/// Return the currently logged in user id
		/// </summary>
		/// <returns>The user id of the currently logged in user.</returns>
		public static string UserId()
		{
			return BaseClasses.Utils.SecurityControls.GetCurrentUserID();
		}

		/// <summary>
		/// Return the currently logged in user ma,e
		/// </summary>
		/// <returns>The user name of the currently logged in user.</returns>
		public static string UserName()
		{
			return BaseClasses.Utils.SecurityControls.GetCurrentUserName();
		}

		/// <summary>
		/// Return the currently logged in user's roles. The roles are returned
		/// as a string array, so you can do something like 
		/// = If("Engineering" in Roles(), "Good", "Bad")
		/// </summary>
		/// <returns>The roles of the currently logged in user.</returns>
		public static string[] Roles {
			get {
				string rStr = BaseClasses.Utils.SecurityControls.GetCurrentUserRoles();
				if ((rStr == null)) {
					return new string[-1 + 1];
				}
				return rStr.Split(';');
			}
		}

		/// <summary>
		/// Return the value of the column from the currently logged in user's database 
		/// record. Allows access to any fields on the user record (e.g., email address)
		/// by simply doing something like UserRecord("EmailAddress")
		/// NOTE: This function ONLY applies to Database Role security. Does NOT
		/// apply to Active Directory, SharePoint, Windows Authentication or .NET Membership Roles
		/// </summary>
		/// <returns>The user record of the currently logged in user.</returns>
		public static object UserRecord(string colName)
		{
			IUserIdentityRecord rec = null;
			rec = BaseClasses.Utils.SecurityControls.GetUserRecord("");
			if (rec == null) {
				return string.Empty;
			}

			BaseColumn col = null;
			col = rec.TableAccess.TableDefinition.ColumnList.GetByCodeName(colName);
			if (col == null) {
				return string.Empty;
			}

			return rec.GetValue(col).Value;
		}
		#endregion

		#region "Database Access Functions"
		/// <summary>
		/// Return the value of the column from the database record specified by the key.  The
		/// key can be either an XML KeyValue structure or just a string that is the Id of the record.
		/// Only works for tables with a primary key or a virtual primary key.
		/// </summary>
		/// <returns>The value for the given field as an Object.</returns>
		public static object GetColumnValue(string tableName, decimal key, string fieldName)
		{
			return GetColumnValue(tableName, key.ToString(), fieldName);
		}


		/// <summary>
		/// Return the value of the column from the database record specified by the key.  The
		/// key can be either an XML KeyValue structure or just a string that is the Id of the record.
		/// Only works for tables with a primary key or a virtual primary key.
		/// </summary>
		/// <returns>The value for the given field as an Object.</returns>
		public static object GetColumnValue(string tableName, string key, string fieldName)
		{
			// Find a specific value from the database for the given record.
			PrimaryKeyTable bt = null;
			bt = (PrimaryKeyTable)DatabaseObjects.GetTableObject(tableName);
			if (bt == null) {
				throw new Exception("GETCOLUMNVALUE(" + tableName + ", " + key + ", " + fieldName + "): " + Resource("Err:NoRecRetrieved"));
			}

			IRecord rec = null;
			try {
				// Always start a transaction since we do not know if the calling function did.
				rec = bt.GetRecordData(key, false);
			} catch {
			}
			if (rec == null) {
				throw new Exception("GETCOLUMNVALUE(" + tableName + ", " + key + ", " + fieldName + "): " + Resource("Err:NoRecRetrieved"));
			}

			BaseColumn col = bt.TableDefinition.ColumnList.GetByCodeName(fieldName);
			if (col == null) {
				throw new Exception("GETCOLUMNVALUE(" + tableName + ", " + key + ", " + fieldName + "): " + Resource("Err:NoRecRetrieved"));
			}
            col.IsApplyDisplayAs = false;
			// The value can be null.  In this case, return an empty string since
			// that is an acceptable value.
			ColumnValue fieldData = rec.GetValue(col);
			if (fieldData == null) {
				return string.Empty;
			}

			return fieldData.Value;
		}

		/// <summary>
		/// Return an array of values from the database.  The values returned are DISTINCT values.
		/// For example, GetColumnValues("Employees", "City") will return a list of all Cities
		/// from the Employees table. There will be no duplicates in the list.
		/// You can use the IN operator to compare the values.  You can also use the resulting array to display
		/// such as String.Join(", ", GetColumnValues("Employees", "City")
		/// to display: New York, Chicago, Los Angeles, San Francisco
		/// </summary>
		/// <returns>An array of values for the given field as an Object.</returns>
		public static string[] GetColumnValues(string tableName, string fieldName)
		{
			return GetColumnValues(tableName, fieldName, string.Empty);
		}

		/// <summary>
		/// Return an array of values from the database.  The values returned are DISTINCT values.
		/// For example, GetColumnValues("Employees", "City") will return a list of all Cities
		/// from the Employees table. There will be no duplicates in the list.
		/// This function adds a Where Clause.  So you can say something like "Country = 'USA'" and in this
		/// case only cities in the US will be returned.
		/// You can use the IN operator to compare the values.  You can also use the resulting array to display
		/// such as String.Join(", ", GetColumnValues("Employees", "City", "Country = 'USA'")
		/// to display: New York, Chicago, Los Angeles, San Francisco
		/// </summary>
		/// <returns>An array of values for the given field as an Object.</returns>
		public static string[] GetColumnValues(string tableName, string fieldName, string whereStr)
		{
			// Find the 
			PrimaryKeyTable bt = null;
			bt = (PrimaryKeyTable)DatabaseObjects.GetTableObject(tableName);
			if (bt == null) {
				throw new Exception("GETCOLUMNVALUES(" + tableName + ", " + fieldName + ", " + whereStr + "): " + Resource("Err:NoRecRetrieved"));
			}

			BaseColumn col = bt.TableDefinition.ColumnList.GetByCodeName(fieldName);
			if (col == null) {
				throw new Exception("GETCOLUMNVALUES(" + tableName + ", " + fieldName + ", " + whereStr + "): " + Resource("Err:NoRecRetrieved"));
			}
            col.IsApplyDisplayAs = false;
			string[] values = null;

			try {
				// Always start a transaction since we do not know if the calling function did.
				SqlBuilderColumnSelection sqlCol = new SqlBuilderColumnSelection(false, true);
				sqlCol.AddColumn(col);

				WhereClause wc = new WhereClause();
				if ((whereStr != null) && whereStr.Trim().Length > 0) {
					wc.iAND(whereStr);
				}
				BaseClasses.Data.BaseFilter @join = null;
				values = bt.GetColumnValues(sqlCol, @join, wc.GetFilter(), null, null, BaseTable.MIN_PAGE_NUMBER, BaseTable.MAX_BATCH_SIZE);
			} catch {
			}

			// The value can be null.  In this case, return an empty array since
			// that is an acceptable value.
			if (values == null) {
				values = new string[-1 + 1];
			}


			return values;
		}
		#endregion

		#region "Private Convenience Functions"

		private const double degreesToRadians = (Math.PI / 180.0);

		private const double radiansToDegrees = (180.0 / Math.PI);
		private const string session_var_geo_location = "isd_geo_location";
		private const string session_var_geo_default_location = "session_var_geo_default_location";
		private const string session_var_geo_unit = "isd_geo_unit";

		private const string session_var_geo_clear_browser_location = "isd_geo_clear_browser_location";
		private const string session_var_geo_previous_address_1 = "isd_geo_previous_address_1";
		private const string session_var_geo_previous_latitude_1 = "isd_geo_previous_latitude_1";

		private const string session_var_geo_previous_longitude_1 = "isd_geo_previous_longitude_1";
		private const string session_var_geo_previous_address_2 = "isd_geo_previous_address_2";
		private const string session_var_geo_previous_latitude_2 = "isd_geo_previous_latitude_2";

		private const string session_var_geo_previous_longitude_2 = "isd_geo_previous_longitude_2";
		private enum GeoUnitType
		{
			Unit_Feet,
			Unit_Yards,
			Unit_Miles,
			Unit_NauticalMiles,
			Unit_Meters,
			Unit_Kilometers
		}

		public enum GeoProviderType
		{
			Provider_Google
		}

		private static GeoUnitType GetUnitType(string unit)
		{
			string unitLower = unit.ToLowerInvariant();

			if (unitLower.StartsWith("nautical") || unitLower.StartsWith("nm")) {
				return GeoUnitType.Unit_NauticalMiles;
			} else if (unitLower.StartsWith("mi")) {
				return GeoUnitType.Unit_Miles;
			} else if (unitLower.StartsWith("feet") || unitLower.StartsWith("foot") || unitLower.StartsWith("ft")) {
				return GeoUnitType.Unit_Feet;
			} else if (unitLower.StartsWith("yard") || unitLower.StartsWith("yd")) {
				return GeoUnitType.Unit_Yards;
			} else if (unitLower.StartsWith("kilometer") || unitLower.StartsWith("km") || unitLower.Length == 0) {
				return GeoUnitType.Unit_Kilometers;
			} else if (unitLower.StartsWith("meter") || unitLower.StartsWith("m")) {
				return GeoUnitType.Unit_Meters;
			} else {
				throw new Exception("GetUnit has invalid unit parameter");
			}
		}


		private static string GetUnitString(GeoUnitType unit)
		{
			switch (unit) {
				case GeoUnitType.Unit_Feet:
					return "feet";
				case GeoUnitType.Unit_Yards:
					return "yards";
				case GeoUnitType.Unit_Miles:
					return "miles";
				case GeoUnitType.Unit_NauticalMiles:
					return "nautical miles";
				case GeoUnitType.Unit_Meters:
					return "meters";
				case GeoUnitType.Unit_Kilometers:
					return "kilometers";
			}

			return "";
		}


		// Assumes that value is in meters
		private static void ConvertToUnit(ref decimal value, string unit)
		{
			const decimal metersPerKilometer = 1000m;
			const decimal metersPerNauticalMile = 1852m;
			const decimal kilometersPerMile = 1.609344m;
			const decimal feetPerMile = 5280m;
			const decimal feetPerYard = 3m;

			if (IsInvalidOrdinate(value)) {
				return;
			}

			switch (GetUnitType(unit)) {
				case GeoUnitType.Unit_NauticalMiles:
					value = value / metersPerNauticalMile;
					break;
				case GeoUnitType.Unit_Miles:
					value = value / kilometersPerMile / metersPerKilometer;
					break;
				case GeoUnitType.Unit_Yards:
					value = value / kilometersPerMile / metersPerKilometer * feetPerMile / feetPerYard;
					break;
				case GeoUnitType.Unit_Feet:
					value = value / kilometersPerMile / metersPerKilometer * feetPerMile;
					break;
				case GeoUnitType.Unit_Kilometers:
					value = value / metersPerKilometer;
					break;
				case GeoUnitType.Unit_Meters:
					break;
				default:

					throw new Exception("unit parameter is invalid");
			}
		}


		private static double GetEarthRadius()
		{
			string unit = GetDistanceUnit();
			decimal radius = 3959m * 1.609344m * 1000m;

			ConvertToUnit(ref radius, unit);

			return Convert.ToDouble(radius);
		}


		private static decimal DecimalToDegreesMinSec(object ordinate, object component)
		{
			decimal ordinateDecimal = 0m;
			string componentStr = "";

			try {
				ordinateDecimal = StringUtils.ParseDecimal(ordinate);
				componentStr = GetStr(component);

				string componentLower = componentStr.ToLowerInvariant();
				decimal degrees = Math.Truncate(ordinateDecimal);
				decimal remainder = (ordinateDecimal - degrees) * 60m;
				decimal minutes = Math.Truncate(remainder);
				decimal seconds = (remainder - minutes) * 60m;

				if (componentLower.StartsWith("degree")) {
					return degrees;
				} else if (componentLower.StartsWith("minute")) {
					return minutes;
				} else if (componentLower.StartsWith("second")) {
					return seconds;
				}

				throw new Exception("DecimalToDegreesMinSec has invalid component parameter");
			} catch (Exception ex) {
				throw new Exception("DecimalToDegreesMinSec(" + ordinate + ", " + component + "): " + ex.Message);
			}

		}


		public static bool IsInvalidOrdinate(decimal ordinate)
		{
			if (ordinate <= BaseClasses.Web.UI.BasePage.GEO_LOCATION_ERRORS) {
				return true;
			} else {
				return false;
			}
		}


		private static void FixUpLatitude(ref decimal latitude)
		{
			if (IsInvalidOrdinate(latitude)) {
				return;
			}

			if (latitude > 90m) {
				latitude = 90m;
			} else if (latitude < -90m) {
				latitude = -90m;
			}
		}


		private static void FixUpLongitude(ref decimal longitude)
		{
			if (IsInvalidOrdinate(longitude)) {
				return;
			}

			if (longitude > 180m) {
				longitude = 180m;
			} else if (longitude < -180m) {
				longitude = -180m;
			}
		}

        private static bool ValidateGeoLocationVariable(string value)
        {
	        if (string.IsNullOrEmpty(value))
		        return true;
	        XmlDocument doc = new XmlDocument();

	        try {
		        doc.LoadXml(value);
		        XmlElement root = (XmlElement)doc.FirstChild;
		        if (root == null)
			        return false;
		        if (!string.Equals(root.Name, "location", StringComparison.InvariantCultureIgnoreCase)) {
			        return false;
		        }


		        if (root.ChildNodes == null || root.ChildNodes.Count == 0) {
			        if (string.IsNullOrEmpty(root.InnerXml))
				        return true;
			        if (System.Text.RegularExpressions.Regex.IsMatch(root.InnerXml, "[^0-9a-zA-Z\\.,-_]")) {
				        return false;
			        }
		        } else {
			        foreach (XmlNode node in root.ChildNodes) {
				        if (node == null || string.IsNullOrEmpty(node.Name))
					        return false;
				        switch (node.Name.ToLowerInvariant()) {
					        case "latitude":
					        case "longitude":
					        case "altitude":
					        case "accuracy":
					        case "altitudeaccuracy":
					        case "speed":
					        case "heading":
					        case "unit":
					        case "donotretrievebrowserlocation":
					        case "error":
						        if (string.IsNullOrEmpty(node.InnerXml))
							        continue;
						        if (System.Text.RegularExpressions.Regex.IsMatch(node.InnerXml, "[^0-9a-zA-Z\\.,-_]")) {
							        return false;
						        }
						        break;
					        default:
						        return false;
				        }
			        }
		        }
	        } catch (Exception ex) {
		        return false;
	        }
	        return true;
        }



		public static string GetBrowserLocation(object unit)
		{
			try {
				string unitStr = "kilometers";

				unitStr = GetStr(unit);

				if (string.IsNullOrEmpty(unitStr)) {
					unitStr = "kilometers";
				}

				if ((System.Web.HttpContext.Current.Session[session_var_geo_clear_browser_location] == null) || 
            ((System.Web.HttpContext.Current.Session[session_var_geo_clear_browser_location] != null) && 
            (Convert.ToString(System.Web.HttpContext.Current.Session[session_var_geo_clear_browser_location]) != "True"))) {
					BaseClasses.Web.UI.BasePage.SetGeolocation();
				}

				string sessionVar = Session(session_var_geo_location);

				if ((sessionVar == null) || !ValidateGeoLocationVariable(sessionVar)) {
					sessionVar = "";
				}

				string address = "";
				string embeddedUnit = "meters";
				decimal latitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				decimal longitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				bool hasLocation = false;
				string errorMsg = "";
				string donotretrievebrowserlocation = "";
				bool forceLocationBuild = false;

				if (IsInLocation(sessionVar, "address")) {
					address = LocationToAddress(sessionVar);
					hasLocation = true;
				}

				if (IsInLocation(sessionVar, "latitude") && IsInLocation(sessionVar, "longitude")) {
					latitude = LocationToLatitude(sessionVar);
					longitude = LocationToLongitude(sessionVar);
					hasLocation = true;
				}

				if (!hasLocation) {
					if (IsInLocation(sessionVar, "error")) {
						errorMsg = LocationToOther(sessionVar, "error");
					}

					if (IsInLocation(sessionVar, "donotretrievebrowserlocation")) {
						donotretrievebrowserlocation = LocationToOther(sessionVar, "donotretrievebrowserlocation");
					}

					sessionVar = BuildLocation(GetDefaultLocation());

					StringBuilder locationTemp = new StringBuilder(sessionVar, 300);

					latitude = LocationToLatitude(sessionVar);
					longitude = LocationToLongitude(sessionVar);

					if (!IsInvalidOrdinate(latitude) && !IsInvalidOrdinate(longitude)) {
						SetLocationTag(ref locationTemp, "latitude", LocationToLatitude(sessionVar).ToString());
						SetLocationTag(ref locationTemp, "longitude", LocationToLongitude(sessionVar).ToString());
					}

					sessionVar = locationTemp.ToString();

					if (!string.IsNullOrEmpty(errorMsg)) {
						StringBuilder location = new StringBuilder(sessionVar, 300);

						SetLocationTag(ref location, "error", errorMsg);

						sessionVar = location.ToString();
					}

					if (!string.IsNullOrEmpty(donotretrievebrowserlocation)) {
						StringBuilder location = new StringBuilder(sessionVar, 300);

						SetLocationTag(ref location, "donotretrievebrowserlocation", donotretrievebrowserlocation);

						sessionVar = location.ToString();
					}

					forceLocationBuild = true;
				}

				if (IsInLocation(sessionVar, "unit")) {
					embeddedUnit = LocationToOther(sessionVar, "unit");
				}

				if (forceLocationBuild || (GetUnitType(unitStr) != GeoUnitType.Unit_Meters && GetUnitType(embeddedUnit) == GeoUnitType.Unit_Meters)) {
					// meters
					decimal altitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
					decimal speed = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
					decimal heading = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
					decimal accuracy = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
					decimal altitudeAccuracy = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;

					if (IsInLocation(sessionVar, "latitude")) {
						latitude = LocationToLatitude(sessionVar);
					}

					if (IsInLocation(sessionVar, "longitude")) {
						longitude = LocationToLongitude(sessionVar);
					}

					if (IsInLocation(sessionVar, "altitude")) {
						altitude = LocationToOtherNumber(sessionVar, "altitude");
					}

					if (IsInLocation(sessionVar, "speed")) {
						speed = LocationToOtherNumber(sessionVar, "speed");
					}

					if (IsInLocation(sessionVar, "heading")) {
						heading = LocationToOtherNumber(sessionVar, "heading");
					}

					if (IsInLocation(sessionVar, "accuracy")) {
						accuracy = LocationToOtherNumber(sessionVar, "accuracy");
					}

					if (IsInLocation(sessionVar, "altitudeaccuracy")) {
						altitudeAccuracy = LocationToOtherNumber(sessionVar, "altitudeaccuracy");
					}

					if (IsInLocation(sessionVar, "error")) {
						errorMsg = LocationToOther(sessionVar, "error");
					}

					if (IsInLocation(sessionVar, "donotretrievebrowserlocation")) {
						donotretrievebrowserlocation = LocationToOther(sessionVar, "donotretrievebrowserlocation");
					}

					ConvertToUnit(ref altitude, unitStr);
					ConvertToUnit(ref speed, unitStr);
					ConvertToUnit(ref accuracy, unitStr);
					ConvertToUnit(ref altitudeAccuracy, unitStr);

					sessionVar = BuildLocation(latitude, longitude, altitude, speed, heading, accuracy, altitudeAccuracy);

					StringBuilder location = new StringBuilder(sessionVar, 300);

					SetLocationTag(ref location, "unit", unitStr);

					if (!string.IsNullOrEmpty(address)) {
						SetLocationTag(ref location, "address", address);
					}

					if (!string.IsNullOrEmpty(errorMsg)) {
						SetLocationTag(ref location, "error", errorMsg);
					}

					if (!forceLocationBuild && !string.IsNullOrEmpty(donotretrievebrowserlocation)) {
						SetLocationTag(ref location, "donotretrievebrowserlocation", donotretrievebrowserlocation);
					}

					sessionVar = location.ToString();
				}

				if (!IsInLocation(sessionVar, "unit")) {
					StringBuilder locationTemp = new StringBuilder(sessionVar, 300);

					SetLocationTag(ref locationTemp, "unit", unitStr);

					sessionVar = locationTemp.ToString();
				}

				return sessionVar;
			} catch (Exception ex) {
				throw new Exception("GETBROWSERLOCATION(" + unit + "): " + ex.Message);
			}
		}


		private static void SetLocationTag(ref StringBuilder location, string tagName, string tagValue)
		{
			string currentLoc = location.ToString().Trim();
			string locationEndTag = "</location>";
			int locationEndTagStart = currentLoc.IndexOf(locationEndTag);

			if (locationEndTagStart >= 0) {
				location.Remove(locationEndTagStart, location.ToString().Length - locationEndTagStart);
			} else {
				// If there are no tags, then assume its a street address
				if (currentLoc.Length > 0 && !currentLoc.Contains("<")) {
					location = new StringBuilder("", 300);

					location.Append("<address>" + currentLoc + "</address>" + Environment.NewLine);
				}
				location.Append("<location>" + Environment.NewLine);
			}

			// First remove existing attribute
			int startTagStart = currentLoc.IndexOf("<" + tagName + ">");
			int endTagStart = currentLoc.IndexOf("</" + tagName + ">");

			if (startTagStart >= 0 && endTagStart >= 0) {
				location.Remove(startTagStart, endTagStart + ("</" + tagName + ">").Length - startTagStart);
			}

			if (tagName.ToLowerInvariant() == "address") {
				location.AppendFormat("<{0}>{1}</{2}>{3}", tagName, HttpUtility.UrlEncode(tagValue), tagName, Environment.NewLine);
			} else {
				location.AppendFormat("<{0}>{1}</{2}>{3}", tagName, tagValue, tagName, Environment.NewLine);
			}

			location.Append("</location>" + Environment.NewLine);
		}


		private static void SwapGeocodeCacheItems()
		{
			string previousAddress1 = Session(session_var_geo_previous_address_1);
			string previousLatitude1 = Session(session_var_geo_previous_latitude_1);
			string previousLongitude1 = Session(session_var_geo_previous_longitude_1);

			string previousAddress2 = Session(session_var_geo_previous_address_2);
			string previousLatitude2 = Session(session_var_geo_previous_latitude_2);
			string previousLongitude2 = Session(session_var_geo_previous_longitude_2);

			System.Web.HttpContext.Current.Session[session_var_geo_previous_address_1] = previousAddress2;
			System.Web.HttpContext.Current.Session[session_var_geo_previous_latitude_1] = previousLatitude2;
			System.Web.HttpContext.Current.Session[session_var_geo_previous_longitude_1] = previousLongitude2;

			System.Web.HttpContext.Current.Session[session_var_geo_previous_address_2] = previousAddress1;
			System.Web.HttpContext.Current.Session[session_var_geo_previous_latitude_2] = previousLatitude1;
			System.Web.HttpContext.Current.Session[session_var_geo_previous_longitude_2] = previousLongitude1;
		}


		private static string Geocode(string location, GeoProviderType provider)
		{
			string googleClientID = GetGoogleClientID();
			string googleSignature = GetGoogleSignature();

			if (location.Contains("<error>LOCATION_ERROR_")) {
				return location;
			}

			string streetAddress = "";
			decimal latitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal longitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;

			// Check if it exists first since LocationToLatitude may call Geocode
			if (IsInLocation(location, "latitude")) {
				latitude = LocationToLatitude(location);
			}

			if (IsInLocation(location, "latitude")) {
				longitude = LocationToLongitude(location);
			}

			bool useStreetAddress = IsInvalidOrdinate(latitude);

			if (useStreetAddress) {
				streetAddress = LocationToAddress(location);
			} else {
				FixUpLatitude(ref latitude);
				FixUpLongitude(ref longitude);
			}

			string previousAddress1 = Session(session_var_geo_previous_address_1);
			string previousLatitude1 = Session(session_var_geo_previous_latitude_1);
			string previousLongitude1 = Session(session_var_geo_previous_longitude_1);

			string previousAddress2 = Session(session_var_geo_previous_address_2);
			string previousLatitude2 = Session(session_var_geo_previous_latitude_2);
			string previousLongitude2 = Session(session_var_geo_previous_longitude_2);

			StringBuilder url = new StringBuilder("", 300);
			string errorMessage = "";

			if (useStreetAddress) {
				if (streetAddress.Equals(previousAddress1)) {

					try {
						latitude = StringUtils.ParseDecimal(previousLatitude1);
						longitude = StringUtils.ParseDecimal(previousLongitude1);

						StringBuilder locationStr = new StringBuilder(location, 300);

						SetLocationTag(ref locationStr, "latitude", latitude.ToString());
						SetLocationTag(ref locationStr, "longitude", longitude.ToString());
						SetLocationTag(ref locationStr, "address", previousAddress1);

						return locationStr.ToString();
					} catch {
					}
				} else if (streetAddress.Equals(previousAddress2)) {

					try {
						latitude = StringUtils.ParseDecimal(previousLatitude2);
						longitude = StringUtils.ParseDecimal(previousLongitude2);

						StringBuilder locationStr = new StringBuilder(location, 300);

						SetLocationTag(ref locationStr, "latitude", latitude.ToString());
						SetLocationTag(ref locationStr, "longitude", longitude.ToString());
						SetLocationTag(ref locationStr, "address", previousAddress2);

						SwapGeocodeCacheItems();

						return locationStr.ToString();
					} catch {
					}
				}

				latitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				longitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			} else {
				if (Convert.ToString(latitude).Equals(previousLatitude1) && Convert.ToString(longitude).Equals(previousLongitude1)) {
					StringBuilder locationStr = new StringBuilder(location, 300);

					SetLocationTag(ref locationStr, "latitude", latitude.ToString());
					SetLocationTag(ref locationStr, "longitude", longitude.ToString());
					SetLocationTag(ref locationStr, "address", previousAddress1);

					return locationStr.ToString();
				} else if (Convert.ToString(latitude).Equals(previousLatitude2) && Convert.ToString(longitude).Equals(previousLongitude2)) {
					StringBuilder locationStr = new StringBuilder(location, 300);

					SetLocationTag(ref locationStr, "latitude", latitude.ToString());
					SetLocationTag(ref locationStr, "longitude", longitude.ToString());
					SetLocationTag(ref locationStr, "address", previousAddress2);

					SwapGeocodeCacheItems();

					return locationStr.ToString();
				}

				streetAddress = "";
			}

			if (streetAddress.Trim().Length == 0 && (IsInvalidOrdinate(latitude) || IsInvalidOrdinate(longitude))) {
				return location;
			}

			switch (provider) {
				case GeoProviderType.Provider_Google:
					if (useStreetAddress) {
						url.Append("https://maps.googleapis.com/maps/api/geocode/xml");
						url.AppendFormat("?address={0}", HttpUtility.UrlEncode(streetAddress));
						url.Append("&sensor=false");
					} else {
						url.Append("https://maps.googleapis.com/maps/api/geocode/xml?latlng=" + HttpUtility.UrlEncode(Convert.ToString(latitude).Replace(",", ".")) + "," + HttpUtility.UrlEncode(Convert.ToString(longitude).Replace(",", ".")) + "&sensor=false");
					}

					if (!string.IsNullOrEmpty(googleClientID)) {
						url.Append("&client=" + HttpUtility.UrlEncode(googleClientID));
					}

					if (!string.IsNullOrEmpty(googleSignature)) {
						url.Append("&signature=" + HttpUtility.UrlEncode(googleSignature));
					}
					break;
			}

			WebResponse response = null;

			try {
				HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url.ToString());
				request.Method = "GET";
				response = request.GetResponse();

				if (response == null) {
					errorMessage = "LOCATION_ERROR_GEO_CODING_NO_RESPONSE";
				} else {
					XPathDocument document = new XPathDocument(response.GetResponseStream());
					XPathNavigator navigator = document.CreateNavigator();
					// get response status
					XPathNodeIterator statusIterator = navigator.Select("/GeocodeResponse/status");

					while (statusIterator.MoveNext()) {
						if (statusIterator.Current.Value != "OK") {
							errorMessage = "LOCATION_ERROR_GEO_CODING_" + statusIterator.Current.Value;
						}
					}

					// get results
					XPathNodeIterator resultIterator = navigator.Select("/GeocodeResponse/result");

					while (string.IsNullOrEmpty(errorMessage) && resultIterator.MoveNext()) {
						if (useStreetAddress) {
							XPathNodeIterator geometryIterator = resultIterator.Current.Select("geometry");

							while (geometryIterator.MoveNext()) {
								XPathNodeIterator locationIterator = geometryIterator.Current.Select("location");

								while (locationIterator.MoveNext()) {
									XPathNodeIterator latIterator = locationIterator.Current.Select("lat");

									while (latIterator.MoveNext()) {
										try {
											latitude = StringUtils.ParseDecimal(latIterator.Current.Value);
										} catch {
										}
									}

									XPathNodeIterator lngIterator = locationIterator.Current.Select("lng");

									while (lngIterator.MoveNext()) {
										try {
											longitude = StringUtils.ParseDecimal(lngIterator.Current.Value);
										} catch {
										}
									}
								}
							}
						} else {
							XPathNodeIterator formattedAddressIterator = resultIterator.Current.Select("formatted_address");

							// There can be more than one formattedAddress -- get the longest one
							while (formattedAddressIterator.MoveNext()) {
								if (formattedAddressIterator.Current.Value.Length > streetAddress.Length) {
									streetAddress = formattedAddressIterator.Current.Value;
								}
							}
						}
					}
				}
			} catch {
			} finally {
				if (response != null) {
					response.Close();
					response = null;
				}
			}

			StringBuilder locationStr2 = new StringBuilder(location, 300);

			if (string.IsNullOrEmpty(errorMessage)) {
				System.Web.HttpContext.Current.Session[session_var_geo_previous_address_2] = System.Web.HttpContext.Current.Session[session_var_geo_previous_address_1];
				System.Web.HttpContext.Current.Session[session_var_geo_previous_latitude_2] = System.Web.HttpContext.Current.Session[session_var_geo_previous_latitude_1];
				System.Web.HttpContext.Current.Session[session_var_geo_previous_longitude_2] = System.Web.HttpContext.Current.Session[session_var_geo_previous_longitude_1];

				System.Web.HttpContext.Current.Session[session_var_geo_previous_address_1] = streetAddress;
				System.Web.HttpContext.Current.Session[session_var_geo_previous_latitude_1] = Convert.ToString(latitude);
				System.Web.HttpContext.Current.Session[session_var_geo_previous_longitude_1] = Convert.ToString(longitude);

				SetLocationTag(ref locationStr2, "latitude", latitude.ToString());
				SetLocationTag(ref locationStr2, "longitude", longitude.ToString());
				SetLocationTag(ref locationStr2, "address", streetAddress);
			} else {
				SetLocationTag(ref locationStr2, "error", errorMessage);
			}

			return locationStr2.ToString();
		}


		public static string GetGoogleKey()
		{
			string value = BaseClasses.Configuration.ApplicationSettings.Current.GoogleKey;

			return value;
		}


		public static string GetGoogleClientID()
		{
			string value = BaseClasses.Configuration.ApplicationSettings.Current.GoogleClientID;

			return value;
		}


		public static string GetGoogleSignature()
		{
			string value = BaseClasses.Configuration.ApplicationSettings.Current.GoogleSignature;

			return value;
		}



		private static string CreateDirections(object startLocation, object endLocation, object popupWidth, object popupHeight, object googleDirectionsParameters, string HTMLInsideLink)
		{
			string startLocationStr = "";
			string endLocationStr = "";
			long popupWidthInteger = 0;
			long popupHeightInteger = 0;
			string googleDirectionsParametersStr = "";

			try {
				startLocationStr = GetStr(startLocation);
				endLocationStr = GetStr(endLocation);
				popupWidthInteger = StringUtils.ParseInteger(popupWidth);
				popupHeightInteger = StringUtils.ParseInteger(popupHeight);
				googleDirectionsParametersStr = GetStr(googleDirectionsParameters);

				if (popupWidthInteger == -1) {
					popupWidthInteger = 800;
				}

				if (popupHeightInteger == -1) {
					popupHeightInteger = 800;
				}

				startLocationStr = BuildLocation(startLocationStr);
				endLocationStr = BuildLocation(endLocationStr);

				string googleKey = GetGoogleKey();
				string startAddress = "";
				decimal startLatitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				decimal startLongitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				string endAddress = "";
				decimal endLatitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
				decimal endLongitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;

				if (IsInLocation(startLocationStr, "address")) {
					startAddress = LocationToAddress(startLocationStr);
				}

				if (IsInLocation(startLocationStr, "latitude")) {
					startLatitude = LocationToLatitude(startLocationStr);
				}

				if (IsInLocation(startLocationStr, "longitude")) {
					startLongitude = LocationToLongitude(startLocationStr);
				}

				if (IsInLocation(endLocationStr, "address")) {
					endAddress = LocationToAddress(endLocationStr);
				}

				if (IsInLocation(endLocationStr, "latitude")) {
					endLatitude = LocationToLatitude(endLocationStr);
				}

				if (IsInLocation(endLocationStr, "longitude")) {
					endLongitude = LocationToLongitude(endLocationStr);
				}

				bool useStreetAddressSource = IsInvalidOrdinate(startLatitude);
				bool useStreetAddressDestination = IsInvalidOrdinate(endLatitude);

				FixUpLatitude(ref startLatitude);
				FixUpLatitude(ref endLatitude);

				FixUpLongitude(ref startLongitude);
				FixUpLongitude(ref endLongitude);

				if (googleDirectionsParametersStr.Length > 0 && !googleDirectionsParametersStr.StartsWith("&")) {
					googleDirectionsParametersStr = "&" + googleDirectionsParametersStr;
				}

				string lowerGoogleDirectionsParameters = googleDirectionsParametersStr.ToLowerInvariant();

				StringBuilder hrefStr = new StringBuilder("", 300);

				// Example format: https://maps.google.com/maps?saddr=2870+Zanker+Road,+San+Jose,+CA&daddr=1173+Geary+Blvd,+Lebanon,+PA+17042,+USA&hl=en&sll=40.509938,-76.380274&sspn=0.01235,0.018947&oq=2870+Zanker+&mra=ls&t=m&z=4

				hrefStr.Append("https://maps.google.com/maps?");

				if (useStreetAddressSource) {
					hrefStr.AppendFormat("saddr={0}", HttpUtility.UrlEncode(startAddress));
				} else {
					hrefStr.AppendFormat("saddr={0},{1}", HttpUtility.UrlEncode(startLatitude.ToString().Replace(",", ".")), HttpUtility.UrlEncode(startLongitude.ToString().Replace(",", ".")));
				}

				if (useStreetAddressDestination) {
					hrefStr.AppendFormat("&daddr={0}", HttpUtility.UrlEncode(endAddress));
				} else {
					hrefStr.AppendFormat("&daddr={0},{1}", HttpUtility.UrlEncode(endLatitude.ToString().Replace(",", ".")), HttpUtility.UrlEncode(endLongitude.ToString().Replace(",", ".")));
				}

				if (!string.IsNullOrEmpty(googleDirectionsParametersStr)) {
					hrefStr.Append(googleDirectionsParametersStr);
				}

				if (googleKey.Length > 0 && !lowerGoogleDirectionsParameters.Contains("&key=")) {
					hrefStr.Append("&key=");
					hrefStr.Append(googleKey);
				}

				StringBuilder str = new StringBuilder("", 300);

				str.Append("<a");
				str.AppendFormat(" href=\"{0}\"", hrefStr.ToString());
				str.AppendFormat(" target=\"{0}\"", "_blank");

				str.AppendFormat(" onclick=\"var left=(screen.width/2)-({0}/2);var top=(screen.height/2)-({1}/2);window.open(this.href, '_blank'" + ", 'scrollbars=yes,resizable=yes,width={0},height={1},top='+top+',left='+left);return false;\"", popupWidthInteger, popupHeightInteger);

				str.Append(">");
				if (string.IsNullOrEmpty(HTMLInsideLink)) {
					str.Append(HttpUtility.HtmlEncode(Resource("Txt:ShowDirections")));
				} else if (HTMLInsideLink.ToUpperInvariant().Contains("<IMG ")) {
					str.Append(HTMLInsideLink);
				} else {
					str.Append(HttpUtility.HtmlEncode(HTMLInsideLink));
				}

				str.Append("</a>");

				return str.ToString();
			} catch (Exception ex) {
				throw new Exception("GOOGLEDIRECTIONS(" + startLocation + ", " + endLocation + "): " + ex.Message);
			}

		}


		private static string CreateMap(string mapType, object location, object width, object height, object popupWidth, object popupHeight, GeoProviderType providerType, object map1Parameters, object map2Parameters)
		{
			string locationStr = "";
			long widthInteger = 0;
			long heightInteger = 0;
			long popupWidthInteger = 0;
			long popupHeightInteger = 0;
			string map1ParametersStr = "";
			string map2ParametersStr = "";

			try {
				locationStr = GetStr(location);

				widthInteger = StringUtils.ParseInteger(width);
				heightInteger = StringUtils.ParseInteger(height);

				popupWidthInteger = StringUtils.ParseInteger(popupWidth);
				popupHeightInteger = StringUtils.ParseInteger(popupHeight);

				if (popupWidthInteger == -1) {
					popupWidthInteger = 800;
				}

				if (popupHeightInteger == -1) {
					popupHeightInteger = 800;
				}

				map1ParametersStr = GetStr(map1Parameters);
				map2ParametersStr = GetStr(map2Parameters);

				location = BuildLocation(locationStr);

				StringBuilder title = new StringBuilder("", 300);

				if (IsInLocation(locationStr, "address")) {
					title.AppendFormat("{0}", LocationToAddress(locationStr));
				} else {
					title.AppendFormat("{0},{1}", LocationToOther(locationStr, "latitude"), LocationToOther(locationStr, "longitude"));
				}

				if (map1ParametersStr.Length > 0 && !map1ParametersStr.StartsWith("&")) {
					map1ParametersStr = "&" + map1ParametersStr;
				}

				string lowerMap1Parameters = map1ParametersStr.ToLowerInvariant();
				string lowerMap2Parameters = map2ParametersStr.ToLowerInvariant();

				if (widthInteger < 0) {
					widthInteger = 600;
				} else if (widthInteger > 2048) {
					widthInteger = 2048;
				}

				if (heightInteger < 0) {
					heightInteger = 300;
				} else if (heightInteger > 2048) {
					heightInteger = 2048;
				}

				StringBuilder str = new StringBuilder("", 300);

				if (mapType == null || mapType.Length == 0) {
					mapType = "staticimagewithpopup";
				}

				mapType = mapType.ToLowerInvariant();

				if (mapType.Equals("interactiveurl")) {
					string iframeURL = GetMapURL("interactive", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append(iframeURL);
				} else if (mapType.Equals("staticimageurl")) {
					string imageURL = GetMapURL("staticimage", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append(imageURL);
				} else if (mapType.Equals("popupurl")) {
					string fullURL = GetMapURL("popup", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append(fullURL);
				} else if (mapType.Equals("interactive")) {
					string iframeUrl = GetMapURL("interactive", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append("<iframe");
					str.AppendFormat(" src=\"{0}\"", iframeUrl);
					str.AppendFormat(" width=\"{0}\" height=\"{1}\"", widthInteger, heightInteger);
					str.Append("></iframe>");
				} else if (mapType.Equals("staticimage")) {
					string imageURL = GetMapURL("staticimage", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append("<img");
					str.AppendFormat(" src=\"{0}\"", imageURL);

					if (!map1ParametersStr.ToLowerInvariant().Contains("&size=")) {
						str.AppendFormat(" width=\"{0}\" height=\"{1}\"", widthInteger, heightInteger);
					}

					str.AppendFormat(" title=\"{0}\"", HttpUtility.HtmlEncode(title.ToString()));
					str.Append(" />");
				} else if (mapType.Equals("staticimagewithpopup")) {
					string imageURL = GetMapURL("staticimage", locationStr, widthInteger, heightInteger, map1ParametersStr);
					string fullURL = GetMapURL("popup", locationStr, widthInteger, heightInteger, map2ParametersStr);

					str.Append("<a");
					str.AppendFormat(" href=\"{0}\"", fullURL);
					str.AppendFormat(" target=\"{0}\"", "_blank");
					str.AppendFormat(" onclick=\"var left=(screen.width/2)-({0}/2);var top=(screen.height/2)-({1}/2);window.open(this.href, '_blank'" + ", 'scrollbars=yes,resizable=yes,width={0},height={1},top='+top+',left='+left); return false;\"", popupWidthInteger, popupHeightInteger);
					str.AppendFormat(" title=\"{0}\"", Resource("Txt:ShowMap"));
					str.Append(">");
					str.Append("<img");
					str.AppendFormat(" src=\"{0}\"", imageURL);

					if (!map1ParametersStr.ToLowerInvariant().Contains("&size=")) {
						str.AppendFormat(" width=\"{0}\" height=\"{1}\"", widthInteger, heightInteger);
					}

					str.AppendFormat(" title=\"{0}\"", HttpUtility.HtmlEncode(title.ToString()));
					str.Append(" />");
					str.Append("</a>");
				} else if (mapType.Equals("textlink")) {
					string fullURL = GetMapURL("popup", locationStr, widthInteger, heightInteger, map1ParametersStr);

					str.Append("<a");
					str.AppendFormat(" href=\"{0}\"", fullURL);
					str.AppendFormat(" target=\"{0}\"", "_blank");
					str.AppendFormat(" onclick=\"var left=(screen.width/2)-({0}/2);var top=(screen.height/2)-({1}/2);window.open(this.href, '_blank'" + ", 'scrollbars=yes,resizable=yes,width={0},height={1},top='+top+',left='+left); return false;\"", popupWidthInteger, popupHeightInteger);
					str.AppendFormat(" title=\"{0}\"", Resource("Txt:ShowMap"));
					str.Append(">");
					str.Append(Resource("Txt:ShowMap"));
					str.Append("</a>");
				}

				return str.ToString();
			} catch (Exception ex) {
				throw new Exception("CREATEMAP(" + location + ", " + width + ", " + height + ", " + map1Parameters + ", " + map2Parameters + "): " + ex.Message);
			}

		}


		private static string GetMapURL(string mapType, string location, long width, long height, string mapParameters)
		{
			string googleKey = GetGoogleKey();
			string googleClientID = GetGoogleClientID();
			string googleSignature = GetGoogleSignature();
			string address = "";
			decimal latitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			decimal longitude = BaseClasses.Web.UI.BasePage.GEO_LOCATION_INVALID_ORDINATE;
			string placeString = "";

			if (IsInLocation(location, "address")) {
				address = LocationToAddress(location);

				placeString = address;
			} else {
				latitude = LocationToLatitude(location);
				longitude = LocationToLongitude(location);

				placeString = latitude.ToString().Replace(",", ".") + "," + longitude.ToString().Replace(",", ".");
			}

			bool useStreetAddress = IsInvalidOrdinate(latitude);

			if (mapParameters.Length > 0 && !mapParameters.StartsWith("&")) {
				mapParameters = "&" + mapParameters;
			}

			string lowerMapParameters = mapParameters.ToLowerInvariant();

			if (width < 0) {
				width = 600;
			} else if (width > 2048) {
				width = 2048;
			}

			if (height < 0) {
				height = 300;
			} else if (height > 2048) {
				height = 2048;
			}

			StringBuilder str = new StringBuilder("", 300);

			if (mapType == null || mapType.Length == 0) {
				mapType = "interactive";
			}

			mapType = mapType.ToLowerInvariant();

			if (mapType.Equals("staticimage")) {
				str.Append("http://maps.googleapis.com/maps/api/staticmap?");

				str.AppendFormat("center={0}", HttpUtility.UrlEncode(placeString));

				if (!lowerMapParameters.Contains("&markers=")) {
					str.AppendFormat("&markers={0}", HttpUtility.UrlEncode(placeString));
				}

				if (!lowerMapParameters.Contains("&size=")) {
					str.AppendFormat("&size={0}x{1}", width, height);
				}

				if (googleKey.Length > 0 && !lowerMapParameters.Contains("&key=")) {
					str.Append("&key=");
					str.Append(googleKey);
				}

				if (!lowerMapParameters.Contains("&type=")) {
					str.Append("&type=roadmap");
				}

				if (!lowerMapParameters.Contains("&sensor=")) {
					str.Append("&sensor=false");
				}
			} else {
				// formats: https://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&;q=2870+Zanker+Road,+San+Jose,+CA&aq=0&oq=2870+zanker+&sll=37.0625,-95.677068&sspn=60.246331,135.263672&
				//          t=h&ie=UTF8&hq=&hnear=2870+Zanker+Rd,+San+Jose,+California+95134&ll=37.395119,-121.927557&spn=0.034095,0.035963&z=14&iwloc=A&output=embed&t=m
				//          http://maps.googleapis.com/maps/api/staticmap?center=2870+Zanker+Rd,San+Jose,CA,USA&zoom=13&size=600x300&maptype=roadmap&markers=%7c2870+Zanker+Rd,San+Jose,CA,USA&sensor=false
				//          http://maps.googleapis.com/maps/api/staticmap?center=37.39519,-121.92724&zoom=13&size=600x300&maptype=roadmap&markers=%7c37.39519,-121.92724&sensor=false
				//          https://maps.google.com/maps?f=q&source=s_q&hl=en&geocode=&;q=2870+Zanker+Road,+San+Jose,+CA&aq=0&oq=2870+zanker+&sll=37.0625,-95.677068&sspn=60.246331,135.263672&t=h&ie=UTF8&
				//          hq=&hnear=2870+Zanker+Rd,+San+Jose,+California+95134&ll=37.395119,-121.927557&spn=0.034095,0.035963&z=14&iwloc=A&output=embed&t=m
				str.Append("https://maps.google.com/maps?");

				str.AppendFormat("q={0}", HttpUtility.UrlEncode(placeString));

				if (!useStreetAddress) {
					str.AppendFormat("&ll={0},{1}", latitude, longitude);
				}

				if (!lowerMapParameters.Contains("&mrt=")) {
					str.Append("&mrt=loc");
				}

				if (mapType.Equals("interactive")) {
					if (!lowerMapParameters.Contains("&output=")) {
						str.Append("&output=embed");
					}
				}

				if (!lowerMapParameters.Contains("&t=")) {
					str.Append("&t=m");
				}

				if (!string.IsNullOrEmpty(googleClientID)) {
					str.Append("&client=" + HttpUtility.UrlEncode(googleClientID));
				}

				if (!string.IsNullOrEmpty(googleSignature)) {
					str.Append("&signature=" + HttpUtility.UrlEncode(googleSignature));
				}
			}

			if (!string.IsNullOrEmpty(lowerMapParameters)) {
				str.Append(mapParameters);
			}

			return str.ToString();
		}


		/// <summary>
		/// Convert an object to string
		/// </summary>
		/// <param name="str">The input to be converted</param>
		/// <returns>The input to be converted.</returns>
		private static string GetStr(object str)
		{
			if (str == null) {
				return string.Empty;
			}
			return str.ToString();
		}

		#endregion

        #region "Misc"



            /// <summary>
            /// evaluate formula along with the data source object
            /// </summary>
            /// <param name="formula">formula to be evaluated</param>
            /// <param name="dataSource">data source object to be used on evaluation</param>
            /// <returns>text to display on quick selector</returns>
            /// <remarks></remarks>
            public static string EvaluateFormula(string formula, BaseRecord dataSource)
            {
	            System.Collections.Generic.IDictionary<string, object> variables = new System.Collections.Generic.Dictionary<string, object>();

	            BaseFormulaEvaluator evaluator = new BaseFormulaEvaluator();
	            if (dataSource != null) {
		            evaluator.Variables.Add(dataSource.TableAccess.TableDefinition.TableCodeName, dataSource);
		            evaluator.DataSource = dataSource;
	            }

	            object resultObj = evaluator.Evaluate(formula);
	            if (resultObj == null) {
		            return "";
	            }
	            return resultObj.ToString();

            }
        #endregion


	}
}
