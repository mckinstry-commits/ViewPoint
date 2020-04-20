
// This file implements the code-behind class for SignInMobile.aspx.
// SignInMobile.Controls.vb contains the Table, Row and Record control classes
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
  
public partial class SignInMobile
        : BaseApplicationPage
// Code-behind class for the SignInMobile page.
// Place your customizations in Section 1. Do not modify Section 2.
{
        
      #region "Section 1: Place your customizations here."

      public SignInMobile()
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
      
      // Login methods perform user authentication, log user in and set roles for user using values in username and password text boxes.
      // These values could be entered by user or stored in cookie and populated from cookie. Password is stored in encrypted form.
      // You may overwrite Login methods here with your functionality
      public void Login(string redirectUrl)
      {
          this.Login_Base(redirectUrl);
      }

      //Login is called when user clicked OK on SignIn page or when Automatically SignIn is set to true
      public void Login(bool bRedirectOnSuccess)
      {
          this.Login_Base(bRedirectOnSuccess);
      }

      // This method stored values from username and password textboxes if login was successful into cookie. Password value is
      // stored in encrypted form. This method also stores state of all three checkboxes.
      protected void SetCookie()
      {
          this.SetCookie_Base();
      }

      // This method clears username and password from cookies if login failed.
      protected void ResetAutoLogin()
      {
          this.ResetAutoLogin_Base();
      }

      // This method clears username and password value from cookie if corresponding checkboxes are unchecked and
      // window is being closed and Cancel button was not clicked. If Cancel button was clicked this method does not
      // clear values.
      protected void StoreCookieOnClose()
      {
          this.StoreCookieOnClose_Base();
      }

      // This method sets value for AutoLogin checkbox in cookie when checkbox state changed.
      // Note that if you delete checkbox CheckBoxAutoLogin_CheckedChanged_Base() become an empty method doing nothing
      protected void CheckBoxAutoLogin_CheckedChanged()
      {
          this.CheckBoxAutoLogin_CheckedChanged_Base();
      }

      // This method stores value of the Remember Password checkbox in cookie and preserves password value which is
      // substituted with ****** pattern in the textbox.
      // Note that if you delete checkbox CheckBoxPass_CheckedChanged_Base() become an empty method doing nothing
      protected void CheckBoxPass_CheckedChanged()
      {
          this.CheckBoxPass_CheckedChanged_Base();
      }

      // This method stores value of Remember User checkbox in cookie
      // Note that if you delete checkbox CheckBoxUN_CheckedChanged_Base() become an empty method doing nothing
      protected void CheckBoxUN_CheckedChanged()
      {
          this.CheckBoxUN_CheckedChanged_Base();
      }

      // This method allows to preserve settings during post back. Settings of checkboxes and values of textboxes
      // are stored in session (password value is stored in encrypted form) and retrieved from session after postback.
      // Also original values are stored and if user clicks Cancel they are retrieved and preserved
      protected void SignIn_PreRender()
      {
          this.SignIn_PreRender_Base();
      }

      // This method is called when login is failed. It also reaises Login Failed event.
      protected void ProcessLoginFailed(string message, string userName)
      {
          this.ProcessLoginFailed_Base(message, userName);
      }
      
      // This method is called when login is succeeded. 
      protected void RedirectOnSuccess()
      {
          this.RedirectOnSuccess_Base();
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
      
        public void OKButton_Click(object sender, ImageClickEventArgs args)
        {
          // Click handler for OKButton.
          // Customize by adding code before the call or replace the call to the Base function with your own code.
          OKButton_Click_Base(sender, args);
          // NOTE: If the Base function redirects to another page, any code here will not be executed.
        }
            
        public void EmailLinkButton_Click(object sender, EventArgs args)
        {

          // Click handler for EmailLinkButton.
          // Customize by adding code before the call or replace the call to the Base function with your own code.
          EmailLinkButton_Click_Base(sender, args);
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
        
        public void SetOKButton()
        {
            SetOKButton_Base(); 
        }              
            
        public void SetEmailLinkButton()
        {
            SetEmailLinkButton_Base(); 
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

            this.LoginSucceeded += LoginSucceededHandler;
            this.LoginFailed += LoginFailedHandler;
            this.Unload += new EventHandler(OnCloseWindow);
            base.PreRender += new EventHandler(SignIn_PreRender);

            EvaluateFormulaDelegate = new BaseClasses.Data.DataSource.EvaluateFormulaDelegate(EvaluateFormula);        
        }
        
    
          // SignInState is a class to store values of cookies in the session state. It is also used by SignOut.ascx.vb(cs)
          private SignInState signInState;
      
        public System.Web.UI.WebControls.Literal PageTitle;
        
        public System.Web.UI.WebControls.CheckBox AutomaticallySignIn;
        
        public System.Web.UI.WebControls.Label AutomaticallySignInLabel;
        
        public ThemeButtonMobile MenuButton;
                
        public System.Web.UI.WebControls.Literal DialogTitle;
            
        public System.Web.UI.WebControls.LinkButton EmailLinkButton;
        
        public System.Web.UI.WebControls.Label LoginMessage;
        
        public System.Web.UI.WebControls.ImageButton OKButton;
        
        public System.Web.UI.WebControls.TextBox Password;
        
        public System.Web.UI.WebControls.Label PasswordLabel;
        
        public System.Web.UI.WebControls.Label PasswordMessage;
        
        public System.Web.UI.WebControls.CheckBox RememberPassword;
        
        public System.Web.UI.WebControls.Label RememberPasswordLabel;
        
        public System.Web.UI.WebControls.CheckBox RememberUserName;
        
        public System.Web.UI.WebControls.Label RememberUserNameLabel;
        
        public System.Web.UI.WebControls.TextBox UserName;
        
        public System.Web.UI.WebControls.Label UserNameLabel;
        
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
      
          this.RememberUserName.CheckedChanged += new EventHandler(RememberUserName_CheckedChanged);
      
          this.RememberPassword.CheckedChanged += new EventHandler(RememberPassword_CheckedChanged);
      
          this.AutomaticallySignIn.CheckedChanged += new EventHandler(AutomaticallySignIn_CheckedChanged);
      
            


          // Setup the pagination events.
        
                    this.OKButton.Click += OKButton_Click;
                        
                    this.EmailLinkButton.Click += EmailLinkButton_Click;
                        
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
    
             if (!this.IsPostBack)
             {
            
                    // Setup the header text for the validation summary control.
                    this.ValidationSummary1.HeaderText = GetResourceValue("ValidationSummaryHeaderText", "ViewpointXRef");
                 
             }
            
    // Load data only when displaying the page for the first time or if postback from child window
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {

    // Read the data for all controls on the page.
    // To change the behavior, override the DataBind method for the individual
    // record or table UI controls.
    this.LoadData();
    }

    
            Page.Title = GetResourceValue("Title:SignIn") + "" + "";
        
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
        
            this.SuccessURL = (string)(this.ViewState["SuccessURL"]);
            this.SuccessURLParam = (string)(this.ViewState["SuccessURLParam"]);
        
        }


        protected object SaveViewState_Base()
        {
        
            this.ViewState["SuccessURL"] = this.SuccessURL;
            this.ViewState["SuccessURLParam"] = this.SuccessURLParam;
            
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
                
                  //If you overwrite LoadDate do not forget to include call to this constructor!

                  {
                  this.signInState = new SignInState();
                  this.CookieInit();
                  }
              
    if ((!this.IsPostBack) || ( this.Request["__EVENTTARGET"] == "ChildWindowPostBack") || ( this.Request["__EVENTTARGET"] == "isd_geo_location")) {
    // Must start a transaction before performing database operations
    DbUtils.StartTransaction();
    }



                this.DataBind();
                
                
                    
    
                // Load and bind data for each record and table UI control.
                
    
                // Load data for chart.
                
            
                // initialize aspx controls
                
                SetOKButton();
              
                SetEmailLinkButton();
              
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
        
        public void SetOKButton_Base()                
              
        {
        
   
        }
            
        public void SetEmailLinkButton_Base()                
              
        {
        
   
        }
            
        public void SetMenuButton_Base()                
              
        {
        
   
        }
                

        // Write out the DataSource properties and methods
                

        // Write out event methods for the page events
        
        // event handler for ImageButton
        public void OKButton_Click_Base(object sender, ImageClickEventArgs args)
        {
              
            try {
                
                this.Login(@"");
      
            } catch (Exception ex) {
                  this.ErrorOnPage = true;

            // Report the error message to the end user
            BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
    
            } finally {
    
            }
    
        }
            
            
        
        // event handler for LinkButton
        public void EmailLinkButton_Click_Base(object sender, EventArgs args)
        {
              
            // The redirect URL is set on the Properties, Custom Properties or Actions.
            // The ModifyRedirectURL call resolves the parameters before the
            // Response.Redirect redirects the page to the URL.  
            // Any code after the Response.Redirect call will not be executed, since the page is
            // redirected to the URL.
            
              string url = BaseClasses.Configuration.ApplicationSettings.Current.MobileForgotUserPageUrl;
            
              if (!String.IsNullOrEmpty(this.UserName.Text))
              {
                  if (url.Contains("?"))
                    url += "&Username=" + this.UserName.Text;
                  else
                    url += "?Username=" + this.UserName.Text;                
              }     
        
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
        
            else if (target == null && !shouldRedirect)
            {
            this.ShouldSaveControlsToSession = true;
            this.CloseWindow(true);
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
            
            
        
          #region "Event Handlers"
          private void LoginSucceededHandler(object sender, System.EventArgs e)
          {
              this.SetCookie();
          }

          private void LoginFailedHandler(object sender, System.EventArgs e)
          {
              this.ResetAutoLogin();
          }

          private void OnCloseWindow(System.Object sender, System.EventArgs e)
          {
              this.StoreCookieOnClose();
          }

          //sets names to their current values before page loads. Need to do that because checkboxes trigger PostBack event and
          //values of textboxes would not be remembered otherwise
          private void SignIn_PreRender(object sender, System.EventArgs e)
          {
              this.SignIn_PreRender();
          }		
          
          private void RememberUserName_CheckedChanged(System.Object sender, System.EventArgs e)
          {
              this.CheckBoxUN_CheckedChanged();
          }
        
          private void RememberPassword_CheckedChanged(System.Object sender, System.EventArgs e)
          {
              this.CheckBoxPass_CheckedChanged();
          }
        
          private void AutomaticallySignIn_CheckedChanged(System.Object sender, System.EventArgs e)
          {
              this.CheckBoxAutoLogin_CheckedChanged();
          }
        
   #endregion
   #region "Cookie Initialization"
        //CookieInit initializes all cookie values.
        private void CookieInit()
        {
            if (this.signInState == null) {
                this.signInState = new SignInState();
            }
            this.UserName.TabIndex = 1;
            this.Password.TabIndex = 2;
            this.RememberUserName.TabIndex = 3;
            this.RememberUserName.AutoPostBack = true;
            this.RememberPassword.TabIndex = 4;
            this.RememberPassword.AutoPostBack = true;
            this.AutomaticallySignIn.TabIndex = 5;
                 			
            Crypto CheckCrypto = new Crypto(Crypto.Providers.DES);
            string key = BaseClasses.Configuration.ApplicationSettings.Current.CookieEncryptionKey;
            
            //isCancelled is set to true when cancel button is pressed
            this.signInState.IsCancelled = false;
            this.signInState.UserName = (BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieUserName()));
            
            //OriginalUserName and other Original... members of signInState keep original values which are used when 
            //Cancel button is pressed to set all cookies to their original values. That is necessary to do because
            //cookie are being modified when checkboxes are triggered.
            this.signInState.OriginalUserName = this.signInState.UserName;
            if (((this.signInState.UserName != null)) && !string.IsNullOrEmpty(this.signInState.UserName)) {
                this.signInState.UserName = CheckCrypto.Decrypt(this.signInState.UserName, key, System.Text.Encoding.Unicode, false);
            }
            else {
                this.signInState.UserName = "";
            }
            this.signInState.Password = (BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookiePassword()));
            this.signInState.OriginalPassword = this.signInState.Password;
            if (((this.signInState.Password != null)) && !string.IsNullOrEmpty(this.signInState.Password)) {
                this.signInState.Password = CheckCrypto.Decrypt(this.signInState.Password, key, System.Text.Encoding.Unicode, false);
            }
            else {
                this.signInState.Password = "";
            }
            string rUser = (BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieRememberName()));
            this.signInState.OriginalRememberUser = rUser;
            
            //Need to check if check boxes are set to visible in Application Generation Options. If not - do not show them and
            //set to false their values
            if (StringUtils.InvariantLCase(BaseClasses.Configuration.ApplicationSettings.Current.ShowRememberUserCheckBox) == "false") {
                
                this.RememberUserName.Visible = false;
                this.RememberUserName.Enabled = false;
                this.RememberUserNameLabel.Visible = false;
                this.RememberUserNameLabel.Enabled = false;
                this.signInState.IsUNToRemember = false;
            }
            else {
                if (((rUser != null)) && (rUser.ToLower() == "true")) {
                    this.signInState.IsUNToRemember = true;
                }
                else {
                    this.signInState.IsUNToRemember = false;
                    
                }
            }
            
            string rPassword = (BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieRememberPassword()));
            this.signInState.OriginalRememberPassword = rPassword;
            if (StringUtils.InvariantLCase(BaseClasses.Configuration.ApplicationSettings.Current.ShowRememberPasswordCheckBox) == "false") {
            
                this.RememberPassword.Enabled = false;
                this.RememberPassword.Visible = false;
                this.RememberPasswordLabel.Visible = false;
                this.RememberPasswordLabel.Enabled = false;				
                this.signInState.IsPassToRemember = false;
            }
            else {
                if ((rPassword != null) && (rPassword.ToLower() == "true")) {
                    this.signInState.IsPassToRemember = true;
                }
                else {
                    this.signInState.IsPassToRemember = false;
                }
            }
            
            if ((this.signInState.IsUNToRemember)) {
                if ((!string.IsNullOrEmpty(this.signInState.UserName))) {
                   this.RememberUserName.Checked = this.signInState.IsUNToRemember;
                    this.UserName.Text = this.signInState.UserName;			
                }
            }
            			
            if ((!string.IsNullOrEmpty(this.signInState.Password))) {
                this.RememberPassword.Checked = this.signInState.IsPassToRemember;
                if (this.Password.Text != "**********" && (!string.IsNullOrEmpty(this.Password.Text.Trim()))) {
                    this.signInState.Password = this.Password.Text;
                }
                else {
                    this.Password.Text = this.signInState.Password;
                }
                this.signInState.LoginPassword = this.signInState.Password;
                this.Password.Attributes.Add("value", "**********");
            }	
            else if (string.IsNullOrEmpty(this.Password.Text)) {
                this.Password.Attributes.Add("value", "");
                this.signInState.LoginPassword = "";
            }
            else {
                this.signInState.LoginPassword = "";
            }		        
            
            
            string isAutoLogin = BaseClasses.Utils.NetUtils.GetCookie(NetUtils.CookieAutoLogin());
            if (StringUtils.InvariantLCase(BaseClasses.Configuration.ApplicationSettings.Current.ShowAutoSignInCheckBox) == "false") {
                this.AutomaticallySignIn.Visible = false;
                this.AutomaticallySignIn.Enabled = false;
                this.AutomaticallySignInLabel.Visible = false;
                this.AutomaticallySignInLabel.Enabled = false;
                this.signInState.IsAutoLogin = false;
            }
            
            //Get value of automatically login cookie, if not set AND security used is Active Directory, than use
            //default value which is True to allow user be automatically signed in with his current credentials
            if ((isAutoLogin == null || string.IsNullOrEmpty(isAutoLogin))) {
                switch (BaseClasses.Configuration.ApplicationSettings.Current.AuthenticationType) {
                    case BaseClasses.Configuration.SecurityConstants.ActiveDirectorySecurity:
                        BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), "true");
                        isAutoLogin = "true";
                        break;
                    case BaseClasses.Configuration.SecurityConstants.WindowsSecurity:
                        BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), "true");
                        isAutoLogin = "true";
                        break;
                    case BaseClasses.Configuration.SecurityConstants.ProprietorySecurity:
                        BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), "false");
                        isAutoLogin = "false";
                        break;
                    case BaseClasses.Configuration.SecurityConstants.None:
                        BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), "false");
                        isAutoLogin = "false";
                        break;
                }
            }

            if (((isAutoLogin.ToLower() == "true") && this.signInState.IsAutoLogin))
            {
                this.AutomaticallySignIn.Checked = true;
                if ((!this.signInState.IsUNToRemember || !this.signInState.IsPassToRemember))
                {
                    this.UserName.Text = "";
                    this.Password.Attributes.Add("value", "");
                    this.signInState.LoginPassword = "";
                }
                this.Login(true);
            }
            else
            {
                this.AutomaticallySignIn.Checked = false;
            }
        }
        
        //Sets cookies when login succeeded
        private void SetCookie_Base()
        {
            if (this.signInState == null) {
                this.signInState = new SignInState();
            }
            Crypto CheckCrypto = new Crypto(Crypto.Providers.DES);
            string key = BaseClasses.Configuration.ApplicationSettings.Current.CookieEncryptionKey;
            if ((this.signInState.IsUNToRemember)) {
                string uNameEncrypted = CheckCrypto.Encrypt(this.UserName.Text, key, System.Text.Encoding.Unicode, false);
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieUserName(), uNameEncrypted);
            }
            else {
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieUserName(), "");
            }
            if ((this.signInState.IsPassToRemember)) {
                if ((this.Password.Text != "**********" && !string.IsNullOrEmpty(this.Password.Text.Trim()))) {
                    this.signInState.Password = this.Password.Text;
                }
                string passwordEncrypted = CheckCrypto.Encrypt(this.signInState.Password, key, System.Text.Encoding.Unicode, false);
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookiePassword(), passwordEncrypted);
            }
            else {
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookiePassword(), "");
            }
            BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberName(), this.signInState.IsUNToRemember.ToString());
            BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberPassword(), this.signInState.IsPassToRemember.ToString());
            this.signInState.IsAutoLogin = true;
        }
 
 

        //Resets AutoLogin when login failed
        private void ResetAutoLogin_Base()
        {
            if (this.signInState == null) {
                this.signInState = new SignInState();
            }
            this.signInState.IsAutoLogin = false;
            if ((!this.signInState.IsUNToRemember)) {
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieUserName(), "");
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberName(), this.signInState.IsUNToRemember.ToString());
            }
            if ((!this.signInState.IsPassToRemember)) {
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookiePassword(), "");
                BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberPassword(), this.signInState.IsPassToRemember.ToString());
            }
        }
        
        public void StoreCookieOnClose_Base()
        {
            if (this.signInState == null) {
                this.signInState = new SignInState();
            }
            //Check if Cancel button clicked. If not and any "remember" box is unchecked, clear content
            if ((!this.signInState.IsCancelled)) {
                if ((!this.signInState.IsUNToRemember)) {
                    BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberName(), bool.FalseString);
                    BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieUserName(), "");
                }
                if ((!this.signInState.IsPassToRemember)) {
                    BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieRememberPassword(), bool.FalseString);
                    BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookiePassword(), "");
                }
            }
        }
        
        //This method handles change of state for AutoLogin checkbox if this checkbox is present.
        //If checkbox was removed from the page this method has empty content.
        private void CheckBoxAutoLogin_CheckedChanged_Base()
        {   
            string key = BaseClasses.Configuration.ApplicationSettings.Current.CookieEncryptionKey;
            bool isAutoLogin = this.AutomaticallySignIn.Checked;
            BaseClasses.Utils.NetUtils.SetCookie(NetUtils.CookieAutoLogin(), isAutoLogin.ToString());
        
        }
        
        //This method handles change of state for Remember Password checkbox if this checkbox is present.
        //If checkbox was removed from the page this method has empty content.
        private void CheckBoxPass_CheckedChanged_Base()
        {   
            if (this.signInState == null) {
                this.signInState = new SignInState();
            } 
            if ((this.RememberPassword.Checked == true)) {
                this.signInState.IsPassToRemember = true;
                if ((this.Password.Text != "**********")) {
                    this.signInState.Password = this.Password.Text;
                }
            }
            else {
                this.signInState.IsPassToRemember = false;
                if ((this.Password.Text != "**********" && !string.IsNullOrEmpty(this.Password.Text.Trim()))) {
                    this.signInState.Password = this.Password.Text;
                }
            } 
        }
        
        //This method handles change of state for Remember UserName checkbox if this checkbox is present.
        //If checkbox was removed from the page this method has empty content. 
        private void CheckBoxUN_CheckedChanged_Base()
        {  
            if (this.signInState == null) {
                this.signInState = new SignInState();
            }  
            if ((this.RememberUserName.Checked == true)) {
                this.signInState.IsUNToRemember = true;
                if ((this.Password.Text != "**********")) {
                    this.signInState.Password = this.Password.Text;
                }
            }
            else {
                this.signInState.IsUNToRemember = false;
                this.signInState.UserName = "";
                if ((this.Password.Text != "**********" && !string.IsNullOrEmpty(this.Password.Text.Trim()))) {
                    this.signInState.Password = this.Password.Text;
                }
            } 
        }

        private void SignIn_PreRender_Base()
        {
        
        // If a UserIdentity table with a UserEmail column is not defined, do not show the email password link
        IUserIdentityTable userTable = (IUserIdentityTable)(BaseClasses.Configuration.ApplicationSettings.Current.GetUserIdentityTable());
        this.EmailLinkButton.Visible = (!(null == userTable || null == userTable.UserEmailColumn))
          && BaseClasses.Configuration.ApplicationSettings.Current.AuthenticationType == BaseClasses.Configuration.SecurityConstants.ProprietorySecurity;
      
        if (this.signInState == null) {
          this.signInState = new SignInState();
        }

        if ((this.signInState.IsUNToRemember)) {
          if ((!string.IsNullOrEmpty(this.signInState.UserName))) {
             this.RememberUserName.Checked = this.signInState.IsUNToRemember;
             this.UserName.Text = this.signInState.UserName;
                }
            }
            
            if ((!string.IsNullOrEmpty(this.signInState.Password))) {
                this.RememberPassword.Checked = this.signInState.IsPassToRemember;
                if ((this.Password.Text != "**********"  && !string.IsNullOrEmpty(this.Password.Text))) {
                    this.signInState.Password = this.Password.Text;
                }
                else {
                    this.Password.Text = this.signInState.Password;
                }
                this.signInState.LoginPassword = this.signInState.Password;
                this.Password.Attributes.Add("value", "**********");
            }
            else if (string.IsNullOrEmpty(this.Password.Text)) {
                this.Password.Attributes.Add("value", "");
                this.signInState.LoginPassword = "";
            }
            else {
                this.signInState.LoginPassword = "";
                
            }
        }
   #endregion
        
   #region " Login Methods "
        public virtual void Login_Base(string redirectUrl)
        {
            if ((redirectUrl != null) &&  !string.IsNullOrEmpty(redirectUrl)) {
                Login_Base(false);
            }
            else {
                Login_Base(true);
            }
        }

        //Performs the login. Passes username and password to current security SetLoginInfo method to validate user
        //If successful raises LoginSucceeded event and redirects back to page, if fails calls ProcessLoginFailed
        public virtual void Login_Base(bool bRedirectOnSuccess)
        {
            string strUserName = "";
            strUserName = this.UserName.Text;
            string strPassword = "";
            strPassword = this.Password.Text;
            if ((this.Password.Text == "**********" || string.IsNullOrEmpty(this.Password.Text))) {
                SignInState state = new SignInState();
                strPassword = state.LoginPassword;
            }
            string errMessage = "";
            string clientIPAddress = this.Page.Request.ServerVariables["REMOTE_ADDR"] + " (HTML)";
           
            bool bSuccess = false;
            try {
                //SetLoginInfo will do the work of authenticating the name and password
                bSuccess = ((BaseApplicationPage)this.Page).CurrentSecurity.SetLoginInfo(strUserName, strPassword, ref errMessage);
            }
            catch (System.Threading.ThreadAbortException ex) {
                throw ex;
            }
            catch (System.Exception e) {
                ProcessLoginFailed(ERR_INTERNAL_ERROR + " " + e.Message, "");
            }
            
            //success!
            if ((bSuccess)) {
                if (LoginSucceeded != null) {
                    LoginSucceeded(this, new System.EventArgs());
                }
                
                if (bRedirectOnSuccess) {
                    RedirectOnSuccess();
                }
            }
            else {
                if ((errMessage != null) && !string.IsNullOrEmpty(errMessage)) {
                    ProcessLoginFailed(errMessage, strUserName);
                }
                else {
                    ProcessLoginFailed(ERR_INVALID_LOGIN_INFO, strUserName);
                }
            }
        }

        protected void RedirectOnSuccess_Base()
        {
            if (this.SuccessURL != null && this.SuccessURL.Trim().Length > 0) {
              this.Page.Response.Redirect(this.SuccessURL);
            }
            else {
              ((BaseClasses.Web.UI.BasePage)this.Page).RedirectBack(true);
            }
        }

        //Login failed, so redirect back to the login page passing information on the URL
        protected void ProcessLoginFailed_Base(string message, string userName)
        {
          if (LoginFailed != null) {
            LoginFailed(this, new System.EventArgs());
          }

          string url = null;
          string deviceSize = ((BaseApplicationPage)(this.Page)).CheckDeviceSize();
          if ( StringUtils.InvariantUCase(deviceSize).Equals(StringUtils.InvariantUCase("Small")) ) {
            url = BaseClasses.Configuration.ApplicationSettings.Current.MobileSignInPageUrl + "?message=" + this.Page.Server.UrlEncode(message);
          } else {
            url = BaseClasses.Configuration.ApplicationSettings.Current.SignInPageUrl + "?message=" + this.Page.Server.UrlEncode(message);
          }

          if ((this.SuccessURLParam != null) && this.SuccessURLParam.Trim().Length > 0) {
            url += "&" + this.SuccessURLParam + "=" + this.SuccessURL;
          }
            
          if ((!string.IsNullOrEmpty(userName))) {
            url = url + "&UserName=" + userName.Trim();
          }
          url = url + "&mode=yes";
          
          if ((!string.IsNullOrEmpty(this.Page.Request["MasterPage"]))) {
            url = url + "&MasterPage=" + this.Page.Request["MasterPage"];
          }
          
          if ((!string.IsNullOrEmpty(this.Page.Request["Target"]))) {
            url = url + "&Target=" + this.Page.Request["Target"];
          }
          
          if ((!string.IsNullOrEmpty(this.Page.Request["RedirectStyle"]))) {
            url = url + "&RedirectStyle=" + this.Page.Request["RedirectStyle"];
          }       
          
          ((BaseApplicationPage)this.Page).SystemUtils.shouldRollBackTransaction = true;
          ((BaseClasses.Web.UI.BasePage)this.Page).RemoveCurrentRequestFromSessionNavigationHistory();
          BaseClasses.Utils.NetUtils.SetCookie(BaseClasses.Utils.NetUtils.CookieAutoLogin(), "false");
          System.Web.SessionState.HttpSessionState Session = System.Web.HttpContext.Current.Session;
          Session.Abandon();
          this.Page.Response.Redirect(url);
          this.Page.Response.End();
        }
   #endregion
   #region " Constants "
        const int INVALID_USER_INFO = -2147467259;
   #endregion
        

   #region " Events "
        public delegate void LoginSucceededDelegate(object sender, System.EventArgs e);
        public event LoginSucceededDelegate LoginSucceeded;

        public delegate void LoginFailedDelegate(object sender, System.EventArgs e);
        public event LoginFailedDelegate LoginFailed;
   #endregion

   #region " Public Properties "
        //URL to redirect to when login is successful
        protected string _successURL;
        public string SuccessURL {
            get { return this._successURL; }
            set { this._successURL = value; }
        }

        //URL parameter name for SuccessURL
        protected string _successURLParm;
        public string SuccessURLParam {
            get { return this._successURLParm; }
            set { this._successURLParm = value; }
        }
   #endregion

   #region " Misc Methods "

        //Sets the text of the login message
        protected override void OnDataBinding(System.EventArgs e)
        {
            base.OnDataBinding(e);
            
            string strMessage = this.Page.Request.QueryString["Message"];
            if (!((strMessage == null))) {
                strMessage = strMessage.Replace("<br>", "");
                strMessage = this.Page.Server.HtmlEncode(strMessage);
            }
            
            this.UserName.Text = this.Page.Request.QueryString["UserName"];
            if (!((this.UserName.Text == null))) {
                this.UserName.Text = this.Page.Server.HtmlEncode(this.UserName.Text);
            }
    	    
            if ((this.SuccessURLParam != null) && this.SuccessURLParam.Trim().Length > 0) {
                this.SuccessURL = this.Page.Request.QueryString[this.SuccessURLParam.Trim()];
                if (((this.SuccessURL != null))) {
                    this.SuccessURL = this.SuccessURL.Trim();
                    this.SuccessURL = this.Page.Server.HtmlEncode(this.SuccessURL);
                }
            }
            
            // Set the Login Message
            if (!(strMessage == null)) {
                this.LoginMessage.Text = strMessage;
            }
            else if (!(this.SuccessURL == null) && !string.IsNullOrEmpty(this.SuccessURL)) {
                this.LoginMessage.Text = LOGIN_MSG_SESSION_INVALID;
            }
            else {
                this.LoginMessage.Text = LOGIN_MSG;
            }
        }

        #endregion

        #region " Protected Properties "

        public string ERR_INVALID_LOGIN_INFO {
        get { return ((BaseApplicationPage)this.Page).GetResourceValue("Err:InvalidLoginInfo", "ViewpointXRef"); }
        }


        public string ERR_INTERNAL_ERROR {
            get { return ((BaseApplicationPage)this.Page).GetResourceValue("Err:InternalErrorLogin", "ViewpointXRef"); }
        }


        public string LOGIN_MSG {
            get { return ((BaseApplicationPage)this.Page).GetResourceValue("Txt:LoginMsg", "ViewpointXRef"); }
        }


        public string LOGIN_MSG_SESSION_INVALID {
            get { return ((BaseApplicationPage)this.Page).GetResourceValue("Txt:LoginMsgSessionInvalid", "ViewpointXRef"); }
        }
   #endregion

      
      


#endregion

  
}
  
}
  