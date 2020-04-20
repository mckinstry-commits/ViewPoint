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

// Change SolutionID in  McK.SMQuotes.Viewpoint.csproj to specify environment

namespace McK.SMQuotes.Viewpoint
{
    /*****************************************************************************************************************
                                                                                                                 
                                             McKinstry McK.SMQuotes.Viewpoint                                                 
                                                                                                                   
                                              copyright McKinstry 2018                                             
                                                                                                                  
        This Microsoft Excel VSTO solution was developed by McKinstry in 2018 in order to send out SM quotes from Vista by Viewpoint.  
        This software is the property of McKinstry and  requires express written permission to be used by any Non-McKinstry employee or entity                    
                                                                                                                   
        Release                Date     Details  
        ========             ========   ========
        1.0.0.0 Initial     10.25.2018  Prototype Dev:      Leo Gurdian                       
                                        Project Manager:    Jean Nichols
                                        
        1.0.0.17  small     01.31.2019  FUNCTION:
                                          3815: replace ud table w/ Active Directory query to lookup aliases' full name, tel. #, email  
                                        TEMPLATE:
                                          3789: Remove Notes Detailed Quote Lines
                                          3790: Contact Email Not Wide Enough
                                          3791: Add 1 Row After Row 38
                                        CLEAN UP:
                                            make customer # not required for mckfnSMQuoteDetail
                                            remove 'Cross Ref: Quote Contacts' ud form
                                            remove mckfnMcKQuoteContacts
        1.0.0.18   small    05.XX.2019 TFS 4457 Converted solution to new 2 version design: – TFS 4457
                                        CONTROL PANEL:
                                            1.	Converted VSTO to NEW design:
                                                a.	"TEST" version has a dropdown menu to easily change environment to Dev, Staging, Project and Upgrade
                                                    i.	Deployed to 1 Shared
                                                        •LOCATION:  \\SESTGVIEWPOINT\Viewpoint Repository\Reports\Custom\TrustedAPP  
                                            b.	"PROD" version has NO dropdown menu to prevent user error
                                        •	Add CLOSE button to CUSTOMERS tab – TFS 4457
                                        •	Selecting any cell in a Customer row, fills the “SM Customer Name” on the Control Panel
                                        •	Selecting a customer in the Customer TAB, auto populates SM Customer in the Control Panel
                                        •   Get Quotes prompts alerts grid will be refresh and prompts user to continue
        1.0.1.1     small   05.xx.2019  •  Allows generating quotes missing Customer #
                                        •  Work Order Quote has autocomplete & trims extra spaces
                                        •  SM Customer Name trims extra spaces
        1.0.1.1    small    06.20.2019  1. Customer Contact Email Missing on Quote when more than one contact in SM Service Sites
                                        1a. Customer Contact Email was pulling default, fixed to use Customer Contact from Quote
                                 ** PROD RELEASE ***
        sql-only   HOTFIX   06.26.2019  TFS 4783 • Cannot view Detailed View: SQL: Removed contact name filter that is blocking data and moved it to left outer join; line #170-174; 
                            06.27.2019 ** PROD RELEASE **
       1.0.1.2    BUG       11.27.19 LG -Doubling the Quoted Price -- TFS 5806  removed SQL SUMs, VSTO total is now 'Derived Pricing Est'
                            12.12.19 LG + sql files
 //*****************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        #region FIELDS & PROPERTIES

        internal static AppSettingsReader _config => new AppSettingsReader();
        internal string Environ { get; }

        internal Dictionary<byte, string> _companyDict = new Dictionary<byte, string>();

        internal Excel.Worksheet _wsQuotes = null;

        internal const string SMQuotes_TabName = "SM Quotes";
        internal const string Search_TabName = "Search";
        internal const string Recipients_TabName = "Recipients";

        // query filters
        internal byte SMCo { get; set; }
        private char QuoteStatus { get; set; }
        internal string QuoteFormat { get; set; }
        internal int CustomerID { get; set; } 
        private string QuoteID { get; set; }

        internal bool _isBuildingTable = false;  // disallows multiple clicking overtaxing app
        internal bool MoreThanOneQuoteSelected => _quotesSelectedList?.Count > 1;

        private List<dynamic> _tblSearchResults = null;
        private List<dynamic> _quotesSelectedList = null;
        internal List<dynamic> _quotesInPreviewTbl = null;

        // remmeber the last checked checkbox to revert back after clearing quote id textbox
        private int _lastCheckedButton = 0;
        private bool _textLengthIsZero = true;

        private int blinkControlFocusCnt = 6;

        #endregion


        public ActionPane1()
        {
            InitializeComponent();

            //* DEPLOY TO DEV ENVIRONMENTS */
            //cboTargetEnvironment.Items.Add("Dev");
            //cboTargetEnvironment.Items.Add("Staging");
            //cboTargetEnvironment.Items.Add("Project");
            //cboTargetEnvironment.Items.Add("Upgrade");

