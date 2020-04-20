using System;
using System.Collections;
using System.Web.UI;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using VPLookup.Data;
using System.Web.UI.WebControls;

namespace VPLookup.UI
// Typical customizations that may be done in this class include
// - adding custom event handlers
//  - overriding base class methods

/// <summary>
/// The superclass (i.e. base class) for all Designer-generated pages in this application.
/// </summary>
/// <remarks>
/// <para>
/// </para>
/// </remarks>
{
    public class BaseApplicationTableControl : System.Web.UI.Control
    {

        public BaseApplicationTableControl()
        {
            this.PreRender += new EventHandler(Control_ClearControls_PreRender);
            this.Unload += new EventHandler(Control_SaveControls_Unload);
			this.Load += new EventHandler(BaseLoad);
        }

        /// <summary>
        /// The name of the row controls. By convention, "Row" is appended to the
        /// end of the name of the table control. So OrdersTableControl will have
        /// OrdersTableControlRow controls.
        /// </summary>
        public virtual string RowName
        {
            get { return this.ID + "Row"; }
        }

        /// <summary>
        /// The name of the repeater controls. By convention, "Repeater" is appended to the
        /// end of the name of the table control. So OrdersTableControl will have
        /// OrdersTableControlRepeater controls. The Row controls defined above are
        /// within the Repeater control.
        /// </summary>
        public virtual string RepeaterName
        {
            get { return this.ID + "Repeater"; }
        }

        // Allow for migration from earlier versions which did not have url encryption.
        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument)
        {
            throw new Exception("This function should be implemented by inherited table control class.");
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            throw new Exception("This function should be implemented by inherited table control class.");
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt, bool includeSession)
        {
            throw new Exception("This function should be implemented by inherited table control class.");
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            throw new Exception("This function should be implemented by inherited table control class.");
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt,bool includeSession)
        {
            throw new Exception("This function should be implemented by inherited table control class.");
        }

        // Allow for migration from earlier versions which did not have url encryption.
        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, Object rec)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, rec, false);
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, Object rec, bool bEncrypt)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, rec, bEncrypt);
        }


        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, Object rec, bool bEncrypt)
        {
            const string PREFIX_NO_ENCODE = "NoUrlEncode:";

            string finalRedirectUrl = redirectUrl;
            string finalRedirectArgument = redirectArgument;

            if ((finalRedirectUrl == null || finalRedirectUrl.Length == 0))
            {
                return finalRedirectUrl;
            }
            else if (finalRedirectUrl.IndexOf('{') < 0)
            {
                return finalRedirectUrl;
            }
            else
            {
                //The old way was to pass separate URL and arguments and use String.Format to
                //do the replacement. Example:
                // URL: EditProductsRecord?Products={0}
                // Argument: PK
                //The new way to is pass the arguments directly in the URL. Example:
                // URL: EditProductsRecord?Products={PK}
                //If the old way is passsed, convert it to the new way.
                if (finalRedirectArgument != null && finalRedirectArgument.Length > 0)
                {
                    string[] arguments = finalRedirectArgument.Split(',');
                    for (int i = 0; i <= (arguments.Length - 1); i++)
                    {
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + i.ToString() + "}", "{" + arguments[i] + "}");
                    }
                    finalRedirectArgument = "";
                    }

                    //Evaluate all of the expressions in the RedirectURL
                    //Expressions can be of the form [ControlName:][NoUrlEncode:]Key[:Value]
                    string remainingUrl = finalRedirectUrl;

                    while ((remainingUrl.IndexOf('{') >= 0) & (remainingUrl.IndexOf('}') > 0) & (remainingUrl.IndexOf('{') < remainingUrl.IndexOf('}')))
                    {

                        int leftIndex = remainingUrl.IndexOf('{');
                        int rightIndex = remainingUrl.IndexOf('}');
                        string expression = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                        string origExpression = expression;
                        remainingUrl = remainingUrl.Substring(rightIndex + 1);

                        bool skip = false;
                        bool returnEmptyStringOnFail = false;
                        string prefix = null;

                        //Check to see if this control must evaluate the expression
                        if ((expression.IndexOf(":") > 0))
                        {
                            prefix = expression.Substring(0, expression.IndexOf(":"));
                        }
                        if ((prefix != null) && (prefix.Length > 0) && (!(StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE))) && (!BaseRecord.IsKnownExpressionPrefix(prefix)))
                        {

                            //Remove the ASCX Prefix
                            string IdString = this.ID;
                            if (IdString.StartsWith("_"))
                            {
                                IdString = IdString.Remove(0, 1);
                            }
                            //The prefix is a control name.
                            if (prefix == IdString)
                            {
                                //This control is responsible for evaluating the expression,
                                //so if it can't be evaluated then return an empty string.
                                returnEmptyStringOnFail = true;
                                expression = expression.Substring(expression.IndexOf(":") + 1);
                            }
                            else
                            {
                                //It's not for this control to evaluate so skip.
                                skip = true;
                            }
                        }

                        if (!skip)
                        {
                            bool bUrlEncode = true;
                            if (StringUtils.InvariantLCase(expression).StartsWith(StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))
                            {
                                bUrlEncode = false;
                                expression = expression.Substring(PREFIX_NO_ENCODE.Length);
                            }
                            object result = null;
                            try
                            {
                                if (rec != null)
                                {
                                    result = ((IRecord)rec).EvaluateExpression(expression);
                                }
                            }
                            catch (Exception)
                            {
                                //Fall through
                            }

                            if (result != null)
                            {
                                result = result.ToString();
                            }
                            if (result == null)
                            {
                                if (!returnEmptyStringOnFail)
                                {
                                    return finalRedirectUrl;
                                }
                                else
                                {
                                    result = string.Empty;
                                }
                            }
                            
                            if (bUrlEncode)
                            {
                                result = System.Web.HttpUtility.UrlEncode((string)result);
                                if (result == null)
                                {
                                    result = string.Empty;
                                }
                            }
                            if (bEncrypt)
                            {
                                if (result != null)
                                {
                                    result = ((BaseApplicationPage)this.Page).Encrypt((string)result);
                                }
                            }
                            finalRedirectUrl = finalRedirectUrl.Replace("{" + origExpression + "}", (string)result);
                        }
                    }
                }

                //If there are still expressions to evaluate. Forward to the page for further processing.
                return finalRedirectUrl;
            }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, Object rec, bool bEncrypt, bool includeSession)
        {
            const string PREFIX_NO_ENCODE = "NoUrlEncode:";

            string finalRedirectUrl = redirectUrl;
            string finalRedirectArgument = redirectArgument;

            if ((finalRedirectUrl == null || finalRedirectUrl.Length == 0))
            {
                return finalRedirectUrl;
            }
            else if (finalRedirectUrl.IndexOf('{') < 0)
            {
                return finalRedirectUrl;
            }
            else
            {
                //The old way was to pass separate URL and arguments and use String.Format to
                //do the replacement. Example:
                // URL: EditProductsRecord?Products={0}
                // Argument: PK
                //The new way to is pass the arguments directly in the URL. Example:
                // URL: EditProductsRecord?Products={PK}
                //If the old way is passsed, convert it to the new way.
                if (finalRedirectArgument != null && finalRedirectArgument.Length > 0)
                {
                    string[] arguments = finalRedirectArgument.Split(',');
                    for (int i = 0; i <= (arguments.Length - 1); i++)
                    {
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + i.ToString() + "}", "{" + arguments[i] + "}");
                    }
                    finalRedirectArgument = "";
                }

                //Evaluate all of the expressions in the RedirectURL
                //Expressions can be of the form [ControlName:][NoUrlEncode:]Key[:Value]
                string remainingUrl = finalRedirectUrl;

                while ((remainingUrl.IndexOf('{') >= 0) & (remainingUrl.IndexOf('}') > 0) & (remainingUrl.IndexOf('{') < remainingUrl.IndexOf('}')))
                {

                    int leftIndex = remainingUrl.IndexOf('{');
                    int rightIndex = remainingUrl.IndexOf('}');
                    string expression = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                    string origExpression = expression;
                    remainingUrl = remainingUrl.Substring(rightIndex + 1);

                    bool skip = false;
                    bool returnEmptyStringOnFail = false;
                    string prefix = null;

                    //Check to see if this control must evaluate the expression
                    if ((expression.IndexOf(":") > 0))
                    {
                        prefix = expression.Substring(0, expression.IndexOf(":"));
                    }
                    if ((prefix != null) && (prefix.Length > 0) && (!(StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE))) && (!BaseRecord.IsKnownExpressionPrefix(prefix)))
                    {

                        //Remove the ASCX Prefix
                        string IdString = this.ID;
                        if (IdString.StartsWith("_"))
                        {
                            IdString = IdString.Remove(0, 1);
                        }
                        //The prefix is a control name.
                        if (prefix == IdString)
                        {
                            //This control is responsible for evaluating the expression,
                            //so if it can't be evaluated then return an empty string.
                            returnEmptyStringOnFail = true;
                            expression = expression.Substring(expression.IndexOf(":") + 1);
                        }
                        else
                        {
                            //It's not for this control to evaluate so skip.
                            skip = true;
                        }
                    }

                    if (!skip)
                    {
                        bool bUrlEncode = true;
                        if (StringUtils.InvariantLCase(expression).StartsWith(StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))
                        {
                            bUrlEncode = false;
                            expression = expression.Substring(PREFIX_NO_ENCODE.Length);
                        }
                        object result = null;
                        try
                        {
                            if (rec != null)
                            {
                                result = ((IRecord)rec).EvaluateExpression(expression);
                            }
                        }
                        catch (Exception)
                        {
                            //Fall through
                        }

                        if (result != null)
                        {
                            result = result.ToString();
                        }
                        if (result == null)
                        {
                            if (!returnEmptyStringOnFail)
                            {
                                return finalRedirectUrl;
                            }
                            else
                            {
                                result = string.Empty;
                            }
                        }

                        if (bUrlEncode)
                        {
                            result = System.Web.HttpUtility.UrlEncode((string)result);
                            if (result == null)
                            {
                                result = string.Empty;
                            }
                        }
                        if (bEncrypt)
                        {
                            if (result != null)
                            {
                                if(includeSession)
                                {
                                    result = ((BaseApplicationPage)this.Page).Encrypt((string)result);
                                }
                                else
                                {
                                    result = BaseFormulaUtils.EncryptData((string)result);
                                }
                            }
                        }
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + origExpression + "}", (string)result);
                    }
                }
            }

            //If there are still expressions to evaluate. Forward to the page for further processing.
            return finalRedirectUrl;
        }
    
        public bool AreAnyUrlParametersForMe(string url, string arg)
        {
            const string PREFIX_NO_ENCODE = "NoUrlEncode:";
            string finalRedirectUrl = url;
            string finalRedirectArgument = url;
            bool skip = false;
            if (finalRedirectArgument != null && finalRedirectArgument.Length > 0)
            {
                string[] arguments = finalRedirectArgument.Split(',');
                for (int i = 0; i <= (arguments.Length - 1); i++)
                {
                    finalRedirectUrl = finalRedirectUrl.Replace("{" + i.ToString() + "}", "{" + arguments[i] + "}");
                }
                finalRedirectArgument = "";
            }
            // Evaluate all of the expressions in the RedirectURL
            // Expressions can be of the form [ControlName:][NoUrlEncode:]Key[:Value]
            string remainingUrl = finalRedirectUrl;
            while ((remainingUrl.IndexOf('{') > 0) & (remainingUrl.IndexOf('}') > 0) & (remainingUrl.IndexOf('{') < remainingUrl.IndexOf('}')))
            {
                int leftIndex = remainingUrl.IndexOf('{');
                int rightIndex = remainingUrl.IndexOf('}');
                string expression = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                string origExpression = expression;
                remainingUrl = remainingUrl.Substring(rightIndex + 1);
                string prefix = null;
                if (expression.IndexOf(":") > 0)
                {
                    prefix = expression.Substring(0, expression.IndexOf(":"));
                }
                if ((prefix != null) && (prefix.Length > 0) && (!((StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))) && (!(BaseRecord.IsKnownExpressionPrefix(prefix))))
                {
                    if (prefix == this.ID)
                    {
                        skip = false;
                        break;
                    }
                    else
                    {
                        skip = true;
                    }
                }
            }

            if (skip)
            {
                return false;
            }

            return true;

        }

        #region " Methods to manage saving and retrieving control values to session. "

        protected void Control_SaveControls_Unload(object sender, EventArgs e)
        {
            if (((BaseApplicationPage)(this.Page)).ShouldSaveControlsToSession)
            {
                this.SaveControlsToSession();
            }
        }

        protected virtual void SaveControlsToSession()
        {
        }

        protected void Control_ClearControls_PreRender(object sender, EventArgs e)
        {
            this.ClearControlsFromSession();
        }

        protected virtual void ClearControlsFromSession()
        {
        }

        public void SaveToSession(Control control, string value)
        {
            SaveToSession(control.UniqueID, value);
        }

        public string GetFromSession(Control control, string defaultValue)
        {
            return GetFromSession(control.UniqueID, defaultValue);
        }

        public string GetFromSession(Control control)
        {
            return GetFromSession(control.UniqueID, null);
        }

        public void RemoveFromSession(Control control)
        {
            RemoveFromSession(control.UniqueID);
        }

        public bool InSession(Control control)
        {
            return InSession(control.UniqueID);
        }

        public void SaveToSession(Control control, string variable, string value)
        {
            SaveToSession(control.UniqueID + variable, value);
        }

        public string GetFromSession(Control control, string variable, string defaultValue)
        {
            return GetFromSession(control.UniqueID + variable, defaultValue);
        }

        public void RemoveFromSession(Control control, string variable)
        {
            RemoveFromSession(control.UniqueID + variable);
        }

        public bool InSession(Control control, string variable)
        {
            return InSession(control.UniqueID + variable);
        }

        public void SaveToSession(string name, string value)
        {
            this.Page.Session[GetValueKey(name)] = value;
        }

        public string GetFromSession(string name, string defaultValue)
        {
            string value = ((string)(this.Page.Session[GetValueKey(name)]));
            if (value == null || value.Length == 0)
            {
                value = defaultValue;
            }
            return value;
        }

        public string GetFromSession(string name)
        {
            return GetFromSession(name, null);
        }

        public void RemoveFromSession(string name)
        {
            this.Page.Session.Remove(GetValueKey(name));
        }

        public bool InSession(string name)
        {
            return (!(this.Page.Session[GetValueKey(name)] == null));
        }

        public string GetValueKey(string name)
        {
            return this.Page.Session.SessionID + this.Page.AppRelativeVirtualPath + name;
        }
        /// <summary>
        /// This function returns the list of record controls within the table control.
        /// There is a more specific GetRecordControls function generated in the 
        /// derived classes, but in some cases, we do not know the specific type of
        /// the table control, so we need to call this method. This is also used by the
        /// Formula evaluator to perform Sum, Count and CountA functions.
        /// </summary>
        public BaseApplicationRecordControl[] GetBaseRecordControls()
        {
            ArrayList recList = new ArrayList();

            // First get the repeater inside the Table Control.
            System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)this.FindControl(this.RepeaterName);
            if ((rep == null) || (rep.Items == null)) return null;

            // We now go inside the repeater to find all the record controls. 
            // Note that we only find the first level record controls. We do not
            // descend down and find other record controls belonging to tables-inside-table.

            foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
            {
                BaseApplicationRecordControl recControl = (BaseApplicationRecordControl)repItem.FindControl(this.RowName);
                if (!((recControl == null))) recList.Add(recControl);
            }

            return (BaseApplicationRecordControl[])recList.ToArray(typeof(BaseApplicationRecordControl));
        }

        /// <summary>
        /// Sum the values of the displayed controls. The controlName must be
        /// a textbox, label or literal.
        /// This function is called as [Products]TableControl.SUM("UnitPrice").
        /// To make sure all the formula functions are in the same location, we call
        /// the SUM function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public decimal Sum(string controlName)
        {
            return FormulaUtils.Sum(this, controlName);
        }

        /// <summary>
        /// Sum the values of the displayed controls.  The controlName must be
        /// a textbox, label or literal.
        /// This function is called as [Products]TableControl.TOTAL("UnitPrice").
        /// To make sure all the formula functions are in the same location, we call
        /// the TOTAL function in the FormulaUtils class, which actually does the work
        /// and return the value.  The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total of adding the value contained in each of the fields.</returns>
        public decimal Total(string controlName)
        {
            return FormulaUtils.Total(this, controlName);
        }

        /// <summary>
        /// Finds the maximum among the values of the displayed controls.  The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.Max("UnitPrice"), not
        /// as shown here. The MAX function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The maximum among the values contained in each of the fields.</returns>
        public decimal Max(string controlName)
        {
            return FormulaUtils.Max(this, controlName);
        }        

        /// <summary>
        /// Finds the minimum among the values of the displayed controls.  The ctlName must be
        /// a textbox, label or literal.
        /// This function should be called as [Products]TableControl.Min("UnitPrice"), not
        /// as shown here. The MIN function in the BaseApplicationTableControl will call this
        /// function to actually perform the work - so that we can keep all of the formula
        /// functions together in one place.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The minimum among the values contained in each of the fields.</returns>
        public decimal Min(string controlName)
        {
            return FormulaUtils.Min(this, controlName);
        }        

        /// <summary>
        /// Count the number of rows in the table control. 
        /// This function is called as [Products]TableControl.COUNT().
        /// To make sure all the formula functions are in the same location, we call
        /// the COUNT function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Count(string controlName)
        {
            return FormulaUtils.Count(this, controlName);
        }

        /// <summary>
        /// Count the number of rows in the table control that are non-blank.
        /// This function is called as [Products]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the COUNTA function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal CountA(string controlName)
        {
            return FormulaUtils.CountA(this, controlName);
        }

        /// <summary>
        /// Mean of the rows in the table control.
        /// This function is called as [Product]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the MEAN function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Mean(string controlName)
        {
            return FormulaUtils.Mean(this, controlName);
        }

        /// <summary>
        /// Average of the rows in the table control.
        /// This function is called as [Product]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the AVERAGE function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Average(string controlName)
        {
            return FormulaUtils.Average(this, controlName);
        }

        /// <summary>
        /// Mode of the rows in the table control.
        /// This function is called as [Product]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the MODE function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Mode(string controlName)
        {
            return FormulaUtils.Mode(this, controlName);
        }

        /// <summary>
        /// Median of the rows in the table control.
        /// This function is called as [Product]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the MEDIAN function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Median(string controlName)
        {
            return FormulaUtils.Median(this, controlName);
        }

        /// <summary>
        /// Range of the rows in the table control.
        /// This function is called as [Product]TableControl.COUNTA().
        /// To make sure all the formula functions are in the same location, we call
        /// the RANGE function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The total number of rows in the table control.</returns>
        public decimal Range(string controlName)
        {
            return FormulaUtils.Range(this, controlName);
        }
        #endregion

        /// <summary>
        /// Create javascript function, ClearSelection which is called when Clear button is clicked
        /// </summary>
        /// <remarks></remarks>
        public virtual void RegisterJSClearSelection()
        {
	        bool multiSelection = false;

	        if (!string.IsNullOrEmpty(Page.Request["Mode"])) {
		        multiSelection = (this.Page as BaseApplicationPage).GetDecryptedURLParameter("Mode") == "FieldFilterMultiSelection";
	        }


	        // qsSelectionID is a special control.  It is used to remember the current selection(s).
	        // It is not shown on the layout of Design Mode.  But you can see it by right-clicking on Design Mode and followed by Page Directives...
	        string qsSelectionID = "";
	        BaseClasses.Web.UI.WebControls.QuickSelector qsSelection = (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this.Page, "QSSelection");
	        if (qsSelection != null) {
		        qsSelectionID = qsSelection.ClientID;
	        }
	        String csName = "ClearSelection";
	        Type csType = this.GetType();

	        // Get a ClientScriptManager reference from the Page class.
	        ClientScriptManager cs = Page.ClientScript;
	        if (!cs.IsClientScriptBlockRegistered(csType, csName)) {
		        System.Text.StringBuilder csText = new System.Text.StringBuilder();
		        csText.AppendLine("<script type=\"text/javascript\"> function ClearSelection() {");

		        // Clear the selection from QSSelection control 
		        csText.AppendLine("updateQuickSelectorItems('" + qsSelectionID + "', new Array(), 'Replace', false);");

		        if (multiSelection) {
			        // if it is multi selection, remove clear the row hightlight by changing the class name.
			        csText.AppendLine("replaceClassName('tr', 'QStrSelected', 'QStr');");
		        } else {
			        // if it is single selection, close the popup.
			        csText.AppendLine("CommitSelection();");
		        }
		        csText.AppendLine("} ");
		        csText.AppendLine("</script>");
		        cs.RegisterClientScriptBlock(csType, csName, csText.ToString());
	        }
        }


        /// <summary>
        /// Create javascript function, CommitSelection which is called when OK button is clicked
        /// </summary>
        /// <remarks></remarks>
        public virtual void RegisterJSCommitSelection()
        {
	        string emptyValue = "";
	        string emptyDisplayText = "";
	        string target = "";
	        if (!string.IsNullOrEmpty(Page.Request["Target"])) {
		        target = ((BaseApplicationPage)this.Page).GetDecryptedURLParameter("Target");
	        }

	        if (!string.IsNullOrEmpty(Page.Request["EmptyValue"])) {
		        emptyValue = ((BaseApplicationPage)this.Page).GetDecryptedURLParameter("EmptyValue");
	        }
	        if (!string.IsNullOrEmpty(Page.Request["EmptyDisplayText"])) {
		        emptyDisplayText = ((BaseApplicationPage)this.Page).GetDecryptedURLParameter("EmptyDisplayText");
	        }


	        string qsSelectionID = "";
	        BaseClasses.Web.UI.WebControls.QuickSelector qsSelection = (BaseClasses.Web.UI.WebControls.QuickSelector)BaseClasses.Utils.MiscUtils.FindControlRecursively(this.Page, "QSSelection");
	        if (qsSelection != null) {
		        qsSelectionID = qsSelection.ClientID;
	        }
	        String csName = "CommitSelection";
	        Type csType = this.GetType();

	        // Get a ClientScriptManager reference from the Page class.
	        // Create CommitSelection function.  QSSelection has no selected items, Update the target control to be --PLEASE_SELECT--
	        ClientScriptManager cs = Page.ClientScript;
	        if (!cs.IsClientScriptBlockRegistered(csType, csName)) {
		        System.Text.StringBuilder csText = new System.Text.StringBuilder();
		        string valueID = qsSelectionID + "_Value";
		        csText.AppendLine("<script type=\"text/javascript\"> function CommitSelection() {");
		        csText.AppendLine("     var w = getParentWindow();");
		        csText.AppendLine("     if (w == window) {return;}");
		        csText.AppendLine("     var listItems = new Array()");
		        csText.AppendLine("     var valCtrl = document.getElementById('" + valueID + "');");
		        csText.AppendLine("     if (valCtrl.value != '') {");
		        csText.AppendLine("         listItems = JSON.parse(valCtrl.value).List;");
		        csText.AppendLine("     }");
		        csText.AppendLine("     if (listItems.length == 0){");
		        csText.AppendLine("         w.updateQuickSelectorItem('" + target + "', '" + emptyValue + "', '" + emptyDisplayText + "', 'Replace', true);");
		        csText.AppendLine("     }");
		        csText.AppendLine("     else {");
		        csText.AppendLine("         w.updateQuickSelectorItems('" + target + "', listItems, 'Replace', true);");
		        csText.AppendLine("     } ");
		        csText.AppendLine("} ");
		        csText.AppendLine("</script>");
		        cs.RegisterClientScriptBlock(csType, csName, csText.ToString());
	        }
        }

        /// <summary>
        /// Method will loop through the literal controls inside the repeater.
        /// Assign the id value if found the duplicate items
        /// </summary>
        /// <param name="ids">Name of the literal controls who has duplicate values</param>
        public virtual void InitializeDuplicateItems(ArrayList ids)
        {
            if (ids.Count == 0) return;

            ArrayList listOfDups = new ArrayList();
            ListItemCollection itemsList = new ListItemCollection();
            int index = 0;

            if (ids.Count == 1)
            {
                System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, this.RepeaterName));
                foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
                {
                    PrimaryKeyRecord pkRecord = ((PrimaryKeyRecord)(this._DataSource[index]));
                    BaseApplicationRecordControl recControl = (BaseApplicationRecordControl)(repItem.FindControl(this.RowName));
                    foreach (System.Web.UI.Control ctrlItem in recControl.Controls)
                    {
                        Literal ltlCtrl;
                        Label lblCtrl;
                        LinkButton lbtnCtrl;
                        string txtValue = "";
                        if (ctrlItem.ID == ids[0].ToString())
                        {
                            if (ctrlItem is System.Web.UI.WebControls.Literal)
                            {
                                ltlCtrl = (System.Web.UI.WebControls.Literal)(ctrlItem);
                                txtValue = ltlCtrl.Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.Label)
                            {
                                lblCtrl = (System.Web.UI.WebControls.Label)(ctrlItem);
                                txtValue = lblCtrl.Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.LinkButton)
                            {
                                lbtnCtrl = (System.Web.UI.WebControls.LinkButton)(ctrlItem);
                                txtValue = lbtnCtrl.Text;
                            }

                            if (txtValue != "")
                            {
                                ListItem dupItem = itemsList.FindByText(txtValue);
                                if (dupItem != null)
                                {
                                    listOfDups.Add(dupItem.Text);
                                    dupItem.Text = dupItem.Text + " (ID " + dupItem.Value + ")";
                                }

                                ListItem newItem = new ListItem(txtValue, pkRecord.GetID().ToDisplayString());
                                itemsList.Add(newItem);

                                if (listOfDups.Contains(newItem.Text))
                                {
                                    newItem.Text = newItem.Text + " (ID " + newItem.Value + ")";
                                }
                                break;
                            }
                        }
                    }
                    index++;
                }

                index = 0;
                foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
                {
                    BaseApplicationRecordControl recControl = (BaseApplicationRecordControl)(repItem.FindControl(this.RowName));
                    foreach (System.Web.UI.Control ctrlItem in recControl.Controls)
                    {
                        if (ctrlItem.ID == ids[0].ToString())
                        {
                            if (ctrlItem is System.Web.UI.WebControls.Literal && itemsList.Count != 0)
                            {
                                Literal ltCtrl = (System.Web.UI.WebControls.Literal)(ctrlItem);
                                ltCtrl.Text = itemsList[index].Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.Label && itemsList.Count != 0)
                            {
                                Label ltCtrl = (System.Web.UI.WebControls.Label)(ctrlItem);
                                ltCtrl.Text = itemsList[index].Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.LinkButton && itemsList.Count != 0)
                            {
                                LinkButton ltCtrl = (System.Web.UI.WebControls.LinkButton)(ctrlItem);
                                ltCtrl.Text = itemsList[index].Text;
                            }
                        }
                    }
                    index++;
                }
            }
            else if (ids.Count == 2)
            {
                System.Web.UI.WebControls.Repeater rep = (System.Web.UI.WebControls.Repeater)(BaseClasses.Utils.MiscUtils.FindControlRecursively(this, this.RepeaterName));
                foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
                {
                    int count = 0;
                    string ltText = "";
                    PrimaryKeyRecord pkRecord = ((PrimaryKeyRecord)(this._DataSource[index]));
                    BaseApplicationRecordControl recControl = (BaseApplicationRecordControl)(repItem.FindControl(this.RowName));
                    foreach (System.Web.UI.Control ctrlItem in recControl.Controls)
                    {
                        if (ctrlItem.ID == ids[0].ToString() || ctrlItem.ID == ids[1].ToString())
                        {
                            if (ctrlItem is System.Web.UI.WebControls.Literal)
                            {
                                Literal ltCtrl = (System.Web.UI.WebControls.Literal)(ctrlItem);
                                ltText += ltCtrl.Text;

                                count++;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.Label)
                            {
                                Label ltCtrl = (System.Web.UI.WebControls.Label)(ctrlItem);
                                ltText += ltCtrl.Text;

                                count++;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.LinkButton)
                            {
                                LinkButton ltCtrl = (System.Web.UI.WebControls.LinkButton)(ctrlItem);
                                ltText += ltCtrl.Text;

                                count++;
                            }
                        }
                                           
                        if (count == ids.Count) 
                        {
                            ListItem dupItem = itemsList.FindByText(ltText);
                            if (dupItem != null)
                            {
                                listOfDups.Add(dupItem.Text);
                                dupItem.Text = " (ID " + dupItem.Value + ")";
                            }

                            ListItem newItem = new ListItem(ltText, pkRecord.GetID().ToDisplayString());
                            itemsList.Add(newItem);

                            if (listOfDups.Contains(newItem.Text))
                            {
                                newItem.Text = " (ID " + newItem.Value + ")";
                            }
                            break;
                        }                        
                    }
                    index++;
                }
                
                index = 0;
                foreach (System.Web.UI.WebControls.RepeaterItem repItem in rep.Items)
                {
                    BaseApplicationRecordControl recControl = (BaseApplicationRecordControl)(repItem.FindControl(this.RowName));
                    foreach (System.Web.UI.Control ctrlItem in recControl.Controls)
                    {
                        if ((ctrlItem.ID == ids[0].ToString() || ctrlItem.ID == ids[1].ToString()) && itemsList.Count != 0)
                        {
                            if (ctrlItem is System.Web.UI.WebControls.Literal && itemsList[index].Text.Contains(" (ID "))
                            {
                                Literal ltCtrl = (System.Web.UI.WebControls.Literal)(ctrlItem);
                                ltCtrl.Text = ltCtrl.Text + itemsList[index].Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.Label && itemsList[index].Text.Contains(" (ID "))
                            {
                                Label ltCtrl = (System.Web.UI.WebControls.Label)(ctrlItem);
                                ltCtrl.Text = ltCtrl.Text + itemsList[index].Text;
                            }
                            else if (ctrlItem is System.Web.UI.WebControls.LinkButton && itemsList[index].Text.Contains(" (ID "))
                            {
                                LinkButton ltCtrl = (System.Web.UI.WebControls.LinkButton)(ctrlItem);
                                ltCtrl.Text = ltCtrl.Text + itemsList[index].Text;
                            }
                        }
                    }
                    index++;
                }
            }
        }

        protected BaseRecord[] _DataSource;

        protected int _AddNewRecord = 0;
        public virtual int AddNewRecord {
	        get { return this._AddNewRecord; }
	        set { this._AddNewRecord = value; }
        }

        protected bool _DataChanged = false;
        public virtual bool DataChanged {
	        get { return this._DataChanged; }
	        set { this._DataChanged = value; }
        }

        protected bool _ResetData = false;
        public virtual bool ResetData {
	        get { return this._ResetData; }
	        set { this._ResetData = value; }
        }

        protected System.Collections.Generic.List<Hashtable> _UIData = new System.Collections.Generic.List<Hashtable>();
        public virtual System.Collections.Generic.List<Hashtable> UIData 
        {
            get {
                return this._UIData;
            }
            set {
                this._UIData = value;
            }
        }

        // verify the processing details for these properties
        protected int _PageSize;
        public virtual int PageSize 
        {
            get {
                return this._PageSize;
            }
            set {
                this._PageSize = value;
            }
        }

        protected int _PageIndex;
        public virtual int PageIndex 
        {
            get {
                return this._PageIndex;
            }
            set {
                this._PageIndex = value;
            }
        }

        private void BaseLoad(object sender, System.EventArgs e)
        {
	        System.Web.UI.WebControls.HiddenField c = (System.Web.UI.WebControls.HiddenField)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, this.ID + "_PostbackTracker");
	        if (c != null) {
		        c.ValueChanged += Postback;
	        }
        }



        private void Postback(object sender, EventArgs e)
        {
	        this.DataChanged = true;
        }
    }
}