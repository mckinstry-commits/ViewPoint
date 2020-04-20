
#region "Using statements"   	  
using System;
using System.Collections;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.ComponentModel;
using BaseClasses;
using BaseClasses.Data;
using BaseClasses.Utils;
using BaseClasses.Web.UI;
using BaseClasses.Web.UI.WebControls;
        
using ViewpointXRef.Business;
using ViewpointXRef.Data;
        
#endregion	  
  
namespace ViewpointXRef.UI
{

  // Code-behind class for the HeaderMobile user control.
public partial class HeaderMobile : BaseApplicationUserControl , IHeaderMobile
{
        
      #region "Section 1: Place your customizations here."

      public HeaderMobile()
        {
            this.Initialize();
    

        }
         
        public void LoadData()
        {
            // LoadData reads database data and assigns it to UI controls.
            // Customize by adding code before or after the call to LoadData_Base()
            // or replace the call to LoadData_Base().
            LoadData_Base();            
        }
        
      private string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string,object> variables, bool includeDS)
      {
          return EvaluateFormula_Base(formula, dataSourceForEvaluate, format, variables, includeDS);
      }
      
      public void Page_InitializeEventHandlers(object sender, System.EventArgs e)
      {
          // Handles base.Init. 
          // Register the Event handler for any Events.
          this.Page_InitializeEventHandlers_Base(sender, e);
      }
      
      protected override void SaveControlsToSession()
      {
        SaveControlsToSession_Base();
      }


      protected override void ClearControlsFromSession()
      {
        ClearControlsFromSession_Base();
      }

      protected override void LoadViewState(object savedState)
      {
        LoadViewState_Base(savedState);
      }


      protected override object SaveViewState()
      {
        return SaveViewState_Base();
      }      


        public void Page_PreRender(object sender, System.EventArgs e)
        {
            this.Page_PreRender_Base(sender, e);
        }
        
      
        public void LogOut()
        {
           // By default application logs out user on the load of SignOut page. To call logout method explicitely here
           // uncomment the following call to security layer:
           // ((BaseApplicationPage)(this.Page)).CurrentSecurity.Logout((BaseApplicationPage)(this.Page));
        }
                
    
      public override void SetControl(string control)
      {
          this.SetControl_Base(control);
      }
    
    
#region "Ajax Functions"

        [System.Web.Services.WebMethod()]
        public static Object[] GetRecordFieldValue(string contextName,
                                                   string tableName , 
                                                   string recordID , 
                                                   string columnName, 
                                                   string fieldName, 
                                                   string title, 
                                                   string closeBtnText,
                                                   bool persist, 
                                                   int popupWindowHeight, 
                                                   int popupWindowWidth, 
                                                   bool popupWindowScrollBar)
        {
            // GetRecordFieldValue gets the pop up window content from the column specified by
            // columnName in the record specified by the recordID in data base table specified by tableName.
            // Customize by adding code before or after the call to  GetRecordFieldValue_Base()
            // or replace the call to  GetRecordFieldValue_Base().
            return GetRecordFieldValue_Base(contextName, tableName, recordID, columnName, fieldName, title, closeBtnText, persist, popupWindowHeight, popupWindowWidth, popupWindowScrollBar);
        }

        [System.Web.Services.WebMethod()]
        public static object[] GetImage(string contextName,
                                        string tableName,
                                        string recordID, 
                                        string columnName, 
                                        string title, 
                                        string closeBtnText,
                                        bool persist, 
                                        int popupWindowHeight, 
                                        int popupWindowWidth, 
                                        bool popupWindowScrollBar)
        {
            // GetImage gets the Image url for the image in the column "columnName" and
            // in the record specified by recordID in data base table specified by tableName.
            // Customize by adding code before or after the call to  GetImage_Base()
            // or replace the call to  GetImage_Base().
            return GetImage_Base(contextName, tableName, recordID, columnName, title, closeBtnText, persist, popupWindowHeight, popupWindowWidth, popupWindowScrollBar);
        }
        
    
      
      #endregion

      // Page Event Handlers - buttons, sort, links
      
