using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;
using Outlook = Microsoft.Office.Interop.Outlook;
using System.Configuration;
using System.IO;
using System.Text;

namespace McK.ARStatement.Viewpoint
{
    /*****************************************************************************************************************
                                          McKinstry McK.AROpenItemStatements.Viewpoint                                                 
                                                                                                                   
                                              copyright McKinstry 2019                                             
                                                                                                                  
        This Microsoft Excel VSTO solution was developed by McKinstry in 2018 in order to send out SM quotes from Vista by Viewpoint.  
        This software is the property of McKinstry and  requires express written permission to be used by any Non-McKinstry employee or entity                    
                                                                                                                   
        Release               Date         Details                                              
        1.0.0.0 Initial     2.14.19     Developer:         Leo Gurdian                       
                                         Project Manager:   Jean Nichols      
                                      •	Made into 2 version of the VSTO; 1 for Prod and 1 for Test - 4457
                                        o	The “test version” lives in 1 central location (STAGING) and is shared amongst Dev, Staging, Project, and Upgrade
                                        o	Easily switch test environment quickly, eliminating the need to uninstall/reinstall 
                                        o	Only uninstall when switching between PROD and TEST environments
                                        o	Saves network disk space as it's no more redundant copies in four different places
                                        o	Easier to deploy and test
                                        o	More manageable and scalable
        1.0.0.18    small   4.4.18    up'd search timeout to 30 minutes 
        1.0.0.19    big                     AR Grouping rewritten by Jonathan Ziebell
        1.0.0.20    big                 •	AR Customer Grouping Logic by Jonathan Ziebell - UPDATED
                                        •   Single “unapplied” lines default to “X” AR Customer Grouping and delivered as Corp
                                        •	GL Dept. 999 Will Default to “S” AR Customer Grouping
                                        •	Invoice Amount When Retainage is Held Should be Total Minus Retainage Held
                                        •	Extra Spaces Removed between Bill To City, State & Zip
                                        •	Control Panel AR Grouping Selection to be B-Both, C-Corporate, S-Service, X-Exceptions
                                        •	Performance Improvements
       1.0.0.23  small  4.2.19      •	FIX BUG – When clicking in Email after Email has been created, boxes pop up and not allowed to open PDF
                                    •	Add Invoices Through on Page 1 AR Statement Template  
                                    •	Hide Columns from the Grid
                                        o	Combine Customer Numbers
                                        o	Bill To Name
                                        o	# of Invoices
                                    •  In Email, Update Thank you to read Thank You.   Ie.  Capitalize the Y in "You"
                                    •  Upon delivery, Update the Send/Preview Statement Y/N Column to “Sent”
      1.0.0.33  med   5.23.19     •	BaseStatementPg2 tab no longer visible when generating statements - 4385
                                    •	Removed ending period at the of billing@mckinstry.com that was causing delivery failure - 4417
                                    •	Statements w/ missing email addresses are now marked as "Sent" on Deliver - 4418
                                    •	Multiple detail Statements now generate an email on Deliver – 4422
                                    •	Multiple detail Statements now get marked as "Sent" on Deliver – 4418
                                    •	[Send / Preview Statement] defaults to N when [Do Not Print] = N else blank – 4446
                                    •	Apply conditional formatting to all ' Send/Preview’ column not just first of multiple detail rows 
                                    •	On preview, clear any previous generated statements - 4570
                                    •	All emails imported into AR Customers- 4557
                                        o	Email now supports up to 1024 characters. 
                                    •	Format detail rows when page 2 overflows – 4576
                                    •	When Email is the Delivery Method, Add Customer # in the Subject Line – 4581
                                    •	Make Statement Email Column pink if an Email Address is missing – 4578
      *** PROD RELEASE ** 
    1.0.0.34    small   5.30.19     •	removed blank pages on PDF output when more than 1 page
    1.0.0.35    small   5.31.19     *   fix TotalBalanceDue formula to include entire pg 2 
    ----------------------------------------------------------------------------------------------

    1.0.1.0     big     xxxxxxx     * n-page dynamic creation - 4580
    1.0.1.1     med              TFS 4683  - Statements after a row marked as Do Not Deliver not getting processed
                                            - On refresh grid, Preview button got enabled when no Send Ys existed
                                            - Lighter Gray highlighting row for better readability
                                            - Default Statement Month to the previous month
                                            - When dragging down values over hidden filtered rows, hidden rows are ignored.
                                    1. Customer with contradicting flags, meaning Y, N and/or Blanks specified for same Customer:
                                        a.	Send/Preview blanks are ignored
                                        b.	Send/Preview Y supersedes N and Blanks, Statement is generated
                                        c.  Preview checkbox supersedes Preview column
    1.0.1.3     small   xxxxxx      - Page 2 (using Page1 template) PDF print Totals don't balance and printing detail outside of page - fixed LG 6.14
                                    - BUG FiX: unable to deliver due to "Value does not fall within the expected range" - due to trying to export as PDF when tab is hidden
    1.0.1.5     big     06.26.19 TFS 4698 - Auto-Deliver Option to mass Email Statements with:
                                        a.) Statement Preview and Email preview.  User needs to hit "Send" on email pop-up.
                                        b.) No Statement or Email Preview - Statement is generated and sent. No user interaction needed.
                                        c.) A mix of a & b: with Statement/Email Preview and without 
                                    - Ability to send out 80+ emails (Ideally ALL)
                                    - Improve memory / system resources by deleting statements with no Preview
                       06.27.19  ** PROD RELEASE ** 
    ----------------------------------------------------------------------------------------------
    1.0.1.7     small   07.02.19    HOT-FIX TFS 4796 - Year, Month, and Day parameters popup error when opening VSTO
                                STG
    1.0.1.8     small   07.16.19    TFS 4825 - Add button on Control Panel to move the "N" Customers to a different worksheet
                                    TFS 4826 - Add in Control Panel How Many Statements Will be Delivered
                        07.30.19   ** PROD RELEASED **
    1.0.1.9     small   01.09.20    ** PROD RELEASED ** TFS 5852 Error: "Month Must Be Between One & Twelve"                           
    //*****************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        #region FIELDS & PROPERTIES

        internal static AppSettingsReader _config => new AppSettingsReader();

        internal string Environ { get; }

        internal Excel.Worksheet _wsStatements = null;

        internal string SheetName_StatementsGrid = "Statements";
        internal const string SheetName_Search = "Search";
        internal const string corpEmail = "AccountsReceivable@McKinstry.com";
        internal const string corpPhone = "206.832.8799";
        internal const string serviceEmail = "Billing@McKinstry.com";
        internal const string servicePhone = "206.832.8328";

        // processing flags
        internal bool _isBuildingTable = false;

        // SQL Tables converted to  List of ExpandoObjects as IDictionary<string, Object>; (Object is KeyValuePairs - see Data layer)
        internal List<dynamic> _lstSearchResults = null;
        internal List<dynamic> _lstCompanies; // fills _companyDict and also queried by SMInvoices.ToExcel() to get FedTaxId
        internal Dictionary<dynamic, dynamic> _dictCompany = new Dictionary<dynamic, dynamic>(); // combobox source
        internal IEnumerable<dynamic> _ienuSendNCustomers = null; // all customers with Send "N" or blank

        // query filters
        private byte? Company { get; set; }
        private dynamic Customer { get; set; }
        private dynamic StatementDate { get; set; }  // same as Invoice date
        private dynamic TransThroughDate { get; set; }

        #endregion

        public ActionPane1()
        {
            InitializeComponent();

            /* DEPLOY TO DEV ENVIRONMENTS */
            //cboTargetEnvironment.Items.Add("Dev");
            //cboTargetEnvironment.Items.Add("Staging");
            //cboTargetEnvironment.Items.Add("Project");
            //cboTargetEnvironment.Items.Add("Upgrade");

