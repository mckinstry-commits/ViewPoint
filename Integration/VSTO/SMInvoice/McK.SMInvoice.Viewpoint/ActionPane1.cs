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
using McK.Models.Viewpoint;
using System.IO;
using System.Text;
using MSForms = Microsoft.Vbe.Interop.Forms;

// Change SolutionID in  McK.SMInvoice.Viewpoint.csproj to specify environment

namespace McK.SMInvoice.Viewpoint
{
    /*****************************************************************************************************************                                                            
                                           McKinstry McK.SMInvoice.Viewpoint                                                 
                                                                                                                   
                                            copyright McKinstry 2017                                              
                                                                                                                  
        This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate closing         
        POs within Vista by Viewpoint.  This software is the property of McKinstry and                             
        requires express written permission to be used by any Non-McKinstry employee or entity                    
                                                                                                                  
        Release      Size           Date            Details                                              
        1.0.0.0   Init      04.2018         Prototype Dev:      Leo Gurdian                       
                                                    Project Manager:    Jean Nichols                            
                                                                                                                   
                  init      07.09.18    init prototype     
        1.0.0.35  small     11.20.18    	“Subquery returned more than 1 value” error when querying by Customer fixed
                                                  	Add “Close” button to Customers tab
                                                  	Update “Bill To Customer” textbox when selecting Customers
                                                  	Sort Customers by Ascending order
                                                  	Querying “All Pending” invoices taking over 1 min; now 4-5 seconds
                                                  	Querying “All Delivered” invoices hangs Excel; now ~12 secs. / 40+K records.
         
        1.0.0.39  small     01.24.19    SM Invoice Review form’s Delivery Tab not displaying Delivery info
                                                     Delivery will also update:
                                                        o SM Invoices tab:
                                                         Sent Date (w/ timestamp)
                                                         Sent By
                                                        o Recipients tab:
                                                         Sent Date
                                         When changing the Customer ID in SM WO, Name & Address Flows to VSTO but not Customer ID
                                         Expand Row Height between Labor and Other Items
       1.0.1.0  med         04.26.19   PROD: 1. Flat Price to include quote # when SM WO is derived from Quote - TFS 3937
                                            2. T&M detail:
                                                a. Consolidate T&M detail line. Description: "Labor & Materials"
                                                b. Consolidate T&M detail line.  When WO derived from Quote, description: "Labor and Materials Per Quote #_____"
                                            3. Audio Visual filter fixed
                                            4. default T&M to Summary
                                        STG:
      1.0.1.8   small       04.26.19     TFS 3937 - fixed Flat price now correctly reads "Labor and Materials Per Quote # _________"
      1.0.1.9   small       05.08.19     TFS 4003 - 4313 - agreement template update. Proj references updated  4.26.2019
      1.0.1.10  small       05.14.19     TFS 4501 - WO Flat Price - Quote Number is being cut off due to description length  
      1.0.1.11  small       06.03.19     TFS 4313 - Agreements: 
                                                    > Add Current Billing Amount to the Insert Box.  
                                                    > Ending Balance = Contract Value - Previously Billed - Current Billing Amount

                                                    -- FIRE ONLY -- "TEMPLATE"
      1.0.1.12  small       06.11.19     TFS 4172 - Get Work Performed description from the Scope Sequence
                                                  - Wrap detail line Description
                                                  - Standardize the Description to either Testing & Inspection or Repair Service
                                                  - Instead of "Ship To" verbiage, will say "Service Site"
                                                  - Add Site # next to the Service Site Address
                                                  - Add Fitter Notes in the Work Performed
                                                  - expand Work Performed for more room for notes
      1.0.1.13              06.13.19              - Add a Drop Down with values "Testing & Inspection" or "Repair Service" (default)
                                                  ---- END FIRE ONLY ---
      1.0.1.14  small       06.13.19    TFS 4667  Go Back to Separating Labor, Materials, Truck & Env. Safety Fee for T&M Billing - 
                            06.18.19        4667 UPDATE: 
                                                - Allow hide/show T&M labor rate
                                                     - hide displays total labor price
                                                    - show displays qty and rate
                                                - Omit $0.00 billable lines
                                        TFS 4313 - Agrmt: chng Ship To to Service Site
                                        TFS 4003 - multi-division agreements hide insert box except PO Number 
      1.0.2.0                                    - Change Ship to verbiage to "Service Site"
      1.0.2.1   small       06.20.19    TFS 4765 - T&M Labor: "Hide Rate" Do Not Display Price or Quantity
                                        TFS 4172 - Fixed Fire Template: If fitter notes missing, Work Performed Description is BLANK
                                    ** PROD RELEASE ** 6.20.19
                                      hotfixed:  - 6.20.19 - T&M missing 2nd labor line Price when Reg and OT 
                                                 - Agreement generating 2nd pg to fit "Thank You For Your Business!" row
                                        STAGING:
     1.0.2.6   med          06.26.19    TFS 4668 - SM Agreement Invoice to Pull Pay Terms from AR Customer
                                        TFS 4771 - Contract Value pulls from SMAgreement.AgreementPrice not RevenueWIPAmount
                                        TFS 4781 - SM Agreement Invoice Template to Move Service Site Address Over 1 position to K
                                        TFS 4780 - FIRE ONLY:
                                                 - Description "Repair Service" is now "Service Repair"
                                                 - Add "Fire Protection" to TYPE Column
                                                 - PayTerms pulled from ARCM
                                    ** PROD RELEASE ** 6.26.19
     1.0.2.7   small       7.11.19      TFS 4791 - Add "Tenant Improvement" to FIRE Drop Down Description List
     1.0.2.9   small                    TFS 4815 - Fix: Recipients tab Send From & Bill Email is BLACK 
                                        TFS 4812 - SQL Fix: Invoice detail is blank for some invoices
                                        + minor Recipients tab enhancements  
                                    ** PROD RELEASE ** 
     1.0.2.11  small       7.18.19      TFS 4828 - Bug Fix: unable to pull detail due to missing Scope 1 
                                        TFS 4823 - FIRE Invoice Template Description Drop Down to Say "Service Repair" instead of Repair Service
                                    ** PROD RELEASE **
     1.0.2.12    small                  TFS 5191 - BUG FIX: generating invoices for hidden rows
                                        TFS 5164 - FIRE WO inv. Remove "Service Repair" as default
                                                 - FIRE WO Inv. default Flat price detail description to blank
                                                 - FIRE Agreements' detail is now: "FIRE PROTECTION SERVICE BILLING AS PER AGREEMENT"
                                        TFS 4934 - ADD 'Material Order' to work description dropdown
                                    ** PROD RELEASE **  
     1.0.2.14   small     9.26.19   STG TFS 5476 - Agreement now has correct Contract Value when more than 1 active revision exists
												 - Agreement not returning data - fixed           
                                    ** PROD RELEASE **  10-10-2019                          
    //*****************************************************************************************************************/

    partial class ActionPane1 : UserControl
    { 
        #region FIELDS & PROPERTIES

        internal static AppSettingsReader _config => new AppSettingsReader();
        internal string Environ { get; }

        // dynamic is Syste.Dynamic.ExpandoObject which represent rows in the table
        internal Dictionary<dynamic, dynamic> _companyDict = new Dictionary<dynamic, dynamic>(); // combobox source
        internal List<dynamic> _tblCompanies; // fills _companyDict and also queried by SMInvoices.ToExcel() to get FedTaxId
        private List<dynamic> _divisionCenter = new List<dynamic>();
        //private List<string> _serviceSitesKV = new List<string>();
        private List<dynamic> _tblRecipients = null;
        List<dynamic> tblAgreemtEmailPhone = null;

        internal Excel.Worksheet _wsSMInvoices = null;
        internal Excel.Worksheet _wsInvoiceInputListSearch = null;
        private static Microsoft.Vbe.Interop.Forms.CommandButton CmdBtn;

        internal const string SMInvoices_TabName = "SM Invoices";
        internal const string Search_TabName = "Search";
        internal const string Recipients_TabName = "Recipients";

        // query filters
        internal byte SMCo { get; set; }
        private char InvoiceStatus { get; set; }
        private char PrintStatus { get; set; }
        internal int BillToCustomerID { get; set; } 
        private string InvoiceStart { get; set; }
        private string InvoiceEnd { get; set; }
        private string division;
        private dynamic serviceCenter;
        private bool detailTandMShowLaborRate = false;

        //internal Models.Viewpoint.InvoicePreview _invoiceWOPreview = null;
        private List<dynamic> _invoicePreview = null;

        internal bool _isBuildingTable = false;  // disallows multiple clicking overtaxing app
        internal bool MoreThanOneInvoiceSelected => _invoicePreview?.Count > 1;

        // remmeber the last checked checkbox to revert back after clearing quote id textbox
        private int _lastCheckedButton = 0;
        private bool _textLengthIsZero = true;

        // blink missing fields
        public byte @switch = 0x0;
        private int blinkCounter = 0;
        private Excel.Range _sendFrom { get; set; }

        #endregion

