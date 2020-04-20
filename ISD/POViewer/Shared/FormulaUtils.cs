using Microsoft.VisualBasic;
using System.IO;
using System.Collections;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using POViewer.UI;
using POViewer.Business;
using System;
using POViewer.Data;

namespace POViewer
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
    public class FormulaUtils:BaseFormulaUtils
    {
    

        #region "Private Convenience Functions"

        /// <summary>
        /// GetSortedValues is a private function that returns the list of sorted values of
        /// the given control name. This is used by Rank, Median, Average, Mode, etc.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>A sorted array of values for the given control. </returns>
        private static ArrayList GetSortedValues(BaseApplicationTableControl tableControl, string ctlName)
        {
            ArrayList rankedArray = new ArrayList();
            
            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {                
                // The control itself may be embedded in sub-panels, so we need to use
                // FindControlRecursively starting from the recCtl.
                System.Web.UI.Control ctl = MiscUtils.FindControlRecursively(recCtl, ctlName);
                if (!(ctl == null) && ctl.Visible)
                {
                    string textVal = null;
                    decimal val = 0;

                    // Get the value from the textbox, label or literal
                    if (ctl is System.Web.UI.WebControls.TextBox)
                    {
                        textVal = ((System.Web.UI.WebControls.TextBox)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Label)
                    {
                        textVal = ((System.Web.UI.WebControls.Label)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Literal)
                    {
                        textVal = ((System.Web.UI.WebControls.Literal)ctl).Text;
                    }

                    try
                    {
                        // If the value is not a valid number, ignore it.
                        val = StringUtils.ParseDecimal(textVal);
                        rankedArray.Add(val);
                    }
                    catch (Exception)
                    {
                        // Ignore exception.
                    }                    
                }
            }

            // Sort the array now.
            rankedArray.Sort();

            return rankedArray;
        }
        #endregion
        
        #region "Table Control-level functions"

        /// <summary>
        /// Sum the values of the displayed controls. The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.SUM("UnitPrice"), not
        /// as shown here. The SUM function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public static decimal Sum(BaseApplicationTableControl tableControl, string ctlName)
        {
            decimal total = 0;

            foreach (object item in GetSortedValues(tableControl, ctlName))
            {
                total += StringUtils.ParseDecimal(item);
            }

            return total;
        }

        /// <summary>
        /// Sum the values of the displayed controls.  The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.TOTAL("UnitPrice"), not
        /// as shown here. The TOTAL function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public static decimal Total(BaseApplicationTableControl tableControl, string ctlName)
        {
            decimal sum = 0;

            foreach (object item in GetSortedValues(tableControl, ctlName))
            {
                sum += StringUtils.ParseDecimal(item);
            }

            return sum;
        }

        /// <summary>
        /// Finds the maximum among the values of the displayed controls.  The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.Max("UnitPrice"), not
        /// as shown here. The MAX function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The maximum among the values contained in each of the fields.</returns>
        public static decimal Max(BaseApplicationTableControl tableControl, string ctlName)
        {
            decimal maxDecimal = Decimal.MinValue;

            foreach (object item in GetSortedValues(tableControl, ctlName))
            {
                maxDecimal = Math.Max(maxDecimal, StringUtils.ParseDecimal(item));
            }

            return maxDecimal;
        }  

        /// <summary>
        /// Finds the minimum among the values of the displayed controls.  The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.Min("UnitPrice"), not
        /// as shown here. The MIN function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The minimum among the values contained in each of the fields.</returns>
        public static decimal Min(BaseApplicationTableControl tableControl, string ctlName)
        {
            decimal minDecimal = Decimal.MaxValue;

            foreach (object item in GetSortedValues(tableControl, ctlName))
            {
                minDecimal = Math.Min(minDecimal, StringUtils.ParseDecimal(item));
            }

            return minDecimal;
        }  
        
        /// <summary>
        /// Count the number of rows in this table control.
        /// This function should be called as <Products>TableControl.COUNT(), not
        /// as shown here. The COUNT function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The count of the number of rows.</returns>
        public static int Count(BaseApplicationTableControl tableControl, string ctlName)
        {
            try
            {
                return tableControl.GetBaseRecordControls().Length;
            }
            catch (Exception)
            {
                // If there is an error getting the length, we simply fall through and return 0.
            }
            return 0;
        }

        /// <summary>
        /// Count the number of rows in this table control that actually contain 
        /// a decimal value (as opposed to be NULL or invalid value)
        /// This function should be called as <Products>TableControl.COUNTA("UnitPrice"), not
        /// as shown here. The COUNTA function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The count of the number of rows.</returns>
        public static int CountA(BaseApplicationTableControl tableControl, string ctlName)
        {
            int totalRows = 0;

            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {
                // The control itself may be embedded in sub-panels, so we need to use
                // FindControlRecursively starting from the recCtl.
                System.Web.UI.Control ctl = MiscUtils.FindControlRecursively(recCtl, ctlName);
                if (!(ctl == null))
                {
                    // Add the row if this contains a valid number.
                    string val = null;
                    // Get the value from the textbox, label or literal
                    if (ctl is System.Web.UI.WebControls.TextBox)
                    {
                        val = ((System.Web.UI.WebControls.TextBox)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Label)
                    {
                        val = ((System.Web.UI.WebControls.Label)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Literal)
                    {
                        val = ((System.Web.UI.WebControls.Literal)ctl).Text;
                    }
                    try
                    {
                        if (!(val == null) && val.Trim().Length > 0)
                        {
                            totalRows += 1;
                        }
                    }
                    catch (Exception)
                    {
                        // Ignore exception - since this is only returning the 
                        // rows that contain a valid value. Other rows with a
                        // NULL value or an invalid value will not be counted.
                    }                    
                }
            }

            return totalRows;
        }

        /// <summary>
        /// Calulates the Mean (Average) of the values of the displayed controls. The ctlName must be
        /// a textbox, label or literal.
        /// We could have implemented this as a call to SUM()/COUNT(), but decided to do it this way
        /// for efficiency.
        /// This function should be called as [Products]TableControl.MEAN("UnitPrice"), not
        /// as shown here. The MEAN function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public static decimal Mean(BaseApplicationTableControl tableControl, string ctlName)
        {
            decimal total = 0;
            int numRows = 0;

            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {
                // The control itself may be embedded in sub-panels, so we need to use
                // FindControlRecursively starting from the recCtl.
                System.Web.UI.Control ctl = MiscUtils.FindControlRecursively(recCtl, ctlName);
                if (!((ctl == null)))
                {
                    string val = null;
                    // Get the value from the textbox, label or literal
                    if (ctl is System.Web.UI.WebControls.TextBox)
                    {
                        val = ((System.Web.UI.WebControls.TextBox)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Label)
                    {
                        val = ((System.Web.UI.WebControls.Label)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Literal)
                    {
                        val = ((System.Web.UI.WebControls.Literal)ctl).Text;
                    }

                    try
                    {
                        // If the value is not a valid number, ignore it.
                        total += StringUtils.ParseDecimal(val);
                    }
                    catch (Exception)
                    {
                        // Ignore exception.
                    }                   

                    // Mean is calculated based on the number of rows, NOT on
                    // the number of non-NULL values. So in this way, it is based on
                    // COUNT and not on COUNTA.
                    numRows += 1;
                }
            }

            return (total / numRows);
        }

        /// <summary>
        /// Calulates the Average of the values of the displayed controls. The ctlName must be
        /// a textbox, label or literal.
        /// We could have implemented this as a call to SUM()/COUNT(), but decided to do it this way
        /// for efficiency.
        /// This function should be called as [Products]TableControl.AVERAGE("UnitPrice"), not
        /// as shown here. The AVERAGE function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public static decimal Average(BaseApplicationTableControl tableControl, string ctlName)
        {
            return Mean(tableControl, ctlName);
        }

        /// <summary>
        /// Return the Mode of this control.
        /// This function should be called as [Products]TableControl.MODE("UnitPrice"), not
        /// as shown here. The MODE function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// Say there are 5 rows and they contain 57, 57, 12, 57, 98.
        /// The Mode is 57 as it is the number which repeats the maximum number of times.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The row number of the recordControl passed in. 0 if this is not a correct row number. </returns>
        public static decimal Mode(BaseApplicationTableControl tableControl, string ctlName)
        {
            ArrayList rankedArray = GetSortedValues(tableControl, ctlName);

            decimal num = 0;
            decimal modeVal = 0;

            int count = 0;
            int max = 0;

            // Because this is a sorted array, we can 
            foreach (object item in rankedArray)
            {
                if (num != StringUtils.ParseDecimal(item))
                {
                    num = StringUtils.ParseDecimal(item);
                    count = 1;
                }
                else
                {
                    count += 1;
                }

                if (count > max)
                {
                    max = count;
                    modeVal = num;
                }
            }

            return modeVal;
        }

        /// <summary>
        /// Return the Median of this control.
        /// This function should be called as [Products]TableControl.MEDIAN("UnitPrice"), not
        /// as shown here. The MEDIAN function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// The order is 12, 19, 32, 57, 98 - so the Median is 32.
        /// If the number of numbers is even, the Median is the average of the two middle numbers.
        /// Say there are 6 rows and they contain 57, 32, 12, 19, 98, 121
        /// The order is 12, 19, 32, 57, 98, 121 - so the two numbers in the mid are 32 and 57.
        /// So the median is (32 + 57) / 2 = 89/2 = 44.5
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The row number of the recordControl passed in. 0 if this is not a correct row number. </returns>
        public static decimal Median(BaseApplicationTableControl tableControl, string ctlName)
        {
            ArrayList rankedArray = GetSortedValues(tableControl, ctlName);

            // If there are 0 elements, then there is no median.
            if (rankedArray.Count == 0) return 0;

            int halfPoint = (int)Math.Floor((double)rankedArray.Count / 2);
            decimal medianValue = 0;
            if (rankedArray.Count % 2 == 0)
            {
                medianValue = (StringUtils.ParseDecimal(rankedArray[halfPoint - 1]) + StringUtils.ParseDecimal(rankedArray[halfPoint]) / 2);
            }
            else
            {
                // Odd numbered items. So 
                medianValue = StringUtils.ParseDecimal(rankedArray[halfPoint]);
            }

            return medianValue;
        }

        /// <summary>
        /// Return the Range of this control.
        /// This function should be called as [Products]TableControl.RANGE("UnitPrice"), not
        /// as shown here. The RANGE function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// The lowest is 12, highest is 98, so the range is 98-12 = 86
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The row number of the recordControl passed in. 0 if this is not a correct row number. </returns>
        public static decimal Range(BaseApplicationTableControl tableControl, string ctlName)
        {
            ArrayList rankedArray = GetSortedValues(tableControl, ctlName);

            // If there are 0 or 1 elements, then there is no range.
            if (rankedArray.Count <= 1) return 0;

            // Take the difference between the largest and the smallest.
            return StringUtils.ParseDecimal(rankedArray[rankedArray.Count - 1]) - StringUtils.ParseDecimal(rankedArray[0]);
        }

        #endregion

        #region "Record Control-level functions"

        /// <summary>
        /// Return the row number of this record control.
        /// This function should be called as <Products>TableControlRow.ROWNUM(), not
        /// as shown here. The ROWNUM function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="recordControl">The record control whose row number is being determined. Row numbers are 1-based.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The row number of the recordControl passed in. 0 if this is not a correct row number. </returns>
        public static int RowNum(BaseApplicationTableControl tableControl, BaseApplicationRecordControl recordControl)
        {
            int rowNumber = 1;

            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {
                if (object.ReferenceEquals(recCtl, recordControl))
                {
                    // We found the row.
                    return rowNumber;
                }
                rowNumber += 1;
            }

            return 0;
        }

        /// <summary>
        /// Return the Rank of this control.
        /// This function should be called as <Products>TableControlRow.RANK("UnitPrice"), not
        /// as shown here. The RANK function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// Their respecitive ranks will be 4, 3, 1, 2, 5
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="recordControl">The record control whose tank is being determined. Rank numbers are 1-based.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The row number of the recordControl passed in. 0 if this is not a correct row number. </returns>
        public static int Rank(BaseApplicationTableControl tableControl, BaseApplicationRecordControl recordControl, string ctlName)
        {
            ArrayList rankedArray = new ArrayList();
            decimal lookFor = 0;

            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {
                System.Web.UI.Control ctl = default(System.Web.UI.Control);
                // The control itself may be embedded in sub-panels, so we need to use
                // FindControlRecursively starting from the recCtl.
                ctl = MiscUtils.FindControlRecursively(recCtl, ctlName);
                if (!(ctl == null))
                {
                    string textVal = null;
                    decimal val = 0;

                    // Get the value from the textbox, label or literal
                    if (ctl is System.Web.UI.WebControls.TextBox)
                    {
                        textVal = ((System.Web.UI.WebControls.TextBox)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Label)
                    {
                        textVal = ((System.Web.UI.WebControls.Label)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Literal)
                    {
                        textVal = ((System.Web.UI.WebControls.Literal)ctl).Text;
                    }

                    try
                    {
                        // If the value is not a valid number, ignore it.
                        val = StringUtils.ParseDecimal(textVal);
                        rankedArray.Add(val);
                        // Save the value that we need to look for to determine the rank
                        if (object.ReferenceEquals(recCtl, recordControl))
                        {
                            lookFor = val;
                        }
                    }
                    catch (Exception)
                    {
                        // Ignore exception.
                    }                    
                }
            }

            // Sort the array now.
            rankedArray.Sort();

            // Rank is always 1 based in our case. So we need to add one to the
            // location returned by IndexOf
            return rankedArray.IndexOf(lookFor) + 1;
        }

        /// <summary>
        /// Return the running total of the control.
        /// This function should be called as [Products]TableControlRow.RUNNINGTOTAL("UnitPrice"), not
        /// as shown here. The RUNNINGTOTAL function in the BaseApplicationRecordControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// Their respecitive running totals will be 57, 89, 101, 120, 218
        /// </summary>
        /// <param name="tableControl">The table control instance.</param>
        /// <param name="recordControl">The record control whose running total is being determined.</param>
        /// <param name="ctlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The running total of the recordControl passed in.</returns>
        public static decimal RunningTotal(BaseApplicationTableControl tableControl, BaseApplicationRecordControl recordControl, string ctlName)
        {
            decimal sum = 0;

            // Get all of the record controls within this table control.
            foreach (BaseApplicationRecordControl recCtl in tableControl.GetBaseRecordControls())
            {
                System.Web.UI.Control ctl = default(System.Web.UI.Control);
                // The control itself may be embedded in sub-panels, so we need to use
                // FindControlRecursively starting from the recCtl.
                ctl = MiscUtils.FindControlRecursively(recCtl, ctlName);
                if (!(ctl == null))
                {
                    string textVal = null;
                    decimal val = 0;

                    // Get the value from the textbox, label or literal
                    if (ctl is System.Web.UI.WebControls.TextBox)
                    {
                        textVal = ((System.Web.UI.WebControls.TextBox)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Label)
                    {
                        textVal = ((System.Web.UI.WebControls.Label)ctl).Text;
                    }
                    else if (ctl is System.Web.UI.WebControls.Literal)
                    {
                        textVal = ((System.Web.UI.WebControls.Literal)ctl).Text;
                    }

                    try
                    {
                        // If the value is not a valid number, ignore it.
                        val = StringUtils.ParseDecimal(textVal);
                        sum = val + sum;                        
                        if (object.ReferenceEquals(recCtl, recordControl))
                        {
                        //Return sum if the row we are looking for is reached
                            return sum;
                        }
                    }
                    catch (Exception)
                    {
                        // Ignore exception.
                    }                    
                }
            }           
           
            return sum;
        }


        /// <summary>
        /// designed to be used on Quick Selector, repeater row
        /// </summary>
        /// <param name="datasource"></param>
        /// <returns>text to display on quick selector</returns>
        /// <remarks></remarks>
        public static string GetQuickSelectorDisplayText(BaseClasses.Data.BaseRecord datasource)
        {
	        if (!string.IsNullOrEmpty(URL("Formula"))) {
		        return BaseFormulaUtils.EvaluateFormula(URL("Formula"), datasource);
	        }
	        if (!string.IsNullOrEmpty(URL("DFKA"))) {
		        BaseColumn col = datasource.TableAccess.TableDefinition.ColumnList.GetByAnyName(URL("DFKA"));
		        return datasource.GetValue(col).ToString();
	        }
	        if (!string.IsNullOrEmpty(URL("IndexField"))) {
		        BaseColumn col = datasource.TableAccess.TableDefinition.ColumnList.GetByAnyName(URL("IndexField"));
		        return datasource.GetValue(URL("IndexField")).ToString();
	        }
	        return "";
        }


        #endregion

    }
}