            /* DEPLOY TO PROD */
            cboTargetEnvironment.Items.Add("Prod");

            try
            {

                if (cboTargetEnvironment.Items.Count > 0) cboTargetEnvironment.SelectedIndex = 0; // RefreshTargetEnvironment() is called on change

                if ((string)cboTargetEnvironment.SelectedItem == "Prod") cboTargetEnvironment.Visible = false;

                lblVersion.Text = "v." + this.ProductVersion;
                btnGetStatement.BackColor = System.Drawing.Color.Honeydew;

                DateTime today = DateTime.Today; // DateTime.Parse("04/01/2019"); // test
                var mth = today.Month > 1 ? today.Month - 1: today.Month; // TFS 5852 Error: "Month Must Be Between One & Twelve"
                today = new DateTime(today.Year,
                                     mth,
                                     DateTime.DaysInMonth(today.Year,
                                                          mth));
           

                txtStatementDate.Text = String.Format("{0:MM/yy}", today);

                DateTime endOfMonth = new DateTime(today.Year,
                                       today.Month,
                                       DateTime.DaysInMonth(today.Year,
                                                            today.Month));

                txtTransThruDate.Text = String.Format("{0:MM/dd/yy}", endOfMonth);

                cboARGroups.SelectedIndex = 0;
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }

