using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Windows.Forms;
//using Excel = Microsoft.Office.Tools.Excel; // using VSTO Add-in Template (New Project -> Office -> Excel template) 
using Excel = Microsoft.Office.Interop.Excel; // using Shared Add-in template (caters multiple Office applications)
//using Mckinstry.VSTO;
using McKinstry.Data.Viewpoint;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using McKinstry.Data.Viewpoint.JCDelete;
using System.Diagnostics;

//**********************************************Code Header Info***************************************************;
//                                                                                                                *;
//                                         McKinstry Projections                                                  *;
//                                                                                                                *;  
//                                        copyright McKinstry 2016                                                *;
//                                                                                                                *;
//    This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate detailed        *; 
//    cost and revenue projections within Vista by Viewpoint.  This software is the property of McKinstry and     *;
//    requires express written permission to be used by any Non-McKinstry employee or entity                      *;
//                                                                                                                *;
//    Release                      Date                     Details                                               *;
//    1.0 Initial Development      09/26/2016 and prior     Prototype Dev:      Bill Orebaugh                     *;
//                                                          Viewpoint/SQL Dev:  Jonathan Ziebell                  *;
//                                                          Project Manager:    Sarah Cantwell                    *;
//                                                          Excel VSTO Dev:     Leo Gurdian                       *;
//                                                          Viewpoint/WIP Dev:  Arun Thomas                       *;
//                                                                                                                *;
//    1.1 Emergency Fix            09/26/2016               Emergency Fix to disable Insert Row on other Panels   *;
//                                                                                                                *;
//    1.2 Small Change Release     10/01/2016               Speed up Rev Posting and Copy Cost Offline Button     *;
//                                                                                                                *;
//    1.3 Emergency Fix            10/05/2016               Contract Report not updating after Rev Post           *;
//                                                                                                                *;
//    1.4 WIP Release              10/15/2016               GMAX Worksheet, Graph, Weeks in Month Comment, etx.   *;
//                                                                                                                *;
//    1.0.5 Small Changes          10/26/2016               Copy ETC Offiline Fix, Proj Nbr Fix, No hide/del tabs *;
//                                                                                                                *;
//*****************************************************************************************************************;

namespace McKinstry.ETC.Template
{
    partial class ETCOverviewActionPane : UserControl
    {

        // Set global variables for accessibility to various sheets and data components

        //Data tables containing fetched Viewpoint Data 
        public DataTable vista_user = new DataTable();
        public DataTable jccm_table = new DataTable();
        public DataTable jcci_table = new DataTable();
        public DataTable jcjm_table = new DataTable();

        public DataTable contractheader_table = new DataTable();
        public DataTable contractlist_table = new DataTable();
        public DataTable contractjobs_table = new DataTable();
        public DataTable contractPRG_table = new DataTable();
        public DataTable contractPRGPivot_table = new DataTable();
        public DataTable contJectNonLabor_table = new DataTable();
        public DataTable contJobJectNonLabor_table = new DataTable();
        public DataTable contJobHeaderDtl_table = new DataTable();
        public DataTable contJobCTSum_table = new DataTable();
        public DataTable contJobParentPhaseSum_table = new DataTable();
        public DataTable contJobJectBatchSum_table = new DataTable();
        public DataTable contJobJectBatchNonLabor_table = new DataTable();
        public DataTable contJobJectBatchLabor_table = new DataTable();
        public List<DataTable> contractjobphases_table = new List<DataTable>();
        public DataTable contJectRevenue_table = new DataTable();

        public Excel.Worksheet _control_ws; // "Control" worksheet for persistent storage of selected items and general overview of execution context/
        public Excel.Worksheet _ws = null;
        public Excel.ListObject _table = null;
        //public Excel.Shape cmdButton;
        //public Microsoft.Vbe.Interop.Forms.CommandButton CmdBtn;

        public Excel.Range LaborEmpDescEdit { get; set; }
        public Excel.Range LaborMonthsEdit { get; set; }
        public Excel.Range LaborRateEdit { get; set; }
        public byte _offsetFromPhseActRate = 0x4;

        public Excel.Range NonLaborWritable1 { get; set; }
        public Excel.Range NonLaborWritable2 { get; set; }
        public byte _offsetFromRemCost = 0x2;

        public Excel.Range CostSumWritable { get; set; }

        public Excel.Range RevWritable1 { get; set; }
        public Excel.Range RevWritable2 { get; set; }

        public bool isRendering;
        private bool isInserting;
        private bool alreadyPrompted;
        //public bool undoing;

        public const string laborSheet =  "Labor-";
        public const string nonLaborSheet = "NonLabor-";
        public const string costSumSheet = "CostSum-";
        public const string revSheet = "Rev-";
        public const string revCurve = "Projected Curve";
        public const string pwd = "prophecy";

        private string lastContractNoDash = "";
        public string lastJobSearched = "";
        public DateTime lastCostProjectedMonth;
        public DateTime lastRevProjectedMonth;

        private byte _jcco;

        //setting JCCo also sets cboMonth with corresponding months
        public byte JCCo
        {
            get { return _jcco; }
            set
            {
                // only display valid months
                cboMonth.SuspendLayout();
                cboMonth.Enabled = true;
                cboMonth.DataSource = HelperData.GetValidMonths(value);
                if (cboMonth.Items.Count > 0)
                {
                    // get current month and if is in list then make default
                    int index = cboMonth.FindString(DateTime.Today.ToString("MM/yyyy"));
                    if (index != -1)
                    {
                        cboMonth.SelectedIndex = index;
                        cboMonth.SelectedItem = cboMonth.SelectedValue;
                        Month = (DateTime)cboMonth.SelectedItem;
                    }
                    else {
                        // selection defaults to latest month
                        cboMonth.SelectedIndex = cboMonth.Items.Count - 1;
                        cboMonth.SelectedItem = cboMonth.SelectedValue;
                        Month = (DateTime)cboMonth.SelectedItem;
                    }
                }
                cboMonth.ResumeLayout();
                _jcco = value;
            }
        }

        public string Login
        {
            get
            {
                return (from DataRow dr in vista_user.Rows select (string)dr["VPUserName"]).FirstOrDefault();
            }
        }

        public string Contract { get; set; }

        public string Job { get; set; }

        public string Pivot { get; set; }

        public string LaborPivot { get; set; }

        public DateTime Month { get; set; }

        public DateTime costBatchDateCreated;
        public DateTime revBatchDateCreated;

        private uint revBatchId;
        public uint RevBatchId
        {
            get
            {
                return revBatchId;
            }
            set
            {
                revBatchId = value;
                _control_ws.Names.Item("RevBatchId").RefersToRange.Value = value != 0 ? value : (object)"" ;
                _control_ws.Names.Item("RevJectMonth").RefersToRange.Value = value != 0 ? string.Format("{0:M/yyyy}", Month.Date) : (object)"";
            }
        }

        private uint costBatchId;
        public uint CostBatchId
        {
            get
            {
                return costBatchId;
            }
            set
            {
                costBatchId = value;
                _control_ws.Names.Item("CostBatchId").RefersToRange.Value = value != 0 ? value : (object)"";
                _control_ws.Names.Item("CostJectMonth").RefersToRange.Value = value != 0 ? string.Format("{0:M/yyyy}", Month.Date) : (object)"";
            }
        }

        //public Microsoft.Vbe.Interop.VBComponent undoMod;

        public static Excel.Workbook workbook
        {
            get { return Globals.ThisWorkbook.Worksheets.Parent; }
        }

        public ETCOverviewActionPane()
        {
            InitializeComponent();
            
            // Get contract list and setup autocomplete feature
            this.txtBoxContract.AutoCompleteSource = AutoCompleteSource.CustomSource;
            this.txtBoxContract.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
            AutoCompleteStringCollection collection = new AutoCompleteStringCollection();

            string[] list = FetchContractList();
            collection.AddRange(list);

            this.txtBoxContract.AutoCompleteCustomSource = collection;

            cboMonth.Enabled = false;
            cboMonth.FormatString = "MM/yyyy";
            cboMonth.Visible = false;
            btnPostCost.Location = new System.Drawing.Point(8, 333);
            btnPostRev.Location = new System.Drawing.Point(8, 333);
            btnGMAX.Location = new System.Drawing.Point(8, 333);
            btnProjectedRevCurve.Location = new System.Drawing.Point(8, 333);
            btnCopyDetailOffline.Location = new System.Drawing.Point(8, 407);
            //btnPOReport.Location = new System.Drawing.Point(8, 477);
            //HelperUI.Hide_RDP_BlackBox();
            //if (System.Windows.Forms.SystemInformation.TerminalServerSession) HelperUI.Hide_RDP_BlackBox();
        }

        private void btnFetchData_Click(object sender, EventArgs e)
        {
            if (isRendering) return; // let it finish rendering before a refresh
            btnFetchData.Enabled = false;
            string btnOrigText = btnFetchData.Text;
            bool failed = false;

            Application.UseWaitCursor = true;
            try
            {
                if (btnFetchData.Text.Contains("Get Contract"))
                {
                    if (!IsValidContract()) return;

                    btnFetchData.Text = "Processing...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);
                    try
                    {
                        if (ClearWorkbook_SavePrompt())
                        {
                            RenderOFF();
                            BuildReports();
                            if (HelperUI.IsTextPosNumeric(workbook.ActiveSheet.Name))
                            {
                                btnFetchData.Text = "Generate Revenue Projection";
                            }
                            else
                            {
                                btnFetchData.Text = "&Get Contract && Projects";
                            }
                            _control_ws.Names.Item("ContractNumber").RefersToRange.Value = txtBoxContract.Text;
                            _control_ws.Names.Item("ContractName").RefersToRange.Value = JobGetTitle.GetTitle(JCCo, txtBoxContract.Text);
                            _control_ws.Names.Item("ContractName").RefersToRange.EntireColumn.AutoFit();
                            alreadyPrompted = false;
                        }
                        else {
                            btnFetchData.Text = btnOrigText;
                            btnFetchData.Refresh();
                            btnFetchData.Enabled = true;
                        }
                    }
                    catch (Exception ex) { ReportErrOut(ex); }
                    finally
                    {
                        RenderON();
                        Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                    }
                }
                else if (btnFetchData.Text.Equals("Generate Revenue Projection"))
                {
                    btnFetchData.Text = "Generating Projection...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);
                    Globals.ThisWorkbook.SheetSelectionChange -= new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);

                    if (GenerateRevenueProjections())
                    {
                        btnFetchData.Text = "Save Projections to Viewpoint";
                        btnFetchData.Visible = true;
                        btnFetchData.Enabled = false;
                        btnPostRev.Visible = true;
                        cboMonth.Enabled = false;
                        lastRevProjectedMonth = Month;
                        SendKeys.Send("%");
                        SendKeys.SendWait("{ESC}");
                    }
                    else {  failed = true; }
                }
                else if (btnFetchData.Text.Equals("Generate Cost Projection"))
                {
                    btnFetchData.Text = "Generating Projection...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);
                    Globals.ThisWorkbook.SheetSelectionChange -= new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
                    if (GenerateCostProjections())
                    {
                        btnFetchData.Text = "Save Projections to Viewpoint";
                        btnFetchData.Enabled = false;
                        cboMonth.Enabled = false;
                        btnCopyDetailOffline.Visible = true;
                        btnCopyDetailOffline.Tag = copyCostDetailsOffline;
                        lastCostProjectedMonth = Month;
                        //btnPOReport.Visible = true;
                        SendKeys.Send("%");
                        SendKeys.SendWait("{ESC}");
                    }
                    else { failed = true; }
                } 
                else if (btnFetchData.Text.Equals("Save Projections to Viewpoint"))
                {
                    btnFetchData.Text = "Saving to Viewpoint...";
                    btnFetchData.Refresh();
                    if (workbook.ActiveSheet.Name.Contains(costSumSheet))
                    {
                        InsertCostProjectionsIntoJCPD();
                    }
                    else if (workbook.ActiveSheet.Name.Contains(revSheet))
                    {
                        UpdateJCIRwithSumData();
                    }
                }
            }
            catch (Exception ex)
            {
                failed = true;
                MessageBox.Show(ex.Message);
            }
            finally
            {
                isInserting = false;
                isRendering = false;
                Application.UseWaitCursor = false;
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
            }

            if (failed)
            {
                btnFetchData.Text = btnOrigText;
                btnFetchData.Enabled = true;
                btnFetchData.Refresh();
            }
            //workbook.Application.ActiveWindow.TabRatio = 0.77;
            //var splashWindow = new SplashWindow();
            //splashWindow.Show();
            //splashWindow.SetMessage("Starting please wait...");
            //DoSomeWork(splashWindow);
            //splashWindow.Close();
        }

        private void ReportErrOut(Exception ex)
        {
            LogProphecyAction.InsProphecyLog(Login, 1, JCCo, Contract, Job, ErrorTxt: getErrTraceProd(ex), 
                              Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
            ErrOut(ex);
            btnFetchData.Text = "&Get Contract && Projects";
            btnFetchData.Refresh();

            workbook.Application.DisplayAlerts = false;
            foreach (Excel.Worksheet _ws in workbook.Worksheets)
            {
                if (!_ws.Name.Contains("GMAX") && _ws.Name != "Control")
                {
                    _ws.Delete();
                }
            }
            workbook.Application.DisplayAlerts = true;

            Globals.GMAX.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

            RevBatchId = 0;
            CostBatchId = 0;
            Globals.ThisWorkbook.isRevDirty = null;
            Globals.ThisWorkbook.isCostDirty = null;
            ClearControlSheet();
        }


        #region BUILD REPORTS

        private void BuildReports()
        {
            isRendering = true;
            try
            {
                //Get user information for logged in user for Contract context.
                vista_user = UserProfile.GetUserProfile(JCCo, null);
                ControlSheetBuilder.BuildUserProfile(workbook, vista_user);

                //Stopwatch t2 = new Stopwatch(); t2.Start();
                lastContractNoDash = Contract.Replace("-", "");
                BuildContractSheet();

                if (cboJobs.Text == "All Projects" || cboJobs.Text == "" || !cboJobs.Text.Contains(lastContractNoDash))
                {
                    Job = null;
                }
                else
                {
                    Job = cboJobs.Text;
                }

                BuildProjectSheets(Job);
                //t2.Stop(); MessageBox.Show(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", t2.Elapsed.ToString()));

                DisableGridlines(null);

                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, Contract);

                Globals.ThisWorkbook.isRevDirty = null;
                Globals.ThisWorkbook.isRevDirty = null;
                lastJobSearched = Job;
                cboJobs.Text = "";
            }
            catch (Exception) { throw; }
            finally
            {
                isRendering = false;
            }
        }