            /* DEPLOY TO PROD */
            cboTargetEnvironment.Items.Add("Prod");


            try
            {
                if (cboTargetEnvironment.Items.Count > 0) cboTargetEnvironment.SelectedIndex = 0;  // RefreshTargetEnvironment() -> RefreshCompanies() & RefreshDivisons() are called on change

                if ((string)cboTargetEnvironment.SelectedItem == "Prod") cboTargetEnvironment.Visible = false;

                lblVersion.Text = "v." + this.ProductVersion;
                btnGetQuotes.BackColor = System.Drawing.Color.Honeydew;

                if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;

                rdoApproved.Checked = true;
                rdoStandard.Checked = true;
                SetQuoteFormat();
                SetQuoteStatus();

                // setup autocomplete
                txtQuoteID.AutoCompleteSource = AutoCompleteSource.CustomSource;
                txtQuoteID.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                AutoCompleteStringCollection collection = new AutoCompleteStringCollection();

                string[] list = Quotes.GetQuoteList()?.Select(n => n.WorkOrderQuote.Value).Cast<string>().ToArray();
                collection.AddRange(list);

                txtQuoteID.AutoCompleteCustomSource = collection;
                txtQuoteID.Enabled = true;
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
        }

        private void btnGetQuotes_Click(object sender, EventArgs e)
        {
            DialogResult action;

            try
            {
                if (_wsQuotes?.ListObjects.Count == 1 && _wsQuotes.ListObjects[1].ListRows.Count > 0)
                {
                    // already ran
                    action = MessageBox.Show("Grid data will be cleared and refreshed.\n\nContinue?", "Refresh Grid", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                    if (action == DialogResult.Yes)
                    {
                        GetQuotes();
                    }
                    else if (action == DialogResult.No)
                    {
                        return;
                    }
                }
                else
                {
                    GetQuotes();
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
        }

        //TODO: limit data pull to 1 year (Add year dropdown)
        private void GetQuotes()
        {
            Application.UseWaitCursor = true;
            Excel.ListObject xlTable = null;

            btnGetQuotes.Tag = btnGetQuotes.Text;
            btnGetQuotes.Text = "Processing...";
            btnGetQuotes.Refresh();
            btnGetQuotes.Enabled = false;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            
            try
            {
                if (!IsValidFields()) throw new Exception("invalid fields");

                SMCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

                QuoteID = txtQuoteID.Text == "" ? null : txtQuoteID.Text.Trim();

                switch (QuoteFormat)
                {
                    case "Standard":
                        _tblSearchResults = QuotesSearch.GetQuotesSumView(SMCo, CustomerID, QuoteID, QuoteStatus);
                        break;
                    case "Detailed":
                        _tblSearchResults = QuotesSearch.GetQuotesDetailView(SMCo, CustomerID, QuoteID, QuoteStatus);
                        break;
                    case "Detailed with Equip":
                        _tblSearchResults = QuotesSearch.GetQuotesDetailView(SMCo, CustomerID, QuoteID, QuoteStatus);
                        break;
                    default:
                        _tblSearchResults = QuotesSearch.GetQuotesSumView(SMCo, CustomerID, QuoteID, QuoteStatus);
                        break;
                }

                if (_tblSearchResults?.Count > 0)
                {
                    _wsQuotes = HelperUI.GetSheet(SMQuotes_TabName, false);

                    Globals.ThisWorkbook.SheetActivate -= Globals.ThisWorkbook.ThisWorkbook_SheetActivate;

                    if (_wsQuotes == null)
                    {
                        // Create new sheet
                        Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.BaseQuotes.Copy(after: Globals.ThisWorkbook.Sheets[Globals.BaseQuotes.Index]);
                        _wsQuotes = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                        _wsQuotes.Name = SMQuotes_TabName;

                        Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    }

                    if (_wsQuotes != null)
                    {
                        _wsQuotes.Activate();

                        string tableName = SMQuotes_TabName.Replace(" ", "_").Replace("-", "_");

                        if (_wsQuotes.ListObjects.Count == 1)
                        {
                            // after already ran
                            Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.BaseQuotes.Copy(after: Globals.ThisWorkbook.Sheets[Globals.BaseQuotes.Index]);
                            HelperUI.DeleteSheet(_wsQuotes.Name);
                            _wsQuotes = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                            _wsQuotes.Name = SMQuotes_TabName;
                            Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        }

                        CleanUpTabs();

                        _isBuildingTable = true;
                        xlTable = SheetBuilderDynamic.BuildTable(_wsQuotes, _tblSearchResults, tableName, offsetFromLastUsedCell: 0, bandedRows: true);
                        _isBuildingTable = false;

                        _quotesSelectedList = null;
                        _quotesSelectedList = new List<dynamic>();

                        _wsQuotes.SelectionChange += Invoice_SelectionChange;
                        xlTable.DataBodyRange.Cells[1, 1].Activate();

                        #region FORMAT TABLE
                            xlTable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                            xlTable.ListColumns["SMCo"].DataBodyRange.EntireColumn.ColumnWidth = 6.25;
                            xlTable.ListColumns["Customer"].DataBodyRange.EntireColumn.ColumnWidth = 9.25;
                            xlTable.ListColumns["Entered Date"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                            xlTable.ListColumns["Derived Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Material Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Labor Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Equipment Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Subcontract Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Other Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            xlTable.ListColumns["Expiration Date"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                            xlTable.ListColumns["Customer Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Customer Name"].DataBodyRange.EntireColumn.ColumnWidth = 21.25;
                            xlTable.ListColumns["Customer Contact Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Customer Contact Phone"].DataBodyRange.NumberFormat = HelperUI.PhoneNumber;
                            xlTable.ListColumns["Service Site Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Service Site Description"].DataBodyRange.EntireColumn.ColumnWidth = 20.25;
                            xlTable.ListColumns["Service Site Address1"].DataBodyRange.EntireColumn.ColumnWidth = 18.25;
                            xlTable.ListColumns["Service Site Address1"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Service Site Address2"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Service Site City"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Scope Of Work"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            xlTable.ListColumns["Scope Of Work"].DataBodyRange.EntireColumn.ColumnWidth = 30;
                            xlTable.Range.EntireRow.AutoFit();

                            if (QuoteFormat.ContainsIgnoreCase("Detailed", StringComparison.OrdinalIgnoreCase))
                            {
                                xlTable.ListColumns["Work Scope Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                            }

                            if (QuoteFormat.ContainsIgnoreCase("Standard", StringComparison.OrdinalIgnoreCase))
                            {
                                xlTable.ListColumns["Derived Pricing Est"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                            }

                            HelperUI.MergeLabel(_wsQuotes, xlTable.ListColumns[1].Name, xlTable.ListColumns[xlTable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                            _wsQuotes.Application.ActiveWindow.SplitRow = 4;
                            _wsQuotes.Application.ActiveWindow.FreezePanes = true;
                            _wsQuotes.Application.ErrorCheckingOptions.NumberAsText = false;

                        #endregion
                    }
                }
                else
                {
                    _wsQuotes = HelperUI.GetSheet(SMQuotes_TabName, false);

                    if (_wsQuotes?.ListObjects.Count == 1)
                    {
                        xlTable = _wsQuotes.ListObjects[1];

                        if (xlTable.ListRows.Count > 0)
                        {
                            xlTable.DataBodyRange.Delete();
                        }
                    }

                    _quotesSelectedList = null;

                    btnGetQuotes.BackColor = System.Drawing.Color.Honeydew;

                    HelperUI.ShowErr(text: "No records found!");
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;
                btnGetQuotes.Text = btnGetQuotes.Tag.ToString();
                btnGetQuotes.Enabled = true;
                btnGetQuotes.Refresh();

                if (xlTable?.ListRows.Count > 0)
                {
                    btnPreview.Enabled = true;
                    btnPreview.BackColor = System.Drawing.Color.Honeydew;
                    btnGetQuotes.BackColor = System.Drawing.SystemColors.ControlLight;
                    tmrBlinkControl.Enabled = true;
                }
                else
                {
                    btnPreview.Enabled = false;
                    //btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
                }

                HelperUI.RenderON();
                HelperUI.AlertON();
                Globals.ThisWorkbook.SheetActivate += Globals.ThisWorkbook.ThisWorkbook_SheetActivate;

                if (xlTable != null) Marshal.ReleaseComObject(xlTable);
            }
        }

        private void btnPreview_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            btnPreview.Tag = btnPreview.Text;
            btnPreview.Enabled = false;
            btnEmail.Enabled = false;
            btnPrint.Enabled = false;

            Excel.ListObject xltable = null;
            Excel.Range rng = null;
            bool quoteTabCreated = false;

            try
            {
                HelperUI.AlertOff();
                HelperUI.RenderOFF();

                if (btnPreview.Text.Contains("Preview"))
                {
                    btnPreview.Text = "Processing...";
                    btnPreview.Refresh();

                    if (_quotesSelectedList.Skip(0).Any())
                    {
                        CleanUpTabs();

                        _quotesInPreviewTbl = new List<dynamic>();

                        // collect quote data from memory
                        foreach (var q in _quotesSelectedList)
                        {
                            var quote = _tblSearchResults.Where(n => 
                                                        n.QuoteID.Value  == q.QuoteID
                                                    //&& n.Customer.Value.GetType() == typeof(DBNull)? null:  == q.Customer
                                                    //&& n.Customer.Value == q.Customer
                                                    && n.SMCo.Value     == q.SMCo
                                                    && ((string)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Price Method"]).Value) == q.PriceMethod
                                                    ).Cast<dynamic>().ToList();
                            if (quote != null)
                            {
                                _quotesInPreviewTbl.AddRange(quote);
                            }
                        }

                        if (!_quotesInPreviewTbl.Skip(0).Any()) throw new Exception("Oops..something went wrong on btnPreview");

                        quoteTabCreated = SMQuotes.ToExcel(_quotesInPreviewTbl);

                        if (quoteTabCreated)
                        {
                            btnEmail.Focus();
                            //SendKeys.Send("{TAB}"); //sets focus on btnDeliverInvoices
                            this.ScrollControlIntoView(btnEmail);
                        }
                        else
                        {
                            HelperUI.ShowInfo(null, "No Quote detail data found.");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                HelperUI.errOut(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;

                btnPreview.Text = (string)btnPreview.Tag;
                btnPreview.Refresh();
                btnPreview.Enabled = false;

                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.ThisWorkbook.InnerObject.SheetActivate += Globals.ThisWorkbook.ThisWorkbook_SheetActivate;
                Globals.ThisWorkbook.ThisWorkbook_SheetActivate(Globals.ThisWorkbook.ActiveSheet);
                HelperUI.AlertON();
                HelperUI.RenderON();

                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }

        private static Excel.ListObject CreateWorksheet(List<dynamic> tableList, string tableName, string tabName)
        {
            Excel.ListObject xltable = null;
            Excel.Worksheet ws = null;

            try
            {
                Globals.ThisWorkbook.Sheets.Add(After: Globals.ThisWorkbook.Sheets[SMQuotes_TabName]);
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                ws.Name = tabName;
                ws.Application.ActiveWindow.DisplayGridlines = false;
                xltable = SheetBuilderDynamic.BuildTable(ws, tableList, tableName, offsetFromLastUsedCell: 2, bandedRows: true);
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                Marshal.ReleaseComObject(ws);
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
            return xltable;
        }

        /// <summary>
        /// When user selects cells within table rows, save records to memory for potential query params search
        /// </summary>
        /// <param name="Target"></param>
        private void Invoice_SelectionChange(Excel.Range Target)
        {
            if (_wsQuotes == null || _isBuildingTable) return;

            Excel.ListObject xlTable = null;
            Excel.Range rng = null;
            bool disableBtnPreview = false;
            long coCol = 0;
            long custCol = 0;
            long quoteIDeCol = 0;
            long priceMethodCol = 0;

            try
            {
                if (_wsQuotes.ListObjects.Count > 0)
                {
                    xlTable = _wsQuotes.ListObjects[1];

                    if (xlTable.ListRows.Count == 0) return;

                    rng      = Target.Application.ActiveWindow.Selection;

                    if (Target.Application.Intersect(xlTable?.DataBodyRange, Target) != null)
                    {
                        if (rng.CountLarge > xlTable.DataBodyRange.CountLarge) return;

                        _quotesSelectedList?.Clear();

                        coCol   = xlTable.ListColumns["SMCo"].Index;
                        custCol   = xlTable.ListColumns["Customer"].Index;
                        quoteIDeCol   = xlTable.ListColumns["QuoteID"].Index;
                        priceMethodCol   = xlTable.ListColumns["Price Method"].Index;

                        foreach (Excel.Range c in rng)
                        {
                            if (c.Application.Intersect(xlTable.DataBodyRange, c) != null)
                            {
                                dynamic expado = new System.Dynamic.ExpandoObject();

                                expado.SMCo     = Convert.ToByte(_wsQuotes.Cells[c.Row, coCol].Value);
                                expado.QuoteID      = _wsQuotes.Cells[c.Row, quoteIDeCol].Formula.Trim();
                                expado.PriceMethod  = _wsQuotes.Cells[c.Row, priceMethodCol].Formula.Trim();

                                _quotesSelectedList.Add(expado);
                            }
                        }

                        if (_quotesSelectedList.Skip(0).Any())
                        {
                            btnPreview.Text = "Preview Quote" + (MoreThanOneQuoteSelected ? "s " : "");
                            btnPreview.Enabled = true;
                            btnPreview.BackColor = System.Drawing.Color.Honeydew;
                        }
                        else
                        {
                            disableBtnPreview = true;
                        }
                    }
                    else
                    {
                        //rngRow.Interior.Color = HelperUI.White;
                        disableBtnPreview = true;
                    }

                    if (disableBtnPreview)
                    {
                        btnPreview.Enabled = false;
                        btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
                    }
                }
            }
            catch (Exception ex)
            {
                HelperUI.errOut(ex);
            }
            finally
            {
                if (xlTable != null) Marshal.ReleaseComObject(xlTable);
            }
        }

        private void btnEmailQuotes_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            btnEmail.Tag = btnEmail.Text;
            btnEmail.Text = "Emailing...";
            btnEmail.Refresh();
            btnEmail.Enabled = false;

            // EMAIL
            Outlook.Application oApp = null;
            Outlook.MailItem mail = null;
            Excel.Worksheet wsQuote = null;

            byte smco;
            string workOrderQuote = "";
            string scopeDesc = "";
            string servicesite = "";
            string toEmail = "";
            string ccEmails = "";
            int quotesEmailedCnt = 0;
            string tempPDF = "";
            dynamic scopedesc = null;

            try
            {
                #region RETIRE
                //// Check whether there is an Outlook process running
                //if (System.Diagnostics.Process.GetProcessesByName("OUTLOOK").Count() > 0)
                //{
                //    oApp = Marshal.GetActiveObject("Outlook.Application") as Outlook.Application; // open instance
                //}
                //else 
                //{
                //    oApp = new Outlook.Application(); // launch it
                //}
                #endregion

                if (!_quotesSelectedList.Skip(0).Any())
                {
                    HelperUI.ShowInfo(null, "Nothing to show!");
                    return;
                }

                //if (MessageBox.Show(null, "For each Quote, you will see an email window to allow edits before sending.\n" +
                //     "\n\nWould like to proceed ?", "Quotes Delivery", MessageBoxButtons.YesNo) == DialogResult.No)
                //{
                //    return;
                //}

                oApp = new Outlook.Application();

                var uniqueQuotes = _quotesInPreviewTbl.GroupBy(r => r.QuoteID).Distinct();

                foreach (var _quote in uniqueQuotes)
                {
                    dynamic quoteDyn = _quote.First();

                    var q = (IDictionary<string, object>)quoteDyn;

                    var co = (KeyValuePair<string, object>)q["SMCo"];
                    var quote = (KeyValuePair<string, object>)q["QuoteID"];
                    var emailTO = (KeyValuePair<string, object>)q["Customer Contact Email"];

                    if (QuoteFormat != "Standard")
                    {
                        scopedesc = (KeyValuePair<string, object>)q["Work Scope Description"];
                        scopeDesc = scopedesc.Value.GetType() == typeof(DBNull) ? string.Empty : scopedesc.Value.ToString().Trim();
                    }

                    var site = (KeyValuePair<string, object>)q["Service Site"];

                    smco            = co.Value.GetType() == typeof(DBNull) ? byte.MinValue : Convert.ToByte(co.Value);
                    servicesite     = site.Value.GetType() == typeof(DBNull) ? string.Empty : site.Value.ToString().Trim();
                    workOrderQuote  = quote.Value.GetType() == typeof(DBNull) ? string.Empty : quote.Value.ToString().Trim();
                    toEmail = emailTO.Value.GetType() == typeof(DBNull) ? string.Empty : emailTO.Value.ToString().Trim();

                    wsQuote = HelperUI.GetSheet(workOrderQuote);

                    if (wsQuote != null)
                    {
                        tempPDF = IOexcel.GetWorksheetAsPDF(wsQuote);

                        if (File.Exists(tempPDF))
                        {
                            mail = oApp.CreateItem(Outlook.OlItemType.olMailItem) as Outlook.MailItem;
                            mail.To = toEmail;
                            mail.CC = ccEmails;

                            if (QuoteFormat == "Standard")
                            {
                                mail.Subject = "McKinstry Quote #" + workOrderQuote + ", " + servicesite;
                            }
                            else
                            {
                                mail.Subject = "McKinstry Quote #" + workOrderQuote + ", " + scopeDesc + " Services, " + servicesite;
                            }

                            mail.Body = "Please see attached quote.";
                            mail.Display();
                            mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, Type.Missing, Type.Missing);
                            //mail.Send();  // business wants to be able to edit subject line / body

                            Application.UseWaitCursor = false;
                            File.Delete(tempPDF);
                        }
                    }
                    else
                    {
                        throw new Exception("Unable to locate Work Order Quote: " + quote + ".\nTab probably got manually deleted.");
                    }
                }

                if(quotesEmailedCnt > 0)
                {
                    HelperUI.ShowInfo(msg: quotesEmailedCnt + " quote" + (quotesEmailedCnt > 1 ? "s " : "") + " are ready to be e-mailed.");
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
            finally
            {
                Application.UseWaitCursor = false;
                btnEmail.Text = (string)btnEmail.Tag;
                btnEmail.Refresh();
                btnEmail.Enabled = true;

                #region CLEAN UP
                if (oApp != null) Marshal.ReleaseComObject(oApp);
                if (mail != null) Marshal.ReleaseComObject(mail);
                if (File.Exists(tempPDF)) File.Delete(tempPDF);
                #endregion
            }
        }

        private void btnPrint_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            btnPrint.Tag = btnPrint.Text;
            btnPrint.Text = "Printing...";
            btnPrint.Refresh();
            btnPrint.Enabled = false;
            Excel.Worksheet ws = null;
            //Excel.PageSetup ps = null;
            int quotesPrintedCnt = 0;

            try
            {
                HelperUI.RenderOFF();

                var uniqueQuotes = _quotesInPreviewTbl.GroupBy(r => r.QuoteID).Distinct();

                foreach (var qt in uniqueQuotes)
                {
                    dynamic quoteDyn = qt.First();

                    var q = (IDictionary<string, object>)quoteDyn;
                    var quote = (KeyValuePair<string, object>)q["QuoteID"];
                    string workOrderQuote = quote.Value.GetType() == typeof(DBNull) ? string.Empty : quote.Value.ToString().Trim();

                    ws = HelperUI.GetSheet(workOrderQuote);

                    if (ws != null)
                    {
                        //HelperUI.PrintPage_Setup(ws);
                        ws.PrintOutEx(Preview: false);
                        quotesPrintedCnt++;
                    }
                }

                if (quotesPrintedCnt > 0)
                {
                    HelperUI.ShowInfo(msg: quotesPrintedCnt + " quote" + (quotesPrintedCnt > 1 ? "s" : "") + " have been sent to the printer.");
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
            finally
            {
                HelperUI.RenderON();
                Application.UseWaitCursor = false;

                btnPrint.Text = (string)btnPrint.Tag;
                btnPrint.Enabled = true;

                if (ws != null) Marshal.ReleaseComObject(ws);
            }
        }

        private void btnSaveQuotesOffline_Click(object sender, EventArgs e)
        {
            btnSave.Tag = btnSave.Text;
            btnSave.Text = "Saving...";
            btnSave.Refresh();
            btnSave.Enabled = false;
            Excel.Worksheet wsQuote = null;
            string tempPDF = "";
            string copyToPathFullFileName = "";
            Application.UseWaitCursor = true;
            int quotesSavedCnt = 0;
            HelperUI.RenderOFF();

            try
            {
                using (var d = new FolderBrowserDialog())
                {
                    d.Description = "Select folder to save your Invoices to:";
                    //diag.RootFolder = Environment.SpecialFolder.MyComputer;
                    //d.RootFolder = Environment.GetFolderPath(Environment.SpecialFolder.Personal);

                    DialogResult action = d.ShowDialog();

                    if (action == DialogResult.OK && !string.IsNullOrWhiteSpace(d.SelectedPath))
                    {
                        foreach (var q in _quotesInPreviewTbl)
                        {
                            wsQuote = HelperUI.GetSheet(q.QuoteID.Value);

                            if (wsQuote != null)
                            {
                                tempPDF = IOexcel.GetWorksheetAsPDF(wsQuote);

                                copyToPathFullFileName = Path.Combine(d.SelectedPath, "McK SM Quote " + wsQuote.Name.Trim() + ".pdf");

                                IOexcel.CopyPDFToFolder(tempPDF, copyToPathFullFileName);

                                if (File.Exists(tempPDF)) File.Delete(tempPDF);
                                quotesSavedCnt++;

                                #region SAVE AS EXCEL
                                //string wsSaveAsName = "McK SM Quote " + ws.Name.Trim();
                                //IOexcel.CopyOfflineAsExcel(ws, wsSaveAsName, copyEntireWorkbook: false);
                                #endregion
                            }
                        }

                        if (quotesSavedCnt > 0)
                        {
                            btnSave.Text = "Saved!";
                            btnSave.Refresh();

                            HelperUI.ShowInfo(msg: quotesSavedCnt + " quote" + (quotesSavedCnt > 1 ? "s" : "") + " saved!");
                        }
                    }
                    //else if (action == DialogResult.Cancel)
                    //{
                    //    btnSave.Text = (string)btnSave.Tag;
                    //    btnSave.Refresh();
                    //}
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex, title: "Failed Save Offline!");
            }
            finally
            {
                Application.UseWaitCursor = false;
                HelperUI.RenderON();
                btnSave.Text = (string)btnSave.Tag;
                btnSave.Refresh();
                btnSave.Enabled = true;
                if (wsQuote != null) Marshal.ReleaseComObject(wsQuote);
            }
        }

        private void btnReset_Click(object sender, EventArgs e)
        {
            try
            {
                HelperUI.RenderOFF();
                HelperUI.AlertOff();

                // delete left-over tabs from last query
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws == Globals.BaseQuotes.InnerObject ||
                        ws == Globals.QuoteStandard.InnerObject ||
                        ws == Globals.QuoteDetail.InnerObject ||
                        ws == Globals.Customers.InnerObject ||
                        ws == Globals.MCK.InnerObject ||
                        ws == Globals.ThisWorkbook.Sheets[SMQuotes_TabName]) continue;

                    ws.Delete();
                }
                HelperUI.AlertON();

                txtCustomer.Text = "";
                txtQuoteID.Text = "";
                rdoStandard.Checked = true;
                rdoApproved.Checked = true;
            }
            catch (Exception) { throw; }
            finally
            {
                HelperUI.RenderON();
            }
        }


        #region CONTROL PANEL

        // validates fields w/ alert
        private bool IsValidFields()
        {
            bool badField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(lblCompany, ErrorIconAlignment.MiddleRight);
                errorProvider1.SetError(lblCompany, "Select a Company");
                badField = true;
            }
            else
            {
                errorProvider1.SetError(cboCompany, "");
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

            SMCo = _companyDict.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }

        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                SMCo = 0;
                cboCompany.SelectedIndex = -1;
            }
        }

        #region ALLOW ENTER KEY INVOKE GET QUOTES

        private delegate void dlgGetInvoices(KeyEventArgs e);

        private dlgGetInvoices _dlgInvokeGetQuotesHndlr = new dlgGetInvoices(InvokeGetInvoicesHndlr);

        // allow enter key invoke GetInvoices
        private void ctrl_KeyUp(object sender, KeyEventArgs e)          => _dlgInvokeGetQuotesHndlr(e);

        // handles _dlgInvokeGetQuotesHndlr
        private static void InvokeGetInvoicesHndlr(KeyEventArgs e) 
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.GetQuotes();
        }

        #endregion

        // paint font on Dropdown menus
        private void cboCompany_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        private void cboTargetEnvironment_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow; // <--- difference here to contrast the font color
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        private void txtCustomer_TextChanged(object sender, EventArgs e)
        {
            int custId = 0;

            if (Int32.TryParse(txtCustomer.Text.Trim(), out custId))
            {
                CustomerID = custId;
            }
            else if (txtCustomer.Tag != null) // user selected from Customers tab
            {

                CustomerID = Convert.ToInt32(txtCustomer.Tag);

                txtCustomer.Tag = null;
                //Int32.TryParse((string)txtCustomer.Tag, out custId);
            }
            else
            {
                CustomerID = 0;
            }
        }

        // handles all Quote Status radio buttons
        private void radioButton_CheckedChanged(object sender, EventArgs e) =>  SetQuoteStatus();

        private void SetQuoteStatus()
        {
            foreach (RadioButton r in grpQuoteStatus.Controls)
            {
                if (r.Checked)
                {
                    if (r.Text == "All")
                    {
                        QuoteStatus = '\0';
                        return;
                    }
                    else
                    {
                        QuoteStatus = r.Text.ToArray()[0];
                        return;
                    }
                }
            }
        }

        private void rdoAll_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoAll.Checked) QuoteStatus = '\0';
        }

        private void rdoApproved_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoApproved.Checked) QuoteStatus = 'A';
        }

        private void rdoCancelled_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoCancelled.Checked) QuoteStatus = 'C';
        }

        private void rdoNew_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoNew.Checked) QuoteStatus = 'N';
        }


        private void rdoQuoteFormat_CheckedChanged(object sender, EventArgs e) => SetQuoteFormat();

        private void SetQuoteFormat()
        {
            foreach (RadioButton r in grpQuoteFormat.Controls)
            {
                if (r.Checked)
                {
                    if (r.Name == "rdoStandard")
                    {
                        rdoStandard_CheckedChanged(null, null);
                    }
                    else if (r.Name == "rdoDetailed")
                    {
                        rdoDetailed_CheckedChanged(null, null);
                    }
                    else if (r.Name == "rdoDetailedEquip")
                    {
                        rdoDetailedEquip_CheckedChanged(null, null);
                    }
                    break;
                }
            }
        }

        private void rdoStandard_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoStandard.Checked) QuoteFormat = rdoStandard.Text;
        }

        private void rdoDetailed_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoDetailed.Checked) QuoteFormat = rdoDetailed.Text;
        }

        private void rdoDetailedEquip_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoDetailedEquip.Checked) QuoteFormat = rdoDetailedEquip.Text;
        }