            //txtCustomerList.Text = "215905"; // 3 pg
            //txtCustomerList.Text = "218406"; // 3 pg + 
        }

        private void cboTargetEnvironment_SelectedIndexChanged(object sender, EventArgs e) => RefreshTargetEnvironment();

        private void RefreshTargetEnvironment()
        {
            string environ = (string)cboTargetEnvironment.SelectedItem;

            try
            {
                switch (environ)
                {
                    case "Dev":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionDev");
                        break;
                    case "Staging":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionStg");
                        break;
                    case "Project":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionProj");
                        break;
                    case "Upgrade":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionUpg");
                        break;
                    case "Prod":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionProd");
                        break;
                    default:
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionDev");
                        break;
                }

                _lstCompanies = Companies.GetCompanyList();
                _dictCompany = _lstCompanies.ToDictionary(n => n.HQCo, n => n.CompanyName);

                cboCompany.DataSource = _dictCompany.Select(kv => kv.Value).ToList();

                if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;

                if (Globals.ThisWorkbook != null) Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = environ;
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }

        }

        private void btnGetStatements_Click(object sender, EventArgs e)
        {
            DialogResult action;

            try
            {
                if (_wsStatements?.ListObjects.Count == 1 && _wsStatements.ListObjects[1].ListRows.Count > 0)
                {
                    // already ran
                        action = MessageBox.Show("Grid data will be cleared and refreshed.\n\nContinue?", "Refresh Grid", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                        if (action == DialogResult.Yes)
                        {
                            GetStatements();
                        }
                        else if (action == DialogResult.No)
                        {
                            return;
                        }
                }
                else
                {
                    GetStatements();
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
        }

        private void GetStatements()
        {
            Application.UseWaitCursor = true;
            Excel.ListObject xltable = null;
            btnGetStatement.Tag = btnGetStatement.Text;
            btnGetStatement.Text = "Processing...";
            btnGetStatement.Refresh();
            btnGetStatement.Enabled = false;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            
            try
            {
                if (!IsValidFields()) throw new Exception("invalid fields");

                var selectedCo = cboCompany.SelectedItem.ToString();
                var selectedCoKey = _dictCompany.FirstOrDefault(x => x.Value == selectedCo).Key;

                Company  = selectedCoKey == 0 ? (Byte?)null : selectedCoKey; // null = 'Any' company

                Customer = txtCustomerList.Text == "" ? null : txtCustomerList.Text; 

                var customerType = cboARGroups.SelectedItem.ToString()[0] == 'A' ? (char?)null : cboARGroups.SelectedItem.ToString()[0];

                _lstSearchResults = Search.GetStatements(Company, Customer, customerType, StatementDate, TransThroughDate);

                _wsStatements = HelperUI.GetSheet(SheetName_StatementsGrid, false);

                if (_lstSearchResults?.Count > 0)
                {
                    Globals.ThisWorkbook.SheetActivate -= Globals.ThisWorkbook.ThisWorkbook_SheetActivate;

                    // Get Statement Month to prefix new worksheet name
                    IDictionary<string, object> statement = (IDictionary<string, object>)(_lstSearchResults.FirstOrDefault());

                    string statementMth = ((KeyValuePair<string, object>)statement["Statement Month"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                          ((KeyValuePair<string, object>)statement["Statement Month"]).Value.ToString();
                    string sheetName = statementMth + " " + SheetName_StatementsGrid;
                    SheetName_StatementsGrid = sheetName;

                    if (_wsStatements == null)
                    {
                        // Create new sheet
                        Globals.BaseResults.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.BaseResults.Copy(after: Globals.BaseResults.InnerObject);
                        _wsStatements = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                        _wsStatements.Name = sheetName;

                        Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        Globals.BaseResults.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    }

                    if (_wsStatements != null)
                    {
                        _wsStatements.Activate();

                        if (_wsStatements.ListObjects.Count == 1)
                        {
                            // after already ran
                            Globals.BaseResults.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.BaseResults.Copy(after: Globals.BaseResults.InnerObject);
                            HelperUI.DeleteSheet(_wsStatements.Name);
                            _wsStatements = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                            _wsStatements.Name = sheetName;
                            Globals.BaseResults.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        }

                        CleanUpTabs();

                        string tableName = sheetName.Replace(" ", "_").Replace("-", "_");

                        _isBuildingTable = true;

                        Globals.ThisWorkbook.SheetChange -= Globals.ThisWorkbook.ThisWorkbook_SheetChange;

                        //xltable = HelperUI.CreateWorksheetFromList(_lstSearchResults, tableName, sheetName, "McK AR Open Item Statements", StatementsPreview_SheetName);
                        xltable = SheetBuilderDynamic.BuildTable(_wsStatements, _lstSearchResults, tableName, offsetFromLastUsedCell: 0, bandedRows: true);

                        //if (xltable.ListRows.Count > 1)
                        //{
                        //    xltable.Sort.SortFields.Add(xltable.ListColumns["Customer Delivery Method"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlDescending);
                        //    //xltable.Sort.SortFields.Add(xltable.ListColumns["Invoice Number"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                        //    xltable.Sort.Apply();
                        //}

                        HelperUI.Grid_ConditionalFormat(xltable);
                        xltable.DataBodyRange.Cells[1, 1].Activate();

                        HelperUI.Grid_ColumnFormat(xltable);

                        _isBuildingTable = false;
                    }

                    btnCopyOffline.Enabled = true;
                    btnCopyOffline.BackColor = System.Drawing.Color.Honeydew;
                    ckbPreview.Enabled = true;
                }
                else
                {
                    if (_wsStatements != null && _wsStatements.ListObjects.Count == 1)
                    {
                        _wsStatements.ListObjects[1].DataBodyRange.Clear();
                    }

                    btnGetStatement.BackColor = System.Drawing.Color.Honeydew;
                    btnCopyOffline.Enabled = false;
                    btnCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
                    ckbPreview.Enabled = false;

                    ShowErr(customErrMsg: "No records found!");
                }

                Globals.ThisWorkbook.ToggleDeliverBtnOnSendReady();
                Globals.ThisWorkbook.TogglePreviewBtnOnPreviewReady();
                Globals.ThisWorkbook.ToggleMoveNCustomersBtn();
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;
                btnGetStatement.Text = btnGetStatement.Tag.ToString();
                btnGetStatement.Enabled = true;
                btnGetStatement.Refresh();

                HelperUI.RenderON();
                HelperUI.AlertON();
                Globals.ThisWorkbook.SheetActivate += Globals.ThisWorkbook.ThisWorkbook_SheetActivate;
                Globals.ThisWorkbook.SheetChange += Globals.ThisWorkbook.ThisWorkbook_SheetChange;
                if (xltable != null) Marshal.ReleaseComObject(xltable);
            }
        }

        private void btnPreview_Click(object sender, EventArgs e)
        {
            try
            {
                CleanUpTabs();

                if (!StatementBuilder.ToExcel(_lstSearchResults, ckbPreview.Checked))
                {
                    if (((Button)sender).Name == "btnDeliver")
                    {
                        ShowInfo(msg: "Nothing to Deliver. Check Send YN flag.");
                    }
                    else
                    {
                        ShowInfo(msg: "Nothing to Preview. Check Preview YN flag.");

                    }
                    return;
                }

                btnDeliver.Enabled = true;
                btnDeliver.BackColor = System.Drawing.Color.Honeydew;
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
        }

        private void btnDeliver_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            btnPreview_Click(sender, e);

            btnDeliver.Tag = btnDeliver.Text;
            btnDeliver.Text = "Emailing...";
            btnDeliver.Refresh();
            btnDeliver.Enabled = false;

            // EMAIL
            Outlook.Application oApp = null;
            Outlook.MailItem mail = null;
            Excel.Worksheet wsStatement = null;
            Excel.Range rng = null;
            Excel.Range rngCust = null;
            Excel.ListObject tbl = null;

            string customerNum = "";

            string fromEmail = "";
            string toEmail = "";
            string emailSubject = "";
            string deliveryMethod = "";
            string statementMth = "";
            string customerName = "";
            string custType = "";
            bool delivered = false;

            int emailReadyCnt = 0;
            int emailSentCnt = 0;
            int printedCnt = 0;

            string tempPDF = "";
            string attachmentFileName = "";
            bool preview = false;

            try
            {
                oApp = new Outlook.Application();

                var uniqueCustomers = _lstSearchResults.Where(n => (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                            ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))
                                                         .OrderBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer Sort Name"]).Value)
                                                         .GroupBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value).Distinct();

                if (!uniqueCustomers.Any()) return; // ShowInfo(null, "Nothing to send!");

                foreach (var _statementDetail in uniqueCustomers)
                {
                    // make a Key-Value of the table to retrive columns with spaces in the name
                    IDictionary<string, object> statement = (IDictionary<string, object>)_statementDetail.FirstOrDefault();

                    customerNum = ((KeyValuePair<string, object>)statement["Customer No."]).Value.GetType() == typeof(DBNull) ? string.Empty :  ((KeyValuePair<string, object>)statement["Customer No."]).Value.ToString();

                    wsStatement = HelperUI.GetSheet(customerNum);

                    if (wsStatement != null)
                    {
                        deliveryMethod = ((KeyValuePair<string, object>)statement["Customer Delivery Method"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Customer Delivery Method"]).Value.ToString();
                        custType = ((KeyValuePair<string, object>)statement["AR Customer Group"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["AR Customer Group"]).Value.ToString();
                        toEmail = ((KeyValuePair<string, object>)statement["Statement Email"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Statement Email"]).Value.ToString();

                        preview = !(!ckbPreview.Checked // NO PREVIEW - GLOBAL
                                         ||
                                    _statementDetail.Any(n =>
                                                // OR NO PREVIEW 
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value)).Equals("N", StringComparison.OrdinalIgnoreCase))
                                                     &&
                                    // and there's no Ys
                                    _statementDetail.Any(b =>
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                !(((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))))
                                                ||
                                    _statementDetail.All(x =>
                                                // OR ALL BLANKS
                                                (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["Preview Statement Y/N"]).Value).GetType() == typeof(DBNull))
                                                ));

                        bool treatAsCorp = custType == "C" || custType == "B" || custType == "X";
                        delivered = false;
                        wsStatement.Visible = Excel.XlSheetVisibility.xlSheetVisible; // else errors out below

                        #region EMAIL

                        if (deliveryMethod == "Email" && toEmail != string.Empty)
                        {
                            statementMth = ((KeyValuePair<string, object>)statement["Statement Month"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Statement Month"]).Value.ToString();
                            customerName = ((KeyValuePair<string, object>)statement["Customer Name"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Customer Name"]).Value.ToString();
                            //contractDesc = ((KeyValuePair<string, object>)statement["Contract Description"]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Contract Description"]).Value.ToString();

                            emailSubject = "McKinstry " + statementMth + " Statement – " + customerName + " " + customerNum; // (!contractDesc.StartsWith("Chk:",StringComparison.OrdinalIgnoreCase) ? contractDesc : customerName); 
                            attachmentFileName = "McKinstry " + statementMth + " Statement – " + customerNum;

                            tempPDF = IOexcel.GetWorksheetAsPDF(wsStatement, attachmentFileName);

                            if (File.Exists(tempPDF))
                            {
                                fromEmail = treatAsCorp ? corpEmail : serviceEmail;
                                mail = oApp.CreateItem(Outlook.OlItemType.olMailItem) as Outlook.MailItem;
                                mail.PropertyAccessor.SetProperty("http://schemas.microsoft.com/mapi/proptag/0x0065001E", fromEmail);
                                mail.SentOnBehalfOfName = fromEmail;
                                mail.To = toEmail;
                                //mail.CC = ccEmails;
                                mail.Subject = emailSubject;
                                mail.Body = 
@"Hello,
Please see the attached " + statementMth + " statement. For any questions about your statement please email " + (treatAsCorp ? corpEmail : serviceEmail) +
@"

Thank You McKinstry
p " + (treatAsCorp ? corpPhone : servicePhone) + @"
Consulting | Construction | Energy | Facility Services";

                                //mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, Type.Missing, Type.Missing);
                                //mail.Send();  // business wants to be able to edit subject line / body
                                /* workaround where email doesn't render correctly on .Display() below
                                  https://social.msdn.microsoft.com/Forums/en-US/9466c4bd-b593-4a4b-ac80-a944437816a8/outlook-new-message-from-vba-display-glitch?forum=outlookdev
                                */
                                //mail.Save();    // WORK-AROUND #1

                                // TFS 4698 - AUTO deliver no preview. Y takes precedence over N
                                if (!preview)
                                {
                                    // don't display email, just send it
                                    try
                                    {
                                        mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, 1, attachmentFileName);
                                        mail.Send();
                                        delivered = true;
                                        emailSentCnt++;
                                    }
                                    catch (Exception)
                                    {
                                        continue; // Customer won't get success color; user can filter by color to see which failed/pass
                                    }
                                    finally
                                    {
                                        File.Delete(tempPDF);
                                    }
                                }
                                else
                                {
                                    try
                                    {
                                        mail.Display();
                                        // ** IMPORTANT: Attachments.Add needs to come after Display() else email renders bad
                                        mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, 1, attachmentFileName); // WORK-AROUND #2
                                        delivered = true;
                                        emailReadyCnt++;
                                    }
                                    catch (Exception)
                                    {
                                        continue; 
                                    }
                                    finally
                                    {
                                        File.Delete(tempPDF);
                                    }
                                }
                            }
                        }
                        #endregion

                        #region PRINT
                        else if (deliveryMethod == "Mail" || (deliveryMethod == "Email" && toEmail == string.Empty))
                        {
                            wsStatement.PrintOutEx(Preview: false);
                            delivered = true;
                            printedCnt++;
                        }
                        #endregion

                        // on success, mark records as "Sent"
                        if (delivered)
                        {
                            if (preview)
                            {
                                wsStatement.Tab.Color = System.Drawing.SystemColors.ControlLight;
                            }

                            tbl = _wsStatements.ListObjects[1];
                            string lastCol = HelperUI.GetColumnName(tbl.ListColumns.Count);
                            int sendYNcol = tbl.ListColumns["Send Statement Y/N"].Index;
                            int previewYNcol = tbl.ListColumns["Preview Statement Y/N"].Index;
                            int firstRowFound = 0;

                            rngCust = tbl.ListColumns["Customer No."].DataBodyRange;

                            rng = rngCust.Find(customerNum, Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                Excel.XlSearchOrder.xlByColumns, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);
                            if (rng != null)
                            {
                                firstRowFound = rng.Row;
                                _wsStatements.get_Range("A" + rng.Row + ":" + lastCol + rng.Row).Interior.Color = HelperUI.LighterGray;
                                _wsStatements.Cells[rng.Row, sendYNcol].Formula = "Sent";
                                _wsStatements.Cells[rng.Row, previewYNcol].Formula = "Sent";

                                do
                                {
                                    rng = rngCust.FindNext(rng);

                                    if (rng.Row == firstRowFound) break;
                                    _wsStatements.get_Range("A" + rng.Row + ":" + lastCol + rng.Row).Interior.Color = HelperUI.LighterGray;
                                    _wsStatements.Cells[rng.Row, sendYNcol].Formula = "Sent";
                                    _wsStatements.Cells[rng.Row, previewYNcol].Formula = "Sent";

                                } while (rng != null);
                            }
                            
                        }

                        // return sheet to whatever visible state it was or delete it if not previewed
                        if (!preview)
                        {
                            // freeup resources
                            HelperUI.AlertOff();
                                wsStatement.Delete();
                                Marshal.ReleaseComObject(wsStatement);
                            HelperUI.AlertON();
                        }
                    }
                    else
                    {
                        throw new Exception("Unable to find Statement " + customerNum + ".");
                    }
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;
                btnDeliver.Text = (string)btnDeliver.Tag;
                btnDeliver.Refresh();
                btnDeliver.Enabled = true;

                if (emailSentCnt > 0 || emailReadyCnt > 0 || printedCnt > 0)
                {
                    ShowInfo(msg: emailSentCnt + " Email" + (emailSentCnt == 1 ? " was" : "s were") + " sent!\n\n"
                                + emailReadyCnt + " Email" + (emailReadyCnt == 1 ? " was" : " were") + " prepared.\n\n"
                                + printedCnt + (printedCnt == 1 ? " was" : " were") + " printed.");
                }

                #region CLEAN UP
                if (oApp != null) Marshal.ReleaseComObject(oApp);
                if (mail != null) Marshal.ReleaseComObject(mail);
                if (wsStatement != null) Marshal.ReleaseComObject(wsStatement);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (rngCust != null) Marshal.ReleaseComObject(rngCust);
                if (tbl != null) Marshal.ReleaseComObject(tbl);
                if (File.Exists(tempPDF)) File.Delete(tempPDF);
                #endregion
            }
        }

        private void CleanUpTabs()
        {
            try
            {
                HelperUI.RenderOFF();
                HelperUI.AlertOff();

                // delete left-over tabs from last query
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws == Globals.BaseStatement.InnerObject ||
                        ws == Globals.BaseStatementPg2.InnerObject ||
                        ws == Globals.BaseResults.InnerObject ||
                        ws == Globals.Customers.InnerObject ||
                        ws == Globals.MCK.InnerObject ||
                        ws == Globals.ThisWorkbook.Sheets[SheetName_StatementsGrid]) continue;

                    ws.Delete();
                }
                btnDeliver.Enabled = false;
                btnDeliver.BackColor = System.Drawing.SystemColors.ControlLight;
            }
            catch (Exception) { throw; }
            finally
            {
                HelperUI.AlertON();
                HelperUI.RenderON();
            }
        }


        #region CONTROL PANEL

        // validates fields w/ alert
        private bool IsValidFields()
        {
            bool badField = false;
            DateTime dt;

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCompany, "Select a Company");
                badField = true;
            }
            else
            {
                errorProvider1.SetError(cboCompany, "");
            }

            // STATEMENT DATE 
            string _mth = txtStatementDate.Text.Replace("/", "");
            string mth = "";
            string yr = "";

            if (_mth.Length == 4)
            {
                mth = _mth.Substring(0, 2);
                yr = _mth.ToString().Substring(2, 2);
    
                if (!DateTime.TryParse(mth + "/01/" + yr, out dt))
                {
                    errorProvider1.SetIconAlignment(txtStatementDate, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtStatementDate, "Statement date must be in MM/YY format.");
                    badField = true;
                }
                else
                {
                    StatementDate = dt;
                    errorProvider1.SetError(txtStatementDate, "");
                }
            }

            if (txtTransThruDate.Text != "")
            {
                if (txtTransThruDate.Text.Length == 8)
                {
                    if (!DateTime.TryParse(txtTransThruDate.Text, out dt))
                    {
                        errorProvider1.SetIconAlignment(txtTransThruDate, ErrorIconAlignment.MiddleLeft);
                        errorProvider1.SetError(txtTransThruDate, "Transactions Through Date must be in MM/DD/YY format.");
                        badField = true;
                    }
                    else
                    {
                        TransThroughDate = dt;
                        errorProvider1.SetError(txtTransThruDate, "");
                    }
                }
            }

            if (txtCustomerList.Text != "" && !Int32.TryParse(txtCustomerList.Text, out int boom))
            {
                errorProvider1.SetIconAlignment(txtCustomerList, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(txtCustomerList, "Must be numeric");
                badField = true;
            }
            else
            {
                errorProvider1.SetError(txtCustomerList, "");
            }

            if (badField)
            {
                return false;
            }

            return true;
        }

        // update company
        private void cboCompany_Leave(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboCompany.SelectedIndex == -1) { errorProvider1.SetError(cboCompany, "Select a Company from the list"); return; }

            Company = _dictCompany.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }

        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                Company = 0;
                cboCompany.SelectedIndex = -1;
            }
        }

        #region ALLOW ENTER KEY INVOKE GET STATEMENT

        private delegate void dlgGetInvoices(KeyEventArgs e);

        private dlgGetInvoices _dlgInvokeGetQuotesHndlr = new dlgGetInvoices(InvokeGetInvoicesHndlr);

        // allow enter key invoke GetInvoices
        private void ctrl_KeyUp(object sender, KeyEventArgs e)          => _dlgInvokeGetQuotesHndlr(e);

        // handles _dlgInvokeGetQuotesHndlr
        private static void InvokeGetInvoicesHndlr(KeyEventArgs e) 
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.GetStatements();
        }

        #endregion

        // paint font on Dropdown menus
        private void cboBoxes_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        private void cboBoxes_DrawItem1(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        private void btnPreview_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.btnPreview_Click(sender, new EventArgs());
        }

        /// <summary>
        /// Default Thru Date to last day of the month of the given Statement Date
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void txtStatementDate_TextChanged(object sender, EventArgs e)
        {
            string _mth = txtStatementDate.Text.Replace("/", "");
            string mth = "";
            string yr = "";

            if (_mth.Length == 4)
            {
                mth = _mth.Substring(0, 2);
                yr = _mth.ToString().Substring(2, 2);

                if (DateTime.TryParse(mth + "/01/" + yr, out DateTime dt))
                {
                    DateTime endOfMonth = new DateTime(dt.Year,
                       dt.Month,
                       DateTime.DaysInMonth(dt.Year,
                                            dt.Month));
                    txtTransThruDate.Text = String.Format("{0:MM/dd/yy}", endOfMonth);
                }
            }
        }


        #region CUSTOMER F4 LOOKUP

        private void txtBillToCustomer_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F4)
            {
                ShowCustomersBySortName();
            }
        }

        private void ShowCustomersBySortName(char Status = 'A')
        {
            Excel.ListObject xlTable = null;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            List<dynamic> table = null;

            try
            {

                //if (cboCompany.SelectedIndex == -1)
                //{
                //    errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                //    errorProvider1.SetError(cboCompany, "Select a Company");
                //}

                //Company = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

                table = CustomersBySortName.GetCustomers(Status);

                if (table?.Count > 0)
                {
                    if (Globals.Customers.Visible != Excel.XlSheetVisibility.xlSheetVisible)
                    {
                        Globals.Customers.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        // Globals.Customers.Controls[Globals.Customers.Controls.IndexOf("optActiveCustomers")]
                    }

                    Globals.Customers.Activate();

                    // re-create table if present
                    if (Globals.Customers.ListObjects.Count == 1)
                    {
                        Globals.Customers.ListObjects[1].Delete();
                    }

                    xlTable = SheetBuilderDynamic.BuildTable(Globals.Customers.InnerObject, table, "tblCustomers_by_SortName", offsetFromLastUsedCell: 2, bandedRows: true, headerRow: 5);

                    xlTable.ListColumns["Customer"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xlTable.ListColumns["State"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xlTable.ListColumns["Zip"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xlTable.ListColumns["Country"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    Globals.Customers.get_Range("G:K").EntireColumn.AutoFit();
                    xlTable.ListColumns["DeliveryMethod"].DataBodyRange.EntireColumn.ColumnWidth = 7.5;

                    HelperUI.MergeLabel(Globals.Customers.InnerObject, xlTable.ListColumns[1].Name, xlTable.ListColumns[xlTable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);
                    Globals.Customers.Application.ActiveWindow.SplitRow = 5;
                    Globals.Customers.Application.ActiveWindow.FreezePanes = true;
                    Globals.Customers.get_Range("A2").Activate();

                }
                else
                {
                    if (Globals.Customers.ListObjects.Count == 1) Globals.Customers.ListObjects[1].DataBodyRange.Clear();
                    ShowInfo(msg: "No records found!");
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;
                HelperUI.AlertON();
                HelperUI.RenderON();
            }
        }

        internal void RdoBtnGetCustomers_CheckedChanged(object sender, EventArgs e)
        {
            RadioButton btn = (RadioButton)sender;

            if (btn.Name == "rdoActiveCustomers")
            {
                if (btn.Checked)
                {
                    ((RadioButton)Globals.Customers.Controls["rdoARCustomers"]).Checked = false;
                    ShowCustomersBySortName('A'); // active
                }

            }
            else
            {
                if (btn.Checked)
                {
                    ((RadioButton)Globals.Customers.Controls["rdoActiveCustomers"]).Checked = false;
                    ShowCustomersBySortName('x'); // get all
                }
            }
        }

        #endregion

        #endregion


        #region SHOW ERRORS

        internal void ShowErr(Exception ex = null, string customErrMsg = null, string title = "Oops!")
        {
            string err = customErrMsg ?? (ex?.Message != "" ? ex.Message : "Something went wrong");

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        internal void ShowInfo(Exception ex = null, string msg = null, string title = "AR Statement")
        {
            string err = msg ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        internal void errOut(Exception ex = null, string title = "Oops") => MessageBox.Show(null, ex?.Message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        #endregion

        private void btnCopyOffline_Click(object sender, EventArgs e)
        {
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            Excel.Workbook wkbFrom = Globals.ThisWorkbook.InnerObject;
            Excel.Workbook wkbTo = null;

            try
            {
                DialogResult action;

                saveFileDialog.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                saveFileDialog.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                saveFileDialog.RestoreDirectory = false;
                saveFileDialog.FileName = wkbFrom.Name + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today) + ".xlsx";

                action = saveFileDialog.ShowDialog();

                if (action == DialogResult.OK)
                {
                    HelperUI.RenderOFF();

                    // Clone workbook
                    wkbTo = wkbFrom.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                    wkbFrom.Application.DisplayAlerts = false;

                    _wsStatements.Copy(After: wkbTo.Sheets["Sheet1"]);

                    ((Excel.Worksheet)wkbTo.Sheets["Sheet1"]).Delete();

                    // Save workbook to user specified path
                    wkbTo.SaveAs(saveFileDialog.FileName);
                    wkbTo.Close();

                }
            }
            catch (Exception)
            {
                if (wkbTo != null) wkbTo.Close(false);
                throw;
            }
            finally
            {
                HelperUI.RenderON();
                wkbFrom.Application.DisplayAlerts = true;

                if (wkbTo != null) Marshal.ReleaseComObject(wkbTo);
            }
        }

        /// <summary>
        /// Toggle Preview Statement Y/N column visibility
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ckbPreview_CheckedChanged(object sender, EventArgs e)
        {
            int previewYNcol = 1;
            Excel.ListObject xltable = null;
            Excel.Range rng = null;

            try
            {
                if (_wsStatements != null && _wsStatements.ListObjects.Count ==1)
                {
                    xltable = _wsStatements.ListObjects[1];
                    previewYNcol = xltable.ListColumns["Preview Statement Y/N"].Index;
                    rng = _wsStatements.Cells[1, previewYNcol];
                    rng.EntireColumn.Hidden = !ckbPreview.Checked;
                    Globals.ThisWorkbook.TogglePreviewBtnOnPreviewReady();
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }

        private void btnMoveNCustomers_Click(object sender, EventArgs e)
        {
            Excel.ListObject xltable_noSend = null;
            Excel.Range rngEntireCustomerCol = null;
            Excel.Range rng = null;
            int firstRowFound = 0;
            List<int> lstRowsToDelete = new List<int>();

            try
            {
                if (_ienuSendNCustomers.Count() == 0) return;

                HelperUI.DeleteSheet("Don't Send");

                // convert structure to list
                List<dynamic> lstSendNo = _ienuSendNCustomers.Cast<dynamic>().ToList<dynamic>();

                HelperUI.RenderOFF();

                // create new worksheet from list
                xltable_noSend = HelperUI.CreateWorksheetFromList(lstSendNo, tableName: "tblSendNoCustomers", sheetName: "Don't Send", A1Title: "Don't Send Statements", placeAfterSheet: SheetName_StatementsGrid, offsetFromLastUsedCell: 2);

                // format worksheet
                HelperUI.Grid_ConditionalFormat(xltable_noSend);
                HelperUI.Grid_ColumnFormat(xltable_noSend);

                #region REMOVE "N" CUSTOMERS FROM EXCEL GRID

                // get excel main grid
                rngEntireCustomerCol = _wsStatements.ListObjects[1].ListColumns["Customer No."].DataBodyRange;

                // get unique customers 
                var uniqueCustomers = _ienuSendNCustomers.GroupBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value).Distinct();

                // delete each customer from the main statements grid
                foreach (var c in uniqueCustomers)
                {
                    var customer = c.FirstOrDefault();
                    var customerNum = ((KeyValuePair<string, object>)((IDictionary<string, object>)customer)["Customer No."]).Value;

                    rng = rngEntireCustomerCol.Find(customerNum, Type.Missing,
                                        Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByColumns, Excel.XlSearchDirection.xlNext, false,
                                        Type.Missing, Type.Missing);
                    if (rng != null)
                    {
                        firstRowFound = rng.Row;
                        // record excel row to delete after exiting loop
                        lstRowsToDelete.Add(rng.Row);
                        do
                        {
                            rng = rngEntireCustomerCol.FindNext(rng);
                            if (rng.Row == firstRowFound) break;

                            lstRowsToDelete.Add(rng.Row);

                        } while (rng != null);
                    }
                }

                // delete rows from main grid 
                _isBuildingTable = true;  // shuts off ThisWorkbook_SheetChange event handler

                for (int i = lstRowsToDelete.Count - 1; i >= 0; i--)
                {
                    _wsStatements.get_Range("A" + lstRowsToDelete[i]).EntireRow.Delete();
                }

                _isBuildingTable = false;
                #endregion


                // remove N Customers from main structure
                _lstSearchResults.RemoveAll(row =>
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                (((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value)).Equals("N", StringComparison.OrdinalIgnoreCase)))
                                                ||
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                !(((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase)))
                                                ||
                                                (((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() == typeof(DBNull));

                // update button
                Globals.ThisWorkbook.ToggleMoveNCustomersBtn();


            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                HelperUI.RenderON();
                if (xltable_noSend != null) Marshal.ReleaseComObject(xltable_noSend);
                if (rngEntireCustomerCol != null) Marshal.ReleaseComObject(rngEntireCustomerCol);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }
    }
}
