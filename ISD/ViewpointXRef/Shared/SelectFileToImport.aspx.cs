// This file implements the code-behind class for SelectFileToImport.aspx.
// App_Code\FirstPage.Controls.vb contains the Table, Row and Record control classes
// for the page.  Best practices calls for overriding methods in the Row or Record control classes.

#region "Using statements"    

using System;
using System.Data;
using System.Collections;
using System.ComponentModel;
using System.Web;
using System.IO;
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
  
public partial class SelectFileToImport
        : BaseApplicationPage
// Code-behind class for the SelectFileToImport page.
// Place your customizations in Section 1. Do not modify Section 2.
{

        /// <summary>
        /// Head1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.HtmlControls.HtmlHead Head1;
        /// <summary>
        /// Body1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.HtmlControls.HtmlGenericControl Body1;
        /// <summary>
        /// Form1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.HtmlControls.HtmlForm Form1;
        /// <summary>
        /// ScrollCoordinates control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::BaseClasses.Web.UI.WebControls.ScrollCoordinates ScrollCoordinates;
        /// <summary>
        /// PageSettings control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::BaseClasses.Web.UI.WebControls.BasePageSettings PageSettings;
        /// <summary>
        /// scriptManager1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.ScriptManager scriptManager1;
        /// <summary>
        /// InfoLabel control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label InfoLabel;
        /// <summary>
        /// InputFile control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.HtmlControls.HtmlInputFile InputFile;
        /// <summary>
        /// fileInfo control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label fileInfo;
        /// <summary>
        /// FileSelectionPanel control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.UpdatePanel FileSelectionPanel;
        /// <summary>
        /// rbtnCSV control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.RadioButton rbtnCSV;
        /// <summary>
        /// rbtnTAB control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.RadioButton rbtnTAB;
        /// <summary>
        /// rbtnExcel control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.RadioButton rbtnExcel;
        /// <summary>
        /// ExcelSheetname control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label ExcelSheetname;
        /// <summary>
        /// txtExcelSheetname control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.TextBox txtExcelSheetname;
        /// <summary>
        /// rbtnAccess control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.RadioButton rbtnAccess;
        /// <summary>
        /// AccessTableName control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label AccessTableName;
        /// <summary>
        /// txtAccessTableName control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.TextBox txtAccessTableName;
        /// <summary>
        /// AccessPassword control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label AccessPassword;
        /// <summary>
        /// txtAccessPassword control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.TextBox txtAccessPassword;
        /// <summary>
        /// AccessPasswordOptional control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Label AccessPasswordOptional;
        /// <summary>
        /// NextButton control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::ViewpointXRef.UI.ThemeButton NextButton;
        /// <summary>
        /// ValidationSummary1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.ValidationSummary ValidationSummary1;        


#region "Section 1: Place your customizations here."    

        public SelectFileToImport()
        {
            this.Initialize();
            this.PreInit += new EventHandler(Page_PreInit);
        }
        
        public void Page_PreInit(System.Object sender, System.EventArgs e)
        {
           this.Page_PreInit_Base();
        }


        public void LoadData()
        {
            // LoadData reads database data and assigns it to UI controls.
            // Customize by adding code before or after the call to LoadData_Base()
            // or replace the call to LoadData_Base().
            LoadData_Base();

            this.Page.Title = this.GetResourceValue("Import:Step1", this.AppName, true);
            this.InfoLabel.Text = this.GetResourceValue("Import:InfoText", this.AppName);
            this.fileInfo.Text = this.GetResourceValue("Import:FileInfoText", this.AppName);
            this.rbtnCSV.Text = this.GetResourceValue("Import:CSVText", this.AppName) + " [" + System.Globalization.CultureInfo.CurrentUICulture.TextInfo.ListSeparator + "]";
            this.rbtnTAB.Text = this.GetResourceValue("Import:TABText", this.AppName);
            this.rbtnExcel.Text = this.GetResourceValue("Import:ExcelText", this.AppName);
            this.rbtnAccess.Text = this.GetResourceValue("Import:AccessText", this.AppName);
            this.AccessPassword.Text = this.GetResourceValue("Import:AccessPassword", this.AppName);
            this.AccessTableName.Text = this.GetResourceValue("Import:AccessTable", this.AppName);
            this.ExcelSheetname.Text = this.GetResourceValue("Import:ExcelSheet", this.AppName);
            this.AccessPasswordOptional.Text = this.GetResourceValue("Import:AccessPasswordOptional", this.AppName);

            this.txtAccessPassword.Enabled = false;
            this.txtAccessTableName.Enabled = false;
            this.txtExcelSheetname.Enabled = false;

        }
    public string AppName
    {
        get
        {
            return BaseClasses.Configuration.ApplicationSettings.Current.GetAppSetting(BaseClasses.Configuration.ApplicationSettings.ConfigurationKey.ApplicationName);
        }
    }
    public  string TableName
    {
        get
        {
            return this.Decrypt(BaseClasses.Utils.NetUtils.GetUrlParam(this,"TableName" , true));
        }
    }
#region "Ajax Functions"

        [System.Web.Services.WebMethod()]
        public static Object[] GetRecordFieldValue(String tableName , 
                                                    String recordID , 
                                                    String columnName, 
                                                    String title, 
                                                    bool persist, 
                                                    int popupWindowHeight, 
                                                    int popupWindowWidth, 
                                                    bool popupWindowScrollBar)
        {
            // GetRecordFieldValue gets the pop up window content from the column specified by
            // columnName in the record specified by the recordID in data base table specified by tableName.
            // Customize by adding code before or after the call to  GetRecordFieldValue_Base()
            // or replace the call to  GetRecordFieldValue_Base().

            return GetRecordFieldValue_Base(tableName, recordID, columnName, title, persist, popupWindowHeight, popupWindowWidth, popupWindowScrollBar);
        }

        [System.Web.Services.WebMethod()]
        public static object[] GetImage(String tableName,
                                        String recordID, 
                                        String columnName, 
                                        String title, 
                                        bool persist, 
                                        int popupWindowHeight, 
                                        int popupWindowWidth, 
                                        bool popupWindowScrollBar)
        {
            // GetImage gets the Image url for the image in the column "columnName" and
            // in the record specified by recordID in data base table specified by tableName.
            // Customize by adding code before or after the call to  GetImage_Base()
            // or replace the call to  GetImage_Base().
            return GetImage_Base(tableName, recordID, columnName, title, persist, popupWindowHeight, popupWindowWidth, popupWindowScrollBar);
        }
        
    

    
#endregion

    // Page Event Handlers - buttons, sort, links
    public void NextButton_Click(object sender, EventArgs args)
    {
        NextButton_Click_Base(sender, args);
    }

    
#endregion

#region "Section 2: Do not modify this section."

      
        private void Initialize()
        {
            // Called by the class constructor to initialize event handlers for Init and Load
            // You can customize by modifying the constructor in Section 1.
            this.Init += new EventHandler(Page_InitializeEventHandlers);
            this.Load += new EventHandler(Page_Load);

            
        }

        // Handles base.Init. Registers event handler for any button, sort or links.
        // You can add additional Init handlers in Section 1.
        protected virtual void Page_InitializeEventHandlers(object sender, System.EventArgs e)
        {
            // Register the Event handler for any Events.
        
             
              this.NextButton.Button.Click += new EventHandler(NextButton_Click);
             
        }

        protected void Page_PreInit_Base()
        {
            //if this is multicolor theme assign correct theme
            string selectedTheme = this.GetSelectedTheme();
            if (!string.IsNullOrEmpty(selectedTheme)) this.Page.Theme = selectedTheme;
        }

        // Handles base.Load.  Read database data and put into the UI controls.
        // You can add additional Load handlers in Section 1.
        protected virtual void Page_Load(object sender, EventArgs e)
        {
        
            // Check if user has access to this page.  Redirects to either sign-in page
            // or 'no access' page if not. Does not do anything if role-based security
            // is not turned on, but you can override to add your own security.
            this.Authorize(this.GetAuthorizedRoles());
                // Load data only when displaying the page for the first time
            if ((!this.IsPostBack)) {   
        
                // Setup the header text for the validation summary control.
                this.ValidationSummary1.HeaderText = GetResourceValue("ValidationSummaryHeaderText", this.AppName);
             

        // Read the data for all controls on the page.
        // To change the behavior, override the DataBind method for the individual
        // record or table UI controls.
        this.LoadData();
        
    }
    }

    public static object[] GetRecordFieldValue_Base(String tableName , 
                                                    String recordID , 
                                                    String columnName, 
                                                    String title, 
                                                    bool persist, 
                                                    int popupWindowHeight, 
                                                    int popupWindowWidth, 
                                                    bool popupWindowScrollBar)
    {
        string content =  NetUtils.EncodeStringForHtmlDisplay(BaseClasses.Utils.MiscUtils.GetFieldData(tableName, recordID, columnName)) ;
        // returnValue is an array of string values.
        // returnValue(0) represents title of the pop up window.
        // returnValue(1) represents content ie, image url.
        // returnValue(2) represents whether pop up window should be made persistant
        // or it should close as soon as mouse moves out.
        // returnValue(3), (4) represents pop up window height and width respectivly
        // returnValue(5) represents whether pop up window should contain scroll bar.
        // (0),(2),(3) and (4) is initially set as pass through attribute.
        // They can be modified by going to Attribute tab of the properties window of the control in aspx page.
        object[] returnValue = new object[6];
        returnValue[0] = title;
        returnValue[1] = content;
        returnValue[2] = persist;
        returnValue[3] = popupWindowWidth;
        returnValue[4] = popupWindowHeight;
        returnValue[5] = popupWindowScrollBar;
        return returnValue;
    }

    public static object[] GetImage_Base(String tableName, 
                                          String recordID, 
                                          String columnName, 
                                          String title, 
                                          bool persist, 
                                          int popupWindowHeight, 
                                          int popupWindowWidth, 
                                          bool popupWindowScrollBar)
    {
        string  content= "<IMG alt =\"" + title + "\" src =" + "\"../Shared/ExportFieldValue.aspx?Table=" + tableName + "&Field=" + columnName + "&Record=" + recordID + "\"/>";
        // returnValue is an array of string values.
        // returnValue(0) represents title of the pop up window.
        // returnValue(1) represents content ie, image url.
        // returnValue(2) represents whether pop up window should be made persistant
        // or it should close as soon as mouse moves out.
        // returnValue(3), (4) represents pop up window height and width respectivly
        // returnValue(5) represents whether pop up window should contain scroll bar.
        // (0),(2),(3), (4) and (5) is initially set as pass through attribute.
        // They can be modified by going to Attribute tab of the properties window of the control in aspx page.
        object[] returnValue = new object[6];
        returnValue[0] = title;
        returnValue[1] = content;
        returnValue[2] = persist;
        returnValue[3] = popupWindowWidth;
        returnValue[4] = popupWindowHeight;
        returnValue[5] = popupWindowScrollBar;
        return returnValue;
    }
  

    // Load data from database into UI controls.
    // Modify LoadData in Section 1 above to customize.  Or override DataBind() in
    // the individual table and record controls to customize.
    public void LoadData_Base()
    {
        
        
        }

        // Write out event methods for the page events
        
        
            
        // event handler for Button with Layout
        public void NextButton_Click_Base(object sender, EventArgs args)
        {
            System.Web.UI.HtmlControls.HtmlInputFile inputFile;
            inputFile = ((System.Web.UI.HtmlControls.HtmlInputFile)(this.Page.FindControl("InputFile")));

            String tmpPath = String.Empty;


            if ((!(inputFile.PostedFile == null) && (inputFile.PostedFile.ContentLength > 0)))
            {
                if (ValidateFileTypeSupported(inputFile.PostedFile.FileName))
                {
                    lock (this)
                    {
                        tmpPath = Server.MapPath("../Temp/" + Guid.NewGuid().ToString());
                    }
                    this.Page.Session["FilePath"] = tmpPath;

                    try
                    {
                        inputFile.PostedFile.SaveAs(tmpPath);
                        this.Page.Response.Redirect("ImportData.aspx?TableName=" + this.Encrypt(this.TableName)); // pass the table name with encryption.    
                    }
                    catch
                    {
                        String msg  = this.GetResourceValue("Import:FailedToSaveFile", this.AppName);
                        BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", msg);
                    }

                }
                else
                {

                    BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", this.GetResourceValue("Import:FileTypeMsg", this.AppName));
                }
            }
            else
            {
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", this.GetResourceValue("Import:SelectFile", this.AppName));
            }

        }
        protected void rbtnCSV_CheckedChanged(object sender, EventArgs e)
        {
            //this.pnlCSV.Enabled = true;
            //this.pnlTAB.Enabled = false;
            //this.pnlExcel.Enabled = false;
            //this.pnlAccess.Enabled = false;
            this.txtAccessPassword.Enabled = false;
            this.txtAccessTableName.Enabled = false;
            this.txtExcelSheetname.Enabled = false;
        }
        protected void rbtnTAB_CheckedChanged(object sender, EventArgs e)
        {
            //this.pnlCSV.Enabled = false;
            //this.pnlTAB.Enabled = true;
            //this.pnlExcel.Enabled = false;
            //this.pnlAccess.Enabled = false;
            this.txtAccessPassword.Enabled = false;
            this.txtAccessTableName.Enabled = false;
            this.txtExcelSheetname.Enabled = false;
        }

        protected void rbtnExcel_CheckedChanged(object sender, EventArgs e)
        {
            //this.pnlCSV.Enabled = false;
            //this.pnlTAB.Enabled = false;
            //this.pnlExcel.Enabled = true;
            //this.pnlAccess.Enabled = false;
            this.txtAccessPassword.Enabled = false;
            this.txtAccessTableName.Enabled = false;
            this.txtExcelSheetname.Enabled = true;
            this.txtExcelSheetname.Focus();
        }
        protected void rbtnAccess_CheckedChanged(object sender, EventArgs e)
        {
            //this.pnlCSV.Enabled = false;
            //this.pnlTAB.Enabled = false;
            //this.pnlExcel.Enabled = false;
            //this.pnlAccess.Enabled = true;
            this.txtAccessPassword.Enabled = true;
            this.txtAccessTableName.Enabled = true;
            this.txtExcelSheetname.Enabled = false;
            this.txtAccessTableName.Focus();
        }
        protected override void UpdateSessionNavigationHistory()
        {
            //Do nothing
        }
        // -----------------------------------------------------------------------------
        // <summary>
        // To validate supported file type for Import 
        // </summary>
        // <returns></returns>
        // <remarks>
        // </remarks>
        // <history>
        // 	[nparmar]	5/2008	Created
        // </history>
        // -----------------------------------------------------------------------------
        public bool ValidateFileTypeSupported(string FileName)
        {
            if (FileName == null) return false;

            string extension = BaseClasses.Utils.FileUtils.GetFileExtension(FileName).ToUpper();

            if ((extension == "MDB" || extension == "ACCDB") && (this.rbtnCSV.Checked || this.rbtnTAB.Checked || this.rbtnExcel.Checked))
                return false;

            if ((extension == "XLS" || extension == "XLSX") && (this.rbtnCSV.Checked || this.rbtnTAB.Checked || this.rbtnAccess.Checked))
                return false;

            if (this.rbtnCSV.Checked)
            {
                Session["FileType"] = "CSV";
                return true;
            }

            if (this.rbtnTAB.Checked)
            {
                Session["FileType"] = "TAB";
                return true;
            }

            if (this.rbtnExcel.Checked)
            {
                switch (extension)
                {
                    case "XLS":
                        Session["FileType"] = "XLS";
                        break;
                    case "XLSX":
                        Session["FileType"] = "XLSX";
                        break;
                }

                if (!string.IsNullOrEmpty(this.txtExcelSheetname.Text))
                {
                    Session["SheetName"] = this.txtExcelSheetname.Text;
                }
                else
                {
                    Session["SheetName"] = "Sheet1";
                }

                return true;
            }

            if (this.rbtnAccess.Checked)
            {
                switch (extension)
                {
                    case "MDB":
                        Session["FileType"] = "MDB";
                        break;
                    case "ACCDB":
                        Session["FileType"] = "ACCDB";
                        break;
                }

                if (!string.IsNullOrEmpty(this.txtAccessTableName.Text))
                {
                    Session["TableName"] = this.txtAccessTableName.Text;
                }
                else
                {
                    Session["TableName"] = "Table1";
                }

                if (!string.IsNullOrEmpty(this.txtAccessPassword.Text))
                {
                    Session["pwd"] = this.txtAccessPassword.Text;
                }
				return true;
            }

            Session["FileType"] = "";
            return false;
        }


            
#endregion

  
}
  
}
  