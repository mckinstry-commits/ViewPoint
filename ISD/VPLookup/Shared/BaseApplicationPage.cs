using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Collections;
using BaseClasses.Data;
using BaseClasses.Utils;
using BaseClasses.Resources;
using VPLookup.Business; 
using VPLookup.Data;
using BaseClasses.Web.UI;

using System.Web.UI.DataVisualization.Charting;

namespace VPLookup.UI
{
    public class BaseApplicationPage : BaseClasses.Web.UI.BasePage
    {
        public BaseApplicationPage()
        {
            this.Load += new EventHandler(Page_Load);
            this.PreRender += new EventHandler(Control_ClearControls_PreRender);
            this.Unload += new EventHandler(Page_SaveControls_Unload);
            base.PreInit += new EventHandler(Page_PreInit);
            this.PreRender += new EventHandler(IncludeLegacyJavaScript);
        }

        private string _Enctype = "";
        public string Enctype
        {
            get
            {
               return this._Enctype;
            }
            set
            {
                this._Enctype = value;
            }
        }
        private void Page_Load(object sender, System.EventArgs e)
        {
            if (BaseClasses.Configuration.ApplicationSettings.Current.RestfulEnabled)
			{                
				MiscUtils.InitializeRestfulHostURL(this.Page.Request);             
            }
			
			if (!String.IsNullOrEmpty(this.Page.Request.QueryString["lat"]) && !String.IsNullOrEmpty(this.Page.Request.QueryString["lng"]))
            {
                System.Web.HttpContext.Current.Session["isd_geo_location"] = BaseFormulaUtils.BuildLocation(this.Page.Request.QueryString["lat"], this.Page.Request.QueryString["lng"]);
                System.Web.HttpContext.Current.Session["isd_geo_clear_browser_location"] = false;
            }
        }

        private void Page_PreInit(object sender, System.EventArgs e)
        {
              //assign proper theme for multicolor themes
              string selectedTheme = this.GetSelectedTheme();
              if(!string.IsNullOrEmpty(selectedTheme)) this.Page.Theme = selectedTheme;
        }

        

       //Script to set focus to the last focused control
       private const string SCRIPT_DOFOCUS = "" + "<script language=\"javascript\" type=\"text/javascript\">" + 
                            "var ctrl = \"{ControlClientID}\"; " + 
                            "function pageLoadedHandler1(sender, args) { setTimeout(\"setTimeoutFocus()\", 1000);} " + 
                            "function setTimeoutFocus() { setFocus(ctrl); }" + 
                            "Sys.WebForms.PageRequestManager.getInstance().add_pageLoaded(pageLoadedHandler1);</script>";


        public virtual void SetFocusOnLoad()
        {
            this.SetFocusOnLoad(null);
        }

        public void LoadFocusScripts(Control CurrentControl)
        {
            //not used any more, retained for compatibility with older versions
        }

        ///Sets focus to the control with ctrlClientID. If empty string is passed, sets focus to the first focusable control
        public virtual void SetFocusOnLoad(Control currentControl)
        {     
            string ctrlClientID = "";
            if(currentControl != null) {
                ctrlClientID = currentControl.ClientID;
                //currentControl.Focus();
            }       
            if (!ClientScript.IsStartupScriptRegistered(Page.GetType(), "SetFocusOnLoad")) {
                string script = SCRIPT_DOFOCUS;
                script = script.Replace("{ControlClientID}", ctrlClientID);
                ScriptManager sm = ScriptManager.GetCurrent(this.Page);
                if (!sm.IsInAsyncPostBack) {
	                ClientScript.RegisterStartupScript(Page.GetType(), "SetFocusOnLoad", script, false);
                }

            }
        }

        ///Verifies that this is editable control
        public virtual bool IsControlEditable(Control ctrl, bool includeCheckBox)
        {
            if (ctrl is System.Web.UI.WebControls.TextBox || ctrl is System.Web.UI.WebControls.DropDownList || ctrl is System.Web.UI.WebControls.ListBox || ctrl is System.Web.UI.WebControls.FileUpload) {
                return true;
            }
            else if (includeCheckBox && ctrl is System.Web.UI.WebControls.CheckBox) {
                return true;
            }
            return false;
        }

        ///Verifies that this is editable control
        public virtual bool IsControlEditable(Control ctrl)
        {
            if (ctrl is System.Web.UI.WebControls.TextBox || ctrl is System.Web.UI.WebControls.DropDownList 
               || ctrl is System.Web.UI.WebControls.ListBox || ctrl is System.Web.UI.WebControls.FileUpload
               || ctrl is System.Web.UI.WebControls.CheckBox) {
                return true;            
            }
            return false;
        }

        public string GetSelectedTheme()
        {
            //First try to get selected theme from Session
            System.Web.SessionState.HttpSessionState Session = System.Web.HttpContext.Current.Session;
            string selectedTheme = (string)Session[NetUtils.CookieSelectedTheme()];
            if (!string.IsNullOrEmpty(selectedTheme)) {
                return selectedTheme;
            }
            //There is no theme stored in session, possibly application is opened for the very first time.
            //Try to get theme from the cookie
            selectedTheme = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieSelectedTheme());
            if (!string.IsNullOrEmpty(selectedTheme)) {
                //make sure theme exists in application
                string appDir = "";
                try
                {
                    appDir = System.Web.HttpContext.Current.Server.MapPath("/");
                    if (!string.IsNullOrEmpty(appDir)) appDir = appDir + "App_Themes"; 
                }
                catch
                {
                    appDir = "";
                }
                if (string.IsNullOrEmpty(appDir))
                {
                    try
                    {
                        appDir = System.Web.HttpContext.Current.Server.MapPath("");
                        if (!string.IsNullOrEmpty(appDir))
                            if (System.IO.Directory.GetParent(appDir)!=null)
                            {
                                appDir = System.IO.Directory.GetParent(appDir).FullName + "\\App_Themes";
                            }
                            else if (appDir.IndexOf("\\") > 0) appDir = appDir.Substring(0, appDir.LastIndexOf("\\")) + "\\App_Themes";
                            else appDir = "";
                    }
                    catch
                    {
                        appDir = "";
                    }
                }
                if (!string.IsNullOrEmpty(appDir) && System.IO.Directory.Exists(appDir))
                {
                    if (System.IO.Directory.Exists(System.IO.Path.Combine(appDir, selectedTheme)))
                    {
                        Session[NetUtils.CookieSelectedTheme()] = selectedTheme;
                        return selectedTheme;
                    }
                    else
                    {
                        BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieSelectedTheme(), "");
                    }
                }
            }
            
