
// This file implements the code-behind class for SignOutMobile.aspx.
// SignOutMobile.Controls.vb contains the Table, Row and Record control classes
// for the page.  Best practices calls for overriding methods in the Row or Record control classes.

#region "Using statements"    

using System;
using System.Data;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
        
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using BaseClasses;
using BaseClasses.Utils;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;
using BaseClasses.Web.UI.WebControls;
        
using ViewpointXRef.Business;
using ViewpointXRef.Data;
        

#endregion

  
namespace ViewpointXRef.UI
{
  
public partial class SignOutMobile
        : BaseApplicationPage
// Code-behind class for the SignOutMobile page.
// Place your customizations in Section 1. Do not modify Section 2.
{
        
      #region "Section 1: Place your customizations here."

      public SignOutMobile()
        {
            this.Initialize();
    

        }
        
    public void SetPageFocus()
    {
      //To set focus on page load to a specific control pass this control to the SetStartupFocus method. To get a hold of a control
      //use FindControlRecursively method. For example:
      //System.Web.UI.WebControls.TextBox controlToFocus = (System.Web.UI.WebControls.TextBox)(this.FindControlRecursively("ProductsSearch"));
      //this.SetFocusOnLoad(controlToFocus);
      //If no control is passed or control does not exist this method will set focus on the first focusable control on the page.
      this.SetFocusOnLoad();	
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
        
      
      public override void SaveData()
      {
          this.SaveData_Base();
      }          
              
    
      public override void SetControl(string control)
      {
          this.SetControl_Base(control);
      }
    
    
      public void Page_PreInit(object sender, System.EventArgs e)
      {
          //override call to PreInit_Base() here to change top level master page used by this page.
          //For example for Microsoft SharePoint applications uncomment next line to use Microsoft SharePoint default master page
          //if(this.Master != null) this.Master.MasterPageFile = Microsoft.SharePoint.SPContext.Current.Web.MasterUrl;	
          //You may change here assignment of application theme
          try
          {
              this.PreInit_Base();
          }
          catch
          {
          
          } 
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
        
    
      protected override void BasePage_PreRender(object sender, EventArgs e)
      {
          base.BasePage_PreRender(sender, e);
          RegisterPostback();
      }
      
      protected void RegisterPostback()
      {
          Base_RegisterPostback();	  
      }
    
      
      #endregion

      // Page Event Handlers - buttons, sort, links
      
        public void ForgetSignInButton_Click(object sender, EventArgs args)
        {

          // Click handler for ForgetSignInButton.
          // Customize by adding code before the call or replace the call to the Base function with your own code.
          ForgetSignInButton_Click_Base(sender, args);
          // NOTE: If the Base function redirects to another page, any code here will not be executed.
        }
            
        public void MenuButton_Click(object sender, EventArgs args)
        {

          // Click handler for MenuButton.
          // Customize by adding code before the call or replace the call to the Base function with your own code.
          MenuButton_Click_Base(sender, args);
          // NOTE: If the Base function redirects to another page, any code here will not be executed.
        }
            
    
        // Write out the Set methods
        
        public void SetForgetSignInButton()
        {
            SetForgetSignInButton_Base(); 
        }              
            
        public void SetMenuButton()
        {
            SetMenuButton_Base(); 
        }              
                         
        
        // Write out the methods for DataSource
        


#endregion

#region "Section 2: Do not modify this section."

      
        private void Initialize()
        {
            // Called by the class constructor to initialize event handlers for Init and Load
            // You can customize by modifying the constructor in Section 1.
            this.Init += new EventHandler(Page_InitializeEventHandlers);
            this.PreInit += new EventHandler(Page_PreInit);
            this.Load += new EventHandler(Page_Load);

            EvaluateFormulaDelegate = new BaseClasses.Data.DataSource.EvaluateFormulaDelegate(EvaluateFormula);        
        }
        
    
         private static string cultureui = "";
    
        public System.Web.UI.WebControls.Literal PageTitle;
        
        public System.Web.UI.WebControls.Literal DialogTitle;
            
        public ThemeButtonMobile ForgetSignInButton;
                
        public ThemeButtonMobile MenuButton;
                
        public System.Web.UI.WebControls.Label SignOutMessage;
        
        public ValidationSummary ValidationSummary1;

  
      // Handles base.Init. Registers event handler for any button, sort or links.
      // You can add additional Init handlers in Section 1.
      public void Page_InitializeEventHandlers_Base(object sender, System.EventArgs e)
      {
    
        // This page does not have FileInput  control inside repeater which requires "multipart/form-data" form encoding, but it might
        // include ascx controls which in turn do have FileInput controls inside repeater. So check if they set Enctype property.
        if(!string.IsNullOrEmpty(this.Enctype)) this.Page.Form.Enctype = this.Enctype;
        	  
          this.PreRender += new EventHandler(Page_PreRender);    
          
          // Register the Event handler for any Events.
      
            


          // Setup the pagination events.
        
                    this.ForgetSignInButton.Button.Click += ForgetSignInButton_Click;
                        
                    this.MenuButton.Button.Click += MenuButton_Click;
                        
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
      
            //Event handler for cookie
            base.PreRender += new EventHandler(SignOut_PreRender);
    
             if (!this.IsPostBack)
             {
            
                    // Setup the header text for the validation summary control.
                    this.ValidationSummary1.HeaderText = GetResourceValue("ValidationSummaryHeaderText", "ViewpointXRef");
                 
                     this.StateInit();
                     cultureui = (string)(Session["AppCultureUI"]);
                     ((BaseApplicationPage)(this.Page)).CurrentSecurity.Logout((BaseApplicationPage)(this.Page));
             }
            
    // Load data only when displaying the page for the first time or if postback from child window
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {

    // Read the data for all controls on the page.
    // To change the behavior, override the DataBind method for the individual
    // record or table UI controls.
    this.LoadData();
    }

    
            Page.Title = GetResourceValue("Title:SignOut") + "" + "";
        
        if (!IsPostBack)
            ScriptManager.RegisterStartupScript(this, this.GetType(), "PopupScript", "openPopupPage('QPageSize');", true);
        
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
      
    
      
      public void SaveData_Base()
      {
      
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
        
    
     
      public void PreInit_Base()
      {
      //If it is SharePoint application this function performs dynamic Master Page assignment.
      
          try
          {
              this.SharePointPreInit();
          }
          catch
          {
              try
              {
                  //when running application in Live preview or outside of Microsoft SharePoint environment use proforma top level master
      
                  if  (!string.IsNullOrEmpty(this.Master.MasterPageFile)) {
          
                  this.Master.MasterPageFile = "../Master Pages/SharePointMobile.master";
            
                  }
          
              }
              catch
              {
              }
          }
            // if url parameter specified a master apge, load it here
            if (!string.IsNullOrEmpty(this.Page.Request["MasterPage"]))
            {
                string masterPage = (this.Page as BaseApplicationPage).GetDecryptedURLParameter("MasterPage");
                this.Page.MasterPageFile = masterPage;
            }
                   
       
      }
        
      public void SharePointPreInit()
      {
          
          //Check if application is running in SharePoint environment. Otherwise use ProForma master page.
          //Do not set master page if it has not been set 
          if  (!string.IsNullOrEmpty(this.Master.MasterPageFile))
          try
          {
              if(BaseClasses.Configuration.ApplicationSettings.Current.CurrentSharePointFunctions != null &&
                 BaseClasses.Configuration.ApplicationSettings.Current.CurrentSharePointFunctions.IsSPContextPresent()  && 
                 this.Master != null)
              {		 
              
                this.Master.MasterPageFile = "../Master Pages/SharePointMobile.master";
                                        
               }
               else 
               {
              
                  this.Master.MasterPageFile = "../Master Pages/SharePointMobile.master";
                
               }
           }
           catch
           {
              try
              {
                  //when running application in Live preview or outside of Microsoft SharePoint environment use proforma top level master
              
                  this.Master.MasterPageFile = "../Master Pages/SharePointMobile.master";
                
              }
              catch
              {
              }
           } 
          
      }
       
    //sec_comment: this method control switches off AutoLogin at sign out
    public void SignOut_PreRender(object sender, System.EventArgs e) {
    
        UI.SignInState state = new SignInState();
        this.ForgetSignInButton.Button.Enabled = (state.IsUNToRemember || state.IsPassToRemember);
        string isAutoLogin = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieAutoLogin());
        if((isAutoLogin==null) || (isAutoLogin == "")) {
            return; }
        else if(isAutoLogin.ToLower() == "true") {
            BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), "False");
        }                
    }
    
    private void StateInit() {
        UI.SignInState state = new UI.SignInState();
        string rUser = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieRememberName());
        if ((rUser != null) && (rUser.ToLower() == "true")) {
            state.IsUNToRemember = true;
        }
        else {
            state.IsUNToRemember = false;
        }
        string rPassword = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieRememberPassword());
        if ((rPassword != null) && (rPassword.ToLower() == "true")) {
            state.IsPassToRemember = true;
        }
        else {
            state.IsPassToRemember = false;
        }
    }
  