        private void BuildContractSheet()
        {
            Excel.Range rng = null;
            Excel.Worksheet after = null;
            Excel.ListObject PRGSum = null;

            Excel.Range periods = null;
            Excel.ListObject PRGPivot = null;
            Excel.Range RevHeaders = null;
            Excel.ListColumn SumCol = null;
            Excel.Range RevStartCell = null;
            Excel.Range RevEndCell = null;

            try
            {
                _ws = HelperUI.GetSheet(lastContractNoDash, false);

                if (_ws != null)
                {
                    after = _ws.Previous;
                    workbook.Application.DisplayAlerts = false;
                        _ws.Delete();
                    workbook.Application.DisplayAlerts = true;
                    _ws = HelperUI.AddSheet(lastContractNoDash, after);
                }
                else
                {
                    _ws = HelperUI.AddSheet(lastContractNoDash, _control_ws);
                }

                _ws.Cells.Locked = false;
                _ws.Unprotect();

                //Get Contract Items for specified Contract
                contractPRG_table = ContractPRG.GetContractPRGTable(JCCo, Contract);
                SheetBuilder.BuildGenericTable(_ws, contractPRG_table);

                _control_ws.Names.Item("ContractNumber").RefersToRange.Value = Contract;

                // ContractPRG table
                rng = _ws.Cells.Range["A1:S1"];
                rng.Merge();
                rng.Value = "CONTRACT OVERVIEW: " + Contract + " " + JobGetTitle.GetTitle(JCCo, Contract).Replace(" - " + Contract, "");
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                PRGSum = _ws.ListObjects[1];
                PRGSum.HeaderRowRange.EntireRow.RowHeight = 30.00;
                PRGSum.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                string[] noSummation = { "Original Margin", "Current Margin", "Last Month Margin", "Projected Margin %", "Margin Variance" };

                foreach (string colName in noSummation)
                {
                    PRGSum.ListColumns[colName].DataBodyRange.Columns.NumberFormat = HelperUI.PercentFormat;
                    PRGSum.ListColumns[colName].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                }

                rng = _ws.Cells[PRGSum.TotalsRowRange.Row, rng.Column];
                rng.Font.Color = HelperUI.NavyBlueTotalRowColor;

                PRGSum.ListColumns["JC Dept"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                PRGSum.ListColumns["Margin Variance"].DataBodyRange.FormulaLocal = "=[@[Projected Margin %]]-[@[Last Month Margin]]";

                rng = _ws.Cells[PRGSum.TotalsRowRange.Row, PRGSum.ListColumns["Projected Margin %"].Index];
                rng.NumberFormat = HelperUI.PercentFormat;
                rng.FormulaLocal = "=IF((SUBTOTAL(109,[Projected Contract]))=0,\"0\",(SUBTOTAL(109,[Projected Margin $])/SUBTOTAL(109,[Projected Contract])))";
                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                _ws.Cells[PRGSum.HeaderRowRange.Row - 1, 1].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown); // head title
                HelperUI.AddFieldDesc(_ws, "PRG", "Project Revenue Group (Project Number) line item on the WIP");
                HelperUI.AddFieldDesc(_ws, "PRG Description", "Project Description");
                HelperUI.AddFieldDesc(_ws, "JC Dept", "Job cost department number");
                HelperUI.AddFieldDesc(_ws, "JC Dept Description", "Job cost department description");
                HelperUI.AddFieldDesc(_ws, "Projected Cost", "Sum of cost projected in last posted cost batch(s)");
                HelperUI.AddFieldDesc(_ws, "Original Contract", "Original contract value (first interface)");
                HelperUI.AddFieldDesc(_ws, "Current Contract", "Current Contract Value (original contract + interfaced change orders)");
                HelperUI.AddFieldDesc(_ws, "Projected Contract", "PM estimate of final contract value on last posted revenue batch");
                HelperUI.AddFieldDesc(_ws, "Unbooked Contract Adjustments", "Delta between projected contract value and current contract value (needed change orders)");
                HelperUI.AddFieldDesc(_ws, "Future CO", "Change orders pending in the system (not yet interfaced)");
                HelperUI.AddFieldDesc(_ws, "Last Month Earned Revenue", "PRG Revenue earned through last calendar month");
                HelperUI.AddFieldDesc(_ws, "Billed to Date", "Amount billed to date (From current WIP)");
                HelperUI.AddFieldDesc(_ws, "Estimated Over/(Under) Billed", "JTD Billing less JTD Earned Revenue (From current WIP)");
                HelperUI.AddFieldDesc(_ws, "Original Margin", "Original contract value compared to original estimated cost");
                HelperUI.AddFieldDesc(_ws, "Current Margin", "Current contract value to current cost");
                HelperUI.AddFieldDesc(_ws, "Last Month Margin", "Margin at end of last calendar month");
                HelperUI.AddFieldDesc(_ws, "Projected Margin $", "Projected margin dollars based on most recent cost and revenue projections that have been posted");
                HelperUI.AddFieldDesc(_ws, "Projected Margin %", "Projected margin percentage based on most recent cost and revenue projections that have been posted");
                HelperUI.AddFieldDesc(_ws, "Margin Variance", "Change in margin since the end of the last calendar month");

                HelperUI.MergeLabel(_ws, "PRG", "JC Dept Description", "Details");
                HelperUI.MergeLabel(_ws, "Projected Cost", "Projected Cost", "Cost");
                HelperUI.MergeLabel(_ws, "Original Contract", "Projected Contract", "Contract");
                HelperUI.MergeLabel(_ws, "Unbooked Contract Adjustments", "Future CO", "Changes");
                HelperUI.MergeLabel(_ws, "Last Month Earned Revenue", "Last Month Earned Revenue", "Earned Revenue");
                HelperUI.MergeLabel(_ws, "Billed to Date", "Estimated Over/(Under) Billed", "Billing");
                HelperUI.MergeLabel(_ws, "Original Margin", "Margin Variance", "Margin");

                _ws.Cells[PRGSum.HeaderRowRange.Row - 1, 1].EntireRow.Group();
                _ws.Cells[PRGSum.HeaderRowRange.Row - 1, 1].EntireRow.Hidden = true;

                PRGSum.ListColumns["PRG"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["PRG Description"].DataBodyRange.ColumnWidth = 20.00;
                PRGSum.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 8.00;
                PRGSum.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 25.00;
                PRGSum.ListColumns["Projected Cost"].DataBodyRange.ColumnWidth = 16.75;
                PRGSum.ListColumns["Original Contract"].DataBodyRange.ColumnWidth = 15.75;
                PRGSum.ListColumns["Current Contract"].DataBodyRange.ColumnWidth = 15.75;
                PRGSum.ListColumns["Projected Contract"].DataBodyRange.ColumnWidth = 20.00;
                //PRGSum.ListColumns["Unbooked Contract Adjustments"].DataBodyRange.ColumnWidth = 15.75;
                //PRGSum.ListColumns["Future CO"].DataBodyRange.ColumnWidth = 14.75;
                //PRGSum.ListColumns["Last Month Earned Revenue"].DataBodyRange.ColumnWidth = 15.57;
                //PRGSum.ListColumns["Billed to Date"].DataBodyRange.ColumnWidth = 15.75;
                //PRGSum.ListColumns["Estimated Over/(Under) Billed"].DataBodyRange.ColumnWidth = 18.00;
                PRGSum.ListColumns["Original Margin"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["Current Margin"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["Last Month Margin"].DataBodyRange.ColumnWidth = 9.00;
                //PRGSum.ListColumns["Projected Margin $"].DataBodyRange.ColumnWidth = 16.86;
                PRGSum.ListColumns["Projected Margin %"].DataBodyRange.ColumnWidth = 16;
                PRGSum.ListColumns["Margin Variance"].DataBodyRange.ColumnWidth = 16;

                PRGSum.ListColumns["Last Month Earned Revenue"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                PRGSum.ListColumns["Billed to Date"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                PRGSum.ListColumns["Estimated Over/(Under) Billed"].DataBodyRange.Style = HelperUI.CurrencyStyle;

                //HelperUI.GroupColumns(_ws, "Projected Cost", "Current Contract");
                //HelperUI.GroupColumns(_ws, "Unbooked Contract Adjustments", "Billed to Date");
                //HelperUI.GroupColumns(_ws, "Original Margin", "Last Month Margin");


                contractPRGPivot_table = ContractPRGPivot.GetContractPRGPivotTable(JCCo, Contract);
                SheetBuilder.BuildGenericTable(_ws, contractPRGPivot_table);

                // ContractPRGPivot Table below 
                PRGPivot = _ws.ListObjects[2];
                RevHeaders = PRGPivot.HeaderRowRange;
                SumCol = PRGPivot.ListColumns["Remaining at Margin"];
                RevStartCell = null;
                RevEndCell = null;

                _ws.Cells[PRGPivot.HeaderRowRange.Row - 1, 1].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown); // head title
                _ws.Cells[PRGPivot.HeaderRowRange.Row - 1, 1].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                rng = _ws.Cells[RevHeaders.Row - 3, 1];
                rng.Merge();
                rng.Value = "Projected Future Revenue";
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                byte RevdataEntryAreaOffset = 0x1;
                int periodStart = PRGPivot.ListColumns["Current Month Catch Up"].Index + RevdataEntryAreaOffset;

                RevStartCell = _ws.Cells[RevHeaders.Row, periodStart];
                RevEndCell = _ws.Cells[RevHeaders.Row, RevHeaders.Columns.Count];

                SumCol.DataBodyRange.FormulaLocal = "=SUM(" + PRGPivot.Name + "[@[" + RevStartCell.Formula + "]:[" + RevEndCell.Formula + "]])";
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.FormulaLocal = "=[@[Calculated Remaining Revenue]]-[@[Remaining at Margin]]";
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.FormulaLocal = "=[@[Margin Change Catch Up]]+[@[" + RevStartCell.Formula + "]]";
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.EntireColumn.ColumnWidth = 13;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.EntireColumn.ColumnWidth = 10;
                PRGPivot.ListColumns["Calculated Remaining Revenue"].DataBodyRange.EntireColumn.ColumnWidth = 13;

                HelperUI.AddFieldDesc(_ws, "PRG", "Project Revenue Group (Project Number)", tableId:2);
                HelperUI.AddFieldDesc(_ws, "PRG Description", "Project Description", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "JC Dept", "Job cost department number", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "JC Dept Description", "Job cost department description", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "Calculated Remaining Revenue", "Projected contract value less revenue earned through prior month", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "Remaining at Margin", "Remaining revenue to be earned assuming margin did not change", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "Margin Change Catch Up", "If margin change, calculates the net current margin hit", tableId: 2);
                HelperUI.AddFieldDesc(_ws, "Current Month Catch Up", "If margin change, calculates Margin catch up + monthly revenue", tableId: 2);

                HelperUI.MergeLabel(_ws, "PRG", "Current Month Catch Up", "Current Month Catch Up",2);
                HelperUI.MergeLabel(_ws, RevStartCell.Text, PRGPivot.ListColumns[RevEndCell.Column].Name, "Remaining Monthly Revenue",2);

                periods = _ws.Range[_ws.Cells[RevHeaders.Row - 1, RevStartCell.Column], _ws.Cells[RevHeaders.Row - 1, RevEndCell.Column]];
                periods.Merge();
                periods.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                periods.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                periods.Value = "Projected revenue by month based on cost estimate and margin";

                periods.EntireColumn.ColumnWidth = 13;
                PRGPivot.ListColumns["Calculated Remaining Revenue"].DataBodyRange.ColumnWidth = 16;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.ColumnWidth = 16;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.ColumnWidth = 16;
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.ColumnWidth = 16;

                PRGSum.ListColumns["Estimated Over/(Under) Billed"].DataBodyRange.ColumnWidth = 16;
                PRGSum.ListColumns["Projected Margin $"].DataBodyRange.ColumnWidth = 16;

                PRGSum.ListColumns["Unbooked Contract Adjustments"].DataBodyRange.ColumnWidth = 16;
                PRGSum.ListColumns["Last Month Earned Revenue"].DataBodyRange.ColumnWidth = 16;
                PRGSum.ListColumns["Billed to Date"].DataBodyRange.ColumnWidth = 16;

                RevHeaders.EntireRow.RowHeight = 30.00;
                RevHeaders.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                _ws.Cells[RevHeaders.Row - 1, 1].EntireRow.Group();
                _ws.Cells[RevHeaders.Row - 1, 1].EntireRow.Hidden = true;

                _ws.Range[_ws.Cells[RevHeaders.Row - 2, 1], _ws.Cells[PRGPivot.TotalsRowRange.Row, 1]].EntireRow.Group();
                _ws.Range[_ws.Cells[RevHeaders.Row - 2, 1], _ws.Cells[PRGPivot.TotalsRowRange.Row, 1]].EntireRow.Hidden = true;
                HelperUI.GroupColumns(_ws, "Projected Cost", "Current Contract");
                HelperUI.GroupColumns(_ws, "Unbooked Contract Adjustments", "Billed to Date");
                HelperUI.GroupColumns(_ws, "Original Margin", "Last Month Margin");

                HelperUI.PrintPageSetup(_ws);

                _ws.UsedRange.Locked = true;
                PRGPivot.TotalsRowRange.Locked = false;
                PRGSum.TotalsRowRange.Locked = false;
                HelperUI.ProtectSheet(_ws, false, false);

                DisableGridlines(_ws);
                _ws.Range["A1"].Activate();
            }
            catch (Exception) { throw; }
            finally
            {
                if (after != null) Marshal.ReleaseComObject(after);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (PRGSum != null) Marshal.ReleaseComObject(PRGSum);
                //------------------------------------------------------
                if (SumCol != null) Marshal.ReleaseComObject(SumCol);
                if (RevStartCell != null) Marshal.ReleaseComObject(RevStartCell);
                if (RevEndCell != null) Marshal.ReleaseComObject(RevEndCell);
                if (PRGPivot != null) Marshal.ReleaseComObject(PRGPivot);
                if (RevHeaders != null) Marshal.ReleaseComObject(RevHeaders);
                if (periods != null) Marshal.ReleaseComObject(periods);
            }
        }
         
        private void BuildProjectSheets(string jobId = null, bool refresh = false)
        {
            Excel.Range rng = null;
            Excel.Worksheet after = null;
            Pivot = "MONTH";
            int rowNum = 19;
            int colNum = 1;
            uint rn = 0;

            //Get associated jobs for specified Contract
            contractjobs_table = ContractJobs.GetContractJobTable(JCCo, Contract, jobId);

            foreach (DataRow dr in contractjobs_table.Rows)
            {
                string job = dr.Field<string>("Job");
                string _pn = HelperUI.JobTrimDash(job);

                if (!refresh)
                {
                    _control_ws.Cells[rowNum, colNum].Value = job;
                    _control_ws.Cells[rowNum, colNum + 1].Value = dr.Field<string>("JobDesc");
                    _control_ws.Names.Add("_" + _pn, _control_ws.Cells[rowNum, colNum]);
                    _control_ws.Names.Add("_" + _pn + "Desc", _control_ws.Cells[rowNum, colNum + 1]);
                    _control_ws.Names.Add("LastSave" + _pn, _control_ws.Cells[rowNum, colNum + 2]);
                    _control_ws.Names.Add("LastPost" + _pn, _control_ws.Cells[rowNum, colNum + 3]);
                    _control_ws.Names.Add("JobUserName" + _pn, _control_ws.Cells[rowNum, colNum + 4]);
                    ++rowNum;
                }

                _ws = HelperUI.GetSheet("-" + _pn);

                if (_ws == null)
                {
                    _ws = HelperUI.AddSheet("-" + _pn, Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                    if (_ws == null)
                    {
                        MessageBox.Show("BuildProjectSheets: Something went wrong building project worksheet: " + _pn + "\nSkipping..");
                        continue;
                    }
                }
                else
                {
                    after = _ws.Previous;
                    workbook.Application.DisplayAlerts = false;
                        _ws.Delete();
                    workbook.Application.DisplayAlerts = true;
                    _ws = HelperUI.AddSheet("-" + _pn, after);
                    // HelperUI.CleanSheet(_ws);  ditching this more efficient method due to Excel v.15 grouping outlines don't refresh correctly (MS BUG fixed in Excel. v.16) LeoG
                }

                _ws.Cells.Locked = false;

                contJobHeaderDtl_table = JobHeader.GetJobHeaderTable(JCCo, job);

                _ws.Cells.Range["A1"].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = _ws.Cells.Range["A1:H1"];
                rng.Merge();
                rng.Value = "PROJECT OVERVIEW: " + job + "_" + dr.Field<string>("JobDesc");
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                int offset = 4;
                int count = contJobHeaderDtl_table.Columns.Count / 2;

                for (int i = 1; i <= count; i++)
                {
                    rng = _ws.Cells[offset + i - 1, 1];
                    rng.Value = contJobHeaderDtl_table.Columns[i - 1].ColumnName;
                    rng.Font.Name = "Calibri Light";
                    rng.Font.Bold = true;
                    rng.Font.Italic = true;
                    _ws.Names.Add(rng.Value.Replace(" ", "").Replace("%", "Percent"), _ws.Cells[offset + i - 1, 2]);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                }

                for (int i = count; i <= contJobHeaderDtl_table.Columns.Count - 1; i++)
                {
                    rng = _ws.Cells[i - count + offset, 3];
                    rng.Value = contJobHeaderDtl_table.Columns[i].ColumnName;
                    rng.Font.Name = "Calibri Light";
                    rng.Font.Bold = true;
                    rng.Font.Italic = true;
                    _ws.Names.Add(rng.Value.Replace(" ", "").Replace("%", "Percent"), _ws.Cells[i - count + offset, 4]);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                }

                foreach (Excel.Name namedRange in _ws.Names)
                {
                    _ws.Names.Item(namedRange.Name).RefersToRange.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    _ws.Names.Item(namedRange.Name).RefersToRange.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;

                    if (namedRange.Name.Contains("Value") || namedRange.Name.Contains("Cost"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.Style = HelperUI.CurrencyStyle;
                        continue;
                    }
                    if (namedRange.Name.Contains("JCDepartment"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.StringFormat;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        continue;
                    }
                    if (namedRange.Name.Contains("Percent"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.PercentFormat;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                        continue;
                    }
                    if (namedRange.Name.Contains("Date"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.DateFormatMMDDYYYY;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    }
                    if (namedRange.Name.Contains("Through"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.DateFormatMMDDYYYY;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    }
                }

                _ws.Names.Item("LastProjection").RefersToRange.NumberFormat = HelperUI.DateFormatMDYYhmmAMPM;
                _ws.Names.Item("Projectionby").RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                _ws.Names.Item("ContractPOC").RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                _ws.Names.Item("PayrollThrough").RefersToRange.AddComment("Standard payroll has been applied through this week ending date.  (terminations, transfers, etc. may follow a different schedule)");
                _ws.Names.Item("PayrollThrough").RefersToRange.Comment.Shape.Width = 300;
                _ws.Names.Item("PayrollThrough").RefersToRange.Comment.Shape.Height = 40;
                for (int i = 1; i <= count; i++)
                {
                    _ws.Cells[offset + i - 1, 2].Value = contJobHeaderDtl_table.Rows[0].Field<object>(i - 1);
                }

                for (int i = count; i <= contJobHeaderDtl_table.Columns.Count - 1; i++)
                {
                    _ws.Cells[i - count + offset, 4].Value = contJobHeaderDtl_table.Rows[0].Field<object>(i);
                }

                if (_ws.Names.Item("GMAX").RefersToRange.Value == "YES") btnGMAX.Visible = true;

                Excel.Range complete = _ws.Cells[_ws.Names.Item("PercentComplete").RefersToRange.Row, _ws.Names.Item("PercentComplete").RefersToRange.Column];

                Excel.FormatCondition completeCond = (Excel.FormatCondition)complete.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, "=IF(" + complete.Address + "=\"\",\"\",OR(" + complete.Address + "< -1," + complete.Address + " > 1 ))",
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                completeCond.Interior.Color = HelperUI.RedNegColor;
                completeCond.Font.Bold = true;

                Excel.Range endDate = _ws.Cells[_ws.Names.Item("ProjectEndDate").RefersToRange.Row, _ws.Names.Item("ProjectEndDate").RefersToRange.Column];

                Excel.FormatCondition endDateCond = (Excel.FormatCondition)endDate.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, "=IF(" + endDate.Address + "=\"\",\"\"," + endDate.Address + "< TODAY())",
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                endDateCond.Interior.Color = HelperUI.RedNegColor;
                endDateCond.Font.Bold = true;
                endDate.AddComment("To update your Project End Date go to PM Projects/Info tab");

                _ws.Names.Item("PercentComplete").RefersToRange.AddComment("Actual Cost/Projected Cost at Completion");

                rng = _ws.Range[_ws.Cells[2, 1], _ws.Cells[contJobHeaderDtl_table.Columns.Count - 1, 1]];
                rng.EntireRow.Group();

                contJobCTSum_table = JobCTSum.GetJobCTSumTable(JCCo, Contract, job, Month);
                SheetBuilder.BuildGenericTable(_ws, contJobCTSum_table, LastCellOffsetStartRow: 3);

                _table = _ws.ListObjects[1];

                rn = (uint)_table.HeaderRowRange.Row;
                _ws.Cells.Range["A" + rn].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = _ws.Cells.Range["A" + rn + ":E" + rn];
                rng.Merge();
                rng.Value = "Cost Type Breakdown".ToUpper();
                rng.Interior.Color = HelperUI.GrayBreakDownHeaderRowColor;
                rng.Font.Size = HelperUI.FourteenBreakDownHeaderFontSize;
                rng.Font.Color = HelperUI.WhiteDownHeaderFontColor;
                rng.Font.Bold = true;
                rng.RowHeight = 21;

                HelperUI.SortAscending(_ws, "Cost Type", null, 1);

                rng = _ws.Range[_ws.Cells[rng.Row + 1, 1], _ws.Cells[_table.TotalsRowRange.Row + 1, 1]];
                //rng.EntireRow.Group();
                int CTBreak = rng.Row + 1;
                int CTBreakEnd = _table.TotalsRowRange.Row + 1;
                //rng.EntireRow.Hidden = true;

                contJobParentPhaseSum_table = JobParentPhaseSum.GetJobParentPhaseSumTable(JCCo, job);
                if (contJobParentPhaseSum_table.Rows.Count > 0)
                {
                    SheetBuilder.BuildGenericTable(_ws, contJobParentPhaseSum_table, 4);

                    _table = _ws.ListObjects[2];

                    rn = (uint)_table.HeaderRowRange.Row - 1;
                    _ws.Cells.Range["A" + rn].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                    rng = _ws.Cells.Range["A" + rn + ":E" + rn];
                    rng.Merge();
                    rng.Value = "Parent Phase Group Breakdown".ToUpper(); ;
                    rng.Interior.Color = HelperUI.GrayBreakDownHeaderRowColor;
                    rng.Font.Size = HelperUI.FourteenBreakDownHeaderFontSize;
                    rng.Font.Color = HelperUI.WhiteDownHeaderFontColor;
                    rng.Font.Bold = true;
                    rng.RowHeight = 21.75;

                    HelperUI.MergeLabel(_ws, "Parent Phase", "Parent Phase Desc", "Phase Group Breakdown", 2, 1);
                    HelperUI.MergeLabel(_ws, "Current Est'd Hours", "Curr Est + Incl CO's", "Current Budget", 2, 1);
                    HelperUI.MergeLabel(_ws, "Actual Hours", "Committed Cost", "Actual", 2, 1);
                    HelperUI.MergeLabel(_ws, "Remaining Hours", "Remaining Committed Cost", "Remaining (ETC)", 2, 1);
                    HelperUI.MergeLabel(_ws, "Projected Hours", "Projected Cost", "Projected @ Completion", 2, 1);
                    HelperUI.MergeLabel(_ws, "Change in Hours", "Change in Cost", "Change from Previous Closed Month", 2, 1);
                    HelperUI.MergeLabel(_ws, "Over/Under Hours", "Over/Under Cost", "Over/Under", 2, 1);

                    _ws.Cells[_table.HeaderRowRange.Row - 1, 1].EntireRow.Hidden = true;

                    //_table.HeaderRowRange.RowHeight = 25.5;

                    _table.HeaderRowRange.EntireRow.WrapText = true;
                    _table.HeaderRowRange.EntireRow.RowHeight = 30.00;

                    _table.ListColumns["Actual CST/HR"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    _table.ListColumns["Remaining CST/HR"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

                    _ws.Columns[1].ColumnWidth = 27.00;
                    _ws.Columns[2].ColumnWidth = 24.00;
                    _ws.Columns[3].ColumnWidth = 20.00;
                    _ws.Columns[4].ColumnWidth = 20.00;

                    _ws.Columns[5].ColumnWidth = 18.00;
                    _ws.Columns[6].ColumnWidth = 15.75;
                    _ws.Columns[7].ColumnWidth = 9.00;
                    _ws.Columns[8].ColumnWidth = 15.75;

                    _ws.Columns[9].ColumnWidth = 10.00;
                    _ws.Columns[10].ColumnWidth = 15.75;
                    _ws.Columns[11].ColumnWidth = 9.00;
                    _ws.Columns[12].ColumnWidth = 15.75;

                    _ws.Columns[13].ColumnWidth = 10.00;
                    _ws.Columns[14].ColumnWidth = 15.75;
                    _ws.Columns[15].ColumnWidth = 9.00;
                    _ws.Columns[16].ColumnWidth = 14.00;
                    _ws.Columns[17].ColumnWidth = 11.00;
                    _ws.Columns[18].ColumnWidth = 14.00;

                    rng = _ws.Range[_ws.Cells[rng.Row + 1, 1], _ws.Cells[_table.TotalsRowRange.Row, 1]];
                    rng.EntireRow.Group();
                    rng.EntireRow.Hidden = true;
                    HelperUI.FormatHoursCost(_ws, 2);

                    _table.HeaderRowRange.EntireRow.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    _table.TotalsRowRange.Locked = false;
                }

                _ws.Range[_ws.Cells[CTBreak - 1, 1], _ws.Cells[CTBreakEnd, 1]].EntireRow.Group();
                _ws.UsedRange.Font.Name = HelperUI.FontCalibri;
                HelperUI.PrintPageSetup(_ws);

                _ws.UsedRange.Locked = true;
                _ws.ListObjects[1].TotalsRowRange.Locked = false;
                _ws.Range[_ws.Range["F2"], _ws.Cells[_table.HeaderRowRange.Row - 3, _table.ListColumns.Count]].Locked = false;

                HelperUI.ProtectSheet(_ws, false, false);
            }

            if (_ws != null) Marshal.ReleaseComObject(_ws);
            if (after != null) Marshal.ReleaseComObject(after);
        }

        private void DisableGridlines(Excel.Worksheet ws)
        {
            workbook.Activate();

            if (ws == null)
            {
                foreach (DataRow dr in contractjobs_table.Rows)
                {
                    string job = HelperUI.JobTrimDash(dr.Field<string>("Job"));
                    _ws = Globals.ThisWorkbook.Sheets["-" + job];
                    _ws.Activate();
                    _ws.Application.ActiveWindow.DisplayGridlines = false;
                }

                _ws = HelperUI.GetSheet(lastContractNoDash);
                if (_ws != null)
                {
                    _ws.Activate();
                    _ws.Application.ActiveWindow.DisplayGridlines = false;
                }
            }
            else
            {
                ws.Activate();
                ws.Application.ActiveWindow.DisplayGridlines = false;
            }
        }

        private void btnFutureCurve_Click(object sender, EventArgs e)
        {
            _ws = HelperUI.GetSheet(revCurve);
            try
            {
                BuildPRGPivot_RevCurve(ref _ws);
                lblMonth.Visible = false;
                cboMonth.Visible = false;
                btnCopyDetailOffline.Text = "Copy Rev Offline Detail";
                btnCopyDetailOffline.Visible = true;
                btnCopyDetailOffline.Tag = copyFutureCurveOffline;
            }
            catch (Exception ex)
            {
                lblMonth.Visible = true;
                cboMonth.Visible = true;
                if (_ws != null)
                {
                    Globals.ThisWorkbook.Application.DisplayAlerts = false;
                        _ws.Delete();
                    Globals.ThisWorkbook.Application.DisplayAlerts = true;
                }
                Globals.ThisWorkbook.Sheets[lastContractNoDash].Activate();
                ErrOut(ex);
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, Contract, null, null, CostBatchId, ErrorTxt: ex.Message);
            }
        }

        private void BuildPRGPivot_RevCurve(ref Excel.Worksheet ws)
        {
            Excel.Range rng = null;
            Excel.Worksheet after = null;
            Excel.Range periods = null;
            Excel.ListObject PRGPivot = null;
            Excel.Range RevHeaders = null;
            Excel.ListColumn SumCol = null;
            Excel.Range RevStartCell = null;
            Excel.Range RevEndCell = null;

            try
            {
                RenderOFF();
                if (ws != null)
                {
                    after = ws.Previous;
                    workbook.Application.DisplayAlerts = false;
                    ws.Delete();
                    workbook.Application.DisplayAlerts = true;
                    ws = HelperUI.AddSheet(revCurve, after);
                }
                else
                {
                    ws = HelperUI.AddSheet(revCurve, Globals.ThisWorkbook.Sheets[lastContractNoDash]);
                }

                ws.Cells.Locked = false;
                contractPRGPivot_table = ContractPRGPivot.GetContractPRGPivotTable(JCCo, Contract);
                SheetBuilder.BuildGenericTable(ws, contractPRGPivot_table);

                // ContractPRGPivot Table below 
                PRGPivot = ws.ListObjects[1];
                RevHeaders = PRGPivot.HeaderRowRange;
                SumCol = PRGPivot.ListColumns["Remaining at Margin"];
                RevStartCell = null;
                RevEndCell = null;

                ws.Cells[PRGPivot.HeaderRowRange.Row - 1, 1].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown); // head title
                ws.Cells[PRGPivot.HeaderRowRange.Row - 1, 1].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = ws.Range["A1:V1"];
                rng.Merge();
                rng.Value = "PROJECTED FUTURE REVENUE: " + ((string)((Excel.Worksheet)Globals.ThisWorkbook.Sheets[lastContractNoDash]).Range["A1"].Value).Split(':')[1];
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                rng = ws.Cells[RevHeaders.Row - 3, 1];
                rng.Merge();
                rng.Value = "Projected Future Revenue";
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                byte RevdataEntryAreaOffset = 0x1;
                int periodStartCol = PRGPivot.ListColumns["Current Month Catch Up"].Index + RevdataEntryAreaOffset;

                RevStartCell = ws.Cells[RevHeaders.Row, periodStartCol];
                RevEndCell = ws.Cells[RevHeaders.Row, RevHeaders.Columns.Count];

                SumCol.DataBodyRange.FormulaLocal = "=SUM(" + PRGPivot.Name + "[@[" + RevStartCell.Formula + "]:[" + RevEndCell.Formula + "]])";
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.FormulaLocal = "=[@[Calculated Remaining Revenue]]-[@[Remaining at Margin]]";
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.FormulaLocal = "=[@[Margin Change Catch Up]]+[@[" + RevStartCell.Formula + "]]";
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.Columns.Style = HelperUI.CurrencyStyle;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.EntireColumn.ColumnWidth = 13;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.EntireColumn.ColumnWidth = 10;
                PRGPivot.ListColumns["Calculated Remaining Revenue"].DataBodyRange.EntireColumn.ColumnWidth = 13;

                HelperUI.AddFieldDesc(ws, "PRG", "Project Revenue Group (Project Number)");
                HelperUI.AddFieldDesc(ws, "PRG Description", "Project Description");
                HelperUI.AddFieldDesc(ws, "JC Dept", "Job cost department number");
                HelperUI.AddFieldDesc(ws, "JC Dept Description", "Job cost department description");
                HelperUI.AddFieldDesc(ws, "Calculated Remaining Revenue", "Projected contract value less revenue earned through prior month");
                HelperUI.AddFieldDesc(ws, "Remaining at Margin", "Remaining revenue to be earned assuming margin did not change");
                HelperUI.AddFieldDesc(ws, "Margin Change Catch Up", "If margin change, calculates the net current margin hit");
                HelperUI.AddFieldDesc(ws, "Current Month Catch Up", "If margin change, calculates Margin catch up + monthly revenue");

                HelperUI.MergeLabel(ws, "PRG", "Current Month Catch Up", "Current Month Catch Up");
                HelperUI.MergeLabel(ws, RevStartCell.Text, PRGPivot.ListColumns[RevEndCell.Column].Name, "Remaining Monthly Revenue");

                periods = ws.Range[ws.Cells[RevHeaders.Row - 1, RevStartCell.Column], ws.Cells[RevHeaders.Row - 1, RevEndCell.Column]];
                periods.Merge();
                periods.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                periods.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                periods.Value = "Projected revenue by month based on cost estimate and margin";

                periods = ws.Range[ws.Cells[RevHeaders.Row, RevStartCell.Column], ws.Cells[RevHeaders.Row, RevEndCell.Column]];
                RevEndCell = ws.Cells[PRGPivot.TotalsRowRange.Row + 3, RevEndCell.Column];
                rng = ws.Range[ws.Cells[PRGPivot.TotalsRowRange.Row + 3, periodStartCol], RevEndCell];
                rng.NumberFormat = "MM/yy";
                rng.Value2 = periods.Value2;
                rng.Font.Color = HelperUI.WhiteFontColor;

                periods = ws.Range[ws.Cells[RevHeaders.Row + 1, RevStartCell.Column], ws.Cells[PRGPivot.TotalsRowRange.Row - 1, RevEndCell.Column]];
                rng = ws.Range[ws.Cells[PRGPivot.TotalsRowRange.Row + 4, RevStartCell.Column], ws.Cells[PRGPivot.TotalsRowRange.Row + 3 + PRGPivot.ListRows.Count, RevEndCell.Column]];
                rng.Value2 = periods.Value2;
                rng.NumberFormat = "$#,##0;$(#,##0);$\" - \"??;(_(@_)";
                rng.Font.Color = HelperUI.WhiteFontColor;

                periods.EntireColumn.ColumnWidth = 12;

                PRGPivot.ListColumns["PRG"].DataBodyRange.ColumnWidth = 8.57;
                PRGPivot.ListColumns["PRG Description"].DataBodyRange.ColumnWidth = 25.14;
                PRGPivot.ListColumns["JC Dept"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                PRGPivot.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 7;
                PRGPivot.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 17.57;
                PRGPivot.ListColumns["Calculated Remaining Revenue"].DataBodyRange.ColumnWidth = 14.5;
                PRGPivot.ListColumns["Remaining at Margin"].DataBodyRange.ColumnWidth = 15.88;
                PRGPivot.ListColumns["Margin Change Catch Up"].DataBodyRange.ColumnWidth = 13.63;
                PRGPivot.ListColumns["Current Month Catch Up"].DataBodyRange.ColumnWidth = 15;

                RevHeaders.EntireRow.RowHeight = 30.00;
                RevHeaders.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                ws.Cells[RevHeaders.Row - 1, 1].EntireRow.Group();
                ws.Cells[RevHeaders.Row - 1, 1].EntireRow.Hidden = true;

                ws.Range[ws.Cells[RevHeaders.Row - 2, 1], ws.Cells[PRGPivot.TotalsRowRange.Row, 1]].EntireRow.Group();

                //for 10/17/2016 1.1 release, postponed per Gen 10/14
                AddRevenueGraph(PRGPivot, RevHeaders, RevEndCell, RevdataEntryAreaOffset);

                HelperUI.GroupColumns(ws, "Calculated Remaining Revenue", "Margin Change Catch Up");
                HelperUI.PrintPage_RevCurveSetup(ws);

                ws.UsedRange.Locked = true;
                PRGPivot.TotalsRowRange.Locked = false;
                HelperUI.ProtectSheet(ws, false, false);
                DisableGridlines(ws);
                ws.Range["A1"].Activate();
            }
            catch (Exception) { throw; }
            finally
            {
                RenderON();
                if (SumCol != null) Marshal.ReleaseComObject(SumCol);
                if (RevStartCell != null) Marshal.ReleaseComObject(RevStartCell);
                if (RevEndCell != null) Marshal.ReleaseComObject(RevEndCell);
                if (PRGPivot != null) Marshal.ReleaseComObject(PRGPivot);
                if (RevHeaders != null) Marshal.ReleaseComObject(RevHeaders);
                if (after != null) Marshal.ReleaseComObject(after);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (periods != null) Marshal.ReleaseComObject(periods);
            }

        }

        private void AddRevenueGraph(Excel.ListObject PRGPivot, Excel.Range RevHeaders, Excel.Range RevEnd, byte RevdataEntryAreaOffset)
        {
            Excel.Range RevStart = null;
            try
            {
                int projectCount = PRGPivot.ListRows.Count;
                dynamic startDraw = _ws.UsedRange.Height - (projectCount * 15) - 15;
                int endCol = RevHeaders.Columns.Count;
                var charts = _ws.ChartObjects() as Excel.ChartObjects;
                var chartObj = charts.Add(0, startDraw, (.50 * endCol) * 100, 255) as Excel.ChartObject;
                var myChart = chartObj.Chart;

                chartObj.Activate();

                myChart.ChartType = Excel.XlChartType.xlLine;
                Excel.SeriesCollection seriesCollection = myChart.SeriesCollection();
                Excel.Range endCell = null;
                Excel.Range startCell = null;

                int startCol = PRGPivot.ListColumns["Current Month Catch Up"].Index + RevdataEntryAreaOffset;
                int PRGcol = PRGPivot.ListColumns["PRG"].Index;
                RevStart = _ws.Cells[PRGPivot.TotalsRowRange.Row + 3, startCol];

                for (int i = 1; i <= projectCount; i++)
                {
                    int row = PRGPivot.TotalsRowRange.Row + i + 3;
                    Excel.Series series = seriesCollection.NewSeries();
                    series.Name = _ws.Cells[row, PRGcol].Formula;
                    series.XValues = _ws.get_Range(RevStart, RevEnd);
                                                                         
                    startCell = _ws.Cells[row, startCol];
                    endCell = _ws.Cells[row, endCol];

                    series.Values = _ws.get_Range(startCell, endCell);
                    series.ChartType = Excel.XlChartType.xlLine;
                   // series.Format.Line.ForeColor.RGB = (int)Excel.XlRgbColor.rgbRed;
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (RevStart != null) Marshal.ReleaseComObject(RevStart);
            }
        }

        private void btnGMAX_Click(object sender, EventArgs e)
        {
            if (HelperUI.SheetExists(ETCOverviewActionPane.costSumSheet.Replace("-", "") + btnGMAX.Tag))
            {
                MessageBox.Show("Please post your batch before opening a GMAX worksheet", "GMAX Report", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            Excel.Worksheet gmax = HelperUI.GetSheet("GMAX" + btnGMAX.Tag);

            try
            {
                if (gmax == null)
                {
                    LoadGMAX(ref gmax, false);
                }
                else {
                    gmax.Activate();
                }
                lblMonth.Visible = false;
                cboMonth.Visible = false;
                btnCopyDetailOffline.Text = "Copy GMAX Worksheet Offline";
                btnCopyDetailOffline.Visible = true;
                btnCopyDetailOffline.Tag = copyGMAXOffline;
            }
            catch (Exception ex)
            {
                lblMonth.Visible = true;
                cboMonth.Visible = true;
                gmax = HelperUI.GetSheet("GMAX" + btnGMAX.Tag);
                if (gmax != null)
                {
                    workbook.Application.DisplayAlerts = false;
                    gmax.Delete();
                    workbook.Application.DisplayAlerts = true;
                }
                Globals.ThisWorkbook.Sheets[btnGMAX.Tag].Activate();
                ErrOut(ex);
                LogProphecyAction.InsProphecyLog(Login, 18, JCCo, Contract, Job, null, CostBatchId, ErrorTxt: ex.Message, 
                                                 Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
            }
            finally
            {
                if (gmax != null) Marshal.ReleaseComObject(gmax);
            }
        }

            private void LoadGMAX(ref Excel.Worksheet gmax, bool refresh)
            {
                try
                {
                    DataTable table = JobGMAX.GetJobGMAXTable(JCCo, cboJobs.Text);
                    if (table.Rows.Count > 0)
                    {
                        if (!refresh)
                        {
                            Globals.GMAX.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.ThisWorkbook.Sheets["GMAX"].Copy(After: Globals.ThisWorkbook.Sheets[btnGMAX.Tag]);
                            gmax = Globals.ThisWorkbook.Sheets[btnGMAX.Tag].Next;
                            Globals.GMAX.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                            gmax.Range["A3"].Activate();
                            gmax.Name = "GMAX" + btnGMAX.Tag;
                            var projectName = (from DataRow dr in contractjobs_table.Rows select (string)dr["JobDesc"]).FirstOrDefault();
                            gmax.Range["A1"].Formula = "GMAX Worksheet: " + cboJobs.Text + "_" + projectName;

                            gmax.Cells.Locked = false;
                            gmax.UsedRange.Locked = true;
                            gmax.Range["B28:B30"].Locked = false;
                            gmax.Range["B38:B39"].Locked = false;
                            gmax.Range["B44:B45"].Locked = false;
                            gmax.Range["C42"].Locked = false;
                            gmax.Range["D37"].Locked = false;
                            gmax.Range["D40:D41"].Locked = false;

                            HelperUI.PrintPage_GMAXSetup(gmax);
                            HelperUI.ProtectSheet(gmax, false, false);
                        }
                        gmax.Names.Item("ActualStaffBurden").RefersToRange.Value = table.Rows[0].Field<object>("ActualStaffBurden");
                        gmax.Names.Item("ContractActualFieldBurden").RefersToRange.Value = table.Rows[0].Field<object>("ContractActualFieldBurden");
                        gmax.Names.Item("ContractShopBurden").RefersToRange.Value = table.Rows[0].Field<object>("ContractShopBurden");
                        gmax.Names.Item("BaseFee").RefersToRange.Value = table.Rows[0].Field<object>("BaseFee");
                        gmax.Names.Item("BandO").RefersToRange.Value = table.Rows[0].Field<object>("BandO");
                        gmax.Names.Item("GLI").RefersToRange.Value = table.Rows[0].Field<object>("GLI");
                        gmax.Names.Item("SmallTools").RefersToRange.Value = table.Rows[0].Field<object>("SmallTools");
                        gmax.Names.Item("Warranty").RefersToRange.Value = table.Rows[0].Field<object>("Warranty");
                        gmax.Names.Item("Bond").RefersToRange.Value = table.Rows[0].Field<object>("Bond");
                        gmax.Names.Item("TB_Staff").RefersToRange.Value = table.Rows[0].Field<object>("TB_Staff");
                        gmax.Names.Item("TB_Field").RefersToRange.Value = table.Rows[0].Field<object>("TB_Field");
                        gmax.Names.Item("TB_Shop").RefersToRange.Value = table.Rows[0].Field<object>("TB_Shop");
                        gmax.Names.Item("UF_Field").RefersToRange.Value = table.Rows[0].Field<object>("UF_Field");
                        gmax.Names.Item("UF_Shop").RefersToRange.Value = table.Rows[0].Field<object>("UF_Shop");
                        gmax.Names.Item("ProjCost").RefersToRange.Value = table.Rows[0].Field<object>("ProjCost");
                        gmax.Names.Item("ProjHours").RefersToRange.Value = table.Rows[0].Field<object>("ProjHours");

                        LogProphecyAction.InsProphecyLog(Login, 18, JCCo, Contract, Job, null, CostBatchId);
                    }
                    else
                    {
                        throw new Exception("No GMAX data available");
                    }
                }
                catch (Exception){ throw;}
            }

        #endregion


        #region GENERATE PROJECTIONS

        private bool GenerateRevenueProjections()
        {
            isRendering = true;
            bool success = false;

            if (HelperUI.SheetExists(revSheet, false))
            {
                throw new Exception("Only 1 Revenue batch can be open at a time. \n\nPlease post the other batch before attempting to open a Revenue batch for this project.");
            }

            if (JCCo == 0) { return false; }
            if (Login == "") throw new Exception("Unable to validate you as a valid user in Viewpoint.\n" +
                                                 "Make sure Viewpoint is online and check your access.");
            Pivot = "MONTH";

            try
            {
                success = ProjectRevenue.GenerateRevenueProjection(JCCo, Contract, Month, Login, out revBatchId, out revBatchDateCreated);
                RevBatchId = revBatchId;
                if (success)
                {
                    contJectRevenue_table = ConJectBatchSummary.GetConJectBatchSumTable(JCCo, Contract, Month);
                    RenderOFF();

                    if (contJectRevenue_table.Rows.Count > 0)
                    {
                        string sheetname = "Rev-" + Contract.Replace("-","");

                        _ws = HelperUI.AddSheet(sheetname, workbook.ActiveSheet);

                        SheetBuilder.BuildGenericTable(_ws, contJectRevenue_table);

                        SetupRevTab(_ws, sheetname);
                        HelperUI.FormatHoursCost(_ws);

                        DisableGridlines(_ws);
                        _ws.Range["A1"].Activate();
                        HelperUI.FreezePane(_ws, "JC Dept");
                    }
                }
            }
            catch (Exception ex) {
                RevJectErrOut(ex);
                return false;
            }
            finally
            {
                //Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                //Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
                RenderON();
            }
            
            return true;
        }

        private bool GenerateCostProjections()
        {
            isRendering = true;

            if (HelperUI.SheetExists(costSumSheet, false))
            {
                throw new Exception("Only 1 cost batch can be open at a time. \n\nPlease post the other batch before attempting to open a cost batch for this project.");
            }

            //if (Job == "" || Job == null)
            //{
            //if (cboJobs.Text != "")
            //{
            //    Job = cboJobs.Text;
            //}
            //else
            //{
            //    errorProvider1.SetError(cboJobs, "Select a Project");
            //    return false;
            //}
            //}

            if (Login == "") throw new Exception("Unable to validate you as a valid user in Viewpoint.\nMake sure Viewpoint is online and check your access.");

            Excel.Worksheet _wsSum = null;
            Excel.Worksheet _wsNonLabor = null;
            Excel.Worksheet _wsLabor = null;
            Excel.Range rngHeaders = null;
            Excel.Range rngTotals = null;
            Excel.Range rngTopLeft = null;
            Excel.Range rngBottomRight = null;
            Excel.ListObject table = null;
            Excel.ListColumn column = null;
            Excel.Range cellStart = null;
            Excel.Range cellEnd = null;
            Excel.Range grpMonths = null;
            string colBeforeEntry = "";

            try
            {
                Pivot = "MONTH";
                bool success = false;
                string newSheetName = "";
                Job = cboJobs.Text;

                //Stopwatch t2 = new Stopwatch(); t2.Start();
                success = JobJectCostProj.GenerateCostProjection(JCCo, Contract, Job, Month, Login, out costBatchId, out costBatchDateCreated);
                CostBatchId = costBatchId;
                //t2.Stop(); MessageBox.Show(string.Format("Time elapsed: {0:hh\\:mm\\:ss\\:ff}", t2.Elapsed));

                if (success)
                {

                    // Summary tab
                    contJobJectBatchSum_table = JobJectBatchSummary.GetJobJectBatchSummaryTable(JCCo, Job, Month);
                    RenderOFF();
                    string job = HelperUI.JobTrimDash(Job);

                    if (contJobJectBatchSum_table.Rows.Count > 0)
                    {
                        newSheetName = costSumSheet + job;

                        _wsSum = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

                        SheetBuilder.BuildGenericTable(_wsSum, contJobJectBatchSum_table);

                        SetupSumTab(_wsSum, newSheetName);

                        // NonLabor tab
                        contJobJectBatchNonLabor_table = JobJectBatchNonLabor.GetJobJectBatchNonLaborTable(JCCo, Job, Pivot);

                        if (contJobJectBatchNonLabor_table.Rows.Count > 0)
                        {
                            newSheetName = nonLaborSheet + job;
                            _wsNonLabor = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

                            SheetBuilder.BuildGenericTable(_wsNonLabor, contJobJectBatchNonLabor_table);
                            Globals.ThisWorkbook.pivotNonLaborRowCount = contJobJectBatchNonLabor_table.Rows.Count;

                            SetupNonLaborTab(_wsNonLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd, out colBeforeEntry);
                        }

                        // Labor tab
                        LaborPivot = LaborPivotSearch.GetLaborPivot(JCCo, Job);
                        contJobJectBatchLabor_table = JobJectBatchLabor.GetJobJectBatchLaborTable(JCCo, Job, LaborPivot);

                        if (contJobJectBatchLabor_table.Rows.Count > 0)
                        {
                            newSheetName = laborSheet + job;

                            _wsLabor = HelperUI.AddSheet(newSheetName, _wsSum);

                            SheetBuilder.BuildGenericTable(_wsLabor, contJobJectBatchLabor_table);

                            Globals.ThisWorkbook.pivotLaborRowCount = contJobJectBatchLabor_table.Rows.Count;

                            SetupLaborTab(_wsSum, _wsNonLabor, _wsLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd);
                        }

                        SetSumTabFormulas(_wsSum);
                        workbook.Activate();

                        _wsLabor.Activate();
                        _wsLabor.Application.ActiveWindow.DisplayGridlines = false;
                        _wsLabor.Range["A1"].Activate();
                        HelperUI.FreezePane(_wsLabor, "Employee ID");
                        HelperUI.ApplyUsedFilter(_wsLabor, "Used", 1);

                        _wsNonLabor.Activate();
                        _wsNonLabor.Application.ActiveWindow.DisplayGridlines = false;
                        _wsNonLabor.Range["A1"].Activate();
                        HelperUI.FreezePane(_wsNonLabor, "Description");
                        HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[_wsNonLabor.ListObjects[1].HeaderRowRange.Row, _wsNonLabor.ListObjects[1].ListColumns["Remaining Cost"].Index + _offsetFromRemCost].Value);
                        HelperUI.ApplyUsedFilter(_wsNonLabor, "Used");

                        _wsSum.Activate();
                        _wsSum.Application.ActiveWindow.DisplayGridlines = false;
                        _wsSum.Range["A1"].Activate();
                        HelperUI.FreezePane(_wsSum, "Original Hours");
                        HelperUI.ApplyUsedFilter(_wsSum, "Used", 1);
                    }
                    else
                    {
                        MessageBox.Show("Please review your project set up and/or contact Viewpoint Training for assistance.", "Summary",MessageBoxButtons.OK,MessageBoxIcon.Information);
                        return false;
                    }
                }
            }
            catch (Exception ex)
            {
                //MessageBox.Show(ex.StackTrace);
                CostJectErrOut(ex);
                return false;
            } // possible exceptions from the back-end or UI
            finally
            {
                //Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                //Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
                RenderON();

                if (_wsLabor != null){Marshal.ReleaseComObject(_wsLabor);}
                if (_wsNonLabor != null){Marshal.ReleaseComObject(_wsNonLabor);}
                if (rngHeaders != null) Marshal.ReleaseComObject(rngHeaders);
                if (rngTotals != null) Marshal.ReleaseComObject(rngTotals);
                if (rngTopLeft != null) Marshal.ReleaseComObject(rngTopLeft);
                if (rngBottomRight != null) Marshal.ReleaseComObject(rngBottomRight);
                if (table != null) Marshal.ReleaseComObject(table);
                if (column != null) Marshal.ReleaseComObject(column);
                if (cellStart != null) Marshal.ReleaseComObject(cellStart);
                if (cellEnd != null) Marshal.ReleaseComObject(cellEnd);
                if (grpMonths != null) Marshal.ReleaseComObject(grpMonths);
                if (_wsSum != null) Marshal.ReleaseComObject(_wsSum);
                if (_wsNonLabor != null) Marshal.ReleaseComObject(_wsNonLabor);
            }
            return true;
        }

        private void CostJectErrOut(Exception ex)
        {
            object errcode = ex.Data.Count > 0 ? ex.Data[0] : 3;  // possible values 2 or 3
            byte code = Convert.ToByte(errcode);

            LogProphecyAction.InsProphecyLog(Login, code, JCCo, Contract, Job, ErrorTxt:  ex.Message, Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
            ErrOut(ex);

            workbook.Application.DisplayAlerts = false;
            foreach (Excel.Worksheet _ws in workbook.Worksheets)
            {
                if (_ws.Name.Contains(costSumSheet) || _ws.Name.Contains(laborSheet) || _ws.Name.Contains(nonLaborSheet))
                {
                    _ws.Delete();
                }
            }
            workbook.Application.DisplayAlerts = true;

            Globals.GMAX.Visible = Excel.XlSheetVisibility.xlSheetHidden;

            CostBatchId = 0;
            Globals.ThisWorkbook.isCostDirty = null;
        }

        private void RevJectErrOut(Exception ex)
        {
            object errcode = ex.Data.Count > 0 ? ex.Data[0] : 6;  // possible values 5 or 6
            byte code = Convert.ToByte(errcode);

            LogProphecyAction.InsProphecyLog(Login, code, JCCo, Contract, Job, ErrorTxt: ex.Message);
            ErrOut(ex);

            workbook.Application.DisplayAlerts = false;
            foreach (Excel.Worksheet _ws in workbook.Worksheets)
            {
                if (_ws.Name.Contains(revSheet))
                {
                    _ws.Delete();
                }
            }
            workbook.Application.DisplayAlerts = true;

            //Globals.GMAX.Visible = Excel.XlSheetVisibility.xlSheetHidden;

            RevBatchId = 0;
            Globals.ThisWorkbook.isRevDirty = null;
            _ws = HelperUI.GetSheet(lastContractNoDash, true);
            _ws?.Activate();
        }
        #endregion


        #region Setup Sum, Labor, Nonlabor and Revenue sheets

        private void SetupSumTab(Excel.Worksheet _ws, string sheetName)
        {
            Excel.Range batchDateCreated = null;
            Excel.Range projectedCost = null;
            Excel.Range projectedMargin = null;

            try
            {
                _ws = HelperUI.GetSheet(sheetName, false);
                _table = _ws.ListObjects[1];
                _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                _ws.Cells.Range["A1:AJ1"].Merge();

                _ws.Cells.Range["A1"].Formula = JobGetTitle.GetTitle(JCCo, Job) + " Summary Worksheet";
                _ws.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
                _ws.Cells.Range["A1"].Font.Bold = true;

                _ws.Cells.Range["A2"].Formula = "Batch Created on: ";
                _ws.Cells.Range["A2:D2"].Font.Color = HelperUI.McKColor(HelperUI.McKColors.Black);
                _ws.Cells.Range["D2"].NumberFormat = "d-mmm-yyyy h:mm AM/PM";
                _ws.Cells.Range["D2"].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                _ws.Cells.Range["D2"].Formula = costBatchDateCreated;
                _ws.Cells.Range["D2"].AddComment("All times Pacific");
                batchDateCreated = _ws.Cells.Range["A2:D2"];

                Excel.FormatCondition batchDateCreatedCond = (Excel.FormatCondition)batchDateCreated.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, "=IF(" + _ws.Cells.Range["D2"].Address + "=\"\",\"\"," + _ws.Cells.Range["D2"].Address + "< TODAY())",
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                batchDateCreatedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                batchDateCreatedCond.Font.Color = HelperUI.WhiteFontColor;
                batchDateCreatedCond.Font.Bold = true;

                int atRow = _table.HeaderRowRange.Row - 3;
                int currEstHrs = _table.ListColumns["Curr Est Hours"].Index;
                int JTDActualHrs = _table.ListColumns["JTD Actual Hours"].Index;
                projectedCost = _ws.Cells.Range[_ws.Cells[atRow, currEstHrs], _ws.Cells[atRow, (JTDActualHrs + 1)]];
                projectedCost.Font.Color = HelperUI.WhiteFontColor;
                projectedCost.Font.Bold = true;
                projectedCost.Font.Size = HelperUI.TwelveFontSizeHeader;
                projectedCost.Interior.Color = HelperUI.NavyBlueHeaderRowColor;

                projectedCost = _ws.Cells.Range[_ws.Cells[atRow, currEstHrs], _ws.Cells[atRow, currEstHrs + 1]];
                projectedCost.Merge();
                projectedCost.Formula = "New Projected Cost";
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;

                projectedCost = _ws.Cells.Range[_ws.Cells[atRow, JTDActualHrs], _ws.Cells[atRow, JTDActualHrs + 1]];
                projectedCost.Merge();
                _ws.Names.Add("NewProjectedCost", projectedCost);
                projectedCost.NumberFormat = HelperUI.CurrencyFormatCondensed;
                projectedCost.FormulaLocal = "=SUM(" + _table.ListColumns["Projected Cost"].DataBodyRange.Address + ")";
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 2;
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThick;
                projectedCost.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                int actualCST_HR = _table.ListColumns["Actual CST/HR"].Index;
                int remCommittedCost = _table.ListColumns["Remaining Committed Cost"].Index;

                projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, actualCST_HR], _ws.Cells[atRow, remCommittedCost]];
                projectedMargin.Font.Color = HelperUI.WhiteFontColor;
                projectedMargin.Font.Bold = true;
                projectedMargin.Font.Size = HelperUI.TwelveFontSizeHeader;
                projectedMargin.Interior.Color = HelperUI.NavyBlueHeaderRowColor;

                _ws.Cells[atRow, actualCST_HR].AddComment("based on most recent posted revenue projection");
                projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, actualCST_HR], _ws.Cells[atRow, actualCST_HR + 1]];
                projectedMargin.Merge();
                projectedMargin.Formula = "New Projected Margin";
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;

                projectedMargin = _ws.Cells[atRow, remCommittedCost];
                _ws.Names.Add("NewProjectedMargin", projectedMargin);
                CostSum_ProjectedMargin_Fill();

                HelperUI.AddFieldDesc(_ws, "Used", "See comment");
                HelperUI.AddFieldDesc(_ws, "Parent Phase Description", "Parent phase grouping");
                HelperUI.AddFieldDesc(_ws, "Phase Code", "Phase Code");
                HelperUI.AddFieldDesc(_ws, "Phase Description", "Phase description");
                HelperUI.AddFieldDesc(_ws, "Cost Type", "Cost Type");
                HelperUI.AddFieldDesc(_ws, "Original Hours", "Original Hours Estimate");
                HelperUI.AddFieldDesc(_ws, "Original Cost", "Original Cost Estimate");
                HelperUI.AddFieldDesc(_ws, "Appr CO Hours", "Approved and interfaced change order hours");
                HelperUI.AddFieldDesc(_ws, "Appr CO Cost", "Approved and interfaced change order cost");
                HelperUI.AddFieldDesc(_ws, "PCO Hours", "Sum of pending change order (PCO) hours in Viewpoint");
                HelperUI.AddFieldDesc(_ws, "PCO Cost", "Sum of pending change order (PCO) cost");
                HelperUI.AddFieldDesc(_ws, "Curr Est Hours", "Original estimated hours plus interfaced change order hours");
                HelperUI.AddFieldDesc(_ws, "Curr Est Cost", "Original estimate + interfaced change orders");
                HelperUI.AddFieldDesc(_ws, "JTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets)");
                HelperUI.AddFieldDesc(_ws, "MTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets) for the current month");
                HelperUI.AddFieldDesc(_ws, "JTD Actual Cost", "Actual cost posted to the project");
                HelperUI.AddFieldDesc(_ws, "MTD Actual Cost", "Actual cost incurred on the project for the current month");
                HelperUI.AddFieldDesc(_ws, "LM Actual Cost", "Actual cost incurred through the end of the prior calendar month");
                HelperUI.AddFieldDesc(_ws, "Actual CST/HR", "Actual cost divided by actual hours");
                HelperUI.AddFieldDesc(_ws, "Total Committed Cost", "Total committments by phase/cost type");
                HelperUI.AddFieldDesc(_ws, "Remaining Hours", "Sum of hours on labor worksheet by phase");
                HelperUI.AddFieldDesc(_ws, "Remaining Cost", "Sum of remaining cost from labor and non-labor worksheet by phase");
                HelperUI.AddFieldDesc(_ws, "Remaining CST/HR", "Remaining cost divided by remaining hours");
                HelperUI.AddFieldDesc(_ws, "Remaining Committed Cost", "Open or remaining committed cost (negative remaining committed cost may not reflect if there are multiple commitments on phase/CT)");
                HelperUI.AddFieldDesc(_ws, "Manual ETC Hours", "Labor only - Manual ETC Entry allows user to enter total remaining hours");
                HelperUI.AddFieldDesc(_ws, "Manual ETC CST/HR", "Labor only - Manual ETC Entry allows user to enter remaining cost per hour");
                HelperUI.AddFieldDesc(_ws, "Manual ETC Cost", "Non-Labor only - Manual ETC Entry allows user to enter total remaining hours");
                HelperUI.AddFieldDesc(_ws, "Projected Hours", "LM Actual Hours + Remaining Hours - or - JTD Hours + Manual ETC hours (if used)");
                HelperUI.AddFieldDesc(_ws, "Projected Cost", "LM Actual Cost + Remaining Cost - or - JTD Actual Cost + Manual ETC Cost (if used)");
                HelperUI.AddFieldDesc(_ws, "Actual Cost > Projected Cost", "If Actual Cost is greater than Projected Cost, the cell will highlight red and warn when saving");
                HelperUI.AddFieldDesc(_ws, "Prev Projected Hours", "Total hours projected from the lasted posted batch");
                HelperUI.AddFieldDesc(_ws, "Prev Projected Cost", "Total cost projected from the last posted batch");
                HelperUI.AddFieldDesc(_ws, "Change in Hours", "Change in total hours projected from last posted batch");
                HelperUI.AddFieldDesc(_ws, "Change in Cost", "Change in total cost projected from last posted batch");
                HelperUI.AddFieldDesc(_ws, "LM Projected Hours", "Hours projected at the end of the last calendar month");
                HelperUI.AddFieldDesc(_ws, "LM Projected Cost", "Cost projected at the end of the last calendar month");
                HelperUI.AddFieldDesc(_ws, "Change from LM Projected Hours", "Change in total hours projected from last calendar month");
                HelperUI.AddFieldDesc(_ws, "Change from LM Projected Cost", "Change in total cost projected from last calendar month");
                HelperUI.AddFieldDesc(_ws, "Over/Under Hours", "Current estimated hours (including interfaced change orders) less total projected hours");
                HelperUI.AddFieldDesc(_ws, "Over/Under Cost", "Current estimated cost (including interfaced change orders) less total projected cost");

                HelperUI.MergeLabel(_ws, "Used", "Cost Type", "Phase Detail");
                HelperUI.MergeLabel(_ws, "Original Hours", "Original Cost", "Original Estimate (Budget)");
                HelperUI.MergeLabel(_ws, "Appr CO Hours", "PCO Cost", "Change Orders");
                HelperUI.MergeLabel(_ws, "Curr Est Hours", "Curr Est Cost", "Current Budget");
                HelperUI.MergeLabel(_ws, "JTD Actual Hours", "Total Committed Cost", "Actual");
                HelperUI.MergeLabel(_ws, "Remaining Hours", "Remaining CST/HR", "Remaining (ETC) from Worksheet");
                HelperUI.MergeLabel(_ws, "Remaining Committed Cost", "Remaining Committed Cost", "Remaining Committed");
                HelperUI.MergeLabel(_ws, "Manual ETC Hours", "Manual ETC Cost", "Manual ETC Entry");
                HelperUI.MergeLabel(_ws, "Projected Hours", "Actual Cost > Projected Cost", "Projected @ Completion");
                HelperUI.MergeLabel(_ws, "Prev Projected Hours", "Prev Projected Cost", "Prev Projection ");
                HelperUI.MergeLabel(_ws, "Change in Hours", "Change in Cost", "Change from Previous Projection");
                HelperUI.MergeLabel(_ws, "LM Projected Hours", "LM Projected Cost", "Last Month");
                HelperUI.MergeLabel(_ws, "Change from LM Projected Hours", "Change from LM Projected Cost", "Change from Last Month");
                HelperUI.MergeLabel(_ws, "Over/Under Hours", "Over/Under Cost", "Over/Under Current Estimate");

                _ws.get_Range("A4", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                _ws.get_Range("A4", Type.Missing).EntireRow.Hidden = true;
                _ws.get_Range("B5", Type.Missing).EntireColumn.Hidden = true;

                _table.ShowTotals = true;

                _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                _table.ListColumns["Manual ETC Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
                _table.ListColumns["Manual ETC CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                _table.ListColumns["Remaining CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;

                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].AddComment("If the phase code has no budgeted, actual or projected cost it is hidden. Adjust column filter to see all rows.");
                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;

                CostSumWritable = _ws.Range[_ws.Cells[_table.HeaderRowRange.Row + 1, _table.ListColumns["Manual ETC Hours"].Index],
                                           _ws.Cells[_table.TotalsRowRange.Row - 1, _table.ListColumns["Manual ETC Cost"].Index]];

                CostSumWritable.Interior.Color = HelperUI.DataEntryColor;

                HelperUI.FormatHoursCost(_ws);

                foreach (Excel.ListColumn col in _table.ListColumns)
                {
                    col.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                }

                string[] noSummation = new string[] { "Used", "Parent Phase Description", "Phase Code", "Phase Description", "Cost Type", "Actual CST/HR", "Remaining CST/HR", "Manual ETC CST/HR" };
                foreach (string col in noSummation)
                {
                    try
                    {
                        _table.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    }
                    catch (Exception) { }
                }
                _table.HeaderRowRange.EntireRow.WrapText = true;
                _table.HeaderRowRange.EntireRow.RowHeight = 30.00;
                _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                _table.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                projectedCost = _table.ListColumns["Projected Cost"].DataBodyRange;
                projectedCost.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                projectedCost.Font.Color = HelperUI.WhiteFontColor;
                projectedCost.Font.Bold = true;
                projectedCost.Cells.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                projectedCost.Cells.Borders.Weight = Excel.XlBorderWeight.xlThin;
                projectedCost.Cells.Borders.Color = HelperUI.GrayBreakDownHeaderRowColor;
                projectedCost.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
                projectedCost.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.GrayBreakDownHeaderRowColor;

                _ws.Cells.Locked = false;
                _ws.Range["A1:A3"].EntireRow.Locked = true;
                _table.HeaderRowRange.Locked = true;
                _table.DataBodyRange.Locked = true;
                _table.TotalsRowRange.Locked = false;
                CostSumWritable.Locked = false;

                int costTypeCol = _table.ListColumns["Cost Type"].Index;
                int tblHeadRow = _table.HeaderRowRange.Row;

                Excel.Range manualETCCost = _table.ListColumns["Manual ETC Cost"].DataBodyRange;
                Excel.Range manualETCHours = _table.ListColumns["Manual ETC Hours"].DataBodyRange;
                Excel.Range manualETC_CST_HR = _table.ListColumns["Manual ETC CST/HR"].DataBodyRange;

                //Attempt to Resolve Enter of ZERO value
                manualETCHours.Value = "";
                manualETCCost.Value = "";
                manualETCHours.NumberFormat = HelperUI.NumberFormat;

                string[] _manualETCCost = manualETCCost.Address.Split('$');
                string[] _manualETCHours = manualETCHours.Address.Split('$');
                string[] _manualETC_CST_HR = manualETC_CST_HR.Address.Split('$');
                int row;
                for (int i = 1; i <= CostSumWritable.Rows.Count; i++)
                {
                    row = tblHeadRow + i;

                    if (_ws.Cells[row, costTypeCol].Value == "L")
                    {
                        _ws.Cells[row, manualETCCost.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                        _ws.Cells[row, manualETCCost.Column].Locked = true;
                        _ws.Cells[row, manualETCCost.Column].FormulaLocal = "=IF([@[Manual ETC Hours]]<>\"\",[@[Manual ETC Hours]]*[@[Manual ETC CST/HR]],\"\")";

                        // Alphanumeric entries red
                        Excel.FormatCondition manualETCHrs_bad = (Excel.FormatCondition)_ws.Cells[row, manualETCHours.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                  "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETCHours[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETCHours[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        manualETCHrs_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                        Excel.FormatCondition manualETC_CST_HR_bad = (Excel.FormatCondition)_ws.Cells[row, manualETC_CST_HR.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                           "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETC_CST_HR[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETC_CST_HR[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        manualETC_CST_HR_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                        Excel.FormatCondition manualETCHrs_manualETC_CST_HR_Cond = (Excel.FormatCondition)_ws.Cells.Range[_ws.Cells[row, manualETCHours.Column], _ws.Cells[row, manualETC_CST_HR.Column]].FormatConditions.Add(
                                                                    Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                    "=AND(IF(SUBSTITUTE($" + _manualETCHours[1] + "$" + row + ",\" \",\"\")<>\"\",TRUE,FALSE),NOT(ISERROR(VALUE(" + _manualETCHours[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        manualETCHrs_manualETC_CST_HR_Cond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
                    }
                    else
                    {
                        _ws.Cells[row, manualETCHours.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                        _ws.Cells[row, manualETCHours.Column].Locked = true;
                        _ws.Cells[row, manualETC_CST_HR.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                        _ws.Cells[row, manualETC_CST_HR.Column].Locked = true;

                        Excel.FormatCondition manualETCCost_BAD = (Excel.FormatCondition)_ws.Cells[row, manualETCCost.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                           "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETCCost[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETCCost[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        manualETCCost_BAD.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                        Excel.FormatCondition manualETCCostCond = (Excel.FormatCondition)_ws.Cells[row, manualETCCost.Column].FormatConditions.Add(
                                            Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                            "=AND(IF(SUBSTITUTE($" + _manualETCCost[1] + "$" + row + ",\" \",\"\")<>\"\",TRUE,FALSE),NOT(ISERROR(VALUE(" + _manualETCCost[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                        manualETCCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
                    }
                }

                _ws.Cells[_table.TotalsRowRange.Row, 1].Value = "Total";
                _ws.UsedRange.Font.Name = HelperUI.FontCalibri;
                _ws.Tab.Color = HelperUI.DataEntryColor;

                _table.ListColumns["Used"].DataBodyRange.EntireColumn.ColumnWidth = 3.50;
                _table.ListColumns["Parent Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 23.50;
                _table.ListColumns["Phase Code"].DataBodyRange.EntireColumn.ColumnWidth = 11.50;
                _table.ListColumns["Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 25.00;
                _table.ListColumns["Cost Type"].DataBodyRange.EntireColumn.ColumnWidth = 6.00;

                _table.ListColumns["Original Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Original Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Appr CO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Appr Co Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;
                _table.ListColumns["PCO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["PCO Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;
                _table.ListColumns["Curr Est Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Curr Est Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["JTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["MTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                _table.ListColumns["JTD Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["MTD Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
                _table.ListColumns["LM Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

                _table.ListColumns["Actual CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Total Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
                _table.ListColumns["Remaining Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
                _table.ListColumns["Remaining Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Remaining CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
                _table.ListColumns["Remaining Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
                _table.ListColumns["Manual ETC Hours"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
                _table.ListColumns["Manual ETC CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
                _table.ListColumns["Manual ETC Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Actual Cost > Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

                _table.ListColumns["Prev Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 11.70;
                _table.ListColumns["Prev Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 17.70;
                _table.ListColumns["Change in Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Change in Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["LM Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.50;
                _table.ListColumns["LM Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 16.75;
                _table.ListColumns["Change from LM Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 15.00;
                _table.ListColumns["Change from LM Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;

                _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.AutoFit();
                _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.AutoFit();

                HelperUI.PrintPageSetup(_ws);

            }
            catch (Exception ex) { throw new Exception("SetupSumTab: " + ex.Message); }
            finally
            {
                if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
                if (_table != null) Marshal.ReleaseComObject(_table);
                if (projectedCost != null) Marshal.ReleaseComObject(projectedCost);
                if (projectedMargin != null) Marshal.ReleaseComObject(projectedMargin);
            }
        }

        private void CostSum_ProjectedMargin_Fill()
        {
            Excel.Worksheet costSumSheet = null;
            try
            {
                costSumSheet = HelperUI.GetSheet(ETCOverviewActionPane.costSumSheet, false);

                if (costSumSheet != null)
                { 
                    _ws = HelperUI.GetSheet("-" + HelperUI.JobTrimDash(Job), true);
                    if (_ws != null)
                    {
                        string contractPRG_CV = _ws.Names.Item("ProjectedPRGContractValue").RefersToLocal;
                        if (contractPRG_CV != "")
                        {
                            string projtedCost = costSumSheet.Names.Item("NewProjectedCost")?.RefersToRange.AddressLocal.Split(':')[0];
                            contractPRG_CV = contractPRG_CV.Remove(0, 1);
                            costSumSheet.Names.Item("NewProjectedMargin").RefersToRange.FormulaLocal = "=IF(" + contractPRG_CV + "<>0,(" + contractPRG_CV + "-" + projtedCost + ")/" + contractPRG_CV + ",0)";
                            costSumSheet.Names.Item("NewProjectedMargin").RefersToRange.NumberFormat = HelperUI.PercentFormat;
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (costSumSheet != null) Marshal.ReleaseComObject(costSumSheet);
            }
        }

        private void SetSumTabFormulas(Excel.Worksheet _wsSum)
        {
            try
            {
                // Summary tab formulas
                _wsSum.ListObjects[1].ListColumns["Remaining CST/HR"].DataBodyRange.FormulaLocal =
                    "=IF([@[Remaining Hours]]<>\" \",IF([@[Remaining Hours]]>0,[@[Remaining Cost]]/[@[Remaining Hours]],\" \"),\" \")";

                _wsSum.ListObjects[1].ListColumns["Used"].DataBodyRange.FormulaLocal = "=IF(OR([@[Original Cost]] <> 0,[@[PCO Cost]]<> 0,[@[Curr Est Cost]]<>0,[@[JTD Actual Cost]]<>0,"
                    + "[@[Total Committed Cost]]<>0,[@[Remaining Cost]]<>0,[@[Remaining Committed Cost]]<>0,[@[Prev Projected Cost]]<>0,[@[LM Projected Cost]]<>0),\"Y\",\"N\")";

                _wsSum.ListObjects[1].ListColumns["Projected Hours"].DataBodyRange.FormulaLocal =
                 "=IF([@[Manual ETC Hours]]<>\"\",SUM(IF([@[JTD Actual Hours]]<>\"\",[@[JTD Actual Hours]],0),[@[Manual ETC Hours]]),SUM(IF([@[Remaining Hours]]<>\"\",[@[Remaining Hours]],0),IF([@[JTD Actual Hours]]<>\"\",[@[JTD Actual Hours]],0),IF([@[MTD Actual Hours]]<>\"\",-[@[MTD Actual Hours]],0)))";

                _wsSum.ListObjects[1].ListColumns["Projected Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Manual ETC Cost]]<>\"\",SUM(IF([@[JTD Actual Cost]]<>\"\",[@[JTD Actual Cost]],0),[@[Manual ETC Cost]]),SUM(IF([@[Remaining Cost]]<>\"\",[@[Remaining Cost]],0),IF([@[JTD Actual Cost]]<>\"\",[@[JTD Actual Cost]],0),IF([@[MTD Actual Cost]]<>\"\",-[@[MTD Actual Cost]],0)))";

                _wsSum.ListObjects[1].ListColumns["Actual Cost > Projected Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[JTD Actual Cost]]>[@[Projected Cost]],SUM([@[JTD Actual Cost]] - [@[Projected Cost]]),0)";

                //_wsSum.ListObjects[1].ListColumns["Manual ETC Cost"].DataBodyRange.FormulaLocal = "=[@[Manual ETC Hours]]*[@[Manual ETC CST/HR]]";

                // _wsSum.ListObjects[1].ListColumns["Over/Under Hours"].DataBodyRange.FormulaLocal = "=[@[Projected Hours]]-[@[LM Projected Hours]]";
                _wsSum.ListObjects[1].ListColumns["Over/Under Hours"].DataBodyRange.FormulaLocal = "=[@[Projected Hours]]-[@[Curr Est Hours]]";

                //_wsSum.ListObjects[1].ListColumns["Over/Under Cost"].DataBodyRange.FormulaLocal = "=[@[Projected Cost]]-[@[LM Projected Cost]]";
                _wsSum.ListObjects[1].ListColumns["Over/Under Cost"].DataBodyRange.FormulaLocal = "=[@[Projected Cost]]-[@[Curr Est Cost]]";

                _wsSum.ListObjects[1].ListColumns["Change in Hours"].DataBodyRange.FormulaLocal = "=[@[Projected Hours]]-[@[Prev Projected Hours]]";
                _wsSum.ListObjects[1].ListColumns["Change in Cost"].DataBodyRange.FormulaLocal = "=[@[Projected Cost]]-[@[Prev Projected Cost]]";
                _wsSum.ListObjects[1].ListColumns["Change from LM Projected Hours"].DataBodyRange.FormulaLocal = "=[@[Projected Hours]]-[@[LM Projected Hours]]";
                _wsSum.ListObjects[1].ListColumns["Change from LM Projected Cost"].DataBodyRange.FormulaLocal = "=[@[Projected Cost]]-[@[LM Projected Cost]]";

                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change from LM Projected Cost"]);

                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change from LM Projected Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change in Cost"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change in Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Over/Under Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Over/Under Cost"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Actual Cost > Projected Cost"]);

                HelperUI.GroupColumns(_wsSum, "Parent Phase Description", "Parent Phase Description");
                HelperUI.GroupColumns(_wsSum, "Original Hours", "PCO Cost");
                HelperUI.GroupColumns(_wsSum, "Prev Projected Hours", "LM Projected Cost");
                HelperUI.GroupColumns(_wsSum, "Manual ETC Hours", "Manual ETC Cost");
                HelperUI.GroupColumns(_wsSum, "MTD Actual Hours", "LM Actual Cost");
                HelperUI.GroupColumns(_wsSum, "Remaining Hours", "Remaining CST/HR", false);

                HelperUI.ProtectSheet(_wsSum, false, false);

            }
            catch (Exception e) { throw new Exception("SetSumTabFormulas: " + e.Message); }
        }

        private void SetupLaborTab(Excel.Worksheet _wsSum, Excel.Worksheet _wsNonLabor, Excel.Worksheet _wsLabor, out Excel.Range rngHeaders,
            out Excel.Range rngTotals, out Excel.Range rngStart, out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd)
        {
            Excel.Range rng = null;
            try
            {
                _wsLabor.Cells.Range["A1:S1"].Merge();
                _wsLabor.Cells.Range["A1"].Formula = ("Labor Worksheet: " + JobGetTitle.GetTitle(JCCo, Job)).ToUpper(); ;
                _wsLabor.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
                _wsLabor.Cells.Range["A1"].Font.Bold = true;

                table = _wsLabor.ListObjects[1];
                rngHeaders = table.HeaderRowRange;
                rngTotals = table.TotalsRowRange;
                
                HelperUI.FormatHoursCost(_wsLabor);

                // set user writable areas
                LaborEmpDescEdit = table.ListColumns["Employee ID"].DataBodyRange;
                LaborEmpDescEdit.NumberFormat = "General";
                LaborEmpDescEdit = _wsLabor.Range[LaborEmpDescEdit, table.ListColumns["Description"].DataBodyRange];
                LaborEmpDescEdit.Interior.Color = HelperUI.DataEntryColor;

                LaborRateEdit = table.ListColumns["Rate"].DataBodyRange;
                LaborRateEdit.EntireColumn.Style = HelperUI.CurrencyStyle;
                LaborRateEdit.Interior.Color = HelperUI.DataEntryColor;

                string phaseActualRate = "Phase Actual Rate";

                table.ListColumns[phaseActualRate].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns[phaseActualRate].Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                // MONTHS body
                int periodStart = table.ListColumns[phaseActualRate].Index + _offsetFromPhseActRate;
                int periodEnd = rngHeaders.Columns.Count;
                rngStart = _wsLabor.Cells[rngHeaders.Row + 1, periodStart];
                rngEnd = _wsLabor.Cells[rngTotals.Row - 1, periodEnd];

                LaborMonthsEdit = _wsLabor.Range[rngStart, rngEnd];
                LaborMonthsEdit.NumberFormat = HelperUI.GeneralFormat;
                LaborMonthsEdit.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                LaborMonthsEdit.Interior.Color = HelperUI.DataEntryColor;

                rngEnd = _wsLabor.Cells[rngTotals.Row, periodEnd];

                _wsLabor.Range[rngStart, rngEnd].NumberFormat = HelperUI.GeneralFormat;
                _wsLabor.Range[rngStart, rngEnd].HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                LaborConditionalFormat(_wsLabor, table, 1, LaborMonthsEdit.Rows.Count, rngHeaders);

                //Labor Tab Formulas that refer to the Summary Tab
                table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
                table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.FormulaLocal =
                     "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Hours],tbl" + contJobJectBatchSum_table.TableName +
                     "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName +
                     "[JTD Actual Hours],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\"))";

                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.FormulaLocal =
                        "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@Phase Code],tbl" +
                    contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[JTD Actual Cost],tbl" + 
                        contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\"))";

                column = table.ListColumns[phaseActualRate];
                column.DataBodyRange.FormulaLocal = "=AVERAGEIFS(tbl" + contJobJectBatchSum_table.TableName +
                                                    "[Actual CST/HR],tbl" + contJobJectBatchSum_table.TableName +
                                                    "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")";
                column = table.ListColumns["Remaining Hours"];

                // MONTHS (titles - readonly)
                cellStart = _wsLabor.Cells[rngHeaders.Row, table.ListColumns[phaseActualRate].Index + _offsetFromPhseActRate];
                cellEnd = _wsLabor.Cells[rngHeaders.Row, rngHeaders.Columns.Count];

                column.DataBodyRange.FormulaLocal = "=SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]])";

                table.ListColumns["Remaining Cost"].DataBodyRange.FormulaLocal = "=[@[Remaining Hours]]*[@Rate]";

                table.ListColumns["Previous Remaining Cost"].DataBodyRange.Value2 = table.ListColumns["Remaining Cost"].DataBodyRange.Value2;


                table.ListColumns["Used"].DataBodyRange.FormulaLocal =
                    "=IF([@Remaining Hours]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@Phase Actual Rate]<>0,\"Y\",IF([@Rate]<>0,\"Y\",IF([@[Budgeted Phase Hours Remaining]]<>0,\"Y\",IF([@Budgeted Phase Cost Remaining]<>0,\"Y\",\"N\"))))))";

                HelperUI.FormatHoursCost(_wsLabor);

                foreach (Excel.ListColumn col in table.ListColumns) col.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                string[] noSummation = new string[] { "Used", "Parent Phase Group", "Phase Code", "Phase Desc", "Employee ID", "Description",
                                                      "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", phaseActualRate, "Rate", "MTD Actual Cost", "MTD Actual Hours" };
                foreach (string col in noSummation)
                {
                    try
                    {
                        table.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    }
                    catch (Exception ex) { throw new Exception("SetupLaborTab: " + ex.Message); }
                }

                column = table.ListColumns["Variance"];
                column.DataBodyRange.FormulaLocal = "=[@[Remaining Cost]]-[@[Previous Remaining Cost]]";
                column.Range.Style = "Currency";

                HelperUI.ApplyVarianceFormat(column);

                table.HeaderRowRange.EntireRow.WrapText = true;
                table.HeaderRowRange.EntireRow.RowHeight = 30.00;
                table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                table.ListColumns["Used"].DataBodyRange.ColumnWidth = 3.50;
                table.ListColumns["Parent Phase Group"].DataBodyRange.ColumnWidth = 23.50;
                table.ListColumns["Phase Code"].DataBodyRange.ColumnWidth = 11.50;
                table.ListColumns["Phase Desc"].DataBodyRange.ColumnWidth = 25.00;

                table.ListColumns["Employee ID"].DataBodyRange.ColumnWidth = 8.00;
                table.ListColumns["Description"].DataBodyRange.ColumnWidth = 20.00;
                table.ListColumns["Remaining Hours"].DataBodyRange.ColumnWidth = 9.00;
                table.ListColumns["Remaining Cost"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.ColumnWidth = 15.50;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Previous Remaining Cost"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Variance"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns[phaseActualRate].DataBodyRange.ColumnWidth = 10.00;
                table.ListColumns["Rate"].DataBodyRange.ColumnWidth = 10.00;
                table.ListColumns["MTD Actual Cost"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns["MTD Actual Hours"].DataBodyRange.ColumnWidth = 10.00;

                HelperUI.AddFieldDesc(_wsLabor, "Parent Phase Group", "Parent phase code grouping (roll up code)");
                HelperUI.AddFieldDesc(_wsLabor, "Phase Code", "Phase Code");
                HelperUI.AddFieldDesc(_wsLabor, "Phase Desc", "PM Project phase description");
                HelperUI.AddFieldDesc(_wsLabor, "Remaining Cost", "Remaining Hours x Rate");
                HelperUI.AddFieldDesc(_wsLabor, "Employee ID", "Employee ID");
                HelperUI.AddFieldDesc(_wsLabor, "Description", "Description to held PM identify and track costs");
                HelperUI.AddFieldDesc(_wsLabor, "Remaining Hours", "Sum of periodic hour estimates");
                HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Hours Remaining", "Current Estimated Hours less Actual Hours (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Cost Remaining", "Current Estimated Cost less Actual Cost (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Previous Remaining Cost", "Projected Remaining Cost as of McKinstry Projections tool opening");
                HelperUI.AddFieldDesc(_wsLabor, "Variance", "Remaining Cost less Previous Remaining Cost");
                HelperUI.AddFieldDesc(_wsLabor, phaseActualRate, "Actual cost per hour (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Rate", "User Input for remaining. Default to Actual, or if null budgeted rate for PHASE CODE");
                HelperUI.AddFieldDesc(_wsLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current month (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "MTD Actual Hours", "Actual hours for the current month (at phase code level)");

                HelperUI.MergeLabel(_wsLabor, "Used", "Description", "Phase Detail", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Remaining Hours", "Remaining Cost", "Projected Remaining", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", "Budgeted Remaining", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Previous Remaining Cost", "Variance", "Previous", 1, 2);
                HelperUI.MergeLabel(_wsLabor, phaseActualRate, "Rate", "Rate", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "MTD Actual Cost", "MTD Actual hours", "MTD Actual", 1, 2);

                int c = table.ListColumns["Rate"].DataBodyRange.Column + 3;

                HelperUI.MergeLabel(_wsLabor, _wsLabor.Cells[rngHeaders.Row, c].Value, _wsLabor.Cells[rngHeaders.Row, table.ListColumns.Count].Value, "PROJECTED HOURS", 1, 2, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                rngStart = _wsLabor.Range[_wsLabor.Cells[rngHeaders.Row - 1, periodStart], _wsLabor.Cells[rngHeaders.Row - 1, table.ListColumns.Count]];
                rngStart.Merge();
                rngStart.Value = "Projected hours remaining on the project by week/month\nReminder: Current month should be MTD Actual Hours plus remaining hours for the month)";
                rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                rngStart.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                
                rngStart.Columns.ColumnWidth = 11;

                if (LaborPivot == "MTH")
                {
                    foreach (Excel.Range col in rngStart.Columns)
                    {
                        rng = _wsLabor.Cells[rngHeaders.Row, col.Column];
                        rng.AddComment(HelperUI.GetWeeksInMonth(DateTime.Parse(rng.Text), DayOfWeek.Sunday) + " Payroll Weeks");
                    }
                }

                rng = _wsLabor.Cells[rngHeaders.Row-2, table.ListColumns["MTD Actual Hours"].Index+1];
                string main = "PROJECTED HOURS";
                string sub = "(INCLUDE MTD ACTUAL HOURS IN CURRENT MONTH)";
                rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
                rng.Characters[Start: main.Length+1, Length: sub.Length+2].Font.Size = 8;

                _wsLabor.get_Range("A3", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                _wsLabor.get_Range("A3", Type.Missing).EntireRow.Hidden = true;

                HelperUI.GroupColumns(_wsLabor, "Parent Phase Group", null, true);
                HelperUI.GroupColumns(_wsLabor, "Budgeted Phase Hours Remaining", "Variance", true);
                HelperUI.GroupColumns(_wsLabor, "Employee ID", "Description", false);

                // HelperUI.SortAscending(_wsLabor, "Phase" "Cost Type");
                table.ListColumns["Rate"].DataBodyRange.EntireColumn.ColumnWidth = 12;

                _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].AddComment("If the phase code has projected remaining hours, previous remaining hours or a phase actual rate it will be shown on default.  Adjust column filter to see all rows.");
                _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;
                _wsLabor.Cells[table.TotalsRowRange.Row, 1].Value = "Total";

                // set key fields to read-only
                _wsLabor.Cells.Locked = false;
                _wsLabor.Range["A1:A3"].EntireRow.Locked = true;
                table.DataBodyRange.Locked = true;
                LaborEmpDescEdit.Locked = false;
                LaborRateEdit.Locked = false;
                LaborMonthsEdit.Locked = false;
                rngHeaders.Locked = true;
                rngTotals.Locked = false;
                HelperUI.ProtectSheet(_wsLabor);

                // Summary tab formulas that ref Labor tab
                _wsSum.ListObjects[1].ListColumns["Remaining Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
                _wsSum.ListObjects[1].ListColumns["Remaining Hours"].DataBodyRange.FormulaLocal =
                    "=IF([@[Cost Type]]=\"L\",SUMIFS(" + table.Name + "[Remaining Hours]," + table.Name + "[Phase Code],[@[Phase Code]]),\" \")";

                _wsSum.ListObjects[1].ListColumns["Remaining Cost"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                _wsSum.ListObjects[1].ListColumns["Remaining Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Cost Type]]=\"L\",SUMIFS(" + table.Name + "[Remaining Cost]," + table.Name + "[Phase Code],[@[Phase Code]]),SUMIFS("
                    + _wsNonLabor.ListObjects[1].Name + "[Remaining Cost]," + _wsNonLabor.ListObjects[1].Name + "[Phase Code],[@[Phase Code]]," + _wsNonLabor.ListObjects[1].Name + "[Cost Type],[@[Cost Type]]))";

                _wsLabor.UsedRange.Font.Name = HelperUI.FontCalibri;
                _wsLabor.Tab.Color = HelperUI.DataEntryColor;
                HelperUI.PrintPageSetup(_wsLabor);

            }
            catch (Exception e) { throw new Exception("SetupLaborTab: " + e.Message, e); }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
        }

            public void LaborConditionalFormat(Excel.Worksheet _wsLabor, Excel.ListObject table, int fromRowCnt, int toRowCnt, Excel.Range target)
            {
                string[] _varianceColA1 = table.ListColumns["Variance"].Range.Address.Split('$');
                string[] _rateColA1 = LaborRateEdit.Address.Split('$');
                string[] _remHrsColA1 = table.ListColumns["Remaining Hours"].Range.Address.Split('$');
                string[] _remCostA1 = table.ListColumns["Remaining Cost"].Range.Address.Split('$');
                string[] _empIDA1 = table.ListColumns["Employee ID"].Range.Address.Split('$');
                string[] _phaseA1 = table.ListColumns["Phase Code"].Range.Address.Split('$');

                int phseActualRateCol = table.ListColumns["Phase Actual Rate"].DataBodyRange.Column;
                int budgetedHoursCol = table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.Column;
                int budgetedCostCol = table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Column;
                int MTDActualCost = table.ListColumns["MTD Actual Cost"].DataBodyRange.Column;
                int MTDActualHrs = table.ListColumns["MTD Actual Hours"].DataBodyRange.Column;
                int empIDCol = table.ListColumns["Employee ID"].DataBodyRange.Column;

                string phseSameAsAbove = "";
                string phseSameAsBelow = "";
                string varianceNotZero = "";
                int rowNum;
                int periodStart = MTDActualHrs + 1;
                int periodEnd = table.ListColumns.Count;

                for (int i = fromRowCnt; i <= toRowCnt; i++)
                {
                    rowNum = target.Row + i;
                    varianceNotZero = "$" + _varianceColA1[1] + "$" + rowNum + " <> 0";

                    // alphanumeric bright red highlight
                    for (int col = periodStart; col <= periodEnd; col++)
                    {
                        Excel.Range cell = _wsLabor.Cells[rowNum, col];
                        Excel.FormatCondition cell_bad = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                  "=ISERROR(VALUE(IF(SUBSTITUTE(" + cell.AddressLocal + ",\" \",\"\")=\"\",0,VALUE(" + cell.AddressLocal + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        cell_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                    }

                    // highlight row when there's a variance |OR| variance = 0 rate = 0 but rem hours not zero
                    Excel.Range rngRow = _wsLabor.Range[_wsLabor.Cells[rowNum, periodStart], _wsLabor.Cells[rowNum, periodEnd]];
                    Excel.FormatCondition monthEditCond = (Excel.FormatCondition)rngRow.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                             "=OR(" + varianceNotZero + ", AND($" + _varianceColA1[1] + "$" + rowNum + " = 0, $" + _remHrsColA1[1] + "$" + rowNum + " <> 0, $" + _rateColA1[1] + "$" + rowNum + " = 0))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    monthEditCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
                    monthEditCond.Font.Bold = true;

                    // Rate alphanumeric bright red highlight
                    Excel.Range rate = _wsLabor.Cells[rowNum, LaborRateEdit.Column];
                    Excel.FormatCondition rate_bad = (Excel.FormatCondition)rate.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(IF(SUBSTITUTE($" + _rateColA1[1] + "$" + rowNum + ",\" \",\"\")=\"\",0,VALUE(" + _rateColA1[1] + "$" + rowNum + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    rate_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                    // Rate red highlight when hours entered but no rate given
                    Excel.FormatCondition rateCond = (Excel.FormatCondition)rate.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                     "=AND($" + _rateColA1[1] + rowNum + " = 0," + "$" + _remHrsColA1[1] + rowNum + " > 0 )"
                                                     , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    rateCond.Interior.Color = HelperUI.RedNegColor;
                    rateCond.Font.Bold = true;

                    // Rate blue highlight when there's a variance
                    Excel.FormatCondition rateVariance = (Excel.FormatCondition)rate.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                          Type.Missing, "=AND(" + varianceNotZero + ", $" + _remCostA1[1] + rowNum + " <> 0)",  Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    rateVariance.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
                    rateVariance.Font.Bold = true;

                    // Alphanumerics red highlight
                    Excel.Range employeeID = _wsLabor.Cells[rowNum, empIDCol];
                    Excel.FormatCondition employeeID_bad = (Excel.FormatCondition)employeeID.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(IF(SUBSTITUTE($" + _empIDA1[1] + "$" + rowNum + ",\" \",\"\")=\"\",0,VALUE(" + _empIDA1[1] + "$" + rowNum + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    employeeID_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                    // if phase code = phase code above it, LightGray out 'Phase actual Rate', remaining phase: 'Budgeted hours' / 'budgeted cost' / 'MTD Actual Cost' / 'MTD Actual Hours'
                    phseSameAsAbove = "=$" + _phaseA1[1] + rowNum + " = " + "$" + _phaseA1[1] + (rowNum - 1);
                    phseSameAsBelow = "=$" + _phaseA1[1] + rowNum + " = " + "$" + _phaseA1[1] + (rowNum + 1);

                    Excel.Range phaseActualRateCol = _wsLabor.Cells[rowNum, phseActualRateCol];
                    Excel.FormatCondition phaseActualRateCond = (Excel.FormatCondition)phaseActualRateCol.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsAbove,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    Excel.FormatCondition phaseActualRateCond2 = (Excel.FormatCondition)phaseActualRateCol.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsBelow,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    phaseActualRateCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    phaseActualRateCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range budgetedHours = _wsLabor.Cells[rowNum, budgetedHoursCol];
                    Excel.FormatCondition budgetedHoursCond = (Excel.FormatCondition)budgetedHours.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsAbove,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    Excel.FormatCondition budgetedHoursCond2 = (Excel.FormatCondition)budgetedHours.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsBelow,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    budgetedHoursCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    budgetedHoursCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range budgetedCost = _wsLabor.Cells[rowNum, budgetedCostCol];
                    Excel.FormatCondition budgetedCostCond = (Excel.FormatCondition)budgetedCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsAbove,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    Excel.FormatCondition budgetedCostCond2 = (Excel.FormatCondition)budgetedCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsBelow,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    budgetedCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    budgetedCostCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range mtdActualCost = _wsLabor.Cells[rowNum, MTDActualCost];
                    Excel.FormatCondition mtdActualCostCond = (Excel.FormatCondition)mtdActualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsAbove,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    Excel.FormatCondition mtdActualCostCond2 = (Excel.FormatCondition)mtdActualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsBelow,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    mtdActualCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    mtdActualCostCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range mtdActualHrs = _wsLabor.Cells[rowNum, MTDActualHrs];
                    Excel.FormatCondition mtdActualHrsCond = (Excel.FormatCondition)mtdActualHrs.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsAbove,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    Excel.FormatCondition mtdActualHrsCond2 = (Excel.FormatCondition)mtdActualHrs.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, phseSameAsBelow,
                                                       Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    mtdActualHrsCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    mtdActualHrsCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                }
            }

        private void SetupNonLaborTab(Excel.Worksheet _wsNonLabor, out Excel.Range rngHeaders, out Excel.Range rngTotals, out Excel.Range rngStart, 
            out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd, out string remainingCost)
        {
            _wsNonLabor.Cells.Locked = false;
            Excel.Range rng = null;
            try
            {
                _wsNonLabor.Cells.Range["A1:P1"].Merge();
                _wsNonLabor.Cells.Range["A1"].Formula = ("Non Labor Worksheet: " + JobGetTitle.GetTitle(JCCo, Job)).ToUpper(); ;
                _wsNonLabor.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
                _wsNonLabor.Cells.Range["A1"].Font.Bold = true;

                table = _wsNonLabor.ListObjects[1];
                rngHeaders = _wsNonLabor.ListObjects[1].HeaderRowRange;
                rngTotals = _wsNonLabor.ListObjects[1].TotalsRowRange;

                // set user writable area
                NonLaborWritable1 = table.ListColumns["Description"].DataBodyRange;
                NonLaborWritable1.Interior.Color = HelperUI.DataEntryColor;

                remainingCost = "Remaining Cost";
                column = table.ListColumns[remainingCost];

                //HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns[keyBeforeDataEntry].Index+1].Value);
                table.ListColumns[remainingCost].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                // months (titles - readonly)
                cellStart = _wsNonLabor.Cells[rngHeaders.Row, column.Index + _offsetFromRemCost];
                cellEnd = _wsNonLabor.Cells[rngHeaders.Row, rngHeaders.Columns.Count];

                column.DataBodyRange.FormulaLocal = "=SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]])";
                column.Range.Style = HelperUI.CurrencyStyle;

                // months (body)
                rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, column.Index + _offsetFromRemCost];
                rngEnd = _wsNonLabor.Cells[rngTotals.Row - 1, rngHeaders.Columns.Count];

                NonLaborWritable2 = _wsNonLabor.Range[rngStart, rngEnd];
                NonLaborWritable2.Cells.Style = HelperUI.CurrencyStyle;
                NonLaborWritable2.Interior.Color = HelperUI.DataEntryColor;
                NonLaborWritable2.Columns.EntireColumn.ColumnWidth = 14.57;

                int periodStart = NonLaborConditionalFormat(_wsNonLabor, table, 1, NonLaborWritable2.Rows.Count, rngHeaders);
                table.ListColumns["MTD Actual Cost"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

                table.ListColumns["Previous Remaining Cost"].DataBodyRange.Value2 = column.DataBodyRange.Value2;
                table.ListColumns["Previous Remaining Cost"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Previous Remaining Cost"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                // Insert formulas & format
                column = table.ListColumns["Variance"];
                table.ListColumns["Variance"].DataBodyRange.FormulaLocal = "=[@[Remaining Cost]]-[@[Previous Remaining Cost]]";
                table.ListColumns["Variance"].Range.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Variance"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                table.ListColumns["Variance"].Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                table.ListColumns["Used"].DataBodyRange.FormulaLocal = "=IF([@[Remaining Cost]]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@[Budgeted Phase Cost Remaining]]<>0,\"Y\",IF([@[Phase Open Committed]]<>0,\"Y\",\"N\"))))";

                //Formulas that Point to the Summary Tab
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.FormulaLocal =
                    "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
                    contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]])) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[JTD Actual Cost],tbl" +
                    contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]]))";

                table.ListColumns["Phase Open Committed"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Phase Open Committed"].DataBodyRange.FormulaLocal =
                    "=SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Remaining Committed Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
                    contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]])";

                HelperUI.ApplyVarianceFormat(column);

                table.HeaderRowRange.EntireRow.RowHeight = 30.00;
                table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                table.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                table.ListColumns["Used"].DataBodyRange.ColumnWidth = 3.50;
                table.ListColumns["Parent Phase Group"].DataBodyRange.ColumnWidth = 23.50;
                table.ListColumns["Phase Code"].DataBodyRange.ColumnWidth = 11.50;
                table.ListColumns["Phase Desc"].DataBodyRange.ColumnWidth = 25.00;
                table.ListColumns["Cost Type"].DataBodyRange.ColumnWidth = 6.50;
                table.ListColumns["Description"].DataBodyRange.ColumnWidth = 20.00;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Previous Remaining Cost"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns["MTD Actual Cost"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns["Variance"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Phase Open Committed"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns[remainingCost].DataBodyRange.ColumnWidth = 14.75;

                HelperUI.AddFieldDesc(_wsNonLabor, "Used", "Used");
                HelperUI.AddFieldDesc(_wsNonLabor, "Parent Phase Group", "Parent phase code grouping (roll up code)");
                HelperUI.AddFieldDesc(_wsNonLabor, "Phase Code", "Phase Code");
                HelperUI.AddFieldDesc(_wsNonLabor, "Phase Desc", "PM Project phase description");
                HelperUI.AddFieldDesc(_wsNonLabor, "Cost Type", "Cost Type");
                HelperUI.AddFieldDesc(_wsNonLabor, "Description", "Description to held PM identify and track costs");
                HelperUI.AddFieldDesc(_wsNonLabor, "Budgeted Phase Cost Remaining", "Budgeted Remaining Cost (at phase code level)");
                HelperUI.AddFieldDesc(_wsNonLabor, "Previous Remaining Cost", "Projected Remaining Cost as of McKinstry Projections tool opening");
                HelperUI.AddFieldDesc(_wsNonLabor, "Variance", "Remaining Cost less Previous Remaining Cost");
                HelperUI.AddFieldDesc(_wsNonLabor, "Remaining Cost", "Sum of monthly cost estimates");
                HelperUI.AddFieldDesc(_wsNonLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current month (at phase code level)");
                HelperUI.AddFieldDesc(_wsNonLabor, "Phase Open Committed", "Open committed cost aka Remaining Committed cost (at phase code level)");

                HelperUI.MergeLabel(_wsNonLabor, _wsNonLabor.Cells[rngHeaders.Row, periodStart].Value, _wsNonLabor.Cells[rngHeaders.Row, table.ListColumns.Count].Value, "PROJECTED COST", horizAlign: Excel.XlHAlign.xlHAlignLeft);

                rngStart = _wsNonLabor.Range[_wsNonLabor.Cells[rngHeaders.Row - 1, periodStart], _wsNonLabor.Cells[rngHeaders.Row - 1, table.ListColumns.Count]];
                rngStart.Merge();
                rngStart.Value = "Projected cost remaining on the project by month\nReminder: Current month should be MTD Actual Costs plus remaining projected costs for the month)";
                rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                rngStart.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;

                rng = _wsNonLabor.Cells[rngHeaders.Row - 2, table.ListColumns["MTD Actual Cost"].Index + 1];
                string main = "PROJECTED COST";
                string sub = "(INCLUDE MTD ACTUAL COST IN CURRENT MONTH)";
                rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
                rng.Characters[Start: main.Length + 1, Length: sub.Length + 2].Font.Size = 8;

                _wsNonLabor.Range[_wsNonLabor.Cells[rngHeaders.Row + 1, periodStart], _wsNonLabor.Cells[rngTotals.Row - 1, table.ListColumns.Count]].Interior.Color = HelperUI.DataEntryColor;

                HelperUI.MergeLabel(_wsNonLabor, "Used", "Description", "Phase Detail");
                HelperUI.MergeLabel(_wsNonLabor, "Budgeted Phase Cost Remaining", remainingCost, "Information");
                HelperUI.MergeLabel(_wsNonLabor, "MTD Actual Cost", "MTD Actual Cost", "MTD ACTUAL");

                _wsNonLabor.get_Range("A3", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                _wsNonLabor.get_Range("A3", Type.Missing).EntireRow.Hidden = true;

                HelperUI.SortAscending(_wsNonLabor, "Phase Code", "Cost Type");

                HelperUI.GroupColumns(_wsNonLabor, "Parent Phase Group", null, true);
                HelperUI.GroupColumns(_wsNonLabor, "Budgeted Phase Cost Remaining", "Variance", true);

                _wsNonLabor.UsedRange.Font.Name = HelperUI.FontCalibri;
                table.HeaderRowRange.EntireRow.WrapText = true;
                table.HeaderRowRange.EntireRow.AutoFit();

                _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].AddComment("If the phase code has no budgeted, MTD actual or projected cost, the row is hidden.  Adjust column filder to see all rows.");
                _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;

                HelperUI.PrintPageSetup(_wsNonLabor);

                // set key fields to read-only
                _wsNonLabor.Cells.Range["A1:A3"].EntireRow.Locked = true;
                table.DataBodyRange.Locked = true;
                table.TotalsRowRange.Locked = false;
                table.ListColumns["Description"].DataBodyRange.Locked = false;
                NonLaborWritable1.Locked = false;
                NonLaborWritable2.Locked = false;
                rngHeaders.Locked = true;
                HelperUI.ProtectSheet(_wsNonLabor);

                _wsNonLabor.Tab.Color = HelperUI.DataEntryColor;

            }
            catch (Exception e) {throw new Exception("SetupNonLaborTab: " + e.Message);}
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
        }

            public int NonLaborConditionalFormat(Excel.Worksheet _wsNonLabor, Excel.ListObject table, int fromRowCnt, int toRowCnt, Excel.Range target)
            {
                string[] _varianceCol = table.ListColumns["Variance"].Range.Address.Split('$');
                string[] _phase = table.ListColumns["Phase Code"].Range.Address.Split('$');
                string[] _costtype = table.ListColumns["Cost Type"].Range.Address.Split('$');
                int budgetedRemainingCostCol = table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Column;
                int phaseOpenCommittedCol = table.ListColumns["Phase Open Committed"].DataBodyRange.Column;
                int MTDActualCost = table.ListColumns["MTD Actual Cost"].DataBodyRange.Column;
                int periodStart = MTDActualCost + 1;
                int periodEnd = table.ListColumns.Count;
                int cellAbove;
                int cellBelow;
                int rowNum;
                for (int i = fromRowCnt; i <= toRowCnt; i++)
                {
                    rowNum = target.Row + i;

                    // alphanumeric bright red highlight
                    for (int col = periodStart; col <= periodEnd; col++)
                    {
                        Excel.Range cell = _wsNonLabor.Cells[rowNum, col];
                        Excel.FormatCondition cell_bad = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                  "=ISERROR(VALUE(IF(SUBSTITUTE(" + cell.AddressLocal + ",\" \",\"\")=\"\",0,VALUE(" + cell.AddressLocal + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        cell_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                    }

                    Excel.Range periodStart_to_End = _wsNonLabor.Range[_wsNonLabor.Cells[rowNum, periodStart], _wsNonLabor.Cells[rowNum, periodEnd]];
                    Excel.FormatCondition editableAreaCond = (Excel.FormatCondition)periodStart_to_End.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                              Type.Missing, "=$" + _varianceCol[1] + "$" + rowNum + " <> 0", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    editableAreaCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);

                    cellAbove = rowNum - 1;
                    cellBelow = rowNum + 1;
                    // if phase code = phase code above it, LightGray out 'Budgeted Remaining Cost' and 'PHASE Open Committed'
                    Excel.Range budgetedRemainingCost = _wsNonLabor.Cells[rowNum, budgetedRemainingCostCol];
                    Excel.FormatCondition budgetedRemainingCostCond = (Excel.FormatCondition)budgetedRemainingCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellAbove +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellAbove + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    Excel.FormatCondition budgetedRemainingCostCond2 = (Excel.FormatCondition)budgetedRemainingCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellBelow +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellBelow + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    budgetedRemainingCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    budgetedRemainingCostCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range phaseOpenCommitted = _wsNonLabor.Cells[rowNum, phaseOpenCommittedCol];
                    Excel.FormatCondition phaseOpenCommittedCond = (Excel.FormatCondition)phaseOpenCommitted.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellAbove +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellAbove + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    Excel.FormatCondition phaseOpenCommittedCond2 = (Excel.FormatCondition)phaseOpenCommitted.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellBelow +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellBelow + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    phaseOpenCommittedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    phaseOpenCommittedCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);

                    Excel.Range MTDactualCost = _wsNonLabor.Cells[rowNum, MTDActualCost];
                    Excel.FormatCondition MTDactualCostCond = (Excel.FormatCondition)MTDactualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellAbove +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellAbove + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    Excel.FormatCondition MTDactualCostCond2 = (Excel.FormatCondition)MTDactualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                       Type.Missing, "=AND($" + _phase[1] + rowNum + " = $" + _phase[1] + cellBelow +
                                                                      ",$" + _costtype[1] + rowNum + " = $" + _costtype[1] + cellBelow + ")", Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                    MTDactualCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    MTDactualCostCond2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                }

                return periodStart;
            }

        private void SetupRevTab(Excel.Worksheet _ws, string sheetName)
        {
            Excel.Range marginTotal = null;
            Excel.Range batchDateCreated = null;
            Excel.Range projectedContractHeader = null;
            Excel.Range projectedContract = null;
            try
            {
                _ws = HelperUI.GetSheet(sheetName, false);
                _table = _ws.ListObjects[1];
                _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                _ws.Cells.Range["A1"].Formula = JobGetTitle.GetTitle(JCCo, Contract) + " Revenue Worksheet";
                _ws.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
                _ws.Cells.Range["A1"].Font.Bold = true;
                _ws.Cells.Range["A1:N1"].Merge();

                _ws.Cells.Range["A2"].Formula = "Batch Created on: ";
                _ws.Cells.Range["A2:C2"].Font.Color = HelperUI.SoftBlackHeaderFontColor;
                _ws.Cells.Range["C2"].NumberFormat = "d-mmm-yyyy h:mm AM/PM";
                _ws.Cells.Range["C2"].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                _ws.Cells.Range["C2"].Formula = revBatchDateCreated;
                _ws.Cells.Range["C2"].AddComment("All times Pacific");
                batchDateCreated = _ws.Cells.Range["A2:C2"];

                Excel.FormatCondition batchDateCreatedCond = (Excel.FormatCondition)batchDateCreated.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, "=IF(" + _ws.Cells.Range["C2"].Address + "=\"\",\"\"," + _ws.Cells.Range["C2"].Address + "< TODAY())",
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                batchDateCreatedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                batchDateCreatedCond.Font.Color = HelperUI.WhiteFontColor;
                batchDateCreatedCond.Font.Bold = true;

                int aboveHeaders = _table.HeaderRowRange.Row - 3;
                int currContract = _table.ListColumns["Current Contract"].Index;
                projectedContract = _table.ListColumns["Projected Contract"].DataBodyRange;
                projectedContract.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                projectedContract.Font.Color = HelperUI.WhiteFontColor;
                projectedContract.Font.Bold = true;
                projectedContract.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                projectedContract.Borders.Weight = Excel.XlBorderWeight.xlThin;
                projectedContract.Borders.Color = HelperUI.GrayBreakDownHeaderRowColor;
                projectedContract.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
                projectedContract.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.GrayBreakDownHeaderRowColor;

                projectedContractHeader = _ws.Cells.Range[_ws.Cells[aboveHeaders, currContract], _ws.Cells[aboveHeaders, projectedContract.Column]];
                projectedContractHeader.Font.Color = HelperUI.WhiteFontColor;
                projectedContractHeader.Font.Bold = true;
                projectedContractHeader.Font.Size = HelperUI.TwelveFontSizeHeader;
                projectedContractHeader.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                _ws.Cells[aboveHeaders, currContract].Formula = "New Projected Contract ";
                _ws.Cells[aboveHeaders, currContract].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                _ws.Cells[aboveHeaders, currContract + 1].Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                _ws.Cells[aboveHeaders, currContract + 1].Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
                _ws.Cells[aboveHeaders, projectedContract.Column].Style = HelperUI.CurrencyStyle;
                _ws.Cells[aboveHeaders, projectedContract.Column].FormulaLocal = "=SUM("+ projectedContract.Address + ")"; 

                _ws.UsedRange.Font.Name = HelperUI.FontCalibri;

                RevWritable2 = _table.ListColumns["Margin Seek"].DataBodyRange;
                RevWritable2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.SoftBeige);

                _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.Interior.Color = HelperUI.DataEntryColor; //light yellow

                projectedContract.FormulaLocal = "=[Current Contract]+[Unbooked Contract Adjustment]";
                projectedContract.Style = HelperUI.CurrencyStyle;

                _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.FormulaLocal = "=IF([Projected Contract]<=0,\"0\",([Projected Contract]-[Margin Seek])/[Projected Contract])";
                _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.NumberFormat = "###,##.##%";

                int col = _table.ListColumns["Projected Contract Item Margin %"].Index;
                int row = _table.TotalsRowRange.Row;
                marginTotal = _ws.Cells[row, col];
                marginTotal.FormulaLocal = "=IF(" + _table.Name + "[[#Totals],[Projected Contract]]<=0,\"0\",(" + _table.Name + "[[#Totals],[Projected Contract]]-" + _table.Name +
                                                                 "[[#Totals],[Margin Seek]])/" + _table.Name + "[[#Totals],[Projected Contract]])";
                marginTotal.NumberFormat = HelperUI.PercentFormat;

                RevWritable1 = _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange;

                string[] _unbookedCol = RevWritable1.Address.Split('$');
                string[] projecteContractCol = projectedContract.Address.Split('$');
                string[] postedProjectedCostCol = _table.ListColumns["Posted Projected Cost"].DataBodyRange.Address.Split('$');
                string[] prevprojContractCol = _table.ListColumns["Previous Projected Contract"].DataBodyRange.Address.Split('$');

                for (int i = 1; i <= RevWritable1.Rows.Count; i++)
                {
                    int r = _table.HeaderRowRange.Row + i;

                    Excel.FormatCondition unbookedCond = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                            Type.Missing, "=$" + projecteContractCol[1] + "$" + r + " <> $" + prevprojContractCol[1] + "$" + r , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    unbookedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);

                    // Alphanumerics bad entries red
                    Excel.FormatCondition unbookedBad = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(SUBSTITUTE($" + _unbookedCol[1] + "$" + r + ",\" \",\"\")))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    unbookedBad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                    Excel.FormatCondition marginSeekBad = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable2.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(SUBSTITUTE($" + _unbookedCol[1] + "$" + r + ",\" \",\"\")))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    marginSeekBad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                }

                string[] applySumTotal = { "Current Contract", "Future CO", "Unbooked Contract Adjustment", "Previous Projected Contract", "Projected Contract", "Margin Seek" };

                foreach (string colName in applySumTotal)
                {
                    _table.ListColumns[colName].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                }

                _table.ListColumns["JC Dept"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                _table.ListColumns["Contract Item"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                _table.TotalsRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                _table.HeaderRowRange.EntireRow.RowHeight = 30.00;
                _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                
                _table.ListColumns["PRG"].DataBodyRange.ColumnWidth = 9.00;
                _table.ListColumns["PRG Description"].DataBodyRange.ColumnWidth = 20.00;
                _table.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 19.43;
                _table.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 25.00;
                _table.ListColumns["Contract Item"].DataBodyRange.ColumnWidth = 12.00;
                _table.ListColumns["Description"].DataBodyRange.ColumnWidth = 25.00;
                _table.ListColumns["Future CO"].DataBodyRange.ColumnWidth = 14.75;

                _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.ColumnWidth = 16.75;
                _table.ListColumns["Current Contract"].DataBodyRange.ColumnWidth = 15.75;
                _table.ListColumns["Previous Projected Contract"].DataBodyRange.ColumnWidth = 15.75;
                projectedContract.ColumnWidth = 15.75;
                _table.ListColumns["Posted Projected Cost"].DataBodyRange.ColumnWidth = 16.00;
                _table.ListColumns["Margin Seek"].DataBodyRange.ColumnWidth = 16.00;
                _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.ColumnWidth = 15.14;
                
                HelperUI.MergeLabel(_ws, "PRG", "Description", "Details");
                HelperUI.MergeLabel(_ws, "Future CO", "Unbooked Contract Adjustment", "Changes");
                HelperUI.MergeLabel(_ws, "Current Contract", "Projected Contract", "Contract");
                HelperUI.MergeLabel(_ws, "Posted Projected Cost", "Margin Seek", "Cost");
                HelperUI.MergeLabel(_ws, "Projected Contract Item Margin %", "Projected Contract Item Margin %", "Margin");

                HelperUI.AddFieldDesc(_ws, "PRG", "Project Revenue Group (Project Number) linked to the contract item");
                HelperUI.AddFieldDesc(_ws, "PRG Description", "Project Description");
                HelperUI.AddFieldDesc(_ws, "JC Dept", "Job cost department");
                HelperUI.AddFieldDesc(_ws, "JC Dept Description", "Department description");
                HelperUI.AddFieldDesc(_ws, "Contract Item", "Contract Item");
                HelperUI.AddFieldDesc(_ws, "Description", "Contract Item Description");
                HelperUI.AddFieldDesc(_ws, "Future CO", "Change orders in Viewpoint that have not been interfaced (reference only)");
                HelperUI.AddFieldDesc(_ws, "Unbooked Contract Adjustment", "Anticipated changes in contract value (include Future CO if applicable)");
                HelperUI.AddFieldDesc(_ws, "Current Contract", "Current contract value including interfaced change orders");
                HelperUI.AddFieldDesc(_ws, "Previous Projected Contract", "Projected contract item value from last revenue projection");
                HelperUI.AddFieldDesc(_ws, "Projected Contract", "Projected contract value (revenue) at contract completion");
                HelperUI.AddFieldDesc(_ws, "Posted Projected Cost", "Sum of all posted projected cost for phase codes mapping to this contract item");
                HelperUI.AddFieldDesc(_ws, "Margin Seek", "See comment");
                HelperUI.AddFieldDesc(_ws, "Projected Contract Item Margin %", "Projected contract value compared to posted projected cost or margin seek at an item level");

                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].AddComment("Scratch pad to calculate margin adjustments. NOTE: This will not update your Cost Projections or Saved once the Revenue batch is posted");
                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].Comment.Shape.TextFrame.AutoSize = true;

                _ws.get_Range("A4", Type.Missing).EntireRow.Group();
                _ws.get_Range("A4", Type.Missing).EntireRow.Hidden = true;

                _table.ListColumns["Previous Projected Contract"].DataBodyRange.EntireColumn.AutoFit();

                HelperUI.GroupColumns(_ws, "Margin Seek", "Margin Seek", true);

                HelperUI.PrintPageSetup(_ws);

                _table.ShowTotals = true;
                _ws.UsedRange.Locked = true;
                _table.TotalsRowRange.Locked = false;
                _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.Locked = false;
                _table.ListColumns["Margin Seek"].DataBodyRange.Locked = false;
                HelperUI.ProtectSheet(_ws, false, false);
                _ws.Tab.Color = HelperUI.DataEntryColor;

                _ws.ListObjects[1].HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
            }
            catch (Exception ex) { throw new Exception("SetupRevTab: " + ex.Message); }
            finally
            {
                if (_table != null) Marshal.ReleaseComObject(_table);
                if (marginTotal != null) Marshal.ReleaseComObject(marginTotal);
                if (projectedContractHeader != null) Marshal.ReleaseComObject(projectedContractHeader);
                if (projectedContract != null) Marshal.ReleaseComObject(projectedContract);
                if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
            }
        }

        #endregion


        #region SAVE TO VIEWPOINT

        private bool InsertCostProjectionsIntoJCPD()
        {
            if (isInserting) return false;
            isInserting = true;
            int insertedRows = 0;
            int totalRows = 0;
            bool successInsert = false;

            object cellVal = null;
            Dictionary<string, Type> columns = null;
            DataTable dtUnpivotedProj = null;
            DataColumn Column;
            DataRow Row;
            string[] projSheetNames = { nonLaborSheet, laborSheet };
            StringBuilder sb = new StringBuilder();
            int nonlaborCount = 0;
            int laborCount = 0;
            byte costtype = 0x1;
            uint detSeq = 0;  // increments by 1 for each row

            if (JCCo == 0)
            {
                if (!IsValidContract()) return false;
            }
            List<int> manualETC_RowsWithValues = null;
            int visibleRows = 0;

            try
            {
                _ws = HelperUI.GetSheet(laborSheet, false);
                Excel.ListObject xltable = _ws.ListObjects[1];
                int used = xltable.ListColumns["Used"].DataBodyRange.Column;

                HelperUI.Alphanumeric_Check(xltable, "Employee ID", used);
                HelperUI.Alphanumeric_Check(xltable, "Rate", used);

                int periodStart = xltable.ListColumns["MTD Actual Hours"].DataBodyRange.Column + 1;
                int periodEnd = xltable.HeaderRowRange.Columns.Count;

                for (int i = periodStart; i <= periodEnd; i++)
                {
                    HelperUI.Alphanumeric_Check(xltable, xltable.ListColumns[i].Name, used);
                }

                _ws = HelperUI.GetSheet(nonLaborSheet, false);
                xltable = _ws.ListObjects[1];
                used = xltable.ListColumns["Used"].DataBodyRange.Column;
                periodStart = xltable.ListColumns["MTD Actual Cost"].DataBodyRange.Column + 1;
                periodEnd = xltable.HeaderRowRange.Columns.Count;

                for (int i = periodStart; i <= periodEnd; i++)
                {
                    HelperUI.Alphanumeric_Check(xltable, xltable.ListColumns[i].Name, used);
                }

                _ws = HelperUI.GetSheet(costSumSheet, false);
                xltable = _ws.ListObjects[1];
                used = xltable.ListColumns["Used"].DataBodyRange.Column;

                HelperUI.Alphanumeric_Check(xltable, "Manual ETC Hours", used);
                HelperUI.Alphanumeric_Check(xltable, "Manual ETC CST/HR", used);
                HelperUI.Alphanumeric_Check(xltable, "Manual ETC Cost", used);
                
                Alphanumeric_AND_ETCOverrideCount_AND_JTDActCostIsGreaterThanProjectedCost_Check(out visibleRows, out manualETC_RowsWithValues);

                // Define SQL Table Schema
                dtUnpivotedProj = new DataTable("JCPD");
                columns = new Dictionary<string, Type>
                            { {"Co",typeof(byte)}, {"DetSeq",typeof(uint) }, {"Mth",typeof(DateTime)}, {"BatchId",typeof(uint)}, {"BatchSeq",typeof(uint)}, {"Source",typeof(string)},
                            {"JCTransType",typeof(string)}, {"TransType",typeof(char)}, {"ResTrans",typeof(uint)}, {"Job",typeof(string)}, {"PhaseGroup",typeof(byte)}, {"Phase",typeof(string)},
                            {"CostType",typeof(byte)}, {"BudgetCode",typeof(string)}, {"EMCo",typeof(byte)}, {"Equipment",typeof(string)}, {"PRCo",typeof(byte)}, {"Craft",typeof(string)},
                            {"Class",typeof(string)}, {"Employee",typeof(uint)}, {"Description",typeof(string)}, {"DetMth",typeof(DateTime)}, {"FromDate",typeof(DateTime)},
                            {"ToDate",typeof(DateTime)}, {"Quantity",typeof(decimal)}, {"Units",typeof(decimal)}, {"UM",typeof(string)}, {"UnitHours",typeof(decimal)}, {"Hours",typeof(decimal)},
                            {"Rate",typeof(decimal)}, {"UnitCost",typeof(decimal)}, {"Amount",typeof(decimal)}, {"Notes",typeof(string)} };

                // Create the table
                foreach (KeyValuePair<string, Type> c in columns)
                {
                    Column = new DataColumn(c.Key);
                    Column.DataType = c.Value;
                    dtUnpivotedProj.Columns.Add(Column);
                }

                foreach (string sheetName in projSheetNames)
                {
                    _ws = HelperUI.GetSheet(sheetName, false);

                    if (_ws == null) throw new Exception("Could not find sheet containing '" + sheetName + "'");

                    object[,] allRows = _ws.ListObjects[1].DataBodyRange.Value2;
                    object[,] colNames = _ws.ListObjects[1].HeaderRowRange.Value2;

                    string lastKeyField;

                    if (sheetName == nonLaborSheet)
                    {

                        Pivot = "MONTH";
                        lastKeyField = "Remaining Cost";
                    }
                    else
                    {

                        if (LaborPivot == "WK")
                        {
                            Pivot = "WEEK";
                        }
                        else if (LaborPivot == "MTH")
                        {
                            Pivot = "MONTH";
                        }

                        lastKeyField = "Phase Actual Rate";
                        costtype = 0x1;
                    }

                    int iLastKeyField = Enumerable.Range(1, colNames.GetUpperBound(1))
                                  .Where(i => (string)colNames[1, i] == lastKeyField)
                                  .Select(i => i)
                                  .FirstOrDefault();

                    int FromDateCol;
                    int totalHeaderColCount;
                    int rateOffset;
                    int offsetPosition;
                    if (sheetName == nonLaborSheet)
                    {
                        rateOffset = _offsetFromRemCost;
                        offsetPosition = 0;
                    }
                    else
                    {
                        rateOffset = _offsetFromPhseActRate;
                        offsetPosition = 1;
                    }
                    totalHeaderColCount = iLastKeyField + offsetPosition;
                    FromDateCol = iLastKeyField + rateOffset;

                    int ToDateCol = allRows.GetUpperBound(1);
                    int totalNumberOfRows = allRows.GetUpperBound(0);

                    // Add rows from Excel Pivot
                    for (int row = 1; row <= totalNumberOfRows; row++)
                    {
                        // key header fields
                        byte phseGroup;
                        uint batchSeq;
                        string phase = null;
                        string description = null;
                        decimal rate = 0;
                        object employee = null;

                        // unpivot and fill DataTable from user input and default values
                        for (int colAmt = FromDateCol; colAmt <= ToDateCol; colAmt++)
                        {
                            decimal amt;
                            Decimal.TryParse(allRows[row, colAmt]?.ToString(), out amt);

                            if (amt != 0)
                            {
                                Row = dtUnpivotedProj.NewRow();

                                // populate header row data into SQL-like table
                                for (int col = 1; col <= totalHeaderColCount; col++)
                                {
                                    string colName = (string)colNames[1, col];

                                    if ((columns.ContainsKey(colName)) || colName == "Cost Type" || colName == "Phase Code" || colName == "Employee ID")
                                    {
                                        cellVal = allRows[row, col] ?? DBNull.Value;
                                        switch (colName)
                                        {
                                            case "Phase Code":
                                                phase = cellVal.ToString();
                                                colName = "Phase";
                                                break;
                                            case "Cost Type":
                                                switch (cellVal.ToString())
                                                {
                                                    case "L":
                                                        costtype = 0x1;
                                                        break;
                                                    case "M":
                                                        costtype = 0x2;
                                                        break;
                                                    case "S":
                                                        costtype = 0x3;
                                                        break;
                                                    case "O":
                                                        costtype = 0x4;
                                                        break;
                                                    case "E":
                                                        costtype = 0x5;
                                                        break;
                                                }
                                                colName = "CostType";
                                                cellVal = costtype;

                                                break;
                                            case "Employee ID":
                                                uint id;

                                                if (UInt32.TryParse(cellVal?.ToString(), out id))
                                                {
                                                    employee = id;
                                                }
                                                else
                                                {
                                                    employee = DBNull.Value;
                                                }
                                                colName = "Employee";
                                                break;
                                            case "Description":
                                                description = cellVal.ToString();
                                                break;
                                            case "Rate":
                                                Decimal.TryParse(allRows[row, FromDateCol - rateOffset + offsetPosition]?.ToString(), out rate);
                                                break;
                                        }
                                        Row[colName] = cellVal;

                                    }
                                }

                                // query SQL for BatchSeq & PhaseGroup
                                object[] tblBatchSeqPhaseGroup = HelperData.GetBatchSeqPhaseGroup(JCCo, Month, Job, CostBatchId, phase, costtype);

                                batchSeq = Convert.ToUInt32(tblBatchSeqPhaseGroup[0]);
                                phseGroup = Convert.ToByte(tblBatchSeqPhaseGroup[1]);
                                Row["Co"] = JCCo;
                                Row["DetSeq"] = ++detSeq;
                                Row["Mth"] = Month; // DateTime.FromOADate((double)Month).ToShortDateString(); // Excel converts DateTime to Decimmal, we must revert to DB type

                                DateTime ToDate = DateTime.Parse(colNames[1, colAmt]?.ToString());
                                DateTime FromDate = DateTime.Now;
                                DateTime DetMth = DateTime.Now;

                                Row["BatchId"] = CostBatchId;
                                Row["BatchSeq"] = batchSeq;
                                Row["Source"] = "JC Projctn";
                                Row["TransType"] = "A";
                                Row["JCTransType"] = "PB";
                                Row["ResTrans"] = DBNull.Value;
                                Row["Job"] = Job;
                                Row["PhaseGroup"] = phseGroup;
                                Row["Phase"] = phase;
                                Row["CostType"] = costtype;
                                Row["BudgetCode"] = DBNull.Value;
                                Row["EMCo"] = DBNull.Value;
                                Row["Equipment"] = DBNull.Value;
                                Row["PRCo"] = JCCo;
                                Row["Craft"] = DBNull.Value;
                                Row["Class"] = DBNull.Value;
                                switch (Pivot)
                                {
                                    case "MONTH":
                                        //ToDate = new DateTime(FromDate.Year, FromDate.Month, DateTime.DaysInMonth(FromDate.Year, FromDate.Month));
                                        FromDate = new DateTime(ToDate.Year, ToDate.Month, 1);
                                        Row["FromDate"] = FromDate;
                                        Row["ToDate"] = ToDate;
                                        break;
                                    case "WEEK":
                                        FromDate = ToDate.AddDays(-6);
                                        Row["FromDate"] = FromDate;
                                        Row["ToDate"] = ToDate;
                                        break;
                                }

                                switch (sheetName)
                                {
                                    case nonLaborSheet:
                                        Row["UM"] = "LS";
                                        Row["Hours"] = DBNull.Value;
                                        Row["Rate"] = DBNull.Value;
                                        Row["Amount"] = amt;
                                        Row["Employee"] = DBNull.Value;
                                        break;
                                    case laborSheet:
                                        Row["UM"] = "HRS";
                                        Row["Hours"] = amt; //this is really 'hours'
                                        Row["Amount"] = amt * rate;
                                        Row["Employee"] = employee;
                                        break;
                                }

                                Row["DetMth"] = new DateTime(ToDate.Year, ToDate.Month, 1);
                                Row["Quantity"] = DBNull.Value;
                                Row["Units"] = DBNull.Value;

                                Row["UnitHours"] = DBNull.Value;

                                Row["UnitCost"] = DBNull.Value;

                                Row["Notes"] = @"";
                                dtUnpivotedProj.Rows.Add(Row);
                            }
                            // no amount; skip, don't add row
                        }
                    }
                    if (sheetName == nonLaborSheet)
                    {
                        nonlaborCount = dtUnpivotedProj.Rows.Count;
                    }
                    else
                    {
                        laborCount = dtUnpivotedProj.Rows.Count - nonlaborCount;
                    }
                }

                if (dtUnpivotedProj.Rows.Count > 0)
                {
                    totalRows = nonlaborCount + laborCount;

                    try
                    {
                        insertedRows = InsertCostBatchNonLaborJCPD.InsCostJCPD(JCCo, Month, CostBatchId, dtUnpivotedProj);
                        successInsert = insertedRows == totalRows;
                    }
                    catch (Exception ex)
                    {
                        sb.Append(ex.Message);
                    }
                }
                if (successInsert)
                {
                    string job = HelperUI.JobTrimDash(Job);
                    _control_ws.Names.Item("LastSave" + job).RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _control_ws.Names.Item("JobUserName" + job).RefersToRange.Value = Login;
                }
                else if (insertedRows != totalRows) { throw new Exception("Cost Projection was NOT saved, please retry.  If problem persists contact support."); }

                UpdateJCPBwithSumData(manualETC_RowsWithValues.Count, visibleRows);

                if (btnFetchData.Text == "Saved") sb.Append("Cost Projection Successfully Saved.");

                MessageBox.Show(sb.ToString());
                dtUnpivotedProj.Clear();
                return true;
                // FOR TESTING ONLY simulate SQl DataTable to Excel
                //string sheet_name = String.Format("Projections_{0}_TEST", Job.Replace("-", "_"));
                //Excel.Worksheet _ws = HelperUI.AddSheet(workbook, sheet_name, workbook.ActiveSheet);
                //SheetBuilder.BuildGenericTable(_ws, dtUnpivotedProj);
            }
            catch (Exception ex)
            {
                if (manualETC_RowsWithValues != null)
                {
                    LogProphecyAction.InsProphecyLog(Login, 17, JCCo, Contract, Job, Month, CostBatchId, getErrTraceProd(ex), "OVR: " + manualETC_RowsWithValues.Count + " of " + visibleRows);
                }
                else
                {
                    LogProphecyAction.InsProphecyLog(Login, 17, JCCo, Contract, Job, Month, CostBatchId, getErrTraceProd(ex));
                }
                throw ex;
            }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
                cellVal = null;
                columns?.Clear();
                columns = null;
                dtUnpivotedProj?.Clear();
                dtUnpivotedProj = null;
                Column = null;
                Row = null;
                sb.Clear();
                manualETC_RowsWithValues?.Clear();
                manualETC_RowsWithValues = null;
            }
        }

        private void Alphanumeric_AND_ETCOverrideCount_AND_JTDActCostIsGreaterThanProjectedCost_Check(out int visibleRows, out List<int> manualETC_RowsWithValues)
        {
            Excel.Range rng = null;
            Excel.Range badCell = null;
            try {
                int JTDActualCost = _ws.ListObjects[1].ListColumns["JTD Actual Cost"].Index;
                int projectedCost = _ws.ListObjects[1].ListColumns["Projected Cost"].Index;
                int manualETCHours = _ws.ListObjects[1].ListColumns["Manual ETC Hours"].DataBodyRange.Column;
                int manualETC_CST_HR = _ws.ListObjects[1].ListColumns["Manual ETC CST/HR"].DataBodyRange.Column;
                int manualETCCost = _ws.ListObjects[1].ListColumns["Manual ETC Cost"].DataBodyRange.Column;
                int used = _ws.ListObjects[1].ListColumns["Used"].DataBodyRange.Column;
                decimal value = 0;
                bool blowup = false;
                int start = _ws.ListObjects[1].HeaderRowRange.Row + 1;
                visibleRows = 0;
                manualETC_RowsWithValues = new List<int>();

                for (int i = start; i <= CostSumWritable.Rows.Count; i++)
                {
                    if (_ws.Cells[i, used].Text == "Y")
                    {
                        visibleRows++;

                        if (_ws.Cells[i, JTDActualCost].Value > _ws.Cells[i, projectedCost].Value)
                        {
                            rng = _ws.Cells[i, JTDActualCost];
                        }

                        if (!_ws.Cells[i, manualETCCost].Locked && _ws.Cells[i, manualETCCost].Value2 != null)
                        {
                            if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETCCost].Value), out value))
                            {
                                badCell = _ws.Cells[i, manualETCCost];
                                blowup = true;
                            }
                            else if (value != 0)
                            {
                                if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                            }
                        }

                        if (!_ws.Cells[i, manualETCHours].Locked && _ws.Cells[i, manualETCHours].Value2 != null)
                        {
                            if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETCHours].Value), out value))
                            {
                                badCell = _ws.Cells[i, manualETCHours];
                                blowup = true;
                            }
                            else if (value != 0)
                            {
                                if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                            }
                        }

                        if (!_ws.Cells[i, manualETC_CST_HR].Locked && _ws.Cells[i, manualETC_CST_HR].Value2 != null)
                        {
                            if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETC_CST_HR].Value), out value))
                            {
                                badCell = _ws.Cells[i, manualETC_CST_HR];
                                blowup = true;
                            }
                            else if (value != 0)
                            {
                                if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                            }
                        }
                        if (blowup)
                        {
                            //_ws.Range[_ws.Cells[i, manualETCHours], _ws.Cells[i, manualETCCost]].EntireColumn.Hidden = false;  // BREAK UNDO - LeoG 9/8
                            workbook.Activate();
                            badCell.Activate();
                            btnFetchData.Text = "Save Projections to Viewpoint";
                            btnFetchData.Enabled = true;
                            isInserting = false;
                            throw new Exception("You have entered a text value in a numeric field, please correct.");
                        }
                    }
                }

                if (rng != null)
                {
                    MessageBox.Show("Actual Cost is greater than Projected Cost, please review.", "Actual Cost Greater", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    rng.Activate();
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (badCell != null) Marshal.ReleaseComObject(badCell); badCell = null;
            }
        }

        private void UpdateJCPBwithSumData(int manualETC_rowsWithValues, int manualETC_visibleRows)
        {
            DataTable table = new DataTable();
            Excel.ListObject xltable = null;
            int updatedTotal = 0;
            int rowCount = 0;

            try
            {
                _ws = HelperUI.GetSheet(costSumSheet, false);
                if (_ws == null) throw new Exception("No Cost Projections Summary tab found");

                string phaseName = "Phase Code";
                string typeName = "Cost Type";
                string hoursName = "Projected Hours";
                string costName = "Projected Cost";

                xltable = _ws.ListObjects[1];

                object[,] phse = xltable.ListColumns[phaseName].DataBodyRange.Value2;
                object[,] type = xltable.ListColumns[typeName].DataBodyRange.Value2;
                object[,] hours = xltable.ListColumns[hoursName].DataBodyRange.Value2;
                object[,] cost = xltable.ListColumns[costName].DataBodyRange.Value2;

                table.Columns.Add(phaseName, typeof(string));
                table.Columns.Add(typeName, typeof(char));
                table.Columns.Add(hoursName, typeof(decimal));
                table.Columns.Add(costName, typeof(decimal));

                rowCount = phse.GetUpperBound(0);
                for (int i = 1; i <= rowCount; i++)
                {
                    var row = table.NewRow();
                    row[phaseName] = phse[i, 1];

                    switch (type[i, 1].ToString())
                    {
                        case "L":
                            row[typeName] = 1;
                            break;
                        case "M":
                            row[typeName] = 2;
                            break;
                        case "S":
                            row[typeName] = 3;
                            break;
                        case "O":
                            row[typeName] = 4;
                            break;
                        case "E":
                            row[typeName] = 5;
                            break;
                    }
                    row[hoursName] = hours[i, 1];
                    row[costName] = cost[i, 1];
                    table.Rows.Add(row);
                }

                updatedTotal = Data.Viewpoint.JCUpdate.JCUpdateJCPB.SumUpdateJCPB(JCCo, Month, Job, CostBatchId, table);

                if (updatedTotal == rowCount)
                {
                    if (manualETC_rowsWithValues == 0)
                    {
                        LogProphecyAction.InsProphecyLog(Login, 4, JCCo, Contract, Job, Month, CostBatchId, null, updatedTotal + " of " + rowCount);
                    }
                    else
                    {
                        LogProphecyAction.InsProphecyLog(Login, 4, JCCo, Contract, Job, Month, CostBatchId, null, "OVR: " + manualETC_rowsWithValues + " of " + manualETC_visibleRows);
                    }
                    Globals.ThisWorkbook.isCostDirty = false;
                    btnPostCost.Visible = true;
                    btnPostCost.Enabled = true;
                    btnFetchData.Text = "Saved";
                    btnFetchData.Enabled = false;
                 }
                else
                {
                    throw new Exception("SumUpdateJCPB: there were errors saving you batch - access Viewpoint/JC Cost Projections to determine the issue");
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (xltable == null) Marshal.ReleaseComObject(xltable);
                if (_ws == null) Marshal.ReleaseComObject(_ws);
            }
        }

        private void UpdateJCIRwithSumData()
        {
            DataTable table = new DataTable();
            Excel.ListObject xltable = null;
            int updatedTotal = 0;
            try
            {
                _ws = HelperUI.GetSheet(revSheet, false);
                if (_ws == null) throw new Exception("No Revenue Projections Summary tab found");

                string contractItem = "Contract Item";
                string jectCV = "Projected Contract";

                xltable = _ws.ListObjects[1];

                HelperUI.Alphanumeric_Check(xltable, "Unbooked Contract Adjustment");

                int postedProjectedCost = xltable.ListColumns["Posted Projected Cost"].Index;
                int marginSeek = xltable.ListColumns["Margin Seek"].Index;
                int r = xltable.HeaderRowRange.Row + 1;
                int end = xltable.TotalsRowRange.Row - 1;

                for (int i = r; i <= end; i++)
                {
                    if (_ws.Cells[i, postedProjectedCost].Value != _ws.Cells[i, marginSeek].Value)
                    {
                        MessageBox.Show("You've entered Projected Cost in the revenue worksheet that does not match the Posted Cost.\n" +
                                        "Open and post cost batch(es) to ensure projected margin is maintained.", "Projected Cost Variance", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                        _ws.Cells[i, postedProjectedCost].Activate();
                        break;
                    }
                }

                if (xltable.ListRows.Count > 1)
                {

                    object[,] items = xltable.ListColumns[contractItem].DataBodyRange.Value2;
                    object[,] jectCVamt = xltable.ListColumns[jectCV].DataBodyRange.Value2;

                    table.Columns.Add(contractItem, typeof(string));
                    table.Columns.Add(jectCV, typeof(decimal));

                    int rowCount = items.GetUpperBound(0);
                    for (int i = 1; i <= rowCount; i++)
                    {
                        var row = table.NewRow();
                        row[contractItem] = items[i, 1];
                        row[jectCV] = jectCVamt[i, 1];
                        table.Rows.Add(row);
                    }
                }
                else if (xltable.ListRows.Count == 1)
                {
                    table.Columns.Add(contractItem, typeof(string));
                    table.Columns.Add(jectCV, typeof(decimal));

                    var row = table.NewRow();
                    row[contractItem] = xltable.ListColumns[contractItem].DataBodyRange.Value2;
                    row[jectCV] = xltable.ListColumns[jectCV].DataBodyRange.Value2;
                    table.Rows.Add(row);
                }
                else
                {
                    throw new Exception("There are no records in the Revenue Projections Summary sheet");
                }
                updatedTotal = Data.Viewpoint.JCUpdate.JCUpdateJCIR.SumUpdateJCIR(JCCo, Month, Contract, RevBatchId, table, Login);

                if (updatedTotal == xltable.ListRows.Count)
                {
                    _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _control_ws.Names.Item("ContractUserName").RefersToRange.Value = Login;
                    Globals.ThisWorkbook.isRevDirty = false;
                    btnPostRev.Visible = true;
                    btnPostRev.Enabled = true;
                    btnFetchData.Text = "Saved";
                    btnFetchData.Enabled = false;
                    MessageBox.Show("Revenue Projection Successfully Saved");
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (xltable == null) Marshal.ReleaseComObject(xltable);
                if (_ws == null) Marshal.ReleaseComObject(_ws);
            }
        }

        #endregion


        #region POST BATCH

        private void btnPostRev_Click(object sender, EventArgs e)
        {
            try
            {
                btnPostRev.Text = "Posting in progress";
                btnPostRev.Enabled = false;
                RenderOFF();
                //Stopwatch t2 = new Stopwatch(); t2.Start();

                if (PostRev.PostRevBatch(JCCo, Month, RevBatchId, Login, Contract))
                {
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);

                    _control_ws.Names.Item("ContractLastPost").RefersToRange.Value = HelperUI.DateTimeShortAMPM;

                    _ws = HelperUI.GetSheet(revSheet, false);
                    workbook.Application.DisplayAlerts = false;
                        _ws?.Delete();
                    workbook.Application.DisplayAlerts = true;
                    Globals.ThisWorkbook.isRevDirty = null;
                    btnPostRev.Text = "&Post Rev Batch";

                    RefreshRev(Job);

                    RevBatchId = 0;

                    CostSum_ProjectedMargin_Fill();

                    Globals.ThisWorkbook.EnableSheetChangeEvent(true);

                    _ws = HelperUI.GetSheet(Contract.Replace("-",""));
                    _ws?.Activate();
                    cboJobs.Text = Job;

                    RenderON();
                    //t2.Stop(); MessageBox.Show(string.Format("Time elapsed: {0:hh\\:mm\\:ss\\:ff}", t2.Elapsed));

                    MessageBox.Show("Revenue Projection Successfully Posted");
                }
            }
            catch (Exception)
            {
                workbook.Application.DisplayAlerts = true;
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                Globals.ThisWorkbook.isRevDirty = null;
                RenderON();
                btnPostRev.Text = "&Post Rev Batch";
                btnPostRev.Enabled = true;
                MessageBox.Show("Revenue Projection was NOT posted, please review the batch validation reports in the Viewpoint action and take corrective action.\nIf problem persists contact support.");
                //Possible failure reason: connectivity, wrong employee ID used
            }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }

        private void btnPostCost_Click(object sender, EventArgs e)
        {
            Excel.Worksheet gmax = null;

            try
            {
                btnPostCost.Text = "Posting in progress";
                btnPostCost.Enabled = false;
                RenderOFF();
                if (PostCost.PostCostBatch(JCCo, Month, CostBatchId))
                {
                    LogProphecyAction.InsProphecyLog(Login, 11, JCCo, Contract, Job, Month, CostBatchId);

                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);

                    string job = HelperUI.JobTrimDash(Job); 
                    _control_ws.Names.Item("LastPost" + job).RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _ws = HelperUI.GetSheet(costSumSheet, false);
                    workbook.Application.DisplayAlerts = false;
                        _ws?.Delete();
                        _ws = HelperUI.GetSheet(laborSheet, false);
                        _ws?.Delete();
                        _ws = HelperUI.GetSheet(nonLaborSheet, false);
                        _ws?.Delete();
                    workbook.Application.DisplayAlerts = true;
                    Globals.ThisWorkbook.isCostDirty = null;
                    btnPostCost.Text = "&Post Cost Batch";

                    RefreshCost(Job);

                    CostBatchId = 0;

                    gmax = HelperUI.GetSheet("GMAX-" + job);
                    if (gmax != null) LoadGMAX(ref gmax, true);

                    Globals.ThisWorkbook.EnableSheetChangeEvent(true);

                    _ws = HelperUI.GetSheet("-" + job);
                    _ws?.Activate();

                    //Added by JZ 8-25 to make button visible after posting a cost projection
                    btnFetchData.Text = "Generate Cost Projection";
                    btnFetchData.Visible = true;
                    btnPostCost.Visible = false;
                    cboMonth.Enabled = true;
                    lastRevProjectedMonth = Month;
                    cboJobs.Text = Job;

                    RenderON();
                    MessageBox.Show("Cost Projection Successfully Posted");
                }
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(Login, 15, JCCo, Contract, Job, Month, CostBatchId, ErrorTxt: ex.Message);
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                workbook.Application.DisplayAlerts = true;
                Globals.ThisWorkbook.isCostDirty = null;
                RenderON();
                btnPostCost.Enabled = true;
                btnPostCost.Text = "&Post Cost Batch";
                MessageBox.Show("Cost Projection was NOT posted, please review the batch validation reports in the Viewpoint action and take corrective action.\n\nIf problem persists contact support.");
                //Possible failure reason: connectivity, wrong employee ID used
            }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
                if (gmax != null) Marshal.ReleaseComObject(gmax);
            }
        }

        #endregion


        #region REFRESH COST / REV
        private void RefreshCost(string job)
        {
            try
            {
                BuildContractSheet();
                BuildProjectSheets(job, true);
                DisableGridlines(null);
                _ws = HelperUI.GetSheet(revCurve);
                if (_ws != null) BuildPRGPivot_RevCurve(ref _ws);

                _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            }
            catch (Exception) { throw; }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }

        private void RefreshRev(string job)
        {
            try
            {
                BuildContractSheet();

                DataTable table = ContractRefresh.GetContractPostRefresh(JCCo, Contract);
                string pn;
                foreach (DataRow row in table.Rows)
                {
                    pn = row.Field<string>("JobPart");
                    _ws = HelperUI.GetSheet(pn, true);
                    if (_ws != null)
                    {
                        _ws.Names.Item("ProjectedPRGContractValue").RefersToRange.Value = row.Field<decimal>("Revenue");
                        _ws.Names.Item("MarginPercent").RefersToRange.Value = row.Field<decimal>("Margin");
                    }
                }

                DisableGridlines(null);

                _ws = HelperUI.GetSheet(revCurve);
                if (_ws != null) BuildPRGPivot_RevCurve(ref _ws);

                _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            }
            catch (Exception) { throw; }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }
        #endregion


        #region CANCEL BATCH

        private void btnCancelRevBatch_Click(object sender, EventArgs e)
        {
            string msg = "";

            if (RevBatchId > 0)
            {
                DialogResult r = MessageBox.Show("Are you sure you want to cancel?", "Cancel Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                if (r == DialogResult.Yes)
                {
                    if (DeleteRevBatch.DeleteBatchRev(JCCo, Month, RevBatchId))
                    {
                        LogProphecyAction.InsProphecyLog(Login, 12, JCCo, Contract, null, Month, RevBatchId);

                        _ws = HelperUI.GetSheet(revSheet, false);

                        if (_ws != null)
                        {
                            workbook.Application.DisplayAlerts = false;
                            _ws.Delete();
                            workbook.Application.DisplayAlerts = true;
                        }
                        msg = "Revenue Batch " + RevBatchId + " was successfully cancelled";
                        btnCancelRevBatch.Enabled = false;
                        btnCancelRevBatch.Text = "Cancel Rev Batch: ";
                        RevBatchId = 0;
                    }
                    else
                    {
                        msg = "Revenue Batch was NOT cancelled.  Please retry or log in to the Viewpoint application to cancel the batch.  If problem persists contact support. ";
                        //Possible failure reason: connectivity, cancelled via VP application
                    }
                    MessageBox.Show(msg);
                }
            }
        }

        private void btnCancelCostBatch_Click(object sender, EventArgs e)
        {
            string msg = "";

            if (CostBatchId > 0)
            {
                DialogResult r = MessageBox.Show("Are you sure you want to cancel?", "Cancel Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                if (r == DialogResult.Yes)
                {
                    if (DeleteCostBatch.DeleteBatchCost(JCCo, Month, CostBatchId))
                    {
                        LogProphecyAction.InsProphecyLog(Login, 10, JCCo, Contract, Job, Month, CostBatchId);

                        workbook.Application.DisplayAlerts = false;
                        foreach (Excel.Worksheet _ws in workbook.Worksheets)
                        {
                            if (_ws.Name.Contains(costSumSheet) || _ws.Name.Contains(laborSheet) || _ws.Name.Contains(nonLaborSheet))
                            {
                                _ws.Delete();
                            }
                        }
                        workbook.Application.DisplayAlerts = true;
                        msg = "Cost Batch " + CostBatchId + " was successfully cancelled";
                        btnCancelCostBatch.Enabled = false;
                        btnCancelCostBatch.Text = "Cancel Cost Batch: ";
                        CostBatchId = 0;
                    }
                    else
                    {
                        msg = "Cost Batch was NOT cancelled.  Please retry or log in to the Viewpoint application to cancel the batch.  If problem persists contact support. ";
                        //Possible failure reason: connectivity, cancelled via VP application
                    }
                    MessageBox.Show(msg);
                }
            }
        }

        #endregion


        #region CONTROL PANEL - ACTION PANE

        public string[] FetchContractList()
        {
            contractlist_table = ContractList.GetContractList(JCCo, Contract);
            // LINQ method pulls Title from a DT into a string array...
            return contractlist_table
                      .AsEnumerable()
                      .Select<DataRow, String>(x => x.Field<String>("TrimContract"))
                      .ToArray();
        }

        private void cboJobs_Enter(object sender, EventArgs e)
        {
            if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";

            if (IsValidContract())
            {
                // Get corresponding company for selected contract
                List<string> result = (from row in contractlist_table.AsEnumerable()
                                   where row.Field<string>("TrimContract") == txtBoxContract.Text
                                   select row.Field<string>("Job")).ToList();

                if (result.Count > 0)
                {
                    result.Insert(0, "All Projects");
                    cboJobs.DataSource = result;
                    cboJobs.SelectedItem = "All Projects";
                }
            }
        }

        // validates contract, if so sets JCCo, Contract
        private bool IsValidContract()
        {
            errorProvider1.Clear();

            string contractNoDash = txtBoxContract.Text.Replace("-", "");

            if (!(HelperUI.IsTextPosNumeric(contractNoDash)))
            {
                txtContractNumber_MouseClick(null, null);
                errorProvider1.SetError(txtBoxContract, "Invalid contract");
                txtBoxContract.Focus();
                return false;
            }

            // Get corresponding company for selected contract
            Array[] result = (from row in contractlist_table.AsEnumerable()
                          where row.Field<string>("TrimContract") == txtBoxContract.Text
                          let objectArray = new object[] {
                              row.Field<byte>("JCCo"),
                              row.Field<string>("Contract")
                          }
                          select objectArray).ToArray();
            if (result.Length == 0)
            {
                txtContractNumber_MouseClick(null, null);
                errorProvider1.SetError(txtBoxContract, "Contract not found in database");
                return false;
            }
            
            JCCo = (byte)result[0].GetValue(0);  //_contract_key.Rows[0].Field<byte>("JCCo");
            Contract = result[0].GetValue(1).ToString();   //_contract_key.Rows[0].Field<string>("Contract");
            return true;
        }

        private void dpMonth_IndexChanged(object sender, EventArgs e)
        {
            errorProvider1.Clear();
            Month = (DateTime)cboMonth.SelectedItem;
        }

        #region Highlight Contract number on focus
        private void txtContractNumber_MouseClick(object sender, MouseEventArgs e)
        {
            txtBoxContract.SelectionStart = 0;
            txtBoxContract.SelectionLength = txtBoxContract.Text.Length;
        }

        private void txtContractNumber_Enter(object sender, EventArgs e) => txtContractNumber_MouseClick(sender, null); //emulate click
        #endregion

        // Allows hitting enter to invoke button click
        private void txtBoxContract_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";

                e.Handled = true;
                if (lastContractNoDash + "-" != txtBoxContract.Text) cboJobs.Text = "All Projects";
                this.btnFetchData_Click(sender, null);
            }
        }

        private void cboJobs_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";

                e.Handled = true;
                if (lastContractNoDash + "-" != txtBoxContract.Text && !cboJobs.Text.Contains(lastContractNoDash)) cboJobs.Text = "All Projects";
                this.btnFetchData_Click(sender, null);
            }
        }

        #endregion


        #region  SAVE COST DETAIL / GMAX / FUTURE CURVE OFFLINE

        public delegate void CopySheetsOffline(string filename, string job, object[] logData);
        public CopySheetsOffline copyCostDetailsOffline = new CopySheetsOffline(ETCOverviewActionPane.CopyCostDetailOffline);
        public CopySheetsOffline copyGMAXOffline = new CopySheetsOffline(ETCOverviewActionPane.CopyGMAXOffline);
        public CopySheetsOffline copyFutureCurveOffline = new CopySheetsOffline(ETCOverviewActionPane.CopyFutureCurveOffline);

        private void btnCopy_CostDetail_GMAX_FutureCurve_Offline_Click(object sender, EventArgs e)
        {
            string orig_text = btnCopyDetailOffline.Text;
            CopySheetsOffline copySheetsOffline = (CopySheetsOffline)btnCopyDetailOffline.Tag;
            string tab = copySheetsOffline.Method.Name;

            try
            {
                btnCopyDetailOffline.Text = "Copying...";
                btnCopyDetailOffline.Enabled = false;

                saveFileDialog1.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                saveFileDialog1.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                if (tab.Contains("Cost"))
                {
                    saveFileDialog1.FileName = Job + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);
                }
                else if (tab.Contains("Curve"))
                {
                    saveFileDialog1.FileName = "Future Curve " + Contract + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);
                }
                else if (tab.Contains("GMAX"))
                {
                    saveFileDialog1.FileName = "GMAX Project " + cboJobs.Text + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);
                }

                DialogResult action = saveFileDialog1.ShowDialog();
                if (action == DialogResult.OK)
                {
                    object[] logData = { Login, JCCo, Contract, Job, Month, CostBatchId };

                    copySheetsOffline(saveFileDialog1.FileName, cboJobs.Text, logData);

                    tmrSavedChangeCaption.Tag = orig_text;
                    btnCopyDetailOffline.Text = "Copied";
                    tmrSavedChangeCaption.Enabled = true;
                    copySheetsOffline = null;
                }
                else
                {
                    btnCopyDetailOffline.Text = orig_text;
                    btnCopyDetailOffline.Enabled = true;
                }
            }
            catch (Exception ex)
            {
                btnCopyDetailOffline.Text = orig_text;
                btnCopyDetailOffline.Enabled = true;
                ErrOut(ex);
            }
        }

        public static void CopyCostDetailOffline(string fullPathFilename, string Job, object[] logData)
        {
            if (HelperUI.SheetExists(costSumSheet, false))
            {
                Excel.Workbook wkbSource = null;
                Excel.Workbook wkbTarget = null;
                Excel.ListObject tableTarget = null;
                Excel.ListObject tableSrc = null;
                string job = HelperUI.JobTrimDash(Job);
                string costSum = ETCOverviewActionPane.costSumSheet + job;
                string labor = ETCOverviewActionPane.laborSheet + job;
                string nonlabor = ETCOverviewActionPane.nonLaborSheet + job;
                string Login = (string)logData[0];
                byte JCCo = (byte)logData[1];
                string Contract = (string)logData[2];
                DateTime Month = (DateTime)logData[4];
                uint CostBatchId = (uint)logData[5];

                try
                {
                    RenderOFF();
                    wkbSource = Globals.ThisWorkbook.Worksheets.Parent;
                    wkbTarget = wkbSource.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                    wkbSource.Sheets[costSum].Copy(After: wkbTarget.Sheets["Sheet1"]);
                    wkbTarget.Sheets["Sheet1"].Delete();

                    wkbSource.Sheets[labor].Copy(After: wkbTarget.Sheets[costSum]);
                    wkbSource.Sheets[nonlabor].Copy(After: wkbTarget.Sheets[labor]);
                    wkbTarget.Sheets[costSum].Activate();

                    string workbookName = "\'" + Globals.ThisWorkbook.FullName + "\'!";
                    string formula;

                    tableTarget = wkbTarget.Worksheets[costSum].ListObjects[1];

                    string[] newWorkbook_columns_formulas = { "Used" , "Remaining Hours", "Remaining Cost", "Remaining CST/HR", "Projected Hours", "Projected Cost" , "Change in Hours", "Change in Cost",
                                             "Change from LM Projected Hours", "Change from LM Projected Cost","Over/Under Hours", "Over/Under Cost" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }

                    foreach (Excel.Range cell in tableTarget.ListColumns["Manual ETC Cost"].DataBodyRange.Cells)
                    {
                        if (cell.HasFormula)
                        {
                            cell.FormulaR1C1 = (string)cell.FormulaR1C1.Replace(workbookName, "");
                        }
                    }

                    tableTarget = wkbTarget.Worksheets[labor].ListObjects[1];

                    newWorkbook_columns_formulas = new string[] { "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", "Phase Actual Rate" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }

                    tableTarget = wkbTarget.Worksheets[nonlabor].ListObjects[1];

                    newWorkbook_columns_formulas = new string[] { "Budgeted Phase Cost Remaining", "Phase Open Committed" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTarget.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }

                    wkbTarget.Sheets[labor].Unprotect(ETCOverviewActionPane.pwd);
                    wkbTarget.Sheets[nonlabor].Unprotect(ETCOverviewActionPane.pwd);

                    wkbSource.ForceFullCalculation = true;
                    wkbSource.Application.DisplayAlerts = false;
                    wkbTarget.Close(true, fullPathFilename, Type.Missing);
                }
                catch (Exception ex)
                {
                    LogProphecyAction.InsProphecyLog(Login, 9, JCCo, Contract, Job, Month, CostBatchId, getErrTraceProd(ex), "CopyCostDetailOffline");
                    throw;
                }
                finally
                {
                    RenderON();
                    wkbSource.Application.DisplayAlerts = true;
                    if (tableTarget != null) Marshal.ReleaseComObject(tableTarget);
                    if (tableSrc != null) Marshal.ReleaseComObject(tableSrc);
                    if (wkbTarget != null) Marshal.ReleaseComObject(wkbTarget);
                    if (wkbSource != null) Marshal.ReleaseComObject(wkbSource);
                }
            }
        }

        public static void CopyGMAXOffline(string fullPathFilename, string job, object[] logData)
        {
            Excel.Workbook wkbSource = null;
            Excel.Workbook wkbTarget = null;
            string Login = (string)logData[0];
            byte JCCo = (byte)logData[1];
            string Contract = (string)logData[2];

            string gmax = "GMAX-" + HelperUI.JobTrimDash(job);
            try
            {
                RenderOFF();
                wkbSource = Globals.ThisWorkbook.Worksheets.Parent;
                wkbTarget = wkbSource.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);
                wkbSource.Sheets[gmax].Copy(After: wkbTarget.Sheets["Sheet1"]);

                wkbTarget.Sheets["Sheet1"].Delete();
                wkbTarget.Sheets[gmax].Unprotect(ETCOverviewActionPane.pwd);

                wkbSource.Application.DisplayAlerts = false;
                wkbTarget.Close(true, fullPathFilename, Type.Missing);
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(Login, 9, JCCo, Contract, job, null, 0x0, getErrTraceProd(ex), "CopyGMAXOffline");
                throw;
            }
            finally
            {
                RenderON();
                wkbSource.Application.DisplayAlerts = true;
                if (wkbTarget != null) Marshal.ReleaseComObject(wkbTarget);
                if (wkbSource != null) Marshal.ReleaseComObject(wkbSource);
            }

        }

        public static void CopyFutureCurveOffline(string fullPathFilename, string contract, object[] logData)
        {
            Excel.Workbook wkbSource = null;
            Excel.Workbook wkbTarget = null;
            string Login = (string)logData[0];
            byte JCCo = (byte)logData[1];
            string Contract = (string)logData[2];

            try
            {
                RenderOFF();
                wkbSource = Globals.ThisWorkbook.Worksheets.Parent;
                wkbTarget = wkbSource.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);
                wkbSource.Sheets[revCurve].Copy(After: wkbTarget.Sheets["Sheet1"]);

                wkbTarget.Sheets["Sheet1"].Delete();
                wkbTarget.Sheets[revCurve].Unprotect(ETCOverviewActionPane.pwd);

                wkbSource.Application.DisplayAlerts = false;
                wkbTarget.Close(true, fullPathFilename, Type.Missing);
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(Login, 9, JCCo, Contract, null, null, 0x0, getErrTraceProd(ex), "CopyFutureCurveOffline");
                throw;
            }
            finally
            {
                RenderON();
                wkbSource.Application.DisplayAlerts = true;
                if (wkbTarget != null) Marshal.ReleaseComObject(wkbTarget);
                if (wkbSource != null) Marshal.ReleaseComObject(wkbSource);
            }

        }

        private void tmrSavedChangeCaption_Tick(object sender, EventArgs e)
        {
            btnCopyDetailOffline.Text = (string)tmrSavedChangeCaption.Tag;
            btnCopyDetailOffline.Enabled = true;
            tmrSavedChangeCaption.Enabled = false;
        }

        #endregion


        // lessen CPU consumption / speed things up
        private static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;

        private static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        private void ErrOut(Exception ex)
        {
            string err = ex.Message;
            if (err.Contains("Missing contract!")) // add-in
            {
                errorProvider1.SetError(txtBoxContract, err);
            }
            if (err.Contains("Month must be between") || err.Contains("Must first add a Fiscal Year in General Ledger.") || // bspHQBatchMonthVal
                     err.Contains("Missing Projection Month")) // add-in
            {
                errorProvider1.SetError(cboMonth, err);
            }
            else if (err.Contains("Missing JC Company!") || // bspJCJMValForProj, GenerateCostProjection
                     err.Contains("Invalid GL Company") ||  // bspHQBatchMonthVal, vspJCUOGet
                     err.Contains("Invalid JC Company"))   // bspJCUOInsert 
            {

            }
            else if (
                     // bspJCJMValForProj job checks
                     err.Contains("Missing Job!") || err.Contains("Job not on file, or no associated contract!") ||
                     err.Contains("Job is pending, cannot do projections.") || err.Contains("exists in a Projection batch for a different month!") ||
                     err.Contains("exists in a Projection batch for the current month") || err.Contains("exists in a PM Cost Projection for the current month") ||
                     err.Contains("is in another open projection batch for the current month!") || err.Contains("has future projections - will be deleted when batch is posted!") ||
                     err.Contains("exists in a PM Cost Projection for the same month and year!") ||
                     // add-in 
                     err.Contains("Unable to pull projections. Batch") || //belongs to someone else  
                     err.Contains("Missing Project (Job ID)"))
            {

                errorProvider1.SetError(cboJobs, err);  // if control is disabled it wont set error.
            }
            //else if (
            //         // bspHQBCInsert
            //         err.Contains("Unable to get next BatchId #!") || err.Contains("Unable to add HQ Batch Control entry!") ||
            //         err.Contains("Unable to retrieve newly created batch ID") ||
            //         // vspJCUOGet, bspJCUOInsert
            //         err.Contains("Invalid JC Form.") || err.Contains("Unable to insert default user options into JCUO.") ||
            //         // bspJCProjTableFill
            //         err.Contains("Unable to read user options from JCUO.") ||
            //         // bspJCProjInitialize
            //         err.Contains("Company not set up in JC Company file!") || err.Contains("Phase group not in HQGP!") ||
            //         err.Contains("User Name is invalid!"))
            //{

            //}
            else
            {
                MessageBox.Show(ex.Message);
            }
        }

        //private static string getErrTraceProd(Exception ex)
        //{
        //    StackTrace st = new StackTrace(ex, true);
        //    int line = st.GetFrame(st.FrameCount-1).GetFileLineNumber();
        //    string method = st.GetFrame(st.FrameCount - 1).GetMethod().Name;

        //    return method + ":" + line;

        //    //string err_evil_line = "";
        //    //int @in = ex.StackTrace.IndexOf("in ");
        //    //if (@in != -1)
        //    //{   //found
        //    //    string fromIn = ex.StackTrace.Substring(@in, ex.StackTrace.Length - @in);
        //    //    int at = fromIn.IndexOf("at ");
        //    //    if (at == -1)
        //    //    {
        //    //        // flat one level trace
        //    //        int module_index = fromIn.LastIndexOf("\\") + 1;
        //    //        if (module_index != -1)
        //    //        {
        //    //            err_evil_line = fromIn.Substring(module_index, fromIn.Length - module_index);
        //    //        }
        //    //        else
        //    //        {
        //    //            err_evil_line = fromIn;
        //    //        }
        //    //        err_evil_line = ex.Message + ": " + err_evil_line;
        //    //    }
        //    //    else
        //    //    {
        //    //        // for when there's chained (multiple levels) of code excution tracing
        //    //        string cs_line = fromIn.Substring(0, at);
        //    //        int start = cs_line.LastIndexOf("\\") + 1;
        //    //        if (start != -1)
        //    //        {
        //    //            err_evil_line = ex.Message + ": " + cs_line.Substring(start, cs_line.Length - start);
        //    //        }
        //    //        else
        //    //        {
        //    //            err_evil_line = ex.Message + ": " + cs_line;
        //    //        }
        //    //    }
        //    //}
        //    //else if (ex.StackTrace.Length != 0)
        //    //{
        //    //    if (ex.StackTrace.Length <= 254)
        //    //    {
        //    //        err_evil_line = ex.StackTrace.Substring(0, ex.StackTrace.Length);
        //    //    }
        //    //    else {
        //    //        err_evil_line = ex.StackTrace.Substring(0, 254);
        //    //    }
        //    //}
        //    //else
        //    //{
        //    //    err_evil_line = ex.Message;
        //    //}
        //}

        private static string getErrTraceProd(Exception ex)
        {
            string err_evil_line = "";
            //int line = (new StackTrace(ex, true)).GetFrame(0).GetFileLineNumber();  //works in DEBUG only

            if (ex.StackTrace.Length != 0)
            {
                int at = ex.StackTrace.IndexOf("at ");
                if (at != -1)
                {
                    int parenth = ex.StackTrace.IndexOf("(");
                    if (parenth != -1)
                    {
                        err_evil_line = ex.StackTrace.Substring(at + 2, parenth - 5);
                    }
                    else
                    {
                        err_evil_line = ex.StackTrace;
                    }
                }
                else
                {
                    err_evil_line = ex.StackTrace;
                }
            }

            if (err_evil_line.Length > 254)
            {
                err_evil_line = err_evil_line.Substring(0, 254);
            }

            return  err_evil_line;
        }

        public bool ClearWorkbook_SavePrompt()
        {
            return SavePrompt(deleteSheets: true);
        }

        public bool SavePrompt(bool deleteSheets)
        {
            if (HelperUI.SheetExists(lastContractNoDash, false))
            {
                DialogResult action;

                if (RevBatchId > 0 &&  CostBatchId > 0 && !alreadyPrompted)
                {
                    MessageBox.Show("You have open batches that have not been saved.  Please save or cancel your batches.", "Open Batches", MessageBoxButtons.OK, MessageBoxIcon.Question);
                    _control_ws.Activate();
                    alreadyPrompted = true;
                    return false;
                }
                else if(!alreadyPrompted)
                {
                    _ws = HelperUI.GetSheet(revSheet, false);
                    if (_ws != null && Globals.ThisWorkbook.isRevDirty == true)
                    {
                            action = MessageBox.Show("Would you like to save your Revenue projections to Viewpoint?", "Save Revenue Projections", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                        if (action == DialogResult.Cancel) return false;
                        if (action == DialogResult.Yes)
                        {
                            _ws.Activate();
                            return false;  //MessageBox.Show(UpdateJCIRwithSumData());
                        }
                    }

                    _ws = HelperUI.GetSheet(costSumSheet, false);
                    if (_ws != null && Globals.ThisWorkbook.isCostDirty == true)
                    {
                            action = MessageBox.Show("Would you like to save your Cost projections to Viewpoint?", "Save Cost Projections", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                        if (action == DialogResult.Cancel) return false;
                        if (action == DialogResult.Yes)
                        {
                            _ws.Activate();
                            return false; //InsertCostProjectionsIntoJCPD();
                        }
                    }
                }
                if (!workbook.Saved && !deleteSheets)
                {
                    action = MessageBox.Show("Would you like to save a copy of the workbook for future reference?", "Save Workbook", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                    if (action == DialogResult.Cancel) return false;
                    if (action == DialogResult.No) workbook.Saved = true;
                    if (action == DialogResult.Yes)
                    {
                        try
                        {
                            saveFileDialog1.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                            saveFileDialog1.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                            saveFileDialog1.FileName = Job +  " " + string.Format("{0:M-dd-yyyy}",DateTime.Today);
                            action = saveFileDialog1.ShowDialog();
                            if (action == DialogResult.OK)
                            {
                                //SaveCostProjectionsToNewWorkbook(saveFileDialog1.FileName);
                                workbook.SaveAs(saveFileDialog1.FileName);
                            }
                            else if (action == DialogResult.Cancel)
                            {
                                return false;
                            }
                        }
                        catch (Exception ex) { ErrOut(ex); }
                    }
                }
                if (deleteSheets)
                {
                    workbook.Application.DisplayAlerts = false;
                    foreach (Excel.Worksheet _ws in workbook.Worksheets)
                    {
                        if (_ws.Name != "GMAX" && _ws.Name != "Control")
                        {
                            _ws.Delete();
                        }
                    }
                    workbook.Application.DisplayAlerts = true;

                    RevBatchId = 0;
                    CostBatchId = 0;
                    Globals.ThisWorkbook.isRevDirty = null;
                    Globals.ThisWorkbook.isCostDirty = null;
                    ClearControlSheet();
                    Globals.ThisWorkbook.laborUserInsertedRowCount.Clear();
                    Globals.ThisWorkbook.nonLaborUserInsertedRowCount.Clear();
                }
            }
            return true;
        }

        private void ClearControlSheet()
        {
            foreach(Excel.Name name in _control_ws.Names)
            {
                name.RefersToRange.Value = "";
            }

            _control_ws.Names.Item("ViewpointLogin").RefersToRange.Value = vista_user.Rows[0].Field<string>("VPUserName");
            _control_ws.Names.Item("TimeOpening").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = "—";
            _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = "—";
            _control_ws.Names.Item("ContractLastPost").RefersToRange.Value = "—";
            _control_ws.Range[_control_ws.Cells[19, 3], _control_ws.Cells[28, 4]].Value = "—";
        }


        #region UNDO FUNCTIONALITY IDEA TO ALLOW CELL HIGHLIGHT ON CHANGE
        /*
        private void btnUndo_Click(object sender, EventArgs e)
        {
            if (Globals.ThisWorkbook.UndoList.Count > 0)
            {
                Excel.Worksheet _ws = Globals.ThisWorkbook.UndoParentList.Pop();
                KeyValuePair<string,string>  _kvUndo = Globals.ThisWorkbook.UndoList.Pop();
                undoing = true;
                _ws.Range[_kvUndo.Key].Formula = _kvUndo.Value;
                undoing = false;
                this.btnUndo.Enabled = Globals.ThisWorkbook.UndoList.Count > 0;
            }
        }
        */
        #endregion
        
        private void tmrWaitSortWinClose_Tick(object sender, EventArgs e)
        {
            Globals.ThisWorkbook.sortDialogVisible = Native.FindWindow("NUIDialog", "Sort") == IntPtr.Zero;

            if (Globals.ThisWorkbook.sortDialogVisible)
            {
                Excel.Worksheet ws = null;
                try
                {
                    ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;

                    if (!ws.ProtectContents)
                    {
                        if (ws.Name.Contains(laborSheet) || ws.Name.Contains(nonLaborSheet))
                        {
                            HelperUI.ProtectSheet(ws);
                        }
                        else
                        {
                            HelperUI.ProtectSheet(ws, false, false);
                        }
                    }
                    tmrWaitSortWinClose.Enabled = false;
                    Globals.ThisWorkbook.isSorting = false;
                }
                catch (Exception) {
                    tmrWaitSortWinClose.Enabled = false;
                    Globals.ThisWorkbook.isSorting = false;
                }
                finally
                {
                    if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                }
            }
        }

        //private void btnPOReport_Click(object sender, EventArgs e)
        //{
        //    try
        //    {
        //        btnPOReport.Enabled = false;
        //        DataTable table = POReport.POreport(JCCo, Job);
        //        if (table.Rows.Count == 0)
        //        {
        //            MessageBox.Show("No PO records found");
        //            return;
        //        }
        //    }
        //    catch (Exception ex) {
        //        //LogProphecyAction.InsProphecyLog(Login, 1, JCCo, Contract, Job, ErrorTxt: getErrTraceProd(ex),
        //        //  Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
        //        ErrOut(ex);
        //    }
        //    finally
        //    {
        //        btnPOReport.Enabled = true;
        //    }
        //}
    }
}