        public void SignIn_Click(object sender, EventArgs args)
        {

          // Click handler for SignIn.
          // Customize by adding code before the call or replace the call to the Base function with your own code.
          SignIn_Click_Base(sender, args);
          // NOTE: If the Base function redirects to another page, any code here will not be executed.
        }
            
    
        // Write out the Set methods
        
        public void SetSignIn()
        {
            SetSignIn_Base(); 
        }              
                         
        
        // Write out the methods for DataSource
        


#endregion

#region "Section 2: Do not modify this section."

      
        private void Initialize()
        {
            // Called by the class constructor to initialize event handlers for Init and Load
            // You can customize by modifying the constructor in Section 1.
            this.Init += new EventHandler(Page_InitializeEventHandlers);
            
            this.Load += new EventHandler(Page_Load);

            EvaluateFormulaDelegate = new BaseClasses.Data.DataSource.EvaluateFormulaDelegate(EvaluateFormula);        
        }
        
    
      // Handles base.Init. Registers event handler for any button, sort or links.
      // You can add additional Init handlers in Section 1.
      public void Page_InitializeEventHandlers_Base(object sender, System.EventArgs e)
      {
    	  
          this.PreRender += new EventHandler(Page_PreRender);    
          
          // Register the Event handler for any Events.
      
            


          // Setup the pagination events.
        
                    this.SignIn.Click += SignIn_Click;
                        
          this.ClearControlsFromSession();    
    
          System.Web.HttpContext.Current.Session["isd_geo_location"] = "<location><error>LOCATION_ERROR_DISABLED</error></location>";
    
        }

        private void Base_RegisterPostback()
        {
                
        }

        protected void BasePage_PreRender_Base(object sender, System.EventArgs e)
        {
            // Load data for each record and table UI control.
                  
            // Data bind for each chart UI control.
          
        }

        // Handles base.Load.  Read database data and put into the UI controls.
        // You can add additional Load handlers in Section 1.
        protected virtual void Page_Load(object sender, EventArgs e)
        {
    
            BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SettingsIconMobile").Visible = false;
            BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "SettingsCollapsibleRegionMobile").Visible = false;
          
            this.ThemeSelector.Visible = false;
            
            this.LanguageSelector.Visible = false;
            
            this.UserStatusInit(); 
            this.SignInButtonInit(); 
             if (!this.IsPostBack)
             {
            
             }
            