      public void Page_PreRender_Base(object sender, System.EventArgs e)
      {
     
          if ((this.Page as BaseApplicationPage).GetDecryptedURLParameter("RedirectStyle")  == "Popup")
              ScriptManager.RegisterStartupScript(this, this.GetType(), "QPopupCreateHeader", "QPopupCreateHeader();", true);          
                 
            // Load data for each record and table UI control.
                  
            // Data bind for each chart UI control.
              
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
                
                SetForgetSignInButton();
              
                SetMenuButton();
              
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
        
        public void SetForgetSignInButton_Base()                
              
        {
        
   
        }
            
        public void SetMenuButton_Base()                
              
        {
        
   
        }
                

        // Write out the DataSource properties and methods
                

        // Write out event methods for the page events
        
        // event handler for Button
        public void ForgetSignInButton_Click_Base(object sender, EventArgs args)
        {
              
              SignInState state = new SignInState();
              BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieUserName(), "");
              BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookiePassword(), "");
              state.IsUNToRemember = false;
              state.IsPassToRemember = false;
              BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberName(), Boolean.FalseString);
              BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberPassword(), Boolean.FalseString);
            try {
                
            } catch (Exception ex) {
                  this.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for Button
        public void MenuButton_Click_Base(object sender, EventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
            string url = @"../Menu Panels/StartMobile.aspx";
            
            if (!string.IsNullOrEmpty(this.Page.Request["RedirectStyle"])) 
                url += "?RedirectStyle=" + this.Page.Request["RedirectStyle"];
            
        bool shouldRedirect = true;
        string target = null;
        if (target == null) target = ""; // avoid warning on VS
      
            try {
                // Enclose all database retrieval/update code within a Transaction boundary
                DbUtils.StartTransaction();
                
                url = this.ModifyRedirectUrl(url, "",true);
              
            } catch (Exception ex) {
                  // Upon error, rollback the transaction
                  this.RollBackTransaction(sender);
                  shouldRedirect = false;
                  this.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
                DbUtils.EndTransaction();
            }
            if (shouldRedirect) {
                this.ShouldSaveControlsToSession = true;
      this.Response.Redirect(url);
        
            }
        
        }
            
            
        
      


#endregion

  
}
  
}
  