            return "";
        }

         protected void IncludeLegacyJavaScript(Object sender , EventArgs e){
            string scriptKey = "LegacyFunctions.js";
            if (!this.ClientScript.IsClientScriptBlockRegistered(scriptKey)){
                string scriptPath = BaseClasses.Configuration.ApplicationSettings.Current.AppRootPath + "LegacyFunctions.js";
                string script= BaseClasses.Web.AspxTextWriter.CreateJScriptExternalScriptReferenceBlock(scriptPath);
                this.ClientScript.RegisterClientScriptBlock(Page.GetType(), scriptKey, script);
            }
        }

        
        //Retrieve selected language from session or cookie
        public string GetSelectedLanguage()
        {
            //First try to get selected language from Session
            System.Web.SessionState.HttpSessionState Session = System.Web.HttpContext.Current.Session;
            string selectedLanguage = (string)Session["AppCultureUI"];
            if (!string.IsNullOrEmpty(selectedLanguage)) return selectedLanguage;
            //There is no theme stored in session, possibly application is opened for the very first time.
            //Try to get theme from the cookie
            selectedLanguage = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieSelectedLanguage());
            if (!string.IsNullOrEmpty(selectedLanguage))
            {
                try
                {
                    System.Globalization.CultureInfo culInfo = new System.Globalization.CultureInfo(selectedLanguage);
                    Session["AppCultureUI"] = selectedLanguage;
                    return selectedLanguage;
                }
                catch
                {
                    //if exception happened this language is not supported
                    BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieSelectedLanguage(), "");
                    selectedLanguage = System.Threading.Thread.CurrentThread.CurrentUICulture.Name;
                    Session["AppCultureUI"] = selectedLanguage;
                }
            }
            else
            {
                selectedLanguage = System.Threading.Thread.CurrentThread.CurrentUICulture.Name;
                Session["AppCultureUI"] = selectedLanguage;
            }


            return selectedLanguage;
        }

        private bool _modifyRedirectUrlInProgress = false;

        // Constant used for EvaluateExpressions
        const string PREFIX_NO_ENCODE = "NoUrlEncode:";

        // Allow for migration from earlier versions which did not have url encryption.
        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, false);
        }

        public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, bEncrypt);
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, bEncrypt, this);
        }



          public virtual string ModifyRedirectUrl(string redirectUrl, string redirectArgument, bool bEncrypt, bool includeSession)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, bEncrypt, includeSession);
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt, bool includeSession)
        {
            return EvaluateExpressions(redirectUrl, redirectArgument, bEncrypt, this, includeSession);
        }
        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt, Control targetCtl,bool includeSession)
        {
            if ((_modifyRedirectUrlInProgress))
            {
                return null;
            }
            else
            {
                _modifyRedirectUrlInProgress = true;
            }
            string finalRedirectUrl = redirectUrl;
            string finalRedirectArgument = redirectArgument;



            string remainingUrl = finalRedirectUrl;


            // encrypt constant value
            if (bEncrypt && targetCtl.GetType() == Page.GetType())
            {
                remainingUrl += "&";
                finalRedirectUrl += "&";

                while ((remainingUrl.IndexOf('=') >= 0) && (remainingUrl.IndexOf('&') > 0) && (remainingUrl.IndexOf('=') < remainingUrl.IndexOf('&')))
                {
                    int leftIndex = remainingUrl.IndexOf('=');
                    int rightIndex = remainingUrl.IndexOf('&');
                    string encryptFrom = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                    remainingUrl = remainingUrl.Substring(rightIndex + 1);
                    if (!encryptFrom.StartsWith("{") || !encryptFrom.EndsWith("}"))
                    {
                        // check if it is already encrypted
                        bool isEncrypted = false;
                        try
                        {
                            if (Decrypt(encryptFrom) != "")
                                isEncrypted = true;
                        }
                        catch
                        {
                        }

                        // if not, process encryption
                        if (!isEncrypted)
                        {
                            string encryptTo = BaseFormulaUtils.EncryptData(encryptFrom as string);
                            finalRedirectUrl = finalRedirectUrl.Replace("=" + encryptFrom + "&", "=" + encryptTo + "&");
                        }
                    }
                }

                finalRedirectUrl = finalRedirectUrl.Trim('&');
            }



            if ((finalRedirectUrl == null) || (finalRedirectUrl.Length == 0))
            {
                return "";
            }
            else if ((finalRedirectUrl.IndexOf('{') < 0))
            {
                _modifyRedirectUrlInProgress = false;
                return finalRedirectUrl;
            }
            else
            {
                if (redirectArgument != null && redirectArgument.Length > 0)
                {
                    string[] arguments = redirectArgument.Split(',');
                    for (int i = 0; i <= (arguments.Length - 1); i++)
                    {
                        finalRedirectUrl = finalRedirectUrl.Replace("{" + i.ToString() + "}", "{" + arguments[i] + "}");
                    }
                    finalRedirectArgument = "";
                }
                ArrayList controlList = new ArrayList();
                GetAllRecordAndTableControls(targetCtl, controlList, true);
                if (controlList.Count == 0)
                {
                    return finalRedirectUrl;
                }
                Hashtable controlIdList = new Hashtable();

                bool found = false;
                foreach (System.Web.UI.Control control in controlList)
                {
                    string uID = control.UniqueID;
                    int pageContentIndex = uID.IndexOf("$PageContent$");
                    if (pageContentIndex > 0)
                    {
                        if (found == false)
                        {
                            //Remove all controls without $PageContent$ prefix, because this page is used with Master Page
                            //and these entries are irrelevant
                            controlIdList.Clear();
                        }
                        found = true;
                    }
                    if (found)
                    {
                        //If we found that Master Page is used for this page construction than disregard all controls
                        //without $PageContent$ prefix
                        if (pageContentIndex > 0)
                        {
                            uID = uID.Substring(pageContentIndex + "$PageContent$".Length);
                            controlIdList.Add(uID, control);
                        }
                    }
                    else
                    {
                        //No Master Page presense found so far
                        controlIdList.Add(uID, control);
                    }
                }

                ArrayList forwardTo = new ArrayList();

                remainingUrl = finalRedirectUrl;
                while ((remainingUrl.IndexOf('{') >= 0) & (remainingUrl.IndexOf('}') > 0) & (remainingUrl.IndexOf('{') < remainingUrl.IndexOf('}')))
                {
                    int leftIndex = remainingUrl.IndexOf('{');
                    int rightIndex = remainingUrl.IndexOf('}');
                    string expression = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                    remainingUrl = remainingUrl.Substring(rightIndex + 1);
                    string prefix = null;
                    if ((expression.IndexOf(":") > 0))
                    {
                        prefix = expression.Substring(0, expression.IndexOf(":"));
                    }
                    if ((prefix != null) && (prefix.Length > 0) && (!((StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))) && (!(BaseRecord.IsKnownExpressionPrefix(prefix))))
                    {
                        if ((controlIdList.Contains(prefix)) & (!(forwardTo.Contains(prefix))))
                        {
                            forwardTo.Add(prefix);
                        }
                    }
                }

                foreach (string containerId in forwardTo)
                {
                    Control ctl = ((Control)(controlIdList[containerId]));
                    if (ctl != null)
                    {
                        if (ctl is BaseApplicationRecordControl)
                        {
                                finalRedirectUrl = ((BaseApplicationRecordControl)(ctl)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt, includeSession);

                        }
                        else if (ctl is BaseApplicationTableControl)
                        {
                                finalRedirectUrl = ((BaseApplicationTableControl)(ctl)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt, includeSession);

                        }
                    }
                }
                foreach (System.Web.UI.Control control in controlList)
                {
                    if ((forwardTo.IndexOf(control.ID) < 0))
                    {
                        if (control is BaseApplicationRecordControl)
                        {
                                finalRedirectUrl = ((BaseApplicationRecordControl)(control)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt, includeSession);
   
                        }
                        else if (control is BaseApplicationTableControl)
                        {
                                finalRedirectUrl = ((BaseApplicationTableControl)(control)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt, includeSession);
                        }
                    }
                }
            }
            _modifyRedirectUrlInProgress = false;
            return finalRedirectUrl;
        }

        public virtual string EvaluateExpressions(string redirectUrl, string redirectArgument, bool bEncrypt, Control targetCtl)
        {
            string finalRedirectUrl = redirectUrl;
            try
            {
                if ((_modifyRedirectUrlInProgress))
                {
                    return null;
                }
                else
                {
                    _modifyRedirectUrlInProgress = true;
                }
                string finalRedirectArgument = redirectArgument;



                string remainingUrl = finalRedirectUrl;


                // encrypt constant value
                if (bEncrypt && targetCtl.GetType() == Page.GetType())
                {
                    remainingUrl += "&";
                    finalRedirectUrl += "&";

                    while ((remainingUrl.IndexOf('=') >= 0) && (remainingUrl.IndexOf('&') > 0) && (remainingUrl.IndexOf('=') < remainingUrl.IndexOf('&')))
                    {
                        int leftIndex = remainingUrl.IndexOf('=');
                        int rightIndex = remainingUrl.IndexOf('&');
                        string encryptFrom = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                        remainingUrl = remainingUrl.Substring(rightIndex + 1);
                        if (!encryptFrom.StartsWith("{") || !encryptFrom.EndsWith("}"))
                        {
                            // check if it is already encrypted
                            bool isEncrypted = false;
                            try
                            {
                                if (Decrypt(encryptFrom) != "")
                                    isEncrypted = true;
                            }
                            catch
                            {
                            }

                            // if not, process encryption
                            if (!isEncrypted)
                            {
                                string encryptTo = (this.Page as BaseApplicationPage).Encrypt(encryptFrom as string);
                                finalRedirectUrl = finalRedirectUrl.Replace("=" + encryptFrom + "&", "=" + encryptTo + "&");
                            }
                        }
                    }

                    finalRedirectUrl = finalRedirectUrl.Trim('&');
                }



                if ((finalRedirectUrl == null) || (finalRedirectUrl.Length == 0))
                {
                    return "";
                }
                else if ((finalRedirectUrl.IndexOf('{') < 0))
                {
                    _modifyRedirectUrlInProgress = false;
                    return finalRedirectUrl;
                }
                else
                {
                    if (redirectArgument != null && redirectArgument.Length > 0)
                    {
                        string[] arguments = redirectArgument.Split(',');
                        for (int i = 0; i <= (arguments.Length - 1); i++)
                        {
                            finalRedirectUrl = finalRedirectUrl.Replace("{" + i.ToString() + "}", "{" + arguments[i] + "}");
                        }
                        finalRedirectArgument = "";
                    }
                    ArrayList controlList = new ArrayList();
                    GetAllRecordAndTableControls(targetCtl, controlList, true);
                    if (controlList.Count == 0)
                    {
                        return finalRedirectUrl;
                    }
                    Hashtable controlIdList = new Hashtable();

                    bool found = false;
                    foreach (System.Web.UI.Control control in controlList)
                    {
                        string uID = control.UniqueID;
                        int pageContentIndex = uID.IndexOf("$PageContent$");
                        if (pageContentIndex > 0)
                        {
                            if (found == false)
                            {
                                //Remove all controls without $PageContent$ prefix, because this page is used with Master Page
                                //and these entries are irrelevant
                                controlIdList.Clear();
                            }
                            found = true;
                        }
                        if (found)
                        {
                            //If we found that Master Page is used for this page construction than disregard all controls
                            //without $PageContent$ prefix
                            if (pageContentIndex > 0)
                            {
                                uID = uID.Substring(pageContentIndex + "$PageContent$".Length);
                                controlIdList.Add(uID, control);
                            }
                        }
                        else
                        {
                            //No Master Page presense found so far
                            controlIdList.Add(uID, control);
                        }
                    }

                    ArrayList forwardTo = new ArrayList();

                    remainingUrl = finalRedirectUrl;
                    while ((remainingUrl.IndexOf('{') >= 0) & (remainingUrl.IndexOf('}') > 0) & (remainingUrl.IndexOf('{') < remainingUrl.IndexOf('}')))
                    {
                        int leftIndex = remainingUrl.IndexOf('{');
                        int rightIndex = remainingUrl.IndexOf('}');
                        string expression = remainingUrl.Substring(leftIndex + 1, rightIndex - leftIndex - 1);
                        remainingUrl = remainingUrl.Substring(rightIndex + 1);
                        string prefix = null;
                        if ((expression.IndexOf(":") > 0))
                        {
                            prefix = expression.Substring(0, expression.IndexOf(":"));
                        }
                        if ((prefix != null) && (prefix.Length > 0) && (!((StringUtils.InvariantLCase(prefix) == StringUtils.InvariantLCase(PREFIX_NO_ENCODE)))) && (!(BaseRecord.IsKnownExpressionPrefix(prefix))))
                        {
                            if ((controlIdList.Contains(prefix)) & (!(forwardTo.Contains(prefix))))
                            {
                                forwardTo.Add(prefix);
                            }
                        }
                    }

                    foreach (string containerId in forwardTo)
                    {
                        Control ctl = ((Control)(controlIdList[containerId]));
                        if (ctl != null)
                        {
                            if (ctl is BaseApplicationRecordControl)
                            {
                                finalRedirectUrl = ((BaseApplicationRecordControl)(ctl)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt);
                            }
                            else if (ctl is BaseApplicationTableControl)
                            {
                                finalRedirectUrl = ((BaseApplicationTableControl)(ctl)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt);
                            }
                        }
                    }
                    foreach (System.Web.UI.Control control in controlList)
                    {
                        if ((forwardTo.IndexOf(control.ID) < 0))
                        {
                            if (control is BaseApplicationRecordControl)
                            {
                                finalRedirectUrl = ((BaseApplicationRecordControl)(control)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt);
                            }
                            else if (control is BaseApplicationTableControl)
                            {
                                finalRedirectUrl = ((BaseApplicationTableControl)(control)).EvaluateExpressions(finalRedirectUrl, finalRedirectArgument, bEncrypt);
                            }
                        }
                    }
                }
                _modifyRedirectUrlInProgress = false;
            }
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                _modifyRedirectUrlInProgress = false;
            }
            return finalRedirectUrl;

        }

        private void GetAllRecordAndTableControls(Control ctl, ArrayList controlList, bool withParents)
        {
	        if (ctl == null) {
		        return;
	        }

	        GetAllRecordAndTableControls(ctl, controlList);

	        if (withParents) {
		        Control parent = ctl.Parent;
		        while (parent != null) {
			        if ((parent) is BaseApplicationRecordControl || (parent) is BaseApplicationTableControl) {
				        controlList.Add(parent);
			        }
			        parent = parent.Parent;
		        }
	        }
        }


        private ArrayList GetAllRecordAndTableControls()
        {
            ArrayList controlList = new ArrayList();
            GetAllRecordAndTableControls(this, controlList);
            return controlList;
        }

        private void GetAllRecordAndTableControls(Control ctl, ArrayList controlList)
        {
            if (ctl == null)
            {
                return;
            }
            if (ctl is BaseApplicationRecordControl || ctl is BaseApplicationTableControl)
            {
                controlList.Add(ctl);
            }
            
            foreach (Control nextCtl in ctl.Controls)
            {
                GetAllRecordAndTableControls(nextCtl, controlList);
            }
        }


		public string GetResourceValue(string keyVal, string appName)
		{
            return(AppResources.GetResourceValue(keyVal, appName));
		}
        public string GetResourceValue(string keyVal)
        {
            return(AppResources.GetResourceValue(keyVal, null));
        }
        public string ExpandResourceValue(string keyVal)
        {
            return(AppResources.ExpandResourceValue(keyVal));
        }

        // -----------------------------------------------------------------------------
        // <summary>
        // Register Control buttonCtrl with ScriptManager to perform traditional postback instead of default async postback
        // </summary>
        // <remarks>
        // </remarks>
        // <history>
        // 	[sramarao]	3/2007	Created
        // </history>
        // -----------------------------------------------------------------------------
        public void RegisterPostBackTrigger(System.Web.UI.Control buttonCtrl, System.Web.UI.Control updatePanelCtrl)
        {
            try
            {
                // Get current ScriptManager
                ScriptManager scriptMgr = ScriptManager.GetCurrent(this.Page);
                System.Web.UI.UpdatePanel CurrentUpdatePanel = (UpdatePanel)updatePanelCtrl;
                // If Scriptmanager not preset return.
                // If buttonCtrl is not surrounded by an UpdatePanel then return.
                if (scriptMgr != null && CurrentUpdatePanel != null && buttonCtrl != null)
                {
                    scriptMgr.RegisterPostBackControl(buttonCtrl);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        public void RegisterPostBackTrigger(System.Web.UI.Control buttonCtrl)
        {
            try
            {
                // Get current ScriptManager
                ScriptManager scriptMgr = ScriptManager.GetCurrent(this.Page);
                // If Scriptmanager not preset return.
                if (scriptMgr != null && buttonCtrl != null)
                {
                    scriptMgr.RegisterPostBackControl(buttonCtrl);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }
        }

        private bool _ShouldSaveControlsToSession = false;

        public bool ShouldSaveControlsToSession
        {
            get
            {
                return this._ShouldSaveControlsToSession;
            }
            set
            {
                this._ShouldSaveControlsToSession = value;
            }
        }

        protected void Page_SaveControls_Unload(object sender, EventArgs e)
        {
            if (this.ShouldSaveControlsToSession)
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
            this.Session[GetValueKey(name)] = value;
        }

        public string GetFromSession(string name, string defaultValue)
        {
            string value = ((string)(this.Session[GetValueKey(name)]));
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
            this.Session.Remove(GetValueKey(name));
        }

        public bool InSession(string name)
        {
            return (!(this.Session[GetValueKey(name)] == null));
        }

        public string GetValueKey(string name)
        {
            return this.Session.SessionID + this.AppRelativeVirtualPath + name;
        }

        public virtual void SaveData()
        {
        }
        public virtual void SetControl(string control)
        {
        }


#region Methods to encrypt and decrypt URL parameters

        // The URLEncryptionKey is specified in the web.config.  The rightmost three characters of the current
        // Session Id are concatenated with the URLEncryptionKey to provide added protection.  You can change
        // this to anything you like by changing this function for the application.
        // This function is private and not overridable because each page cannot have its own key - it must
        // be common across the entire application.

        public virtual string Encrypt(string Source)
        {
            Crypto CheckCrypto = new Crypto();
            return(CheckCrypto.Encrypt(Source));
        }

        public virtual string Decrypt(string Source)
        {
            Crypto CheckCrypto = new Crypto();
            return(CheckCrypto.Decrypt(Source));
        }

        public virtual string Encrypt(string Source, bool includeSession)
        {
            Crypto CheckCrypto = new Crypto();
            return CheckCrypto.Encrypt(Source, includeSession);
        }

        public virtual string Decrypt(string Source, bool includeSession)
        {
            Crypto CheckCrypto = new Crypto();
            return CheckCrypto.Decrypt(Source, includeSession);
        }

        // Encrypt url parameter which is enclosed in {}. For eg:..\Shared\SelectFileToImport?TableName=Employees
        public string EncryptUrlParameter(string url)
        {
            if (url == null)
            {
                return "";
            }
            if (url.IndexOf('=') > 0)
            {
                string[] queryString = url.Split('=');
                string expression = queryString[1];
                string encryptedValue = Encrypt(expression);
                url = url.Replace( expression, encryptedValue);
            }
            return url;
        }

#endregion

#region Import Wizard methods

        public virtual string GetPreviousURL()
        {
            this.RemoveCurrentRequestFromSessionNavigationHistory();

            BaseClasses.Web.SessionNavigationHistory snh = this.GetSessionNavigationHistory();
            string prevUrl = null;
            if (snh != null)
            {
                BaseClasses.Web.SessionNavigationHistory.RequestInfo prevRequest = snh.GetCurrentRequest();
                if (prevRequest != null)
                {
                    if (StringUtils.InvariantUCase(this.Request.Url.PathAndQuery) != StringUtils.InvariantUCase(prevRequest._Url.PathAndQuery))
                    {
                        //If it is different than the current URL, redirect to the previous request's URL
                        prevUrl = prevRequest._Url.PathAndQuery;
                    }
                    else if ((prevRequest._UrlReferrer != null) && (StringUtils.InvariantUCase(this.Request.Url.PathAndQuery) != StringUtils.InvariantUCase(prevRequest._UrlReferrer.PathAndQuery)))
                    {
                        //ElseIf it is different than the current URL, redirect to the previous request's URLReferrer
                        prevUrl = prevRequest._UrlReferrer.PathAndQuery;
                    }
                }
            }

            if (string.IsNullOrEmpty(prevUrl))
            {
                prevUrl = BaseClasses.Configuration.ApplicationSettings.Current.DefaultPageUrl;
            }
            return prevUrl;
        }

        #endregion

#region Chart control initialization
        public const string PIE = "Pie";
        public const string LINE = "Line";
        public const string BAR  = "Bar";
        public const string COLUMN  = "Column";
        public const string LabelInsideBar  = "Label inside bar";
        public const string ValueAtBarEnd  = "Value at bar end";
        public const string NothingInside = "Nothing";
        // <summary>
        //Creates chart control based on the passed parameters
        // </summary>
        // <param name="barThickness"> How thick the bar or column</param>
        // <param name="chartType">Bar, Column, Pie or Line</param>
        // <param name="usePalette">If true - uses Palette, otherwise - single color. For Pie chart palette is used regardless of this parameter</param>
        // <param name="palette">One of the palette in Windows.Forms.DataVisualization.ChartColorPalette </param>
        // <param name="color">One of the colors in Drawing.Color. Used for the bars, columns, or line</param>
        // <param name="fontFamily">One of the font familie as defined in Drawinf.FontFamily (string)</param>
        // <param name="fontColor">color of the font used for all texts - labels and values (from Drawing.color)</param>
        // <param name="backGroundColor">Background on the chart area. From Drawing.Color</param>
        // <param name="gridColor">The color used on all grid lines and markers. From Drawing.Color</param>
        // <param name="title">Title of the chart</param>
        // <param name="indexAxisTitle">Title on the Axis with labels</param>
        // <param name="valueAxisTitle">Title on the axis with values</param>
        // <param name="indexArray">Array of labels (String)</param>
        // <param name="valueArray">Array of values (Decimal)</param>
        // <param name="labelAngle">If 0, label on the X axis is shown horizontally, if negative, it is tilted counter clock wize, if positive,
        // tilted colck wise. Could be from -90 to 90. (degrees)</param>
        // <param name="showValueAtEdge">If set to truw, will show numeric value at the tip of the bar of column</param>
        // <param name="showLabelInside">If set to true, will show label inside the bar. Can be only set if showValueAtEdge is false</param>
        // <param name="SetIndexLabelBold">Used to show SELECT! word on the index axis in Index step.</param>
        // <param name="customProperties">Added to custom properties to series. To the list of supported properties refer to
        // http://msdn.microsoft.com/en-us/library/dd456764.aspx</param>
        // <returns>chart control or Nothing</returns>
        // <remarks></remarks>
        public virtual void InitializeChartControl(Chart chartControl,
                                                 string[] indexArray,
                                                 decimal[] valueArray,
                                                 int barThickness,
                                                 string chartType,
                                                 bool usePalette,
                                                 ChartColorPalette palette,
                                                 System.Drawing.Color color,
                                                 System.Drawing.Color backGroundColor,
                                                 System.Drawing.Color gridColor,
                                                 string fontFamily,
                                                 System.Drawing.Color fontColor,
                                                 System.Drawing.Color internalLabelColor,
                                                 string showInsideBar,
                                                 string title,
                                                 string indexAxisTitle,
                                                 string valueAxisTitle,
                                                 int labelAngle,
                                                 bool generatePercentage,
                                                 string labelFormat,
                                                 string customProperties)
        {
            System.Collections.Generic.List<object> args = new System.Collections.Generic.List<object>();
            args.Add(chartControl);
            args.Add(indexArray);
            args.Add(valueArray);
            args.Add(null);
            args.Add(null);
            args.Add(barThickness);
            args.Add(chartType);
            args.Add(usePalette);
            args.Add(palette);
            args.Add(color);
            args.Add(backGroundColor);
            args.Add(gridColor);
            args.Add(fontFamily);
            args.Add(fontColor);
            args.Add(internalLabelColor);
            args.Add(showInsideBar);
            args.Add(title);
            args.Add(indexAxisTitle);
            args.Add(valueAxisTitle);
            args.Add(labelAngle);
            args.Add(generatePercentage);
            args.Add(labelFormat);
            args.Add("");
            args.Add("");
            args.Add("");
            args.Add("");
            args.Add("");
            args.Add(customProperties);
            InitializeChartControl(args.ToArray());
        }

        /// <summary>
        /// Creates chart control based on the passed parameters
        /// </summary>
        /// <param name="args"> parameters to initialize the chart</param>
        public virtual void InitializeChartControl(object[] args)
        {
            int n;
            Chart chartControl = null;
            string[] indexArray = null;
            decimal[] valueArray = null;
            string[] legendURLArray = null;
            string[] dataPointURLArray = null;
            int barThickness = 3;
            string chartType = null;
            bool usePalette = false;
            ChartColorPalette palette = ChartColorPalette.None;
            System.Drawing.Color color = System.Drawing.Color.White;
            System.Drawing.Color backGroundColor = System.Drawing.Color.White;
            System.Drawing.Color gridColor = System.Drawing.Color.Black;
            string fontFamily = null;
            System.Drawing.Color fontColor = System.Drawing.Color.Black;
            System.Drawing.Color internalLabelColor = System.Drawing.Color.Black;
            string showInsideBar = "";
            string title = "";
            string indexAxisTitle = "";
            string valueAxisTitle = "";
            int labelAngle = 0;
            bool generatePercentage = false;
            string labelFormat = null;
            string chartTitleFontSize = "";
            string axisTitleFontSize = "";
            string scaleFontSize = "";
            string labelInsideFontSize = "";
            string customProperties = "";


            if (args.Length > 0 && args[0] != null)
            {
                chartControl = (Chart)args[0];
            }
            if (args.Length > 1 && args[1] != null)
            {
                indexArray = (string[])args[1];
            }
            if (args.Length > 2 && args[2] != null)
            {
                valueArray = (decimal[])args[2];
            }
            if (args.Length > 3 && args[3] != null)
            {
                legendURLArray = (string[])args[3];
            }
            if (args.Length > 4 && args[4] != null)
            {
                dataPointURLArray = (string[])args[4];
            }
            if (args.Length > 5 && args[5] != null)
            {
                barThickness = (int)args[5];
            }
            if (args.Length > 6 && args[6] != null)
            {
                chartType = (string)args[6];
            }
            if (args.Length > 7 && args[7] != null)
            {
                usePalette = (bool)args[7];
            }
            if (args.Length > 8 && args[8] != null)
            {
                palette = (ChartColorPalette)args[8];
            }
            if (args.Length > 9 && args[9] != null)
            {
                color = (System.Drawing.Color)args[9];
            }
            if (args.Length > 10 && args[10] != null)
            {
                backGroundColor = (System.Drawing.Color)args[10];
            }
            if (args.Length > 11 && args[11] != null)
            {
                gridColor = (System.Drawing.Color)args[11];
            }
            if (args.Length > 12 && args[12] != null)
            {
                fontFamily = (string)args[12];
            }
            if (args.Length > 13 && args[13] != null)
            {
                fontColor = (System.Drawing.Color)args[13];
            }
            if (args.Length > 14 && args[14] != null)
            {
                internalLabelColor = (System.Drawing.Color)args[14];
            }
            if (args.Length > 15 && args[15] != null)
            {
                showInsideBar = (string)args[15];
            }
            if (args.Length > 16 && args[16] != null)
            {
                title = (string)args[16];
            }
            if (args.Length > 17 && args[17] != null)
            {
                indexAxisTitle = (string)args[17];
            }
            if (args.Length > 18 && args[18] != null)
            {
                valueAxisTitle = (string)args[18];
            }
            if (args.Length > 19 && args[19] != null)
            {
                labelAngle = (int)args[19];
            }
            if (args.Length > 20 && args[20] != null)
            {
                generatePercentage = (bool)args[20];
            }
            if (args.Length > 21 && args[21] != null)
            {
                labelFormat = (string)args[21];
            }
            if (args.Length > 22 && args[22] != null)
            {
                chartTitleFontSize = (string)args[22];
            }
            if (args.Length > 23 && args[23] != null)
            {
                axisTitleFontSize = (string)args[23];
            }
            if (args.Length > 24 && args[24] != null)
            {
                scaleFontSize = (string)args[24];
            }
            if (args.Length > 25 && args[25] != null)
            {
                labelInsideFontSize = (string)args[25];
            }

            if (args.Length > 26 && args[26] != null)
            {
                customProperties = (string)args[26];
            }
	        //Add chart area to the control
	        string baseChartAreaName = "ChartArea";
	        string chartAreaName = "ChartArea1";
	        if ((chartControl.ChartAreas != null) && chartControl.ChartAreas.Count > 0) {
		        int suffix = 1;
		        bool found = true;

		        while (found && suffix < 100) {
			        chartAreaName = baseChartAreaName + suffix.ToString();
			        found = false;
			        foreach (ChartArea ca in chartControl.ChartAreas) {
				        if (ca.Name == chartAreaName) {
					        found = true;
					        suffix++;
					        break;
				        }
			        }
		        }
		        if (found)
			        return;
	        }
	        ChartArea chartArea = chartControl.ChartAreas.Add(chartAreaName);

	        chartArea.AxisX.TitleForeColor = fontColor;
	        chartArea.AxisY.TitleForeColor = fontColor;
	        chartArea.AxisY.TitleFont = new System.Drawing.Font(fontFamily, chartArea.AxisY.TitleFont.Size);
	        chartArea.AxisX.TitleFont = new System.Drawing.Font(fontFamily, chartArea.AxisX.TitleFont.Size);
            chartArea.AxisX.TitleFont = new System.Drawing.Font(fontFamily, int.TryParse(chartTitleFontSize, out n) ?
                                                                (int.TryParse(axisTitleFontSize, out n) ? int.Parse(axisTitleFontSize) : chartArea.AxisX.TitleFont.Size)
                                                                : chartArea.AxisX.TitleFont.Size);
            chartArea.AxisY.TitleFont = new System.Drawing.Font(fontFamily, int.TryParse(chartTitleFontSize, out n) ?
                                                                (int.TryParse(axisTitleFontSize, out n) ? int.Parse(axisTitleFontSize) : chartArea.AxisY.TitleFont.Size)
                                                                : chartArea.AxisY.TitleFont.Size);
	        chartArea.AxisY.IsLabelAutoFit = true;
	        chartArea.AxisX.IsLabelAutoFit = false;
            chartArea.AxisX.Interval = 1;
	        chartArea.AxisX.MajorGrid.LineColor = System.Drawing.Color.LightGray;
	        chartArea.AxisY.MajorGrid.LineColor = System.Drawing.Color.LightGray;
	        chartArea.AxisX.LabelStyle.ForeColor = fontColor;
	        chartArea.AxisY.LabelStyle.ForeColor = fontColor;
            chartArea.AxisX.LabelStyle.Font = new System.Drawing.Font(fontFamily, int.TryParse(scaleFontSize, out n) ? int.Parse(scaleFontSize) : chartArea.AxisX.LabelStyle.Font.Size);
            chartArea.AxisX.LineColor = gridColor;
	        chartArea.AxisY.LineColor = gridColor;
	        chartArea.AxisX.MajorTickMark.LineColor = gridColor;
	        chartArea.AxisY.MajorTickMark.LineColor = gridColor;
	        chartArea.AxisX.LabelStyle.Enabled = true;
	        chartArea.AxisY.LabelStyle.Enabled = true;
	        chartArea.AxisX.Title = indexAxisTitle;
	        chartArea.AxisY.Title = valueAxisTitle;
            chartArea.AxisY.LabelStyle.Format = labelFormat;
	        if (generatePercentage) {
		        chartArea.AxisY.LabelStyle.Format = "0%";
	        }

            chartArea.AxisY.LabelStyle.Font = new System.Drawing.Font(fontFamily, int.TryParse(scaleFontSize, out n) ? int.Parse(scaleFontSize) : chartArea.AxisY.LabelStyle.Font.Size);
	        chartArea.BackColor = backGroundColor;
	        //Now add Series
	        string baseSeriesName = "Series";
	        string seriesName = "Series1";
	        if ((chartControl.Series != null) && chartControl.Series.Count > 0) {
		        int suffix = 1;
		        bool found = true;

		        while (found && suffix < 100) {
			        seriesName = baseSeriesName + suffix.ToString();
			        found = false;
			        foreach (Series s in chartControl.Series) {
				        if (s.Name == seriesName) {
					        found = true;
					        suffix++;
					        break;
				        }
			        }
		        }
		        if (found)
			        return;
	        }
	        Series series = chartControl.Series.Add(seriesName);

	        series.ChartArea = chartAreaName;
	        chartControl.Series[seriesName].Points.Clear();
	        chartControl.Series[seriesName].BackGradientStyle = GradientStyle.None;
	        chartControl.Series[seriesName].BackHatchStyle = ChartHatchStyle.None;

	        chartControl.Series[seriesName].Font = new System.Drawing.Font(fontFamily, 6);
	        chartControl.Series[seriesName].LabelForeColor = fontColor;
            chartControl.Series[seriesName].SmartLabelStyle.AllowOutsidePlotArea = LabelOutsidePlotAreaStyle.Yes;
	        chartControl.AntiAliasing = AntiAliasingStyles.All;
	        if (usePalette || chartType == PIE) {
		        chartControl.Series[seriesName].Palette = palette;
	        } else {
		        chartControl.Series[seriesName].Color = color;
	        }

	        string baseTitleName = "Title";
	        string TitleName = "Title1";
	        if ((chartControl.Titles != null) && chartControl.Titles.Count > 0) {
		        int suffix = 1;
		        bool found = true;

		        while (found && suffix < 100) {
			        TitleName = baseTitleName + suffix.ToString();
			        found = false;
			        foreach (Title t in chartControl.Titles) {
				        if (t.Name == TitleName) {
					        found = true;
					        suffix++;
					        break;
				        }
			        }
		        }
		        if (found)
			        return;
	        }
	        int titleIndex = chartControl.Titles.Count - 1;
	        chartControl.Titles.Add(TitleName).Text = title;
	        titleIndex += 1;
	        chartControl.Titles[titleIndex].ForeColor = fontColor;
            chartControl.Titles[titleIndex].Font = new System.Drawing.Font(fontFamily, int.TryParse(chartTitleFontSize, out n) ? int.Parse(chartTitleFontSize) : chartArea.AxisY.TitleFont.Size);
	        System.Data.DataSet dataSet = new System.Data.DataSet();
	        System.Data.DataTable seriesTable = new System.Data.DataTable();
	        string cProperties = customProperties;
	        seriesTable.Columns.Add(new System.Data.DataColumn("X", typeof(string)));
            if (labelFormat == "0")
                seriesTable.Columns.Add(new System.Data.DataColumn("Y", typeof(int)));
            else
                seriesTable.Columns.Add(new System.Data.DataColumn("Y", typeof(double)));            

	        //Append cProperties with some style qualifiers
            if (!cProperties.ToLower().Contains("DrawingStyle".ToLower()))
            {
                if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
                cProperties = "DrawingStyle = Emboss";
            }
	        if (string.Equals(showInsideBar, LabelInsideBar, StringComparison.InvariantCultureIgnoreCase) && chartType != PIE) {
                if (!cProperties.ToLower().Contains("BarLabelStyle".ToLower()))
                {
                    if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
                    cProperties += "BarLabelStyle = Center";
                }
	        }
            if (chartType == PIE)
            {
                if (showInsideBar == ValueAtBarEnd)
                {
                    if (!cProperties.ToLower().Contains("PieLabelStyle".ToLower()))
                    {
                        if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
                        cProperties += "PieLabelStyle = Outside";
                    }
                }
                else
                {
                    if (!cProperties.ToLower().Contains("PieLabelStyle".ToLower()))
                    {
                        if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
                        cProperties += "PieLabelStyle = Inside";
                    }
                }
                if (!cProperties.ToLower().Contains("PieDrawingStyle".ToLower()))
                {
                    if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
                    cProperties += "PieDrawingStyle = Concave";
                }
            }
	        switch (chartType) {
		        case BAR:
			        chartArea.AxisY.LabelStyle.Angle = labelAngle;
			        series.ChartType = SeriesChartType.Bar;
			        if (!cProperties.ToLower().Contains("PixelPointWidth".ToLower())) {
				        string barWidth = "PixelPointWidth = " + barThickness;
                        if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
				        cProperties += barWidth;
			        }
			        break;
		        case COLUMN:
			        chartArea.AxisX.LabelStyle.Angle = labelAngle;
			        series.ChartType = SeriesChartType.Column;
			        if (!cProperties.ToLower().Contains("PixelPointWidth".ToLower())) {
				        string barWidth = "PixelPointWidth = " + barThickness;
                        if (!string.IsNullOrEmpty(cProperties) && !cProperties.EndsWith(",")) cProperties += ",";
				        cProperties += barWidth;
			        }
			        break;
		        case LINE:
			        chartArea.AxisX.LabelStyle.Angle = labelAngle;
			        series.ChartType = SeriesChartType.Line;
			        break;
		        case PIE:
			        chartControl.Series[seriesName].BorderColor = System.Drawing.Color.LightGray;
			        chartControl.Series[seriesName].BorderWidth = 1;
			        series.ChartType = SeriesChartType.Pie;
			        //Construct Legend
			        string baseLegendName = "Legend";
			        string legendName = "Legend1";
			        if ((chartControl.Legends != null) && chartControl.Legends.Count > 0) {
				        int suffix = 1;
				        bool found = true;
				        while (found && suffix < 100) {
					        legendName = baseLegendName + suffix.ToString();
					        found = false;
					        foreach (Legend l in chartControl.Legends) {
						        if (l.Name == legendName) {
							        found = true;
							        suffix += 1;
							        break; // TODO: might not be correct. Was : Exit For
						        }
					        }
				        }
				        if (found)
					        return;
			        }
			        System.Web.UI.DataVisualization.Charting.Legend legend = chartControl.Legends.Add(legendName);
			        legend.Title = indexAxisTitle;
                    legend.ForeColor = fontColor;
                    legend.TitleForeColor = chartArea.AxisX.TitleForeColor;
                    legend.TitleFont = new System.Drawing.Font(fontFamily, int.TryParse(axisTitleFontSize, out n) ? int.Parse(axisTitleFontSize) : legend.TitleFont.Size);
                    legend.Font = new System.Drawing.Font(fontFamily, int.TryParse(scaleFontSize, out n) ? int.Parse(scaleFontSize) : legend.Font.Size);
                    break;
	        }
	        chartControl.Series[seriesName].CustomProperties = cProperties;

	        //Sanity check for label and value arrays. They should not be empty
	        if (indexArray == null || valueArray == null) {
		        return;
	        }

	        //Add data to data table. For Bar chart add them in the reversed order
	        int dimention = indexArray.Length - 1;
	        if (dimention > valueArray.Length - 1)
		        dimention = valueArray.Length - 1;
	        if (chartType == BAR) {
		        for (int i = dimention; i >= 0; i += -1) {
			        seriesTable.Rows.Add(new object[] {
				        indexArray[i],
				        Convert.ToDouble(valueArray[i])
			        });
		        }
                if (legendURLArray != null && legendURLArray.Length > 0)
                    Array.Reverse(legendURLArray);
                if (dataPointURLArray != null && dataPointURLArray.Length > 0)
                    Array.Reverse(dataPointURLArray);

	        } else {
		        for (int i = 0; i <= dimention; i++) {
			        seriesTable.Rows.Add(new object[] {
				        indexArray[i],
				        Convert.ToDouble(valueArray[i])
			        });
		        }
	        }


	        dataSet.Tables.Add(seriesTable);

	        series.BorderWidth = 2;
	        chartControl.Series[seriesName].XValueMember = "X";
	        chartControl.Series[seriesName].YValueMembers = "Y";

	        chartControl.DataSource = dataSet;
	        if (chartControl.DataSource == null) {
		        return;
	        } else {
		        chartControl.DataBind();
	        }

	        //now when data bound to the chart, change some properties on particular elements (data points) of series
	        if (chartType == PIE) {
		        foreach (DataPoint dp in chartControl.Series[seriesName].Points) {
                    if (showInsideBar == ValueAtBarEnd)
                    {
                        dp.LabelForeColor = fontColor;
                    }
                    else
                    {
                        dp.LabelForeColor = internalLabelColor;
                    }
			        double value = dp.YValues[0];
			        dp.Label = value.ToString(labelFormat);
                
			        dp.LegendText = "#AXISLABEL";
                    dp.Font = new System.Drawing.Font(fontFamily, int.TryParse(scaleFontSize, out n) ? int.Parse(scaleFontSize) : dp.Font.Size);
                    if(string.IsNullOrEmpty(dp.AxisLabel)) dp.LegendText = " ";
		        }
                for (int i = 0; i <= chartControl.Series[seriesName].Points.Count - 1; i++)
                {
                    DataPoint dp = chartControl.Series[seriesName].Points[i];
                    if (legendURLArray != null && i < legendURLArray.Length)
                    {
                        dp.LegendUrl = legendURLArray[i];
                        dp.LegendMapAreaAttributes = "target=\"_blank\"";
                    }
                    if (dataPointURLArray != null && i < dataPointURLArray.Length)
                    {
                        dp.Url = dataPointURLArray[i];
                        dp.MapAreaAttributes = "target=\"_blank\"";
                    }
                }

	        } else {
		        if (showInsideBar == ValueAtBarEnd)
                    {
	                    // find out the largest value to be shown
	                    decimal largestValInChart = decimal.MinValue;
	                    foreach (decimal v in valueArray) {
		                    if (largestValInChart < v) {
			                    largestValInChart = v;
		                    }
	                    }

                    foreach (DataPoint dp in chartControl.Series[seriesName].Points) {
	                    dp.MarkerStyle = MarkerStyle.None;
	                    double value = dp.YValues[0];
	                    dp.Label = value.ToString(labelFormat);
	                    dp.LabelForeColor = fontColor;
	                    dp.CustomProperties = "BarLabelStyle = Outside";

	                    // for small value, show the label outside
	                    // for large value, show the label inside
	                    if (chartType == BAR && (largestValInChart / 2) < Convert.ToDecimal(value)) {
		                    dp.LabelForeColor = internalLabelColor;
		                    dp.CustomProperties = "BarLabelStyle = Right";
                            dp.Font = new System.Drawing.Font(fontFamily, int.TryParse(scaleFontSize, out n) ? int.Parse(scaleFontSize) : dp.Font.Size);

	                    }
                    }



		        } else if (showInsideBar == LabelInsideBar) {
			        if (chartControl.Series[seriesName].Points.Count == indexArray.Length) {
				        int index = 0;
				        int increment = 1;
				        System.Drawing.Color lColor = fontColor;
				        chartArea.AxisX.LabelStyle.Enabled = false;
				        if (chartType == BAR) {
                            lColor = internalLabelColor;
					        index = indexArray.Length - 1;
					        increment = -1;
				        }
				        foreach (DataPoint dp in chartControl.Series[seriesName].Points) {
					        dp.MarkerStyle = MarkerStyle.None;
					        dp.CustomProperties = "BarLabelStyle = Center";
                            dp.LabelForeColor = lColor;
					        dp.Label = indexArray[index];
					        index += increment;
				        }
			        }
		        }
                for (int i = 0; i <= chartControl.Series[seriesName].Points.Count - 1; i++)
                {
                    DataPoint dp = chartControl.Series[seriesName].Points[i];
                    if (string.IsNullOrEmpty(dp.AxisLabel))
                    {
                        dp.AxisLabel = " ";
                    }
                    if (legendURLArray != null && i < legendURLArray.Length)
                    {
                        dp.LegendUrl = legendURLArray[i];
                        dp.LegendMapAreaAttributes = "target=\"_blank\"";
                    }
                    if (dataPointURLArray != null && i < dataPointURLArray.Length)
                    {
                        dp.Url = dataPointURLArray[i];
                        dp.MapAreaAttributes = "target=\"_blank\"";
                    }
                    dp.Font = new System.Drawing.Font(fontFamily, int.TryParse(labelInsideFontSize, out n) ? int.Parse(labelInsideFontSize) : dp.Font.Size);
                }
            }
        }
#endregion

        // <summary>
        // Forms the ExportFieldValue URL for the Image to Render
        // For Instance - "../Shared/ExportFieldValue.aspx?"
        // Also add the style for the image to appear in the background
        // </summary>
        // <returns>ExportFieldValue URL for the Image with the Background styles</returns>
        public string GetImageWithOverlaidText(string imgFieldName, PrimaryKeyRecord dataSource, object otherFieldName, string redirectURL) {
            if (dataSource == null) return ""; 

            string imgURL  = "";
            if (!string.IsNullOrEmpty(imgFieldName)) {            
                BaseColumn col  = dataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(imgFieldName);

                if (col == null) {
                    return "Invalid column name For image type";
                }

                switch (col.ColumnType) {
                    case BaseColumn.ColumnTypes.Binary:
                    case BaseColumn.ColumnTypes.Image:
                        imgURL = dataSource.FormatImageUrl(col, Encrypt(col.TableDefinition.TableCodeName), Encrypt(col.UniqueName), Encrypt(dataSource.GetID().ToXmlString()));
                        break;
                }            
            }

            return GetImageWithOverlaidText(imgURL, otherFieldName, redirectURL);
        }

        // <summary>
        // Forms the ExportFieldValue URL for the Image to Render
        // For Instance - "../Shared/ExportFieldValue.aspx?"
        // Also add the style for the image to appear in the background
        // </summary>
        // <returns>ExportFieldValue URL for the Image with the Background styles</returns>
        public string GetImageWithOverlaidText(string imgFieldName, KeylessRecord dataSource, object otherFieldName, string redirectURL) {
            if (dataSource == null) return ""; 

            string imgURL  = "";
            if (!string.IsNullOrEmpty(imgFieldName)) {            
                BaseColumn col  = dataSource.TableAccess.TableDefinition.ColumnList.GetByCodeName(imgFieldName);

                if (col == null) {
                    return "Invalid column name For image type";
                }

                switch (col.ColumnType) {
                    case BaseColumn.ColumnTypes.Binary:
                    case BaseColumn.ColumnTypes.Image:
                        imgURL = dataSource.FormatImageUrl(col, Encrypt(col.TableDefinition.TableCodeName), Encrypt(col.UniqueName), Encrypt(dataSource.GetDefaultID().ToXmlString()));
                        break;
                }
            } 

            return GetImageWithOverlaidText(imgURL, otherFieldName, redirectURL);         
        }

        // <summary>
        // Add the style for the image to appear in the background
        // </summary>
        // <returns>ExportFieldValue URL for the Image with the Background styles</returns>   
        public string GetImageWithOverlaidText(string imgURL, object otherFieldName, string redirectURL) {
            string fieldValue = "";
            if ((otherFieldName != null))
            {
                fieldValue = otherFieldName.ToString();
            }

            string redirectAndImageURLString = "";
            if (string.IsNullOrEmpty(redirectURL))
            {
                if (string.IsNullOrEmpty(imgURL))
                {
                    redirectAndImageURLString = "<div class=\"galleryBackgroundImage\">";
                }
                else
                {
                    redirectAndImageURLString = "<div class=\"galleryBackgroundImage\" style=\"background-image: url('" + imgURL + "');\">";
                }
            }
            else
            {
                if (string.IsNullOrEmpty(imgURL))
                {
                    redirectAndImageURLString = "<div onClick=\"document.location.href='" + redirectURL + "'\" class=\"galleryBackgroundImage\">";
                }
                else
                {
                    redirectAndImageURLString = "<div onClick=\"document.location.href='" + redirectURL + "'\" class=\"galleryBackgroundImage\" style=\"background-image: url('" + imgURL + "');\">";
                }
            }

            string fieldString = "";
            if (string.IsNullOrEmpty(fieldValue))
            {
                fieldString = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"width: 100%;\"><tr><td class=\"galleryDescriptionBackground\"></td></tr></table></div>";
            }
            else
            {
                string param = "<span class=\"galleryTitle\">" + fieldValue + "</span><br/>";
                fieldString = "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"width: 100%;\"><tr><td class=\"galleryDescriptionBackground\"><div class=\"galleryTitleCrop\">" + param + "</div></td></tr></table></div>";
            }

            return redirectAndImageURLString + fieldString;
        }

      // sort the list item using bubble sort
      [System.Web.Services.WebMethod()]
      public static string SortListItems(string str)
        {
            // the input is JSON in string which is passed by 
                ListItemCollection list = MiscUtils.DeserializeJSON(str);
                ListItem[] items = new ListItem[list.Count];
                list.CopyTo(items, 0);
                ListItem temp;
                for (int write = 0; write < items.Length; write++)
                {
                    for (int sort = 0; sort < items.Length - 1; sort++)
                    {
                        if (String.Compare(items[sort].Text, items[sort + 1].Text) > 0)
                        {
                            temp = items[sort + 1];
                            items[sort + 1] = items[sort];
                            items[sort] = temp;
                        }

                    }

                }
                list.Clear();
                list.AddRange(items);
                return MiscUtils.SerializeJSON(list);
        }
    }
}