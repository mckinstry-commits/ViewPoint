// This file implements the code-behind class for ImportData.aspx.

#region "Using statements"    

using System;
using System.Data;
using System.Collections;
using System.ComponentModel;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using BaseClasses;
using BaseClasses.Utils;
using BaseClasses.Data;
using BaseClasses.Data.SqlProvider;
using BaseClasses.Web.UI.WebControls;
        
using VPLookup.Business;
using VPLookup.Data;
     
using System.Text;
using System.IO;
#endregion

  
namespace VPLookup.UI
{

public partial class ImportData
        : BaseApplicationPage
// Code-behind class for the ImportData page.
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
        /// ImportSelectColumns control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Literal ImportSelectColumns;
        /// <summary>
        /// ImportFirstRowCheckBox control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.CheckBox ImportFirstRowCheckBox;
        /// <summary>
        /// ImportResolveForeignKeys control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.CheckBox ImportResolveForeignKeys;
        /// <summary>
        /// DisplayTable control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.Table DisplayTable;
        /// <summary>
        /// PreviousButton control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::VPLookup.UI.ThemeButton PreviousButton;
        /// <summary>
        /// ImportButton control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::VPLookup.UI.ThemeButton ImportButton;
        /// <summary>
        /// ValidationSummary1 control.
        /// </summary>
        /// <remarks>
        /// Auto-generated field.
        /// To modify move field declaration from designer file to code-behind file.
        /// </remarks>
        protected global::System.Web.UI.WebControls.ValidationSummary ValidationSummary1;


#region "Section 1: Place your customizations here."    

        private const int MAXIMUMCHAR = 100;
        private const int CHARLIMIT = 2000;
        private const int SKIPTHRESHOLD = 25;
        private const string ENDING = "...";
        private const string ASSEMBLY_NAME = "VPLookup.Business";
        public ImportData()
        {
            this.Initialize();
            this.Init += new EventHandler(MyInit);

            this.PreInit += new EventHandler(Page_PreInit);
        }
        

        public void Page_PreInit(object sender, System.EventArgs e)
        {
            //override call to PreInit_Base() here to change top level master page used by this page, for example uncomment
            //next line to use Microsoft SharePoint default master page
            //if(this.Master != null) this.Master.MasterPageFile = Microsoft.SharePoint.SPContext.Current.Web.MasterUrl;
            //You may change here assignment of application theme
            this.PreInit_Base();
        }