        public ActionPane1()
        {
            InitializeComponent();

            ///* DEPLOY TO DEV ENVIRONMENTS */
            cboTargetEnvironment.Items.Add("Dev");
            cboTargetEnvironment.Items.Add("Staging");
            cboTargetEnvironment.Items.Add("Project");
            cboTargetEnvironment.Items.Add("Upgrade");

            /* DEPLOY TO PROD */
            //cboTargetEnvironment.Items.Add("Prod");

            try
            {
                if (cboTargetEnvironment.Items.Count > 0) cboTargetEnvironment.SelectedIndex = 0;  // RefreshTargetEnvironment() -> RefreshCompanies() & RefreshDivisons() are called on change

                if ((string)cboTargetEnvironment.SelectedItem == "Prod") cboTargetEnvironment.Visible = false;

                lblVersion.Text = "v." + this.ProductVersion;
                btnGetInvoices.BackColor = System.Drawing.Color.Honeydew;

                rdoInvoiced.Checked = true;

                if (rdoInvoiced.Checked)
                {
                    if (rdoDeliveryAll.Checked) PrintStatus = '\0';
                    else if (rdoDelivered.Checked) PrintStatus = 'P';
                    else if (rdoNotDelivered.Checked) PrintStatus = 'N';
                }

                detailTandMShowLaborRate = rdoTandMHideLaborRate.Checked;
                
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
        }

        private void btnGetInvoices_Click(object sender, EventArgs e) => GetInvoiceDeliverySearch();

        //TODO: limit data pull to 1 year (Add year dropdown)
        private void GetInvoiceDeliverySearch()
        {
            List<dynamic> table = null;
            object[,] myInvoices = null;
            dynamic myInvoiceDyn = null;
            object[] myinvoiceList = null;
            InvoiceList invoiceList = null;
            Application.UseWaitCursor = true;
            Excel.ListObject xltable = null;

            btnGetInvoices.Tag = btnGetInvoices.Text;
            btnGetInvoices.Text = "Processing...";
            btnGetInvoices.Refresh();
            btnGetInvoices.Enabled = false;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();

            try
            {
                if (!IsValidFields()) throw new Exception("invalid fields");

                // prep invoiceList structure to be sent to query
                if (_wsInvoiceInputListSearch != null)
                {
                    myInvoiceDyn = _wsInvoiceInputListSearch.get_Range("A2:A" + _wsInvoiceInputListSearch.UsedRange.SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row).Value2;

                    if (myInvoiceDyn != null)
                    {
                        invoiceList = new InvoiceList();

                        if (myInvoiceDyn?.GetType() == typeof(object[,]))
                        {
                            myInvoices = myInvoiceDyn;

                            // flatten 2D array to 1D array
                            myinvoiceList = myInvoices.Cast<object>().ToArray();

                            // get all invoice numbers that will be searched
                            for (int i = 0; i <= myinvoiceList.Length - 1; i++)
                            {
                                var invoice = myinvoiceList[i]?.ToString().Trim();

                                if (invoice != null && invoice != "") // do not send null or empty records
                                {
                                    invoiceList.Add(new InvoiceParam(invoice));
                                }
                            }
                        }
                        else
                        {
                            invoiceList.Add(new InvoiceParam(myInvoiceDyn.ToString())); //single entry

                        }
                    }

                    // ignore consecutive range search
                    InvoiceStart = null;
                    InvoiceEnd = null;
                }
                else
                {
                    InvoiceStart = txtInvoiceStart.Text.Trim();
                    InvoiceEnd = txtInvoiceEnd.Text.Trim();

                    InvoiceStart = InvoiceStart == "" ? null : InvoiceStart;
                    InvoiceEnd   = InvoiceEnd   == "" ? null : InvoiceEnd;
                }

                if (!grpDelivery.Enabled) PrintStatus = '\0';

                SMCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

                if(cboDivision.SelectedItem.ToString() == "Any")
                {
                    division = null;
                }
                else
                {
                    // grab 'Division' instead of Division's "Description"
                    division = _divisionCenter.Where(n => n.Description == cboDivision.SelectedItem.ToString()).Select(x => x.Division)?.First();
                }

                serviceCenter = cboServiceCenter.SelectedItem.ToString() == "Any" ? null : cboServiceCenter.SelectedItem.ToString();

                // grab 'ServiceCenter' ID instead of Service Center Description
                serviceCenter = serviceCenter != null && division != null ? _divisionCenter.Where(n => n.Division == division && n.ServiceCenterDescription == serviceCenter)
                                                                                            .Select(x => x.ServiceCenter).First() : null;

                table = InvoiceDeliverySearch.GetInvoices(SMCo, InvoiceStatus, PrintStatus, BillToCustomerID, InvoiceStart, InvoiceEnd, invoiceList, division, serviceCenter);

                _wsSMInvoices = HelperUI.GetSheet(SMInvoices_TabName, false);

                if (table?.Count > 0)
                {
                    Globals.ThisWorkbook.SheetActivate -= Globals.ThisWorkbook.ThisWorkbook_SheetActivate;

                    if (_wsSMInvoices == null)
                    {
                        // Create new sheet
                        Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.BaseInvoiceList.Copy(after: Globals.ThisWorkbook.Sheets[Globals.BaseInvoiceList.Index]);
                        _wsSMInvoices = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                        _wsSMInvoices.Name = SMInvoices_TabName;

                        Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    }

                    if (_wsSMInvoices != null)
                    {
                        _wsSMInvoices.Activate();

                        string tableName = SMInvoices_TabName.Replace(" ", "_").Replace("-", "_");

                        if (_wsSMInvoices.ListObjects.Count == 1)
                        {
                            // after already ran
                            Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.BaseInvoiceList.Copy(after: Globals.ThisWorkbook.Sheets[Globals.BaseInvoiceList.Index]);
                            HelperUI.DeleteSheet(_wsSMInvoices.Name);
                            _wsSMInvoices = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                            _wsSMInvoices.Name = SMInvoices_TabName;
                            Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        }

                        _isBuildingTable = true;
                        xltable = SheetBuilderDynamic.BuildTable(_wsSMInvoices, table, tableName, offsetFromLastUsedCell: 2, bandedRows: true);
                        _isBuildingTable = false;

                        _invoicePreview = null;
                        _invoicePreview = new List<dynamic>();

                        _wsSMInvoices.SelectionChange += Invoice_SelectionChange;

                        xltable.DataBodyRange.Cells[1, 1].Activate();

                        xltable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                        xltable.ListColumns["Invoice Date"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                        xltable.ListColumns["Customer Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        xltable.ListColumns["Customer Name"].DataBodyRange.EntireColumn.AutoFit();
                        xltable.ListColumns["Bill To"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        xltable.ListColumns["Bill To"].DataBodyRange.EntireColumn.AutoFit();
                        xltable.ListColumns["Bill To Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        xltable.ListColumns["Bill To Name"].DataBodyRange.EntireColumn.AutoFit();
                        xltable.ListColumns["Sent Date"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        xltable.ListColumns["Sent By"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        xltable.ListColumns["Sent By"].DataBodyRange.EntireColumn.ColumnWidth = 12;
                        xltable.ListColumns["Invoice Amt"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                        xltable.ListColumns["Total Paid"].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                        xltable.ListColumns["SMCo"].DataBodyRange.EntireColumn.ColumnWidth = 6.25;
                        xltable.ListColumns["Invoice Date"].DataBodyRange.EntireColumn.ColumnWidth = 8;
                        xltable.ListColumns["Work Orders"].DataBodyRange.EntireColumn.AutoFit();

                        if (xltable.ListRows.Count > 1)
                        {
                            xltable.Sort.SortFields.Add(xltable.ListColumns["Invoice Type"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlDescending);
                            xltable.Sort.SortFields.Add(xltable.ListColumns["Invoice Number"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                            xltable.Sort.Apply();
                        }

                        HelperUI.MergeLabel(_wsSMInvoices, xltable.ListColumns[1].Name, xltable.ListColumns[xltable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                        _wsSMInvoices.Application.ActiveWindow.SplitRow = 4;
                        _wsSMInvoices.Application.ActiveWindow.FreezePanes = true;
                        _wsSMInvoices.Application.ErrorCheckingOptions.NumberAsText = false;
                    }
                }
                else
                {
                    if (_wsSMInvoices != null)
                    {
                        if (_wsSMInvoices.ListObjects.Count == 1) _wsSMInvoices.ListObjects[1].DataBodyRange.Clear();
                    }

                    btnGetInvoices.BackColor = System.Drawing.Color.Honeydew;

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
                btnGetInvoices.Text = btnGetInvoices.Tag.ToString();
                btnGetInvoices.Enabled = true;
                btnGetInvoices.Refresh();
                btnDeliverInvoices.Enabled = false;
                btnDeliverInvoices.BackColor = System.Drawing.SystemColors.ControlLight;

                if (xltable?.ListRows.Count > 0)
                {
                    btnPreviewOrCopyOffline.Enabled = true;
                    btnPreviewOrCopyOffline.BackColor = System.Drawing.Color.Honeydew;
                    btnGetInvoices.BackColor = System.Drawing.SystemColors.ControlLight;
                }
                else
                {
                    btnPreviewOrCopyOffline.Enabled = false;
                    btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
                }
                HelperUI.RenderON();
                HelperUI.AlertON();
                Globals.ThisWorkbook.SheetActivate += Globals.ThisWorkbook.ThisWorkbook_SheetActivate;

                if (xltable != null) Marshal.ReleaseComObject(xltable);
                //btnPrint.Enabled = false;

            }
        }

        private void btnPreview_or_CopyOffline_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            btnPreviewOrCopyOffline.Tag = btnPreviewOrCopyOffline.Text;
            btnPreviewOrCopyOffline.Enabled = false;
            btnDeliverInvoices.Enabled = false;
            HelperUI.AlertOff();
            HelperUI.RenderOFF();

            Excel.ListObject xltable = null;
            Excel.Worksheet recipients = null;
            Excel.Range rng = null;

            List<dynamic> tblWOInvoices = null;
            List<dynamic> tblAgreementInvoices = null;
            string tempPDF = null;

            bool oneOrMoreAgrInvoices = false;
            bool oneOrMoreWOinvoices = false;
            bool agreementInvCreatedOK = false;
            bool woInvCreatedOK = false;

            //TFS 4797 uncomment below
            Excel.Range rngDiv = null;
            Excel.Range currentFind = null;
            int divisionCol = 0;
            int sendFromCol = 0;
            int billingPhoneCol = 0;
            int rowAt = 0;
            string divisionList = "";
            bool multiDivisionWithMultipleMcKContacts = false;

            try
            {
                if (btnPreviewOrCopyOffline.Text.Contains("Preview"))
                {

                    btnPreviewOrCopyOffline.Text = "Processing...";
                    btnPreviewOrCopyOffline.Refresh();

                    if (_invoicePreview?.Count > 0)
                    {
                        _tblRecipients = Recipients.GetRecipients(_invoicePreview);

                        var woInvoices = _invoicePreview.Where(n => n.Agreement == "").Cast<dynamic>().ToList();
                        oneOrMoreWOinvoices = woInvoices.Skip(0).Any(); // (checks count without traversing)

                        if (oneOrMoreWOinvoices) // 1 or more break-fix (WO) invoices exists 
                        {
                            tblWOInvoices = Data.Viewpoint.InvoicePreview.GetWOinvoiceHeader(woInvoices);
                        }
                        
                        var agreementInvoices = _invoicePreview.Where(n => n.Agreement != "").Cast<dynamic>().ToList();
                        oneOrMoreAgrInvoices = agreementInvoices.Skip(0).Any();

                        if (oneOrMoreAgrInvoices) // 1 or more exists without traversing
                        {
                            // this tries to grab the Service Site associated with agreements
                            //foreach (var inv in agreementInvoices)
                            //{
                            //    foreach (var recp in tblRecipients)
                            //    {
                            //        var r = (IDictionary<string, object>)recp;

                            //        var recpInvoice = ((KeyValuePair<string, object>)r["Invoice Number"]).Value.ToString().Trim();

                            //        if (inv.InvoiceNumber == recpInvoice)
                            //        {
                            //            var recpServiceSite = ((KeyValuePair<string, object>)r["Service Site"]).Value.ToString().Trim();

                            //            inv.ServiceSite = recpServiceSite; //update ServiceSite
                            //            break;
                            //        }
                            //    }
                            //}

                            tblAgreementInvoices = Data.Viewpoint.InvoicePreview.GetAgreementInvoiceHeader(agreementInvoices);
                        }

                        #region check whether a invoice exist more than once, if so it means it has multiple WOs and is an Agreement

                        //var invoiceMoreThanOnce = tblInvoices.GroupBy(r => r.InvoiceNumber.Value).Where(n => n.Skip(1).Any()).Distinct();

                        //foreach (var inv in invoiceMoreThanOnce)
                        //{
                        //    var i = inv.First();
                        //    var chooseSiteFromList = tblInvoices.Where(n => n.InvoiceNumber.Value == i.InvoiceNumber.Value).Cast<dynamic>().ToList();

                        //    xltable = CreateWorksheet(chooseSiteFromList, "tblChooseSite", "Choose Site");
                        //    xltable.HeaderRowRange.WrapText = false;
                        //    xltable.HeaderRowRange.EntireColumn.AutoFit();
                        //    xltable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                        //    sh = (Excel.Worksheet)xltable.Parent;
                        //    rng = sh.get_Range("A2");
                        //    rng.Formula = "Choose the Recipient for " + i.InvoiceNumber.Value;
                        //    rng.Font.Bold = true;
                        //    rng.Font.Size = 16;
                        //}

                        //bool hasMultipleWOs = uniqueInvoices.Count() > tblInvoices.Count;
                        #endregion

                        if (oneOrMoreWOinvoices || oneOrMoreAgrInvoices)
                        {
                            HelperUI.DeleteLeftOverTabs();

                            #region CREATE RECIPIENTS TAB

                            if (_tblRecipients.Count > 0)
                            {
                                #region FORMAT RECIPIENTS TABLE

                                xltable = HelperUI.CreateWorksheetWithTable(_tblRecipients, "tblRecipients", Recipients_TabName);
                                xltable.HeaderRowRange.WrapText = true;
                                xltable.HeaderRowRange.EntireRow.RowHeight = 30;
                                xltable.HeaderRowRange.EntireColumn.AutoFit();
                                xltable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                                xltable.ListColumns["Send From"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Delivery Method"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Customer Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Bill TO"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Bill Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Bill Email"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Bill Address"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                xltable.ListColumns["Bill Address2"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                                rng = xltable.ListColumns["Bill CC Email"].DataBodyRange;
                                rng.Interior.Color = HelperUI.YellowLight;
                                rng = xltable.HeaderRowRange[1, rng.Column];
                                rng.AddComment("You may enter a comma-delimited list of email addresses here.");
                                rng.Comment.Shape.Height = 25;
                                rng.Comment.Shape.Width = 160;
                                rng.Comment.Shape.Top = 5;
                                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                
                                recipients = (Excel.Worksheet)xltable.Parent;
                                rng = recipients.get_Range("A2");
                                rng.Formula = "MCK SM Recipients";
                                rng.Font.Bold = true;
                                rng.Font.Size = 16;

                                recipients.get_Range("A1").EntireRow.RowHeight = 21;

                                HelperUI.Recipients_ConditionalFormat(xltable);

                                xltable.ListColumns["Billing Phone"].DataBodyRange.NumberFormat = HelperUI.PhoneNumber;

                                xltable.ListColumns["Bill"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Send From"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill Email"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Invoice Number"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Sent Date"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Delivery Method"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Delivery To"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Customer"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Customer Name"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill To"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill Name"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill Address"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill Address2"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill City"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill State"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Bill Zip"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Required WO With Billing"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Require Inspection Report With Billing"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Sign Off Required"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Lien Release"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Certified Payroll"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["SMCo"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Service Site"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Work Orders"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Division"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Billing Phone"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Customer Group"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                                xltable.ListColumns["Invoice Summary Level"].DataBodyRange.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;

                                xltable.ListColumns["Bill"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Send From"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill Email"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Invoice Number"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Sent Date"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Delivery Method"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Delivery To"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Customer"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Customer Name"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill To"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill Name"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill Address"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill Address2"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill City"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill State"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Bill Zip"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Required WO With Billing"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Require Inspection Report With Billing"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Sign Off Required"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Lien Release"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Certified Payroll"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["SMCo"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Service Site"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Work Orders"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Division"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Billing Phone"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Customer Group"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;
                                xltable.ListColumns["Invoice Summary Level"].DataBodyRange.Interior.TintAndShade = HelperUI.tintshadelight;

                                xltable.ListColumns["Delivery Method"].DataBodyRange.EntireColumn.AutoFit();
                                xltable.ListColumns["Send From"].DataBodyRange.EntireColumn.AutoFit();

                                xltable.ListColumns["Invoice Summary Level"].DataBodyRange.EntireColumn.ColumnWidth = 13.13;
                                xltable.ListColumns["Required WO With Billing"].DataBodyRange.EntireColumn.ColumnWidth = 11.50;
                                xltable.ListColumns["Require Inspection Report With Billing"].DataBodyRange.EntireColumn.ColumnWidth = 13.75;
                                xltable.ListColumns["Sign Off Required"].DataBodyRange.EntireColumn.ColumnWidth = 9.38;
                                xltable.ListColumns["Lien Release"].DataBodyRange.EntireColumn.ColumnWidth = 8.25;
                                xltable.ListColumns["Certified Payroll"].DataBodyRange.EntireColumn.ColumnWidth = 8.13;
                                xltable.ListColumns["Work Orders"].DataBodyRange.EntireColumn.ColumnWidth = 7.50;
                                xltable.ListColumns["Billing Phone"].DataBodyRange.EntireColumn.ColumnWidth = 9.38;
                                xltable.ListColumns["Customer Group"].DataBodyRange.EntireColumn.ColumnWidth = 7.63;

                                recipients.Change += Recipients_SheetChange;

                                #endregion

                                CreateOLEButtonContacts(xltable.Parent, "C1");

                                if (oneOrMoreWOinvoices)
                                {
                                    woInvCreatedOK = SMInvoices.ToExcel(tblWOInvoices, _tblRecipients, detailTandMShowLaborRate);
                                }

                                if (oneOrMoreAgrInvoices)
                                {
                                    // create the Invoice tab
                                    agreementInvCreatedOK = SMInvoices.ToExcel(tblAgreementInvoices, _tblRecipients, null);

                                    // get corresponding MCK contacts to agreements
                                    divisionCol = xltable.ListColumns["Division"].DataBodyRange.Column;
                                    sendFromCol = xltable.ListColumns["Send From"].DataBodyRange.Column;
                                    billingPhoneCol = xltable.ListColumns["Billing Phone"].DataBodyRange.Column;

                                    tblAgreemtEmailPhone = Recipients.GetAgreemtMcKEmailPhone(agreementInvoices);

                                    var uniqueInvoices = tblAgreemtEmailPhone.GroupBy(x => x.InvoiceNumber).Distinct();

                                    foreach (var invoice in uniqueInvoices)
                                    {
                                        dynamic inv = invoice.First();

                                        var grpByInvDivision = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value == inv.InvoiceNumber.Value)
                                                                         .GroupBy(r => new
                                                                            {
                                                                                InvoiceNumber = r.InvoiceNumber.Value,
                                                                                Division = r.Division.Value
                                                                            })
                                                                          .Select(n => new { n.Key.InvoiceNumber, n.Key.Division })
                                                                          .Distinct();
                                        // find invoice number on the excel grid
                                        currentFind = rng.Find(inv.InvoiceNumber.Value.Trim(), Type.Missing,
                                                            Excel.XlFindLookIn.xlFormulas,
                                                            Excel.XlLookAt.xlWhole,
                                                            Excel.XlSearchOrder.xlByRows,
                                                            Excel.XlSearchDirection.xlNext,
                                                            Type.Missing, Type.Missing, Type.Missing);

                                        // get Excel row #
                                        if (currentFind != null)
                                        {
                                            rowAt = currentFind.Row;
                                        }
                                        else
                                        {
                                            continue;
                                        }

                                        rngDiv = recipients.Cells[rowAt, divisionCol];

                                        if (grpByInvDivision.Count() > 1) // multi-division ?
                                        {
                                            var grpByEmailPhone = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value == inv.InvoiceNumber.Value)
                                                                                     .GroupBy(r => new
                                                                                        {
                                                                                            Email = r.Email.Value,
                                                                                            PhoneNumber = r.PhoneNumber.Value
                                                                                        })
                                                                                      .Select(n => new { n.Key.Email, n.Key.PhoneNumber })
                                                                                      .Distinct();

                                            multiDivisionWithMultipleMcKContacts = grpByEmailPhone.Count() > 1;

                                            // convert to comma-delimited Division list
                                            var arrDivision = grpByInvDivision.Select(x => x.Division).ToArray();
                                            divisionList = string.Join(",", arrDivision);

                                            // Create a drop down list if multiple contacts
                                            if (multiDivisionWithMultipleMcKContacts) 
                                            {
                                                // MULTIPLE MCKINSTRY CONTACTS - multi-division

                                                // add Divison drop down 
                                                rngDiv.Validation.Delete();
                                                rngDiv.Validation.Add(
                                                                    Excel.XlDVType.xlValidateList,
                                                                    Excel.XlDVAlertStyle.xlValidAlertInformation,
                                                                    Excel.XlFormatConditionOperator.xlBetween,
                                                                    divisionList,  // <---- comma delimited list
                                                                    Type.Missing);
                                                rngDiv.Validation.IgnoreBlank = true;
                                                rngDiv.Validation.InCellDropdown = true;
                                                rngDiv.Interior.Color = HelperUI.YellowLight;
                                                rngDiv.Formula = arrDivision[0];
                                            }
                                            else  // SINGLE MCK CONTACT - multi-division
                                            {
                                                // update Recipients tab 
                                                rngDiv.Formula = divisionList;
                                                //recipients.Cells[rowAt, sendFromCol] = grpByEmailPhone.Select(x => x.Email).FirstOrDefault();
                                                //recipients.Cells[rowAt, billingPhoneCol] = grpByEmailPhone.Select(x => x.PhoneNumber).FirstOrDefault();
                                            }
                                        }
                                        else
                                        {
                                            // SINGLE MCKINSTRY CONTACT DETAIL - Single division or multi-division 
                                            //foreach (var recp in _tblRecipients)
                                            //{
                                            //    var r = (IDictionary<string, object>)recp;

                                            //    var recpInvoice = ((KeyValuePair<string, object>)r["Invoice Number"]).Value.ToString().Trim();

                                            //    if (inv.InvoiceNumber.Value.Trim() == recpInvoice)
                                            //    {
                                            //        r["Send From"] = inv.Email;
                                            //        r["Billing Phone"] = inv.PhoneNumber;
                                            //        r["Division"] = inv.Division;
                                            //        break;
                                            //    }
                                            //}
                                            rngDiv.Formula = grpByInvDivision.Select(x => x.Division).FirstOrDefault();
                                        }

                                        // populate Recipients tab email and phone number
                                        if (!multiDivisionWithMultipleMcKContacts)
                                        {
                                            updateRecipientsTabAndInvoiceMcKContact(inv.InvoiceNumber.Value.Trim());
                                        }
                                        else // multi-division with mutliple contacts; use dropdown list to get specific division contact
                                        {
                                            Recipients_SheetChange(rng); // updates Recipients tab and Invoice "DIRECT INQUIRIES TO" section
                                        }
                                    }
                                }

                                if (woInvCreatedOK || agreementInvCreatedOK)
                                {
                                    recipients.Activate();
                                    xltable.DataBodyRange.Cells[1, 1].Activate();
                                    btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
                                    btnDeliverInvoices.Enabled = true;
                                    btnDeliverInvoices.BackColor = System.Drawing.Color.Honeydew;
                                    btnDeliverInvoices.Focus();
                                    //SendKeys.Send("{TAB}"); //sets focus on btnDeliverInvoices
                                    this.ScrollControlIntoView(btnDeliverInvoices);
                                }

                            }
                            else
                            {
                                HelperUI.ShowInfo(null, "No Invoice recipient data found.");
                            }
                            #endregion

                        }
                        else
                        {
                            HelperUI.ShowInfo(null, "No Invoice detail data found.");
                        }
                    }
                }

                else if (btnPreviewOrCopyOffline.Text == "Save Invoices Offline")
                {
                    btnPreviewOrCopyOffline.Text = "Saving...";
                    btnPreviewOrCopyOffline.Refresh();

                    try
                    {
                        using (var d = new FolderBrowserDialog())
                        {
                            d.Description = "Save your invoice" + (_invoicePreview?.Count > 1 ? "s" : "") + " to:";
                            //diag.RootFolder = Environment.SpecialFolder.MyComputer;
                            //d.RootFolder = Environment.GetFolderPath(Environment.SpecialFolder.Personal);

                            DialogResult action = d.ShowDialog();

                            if (action == DialogResult.OK && !string.IsNullOrWhiteSpace(d.SelectedPath))
                            {
                                foreach (var invoice in _invoicePreview)
                                {
                                    recipients = HelperUI.GetSheet(invoice.InvoiceNumber);

                                    if (recipients != null)
                                    {
                                        tempPDF = IOexcel.GetWorksheetAsPDF(recipients);

                                        string copyToPathFullFileName = Path.Combine(d.SelectedPath, "McK SM Invoice " + recipients.Name.Trim() + ".pdf");

                                        IOexcel.CopyFileToFolder(tempPDF, copyToPathFullFileName);
                                    }
                                }
                                btnPreviewOrCopyOffline.Text = "Copied!";
                                btnPreviewOrCopyOffline.Refresh();

                                HelperUI.ShowInfo(msg: "All invoices copied!");
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        HelperUI.ShowErr(ex, title: "Failed Copy Offline!");
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

                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.ThisWorkbook.InnerObject.SheetActivate += Globals.ThisWorkbook.ThisWorkbook_SheetActivate;
                Globals.ThisWorkbook.ThisWorkbook_SheetActivate(Globals.ThisWorkbook.ActiveSheet);
                HelperUI.AlertON();
                HelperUI.RenderON();
                tblWOInvoices = null;
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (File.Exists(tempPDF)) File.Delete(tempPDF);
                btnPreviewOrCopyOffline.Text = btnPreviewOrCopyOffline.Tag.ToString();
                btnPreviewOrCopyOffline.BackColor = System.Drawing.Color.Honeydew;
                btnPreviewOrCopyOffline.Refresh();
            }
        }

        private void btnGetQuotes_Click(object sender, EventArgs e)
        {
            string vstolocation = "";

            try
            {
                switch (Environ)
                {
                    case "Prod":
                        vstolocation = @"\\mckviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McK.SMQuotes.Viewpoint\McK.SMQuotes.Viewpoint.xltx";
                        break;

                    case "Proj":
                        vstolocation = @"\\sea-stgupgvp01\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McK.SMQuotes.Viewpoint\McK.SMQuotes.Viewpoint.xltx";
                        break;

                    case "Stg":
                        vstolocation = @"\\sestgviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McK.SMQuotes.Viewpoint\McK.SMQuotes.Viewpoint.xltx";
                        break;

                    default:
                        throw new Exception("Oops..something went wrong. Try launching it from the Viewpoint menu.");
                }

                IOexcel.OpenSpreadsheet(vstolocation);
            }
            catch (Exception ex)
            {
                HelperUI.errOut(ex);
            }

        }

        /// <summary>
        /// Create button that can create the McKinstry Billing Contacts tab
        /// </summary>
        private static void CreateOLEButtonContacts(Excel.Worksheet ws, string cellTarget = "A1")
        {
            Excel.Range rng = ws.get_Range(cellTarget);

            // insert button shape
            Excel.Shape cmdButton = ws.Shapes.AddOLEObject("Forms.CommandButton.1", Type.Missing, false, false, Type.Missing, Type.Missing, Type.Missing, rng.Left, rng.Top, rng.Width, rng.Height);
            cmdButton.Name = "btnButtonContacts";

            // bind it and wire it up
            CmdBtn = (Microsoft.Vbe.Interop.Forms.CommandButton)Microsoft.VisualBasic.CompilerServices.NewLateBinding.LateGet(ws, null, "btnButtonContacts", new object[0], null, null, null);
            CmdBtn.Caption = "Contacts";
            CmdBtn.Click += new MSForms.CommandButtonEvents_ClickEventHandler(ExecuteCmd_Click);
        }

        /// <summary>
        /// Create McKinstry Billing Contacts tab
        /// </summary>
        private static void ExecuteCmd_Click()
        {
            Excel.Worksheet ws = null;
            Excel.Range rng = null;

            try
            {
                var table = Recipients.GetDivServCenterContacts();

                if (table.Skip(0).Any())
                {
                    ws = HelperUI.GetSheet("Contacts");

                    if (ws != null)
                    {
                        HelperUI.AlertOff();
                        ws.Delete();
                        HelperUI.AlertON();
                    }

                    var xltable = HelperUI.CreateWorksheetWithTable(table, "udxrefSMFromEmail", "Contacts");
                    rng = xltable.ListColumns["PhoneNumber"].DataBodyRange;
                    rng.NumberFormat = HelperUI.PhoneNumber;
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.DataBodyRange.EntireColumn.AutoFit();
                    ws = xltable.Parent;

                    rng = ws.get_Range("A2");
                    rng.Formula = "McKinstry Billing Contacts";
                    rng.Font.Size = 14;
                    rng.Font.Bold = true;
                    rng.VerticalAlignment = Excel.XlVAlign.xlVAlignTop;
                }
                

            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
        }


        /// <summary>
        /// Collect WOs and Agrements into separate lists to query for details preview
        /// </summary>
        /// <param name="Target"></param>
        private void Invoice_SelectionChange(Excel.Range Target)
        {
            if (_wsSMInvoices == null || _isBuildingTable || _wsSMInvoices.ListObjects[1].ListColumns.Count == 0) return;

            Excel.ListObject xltable = null;
            Excel.Range rng = null;;
            bool disableBtnPreview = false;
            long smCOcol = 0;
            long customerCol = 0;
            long smInvoiceIDcol = 0;
            long invoiceNumberCol = 0;
            long workOrderCol = 0;
            long agreementCol = 0;
            string invType = "";

            try
            {
                if (_wsSMInvoices.ListObjects.Count > 0)
                {
                    xltable = _wsSMInvoices.ListObjects[1];

                    if (Target.Application.Intersect(xltable.DataBodyRange, Target) != null) // is selection inside grid ?
                    {
                        rng = Target.Application.ActiveWindow.Selection;

                        if (rng.CountLarge > xltable.DataBodyRange.CountLarge) return; // does selection extend passed table body boundries?

                        _invoicePreview?.Clear();

                        smCOcol          = xltable.ListColumns["SMCo"].Index;
                        customerCol      = xltable.ListColumns["Customer"].Index;
                        smInvoiceIDcol   = xltable.ListColumns["SMInvoiceID"].Index;
                        invoiceNumberCol = xltable.ListColumns["Invoice Number"].Index;
                        workOrderCol     = xltable.ListColumns["Work Orders"].Index;
                        agreementCol     = xltable.ListColumns["Agreement"].Index;

                        foreach (Excel.Range c in rng)
                        {
                            // ignore hidden rows -- TFS 5191
                            if (c.RowHeight == 0) continue;

                            var rowAt = _wsSMInvoices.get_Range("A" + c.Row);

                            invType = rowAt.Formula;

                            if (invType == "Work Order")
                            {
                                dynamic expado = new System.Dynamic.ExpandoObject();

                                expado.SMCo         = Convert.ToByte(_wsSMInvoices.Cells[c.Row, smCOcol].Value);
                                expado.Customer     = Convert.ToInt64(_wsSMInvoices.Cells[c.Row, customerCol].Value);
                                expado.smInvoiceID  = Convert.ToInt64(_wsSMInvoices.Cells[c.Row, smInvoiceIDcol].Value);
                                expado.InvoiceNumber = _wsSMInvoices.Cells[c.Row, invoiceNumberCol].Formula.Trim();
                                expado.WorkOrders    = _wsSMInvoices.Cells[c.Row, workOrderCol].Formula.Trim();
                                expado.Agreement    = _wsSMInvoices.Cells[c.Row, agreementCol].Formula.Trim();

                                _invoicePreview.Add(expado);
                                //_invoiceWOPreview.Add(new InvoicePreviewParam(smco, smInvoiceID, invoiceNumber, workOrder));
                            }
                            else if (invType == "Agreement")
                            {
                                dynamic expado = new System.Dynamic.ExpandoObject();

                                expado.SMCo          = Convert.ToByte(_wsSMInvoices.Cells[c.Row, smCOcol].Value);
                                expado.Customer      = Convert.ToInt64(_wsSMInvoices.Cells[c.Row, customerCol].Value);
                                expado.InvoiceNumber = _wsSMInvoices.Cells[c.Row, invoiceNumberCol].Formula.Trim();
                                expado.Agreement     = _wsSMInvoices.Cells[c.Row, agreementCol].Formula.Trim();

                                _invoicePreview.Add(expado);
                            }
                        }

                        if (_invoicePreview?.Count > 0)
                        {
                            btnPreviewOrCopyOffline.Text = "Preview Invoice" + (MoreThanOneInvoiceSelected ? "s " : "");
                            btnPreviewOrCopyOffline.Enabled = true;
                            btnPreviewOrCopyOffline.BackColor = System.Drawing.Color.Honeydew;
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
                        btnPreviewOrCopyOffline.Enabled = false;
                        btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
                    }
                }
            }
            catch (Exception ex)
            {
                HelperUI.errOut(ex);
            }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }

        #region POPULATE MCK AGREEMENT CONTACTS - TFS 4797

        /// <summary>
        /// A version of updateRecipientsTabAndInvoiceMcKContact but with visual cues
        /// </summary>
        /// <param name="Target"></param>
        private void Recipients_SheetChange(Excel.Range Target)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xltable = null;
            Excel.Range rng = null;
            long divisionCol = 0;

            try
            {
                ws = Target.Parent;

                if (ws.ListObjects.Count > 0)
                {
                    xltable = ws.ListObjects[1];

                    if (Target.Application.Intersect(xltable.DataBodyRange, Target) != null)
                    {
                        if (Target.CountLarge > 1) return;

                        divisionCol = xltable.ListColumns["Division"].Index;

                        if (Target.Column == divisionCol)
                        {
                            long invoiceNumberCol = xltable.ListColumns["Invoice Number"].Index;
                            string invoiceNumber = ws.Cells[Target.Row, invoiceNumberCol].Formula;

                            updateRecipientsTabAndInvoiceMcKContact(invoiceNumber, visualCue: true);
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
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }

        /// <summary>
        /// Updates Send From email and phone number in Recipients tab and Invoice
        /// </summary>
        /// <param name="invoiceNumber"></param>
        /// <param name="visualCue"></param>
        private void updateRecipientsTabAndInvoiceMcKContact(string invoiceNumber, bool visualCue = false)
        {
            if (invoiceNumber == "") return;

            Excel.Worksheet wsRecipients = null;
            Excel.Worksheet wsInvoice = null;
            Excel.ListObject xltable = null;
            Excel.Range rngInvoiceRecipAt = null;
            Excel.Range rngDiv = null;
            string divisionList = "";

            try
            {
                wsRecipients = HelperUI.GetSheet(Recipients_TabName);

                if (wsRecipients != null)
                {
                    xltable = wsRecipients.ListObjects[1];

                    long divisionCol = xltable.ListColumns["Division"].Index;
                    long invoiceNumberCol = xltable.ListColumns["Invoice Number"].Index;
                    long sendFromCol = xltable.ListColumns["Send From"].Index;
                    long billingPhoneCol = xltable.ListColumns["Billing Phone"].Index;

                    rngInvoiceRecipAt = wsRecipients.Cells[1, invoiceNumberCol].EntireColumn;

                    // find invoice number on the excel grid
                    rngInvoiceRecipAt = rngInvoiceRecipAt.Find(invoiceNumber, 
                                        Type.Missing,
                                        Excel.XlFindLookIn.xlFormulas,
                                        Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows,
                                        Excel.XlSearchDirection.xlNext,
                                        Type.Missing, Type.Missing, Type.Missing);

                    if (rngInvoiceRecipAt != null)
                    {
                        var grpByInvDivision = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value.Trim() == invoiceNumber)
                                                                         .GroupBy(r => new
                                                                         {
                                                                             InvoiceNumber = r.InvoiceNumber.Value,
                                                                             Division = r.Division.Value
                                                                         })
                                                                          .Select(n => new { n.Key.InvoiceNumber, n.Key.Division })
                                                                          .Distinct();

                        // if multi-division w/ same contact show division list, else division from structure
                        rngDiv = wsRecipients.Cells[rngInvoiceRecipAt.Row, divisionCol];
                        divisionList = rngDiv.Formula;
                        var divmem = grpByInvDivision.Where(n => n.Division == rngDiv.Formula).FirstOrDefault();

                        // update Recipients tab 
                        wsRecipients.Change -= Recipients_SheetChange;

                        // get email and phone number from memory
                        IEnumerable<dynamic> invMcKContactList;

                        if (divisionList.ContainsIgnoreCase(","))
                        {
                            rngDiv.Formula = divisionList;
                            invMcKContactList = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value.Trim() == invoiceNumber);
                        }
                        else
                        {
                            rngDiv.Formula = divmem.Division;
                            invMcKContactList = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value.Trim() == invoiceNumber && (x.Division.Value == divmem.Division));
                        }
                        //rngDiv.Formula = divisionList.ContainsIgnoreCase(",") ? divisionList : divmem.Division;
                        rngDiv.EntireColumn.AutoFit();

                        //var invMcKContactList = tblAgreemtEmailPhone.Where(x => x.InvoiceNumber.Value.Trim() == invoiceNumber && (x.Division.Value == divisionList));
                        var invMcKContact = invMcKContactList.FirstOrDefault();

                        wsRecipients.Cells[rngInvoiceRecipAt.Row, sendFromCol].Formula  = invMcKContact.Email.Value;
                        wsRecipients.Cells[rngInvoiceRecipAt.Row, sendFromCol].EntireColumn.AutoFit();
                        wsRecipients.Cells[rngInvoiceRecipAt.Row, billingPhoneCol].Formula = invMcKContact.PhoneNumber.Value;

                        wsRecipients.Change += Recipients_SheetChange;

                        //update Invoice tab
                        wsInvoice = HelperUI.GetSheet(invoiceNumber);

                        if (wsInvoice != null)
                        {
                            wsInvoice.Names.Item("MCKINSTRY_EMAIL_PHONE").RefersToRange.Formula = "DIRECT INQUIRIES TO " + invMcKContact.Email.Value.ToUpper() + " PHONE " + invMcKContact.PhoneNumber.Value.ToUpper();

                            if (visualCue)
                            {
                                _sendFrom = wsRecipients.Cells[rngInvoiceRecipAt.Row, sendFromCol]; // cell to blink
                                tmrAlertCell.Enabled = true;
                            }
                        }
                    }
                }
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rngInvoiceRecipAt != null) Marshal.ReleaseComObject(rngInvoiceRecipAt);
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (wsRecipients != null) Marshal.ReleaseComObject(wsRecipients);
                if (wsInvoice != null) Marshal.ReleaseComObject(wsInvoice);
            }
        }

        #endregion

        private void btnDeliverInvoices_Click(object sender, EventArgs e)
        {
            Application.UseWaitCursor = true;

            Outlook.Application oApp = null;
            Outlook.MailItem mail = null;
            Excel.Worksheet wsInvoice = null;
            Excel.Worksheet wsRecipients = null;
            Excel.Worksheet wsErrs = null;
            Excel.ListObject tblRecipient = null;
            Excel.ListObject tblSMInvoices = null;
            Excel.Range rngRecipientsInvRow = null;
            Excel.Range rng = null;
            Excel.Range rngSMInvoicesInvRow = null;

            List<dynamic> tblDelivery = null;
            List<dynamic> errList = null;
            string tempPDF = "";
            byte smco;
            string customer = "";
            string invoiceNumber = "";
            string workorders;
            string division = "";
            string servicesite = "";
            string fromEmail = "";
            string toEmail = "";
            string ccEmails = "";
            int sendFromCol = 1;
            int toEmailCol;
            int ccCol;
            int sentDateCol = 1;
            int invoicesEmailedCnt = 0;
            //int invoicesPrintedCnt = 0;
            bool markAsDelivered = false;

            btnDeliverInvoices.Tag = btnDeliverInvoices.Text;
            btnDeliverInvoices.Text = "Processing...";
            btnDeliverInvoices.Refresh();
            btnDeliverInvoices.Enabled = false;

            // PRINT
            Excel.Worksheet ws = null;

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

                var emailing = _tblRecipients.Where(n => (string)n.Bill.Value == "Y" && 
                                        
                                    ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Delivery Method"]).Value)).ContainsIgnoreCase("Emails")

                                    );

                if (emailing.Count() > 0)
                {
                    if (MessageBox.Show(null, "For each invoice, you will see an email window to allow edits before sending.\n" +
                                                "The invoice will be marked as Delivered whether you send it or not.\n\n" +
                                                "Would like to proceed ?", "Invoice Delivery", MessageBoxButtons.YesNo) == DialogResult.No)
                    {
                        return;
                    }
                }

                HelperUI.RenderOFF();

                oApp = new Outlook.Application();

                // Get 'SEND TO' email address ?
                wsRecipients = HelperUI.GetSheet("Recipients");

                if (wsRecipients != null)
                {
                    tblRecipient = wsRecipients.ListObjects[1];

                    sendFromCol = tblRecipient.ListColumns["Send From"].Index;
                    toEmailCol = tblRecipient.ListColumns["Bill Email"].Index;
                    ccCol = tblRecipient.ListColumns["Bill CC Email"].Index;
                    sentDateCol = tblRecipient.ListColumns["Sent Date"].Index;

                    foreach (var _inv in _tblRecipients)
                    {
                        // get invoice data
                        var invo = (IDictionary<string, object>)_inv;
                        var bill = (KeyValuePair<string, object>)invo["Bill"];

                        if ((string)bill.Value == "Y")
                        {
                            var deliverMethod = (KeyValuePair<string, object>)invo["Delivery Method"];

                            var co = (KeyValuePair<string, object>)invo["SMCo"];
                            var cust = (KeyValuePair<string, object>)invo["Customer"];
                            var inv = (KeyValuePair<string, object>)invo["Invoice Number"];
                            var wos = (KeyValuePair<string, object>)invo["Work Orders"];
                            var div = (KeyValuePair<string, object>)invo["Division"];
                            var site = (KeyValuePair<string, object>)invo["Service Site"];

                            smco = co.Value.GetType() == typeof(DBNull) ? byte.MinValue : Convert.ToByte(co.Value);
                            customer = cust.Value.GetType() == typeof(DBNull) ? string.Empty : cust.Value.ToString().Trim();
                            invoiceNumber = inv.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Value.ToString().Trim();
                            workorders = wos.Value.GetType() == typeof(DBNull) ? string.Empty : wos.Value.ToString();
                            division = div.Value.GetType() == typeof(DBNull) ? string.Empty : div.Value.ToString().Trim();
                            servicesite = site.Value.GetType() == typeof(DBNull) ? string.Empty : site.Value.ToString().Trim();

                            wsInvoice = HelperUI.GetSheet(invoiceNumber);

                            rngRecipientsInvRow = tblRecipient.ListColumns["Invoice Number"].DataBodyRange.Find(invoiceNumber, Type.Missing, Type.Missing,
                                                                        Excel.XlLookAt.xlWhole,
                                                                        Excel.XlSearchOrder.xlByRows,
                                                                        Excel.XlSearchDirection.xlNext,
                                                                        Type.Missing, Type.Missing, Type.Missing);
                            #region EMAIL

                            if (((string)deliverMethod.Value).ContainsIgnoreCase("Emails"))
                            {
                                if (rngRecipientsInvRow != null)
                                {
                                    fromEmail = ((string)wsRecipients.Cells[rngRecipientsInvRow.Row, sendFromCol].Formula).Trim();
                                    toEmail = ((string)wsRecipients.Cells[rngRecipientsInvRow.Row, toEmailCol].Formula).Trim();
                                    ccEmails = wsRecipients.Cells[rngRecipientsInvRow.Row, ccCol].Formula;
                                }
                                else
                                {
                                    errList = errList ?? new List<dynamic>();
                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    row.Add("Invoice", new KeyValuePair<string, object>(typeof(string).ToString(), invoiceNumber));
                                    row.Add("Email", new KeyValuePair<string, object>(typeof(string).ToString(), fromEmail));
                                    row.Add("Error", new KeyValuePair<string, object>(typeof(string).ToString(), "Unable to find Invoice: '" + invoiceNumber + "' on the Recipients tab"));

                                    errList.Add(row);
                                    continue;
                                }

                                // 'Bill Email' email address valid?
                                if (!RegEx.IsValidEmailAddress(toEmail))
                                {
                                    errList = errList ?? new List<dynamic>();
                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    // Column Name | data type | value
                                    row.Add("Invoice", new KeyValuePair<string, object>(typeof(string).ToString(), invoiceNumber));
                                    row.Add("Email", new KeyValuePair<string, object>(typeof(string).ToString(), toEmail));
                                    row.Add("Error", new KeyValuePair<string, object>(typeof(string).ToString(), "Invalid recipient's 'Bill Email'"));

                                    errList.Add(row);
                                    continue;
                                }

                                // valid 'SEND FROM' email address ? default if none
                                fromEmail = fromEmail == "" ? "Billing@Mckinstry.com" : fromEmail; // default if none
                                wsRecipients.Cells[rngRecipientsInvRow.Row, sendFromCol].Formula = fromEmail;

                                if (!RegEx.IsValidEmailAddress(fromEmail))
                                {
                                    errList = errList ?? new List<dynamic>();
                                    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;

                                    row.Add("Invoice", new KeyValuePair<string, object>(typeof(string).ToString(), invoiceNumber));
                                    row.Add("Email", new KeyValuePair<string, object>(typeof(string).ToString(), fromEmail));
                                    row.Add("Error", new KeyValuePair<string, object>(typeof(string).ToString(), "Invalid Send FROM email"));

                                    errList.Add(row);
                                }

                                if (wsInvoice != null && errList == null)
                                {
                                    tempPDF = IOexcel.GetWorksheetAsPDF(wsInvoice);

                                    if (File.Exists(tempPDF))
                                    {
                                        mail = oApp.CreateItem(Outlook.OlItemType.olMailItem) as Outlook.MailItem;
                                        mail.PropertyAccessor.SetProperty("http://schemas.microsoft.com/mapi/proptag/0x0065001E", fromEmail);
                                        mail.SentOnBehalfOfName = fromEmail;
                                        mail.To = toEmail;
                                        mail.CC = ccEmails;
                                        mail.Subject = "McKinstry Invoice #" + invoiceNumber + ", WO#" + workorders + ", " + division + " Services, " + servicesite;
                                        mail.Body = "Please see attached invoice for the recent service provided at your facility.";
                                        mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, Type.Missing, Type.Missing);
                                        mail.Display(false);
                                        //mail.Send();  // business wants to be able to edit subject line / body

                                        Application.UseWaitCursor = false;

                                        #region NEED MORE TIME PROMPT - UNUSED

                                        //needmoretime:
                                        //                                int timeoutNeedMoretime = 10000;
                                        //                                int waitForMilliseconds = 5000;

                                        //                                while (timeoutNeedMoretime != 0)
                                        //                                {
                                        //                                    System.Threading.Thread.Sleep(waitForMilliseconds);
                                        //                                    timeoutNeedMoretime -= waitForMilliseconds;

                                        //                                    if (timeoutNeedMoretime == 0)
                                        //                                    {
                                        //                                        if (MessageBox.Show(null, "Do you still need more time?", "Pending Send", MessageBoxButtons.YesNo) == DialogResult.Yes)
                                        //                                        {
                                        //                                            goto needmoretime;
                                        //                                        }
                                        //                                        else
                                        //                                        {
                                        //                                            break;
                                        //                                        }
                                        //                                    }
                                        //                                }
                                        #endregion

                                        File.Delete(tempPDF);
                                        markAsDelivered = true;
                                    }
                                }
                            }

                            #endregion

                            #region PRINT

                            //if (RegEx.ContainsWord(((string)deliverMethod.Value), "Mails"))
                            if (RegEx.ContainsWord(((string)deliverMethod.Value), "Mails"))
                            {
                                ws = HelperUI.GetSheet(invoiceNumber);

                                if (ws != null)
                                {
                                    //HelperUI.PrintPage_Setup(ws);
                                    ws.PrintOutEx(Preview: false);
                                    markAsDelivered = true;
                                }
                            }
                            #endregion

                            if (markAsDelivered)
                            {
                                tblDelivery = Delivery.DeliverInvoice(smco, invoiceNumber);

                                if (tblDelivery.Count > 0)
                                {
                                    // update 'Recipient' tab 
                                    var d = tblDelivery.FirstOrDefault();

                                    var sentDate = d.SentDate.Value.GetType() == typeof(DBNull) ? string.Empty : d.SentDate.Value.ToString().Trim();

                                    if (rngRecipientsInvRow != null)
                                    {
                                        wsRecipients.Cells[rngRecipientsInvRow.Row, sentDateCol].Formula = sentDate;
                                    }

                                    // update 'SM Invoices' tab 
                                    tblSMInvoices = _wsSMInvoices.ListObjects[1];

                                    rngSMInvoicesInvRow = tblSMInvoices.ListColumns["Invoice Number"].DataBodyRange.Find(invoiceNumber, Type.Missing, Type.Missing,
                                                                Excel.XlLookAt.xlWhole,
                                                                Excel.XlSearchOrder.xlByRows,
                                                                Excel.XlSearchDirection.xlNext,
                                                                Type.Missing, Type.Missing, Type.Missing);

                                    if (rngSMInvoicesInvRow != null)
                                    {
                                            sentDateCol = tblSMInvoices.ListColumns["Sent Date"].Index;
                                        var sentByCol   = tblSMInvoices.ListColumns["Sent By"].Index;
                                        var sentBy      = d.SentBy.Value.GetType() == typeof(DBNull) ? string.Empty : d.SentBy.Value.ToString().Trim();

                                        _wsSMInvoices.Cells[rngSMInvoicesInvRow.Row, sentDateCol].Formula = sentDate;
                                        _wsSMInvoices.Cells[rngSMInvoicesInvRow.Row, sentByCol].Formula = sentBy;
                                    }

                                    invoicesEmailedCnt++;
                                    markAsDelivered = false;
                                    wsInvoice.Tab.Color = HelperUI.GreenPastel;
                                }
                            }
                        }
                    }

                    if (errList?.Count > 0)
                    {
                        wsErrs = HelperUI.GetSheet("Send Errors");

                        HelperUI.AlertOff();

                        if (wsErrs != null) wsErrs.Delete();

                        HelperUI.AlertON();

                        // create error report
                        tblRecipient = HelperUI.CreateWorksheetWithTable(errList, "tblSendErrors", "Send Errors");
                        tblRecipient.Range.EntireColumn.AutoFit();

                        wsErrs = (Excel.Worksheet)tblRecipient.Parent;
                        wsErrs.Tab.Color = HelperUI.OrangePastel;

                        int rowTitle = tblRecipient.HeaderRowRange.Row - 1;
                        rng = wsErrs.get_Range("A" + rowTitle);
                        rng.Formula = "Failed to Send";
                        rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                        rng.Font.Bold = true;
                    }
                    else
                    {
                        wsErrs = HelperUI.GetSheet("Send Errors");

                        HelperUI.AlertOff();

                        if (wsErrs != null) wsErrs.Delete();

                        HelperUI.AlertON();
                    }

                    if (invoicesEmailedCnt > 0)
                    {
                        HelperUI.ShowInfo(msg: invoicesEmailedCnt + " invoice" + (invoicesEmailedCnt > 1 ? "s " : "") + " have been marked as DELIVERED.");
                    }

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

                btnDeliverInvoices.Text = (string)btnDeliverInvoices.Tag;
                btnDeliverInvoices.Refresh();
                btnDeliverInvoices.Enabled = true;

                #region CLEAN UP
                if (oApp != null) Marshal.ReleaseComObject(oApp);
                if (mail != null) Marshal.ReleaseComObject(mail);
                if (rngRecipientsInvRow != null) Marshal.ReleaseComObject(rngRecipientsInvRow);
                if (rngSMInvoicesInvRow != null) Marshal.ReleaseComObject(rngSMInvoicesInvRow);
                if (tblRecipient != null) Marshal.ReleaseComObject(tblRecipient);
                if (tblSMInvoices != null) Marshal.ReleaseComObject(tblSMInvoices);
                if (wsInvoice != null) Marshal.ReleaseComObject(wsInvoice);
                if (wsRecipients != null) Marshal.ReleaseComObject(wsRecipients);
                if (ws != null) Marshal.ReleaseComObject(ws);
                if (File.Exists(tempPDF)) File.Delete(tempPDF);
                #endregion
            }
        }

        private void btnReset_Click(object sender, EventArgs e)
        {
            //SMCo = 0x0;
            //cboCompany.SelectedIndex = -1;
            //cboCompany.DrawMode = DrawMode.OwnerDrawFixed;

            try
            {
                HelperUI.RenderOFF();
                HelperUI.AlertOff();

                HelperUI.DeleteLeftOverTabs();

                cboDivision.SelectedIndex = 0;
                cboServiceCenter.SelectedIndex = 0;
                txtBillToCustomer.Text = "";
                txtInvoiceStart.Text = "";
                txtInvoiceEnd.Text = "";
                rdoInvoiced.Checked = true;
                rdoNotDelivered.Checked = true;
                rdoTandMHideLaborRate.Checked = true;
            }
            catch (Exception) { throw; }
            finally
            {
                HelperUI.RenderON();
                HelperUI.AlertON();
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

            #region WORKING CODE BUT HIDDEN LEAVE FOR MAY BE LATER USAGE
            //DateTime dt;
            //string mth = "";
            //string day = "";
            //string yr = "";
            //string[] mthSplit = null;

            //// INVOICE START DATE
            //mth = txtInvoiceStartDate.Text.Replace("/", "").Trim();

            //if (mth != "")
            //{
            //    mthSplit = txtInvoiceStartDate.Text.Split('/');
            //    mth = mthSplit[0];
            //    day = mthSplit[1];
            //    yr = mthSplit[2];
            //    //string invoiceStartDate = string.Format("{0}/01/{1}", mth, yr);

            //    if (!DateTime.TryParse(mth + "/" + day + "/" + yr, out dt))
            //    {
            //        errorProvider1.SetIconAlignment(txtInvoiceStartDate, ErrorIconAlignment.MiddleLeft);
            //        errorProvider1.SetError(txtInvoiceStartDate, "Must be MM/YY format.");
            //        _invoiceStartDate = null;
            //        badField = true;
            //    }
            //    else
            //    {
            //        _invoiceStartDate = dt;
            //        errorProvider1.SetError(txtInvoiceStartDate, "");
            //    }
            //}

            //// INVOICE END DATE
            //mth = txtInvoiceEndDate.Text.Replace("/", "").Trim(); ;

            //if (mth != "")
            //{
            //    mthSplit = txtInvoiceEndDate.Text.Split('/');
            //    mth = mthSplit[0];
            //    day = mthSplit[1];
            //    yr = mthSplit[2];

            //    if (!DateTime.TryParse(mth + "/" + day  + "/" + yr, out dt))
            //    {
            //        errorProvider1.SetIconAlignment(txtInvoiceEndDate, ErrorIconAlignment.MiddleLeft);
            //        errorProvider1.SetError(txtInvoiceEndDate, "Must be MM/YY format.");
            //        _invoiceEndDate = null;
            //        badField = true;
            //    }
            //    else
            //    {
            //        _invoiceEndDate = dt; //.AddDays(DateTime.DaysInMonth(dt.Year, dt.Month) - 1);
            //        errorProvider1.SetError(txtInvoiceEndDate, "");
            //    }
            //}

            //// DELIVERY DATES ?
            //if (rdoInvoiced.Checked)
            //{
            //    // DELIVERY START DATE
            //    mth = txtDeliveryStartDate.Text.Replace("/", "").Trim(); ;

            //    if (mth != "")
            //    {
            //        mthSplit = txtDeliveryStartDate.Text.Split('/');
            //        mth = mthSplit[0];
            //        day = mthSplit[1];
            //        yr = mthSplit[2];

            //        if (!DateTime.TryParse(mth + "/" + day  + "/" + yr, out dt))
            //        {
            //            errorProvider1.SetIconAlignment(txtDeliveryStartDate, ErrorIconAlignment.MiddleLeft);
            //            errorProvider1.SetError(txtDeliveryStartDate, "Must be MM/YY format.");
            //            badField = true;
            //        }
            //        else
            //        {
            //            _deliveryStartDate = dt;
            //            errorProvider1.SetError(txtDeliveryStartDate, "");
            //        }
            //    }

            //    // DELIVERY END DATE
            //    mth = txtDeliveryEndDate.Text.Replace("/", "").Trim(); ;

            //    if (mth != "")
            //    {
            //        mthSplit = txtDeliveryEndDate.Text.Split('/');
            //        mth = mthSplit[0];
            //        day = mthSplit[1];
            //        yr = mthSplit[2];

            //        if (!DateTime.TryParse(mth + "/" + day  + "/" + yr, out dt))
            //        {
            //            errorProvider1.SetIconAlignment(txtDeliveryEndDate, ErrorIconAlignment.MiddleLeft);
            //            errorProvider1.SetError(txtDeliveryEndDate, "Must be MM/YY format.");
            //            badField = true;
            //        }
            //        else
            //        {
            //            _deliveryEndDate = dt.AddDays(DateTime.DaysInMonth(dt.Year, dt.Month) - 1);
            //            errorProvider1.SetError(txtDeliveryEndDate, "");
            //        }
            //    }
            //}
            //else
            //{
            //    _deliveryStartDate = null;
            //    _deliveryEndDate = null;
            //}

            #endregion

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

        private void cboDivision_SelectedIndexChanged(object sender, EventArgs e)
        {
            // update associated Service Centers combo box
            division = cboDivision.SelectedItem.ToString();

            if (division != "Any")
            {
                cboServiceCenter.DataSource = _divisionCenter.Where(n => n.Description == division).Select(x => x.ServiceCenterDescription).ToList();
            }
            else
            {
                // commented sort done on back-end
                cboServiceCenter.DataSource = _divisionCenter.GroupBy(n => n.ServiceCenterDescription).Distinct()/*.OrderBy(o => o.First().ServiceCenterDescription)*/.Select(x => x.First().ServiceCenterDescription).ToList();
            }

            //cboServiceSite.DataSource = SitesLookup.GetServiceSiteList(division);
            //if (cboServiceSite.Items.Count > 0) cboServiceSite.SelectedIndex = 0;
        }

        private void cboServiceCenter_SelectedIndexChanged(object sender, EventArgs e)
        {
            serviceCenter = cboServiceCenter.SelectedItem.ToString();

            if (serviceCenter != "Any" && division == "Any")
            {
                cboDivision.SelectedItem = _divisionCenter.Where(n => n.ServiceCenterDescription == serviceCenter)
                                                            .Select(x => x.Description).ToList().First();
            }

        }

        #region ALLOW ENTER KEY INVOKE GET INVOICES

        private delegate void dlgGetInvoices(KeyEventArgs e);

        private dlgGetInvoices _dlgInvokeGetInvoicesHndlr = new dlgGetInvoices(InvokeGetInvoicesHndlr);

        // allow enter key invoke GetInvoices
        private void ctrl_KeyUp(object sender, KeyEventArgs e)        => _dlgInvokeGetInvoicesHndlr(e);

        //// handles _dlgInvokeGetInvoicesHndlr
        private static void InvokeGetInvoicesHndlr(KeyEventArgs e) 
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.GetInvoiceDeliverySearch();
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

        /// <summary>
        /// handles cboTargetEnvironment with black background
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void cboTargetEnvironment_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        // handles all 3 radio buttons
        private void radioButton_CheckedChanged(object sender, EventArgs e) =>  SetInvoiceStatus();

        private void SetInvoiceStatus()
        {
            foreach (RadioButton r in grpStatus.Controls)
            {
                if (r.Checked)
                {
                    InvoiceStatus = r.Text.ToArray()[0];
                    break;
                }
            }

            if (rdoPending.Checked || rdoVoided.Checked)
            {
                grpDelivery.Enabled = false;
            }
            else
            {
                grpDelivery.Enabled = true;

                // when rdoPending.Checked and GetInvoiceDeliverySearch invoked, it sets PrintStatus to 0, we need to set back what Delivery was before invoke
                foreach (RadioButton r in grpDelivery.Controls)
                {
                    if (r.Checked)
                    {
                        //PrintStatus = r.Text.ToArray()[0];
                        if (r.Name == "rdoDeliveryAll")
                        {
                            rdoDeliveryAll_CheckedChanged(null, null);
                        }
                        else if (r.Name == "rdoDelivered")
                        {
                            rdoDelivered_CheckedChanged(null, null);
                        }
                        else if (r.Name == "rdoNotDelivered")
                        {
                            rdoNotDelivered_CheckedChanged(null, null);
                        }
                        break;
                    }
                }
            }
        }

        private void rdoDeliveryAll_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoInvoiced.Checked) PrintStatus = '\0';
        }

        private void rdoDelivered_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoInvoiced.Checked) PrintStatus = 'P';
        }

        private void rdoNotDelivered_CheckedChanged(object sender, EventArgs e)
        {
            if (rdoInvoiced.Checked) PrintStatus = 'N';
        }

        private void txtInvoiceStart_TextChanged(object sender, EventArgs e)
        {
            if (txtInvoiceStart.Text.Length > 0)
            {
                if (_textLengthIsZero) // if user presses the backspace to clear chars off, maintain last remembered checked radio button
                {
                    _lastCheckedButton = grpDelivery.Controls.IndexOf(grpDelivery.Controls.OfType<RadioButton>().FirstOrDefault(r => r.Checked));
                    rdoDeliveryAll.Checked = true;
                    _textLengthIsZero = false;
                }
            }
            else
            {
                ((RadioButton)grpDelivery.Controls[_lastCheckedButton]).Checked = _textLengthIsZero = true;
            }

            btnInputList.Enabled = txtInvoiceStart.Text.Length > 0 || txtInvoiceEnd.Text.Length > 0 ? false : true;
            txtInvoiceEnd.Text = txtInvoiceStart.Text;
        }

        private void txtInvoiceEnd_TextChanged(object sender, EventArgs e) => btnInputList.Enabled = txtInvoiceStart.Text.Length > 0 || txtInvoiceEnd.Text.Length > 0 ? false : true;

        private void txtBillToCustomer_TextChanged(object sender, EventArgs e)
        {

            if (Int32.TryParse(txtBillToCustomer.Text.Trim(), out int custId))
            {
                BillToCustomerID = custId;
            }
            else
            {
                BillToCustomerID = 0;
            }
        }

        private void btnInputList_Click(object sender, EventArgs e)
        {
            try
            {
                if (btnInputList.Text == "Open Input List")
                {
                    Globals.BaseSearch.Visible = Excel.XlSheetVisibility.xlSheetVisible;

                    HelperUI.DeleteSheet(Search_TabName);

                    // clone sheet from hidden template
                    Globals.BaseSearch.Copy(after: Globals.ThisWorkbook.Sheets["BaseSearch"]);
                    Globals.BaseSearch.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                    _wsInvoiceInputListSearch = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                    _wsInvoiceInputListSearch.Name = Search_TabName;

                    btnInputList.Text = "Close Input List";
                    grpInvoiceRange.Enabled = false;
                }
                else
                {
                    if (_wsSMInvoices?.Visible != Excel.XlSheetVisibility.xlSheetVisible)
                    {
                        // _wsSMInvoices is null or not visible
                        Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                    }
                    if (HelperUI.DeleteSheet(Search_TabName))
                        Marshal.ReleaseComObject(_wsInvoiceInputListSearch); _wsInvoiceInputListSearch = null;

                    btnInputList.Text = "Open Input List";
                    grpInvoiceRange.Enabled = true;
                }

            }
            catch (Exception)
            {

                throw;
            }

        }

        private void btnPreviewOrCopyOffline_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.btnPreview_or_CopyOffline_Click(sender, new EventArgs());
        }

        private void btnDeliverInvoices_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) Globals.ThisWorkbook._myActionPane.btnDeliverInvoices_Click(sender, new EventArgs());
        }

        #region SERVICE SITE F4 LOOKUP

        private void txtServiceSite_KeyDown(object sender, KeyEventArgs e)
        {
            //if (e.KeyCode == Keys.F4)
            //{
            //    ShowServiceSites();
            //}
        }

        //private void ShowServiceSites()
        //{
        //    Excel.ListObject xlTable = null;

        //    HelperUI.AlertOff();
        //    HelperUI.RenderOFF();
        //    List<dynamic> table = null;

        //    try
        //    {
        //        if (cboCompany.SelectedIndex == -1)
        //        {
        //            errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
        //            errorProvider1.SetError(cboCompany, "Select a Company");
        //        }

        //        SMCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

        //        table = SMServiceSites.GetServiceSites();

        //        if (table?.Count > 0)
        //        {
        //            if (Globals.ServiceSites.Visible != Excel.XlSheetVisibility.xlSheetVisible)
        //            {
        //                Globals.ServiceSites.Visible = Excel.XlSheetVisibility.xlSheetVisible;
        //            }

        //            Globals.ServiceSites.Activate();

        //            // re-create table if present
        //            if (Globals.ServiceSites.ListObjects.Count == 1)
        //            {
        //                Globals.ServiceSites.ListObjects[1].Delete();
        //            }

        //            xlTable = SheetBuilderDynamic.BuildTable(Globals.ServiceSites.InnerObject, table, "tblServiceSites", offsetFromLastUsedCell: 2, bandedRows: true, headerRow: 5);

        //            //xlTable.ListColumns["Customer"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
        //            //xlTable.ListColumns["State"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
        //            //xlTable.ListColumns["Zip"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
        //            //xlTable.ListColumns["Country"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
        //            //Globals.ServiceSites.get_Range("G:H").EntireColumn.AutoFit();

        //            HelperUI.MergeLabel(Globals.ServiceSites.InnerObject, xlTable.ListColumns[1].Name, xlTable.ListColumns[xlTable.ListColumns.Count].Name, "Service Sites", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

        //            Globals.ServiceSites.get_Range("A2").Activate();

        //        }
        //        else
        //        {
        //            if (Globals.ServiceSites.ListObjects.Count == 1) Globals.ServiceSites.ListObjects[1].DataBodyRange.Clear();
        //            HelperUI.ShowInfo(customErr: "No records found!");
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        HelperUI.ShowErr(ex);
        //    }
        //    finally
        //    {
        //        Application.UseWaitCursor = false;
        //        HelperUI.AlertON();
        //        HelperUI.RenderON();
        //    }
        //}

        #endregion

        #endregion

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
            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCompany, "Select a Company");
            }

            SMCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

            ShowARCustomers.BySortName(Status);
        }

        /// <summary>
        /// Toggle between active and All AR Customers
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
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
                RefreshDivisions();

                if (Globals.ThisWorkbook != null) Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = environ;
            }
            catch (Exception ex)  {
                HelperUI.ShowErr(ex);
            }
        }

        private void RefreshDivisions()
        {
            _divisionCenter = DivisionCenters.GetDivisionServiceCenters();

            if (_divisionCenter.Count > 0)
            {
                // fill Divisions in combobox
                cboDivision.DataSource = _divisionCenter.GroupBy(n => n.Description).Distinct().Select(x => x.First().Description).ToList();

                if (cboDivision.Items.Count > 0) cboDivision.SelectedIndex = 0;
            }
        }

        private void RefreshCompanies()
        {
            _tblCompanies = Companies.GetCompanyList();
            _companyDict = _tblCompanies.ToDictionary(n => n.HQCo, n => n.CompanyName);

            cboCompany.DataSource = _companyDict.Select(kv => kv.Value).ToList();

            if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;
        }

        private void rdoDetailTandM_CheckedChanged(object sender, EventArgs e) => detailTandMShowLaborRate = rdoTandMShowLaborRate.Checked ? false : true;
        private void rdoSumTandM_CheckedChanged(object sender, EventArgs e) => detailTandMShowLaborRate = rdoTandMHideLaborRate.Checked ? true : false;

        private void tmrAlertCell_Tick(object sender, EventArgs e)
        {
            try
            {
                if (blinkCounter <= 5)
                {
                    if (@switch == 0x0)
                    {
                        _sendFrom.Interior.Color = HelperUI.YellowLight;
                        blinkCounter++;
                        @switch = 0x1;
                        return;
                    }

                    _sendFrom.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                    blinkCounter++;
                    @switch = 0x0;
                }
                else
                {
                    tmrAlertCell.Enabled = false;
                    blinkCounter = 0;
                }
            }
            catch (Exception)
            {
                blinkCounter = 0;
                tmrAlertCell.Enabled = false;
            }
        }
    }
}