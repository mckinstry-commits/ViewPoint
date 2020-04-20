using System;
using System.Web.UI;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using System.Collections;
using System.Web.UI.WebControls;
using POViewer.Data;

namespace POViewer.UI
{
    public class BaseApplicationRecordControl : System.Web.UI.Control
    {
        public BaseApplicationRecordControl()
        {
            this.PreRender += new EventHandler(Control_ClearControls_PreRender);
            this.Unload += new EventHandler(Control_SaveControls_Unload);
			this.Load += new EventHandler(BaseLoad);
        }

        // Allow for migration from earlier versions which did not have url encryption.
        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument)
        {
            throw new Exception("This function should be implemented by inherited record control class.");
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            throw new Exception("This function should be implemented by inherited record control class.");
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt,bool includeSession)
        {
            throw new Exception("This function should be implemented by inherited record control class.");
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            throw new Exception("This function should be implemented by inherited record control class.");
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt, bool includeSession)
        {
            throw new Exception("This function should be implemented by inherited record control class.");
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

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, Object rec, bool bEncrypt,bool includeSession)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, rec, bEncrypt,includeSession);
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
            else if ((finalRedirectUrl.IndexOf('{') < 0))
            {
                return finalRedirectUrl;
            }
            else
            {
                // The old way was to pass separate URL and arguments and use String.Format to
                // do the replacement.  Example:
                // URL:        EditProductsRecord?Products={0}
                // Argument:   PK
                // The new way to is pass the arguments directly in the URL.  Example:
                // URL:        EditProductsRecord?Products={PK}
                // If the old way is passsed, convert it to the new way.
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
                    // Check to see if this control must evaluate the expression
                    if ((expression.IndexOf(":") > 0))
                    {
                        prefix = expression.Substring(0, expression.IndexOf(":"));
                    }
                    if ((prefix != null) && (prefix.Length > 0) && (!((StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))) && (!(BaseRecord.IsKnownExpressionPrefix(prefix))))
                    {
                       // Remove the ASCX Prefix
                        string IdString = this.ID;
                        if (IdString.StartsWith("_"))
                        {
                            IdString = IdString.Remove(0, 1);
                        }
                        // The prefix is a control name.
                        if (prefix == IdString)
                        {
                            // This control is responsible for evaluating the expression,
                            // so if it can't be evaluated then return an empty string.
                            returnEmptyStringOnFail = true;
                            expression = expression.Substring(expression.IndexOf(":") + 1);
                        }
                        else
                        {
                            // It's not for this control to evaluate so skip.
                            skip = true;
                        }
                    }
                    if (!skip)
                    {
                        bool bUrlEncode = true;
                        if ((StringUtils.InvariantLCase(expression).StartsWith(StringUtils.InvariantLCase(PREFIX_NO_ENCODE))))
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
                        catch (Exception )
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
                        if ((bUrlEncode))
                        {
                            result = System.Web.HttpUtility.UrlEncode(((string)(result)));
                            if (result == null)
                            {
                                result = string.Empty;
                            }
                        }
                        if(bEncrypt) {
                            if(result!= null) {
                                result = ((BaseApplicationPage)(this.Page)).Encrypt((string)result);
                            }
                        }
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + origExpression + "}", ((string)(result)));
                    }
                }
            }
            // If there are still expressions to evaluate. Forward to the page for further processing.
            return finalRedirectUrl;
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, Object rec, bool bEncrypt,bool includeSession)
        {
            const string PREFIX_NO_ENCODE = "NoUrlEncode:";
            string finalRedirectUrl = redirectUrl;
            string finalRedirectArgument = redirectArgument;
            if ((finalRedirectUrl == null || finalRedirectUrl.Length == 0))
            {
                return finalRedirectUrl;
            }
            else if ((finalRedirectUrl.IndexOf('{') < 0))
            {
                return finalRedirectUrl;
            }
            else
            {
                // The old way was to pass separate URL and arguments and use String.Format to
                // do the replacement.  Example:
                // URL:        EditProductsRecord?Products={0}
                // Argument:   PK
                // The new way to is pass the arguments directly in the URL.  Example:
                // URL:        EditProductsRecord?Products={PK}
                // If the old way is passsed, convert it to the new way.
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
                    // Check to see if this control must evaluate the expression
                    if ((expression.IndexOf(":") > 0))
                    {
                        prefix = expression.Substring(0, expression.IndexOf(":"));
                    }
                    if ((prefix != null) && (prefix.Length > 0) && (!((StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))) && (!(BaseRecord.IsKnownExpressionPrefix(prefix))))
                    {
                        // Remove the ASCX Prefix
                        string IdString = this.ID;
                        if (IdString.StartsWith("_"))
                        {
                            IdString = IdString.Remove(0, 1);
                        }
                        // The prefix is a control name.
                        if (prefix == IdString)
                        {
                            // This control is responsible for evaluating the expression,
                            // so if it can't be evaluated then return an empty string.
                            returnEmptyStringOnFail = true;
                            expression = expression.Substring(expression.IndexOf(":") + 1);
                        }
                        else
                        {
                            // It's not for this control to evaluate so skip.
                            skip = true;
                        }
                    }
                    if (!skip)
                    {
                        bool bUrlEncode = true;
                        if ((StringUtils.InvariantLCase(expression).StartsWith(StringUtils.InvariantLCase(PREFIX_NO_ENCODE))))
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
                        if ((bUrlEncode))
                        {
                            result = System.Web.HttpUtility.UrlEncode(((string)(result)));
                            if (result == null)
                            {
                                result = string.Empty;
                            }
                        }
                        if (bEncrypt)
                        {
                            if (result != null)
                            {
                                if (includeSession)
                                {
                                    result = ((BaseApplicationPage)(this.Page)).Encrypt((string)result);
                                }
                                else
                                {
                                    result = BaseFormulaUtils.EncryptData((string)result);
                                }
                            }
                        }
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + origExpression + "}", ((string)(result)));
                    }
                }
            }
            // If there are still expressions to evaluate. Forward to the page for further processing.
            return finalRedirectUrl;
        }

        /// <summary>
        /// Get the Id of the parent table control.  We navigate up the chain of
        /// controls until we find the table control.  Note that the first table
        /// control above the record control would be the parent.  You cannot have
        /// a record control embedded in a different parent control other than its parent.
        /// </summary>
        /// <returns>The Id of the parent table control.</returns>
        protected virtual string GetParentTableControlID()
        {
            try
            {
                if (this.Parent is BaseApplicationTableControl) return this.Parent.ID;
                if (this.Parent.Parent is BaseApplicationTableControl) return this.Parent.Parent.ID;
                if (this.Parent.Parent.Parent is BaseApplicationTableControl) return this.Parent.Parent.Parent.ID;
                if (this.Parent.Parent.Parent.Parent is BaseApplicationTableControl) return this.Parent.Parent.Parent.Parent.ID;
            }
            catch (Exception)
            {
            }
            return "";
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
            if (value == null || value.Trim() == "")
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
        /// Get the parent table control. We navigate up the chain of
        /// controls until we find the table control. Note that the first table
        /// control above the record control would be the parent. You cannot have
        /// a record control embedded in a different parent control other than its parent.
        /// </summary>
        /// <returns>The Id of the parent table control.</returns>
        public virtual BaseApplicationTableControl GetParentTableControl()
        {
            try
            {
                Control parent = this.Parent;
                while (!((parent == null)))
                {
                    if (parent is BaseApplicationTableControl)
                    {
                        return (BaseApplicationTableControl)parent;
                    }
                    parent = parent.Parent;
                }
            }
            catch (Exception)
            {
            }
            // Ignore and return Nothing
            return null;
        }

        /// <summary>
        /// The row number of this record control within the table control.
        /// This function is called as {TableName}TableControlRow.ROWNUM().
        /// To make sure all the formula functions are in the same location, we call
        /// the ROWNUM function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// The row number is 1 based.
        /// </summary>
        /// <returns>The row number of this row relative to the other rows in the table control.</returns>
        public decimal RowNum()
        {
            return FormulaUtils.RowNum(this.GetParentTableControl(), this);
        }

        /// <summary>
        /// The rank of this field relative to other fields in the table control.
        /// This function is called as {TableName}TableControlRow.RANK().
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// Their respecitive ranks will be 4, 3, 1, 2, 5
        /// To make sure all the formula functions are in the same location, we call
        /// the RANK function in the FormulaUtils class, which actually does the work
        /// and return the value. The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// The rank is 1 based.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The rank of this row relative to the other rows in the table control..</returns>
        public decimal Rank(string controlName)
        {
            return FormulaUtils.Rank(this.GetParentTableControl(), this, controlName);
        }

        /// <summary>
        /// The running total of the field.
        /// This function is called as {TableName}TableControlRow.RUNNINGTOTAL().
        /// Say there are 5 rows and they contain 57, 32, 12, 19, 98.
        /// The respecitive values for running totals will be  be 57, 89, 101, 120, 218
        /// To make sure all the formula functions are in the same location, we call
        /// the RUNNINGTOTAL function in the FormulaUtils class, which actually does the work
        /// and return the value.  The function in FormulaUtils will need to know the
        /// TableControl, so it is passed as the first instance.
        /// </summary>
        /// <param name="controlName">The string name of the UI control (e.g., "UnitPrice") </param>
        /// <returns>The running total of the row.</returns>
        public decimal RunningTotal(string controlName)
        {
            return FormulaUtils.RunningTotal(this.GetParentTableControl(), this, controlName);
        }
        #endregion


        /// <summary>
        /// Store the UI data within the current record or row control and return as hashtable
        /// </summary>
        /// <returns></returns>
        /// <remarks></remarks>
        public virtual Hashtable PreservedUIData()
        {
            // This method get the UI data within the current record and return them as Hastable
            Hashtable uiData = new Hashtable();


            Control[] controls = MiscUtils.FindControlsRecursively(this);

            foreach (Control control in controls)
            {
                if (!string.IsNullOrEmpty(control.ID) && !uiData.ContainsKey(control.ID))
                {
                    if (object.ReferenceEquals(control.GetType(), typeof(TextBox)))
                    {
                        TextBox textbox = (TextBox)control;
                        uiData.Add(textbox.ID, textbox.Text);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(Literal)))
                    {
                        Literal literal = (Literal)control;
                        uiData.Add(literal.ID, literal.Text);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(Label)))
                    {
                        Label label = (Label)control;
                        uiData.Add(label.ID, label.Text);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(CheckBox)))
                    {
                        CheckBox checkbox = (CheckBox)control;
                        uiData.Add(checkbox.ID, checkbox.Checked);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(Button)))
                    {
                        Button button = (Button)control;
                        uiData.Add(button.ID, button.Text);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(LinkButton)))
                    {
                        LinkButton linkButton = (LinkButton)control;
                        uiData.Add(linkButton.ID, linkButton.Text);
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(ListBox)))
                    {
                        ListBox listbox = (ListBox)control;
                        uiData.Add(listbox.ID, MiscUtils.GetValueSelectedPageRequest(listbox));
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(DropDownList)))
                    {
                        DropDownList dropdownList = (DropDownList)control;
                        uiData.Add(dropdownList.ID, MiscUtils.GetValueSelectedPageRequest(dropdownList));
                    }
                    else if (object.ReferenceEquals(control.GetType(), typeof(DropDownList)))
                    {
                        RadioButtonList radioButtonList = (RadioButtonList)control;
                        uiData.Add(radioButtonList.ID, MiscUtils.GetValueSelectedPageRequest(radioButtonList));
                    }
					else if (control.GetType().GetInterface("IDatePagination") != null || control.GetType().GetInterface("IDatePaginationMobile") != null) 
					{
						// Save the pagination's Interval and FirstStartDate and restore it by these values later
						System.Reflection.PropertyInfo[] props = control.GetType().GetProperties();
						Hashtable ht = new Hashtable();
						foreach (System.Reflection.PropertyInfo prop in props) 
						{
							System.ComponentModel.PropertyDescriptor descriptor = System.ComponentModel.TypeDescriptor.GetProperties(control.GetType())[prop.Name];
							if (descriptor.Name == "Interval") 
								ht.Add("Interval", prop.GetValue(control, null).ToString());
							else if (descriptor.Name == "FirstStartDate") 
								ht.Add("FirstStartDate", prop.GetValue(control, null).ToString());
						}
						uiData.Add(control.ID, ht);
	                }
				}
            }
            return uiData;
        }

        protected BaseRecord _DataSource;
        protected bool _IsNewRecord = true;
        public virtual bool IsNewRecord {
	        get { return this._IsNewRecord; }
	        set { this._IsNewRecord = value; }
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