        public void LoadData()
        {
            // LoadData reads database data and assigns it to UI controls.
            // Customize by adding code before or after the call to LoadData_Base()
            // or replace the call to LoadData_Base().
            LoadData_Base();
            
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

#region "Properties"

        public string AppName
        {
            get
            {
             return BaseClasses.Configuration.ApplicationSettings.Current.GetAppSetting(BaseClasses.Configuration.ApplicationSettings.ConfigurationKey.ApplicationName);
            }
         }   
        public string TableName
        {
            get
            {
                return this.Decrypt(BaseClasses.Utils.NetUtils.GetUrlParam(this, "TableName", true));
            }
        }

        public string FilePath
        {
            get
            {
                return (string)Session["FilePath"];
            }
        }
#endregion 

    private void MyInit(object sender, System.EventArgs e)
    {
       
        if (!(Session["FilePath"] == null))
        {
            // Retrieve information from session.
            string updatedRecordID = (string)Session["FilePath"];

            ParseCSVFile();
        }
        this.Page.Title = this.GetResourceValue("Import:Step2", this.AppName);
        this.ImportFirstRowCheckBox.Checked = true;
        this.ImportResolveForeignKeys.Checked = true;
    }  
  
    

   
    public void PreviousButton_Click(object sender, EventArgs args)
    {

        // Click handler for PreviousButton.
        // Customize by adding code before the call or replace the call to the Base function with your own code.
        //PreviousButton_Click_Base(sender, args);
        if (File.Exists(this.FilePath))
        {
            File.Delete(this.FilePath);
        }
        this.Page.Response.Redirect("SelectFileToImport.aspx?TableName=" + this.Encrypt(this.TableName)); // pass the table name as it is, without decryption.
        // NOTE: If the Base function redirects to another page, any code here will not be executed.
    }

     //This is the Import button click
    public void ImportButton_Click(object sender, EventArgs args)
    {
        // Click handler for ImportButton.
        // Customize by adding code before the call or replace the call to the Base function with your own code.
        //ImportButton_Click_Base(sender, args);
        ImportButton_Click_Base(sender, args);
    }
    
    
public BaseClasses.Data.BaseTable GetTable()
    {
        try
        {
            return DatabaseObjects.GetTableObject(this.TableName);
        }
        catch (System.Exception )
        {
             return DatabaseObjects.GetTableObject(this.TableName);
        }
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
        
              this.ImportButton.Button.Click += new EventHandler(ImportButton_Click);
              this.PreviousButton.Button.Click += new EventHandler(PreviousButton_Click);
        }


        public void PreInit_Base()
        {
            //If it is SharePoint application this function performs dynamic Master Page assignment.
            //If application uses multi-color theme this function performs dynamic theme assignment.
            //This is multi-color theme, so assign proper theme.
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
             
                // Show message on Click
                //this.NextButton.Button.Attributes.Add("onClick", "javascript:window.status=\"Import is the last step of Import Wizard.\";");

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
        this.ImportFirstRowCheckBox.Text = GetResourceValue("Import:FirstRowText", this.AppName);
        this.ImportResolveForeignKeys.Text = GetResourceValue("Import:ResolveForeignKeys", this.AppName);
        this.DataBind();
    }
        

        // Write out event methods for the page events
        
        // event handler for Button with Layout
    public void ImportButton_Click_Base(object sender, EventArgs args)
    {

        BaseTable bt = this.GetTable();
        BaseClasses.Utils.ImportedResults recordsImported = null;
   

        try
        {
            // Get the column names list and importChkBox list.
            Table disp = (Table)this.Page.FindControl("DisplayTable");
            int cellcount = disp.Rows[0].Cells.Count;
            ArrayList ddListSelected = new ArrayList();
            ArrayList chkBoxList = new ArrayList();
            for (int rc = 0; rc < cellcount - 1; rc++)
            {
                DropDownList dd = (DropDownList)(disp.FindControl("dropDownList" + rc));
                if (ddListSelected.Contains(dd.SelectedValue) && dd.SelectedValue != "") //&& this.ColumnsList.SelectedValue != DDLIST_TEXT)
                {
                    MiscUtils.RegisterJScriptAlert(this, "Duplicate Column", this.GetResourceValue("Import:DuplicateColumn", this.AppName).Replace("{ColumnName}", dd.SelectedValue));
                    return;
                }

                ddListSelected.Add(dd.SelectedValue);
                CheckBox chkBox = (CheckBox)(disp.FindControl("importChkBox" + rc));
                chkBoxList.Add(chkBox);
            }

            // Validate selected columns.
            if (!validateColumns(ddListSelected, chkBoxList, bt))
            {
                return;
            }
            ImportDataItems imp = new ImportDataItems(this.FilePath, GetFileType(), bt, ddListSelected, chkBoxList);
            recordsImported = imp.ImportRecords(this.ImportFirstRowCheckBox.Checked, this.ImportResolveForeignKeys.Checked);
            
        }
        catch (Exception e)
        {

            AjaxControlToolkit.ToolkitScriptManager.RegisterStartupScript(this.Page, Page.GetType(), "ErrorMsg", "alert(" + BaseClasses.Web.AspxTextWriter.CreateJScriptStringLiteral(e.Message) + ");", true); 
        }
        if (recordsImported == null) recordsImported = new BaseClasses.Utils.ImportedResults();

        string script = this.ConstructScriptForSkippedRecords(recordsImported);
        if (script.Contains("<script>"))
            ClientScript.RegisterStartupScript(Page.GetType(), "CloseWindow", script);
        else
            WriteTextFileForSkippedRecords(script);
    }

    private string ConstructScriptForSkippedRecords(BaseClasses.Utils.ImportedResults recordsImported)
    {
        string msg = this.GetResourceValue("Import:Success", this.AppName).Replace("{Records}", recordsImported.NumberOfImported.ToString());
        string msg2 = this.GetResourceValue("Import:Skipped", this.AppName).Replace("{Records}", recordsImported.NumberOfSkipped.ToString());
        string script = "";
        int symbolsCount = 0;
        script += "<script>";
        if (recordsImported.NumberOfSkipped > 0)
        {
            script += "CloseWindow('" + msg + "','" + msg2;
            string msg3 = this.GetResourceValue("Import:FirstSkippedRecords", this.AppName);
            symbolsCount += msg.Length + msg2.Length + msg3.Length;
            string linesMsg = "";
            int index = 0;
            foreach (BaseClasses.Utils.SkippedLine rec in recordsImported.ListOfSkipped)
            {
                string newLineEntry = "";
                if (recordsImported.NumberOfSkipped > SKIPTHRESHOLD || (recordsImported.NumberOfSkipped > 0 && recordsImported.NumberOfImported > 0))
                    newLineEntry = this.ConstructLineEntryForTextFile(rec, MAXIMUMCHAR);
                else
                    newLineEntry = this.ConstructLineEntry(rec, MAXIMUMCHAR);
                if (newLineEntry.Length + symbolsCount < CHARLIMIT)
                {
                    linesMsg += newLineEntry;
                    symbolsCount += newLineEntry.Length;
                    index += 1;
                }
                else
                {
                    break; 
                }
            }
            if (index < recordsImported.ListOfSkipped.Count)
            {
                msg3 = this.GetResourceValue("Import:FirstSkippedRecords", this.AppName).Replace("{Number}", index.ToString());
            }
            else
            {
                msg3 = this.GetResourceValue("Import:SkippedRecords", this.AppName);
            }
            if (recordsImported.NumberOfSkipped > SKIPTHRESHOLD || (recordsImported.NumberOfSkipped > 0 && recordsImported.NumberOfImported > 0))
            {
                script = "";
                if (recordsImported.NumberOfImported > 0) {
                    script += msg + "\r\n";
                }
                script += msg3 + "\r\n";
                script += linesMsg;
                return script;
            }
            else
            {
            script += "\\n" + "\\n" + msg3;
            script += linesMsg;
            script += "');";
            }
        }
        else
        {
            script += "CloseWindow('" + msg + "','" + msg2 + "');";
        }
        script += "</" + "script>";
        return script;
    }

    private string ConstructLineEntry(BaseClasses.Utils.SkippedLine skippedLine, int maximumChar)
    {
        string result = "";
        try
        {
            result += "\\n\\n" + this.GetResourceValue("Import:LineNumber", this.AppName).Replace("{Number}", skippedLine.LineNumber.ToString());
            string truncatedContent = skippedLine.LineContent.Replace("'", "\\'");
            if (truncatedContent.Length > maximumChar)
            {
                truncatedContent = truncatedContent.Substring(0, maximumChar - 3) + ENDING;
            }
            result += " " + truncatedContent;
            if (!string.IsNullOrEmpty(skippedLine.ErrorMessage.Trim()))
            {
                result += "\\n" + this.GetResourceValue("Import:ErrorMessage", this.AppName) + " " + skippedLine.ErrorMessage;
            }
        }
        catch
        {
            return "";
        }

        return result;
    }
       
    private string ConstructLineEntryForTextFile(BaseClasses.Utils.SkippedLine skippedLine, int maximumChar)
    {
        string result = "";
        try
        {
            result += this.GetResourceValue("Import:LineNumber", this.AppName).Replace("{Number}", skippedLine.LineNumber.ToString());
            string truncatedContent = skippedLine.LineContent.Replace("'", "\\'");
            if (truncatedContent.Length > maximumChar)
            {
                truncatedContent = truncatedContent.Substring(0, maximumChar - 3) + ENDING;
            }
            result += " " + truncatedContent + "\r\n";
            if (!string.IsNullOrEmpty(skippedLine.ErrorMessage.Trim()))
            {
                result += "     " + this.GetResourceValue("Import:ErrorMessage", this.AppName) + " " + skippedLine.ErrorMessage + "\r\n";
            }
        }
        catch
        {
            return "";
        }

        return result;
    }

    public void WriteTextFileForSkippedRecords(string script)
    {
        string name = this.GetResourceValue("Import:SkippedRecords", this.AppName);
        if (name.Contains(":"))
        {
            name.Replace(":", "");
            name.Trim();
        }
        string fileName = name + ".txt";
        SetupResponse(Response, fileName);
        Response.ContentType = "text/plain";
        StreamWriter Writer = new StreamWriter(Response.OutputStream, System.Text.Encoding.UTF8);
        Writer.Write(script);
        Writer.Flush();
        Response.End();
    }

    public void SetupResponse(System.Web.HttpResponse response, string fileName)
    {
        response.ClearHeaders();
        response.Clear();
        response.Cache.SetCacheability(System.Web.HttpCacheability.Private);
        response.Cache.SetMaxAge(new TimeSpan(0));
        response.Cache.SetExpires(new DateTime(0));
        response.Cache.SetNoServerCaching();
        response.AppendHeader("Content-Disposition", ("attachment; filename=\"" + (fileName + "\"")));
    }
        // event handler for Button with Layout
        public void PreviousButton_Click_Base(object sender, EventArgs args)
        {
              
            try {
                
            } catch (Exception ex) {
                this.ErrorOnPage = true;
    
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", ex.Message);
            } finally {
    
            }
    
        }
        /// <summary>
        /// Parses CSV file and retrieves five rows and populates ASP DataTable.
        /// </summary>
        public void ParseCSVFile()
        {

            if (File.Exists(this.FilePath))
            {
                BaseTable bt = this.GetTable();
                TableDefinition td = null;
                if (bt != null)
                {
                    td = bt.TableDefinition;
                }
                try
                {
                    Parser parser = Parser.GetParser(this.FilePath , GetFileType());//new CsvParser(path);

                    string checkboxChecked = (string)Session["checked"];

                    TableRow columnListAspTableRow = new TableRow();
                    TableRow columnAspTableRow = new TableRow();
                    TableRow importAspTableRow = new TableRow();

                    // Add first row with header label
                    TableCell columnHeaderTableCell = new TableCell();
                    TableCell importHeaderTableCell = new TableCell();
                    TableCell columnListHeaderTableCell = new TableCell();
                    Label columnHeaderLabel = new Label();
                    columnHeaderLabel.ID = "columnLabelHeader";
                    columnHeaderLabel.Text = GetResourceValue("Import:Column", this.AppName); //Column
                    Label importLabel = new Label();
                    importLabel.ID = "importLabelHeader";
                    importLabel.Text = GetResourceValue("Import:Import", this.AppName); //Import
                    Label columnListLabel = new Label();
                    columnListLabel.ID = "columnListLabelHeader";
                    columnListLabel.Text = GetResourceValue("Import:ColumnNames", this.AppName); //"Column names list";

                    columnHeaderTableCell.Controls.Add(columnHeaderLabel);
                    columnAspTableRow.Cells.Add(columnHeaderTableCell);
                    importHeaderTableCell.Controls.Add(importLabel);
                    importAspTableRow.Cells.Add(importHeaderTableCell);
                    columnListHeaderTableCell.Controls.Add(columnListLabel);
                    columnListHeaderTableCell.Wrap = false;
                    columnListAspTableRow.Cells.Add(columnListHeaderTableCell);

                    DisplayTable.Rows.Add(columnAspTableRow);
                    DisplayTable.Rows.Add(importAspTableRow);
                    DisplayTable.Rows.Add(columnListAspTableRow);

                    int rowIndex = 0;
                    int i = 0;
                    // Read 5 rows from csv file and display them in a Data Table.
                    while (rowIndex < 5)
                    {
                        string[] collValues = parser.GetNextRow();
                        if (collValues == null)
                        {
                            parser.Close();
                            return;
                        }
                        if (collValues[0] == null)
                            continue;
                        //Create column names dropdownList, import checkbox and Columns header
                        if (rowIndex == 0)
                        {

                            foreach (string value in collValues)
                            {
                                TableCell aspTableCell = new TableCell();
                                DropDownList x = new DropDownList();
                                x.ID = "dropDownList" + i;
                                x.CssClass = "fili";
                                x.Items.Add("");

                                //this.ColumnsList.Items.Add(DDLIST_TEXT);

                                //Adding column names to drop down list which are retrieved from database
                                foreach (BaseColumn column in td.Columns)
                                {
                                    ListItem item = new ListItem();
                                    item.Text = column.Name;
                                    item.Value = column.InternalName;
                                    x.Items.Add(item);
                                }

                                aspTableCell.Controls.Add(x);
                                columnListAspTableRow.Cells.Add(aspTableCell);

                                TableCell columnTableCell = new TableCell();
                                TableCell importTableCell = new TableCell();
                                Label columnLabel = new Label();
                                columnLabel.ID = "columnLabel" + i;
                                columnLabel.Text = (i + 1).ToString();

                                CheckBox importChkBox = new CheckBox();
                                importChkBox.ID = "importChkBox" + i;

                                // center align the check boxes and column numbers
                                importTableCell.HorizontalAlign = System.Web.UI.WebControls.HorizontalAlign.Center;

                                columnTableCell.HorizontalAlign = System.Web.UI.WebControls.HorizontalAlign.Center;

                                columnTableCell.Controls.Add(columnLabel);
                                columnAspTableRow.Cells.Add(columnTableCell);
                                importTableCell.Controls.Add(importChkBox);
                                importAspTableRow.Cells.Add(importTableCell);

                                if (value != null && (x.Items.FindByText(value) != null))
                                {
                                    x.Items.FindByText(value).Selected = true;
                                    importChkBox.Checked = true;
                                }
                                i++;
                            }
                        }

                        // reads through temp table and creates table cell and rows out of it and adds it to Display table
                        TableRow aspTableRow = new TableRow();
                        TableCell firstTableCell = new TableCell(); // let the first cell contains row number.
                        firstTableCell.Text = (rowIndex + 1).ToString();
                        aspTableRow.Cells.Add(firstTableCell);
                        foreach (string value in collValues)
                        {
                            TableCell aspTableCell = new TableCell();
                            if (value.Length > 100)
                            {

                                aspTableCell.Text = HttpUtility.HtmlEncode(value.Substring(0, 100) + "...");
                            }
                            else
                            {
                                aspTableCell.Text = HttpUtility.HtmlEncode(value);
                            }
                            aspTableRow.Cells.Add(aspTableCell);

                        }
                        DisplayTable.Rows.Add(aspTableRow);
                        rowIndex++;
                    }
                    parser.Close();
                }
                catch (Exception ex)
                {
                    MiscUtils.RegisterJScriptAlert(this, "Import_Error_Message", ex.Message);
                    this.ImportButton.Button.Enabled = false;
                }

            }
            else
            {
                BaseClasses.Utils.MiscUtils.RegisterJScriptAlert(this, "BUTTON_CLICK_MESSAGE", "file not found");
            }
        }
        public Parser.FileTypes GetFileType()
        {
            string type = string.Empty;
            if (Session["FileType"] != null)
            {
                if (Session["FileType"].ToString() != "")
                {
                    type = Session["FileType"].ToString();
                    switch (type)
                    {
                        case "CSV":
                            return Parser.FileTypes.CSV;
                        case "TAB":
                            return Parser.FileTypes.TAB;
                        case "XLS":
                            return Parser.FileTypes.XLS;
                        case "XLSX":
                            return Parser.FileTypes.XLSX;
                        case "MDB":
                            this.ImportFirstRowCheckBox.Checked = false;
                            this.ImportFirstRowCheckBox.Enabled = false;
                            return Parser.FileTypes.MDB;
                        case "ACCDB":
                            this.ImportFirstRowCheckBox.Checked = false;
                            this.ImportFirstRowCheckBox.Enabled = false;
                            return Parser.FileTypes.ACCDB;
                    }
                }
             }   
             return Parser.FileTypes.CSV;
            
        }
        protected override void UpdateSessionNavigationHistory()
        {
            //Do nothing
        }
        /// <summary>
        /// Perform validation on selected columns
        /// </summary>
        /// <param name="ddListSelected"></param>
        /// <param name="chkBoxList"></param>
        /// <param name="bTable"></param>
        /// <returns></returns>
        public bool validateColumns(ArrayList ddListSelected, ArrayList chkBoxList, BaseTable bTable)
        {

            int j = 0;
            while (j < ddListSelected.Count)
            {

                if (ddListSelected[j].ToString() != "" && ((CheckBox)chkBoxList[j]).Checked)
                {
                    BaseColumn currentColumn = bTable.TableDefinition.ColumnList.GetByAnyName((string)ddListSelected[j]);
                    //ForeignKey fkColumn = bTable.TableDefinition.GetForeignKeyByColumnName(currentColumn.InternalName);

                    // Check if the foreign key has DFKA. If so, then check the value from csv file against the DFKA column in the parent/foreign key table.
                    // If a match is found retrieve its ID and set that as value to be inserted in the current table where you are adding records.
                    // if (fkColumn != null && fkColumn.IsCompositeKey)
                    // {
                    //     throw new Exception("Import wizard does not support importing for tables with composite foreign keys");
                    //     return false;
                    // }
                    //if (currentColumn.IsPrimaryKeyElement())
                    //{
                    //    MiscUtils.RegisterJScriptAlert(this, "Import_Error_Message", this.GetResourceValue("Import:CompositeColumn", this.AppName).Replace("{ColumnName}", currentColumn.Name));
                    //    return false;
                    //}
                    if (currentColumn.IsValuesComputed)
                    {
                        MiscUtils.RegisterJScriptAlert(this, "Import_Error_Message", this.GetResourceValue("Import:ReadOnly", this.AppName).Replace("{ColumnName}", currentColumn.Name));
                        return false;
                    }

                }
                j++;
            }
            return true;

        }


            
#endregion

  
}
  
}
  