        /// <summary>
        /// Narrowing search to quote id, expands quote status to "ALL" but remembers which status was selected to put back when quote id textbox clears
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void txtQuoteID_TextChanged(object sender, EventArgs e)
        {
            if (txtQuoteID.Text.Length > 0)
            {
                if (_textLengthIsZero) // if user presses the backspace to clear chars off, maintain last remembered checked radio button
                {
                    _lastCheckedButton = grpQuoteStatus.Controls.IndexOf(grpQuoteStatus.Controls.OfType<RadioButton>().FirstOrDefault(r => r.Checked));
                    rdoAll.Checked = true;
                    _textLengthIsZero = false;
                }
            }
            else
            {
                //TextLenHasZerodOut = true;
                ((RadioButton)grpQuoteStatus.Controls[_lastCheckedButton]).Checked = _textLengthIsZero = true;
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

                if (cboCompany.SelectedIndex == -1)
                {
                    errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(cboCompany, "Select a Company");
                }

                SMCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

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
                    Globals.Customers.get_Range("G:H").EntireColumn.AutoFit();

                    HelperUI.MergeLabel(Globals.Customers.InnerObject, xlTable.ListColumns[1].Name, xlTable.ListColumns[xlTable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                    Globals.Customers.get_Range("A2").Activate();

                }
                else
                {
                    if (Globals.Customers.ListObjects.Count == 1) Globals.Customers.ListObjects[1].DataBodyRange.Clear();
                    HelperUI.ShowInfo(msg: "No records found!");
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
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


        private void tmrBlinkControl_Tick(object sender, EventArgs e)
        {
            if (blinkControlFocusCnt != 0)
            {
                if (blinkControlFocusCnt % 2 == 0)
                {
                    btnPreview.Focus();
                }
                else
                {
                    this.ActiveControl = label1;
                }
            }
            else
            {
                tmrBlinkControl.Enabled = false;
                btnPreview.Focus();
                blinkControlFocusCnt = 6;
            }

            blinkControlFocusCnt--;
        }

        private void btnPreview_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.btnPreview_Click(sender, new EventArgs());
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

                RefreshCompanies();

                if (Globals.ThisWorkbook != null) Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = environ;
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
        }

        private void RefreshCompanies()
        {
            _companyDict = Companies.GetCompanyList();

            cboCompany.DataSource = _companyDict.Select(kv => kv.Value).ToList();

            if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;

        }

        private void CleanUpTabs()
        {
            // put back values once done
            bool renderOFF = Globals.ThisWorkbook.Application.ScreenUpdating;
            bool alertOff = Globals.ThisWorkbook.Application.DisplayAlerts;

            try
            {
                HelperUI.RenderOFF();
                HelperUI.AlertOff();

                // delete left-over tabs from last query
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws == Globals.BaseQuotes.InnerObject ||
                        ws == Globals.QuoteStandard.InnerObject ||
                        ws == Globals.QuoteDetail.InnerObject ||
                        ws == Globals.Customers.InnerObject ||
                        ws == Globals.MCK.InnerObject ||
                        ws == Globals.ThisWorkbook.Sheets[SMQuotes_TabName]) continue;

                    ws.Delete();
                }
            }
            catch (Exception) { throw; }
            finally
            {
                Globals.ThisWorkbook.Application.ScreenUpdating = renderOFF;
                Globals.ThisWorkbook.Application.DisplayAlerts = alertOff;
            }
        }
    }
}