    // Load data only when displaying the page for the first time or if postback from child window
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {

    // Read the data for all controls on the page.
    // To change the behavior, override the DataBind method for the individual
    // record or table UI controls.
    this.LoadData();
    }

        
            }

            public static object[] GetRecordFieldValue_Base(string contextName,
                        string tableName ,
                        string recordID ,
                        string columnName,
                        string fieldName,
                        string title, 
                        string closeBtnText,
                        bool persist,
                        int popupWindowHeight,
                        int popupWindowWidth,
                        bool popupWindowScrollBar)
            {
            if (recordID != ""){
                recordID = System.Web.HttpUtility.UrlDecode(recordID);
            }
            string content = BaseClasses.Utils.MiscUtils.GetFieldData(tableName, recordID, columnName);
            
            content =  NetUtils.EncodeStringForHtmlDisplay(content);
            // returnValue is an array of string values.
            // returnValue(0) represents title of the pop up window.
            // returnValue(1) represents the tooltip of the close button.
            // returnValue(2) represents content of the text.
            // returnValue(3) represents whether pop up window should be made persistant
            // or it should close as soon as mouse moves out.
            // returnValue(4), (5) represents pop up window height and width respectivly
            // returnValue(6) represents whether pop up window should contain scroll bar.
            // They can be modified by going to Attribute tab of the properties window of the control in aspx page.
            object[] returnValue = new object[7];
            returnValue[0] = title;
            returnValue[1] = closeBtnText;
            returnValue[2] = content;
            returnValue[3] = persist;
            returnValue[4] = popupWindowWidth;
            returnValue[5] = popupWindowHeight;
            returnValue[6] = popupWindowScrollBar;
            return returnValue;
        }
        

        public static object[] GetImage_Base(string contextName,
        string tableName,
        string recordID,
        string columnName,
        string title, 
        string closeBtnText,
        bool persist,
        int popupWindowHeight,
        int popupWindowWidth,
        bool popupWindowScrollBar)
        {
            string  content;
            if (contextName != null && contextName != "NULL")
            {
                content = "<IMG alt =\"" + title + "\" src =" + "\"../Shared/ExportFieldValue.aspx?Context=" + contextName + "&Table=" + tableName + "&Field=" + columnName + "&Record=" + recordID + "\"/>";
            }
            else
            {
                content = "<IMG alt =\"" + title + "\" src =" + "\"../Shared/ExportFieldValue.aspx?Table=" + tableName + "&Field=" + columnName + "&Record=" + recordID + "\"/>";
            }
        // returnValue is an array of string values.
        // returnValue(0) represents title of the pop up window.
        // returnValue(1) represents the tooltip of the close button.
        // returnValue(2) represents content ie, image url.
        // returnValue(3) represents whether pop up window should be made persistant
        // or it should close as soon as mouse moves out.
        // returnValue(4), (5) represents pop up window height and width respectivly
        // returnValue(6) represents whether pop up window should contain scroll bar.
        // They can be modified by going to Attribute tab of the properties window of the control in aspx page.
        object[] returnValue = new object[7];
        returnValue[0] = title;
        returnValue[1] = closeBtnText;
        returnValue[2] = content;
        returnValue[3] = persist;
        returnValue[4] = popupWindowWidth;
        returnValue[5] = popupWindowHeight;
        returnValue[6] = popupWindowScrollBar;
        return returnValue;
    }

      public void SetControl_Base(string control)
      {
          // Load data for each record and table UI control.
        
      }
      
    
    
        protected void SaveControlsToSession_Base()
        {
            base.SaveControlsToSession();
        
        }


        protected void ClearControlsFromSession_Base()
        {
            base.ClearControlsFromSession();
        
        }

        protected void LoadViewState_Base(object savedState)
        {
            base.LoadViewState(savedState);
        
        }


        protected object SaveViewState_Base()
        {
            
            return base.SaveViewState();
        }
        
    
     
      public void Page_PreRender_Base(object sender, System.EventArgs e)
      {
     
            // Call initialize function for theme selector for multi-color theme here
                   
            // Load data for each record and table UI control.
                  
            // Data bind for each chart UI control.
              
      }  
      
        
      //Initializes Sign In status text.
      protected virtual void UserStatusInit() {
      
        this.UserStatusLbl.Text = "";
      
      }
    
      //Initializes Sign In LinkButton.
      protected virtual void SignInButtonInit(){
      
        this.UserStatusLbl.Visible = false; 
        if(BaseClasses.Configuration.ApplicationSettings.Current.AuthenticationType == BaseClasses.Configuration.SecurityConstants.None){
        
            this.SignIn.Visible = false; 
           
            Control dvCtrl = this.Page.FindControlRecursively("dvSignIn");
            if (dvCtrl != null)
            {
                System.Web.UI.HtmlControls.HtmlGenericControl dvHtml = (System.Web.UI.HtmlControls.HtmlGenericControl)dvCtrl;
                dvHtml.Style.Add("display", "none");
            }
           
        }
        else {
        
            this.SignIn.Visible = true; 
          
            Control dvCtrl = this.Page.FindControlRecursively("dvSignIn");
            if (dvCtrl != null)
            {
                System.Web.UI.HtmlControls.HtmlGenericControl dvHtml = (System.Web.UI.HtmlControls.HtmlGenericControl)dvCtrl;
                dvHtml.Style.Remove("display");
            }
          
            this.UserStatusLbl.Visible = true;
        
        }
  
        switch (((BaseApplicationPage)(this.Page)).CurrentSecurity.GetUserStatus()) {
          case null:
          case "":
                                                  
              this.SignIn.Text = GetResourceValue("Txt:SignIn", "ViewpointXRef");
              this.SignIn.ToolTip = GetResourceValue("Txt:SignIn", "ViewpointXRef");
                
            break;
          default:
                                                  
            this.SignIn.Text = GetResourceValue("Txt:SignOut", "ViewpointXRef");
            this.SignIn.ToolTip = GetResourceValue("Txt:SignOut", "ViewpointXRef");
                
            break;
        }
      }
      //Performs SignIn and SignOut.
      protected virtual void SignInOutProceed(object sender)
      {
        string url;
        string deviceSize = ((BaseApplicationPage)(this.Page)).CheckDeviceSize();
        bool shouldRedirect;
        
        switch (((BaseApplicationPage)(this.Page)).CurrentSecurity.GetUserStatus())
        {
        case null:
        case "":
        if ( StringUtils.InvariantUCase(deviceSize).Equals(StringUtils.InvariantUCase("Small")) ) {
          url = BaseClasses.Configuration.ApplicationSettings.Current.MobileSignInPageUrl;
        } else {
          url = BaseClasses.Configuration.ApplicationSettings.Current.SignInPageUrl;
        }

        url = ".." + url.Substring(BaseClasses.Configuration.ApplicationSettings.Current.AppRootPath.Length-1);
        shouldRedirect = true;
        try
        {
          DbUtils.StartTransaction();
          url = ((BaseApplicationPage)this.Page).ModifyRedirectUrl(url, "", false);
          ((BaseApplicationPage)this.Page).CommitTransaction(sender);
        }
        catch (Exception ex)
        {
          ((BaseApplicationPage)this.Page).RollBackTransaction(sender);
          shouldRedirect = false;
          ((BaseApplicationPage)this.Page).ErrorOnPage = true;
          BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
         }
        finally
        {
          DbUtils.EndTransaction();
        }

        if (shouldRedirect)
        {
          ((BaseApplicationPage)this.Page).Response.Redirect(url);
        }
        break;

        default:
        if ( StringUtils.InvariantUCase(deviceSize).Equals(StringUtils.InvariantUCase("Small")) ) {
          url = BaseClasses.Configuration.ApplicationSettings.Current.MobileSignedOutPageUrl;
        } else {
          url = BaseClasses.Configuration.ApplicationSettings.Current.SignedOutPageUrl;
        }
        url = ".." + url.Substring(BaseClasses.Configuration.ApplicationSettings.Current.AppRootPath.Length-1);
        if(!string.IsNullOrEmpty((string)(Session["AppCultureUI"]))) 
        {
            if (url.Contains("?"))
                url = url + "&cultureui=" + (string)(Session["AppCultureUI"]);
            else
                url = url + "?cultureui=" + (string)(Session["AppCultureUI"]);
        }
        if (!string.IsNullOrEmpty(this.Request["RedirectStyle"]))
        {
            if (url.Contains("?"))
                url += "&RedirectStyle=" + this.Request["RedirectStyle"];        
            else
                url += "?RedirectStyle=" + this.Request["RedirectStyle"];        
        }
        
        shouldRedirect = true;
        try
        {
          DbUtils.StartTransaction();
          this.LogOut();
          url = ((BaseApplicationPage)this.Page).ModifyRedirectUrl(url, "", false);
          ((BaseApplicationPage)this.Page).CommitTransaction(sender);
        }
        catch (Exception ex)
        {
          ((BaseApplicationPage)this.Page).RollBackTransaction(sender);
          shouldRedirect = false;
          ((BaseApplicationPage)this.Page).ErrorOnPage = true;
          BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
        }
        finally
        {
          DbUtils.EndTransaction();
        }

        if (shouldRedirect)
        {
          ((BaseApplicationPage)this.Page).ShouldSaveControlsToSession = true;
          ((BaseApplicationPage)this.Page).Response.Redirect(url);
        }
        break;
      }
    }
    

    // Load data from database into UI controls.
    // Modify LoadData in Section 1 above to customize.  Or override DataBind() in
    // the individual table and record controls to customize.
    public void LoadData_Base()
    {
    
            try {
                
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {
    // Must start a transaction before performing database operations
    DbUtils.StartTransaction();
    }



                this.DataBind();
                
                
                    
    
                // Load and bind data for each record and table UI control.
                
    
                // Load data for chart.
                
            
                // initialize aspx controls
                
                SetSignIn();
              
    } catch (Exception ex) {
    // An error has occured so display an error message.
    BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "Page_Load_Error_Message", ex.Message);
    } finally {
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {
    // End database transaction
    DbUtils.EndTransaction();
    }
    }

    }

    public BaseClasses.Data.DataSource.EvaluateFormulaDelegate EvaluateFormulaDelegate;
    public string EvaluateFormula_Base(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables, bool includeDS)
        {
            FormulaEvaluator e = new FormulaEvaluator();

            // add variables for formula evaluation
            if (variables != null)
            {
                System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> enumerator = variables.GetEnumerator();
                while (enumerator.MoveNext())
                {
                    e.Variables.Add(enumerator.Current.Key, enumerator.Current.Value);
                }
            }
            
            if (includeDS)
            {
                
            }

            
            e.CallingControl = this;

            // All variables referred to in the formula are expected to be
            // properties of the DataSource.  For example, referring to
            // UnitPrice as a variable will refer to DataSource.UnitPrice
            e.DataSource = dataSourceForEvaluate;
            
            // Define the calling control.  
            e.CallingControl = this;

            object resultObj = e.Evaluate(formula);
            if (resultObj == null)
                return "";
            
            if ( !string.IsNullOrEmpty(format) && (string.IsNullOrEmpty(formula) || formula.IndexOf("Format(") < 0) )
            {
                return FormulaUtils.Format(resultObj, format);
            }
            else
            {
                return resultObj.ToString();
            }
        }		
        
        public string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate, string format, System.Collections.Generic.IDictionary<string, object> variables)
        {
            return EvaluateFormula(formula, dataSourceForEvaluate, format, variables, true);
        }
        
        
        private string EvaluateFormula(string formula, BaseClasses.Data.BaseRecord dataSourceForEvaluate)
        {
            return EvaluateFormula(formula, dataSourceForEvaluate, null, null, true);
        }
        
        public string EvaluateFormula(string formula, bool includeDS)
        {
            return EvaluateFormula(formula, null, null, null, includeDS);
        }
        
        public string EvaluateFormula(string formula)
        {
            return EvaluateFormula(formula, null, null, null, true);
        }
        
                
        // Write out the Set methods
        
        public void SetSignIn_Base()                
              
        {
        
   
        }
                

        // Write out the DataSource properties and methods
                

        // Write out event methods for the page events
        
        // event handler for LinkButton
        public void SignIn_Click_Base(object sender, EventArgs args)
        {
              
            try {
                
        this.SignInOutProceed(sender);
      
            } catch (Exception ex) {
                  ((BaseApplicationPage)this.Page).ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
#region Interface Properties
          
        [Bindable(true),
        Category("Behavior"),
        DefaultValue(""),
        NotifyParentProperty(true),
        DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public System.Web.UI.WebControls.DropDownList LanguageSelector {
                  get {
                  return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "LanguageSelector"); 
            }
        }
                
        [Bindable(true),
        Category("Behavior"),
        DefaultValue(""),
        NotifyParentProperty(true),
        DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public System.Web.UI.WebControls.Image Logo {
            get {
                return (System.Web.UI.WebControls.Image)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "_Logo");
            }
        }
                
        [Bindable(true),
        Category("Behavior"),
        DefaultValue(""),
        NotifyParentProperty(true),
        DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public System.Web.UI.WebControls.LinkButton SignIn {
            get {
                return (System.Web.UI.WebControls.LinkButton)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "_SignIn");
            }
        }
                
        [Bindable(true),
        Category("Behavior"),
        DefaultValue(""),
        NotifyParentProperty(true),
        DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public System.Web.UI.WebControls.DropDownList ThemeSelector {
                  get {
                  return (System.Web.UI.WebControls.DropDownList)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "ThemeSelector"); 
            }
        }
                
        [Bindable(true),
        Category("Behavior"),
        DefaultValue(""),
        NotifyParentProperty(true),
        DesignerSerializationVisibility(DesignerSerializationVisibility.Content)]
        public System.Web.UI.WebControls.Label UserStatusLbl {
            get {
                return (System.Web.UI.WebControls.Label)BaseClasses.Utils.MiscUtils.FindControlRecursively(this, "_UserStatusLbl");
            }
        }
                
      public override bool Visible {
          get {
              return base.Visible;
          }
          set {
              base.Visible = value;
          }
      }
      
      public override string ID {
          get {
              return base.ID;
          }
          set {
              base.ID = value;
          }
      }      
            
#endregion
    
            public new BaseApplicationPage Page {
            get {
                return ((BaseApplicationPage)base.Page);
            }
        }
        
      


#endregion

  

}
  
}

  