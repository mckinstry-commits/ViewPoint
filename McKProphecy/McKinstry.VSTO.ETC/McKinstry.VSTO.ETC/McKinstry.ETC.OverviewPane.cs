using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Windows.Forms;
//using Excelo = Microsoft.Office.Tools.Excel; // VSTO Add-in Template (New Project -> Office -> Excel template) 
using Excel = Microsoft.Office.Interop.Excel; // Shared Add-in template (caters multiple Office applications)
//using Mckinstry.VSTO;
using McKinstry.Data.Viewpoint;
using System.Linq;
using System.Runtime.InteropServices;
using McKinstry.Data.Viewpoint.JCDelete;
using McKinstry.Data.Models.Viewpoint;


/***********************************************Code Header Info***************************************************;
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
//    1.0.6 Cost Fix               11/03/2016               Opening 2nd Cost Projection Fix                       *;
//                                                                                                                *;
//    1.0.7 Small Changes          11/04/2016               Cost Posting Fix                                      *;
//                                                                                                                *;
//    1.0.8 Small Changes          11/30/2016               Include Non Closed Months, Sorting, error fixes       *;
//                                                                                                                *;
//    1.0.9 Small Changes          01/15/2017               Save ETC Override                                     *; 
//                                                                                                                *; 
//    1.0.9.1 Small Changes        01/16/2017               Projection audit in Control tab                       *; 
//                                                                                                                *; 
//    1.0.9.2 Small Changes        02/13/2017               Open Batches on Control tab                           *; 
//                                                                                                                *; 
//    1.1.0  Bug Fixes             05/18/2017               New Error Msg Text, Bug fixes                         *;
//                                                                                                                *; 
//    1.2.0  SL and PO Reports     07/13/2017               New SL and PO Report, New Cost Col, Bug Fixes         *; 
//                                                                                                                *; 
//    1.2.1  Small Fixes           08/17/2017               Cancel Cost ject for new Projects w/ no Phase Codes   *; 
//                                                                                                                *; 
//    1.2.1.2  Enhace / tweak      9/29/2017                541- Prevent arbritrary Project / Month  user input   *;
//                                                                                                                *;
//    1.3.0.0  Enhance             12/08/2017               Axosoft 101150 Manweek Projection Details             *;

                                                            LABOR ONLY and NON-LABOR ONLY   
                                                            Control Panel button now visible 
                                                          - SUM formulas updated for labor, nonlabor only and both cases
                                                          - udpated manweeks logic to include past month gray column
                                                          - Control Panel button won't disappear after click   
                                                          - fixed SUM formulas and manweeks logic   
                                                          - fixed empty msg box when saving to VP w/ manual ETC 
                                                          - SAVE TO VP; SUM: check ETC 'Hours with missing Rate'
                                                          - uncommneted "Updating Reports.." btn txt after posting
                                                          - SAVE TO VP; LABOR: check 'hours with missing rate'
                                                          - SUM: highlight 'Batch Created On' date regardless of date
                                                          - Fix inserting row issue (caused by renaming 'MTD Actual Hours' column to 'MTD Actuals')
                                                          - updated UI controls workflow and triggers for pulling contracts
                                                          - UI controls are now updated when deleting Contract after report pull then tabbing to reports
                                                          - Hours missing rate for Manual ETC and Labor detail text updated
                                                          - LABOR: swap Projected Remaining Hours formula to check if R1 = 'W' = * 40
                                                          - updated WIP refresh err handle
                                                          - Swap Labor Detail: Projected Remaining Manweeks in Column G and Projected Remaining Hours in Column H
                                                          - Reorder Actuals in Cost Summary tab to be Batch, Total Closed, JTD
                                                          - FIX: NonLabor save OK
                                                          - 2 decimal manweeks
                                                          - Cost Projections cap limit fix for Projects that exceed 60 months or 100 weeks
                                                          - Add Contract and Job reports to copy offline
                                                          - save multiple filters for Sum, Labor and Nonlabor in copy offline
                                                          - LABOR: gray out all weeks of starting month
                                                     
    1.3.20                         3/9/218                - when no printer setup, program doesn't halt and continues  
                                                          - Open batches cancel button added! eliminates the need to open the projection
                                                          - visual queue highlights batch in question
                                                                                                                
*******************************************************************************************************************/

namespace McKinstry.ETC.Template
{
    partial class ETCOverviewActionPane : UserControl
    {
        public const string pwd = "prophecy";

        #region  TABLES
        public Contracts contractList = new Contracts();

        public DataTable contractPRG_table = new DataTable();
        public DataTable contractPRGPivot_table = new DataTable();
        public DataTable contJobHeaderDtl_table = new DataTable();
        public DataTable contJobCTSum_table = new DataTable();
        public DataTable contJobParentPhaseSum_table = new DataTable();
        public DataTable contJobJectBatchSum_table = new DataTable();
        public DataTable contJobJectBatchNonLabor_table = new DataTable();
        public DataTable contJobJectBatchLabor_table = new DataTable();
        public DataTable contJectRevenue_table = new DataTable();
        private Dictionary<string, string> job_list = null;
        private List<ProjectionAudit> jobAudit_list = null;
        #endregion

        #region PROPERTIES / FIELDS (COM)

        public Excel.Worksheet _control_ws; // "Control" worksheet for persistent storage of selected items and general overview of execution context
        public Excel.Worksheet _ws = null;
        public Excel.ListObject _table = null;

        public Excel.Range LaborEmpDescEdit { get; set; }
        public Excel.Range LaborMonthsEdit { get; set; }
        public Excel.Range LaborRateEdit { get; set; }
        public int _offsetFromPhseActRate = 4;
        private int laborMonthStart;
        private int nonLaborMonthStart;

        public Excel.Range NonLaborWritable1 { get; set; }
        public Excel.Range NonLaborWritable2 { get; set; }
        public int _offsetFromRemCost = 2;

        public Excel.Range CostSumWritable { get; set; }

        public Excel.Range RevWritable1 { get; set; }
        public Excel.Range RevWritable2 { get; set; }

        #endregion

        #region PROPERTIES / FIELDS (NON-COM)
        private byte _jcco;
        // setting JCCo  **** ALSO SETS MONTH ***
        public byte JCCo
        { 
            get { return _jcco; }
            set
            {
                try
                {
                    if (lastContractNoDash + "-" != _Contract)
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
                                MonthSearch = DateTime.Parse(cboMonth.SelectedItem.ToString());
                            }
                            else
                            {
                                // selection defaults to latest month
                                cboMonth.SelectedIndex = cboMonth.Items.Count - 1;
                                cboMonth.SelectedItem = cboMonth.SelectedValue;
                                MonthSearch = DateTime.Parse(cboMonth.SelectedItem.ToString());
                            }
                        }
                        cboMonth.ResumeLayout();
                    }
                    _jcco = value;
                }
                catch (Exception e) { ShowErr(e); }
            }
        }

        public string Login { get; set; }

        public string _Contract { get; set; }

        public string Job { get; set; }

        public string Pivot { get; set; }

        public string LaborPivot { get; set; }

        public DateTime MonthSearch { get; set; }

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
                if (value != 0)
                {
                    _control_ws.Names.Item("RevJectContract").RefersToRange.Value = _Contract;
                    _control_ws.Names.Item("RevBatchId").RefersToRange.Value = value;
                    _control_ws.Names.Item("RevJectType").RefersToRange.Formula = "Revenue";
                    _control_ws.Names.Item("RevJectMonth").RefersToRange.Value = string.Format("{0:MM/yyyy}", MonthSearch.Date);
                }
                else
                {
                    _control_ws.Names.Item("RevJectContract").RefersToRange.Formula = "";
                    _control_ws.Names.Item("RevBatchId").RefersToRange.Formula = "";
                    _control_ws.Names.Item("RevJectType").RefersToRange.Formula = "";
                    _control_ws.Names.Item("RevJectMonth").RefersToRange.Value = (object)"";
                }
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
                if (value != 0)
                {
                    _control_ws.Names.Item("CostJectJob").RefersToRange.Value = Job;
                    _control_ws.Names.Item("CostBatchId").RefersToRange.Value = value;
                    _control_ws.Names.Item("CostJectType").RefersToRange.Formula = "Cost";
                    Globals.ThisWorkbook.Names.Item("CostJectMonth").RefersToRange.Value = string.Format("{0:MM/yyyy}", MonthSearch.Date);
                }
                else
                {
                    _control_ws.Names.Item("CostJectJob").RefersToRange.Formula = "";
                    _control_ws.Names.Item("CostBatchId").RefersToRange.Formula = "";
                    _control_ws.Names.Item("CostJectType").RefersToRange.Formula = "";
                    Globals.ThisWorkbook.Names.Item("CostJectMonth").RefersToRange.Value2 = (object)"";
                }
            }
        }
        #endregion

        #region SHEET NAMES
        internal const string controlSheet = "Control";
        internal const string laborSheet = "Labor-";
        internal const string nonLaborSheet = "NonLabor-";
        internal const string costSumSheet = "CostSum-";
        internal const string revSheet = "Rev-";
        internal const string revCurve = "Projected Curve";
        internal const string subcontracts = "Subcontracts-";
        internal const string pos = "POs-";
        #endregion

        #region CONTROL PROGRAM FLOW
        public int open_batches_row_offset = 0;
        public bool isRendering;
        private bool isInserting;
        private bool alreadyPrompted;
        public string saveManualETC = null;
        private bool newProjection = false; // new projection use ETC flag from report, else query
        private bool userOKtoSaveRev = false;
        private bool saving = false;

        //public bool undoing;
        #endregion

        #region CONTRACT SEARCH 
        internal const string allprojects = "All Projects";
        private string lastContractNoDash = "";
        public string lastJobPulled = "";
        public string prevContract = "";
        public DateTime lastCostProjectedMonth;
        public DateTime lastRevProjectedMonth;
        #endregion

        #region LABOR: HOURS <-> MANWEEKS

        Microsoft.Vbe.Interop.Forms.CommandButton btnConvertLaborTime;
        internal enum LaborEnum
        {
            Hours,
            Manweeks
        }
        internal LaborEnum LaborTime { get; set; }
        private string hours_weeks = null;

        private static List<Filter> _filters;

        #endregion

        public static Excel.Workbook workbook => Globals.ThisWorkbook.Worksheets.Parent;

        //public Stopwatch t2;
        //internal TimeSpan diff;
        //public Microsoft.Vbe.Interop.VBComponent undoMod;
        
        
        public ETCOverviewActionPane()
        {
            //t2 = new Stopwatch(); t2.Start();
            InitializeComponent();
            // Get contract list and setup autocomplete feature
            this.txtBoxContract.AutoCompleteSource = AutoCompleteSource.CustomSource;
            this.txtBoxContract.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
            AutoCompleteStringCollection collection = new AutoCompleteStringCollection();

            //t2.Stop(); secs += t2.Elapsed.Milliseconds; t2.Reset();

            string[] list = FetchContractList();
            collection.AddRange(list);

            txtBoxContract.AutoCompleteCustomSource = collection;
            txtBoxContract.Enabled = true;
            //txtBoxContract.Text = "104203-";
            //txtBoxContract.Text = "112218-";

            cboMonth.Enabled = false;
            cboMonth.FormatString = "MM/yyyy";
            cboMonth.Visible = false;

            btnPostCost.Location = new System.Drawing.Point(8, 321);
            btnPostRev.Location = new System.Drawing.Point(8, 321);
            btnProjectedRevCurve.Location = new System.Drawing.Point(8, 325);
            btnSubcontracts.Location = new System.Drawing.Point(8, 386);
            btnPOs.Location = new System.Drawing.Point(8, 451);
            btnCopyDetailOffline.Location = new System.Drawing.Point(8, 516);
            btnOpenBatches.Location = new System.Drawing.Point(8, 455);
            cboJobs.BackColor = System.Drawing.Color.LightGray;
            //HelperUI.Hide_RDP_BlackBox(); // RDP session security won't allow
            //if (System.Windows.Forms.SystemInformation.TerminalServerSession) HelperUI.Hide_RDP_BlackBox();
            txtBoxContract.Focus();

            this.btnCancelRevBatch.Click += (sender, EventArgs) => { this.btnCancelRevBatch_Click(sender, EventArgs, true); };
            this.btnCancelCostBatch.Click += (sender, EventArgs) => { this.btnCancelCostBatch_Click(sender, EventArgs, true); };

        }

        internal void btnFetchData_Click(object sender, EventArgs e)
        {
            if (isRendering) return; // let it finish rendering before a refresh
            btnFetchData.Enabled = false;
            string btnOrigText = btnFetchData.Text;
            bool failed = false;
            bool rev = false;
            bool cost = false;
            LaborEnum laborTimeBeforeSave = LaborTime;

            Application.UseWaitCursor = true;

            try
            {
                if (btnFetchData.Text.Contains("Get Contract"))
                {
                    if (txtBoxContract.Text == "" || !HelperUI.IsTextPosNumeric(txtBoxContract.Text.Replace("-", "")))
                    {
                        errorProvider1.SetIconAlignment(txtBoxContract, ErrorIconAlignment.MiddleRight);
                        errorProvider1.SetError(txtBoxContract, "Select a Contract from the list");
                        ResetGetContract(btnOrigText);
                        isInserting = false;
                        isRendering = false;
                        saving = false;
                        Application.UseWaitCursor = false;
                        return;
                    }
                    else
                    {
                        if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";
                        Refresh_cboJobs(txtBoxContract.Text);
                    }

                    errorProvider1.Clear();
                    btnFetchData.Text = "Processing...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);

                    try
                    {
                        if (ClearWorkbook_SavePrompt())
                        {
                            Globals.ThisWorkbook.SheetActivate -= new Excel.WorkbookEvents_SheetActivateEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetActivate);
                            RenderOFF();
                            BuildReports();
                            LoadContractProphecyHistory();
                            btnFetchData.Enabled = true;

                            if (HelperUI.IsTextPosNumeric(workbook.ActiveSheet.Name))
                            {
                                btnFetchData.Text = "Generate Revenue Projection";
                                btnProjectedRevCurve.Visible = true;
                                cboMonth.Visible = true;
                                groupPost.Visible = false;
                                btnOpenBatches.Visible = false;
                                lblMonth.Visible = true;
                                txtBoxContract.Enabled = false;
                            }
                            else
                            {
                                btnFetchData.Text = "&Get Contract && Projects";
                            }
                            alreadyPrompted = false;
                        }
                        else
                        {
                            if (!userOKtoSaveRev)
                            {
                                btnFetchData.Text = btnOrigText;
                                btnFetchData.Enabled = true;
                            }
                            btnFetchData.Refresh();
                        }
                    }
                    catch (Exception ex)
                    {
                        failed = true;
                        if (ex.Message != "handled") ReportErrOut(ex);
                    }
                    finally
                    {
                        Globals.ThisWorkbook.SheetActivate += new Excel.WorkbookEvents_SheetActivateEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetActivate);
                        //Globals.ThisWorkbook.ThisWorkbook_SheetActivate(_ws);
                        Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                        if (workbook.ActiveSheet.Name == lastContractNoDash)
                        {
                            cboJobs.Text = allprojects;
                            cboJobs.SelectedItem = 0;
                            cboJobs.Enabled = false;
                        }
                        RenderON();
                    }
                }
                else if (btnFetchData.Text == "Generate Revenue Projection")
                {
                    rev = true;
                    btnFetchData.Text = "Generating Projection...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);
                    Globals.ThisWorkbook.SheetSelectionChange -= new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);

                    if (GenerateRevenueProjections())
                    {
                        btnFetchData.Text = "Save Projections to Viewpoint";
                        btnFetchData.Visible = true;
                        btnPostRev.Visible = true;
                        cboMonth.Enabled = false;
                        cboMonth.Visible = true;
                        lastRevProjectedMonth = MonthSearch;
                        cboJobs.Enabled = false;
                        // No control is left focused on Action Pane; return focus to Control Panel
                        SendKeys.Send("%");
                        SendKeys.SendWait("{ESC}");
                        OpenBatches.RefreshOpenBatchesUI();
                    }
                    else { failed = true; }
                }
                else if (btnFetchData.Text == "Generate Cost Projection")
                {
                    cost = true;
                    btnFetchData.Text = "Generating Projection...";
                    btnFetchData.Refresh();
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);
                    Globals.ThisWorkbook.SheetSelectionChange -= new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);

                    if (GenerateCostProjections2())
                    {
                        btnFetchData.Text = "Save Projections to Viewpoint";
                        cboMonth.Enabled = false;
                        btnCopyDetailOffline.Visible = true;
                        btnCopyDetailOffline.Tag = copyCostDetailsOffline;
                        lastCostProjectedMonth = MonthSearch;
                        // Return control focus to Control Panel
                        SendKeys.Send("%");
                        SendKeys.SendWait("{ESC}");
                        btnPOs.Visible = true;
                        btnSubcontracts.Visible = true;
                        OpenBatches.RefreshOpenBatchesUI();
                    }
                    else { failed = true; }
                    //MessageBox.Show(String.Format("Time elapsed: {0} seconds", secs * .001m));
                }
                else if (btnFetchData.Text == "Save Projections to Viewpoint")
                {
                    btnFetchData.Text = "Saving to Viewpoint...";
                    btnFetchData.Refresh();
                    if (workbook.ActiveSheet.Name.Contains(costSumSheet))
                    {
                        cost = true;
                        saving = true;
                        if (LaborTime == LaborEnum.Manweeks)
                        {
                            ConvertLaborTime(LaborEnum.Hours);
                            InsertCostProjectionsIntoJCPD2();
                            ConvertLaborTime(LaborEnum.Manweeks);
                        }
                        else
                        {
                            InsertCostProjectionsIntoJCPD2();
                        }
                    }
                    else if (workbook.ActiveSheet.Name.Contains(revSheet))
                    {
                        rev = true;
                        userOKtoSaveRev = false;
                        UpdateJCIRwithSumData();
                        //UpdateJCIRwithSumData2();
                    }
                }
            }
            catch (Exception ex)
            {
                failed = true;
                if (cost)
                {
                    if (saving)
                    {
                        // // Revert back LaborTime in case it wasn't chng'd back to Manweeks
                        if (LaborTime == LaborEnum.Hours && laborTimeBeforeSave == LaborEnum.Manweeks)
                        {
                            ConvertLaborTime(LaborEnum.Manweeks);
                        }
                    }
                    CostJectErrOut(ex);
                }
                else if (rev)
                {
                    RevJectErrOut(ex);
                }
                else
                {
                    ShowErr(ex);
                }
            }
            finally
            {
                isInserting = false;
                isRendering = false;
                saving = false;
                Application.UseWaitCursor = false;
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
            }

            if (failed) ResetGetContract(btnOrigText);
            //workbook.Application.ActiveWindow.TabRatio = 0.77;
        }

        private void ResetGetContract(string btnOrigText)
        {
            btnFetchData.Text = btnOrigText;
            btnFetchData.Enabled = true;
            cboJobs.Enabled = btnFetchData.Text == "Generate Revenue Projection" || _Contract == null ? false : true;
            btnFetchData.Refresh();    
        }

        #region BUILD REPORTS

        private void BuildReports()
        {
            isRendering = true;
            try
            {
                if (_Contract == null)
                {
                    errorProvider1.SetIconAlignment(txtBoxContract, ErrorIconAlignment.MiddleRight);
                    errorProvider1.SetError(txtBoxContract, "Select a Contract from the list");
                    throw new Exception("handled");
                }
                //Stopwatch t2 = new Stopwatch(); t2.Start();
                lastContractNoDash = _Contract.Replace("-", "");
                BuildContractSheet();

                if (cboJobs.SelectedIndex == 0 || cboJobs.Text == "" || !cboJobs.Text.Contains(lastContractNoDash))
                {
                    Job = null;
                }
                else
                {
                    Job = cboJobs.Text;
                }

                BuildProjectSheets(Job);

                DisableGridlines();

                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract);

                Globals.ThisWorkbook.isRevDirty = null;
                Globals.ThisWorkbook.isRevDirty = null;
                lastJobPulled = Job;
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, 1);
                throw ex;
            }
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

            try
            {
                _ws = HelperUI.GetSheet(lastContractNoDash, false);

                if (_ws != null)
                {
                    // delete it and re-add it otherwise grouping outlines get's lost (MS BUG)
                    after = _ws.Previous;
                    workbook.Application.DisplayAlerts = false;
                    _ws.Delete();
                    workbook.Application.DisplayAlerts = true;
                    _ws = HelperUI.AddSheet(lastContractNoDash, after, false);
                }
                else
                {
                    _ws = HelperUI.AddSheet(lastContractNoDash, _control_ws, false);
                }

                _ws.Cells.Locked = false;
                _ws.Unprotect();

                //Get Contract Items for specified Contract
                contractPRG_table = ContractPRG.GetContractPRGTable(JCCo, _Contract);

                SheetBuilder.BuildGenericTable(_ws, contractPRG_table);

                _control_ws.Names.Item("ContractNumber").RefersToRange.Value = _Contract;

                // ContractPRG table
                rng = _ws.Cells.Range["A1:S1"];
                rng.Merge();
                rng.Value = "CONTRACT OVERVIEW: " + _Contract + " " + JobGetTitle.GetTitle(JCCo, _Contract).Replace(" - " + _Contract, "");
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

                #region FIELD DESC
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
                #endregion

                HelperUI.MergeLabel(_ws, "PRG", "JC Dept Description", "Details");
                HelperUI.MergeLabel(_ws, "Projected Cost", "Projected Cost", "Cost");
                HelperUI.MergeLabel(_ws, "Original Contract", "Projected Contract", "Contract");
                HelperUI.MergeLabel(_ws, "Unbooked Contract Adjustments", "Future CO", "Changes");
                HelperUI.MergeLabel(_ws, "Last Month Earned Revenue", "Last Month Earned Revenue", "Earned Revenue");
                HelperUI.MergeLabel(_ws, "Billed to Date", "Estimated Over/(Under) Billed", "Billing");
                HelperUI.MergeLabel(_ws, "Original Margin", "Margin Variance", "Margin");

                _ws.Cells[PRGSum.HeaderRowRange.Row - 1, 1].EntireRow.Group();
                _ws.Cells[PRGSum.HeaderRowRange.Row - 1, 1].EntireRow.Hidden = true;

                #region COLUMN WIDTH
                PRGSum.ListColumns["PRG"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["PRG Description"].DataBodyRange.EntireColumn.AutoFit();
                PRGSum.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 8.00;
                PRGSum.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 25.00;
                PRGSum.ListColumns["Projected Cost"].DataBodyRange.ColumnWidth = 16.75;
                PRGSum.ListColumns["Original Contract"].DataBodyRange.ColumnWidth = 15.75;
                PRGSum.ListColumns["Current Contract"].DataBodyRange.ColumnWidth = 15.75;
                PRGSum.ListColumns["Projected Contract"].DataBodyRange.ColumnWidth = 18.14;
                PRGSum.ListColumns["Unbooked Contract Adjustments"].DataBodyRange.ColumnWidth = 14.71;
                PRGSum.ListColumns["Future CO"].DataBodyRange.ColumnWidth = 14.29;
                PRGSum.ListColumns["Last Month Earned Revenue"].DataBodyRange.ColumnWidth = 14.73;
                PRGSum.ListColumns["Billed to Date"].DataBodyRange.ColumnWidth = 15.75;
                PRGSum.ListColumns["Estimated Over/(Under) Billed"].DataBodyRange.ColumnWidth = 15.43;
                PRGSum.ListColumns["Original Margin"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["Current Margin"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["Last Month Margin"].DataBodyRange.ColumnWidth = 9.00;
                PRGSum.ListColumns["Projected Margin $"].DataBodyRange.ColumnWidth = 17;
                PRGSum.ListColumns["Projected Margin %"].DataBodyRange.ColumnWidth = 17.43;
                PRGSum.ListColumns["Margin Variance"].DataBodyRange.ColumnWidth = 16;
                #endregion

                PRGSum.ListColumns["Last Month Earned Revenue"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                PRGSum.ListColumns["Billed to Date"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                PRGSum.ListColumns["Estimated Over/(Under) Billed"].DataBodyRange.Style = HelperUI.CurrencyStyle;

                HelperUI.GroupColumns(_ws, "Projected Cost", "Current Contract");
                HelperUI.GroupColumns(_ws, "Unbooked Contract Adjustments", "Billed to Date");
                HelperUI.GroupColumns(_ws, "Original Margin", "Last Month Margin");

                HelperUI.PrintPageSetup(_ws);

                _ws.UsedRange.Locked = true;
                //PRGPivot.TotalsRowRange.Locked = false;
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
            }
        }

        private void BuildProjectSheets(string jobId = null, bool refresh = false)
        {
            Excel.Range rng = null;
            Excel.Worksheet after = null;
            Pivot = "MONTH";
            int rowNum = 15;
            int colNum = 1;
            uint rn = 0;


            //Get associated jobs for specified Contract
            job_list = ContractJobs.GetContractJobTable(JCCo, _Contract, jobId);

            foreach (KeyValuePair<string, string> kv in job_list)
            {
                string job = kv.Key;
                string _pn = HelperUI.JobTrimDash(job);

                if (!refresh)
                {
                    _control_ws.Cells[rowNum, colNum].Value = job;
                    _control_ws.Cells[rowNum, colNum + 1].Value = kv.Value;
                    _control_ws.Names.Add("_" + _pn, _control_ws.Cells[rowNum, colNum]);
                    _control_ws.Names.Add("_" + _pn + "Desc", _control_ws.Cells[rowNum, colNum + 1]);
                    _control_ws.Names.Add("LastSave_" + _pn, _control_ws.Cells[rowNum, colNum + 2]);
                    _control_ws.Names.Add("SaveUser_" + _pn, _control_ws.Cells[rowNum, colNum + 3]);
                    _control_ws.Names.Add("LastPost_" + _pn, _control_ws.Cells[rowNum, colNum + 4]);
                    _control_ws.Names.Add("PostUser_" + _pn, _control_ws.Cells[rowNum, colNum + 5]);
                    ++rowNum;
                }

                _ws = HelperUI.GetSheet("-" + _pn);

                if (_ws == null)
                {
                    _ws = HelperUI.AddSheet("-" + _pn, Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count], false);
                    if (_ws == null)
                    {
                        MessageBox.Show("BuildProjectSheets: Something went wrong building project worksheet: -" + _pn + "\nSkipping..");
                        continue;
                    }
                }
                else
                {
                    // delete it and re-add it otherwise grouping outlines get's lost
                    // HelperUI.CleanSheet(_ws);  ditching this more efficient way due to Excel v.15 grouping outlines don't refresh correctly (MS BUG fixed in Excel. v.16) - LeoG
                    after = _ws.Previous;
                    workbook.Application.DisplayAlerts = false;
                    _ws.Delete();
                    workbook.Application.DisplayAlerts = true;
                    _ws = HelperUI.AddSheet("-" + _pn, after, false);
                }

                _ws.Cells.Locked = false;

                contJobHeaderDtl_table = JobHeader.GetJobHeaderTable(JCCo, job);

                _ws.Cells.Range["A1"].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = _ws.Cells.Range["A1:H1"];
                rng.Merge();
                rng.Value = "PROJECT OVERVIEW: " + job + "_" + kv.Value;
                rng.Font.Size = HelperUI.TwentyFontSizePageHeader;
                rng.Font.Bold = true;

                // overview section
                int row_offset = 4;
                int count = contJobHeaderDtl_table.Columns.Count / 2;

                for (int i = 1; i <= count; i++)
                {
                    rng = _ws.Cells[row_offset + i - 1, 1];
                    rng.Value = contJobHeaderDtl_table.Columns[i - 1].ColumnName;
                    rng.Font.Name = "Calibri Light";
                    rng.Font.Bold = true;
                    rng.Font.Italic = true;
                    _ws.Names.Add(rng.Value.Replace(" ", "").Replace("%", "Percent"), _ws.Cells[row_offset + i - 1, 2]);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                }

                for (int i = count; i <= contJobHeaderDtl_table.Columns.Count - 1; i++)
                {
                    rng = _ws.Cells[i - count + row_offset, 3];
                    rng.Value = contJobHeaderDtl_table.Columns[i].ColumnName;
                    rng.Font.Name = "Calibri Light";
                    rng.Font.Bold = true;
                    rng.Font.Italic = true;
                    _ws.Names.Add(rng.Value.Replace(" ", "").Replace("%", "Percent"), _ws.Cells[i - count + row_offset, 4]);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                }

                _ws.get_Range("E" + row_offset + ":E" + (count + row_offset)).Borders[Excel.XlBordersIndex.xlInsideHorizontal].Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                _ws.get_Range("E" + row_offset + ":E" + (count + row_offset)).Borders[Excel.XlBordersIndex.xlInsideHorizontal].Weight = Excel.XlBorderWeight.xlThin;

                foreach (Excel.Name namedRange in _ws.Names)
                {
                    _ws.Names.Item(namedRange.Name).RefersToRange.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
                    _ws.Names.Item(namedRange.Name).RefersToRange.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;

                    if (namedRange.Name.Contains("Value") || namedRange.Name.Contains("Cost"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.Style = HelperUI.CurrencyStyle;
                    }
                    else if (namedRange.Name.Contains("JCDepartment"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.StringFormat;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    }
                    else if (namedRange.Name.Contains("ETC"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.StringFormat;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                    }
                    else if (namedRange.Name.Contains("Percent"))
                    {
                        _ws.Names.Item(namedRange.Name).RefersToRange.NumberFormat = HelperUI.PercentFormat;
                        _ws.Names.Item(namedRange.Name).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                    }
                    else if (namedRange.Name.Contains("Date") || namedRange.Name.Contains("Through") || namedRange.Name.Contains("Month"))
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
                    _ws.Cells[row_offset + i - 1, 2].Value = contJobHeaderDtl_table.Rows[0].Field<object>(i - 1);
                }

                for (int i = count; i <= contJobHeaderDtl_table.Columns.Count - 1; i++)
                {
                    _ws.Cells[i - count + row_offset, 4].Value = contJobHeaderDtl_table.Rows[0].Field<object>(i);
                }

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

                contJobCTSum_table = JobCTSum.GetJobCTSumTable(JCCo, _Contract, job, MonthSearch);

                SheetBuilder.BuildGenericTable(_ws, contJobCTSum_table, LastCellOffsetStartRow: 3);

                _table = _ws.ListObjects[1];

                rn = (uint)_table.HeaderRowRange.Row;
                _ws.Cells.Range["A" + rn].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = _ws.Cells.Range["A" + rn + ":F" + rn];
                rng.Merge();
                rng.Value = "Cost Type Breakdown".ToUpper();
                rng.Interior.Color = HelperUI.GrayBreakDownHeaderRowColor;
                rng.Font.Size = HelperUI.FourteenBreakDownHeaderFontSize;
                rng.Font.Color = HelperUI.WhiteDownHeaderFontColor;
                rng.Font.Bold = true;
                rng.RowHeight = 21;

                _table.HeaderRowRange.RowHeight = 30;

                HelperUI.SortAscending(_ws, "Cost Type", null, 1);

                rng = _ws.Range[_ws.Cells[rng.Row + 1, 1], _ws.Cells[_table.TotalsRowRange.Row + 1, 1]];
                int CTBreak = rng.Row + 1;
                int CTBreakEnd = _table.TotalsRowRange.Row + 1;

                contJobParentPhaseSum_table = JobParentPhaseSum.GetJobParentPhaseSumTable(JCCo, job);

                if (contJobParentPhaseSum_table.Rows.Count > 0)
                {
                    SheetBuilder.BuildGenericTable(_ws, contJobParentPhaseSum_table, 4);

                    _table = _ws.ListObjects[2];

                    rn = (uint)_table.HeaderRowRange.Row - 1;
                    _ws.Cells.Range["A" + rn].EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                    rng = _ws.Cells.Range["A" + rn + ":F" + rn];
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

                    // Parent Phase Group Breakdown
                    rng = _ws.Range[_ws.Cells[rng.Row + 1, 1], _ws.Cells[_table.TotalsRowRange.Row, 1]];
                    rng.EntireRow.Group();
                    rng.EntireRow.Hidden = false;
                    HelperUI.FormatHoursCost(_ws, 2);

                    _table.HeaderRowRange.EntireRow.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    _table.TotalsRowRange.Locked = false;
                }

                _ws.Range[_ws.Cells[CTBreak - 1, 1], _ws.Cells[CTBreakEnd, 1]].EntireRow.Group();
                _ws.UsedRange.Font.Name = HelperUI.FontCalibri;
                HelperUI.PrintPageSetup(_ws);

                _ws.UsedRange.Locked = true;
                _ws.ListObjects[1].TotalsRowRange.Locked = false;
                _ws.Range[_ws.Range["G2"], _ws.Cells[_table.HeaderRowRange.Row - 3, _table.ListColumns.Count]].Locked = false;

                HelperUI.ProtectSheet(_ws, false, false);
            }

            if (_ws != null) Marshal.ReleaseComObject(_ws);
            if (after != null) Marshal.ReleaseComObject(after);
        }

        private void DisableGridlines(Excel.Worksheet ws = null)
        {
            workbook.Activate();

            if (ws == null)
            {
                foreach (KeyValuePair<string, string> kv in job_list)
                {
                    string job = HelperUI.JobTrimDash(kv.Key);
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

        private void btnProjectedRevCurve_Click(object sender, EventArgs e)
        {
            _ws = HelperUI.GetSheet(revCurve);
            string orig_text = btnProjectedRevCurve.Text;

            try
            {
                btnProjectedRevCurve.Text = "Processing...";
                btnProjectedRevCurve.Enabled = false;

                BuildPRGPivot_RevCurve(_ws);

                btnProjectedRevCurve.Text = orig_text;
                btnProjectedRevCurve.Enabled = true;

                lblMonth.Visible = false;
                cboMonth.Visible = false;
                btnCopyDetailOffline.Text = "Copy Rev Offline Detail";
                btnCopyDetailOffline.Visible = true;
                btnCopyDetailOffline.Tag = copyFutureCurveOffline;
            }
            catch (Exception ex)
            {
                btnProjectedRevCurve.Enabled = true;
                btnProjectedRevCurve.Text = orig_text;
                lblMonth.Visible = true;
                cboMonth.Visible = true;
                if (_ws != null)
                {
                    Globals.ThisWorkbook.Application.DisplayAlerts = false;
                    _ws.Delete();
                    Globals.ThisWorkbook.Application.DisplayAlerts = true;
                }
                Globals.ThisWorkbook.Sheets[lastContractNoDash].Activate();
                ShowErr(ex);
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, null, null, RevBatchId, ErrorTxt: ex.Message);
            }
        }

        private void BuildPRGPivot_RevCurve(Excel.Worksheet ws)
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
                contractPRGPivot_table = ContractPRGPivot.GetContractPRGPivotTable(JCCo, _Contract);
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

                // description of months periods above table header
                string startColLetter = RevStartCell.Address[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1]?.Split('$')[1];

                string endColLetter = RevEndCell.Address[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1];

                int rowNum = int.Parse(endColLetter.Split('$')[2]);
                --rowNum;

                endColLetter = endColLetter.Split('$')[1];

                periods = ws.get_Range(startColLetter + rowNum + ":" + endColLetter + rowNum);
                periods.Merge();
                periods.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                periods.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                periods.Value = "Projected revenue by month based on cost estimate and margin";

                // months
                periods = ws.get_Range(RevStartCell, RevEndCell);

                // new formatting to reflect on chart
                // clone period months
                int newRowNum = PRGPivot.TotalsRowRange.Row + 3;

                RevEndCell = ws.get_Range(endColLetter + newRowNum);

                rng = ws.get_Range(startColLetter + newRowNum + ":" + endColLetter + newRowNum);
                rng.NumberFormat = "MM/yy";
                rng.Value2 = periods.Value2;
                rng.Font.Color = HelperUI.WhiteFontColor;

                // clone dollars
                periods = ws.get_Range(startColLetter + (RevStartCell.Row + 1) + ":" + endColLetter + (PRGPivot.TotalsRowRange.Row - 1));

                rng = ws.get_Range(startColLetter + (PRGPivot.TotalsRowRange.Row + 4) + ":" + endColLetter + (PRGPivot.TotalsRowRange.Row + 3 + PRGPivot.ListRows.Count));
                rng.Value2 = periods.Value2;
                rng.NumberFormat = "$#,##0;$(#,##0);$\" - \"??;(_(@_)";
                rng.Font.Color = HelperUI.WhiteFontColor;

                RevStartCell = ws.get_Range(startColLetter + newRowNum);

                periods.EntireColumn.ColumnWidth = 13;
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

                //for 10/17/2016 1.1 release, postponed per Gen 10/14 - LG
                //for 1/26/17 release per Gen 1/4/17 - LG
                AddRevenueGraph(PRGPivot, RevStartCell, RevEndCell);

                HelperUI.GroupColumns(ws, "Calculated Remaining Revenue", "Margin Change Catch Up", false);
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

        private void AddRevenueGraph(Excel.ListObject PRGPivot, Excel.Range RevStartCell, Excel.Range RevEndCell)
        {
            try
            {
                //  months periods
                string startColLetter = RevStartCell.Address[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1]?.Split('$')[1];
                string endColLetter = RevEndCell.Address[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1]?.Split('$')[1];

                // draw chart area
                int projectCount = PRGPivot.ListRows.Count;
                dynamic startDraw = _ws.UsedRange.Height - (projectCount * 15) - 15;
                var charts = _ws.ChartObjects() as Excel.ChartObjects;
                var chartObj = charts.Add(0, startDraw, (.50 * RevEndCell.Column) * 100, 255) as Excel.ChartObject;
                Excel._Chart chart = chartObj.Chart;

                chartObj.Activate();

                chart.ChartType = Excel.XlChartType.xlColumnClustered;
                chart.ChartColor = 12;

                Excel.SeriesCollection seriesCollection = chart.SeriesCollection();
                Excel.Range months = _ws.get_Range(RevStartCell, RevEndCell);

                Excel.Series series = seriesCollection.NewSeries();
                series.Name = "Total";
                series.XValues = months;
                //series.Values    = _ws.Range[_ws.Cells[PRGPivot.TotalsRowRange.Row, RevStartCell.Column], _ws.Cells[PRGPivot.TotalsRowRange.Row, PRGPivot.ListColumns.Count]];   // _ws.get_Range(startColLetter + col + ":" + endColLetter + col);
                series.Values = _ws.get_Range(startColLetter + PRGPivot.TotalsRowRange.Row + ":" + endColLetter + PRGPivot.TotalsRowRange.Row);
                series.ChartType = Excel.XlChartType.xlColumnClustered;
                series.Format.Fill.ForeColor.RGB = HelperUI.ColorToInt(HelperUI.NavyBlueHeaderRowColor);

                Excel.Axis axis = chart.Axes(Excel.XlAxisType.xlValue, Excel.XlAxisGroup.xlPrimary);
                axis.HasTitle = true;
                axis.AxisTitle.Text = "Projected Revenue";
                //chart.HasAxis[Excel.XlAxisType.xlCategory, Excel.XlAxisGroup.xlPrimary] = true;
                //chart.HasAxis[Excel.XlAxisType.xlValue, Excel.XlAxisGroup.xlPrimary] = true;

                for (int i = 1; i <= projectCount; i++)
                {
                    series = seriesCollection.NewSeries();
                    int row = PRGPivot.TotalsRowRange.Row + i + 3;
                    series.Name = _ws.get_Range("A" + (PRGPivot.HeaderRowRange.Row + i)).Formula; // label
                    series.XValues = months;                                                         // X - months
                    series.Values = _ws.get_Range(startColLetter + row + ":" + endColLetter + row); // Y - $
                    series.ChartType = Excel.XlChartType.xlLine;
                    series.AxisGroup = Excel.XlAxisGroup.xlSecondary;
                }
                chart.Legend.Position = Excel.XlLegendPosition.xlLegendPositionLeft;

                //chart.set_HasAxis(Excel.XlAxisType.xlValue, Excel.XlAxisGroup.xlSecondary, true);
                //chart.set_HasAxis(Excel.XlAxisType.xlCategory, Excel.XlAxisGroup.xlSecondary, true);
            }
            catch (Exception) { throw; }
        }

        private void btnSubcontracts_Click(object sender, EventArgs e)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xltable = null;
            string origText = btnSubcontracts.Text;
            Application.UseWaitCursor = true;

            try
            {
                btnSubcontracts.Text = "Processing...";
                btnSubcontracts.Enabled = false;

                string job = HelperUI.JobTrimDash(Job);
                string sheetname = subcontracts + job;
                ws = HelperUI.GetSheet(sheetname);

                if (ws != null)
                {
                    btnSubcontracts.Enabled = true;
                    btnSubcontracts.Text = origText;
                    ws.Activate();
                    return;
                }

                List<dynamic> table = Subcontracts.GetSubcontracts(Job);

                if (table.Count == 0)
                {
                    MessageBox.Show("No Subcontracts found in Viewpoint for this Project");
                    return;
                }

                RenderOFF();
                // ---------------------------------------------------------------------------------------------------
                ws = HelperUI.AddSheet(sheetname, workbook.Sheets[nonLaborSheet + job]);

                HelperUI.CreateTitleHeader(ws, "SUBCONTRACT WORKSHEET: " + (JobGetTitle.GetTitle(JCCo, Job)).ToUpper());
                ws.Application.ActiveWindow.DisplayGridlines = false;

                //Stopwatch t2 = new Stopwatch(); t2.Start();

                SheetBuilderDynamic.BuildTable(ws, table, sheetname);

                //t2.Stop(); MessageBox.Show(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", t2.Elapsed.ToString()));

                xltable = ws.ListObjects[1];
                FormatReportWithHeaders(ws, xltable);

                #region Column Widths
                xltable.ListColumns["SubContract"].Range.EntireColumn.ColumnWidth = 12.5;
                xltable.ListColumns["Description"].Range.EntireColumn.ColumnWidth = 24;
                xltable.ListColumns["Vendor #"].Range.EntireColumn.ColumnWidth = 10;
                xltable.ListColumns["Vendor"].Range.EntireColumn.ColumnWidth = 24;
                xltable.ListColumns["Phase Code"].Range.EntireColumn.ColumnWidth = 11.5;
                //xltable.ListColumns["Cost Type"].Range.EntireColumn.ColumnWidth = 8;
                xltable.ListColumns["Line Descr"].Range.EntireColumn.ColumnWidth = 24;
                xltable.ListColumns["Line Count"].Range.EntireColumn.ColumnWidth = 8;
                xltable.ListColumns["SL Status"].Range.EntireColumn.ColumnWidth = 9.5;
                xltable.ListColumns["Current Amount"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Invoiced"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Paid"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Retainage"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Current Due"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Remaining Committed"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Overspend"].Range.EntireColumn.ColumnWidth = 14.5;
                #endregion

                xltable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                xltable.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["SubContract"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                //xltable.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Line Descr"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Vendor"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Vendor #"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["SL Status"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                HelperUI.PrintPageSetup(ws);

                // ---------------------------------------------------------------------------------------------------
                tmrRestoreButtonText.Tag = new object[] { btnSubcontracts, origText };
                tmrRestoreButtonText.Enabled = true;
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, MonthSearch, CostBatchId, Details: subcontracts);
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, MonthSearch, CostBatchId, ErrorTxt: ex.Message,
                                                 Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                ShowErr(ex);
                workbook.Application.DisplayAlerts = false;
                if (ws != null) ws.Delete();
                ws = HelperUI.GetSheet(costSumSheet, false);
                if (ws != null) ws.Activate();
                workbook.Application.DisplayAlerts = true;
            }
            finally
            {
                RenderON();
                btnSubcontracts.Enabled = true;
                btnSubcontracts.Text = origText;
                Application.UseWaitCursor = false;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        private void btnPOs_Click(object sender, EventArgs e)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xltable = null;
            string origText = btnPOs.Text;
            Application.UseWaitCursor = true;

            try
            {
                btnPOs.Text = "Processing...";
                btnPOs.Enabled = false;

                string job = HelperUI.JobTrimDash(Job);
                string pos_sheetname = pos + job;
                ws = HelperUI.GetSheet(pos_sheetname);

                if (ws != null)
                {
                    btnPOs.Enabled = true;
                    btnPOs.Text = origText;
                    ws.Activate();
                    return;
                }

                List<dynamic> table = POs.GetPOs(Job);

                if (table.Count == 0)
                {
                    throw new Exception("No POs found in Viewpoint for this Project");
                }
                RenderOFF();
                // ---------------------------------------------------------------------------------------------------
                ws = HelperUI.AddSheet(pos_sheetname, workbook.Sheets[nonLaborSheet + job]);

                HelperUI.CreateTitleHeader(ws, "PURCHASE ORDER WORKSHEET: " + (JobGetTitle.GetTitle(JCCo, Job)).ToUpper());
                ws.Application.ActiveWindow.DisplayGridlines = false;

                //Stopwatch t2 = new Stopwatch(); t2.Start();

                SheetBuilderDynamic.BuildTable(ws, table, pos_sheetname);

                //t2.Stop(); MessageBox.Show(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", t2.Elapsed.ToString()));

                xltable = ws.ListObjects[1];

                xltable.ListColumns[xltable.ListColumns.Count].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

                FormatReportWithHeaders(ws, xltable);

                #region Column Widths
                xltable.ListColumns["PO Req #"].Range.EntireColumn.ColumnWidth = 11.5;
                xltable.ListColumns["McK PO"].Range.EntireColumn.ColumnWidth = 8.5;
                xltable.ListColumns["Description"].Range.EntireColumn.ColumnWidth = 26;
                xltable.ListColumns["Item Count"].Range.EntireColumn.ColumnWidth = 8;
                xltable.ListColumns["Vendor"].Range.EntireColumn.ColumnWidth = 8;
                xltable.ListColumns["Vendor Name"].Range.EntireColumn.ColumnWidth = 20;
                xltable.ListColumns["PO Status"].Range.EntireColumn.ColumnWidth = 10;
                xltable.ListColumns["PO Amount"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Invoiced"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Paid"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Current Due"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Remaining Committed"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Overspend"].Range.EntireColumn.ColumnWidth = 14.5;
                xltable.ListColumns["Phase Code"].Range.EntireColumn.ColumnWidth = 11;
                xltable.ListColumns["Cost Type"].Range.EntireColumn.ColumnWidth = 6;
                xltable.ListColumns["Phase Code Description"].Range.EntireColumn.ColumnWidth = 15.5;
                xltable.ListColumns["WO #"].Range.EntireColumn.ColumnWidth = 10;
                xltable.ListColumns["Work Order Description"].Range.EntireColumn.ColumnWidth = 15.5;
                xltable.ListColumns["Ordered By"].Range.EntireColumn.ColumnWidth = 7.75;
                xltable.ListColumns["Ordered By Name"].Range.EntireColumn.ColumnWidth = 12;
                xltable.ListColumns["Order Date"].Range.EntireColumn.ColumnWidth = 12;

                #endregion

                #region Text Alignment
                xltable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                xltable.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["PO Req #"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["McK PO"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Item Count"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Vendor"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Vendor Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["PO Status"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["PO Status"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                //xltable.ListColumns["Phase Code"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Phase Code"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Phase Code Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["WO #"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Work Order Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Ordered By"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Ordered By Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Order Date"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;



                #endregion

                HelperUI.PrintPageSetup(ws);
                // ---------------------------------------------------------------------------------------------------
                tmrRestoreButtonText.Tag = new object[] { btnPOs, origText };
                tmrRestoreButtonText.Enabled = true;

                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, MonthSearch, CostBatchId, Details: pos);
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, MonthSearch, CostBatchId, ErrorTxt: ex.Message,
                                                 Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                ShowErr(ex);
                workbook.Application.DisplayAlerts = false;
                if (ws != null) ws.Delete();
                ws = HelperUI.GetSheet(costSumSheet, false);
                if (ws != null) ws.Activate();
                workbook.Application.DisplayAlerts = true;
            }
            finally
            {
                RenderON();
                btnPOs.Enabled = true;
                btnPOs.Text = origText;
                Application.UseWaitCursor = true;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        private static void FormatReportWithHeaders(Excel.Worksheet ws, Excel.ListObject xltable)
        {
            xltable.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
            xltable.HeaderRowRange.EntireRow.RowHeight = 26.5;
            xltable.HeaderRowRange.EntireRow.WrapText = true;
            xltable.HeaderRowRange.EntireColumn.AutoFit();
            //xltable.ListColumns[xltable.ListColumns.Count].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

            ws.UsedRange.Font.Name = HelperUI.FontCalibri;
            ws.Tab.Color = HelperUI.GreenPosColor;

            int lastRow = xltable.TotalsRowRange.Row - 1;
            ws.Cells.Locked = false;
            ws.get_Range("A1:A" + lastRow).Rows.EntireRow.Locked = true;
            HelperUI.ProtectSheet(ws, false, false);
        }

        #endregion


        #region GENERATE PROJECTIONS

        private bool GenerateRevenueProjections()
        {
            isRendering = true;
            bool success = false;

            if (HelperUI.SheetExists(revSheet, false))
            {
                MessageBox.Show("Only 1 Revenue batch can be open at a time. \n\nPlease post the other batch before attempting to open a Revenue batch for this project.");
                return false;
            }

            if (Login == "")
            {
                MessageBox.Show("Unable to validate you as a valid user in Viewpoint.\n\n" + "Make sure Viewpoint is online and check your access.");
                return false;
            }

            Pivot = "MONTH";

            try
            {
                MonthSearch = DateTime.Parse(cboMonth.SelectedItem.ToString());
                success = ProjectRevenue.GenerateRevenueProjection(JCCo, _Contract, MonthSearch, Login, out revBatchId, out revBatchDateCreated);
                RevBatchId = revBatchId;
                if (success)
                {
                    contJectRevenue_table = ConJectBatchSummary.GetConJectBatchSumTable(JCCo, _Contract, MonthSearch);
                    RenderOFF();

                    if (contJectRevenue_table.Rows.Count > 0)
                    {
                        string sheetname = "Rev-" + _Contract.Replace("-", "");

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
            catch (Exception) { throw; }
            finally
            {
                //Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                //Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
                RenderON();
            }

            return true;
        }

        private bool GenerateCostProjections2()
        {
            isRendering = true;

            if (HelperUI.SheetExists(costSumSheet, false))
            {
                MessageBox.Show("Only 1 cost batch can be open at a time. \n\nPlease post the other batch before attempting to open a cost batch for this project.");
                return false;
            }

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

                hours_weeks = Globals.ThisWorkbook.Application.Sheets["-" + HelperUI.JobTrimDash(Job)].Names("LaborTimeEntry").RefersToRange.Value;
                MonthSearch = DateTime.Parse(cboMonth.SelectedItem.ToString());
                //Stopwatch t2 = new Stopwatch(); t2.Start();
                success = JobJectCostProj.GenerateCostProjection(JCCo, _Contract, Job, MonthSearch, Login, out costBatchId, out costBatchDateCreated, out newProjection, hours_weeks);
                CostBatchId = costBatchId;
                //t2.Stop(); MessageBox.Show(string.Format("Time elapsed: {0:hh\\:mm\\:ss\\:ff}", t2.Elapsed));

                if (success)
                {
                    // -----------------------------------------------------*************************************************************************************
                    //Stopwatch t2 = new Stopwatch(); t2.Start();

                    // Summary tab
                    contJobJectBatchSum_table = JobJectBatchSummary.GetJobJectBatchSummaryTable(JCCo, Job, MonthSearch);

                    //t2.Stop();
                    //Debug.Print("time elapsed: " + t2.Elapsed.ToString() + " + diff " + diff.Duration());
                    //diff = diff.Add(t2.Elapsed);
                    //Debug.Print(string.Format("= {0}", diff.Duration()));
                    //t2.Reset();
                    RenderOFF();
                    string job = HelperUI.JobTrimDash(Job);

                    if (contJobJectBatchSum_table.Rows.Count > 0)
                    {
                        newSheetName = costSumSheet + job;

                        _wsSum = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

                        SheetBuilderJCPB.BuildTable(_wsSum, contJobJectBatchSum_table);

                        SetupSumTab2(_wsSum);

                        // NonLabor tab
                        contJobJectBatchNonLabor_table = JobJectBatchNonLabor.GetJobJectBatchNonLaborTable(JCCo, Job, Pivot);

                        if (contJobJectBatchNonLabor_table.Rows.Count > 0)
                        {
                            newSheetName = nonLaborSheet + job;
                            _wsNonLabor = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

                            SheetBuilder.BuildGenericTable(_wsNonLabor, contJobJectBatchNonLabor_table);
                            Globals.ThisWorkbook.PivotNonLaborRowCount = contJobJectBatchNonLabor_table.Rows.Count;

                            SetupNonLaborTab2(_wsNonLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd, out colBeforeEntry);
                        }

                        // Labor tab
                        LaborPivot = LaborPivotSearch.GetLaborPivot(JCCo, Job);
                        contJobJectBatchLabor_table = JobJectBatchLabor.GetJobJectBatchLaborTable(JCCo, Job, LaborPivot);

                        //Debug.Print(diff.Duration().ToString());
                        //MessageBox.Show(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", diff.Duration().ToString()));

                        if (contJobJectBatchLabor_table.Rows.Count > 0)
                        {
                            newSheetName = laborSheet + job;

                            _wsLabor = HelperUI.AddSheet(newSheetName, _wsSum);

                            SheetBuilder.BuildGenericTable(_wsLabor, contJobJectBatchLabor_table);

                            Globals.ThisWorkbook.PivotLaborRowCount = contJobJectBatchLabor_table.Rows.Count;

                            SetupLaborTab2(_wsSum, _wsNonLabor, _wsLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd);
                        }

                        #region FINALIZE SUMMARY TAB
                        SetSumTabFormulas(_wsSum, _wsLabor, _wsNonLabor);
                        workbook.Activate();

                        if (_wsLabor != null)
                        {
                            _wsLabor.Activate();
                            _wsLabor.Application.ActiveWindow.DisplayGridlines = false;
                            _wsLabor.get_Range("A1").Activate();
                            HelperUI.FreezePane(_wsLabor, "Employee ID");

                            if (LaborTime == LaborEnum.Manweeks) ConvertLaborTime(LaborEnum.Manweeks);
                            HelperUI.ApplyUsedFilter(_wsLabor, "Used", 1);
                        }

                        if (_wsNonLabor != null)
                        {
                            _wsNonLabor.Activate();
                            _wsNonLabor.Application.ActiveWindow.DisplayGridlines = false;
                            _wsNonLabor.get_Range("A1").Activate();
                            HelperUI.FreezePane(_wsNonLabor, "Description");
                            HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[_wsNonLabor.ListObjects[1].HeaderRowRange.Row, nonLaborMonthStart].Value);
                            HelperUI.ApplyUsedFilter(_wsNonLabor, "Used");
                        }

                        if (_wsSum != null)
                        {
                            _wsSum.Activate();
                            _wsSum.Application.ActiveWindow.DisplayGridlines = false;
                            _wsSum.get_Range("A1").Activate();
                            HelperUI.ApplyUsedFilter(_wsSum, "Used", 1);
                        }
                        #endregion
                    }
                    else
                    {
                        // empty batch has been created - needs cancelling
                        string msg;
                        string title;
                        try
                        {
                            if (DeleteCostBatch.DeleteBatchCost(JCCo, MonthSearch, CostBatchId))
                            {
                                LogProphecyAction.InsProphecyLog(Login, 10, JCCo, _Contract, Job, MonthSearch, CostBatchId, "Project no Phase Codes");

                                title = "Generate Cost Projection Failed";
                                msg = "A Cost Projection cannot be generated for a Project with no Phase Codes attached to it.\n\n" +
                                      "The batch has been cancelled.";
                            }
                            else
                            {
                                LogProphecyAction.InsProphecyLog(Login, 9, JCCo, _Contract, Job, MonthSearch, CostBatchId, "Cancel Project no Phase Codes");

                                // possible connectivity issue
                                title = "Cancel Cost Batch Failed";
                                msg = "A Cost Projection cannot be generated for a Project with no Phase Codes attached to it.\n" +
                                      "An attempt to cancel the batch has failed.\n\n" +
                                      "Please contact Viewpoint Training for assistance.";
                            }

                            CostBatchId = 0;

                            ShowErr(new Exception(msg), title: title);
                        }
                        catch (Exception ex)
                        {
                            LogProphecyAction.InsProphecyLog(Login, 10, JCCo, _Contract, Job, MonthSearch, CostBatchId, ex.Message);
                            ShowErr(ex);
                        }
                        return false;
                        //MessageBox.Show("Please review your project set up and/or contact Viewpoint Training for assistance.", "Summary", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, 3);
                CostJectErrOut(ex);
                return false;
            } // possible exceptions from the back-end or UI
            finally
            {
                //Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                //Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
                RenderON();
                #region CLEAN UP
                if (_wsLabor != null) { Marshal.ReleaseComObject(_wsLabor); }
                if (_wsNonLabor != null) { Marshal.ReleaseComObject(_wsNonLabor); }
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
                #endregion
            }
            return true;
        }

        #endregion


        #region Setup Sum, Labor, Nonlabor and Revenue sheets

        #region SUM TAB SETUP
        private void SetupSumTab2(Excel.Worksheet _ws)
        {
            Excel.Range batchDateCreated = null;
            Excel.Range projectedCost = null;
            Excel.Range projectedMargin = null;
            Excel.Range useManualETC = null;

            Excel.Range manualETCCost = null;
            Excel.Range manualETCHours = null;
            Excel.Range manualETC_CST_HR = null;

            try
            {
                if (_ws == null) throw new Exception("SetupSumTab2: CostSum tab is missing");
                _table = _ws.ListObjects[1];
                _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                _ws.get_Range("A1:AH1").Merge();

                _ws.get_Range("A1").Formula = JobGetTitle.GetTitle(JCCo, Job) + " Summary Worksheet";
                _ws.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                _ws.get_Range("A1").Font.Bold = true;

                _ws.get_Range("A2").Formula = "Batch Created on: ";
                _ws.get_Range("A2:D2").Font.Color = HelperUI.McKColor(HelperUI.McKColors.Black);
                _ws.get_Range("D2").NumberFormat = "d-mmm-yyyy h:mm AM/PM";
                _ws.get_Range("D2").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                _ws.get_Range("D2").Formula = costBatchDateCreated;
                _ws.get_Range("D2").AddComment("All times Pacific");
                batchDateCreated = _ws.get_Range("A2:D2");

                //Excel.FormatCondition batchDateCreatedCond = (Excel.FormatCondition)batchDateCreated.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                //                                    Type.Missing, "=IF(" + _ws.get_Range("D2").Address + "=\"\",\"\"," + _ws.get_Range("D2").Address + "< TODAY())",
                //                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                //rng = _ws.get_Range("D2");
                batchDateCreated.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                batchDateCreated.Font.Color = HelperUI.WhiteFontColor;
                batchDateCreated.Font.Bold = true;


                //BEGIN Top of Cost Summary Sheet Header Numbers

                // NEW PROJECTED COST: LABEL
                int atRow = _table.HeaderRowRange.Row - 4;
                int begin = _table.ListColumns["Projected Hours"].Index;
                int end = _table.ListColumns["Projected Cost"].Index;
                projectedCost = _ws.Cells.Range[_ws.Cells[atRow, begin], _ws.Cells[atRow, end + 1]];
                projectedCost.Font.Bold = true;
                projectedCost.Font.Size = HelperUI.TwelveFontSizeHeader;

                projectedCost = _ws.Cells.Range[_ws.Cells[atRow, begin], _ws.Cells[atRow, end]];
                projectedCost.Merge();
                projectedCost.Formula = "New Projected Cost";
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
                projectedCost.Font.Color = HelperUI.SoftBlackHeaderFontColor;

                // NEW PROJECTED COST: $ VALUE
                projectedCost = _ws.Cells[atRow, end + 1];
                projectedCost.Font.Color = HelperUI.WhiteFontColor;
                projectedCost.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                _ws.Names.Add("NewProjectedCost", projectedCost);
                projectedCost.NumberFormat = HelperUI.CurrencyFormatCondensed;
                projectedCost.FormulaLocal = "=SUM(" + _table.ListColumns["Projected Cost"].DataBodyRange.Address + ")";
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeBottom].ColorIndex = 2;
                projectedCost.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
                projectedCost.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                // NEW PROJECTED MARGIN: LABEL
                atRow = _table.HeaderRowRange.Row - 3;

                projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, begin], _ws.Cells[atRow, end + 1]];
                projectedMargin.Font.Size = HelperUI.TwelveFontSizeHeader;
                projectedMargin.Font.Bold = true;
                _ws.Cells[atRow, begin].AddComment("based on most recent posted revenue projection");

                projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, begin], _ws.Cells[atRow, end]];
                projectedMargin.Merge();
                projectedMargin.Formula = "New Projected Margin";
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
                projectedMargin.Font.Color = HelperUI.SoftBlackHeaderFontColor;

                // NEW PROJECTED MARGIN: % VALUE 
                projectedMargin = _ws.Cells[atRow, end + 1];
                projectedMargin.Font.Color = HelperUI.WhiteFontColor;
                projectedMargin.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                projectedMargin.Font.Size = HelperUI.TwelveFontSizeHeader;
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 2;
                projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThick;
                projectedMargin.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;
                _ws.Names.Add("NewProjectedMargin", projectedMargin);

                //BEGIN Manual ETC Addition;
                useManualETC = _ws.get_Range("AE" + atRow + ":" + "AF" + atRow);
                useManualETC.Merge();
                useManualETC.Value = "Full Manual ETC:";
                useManualETC.Font.Color = HelperUI.WhiteFontColor;
                useManualETC.Font.Bold = true;
                useManualETC.Font.Size = HelperUI.TwelveFontSizeHeader;
                useManualETC.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
                useManualETC.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeLeft].ColorIndex = 2;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeLeft].Weight = Excel.XlBorderWeight.xlThick;

                useManualETC = _ws.get_Range("AG" + atRow);
                useManualETC.Validation.Add(Excel.XlDVType.xlValidateList, Excel.XlDVAlertStyle.xlValidAlertStop, Excel.XlFormatConditionOperator.xlBetween, "Yes, No");
                useManualETC.Validation.ErrorTitle = "Invalid Selection";
                useManualETC.Validation.ErrorMessage = "For Manual ETC select Yes.\nFor Detail select No.";

                string job = _ws.Name.Substring(_ws.Name.IndexOf('-', 0, _ws.Name.Length));

                if (newProjection)
                {
                    //get from report
                    useManualETC.Value = Globals.ThisWorkbook.Application.Sheets[job].Names["FullETCOverride"].RefersToRange.Value;
                    if (!Convert.IsDBNull(Globals.ThisWorkbook.Application.Sheets[job].Names["LaborTimeEntry"].RefersToRange.Value))
                    {
                        hours_weeks = Globals.ThisWorkbook.Application.Sheets[job].Names["LaborTimeEntry"].RefersToRange.Value;
                        hours_weeks = hours_weeks == "Manweeks" ? "W" : "H";
                        LaborTime = hours_weeks == "W" ? LaborEnum.Manweeks : LaborEnum.Hours;
                    }
                    else
                    {
                        hours_weeks = "H";
                        LaborTime = LaborEnum.Hours;
                    }
                }
                else
                {
                    //query log
                    List<dynamic> table = JobJectETC.GetFullETC(cboJobs.SelectedItem.ToString(), MonthSearch, costBatchId);

                    if (table.Count > 0)
                    {
                        foreach (var r in table)
                        {
                            useManualETC.Value = r.FullETC == "Y" ? "YES" : "No";
                            hours_weeks = Convert.IsDBNull(r.HoursWeeks) ? "H" : r.HoursWeeks;
                            LaborTime = hours_weeks == "W" ? LaborEnum.Manweeks : LaborEnum.Hours;
                        }
                    }
                    else
                    {
                        useManualETC.Value = "No";
                        hours_weeks = "H";
                        LaborTime = hours_weeks == "W" ? LaborEnum.Manweeks : LaborEnum.Hours;
                    }
                }

                useManualETC.Font.Bold = true;
                useManualETC.Font.Size = HelperUI.TwelveFontSizeHeader;
                useManualETC.Interior.Color = HelperUI.DataEntryColor;
                useManualETC.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeTop].ColorIndex = 1;
                useManualETC.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;

                //END Manual ETC Addition;
                useManualETC.Application.EnableAutoComplete = false;

                CostSum_ProjectedMargin_Fill();

                #region FIELD DESC
                HelperUI.AddFieldDesc(_ws, "Used", "See comment");
                HelperUI.AddFieldDesc(_ws, "Parent Phase Description", "Parent phase grouping");
                HelperUI.AddFieldDesc(_ws, "Phase Code", "Phase Code");
                HelperUI.AddFieldDesc(_ws, "Phase Description", "Phase description");
                HelperUI.AddFieldDesc(_ws, "Cost Type", "Cost Type");
                HelperUI.AddFieldDesc(_ws, "Original Manweeks", "Original Manweeks Estimate");
                HelperUI.AddFieldDesc(_ws, "Original Hours", "Original Hours Estimate");
                HelperUI.AddFieldDesc(_ws, "Original Cost", "Original Cost Estimate");
                HelperUI.AddFieldDesc(_ws, "Appr CO Hours", "Approved and interfaced change order hours");
                HelperUI.AddFieldDesc(_ws, "Appr CO Cost", "Approved and interfaced change order cost");
                HelperUI.AddFieldDesc(_ws, "PCO Hours", "Sum of pending change order (PCO) hours in Viewpoint");
                HelperUI.AddFieldDesc(_ws, "PCO Cost", "Sum of pending change order (PCO) cost");
                HelperUI.AddFieldDesc(_ws, "Curr Est Manweeks", "Original estimated Manweeks plus interfaced change order Manweeks");
                HelperUI.AddFieldDesc(_ws, "Curr Est Hours", "Original estimated hours plus interfaced change order hours");
                HelperUI.AddFieldDesc(_ws, "Curr Est Cost", "Original estimate + interfaced change orders");
                HelperUI.AddFieldDesc(_ws, "JTD Actual Manweeks", "Actual hours completed as entered through Payroll (timesheets) divided by 40");
                HelperUI.AddFieldDesc(_ws, "JTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets)");
                HelperUI.AddFieldDesc(_ws, "Batch MTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets) for the current batch month");
                HelperUI.AddFieldDesc(_ws, "JTD Actual Cost", "Actual cost posted to the project");
                HelperUI.AddFieldDesc(_ws, "Batch MTD          Actual Cost", "Actual cost incurred on the project for the current batch month");
                HelperUI.AddFieldDesc(_ws, "Total Hours - All Closed Months", "Actual hours incurred through the end of the prior closed month");
                HelperUI.AddFieldDesc(_ws, "Total Cost - All Closed Months", "Actual cost incurred through the end of the prior closed month");
                HelperUI.AddFieldDesc(_ws, "Actual CST/HR", "Actual cost divided by actual hours");
                HelperUI.AddFieldDesc(_ws, "Total Committed Cost", "Total committments by phase/cost type");
                HelperUI.AddFieldDesc(_ws, "Projected Remaining Manweeks", "Sum of hours on labor worksheet by phase dived by 40");
                HelperUI.AddFieldDesc(_ws, "Projected Remaining Hours", "Sum of hours on labor worksheet by phase");
                HelperUI.AddFieldDesc(_ws, "Projected Remaining Total Cost", "Sum of remaining cost from labor and non-labor worksheet by phase");
                HelperUI.AddFieldDesc(_ws, "Remaining CST/HR", "Remaining cost divided by remaining hours");
                HelperUI.AddFieldDesc(_ws, "Remaining Committed Cost", "Open or remaining committed cost (negative remaining committed cost may not reflect if there are multiple commitments on phase/CT)");
                HelperUI.AddFieldDesc(_ws, "Remaining Est Hours", "Current Est Hours minus JTD Actual Hours");
                HelperUI.AddFieldDesc(_ws, "JTD + Remaining Committed", "JTD Actual Cost + Remaining Committed Cost");
                HelperUI.AddFieldDesc(_ws, "Manual ETC Hours", "Labor only - Manual ETC Entry allows user to enter total remaining hours");
                HelperUI.AddFieldDesc(_ws, "Manual ETC CST/HR", "Labor only - Manual ETC Entry allows user to enter remaining cost per hour");
                HelperUI.AddFieldDesc(_ws, "Manual ETC Cost", "Non-Labor only - Manual ETC Entry allows user to enter total remaining hours");
                HelperUI.AddFieldDesc(_ws, "Projected Hours", "All Closed Months Hours + Remaining Hours - or - JTD Hours + Manual ETC hours (if used)");
                HelperUI.AddFieldDesc(_ws, "Projected Cost", "All Closed Months Cost + Remaining Cost - or - JTD Actual Cost + Manual ETC Cost (if used)");
                HelperUI.AddFieldDesc(_ws, "Actual Cost > Projected Cost", "If Actual Cost is greater than Projected Cost, the cell will highlight red and warn when saving");
                HelperUI.AddFieldDesc(_ws, "Prev Projected Hours", "Total hours projected from the lasted posted batch");
                HelperUI.AddFieldDesc(_ws, "Prev Projected Cost", "Total cost projected from the last posted batch");
                HelperUI.AddFieldDesc(_ws, "Change in Hours", "Change in total hours projected from last posted batch");
                HelperUI.AddFieldDesc(_ws, "Change in Cost", "Change in total cost projected from last posted batch");
                HelperUI.AddFieldDesc(_ws, "LM Projected Hours", "Hours projected at the end of the last batch month");
                HelperUI.AddFieldDesc(_ws, "LM Projected Cost", "Cost projected at the end of the last batch month");
                HelperUI.AddFieldDesc(_ws, "Change from LM Projected Hours", "Change in total hours projected from last batch month");
                HelperUI.AddFieldDesc(_ws, "Change from LM Projected Cost", "Change in total cost projected from last batch month");
                HelperUI.AddFieldDesc(_ws, "Over/Under Hours", "Current estimated hours (including interfaced change orders) less total projected hours");
                HelperUI.AddFieldDesc(_ws, "Over/Under Cost", "Current estimated cost (including interfaced change orders) less total projected cost");
                #endregion

                HelperUI.MergeLabel(_ws, "Used", "Cost Type", "Phase Detail");
                HelperUI.MergeLabel(_ws, "Original Manweeks", "Original Cost", "Original Estimate (Budget)");
                HelperUI.MergeLabel(_ws, "Appr CO Hours", "PCO Cost", "Change Orders");
                HelperUI.MergeLabel(_ws, "Batch MTD Actual Hours", "Total Committed Cost", "Actual");
                HelperUI.MergeLabel(_ws, "Curr Est Manweeks", "Curr Est Cost", "Current Budget");
                HelperUI.MergeLabel(_ws, "Projected Remaining Manweeks", "Remaining CST/HR", "Projected Remaining (ETC) from Worksheet");
                HelperUI.MergeLabel(_ws, "Remaining Committed Cost", "Remaining Est Hours", "Remaining");
                HelperUI.MergeLabel(_ws, "JTD + Remaining Committed", "Manual ETC Cost", "Manual ETC Entry");
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

                // MANWEEKS
                _table.ListColumns["Original Manweeks"].DataBodyRange.NumberFormat = HelperUI.NumberFormat2Decimals;

                _table.ListColumns["Curr Est Manweeks"].DataBodyRange.NumberFormat = HelperUI.NumberFormat2Decimals;
                _table.ListColumns["JTD Actual Manweeks"].DataBodyRange.NumberFormat = HelperUI.NumberFormat2Decimals;

                _table.ListColumns["Projected Remaining Manweeks"].DataBodyRange.NumberFormat = HelperUI.NumberFormat2Decimals;

                _table.ListColumns["Original Manweeks"].Total.NumberFormat = HelperUI.NumberFormat2Decimals;
                _table.ListColumns["Curr Est Manweeks"].Total.NumberFormat = HelperUI.NumberFormat2Decimals;
                _table.ListColumns["JTD Actual Manweeks"].Total.NumberFormat = HelperUI.NumberFormat2Decimals;

                _table.ListColumns["Manual ETC Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
                _table.ListColumns["Manual ETC CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                _table.ListColumns["Remaining CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;

                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].AddComment("If the phase code has no budgeted, actual or projected cost it is hidden. Adjust column filter to see all rows.");
                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;

                manualETCHours = _ws.Cells[_table.HeaderRowRange.Row + 1, _table.ListColumns["Manual ETC Hours"].Index];
                manualETCCost = _ws.Cells[_table.TotalsRowRange.Row - 1, _table.ListColumns["Manual ETC Cost"].Index];
                CostSumWritable = _ws.get_Range(manualETCHours, manualETCCost);

                CostSumWritable.Interior.Color = HelperUI.DataEntryColor;

                // MANUEL ETC No Alpahnumerics validation rule 
                HelperUI.SetAlphanumericNotAllowedRule(CostSumWritable);

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
                _table.HeaderRowRange.EntireRow.RowHeight = 40.00;
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
                _ws.get_Range("A1:A3").EntireRow.Locked = true;
                useManualETC.Locked = false;
                _table.HeaderRowRange.Locked = true;
                _table.DataBodyRange.Locked = true;
                _table.TotalsRowRange.Locked = false;
                CostSumWritable.Locked = false;

                int costTypeCol = _table.ListColumns["Cost Type"].Index;
                int tblHeadRow = _table.HeaderRowRange.Row;

                manualETCCost = _table.ListColumns["Manual ETC Cost"].DataBodyRange;
                manualETCHours = _table.ListColumns["Manual ETC Hours"].DataBodyRange;
                manualETC_CST_HR = _table.ListColumns["Manual ETC CST/HR"].DataBodyRange;

                //Attempt to Resolve Enter of ZERO value
                //manualETCHours.Value = "";
                //manualETCCost.Value = "";
                //if (manualETCCost == ".02") manualETCCost.Value = "";

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

                        Excel.FormatCondition manualETCHrs_manualETC_CST_HR_Cond = (Excel.FormatCondition)_ws.Range[_ws.Cells[row, manualETCHours.Column], _ws.Cells[row, manualETC_CST_HR.Column]].FormatConditions.Add(
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

                #region COLUMN WIDTH
                _table.ListColumns["Used"].DataBodyRange.EntireColumn.ColumnWidth = 3.50;
                _table.ListColumns["Parent Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 23.50;
                _table.ListColumns["Phase Code"].DataBodyRange.EntireColumn.ColumnWidth = 11.50;
                _table.ListColumns["Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 25.00;
                _table.ListColumns["Cost Type"].DataBodyRange.EntireColumn.ColumnWidth = 6.00;

                _table.ListColumns["Original Manweeks"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
                _table.ListColumns["Original Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Original Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Appr CO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Appr Co Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;
                _table.ListColumns["PCO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["PCO Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;

                _table.ListColumns["Curr Est Manweeks"].DataBodyRange.EntireColumn.ColumnWidth = 10.75;
                _table.ListColumns["Curr Est Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Curr Est Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;

                _table.ListColumns["JTD Actual Manweeks"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
                _table.ListColumns["JTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
                _table.ListColumns["Batch MTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 9.3;
                _table.ListColumns["JTD Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Batch MTD          Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

                _table.ListColumns["Total Hours - All Closed Months"].DataBodyRange.EntireColumn.ColumnWidth = 9.3;
                _table.ListColumns["Total Cost - All Closed Months"].DataBodyRange.EntireColumn.ColumnWidth = 15.00;

                _table.ListColumns["Actual CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
                _table.ListColumns["Total Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

                _table.ListColumns["Projected Remaining Manweeks"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                _table.ListColumns["Projected Remaining Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
                _table.ListColumns["Projected Remaining Total Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Remaining CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
                _table.ListColumns["Remaining Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
                _table.ListColumns["Remaining Est Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                _table.ListColumns["JTD + Remaining Committed"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
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
                _table.ListColumns["Change from LM Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.5;
                _table.ListColumns["Change from LM Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
                _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;

                _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.AutoFit();
                _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.AutoFit();
                #endregion

                HelperUI.PrintPageSetup(_ws);

            }
            catch (Exception ex) { throw new Exception("SetupSumTab: " + ex.Message); }
            finally
            {
                if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
                if (_table != null) Marshal.ReleaseComObject(_table);
                if (projectedCost != null) Marshal.ReleaseComObject(projectedCost);
                if (projectedMargin != null) Marshal.ReleaseComObject(projectedMargin);
                if (manualETCCost != null) Marshal.ReleaseComObject(manualETCCost);
                if (manualETCHours != null) Marshal.ReleaseComObject(manualETCHours);
                if (manualETC_CST_HR != null) Marshal.ReleaseComObject(manualETC_CST_HR);
                if (useManualETC != null) Marshal.ReleaseComObject(useManualETC);
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
                            costSumSheet.Names.Item("NewProjectedMargin").RefersToRange.FormulaLocal = "=IF(" + contractPRG_CV + "<>0,IF(((" + contractPRG_CV + "-" + projtedCost + ")/" + contractPRG_CV + ")>-1,((" + contractPRG_CV + "-" + projtedCost + ")/" + contractPRG_CV + "),-1),-1)";
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

        private void SetSumTabFormulas(Excel.Worksheet _wsSum, Excel.Worksheet _wsLabor, Excel.Worksheet _wsNonLabor)
        {
            Excel.ListObject table = null;

            try
            {
                // Summary tab formulas
                _wsSum.ListObjects[1].ListColumns["Remaining CST/HR"].DataBodyRange.FormulaLocal =
                    "=IF([@[Projected Remaining Hours]]<>\" \",IF([@[Projected Remaining Hours]]>0,[@[Projected Remaining Total Cost]]/[@[Projected Remaining Hours]],\" \"),\" \")";

                _wsSum.ListObjects[1].ListColumns["Used"].DataBodyRange.FormulaLocal = "=IF(OR([@[Original Cost]] <> 0,[@[PCO Cost]]<> 0,[@[Curr Est Cost]]<>0,[@[JTD Actual Cost]]<>0,"
                    + "[@[Total Committed Cost]]<>0,[@[Projected Remaining Total Cost]]<>0,[@[Remaining Committed Cost]]<>0,[@[Prev Projected Cost]]<>0,[@[LM Projected Cost]]<>0),\"Y\",\"N\")";

                _wsSum.ListObjects[1].ListColumns["Projected Hours"].DataBodyRange.FormulaLocal =
                    "=IF([@[Manual ETC Hours]]<>\"\",SUM(IF([@[JTD Actual Hours]]<>\"\",[@[JTD Actual Hours]],0),[@[Manual ETC Hours]]),IF($AG$2=\"Yes\",[@[Prev Projected Hours]],SUM(IF([@[Projected Remaining Hours]]<>\"\",[@[Projected Remaining Hours]],0),IF([@[Total Hours - All Closed Months]]<>\"\",[@[Total Hours - All Closed Months]],0))))";

                _wsSum.ListObjects[1].ListColumns["Projected Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Manual ETC Cost]]<>\"\",SUM(IF([@[JTD + Remaining Committed]]<>\"\",[@[JTD + Remaining Committed]],0),[@[Manual ETC Cost]]),IF($AG$2=\"Yes\",[@[Prev Projected Cost]],SUM(IF([@[Projected Remaining Total Cost]]<>\"\",[@[Projected Remaining Total Cost]],0),IF([@[Total Cost - All Closed Months]]<>\"\",[@[Total Cost - All Closed Months]],0))))";

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

                _wsSum.ListObjects[1].ListColumns["Projected Remaining Manweeks"].DataBodyRange.FormulaLocal = "=IF([@[Projected Remaining Hours]]<>\" \",[@[Projected Remaining Hours]]/40,\" \")";


                // Summary tab formulas that ref Labor tab
                _wsSum.ListObjects[1].ListColumns["Projected Remaining Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;


                _wsSum.ListObjects[1].ListColumns["Projected Remaining Total Cost"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                if (_wsNonLabor != null && _wsLabor == null)
                {
                    //NON LABOR IS THE ONLY TAB
                    table = _wsNonLabor.ListObjects[1];
                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Total Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Cost Type]]=\"L\", 0, SUMIFS(" + table.Name + "[Remaining Cost]," + table.Name + "[Phase Code],[@[Phase Code]]," + table.Name + "[Cost Type],[@[Cost Type]]))";

                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Hours"].DataBodyRange.FormulaLocal = " ";
                }
                else if (_wsNonLabor == null && _wsLabor != null)
                {
                    //LABOR IS THE ONLY TAB
                    table = _wsLabor.ListObjects[1];
                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Total Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Cost Type]]=\"L\", SUMIFS(" + table.Name + "[Projected Remaining Total Cost]," + table.Name + "[Phase Code],[@[Phase Code]]), 0)";
   
                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Hours"].DataBodyRange.FormulaLocal =
                     "=IF([@[Cost Type]]=\"L\", SUMIFS(" + table.Name + "[Projected Remaining Hours]," + table.Name + "[Phase Code],[@[Phase Code]]),\" \")";
                }
                else if (_wsNonLabor != null && _wsLabor != null)
                {
                    //BOTH TABS EXIST
                    table = _wsLabor.ListObjects[1];
                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Total Cost"].DataBodyRange.FormulaLocal =
                    "=IF([@[Cost Type]]=\"L\", SUMIFS(" + table.Name + "[Projected Remaining Total Cost]," + table.Name + "[Phase Code],[@[Phase Code]]), SUMIFS("
                    + _wsNonLabor.ListObjects[1].Name + "[Remaining Cost]," + _wsNonLabor.ListObjects[1].Name + "[Phase Code],[@[Phase Code]]," + _wsNonLabor.ListObjects[1].Name + "[Cost Type],[@[Cost Type]]))";

                    _wsSum.ListObjects[1].ListColumns["Projected Remaining Hours"].DataBodyRange.FormulaLocal =
                         "=IF([@[Cost Type]]=\"L\", SUMIFS(" + table.Name + "[Projected Remaining Hours]," + table.Name + "[Phase Code],[@[Phase Code]]),\" \")";
                }


                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change from LM Projected Cost"]);

                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change from LM Projected Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change in Cost"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Change in Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Over/Under Hours"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Over/Under Cost"]);
                HelperUI.ApplyVarianceFormat(_wsSum.ListObjects[1].ListColumns["Actual Cost > Projected Cost"]);

                _wsSum.Activate();
                HelperUI.FreezePane(_wsSum, "Original Manweeks");

                HelperUI.GroupColumns(_wsSum, "Parent Phase Description", "Parent Phase Description");
                HelperUI.GroupColumns(_wsSum, "Original Manweeks", "PCO Cost");
                HelperUI.GroupColumns(_wsSum, "Prev Projected Hours", "LM Projected Cost");
                HelperUI.GroupColumns(_wsSum, "Batch MTD Actual Hours", "Total Cost - All Closed Months");

                if (_wsSum.get_Range("AG2").Value == "Yes")
                {
                    HelperUI.GroupColumns(_wsSum, "JTD + Remaining Committed", "Manual ETC Cost", false);
                    HelperUI.GroupColumns(_wsSum, "Projected Remaining Manweeks", "Remaining CST/HR");
                }
                else
                {
                    HelperUI.GroupColumns(_wsSum, "JTD + Remaining Committed", "Manual ETC Cost");
                    HelperUI.GroupColumns(_wsSum, "Projected Remaining Manweeks", "Remaining CST/HR", false);
                }


                HelperUI.ProtectSheet(_wsSum, false, false);

            }
            catch (Exception e) { throw new Exception("SetSumTabFormulas: " + e.Message); }
        }
        #endregion

        #region LABOR SETUP

        private void SetupLaborTab2(Excel.Worksheet _wsSum, Excel.Worksheet _wsNonLabor, Excel.Worksheet _wsLabor, out Excel.Range rngHeaders,
            out Excel.Range rngTotals, out Excel.Range rngStart, out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd)
        {
            Excel.Range rng = null;
            Excel.Range rngMthStart = null;

            try
            {
                _wsLabor.get_Range("A1:P1").Merge();
                _wsLabor.get_Range("A1").Formula = ("Labor Worksheet: " + JobGetTitle.GetTitle(JCCo, Job)).ToUpper(); ;
                _wsLabor.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                _wsLabor.get_Range("A1").Font.Bold = true;

                table = _wsLabor.ListObjects[1];
                rngHeaders = table.HeaderRowRange;
                rngTotals = table.TotalsRowRange;

                HelperUI.FormatHoursCost(_wsLabor);

                // USER EDITABLE CELLS
                LaborEmpDescEdit = table.ListColumns["Employee ID"].DataBodyRange;
                LaborEmpDescEdit.NumberFormat = "General";

                HelperUI.SetAlphanumericNotAllowedRule(LaborEmpDescEdit);

                LaborEmpDescEdit = _wsLabor.get_Range(LaborEmpDescEdit, table.ListColumns["Description"].DataBodyRange);
                LaborEmpDescEdit.Interior.Color = HelperUI.DataEntryColor;

                LaborRateEdit = table.ListColumns["Rate"].DataBodyRange;
                LaborRateEdit.EntireColumn.Style = HelperUI.CurrencyStyle;
                LaborRateEdit.Interior.Color = HelperUI.DataEntryColor;

                HelperUI.SetAlphanumericNotAllowedRule(LaborRateEdit);

                string phaseActualRate = "Phase Actual Rate";

                table.ListColumns[phaseActualRate].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns[phaseActualRate].Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                // MONTHS body
                laborMonthStart = table.ListColumns[phaseActualRate].Index + _offsetFromPhseActRate;
                string startDate = table.ListColumns[laborMonthStart].Name;
                rngStart = _wsLabor.Cells[rngHeaders.Row + 1, laborMonthStart];

                DateTime startPeriod = DateTime.Parse(startDate);

                // if the starting month is less than the projection month, gray it out and make read-only
                if ((MonthSearch.Year == startPeriod.Year && MonthSearch.Date.Month > startPeriod.Month) || MonthSearch.Year > startPeriod.Year)
                {
                    //++_offsetFromPhseActRate;
                    int timePastEndCol = 0;

                    if (LaborPivot == "MTH")
                    {
                        timePastEndCol = 1;
                        ++_offsetFromPhseActRate;
                    }
                    else // gray out all weeks of starting month
                    {
                        string wk = "";

                        // loop thru all dates
                        for (int i = laborMonthStart; i <= table.ListColumns.Count; i++)
                        {
                            wk = table.ListColumns[i].Name;
                            DateTime date = DateTime.Parse(wk);

                            if ((date.Year == startPeriod.Year && date.Date.Month > startPeriod.Month) || date.Year > startPeriod.Year) break;

                            ++_offsetFromPhseActRate;
                            ++timePastEndCol;  // <- last week of the month column index
                        }
                    }

                    if (timePastEndCol == 1)
                    {
                        rngEnd = _wsLabor.Cells[rngTotals.Row - 1, laborMonthStart];
                    }
                    else
                    {
                        rngEnd = _wsLabor.Cells[rngTotals.Row - 1, laborMonthStart + timePastEndCol - 1];
                    }

                    // gray out / make ready-only past mths/wks
                    rngStart = _wsLabor.get_Range(rngStart, rngEnd);
                    rngStart.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                    rngStart.NumberFormat = HelperUI.GeneralFormat;
                    rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                    // format bottom totals
                    rngStart = _wsLabor.Cells[rngTotals.Row, laborMonthStart];
                    rngEnd   = _wsLabor.Cells[rngTotals.Row, laborMonthStart + timePastEndCol - 1];

                    rngStart = _wsLabor.get_Range(rngStart, rngEnd);
                    rngStart.NumberFormat = HelperUI.GeneralFormat;
                    rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                    rngStart = _wsLabor.Cells[rngHeaders.Row + 1, laborMonthStart + timePastEndCol];
                }
                else
                {
                    rngStart = _wsLabor.Cells[rngHeaders.Row + 1, laborMonthStart];
                }

                int monthsLastCol = rngHeaders.Columns.Count;
                rngEnd = _wsLabor.Cells[rngTotals.Row - 1, monthsLastCol];

                LaborMonthsEdit = _wsLabor.get_Range(rngStart, rngEnd);
                LaborMonthsEdit.NumberFormat = "General;(#,##0.000);;@";
                //LaborMonthsEdit.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                LaborMonthsEdit.Interior.Color = HelperUI.DataEntryColor;

                // period months data valication rule
                HelperUI.SetAlphanumericNotAllowedRule(LaborMonthsEdit);

                rngEnd = _wsLabor.Cells[rngTotals.Row, monthsLastCol]; // includes totals

                _wsLabor.get_Range(rngStart, rngEnd).NumberFormat = HelperUI.GeneralFormat;
                _wsLabor.get_Range(rngStart, rngEnd).HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                LaborConditionalFormat(_wsLabor, table, 1, LaborMonthsEdit.Rows.Count, rngHeaders);

                //Labor Tab Formulas that refer to the Summary Tab

                #region FORMULAS
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

                column = table.ListColumns["Projected Remaining Hours"];
                cellStart = _wsLabor.Cells[rngHeaders.Row, laborMonthStart];
                cellEnd = _wsLabor.Cells[rngHeaders.Row, rngHeaders.Columns.Count];
                column.DataBodyRange.FormulaLocal = "=IF($R$1=\"W\", SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]]) * 40, SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]]))";

                table.ListColumns["Projected Remaining Total Cost"].DataBodyRange.FormulaLocal = "=[@[Projected Remaining Hours]]*[@Rate]";

                table.ListColumns["Projected Remaining Manweeks"].DataBodyRange.FormulaLocal = "=[@[Projected Remaining Hours]]/40";

                table.ListColumns["Previous Remaining Cost"].DataBodyRange.Value2 = table.ListColumns["Projected Remaining Total Cost"].DataBodyRange.Value2;


                table.ListColumns["Used"].DataBodyRange.FormulaLocal =
                    "=IF([@Projected Remaining Hours]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@Phase Actual Rate]<>0,\"Y\",IF([@Rate]<>0,\"Y\",IF([@[Budgeted Phase Hours Remaining]]<>0,\"Y\",IF([@Budgeted Phase Cost Remaining]<>0,\"Y\",IF([@MTD Actual Cost]<>0,\"Y\",IF([@MTD Actuals]<>0,\"Y\",\"N\"))))))))";

                #endregion

                //HelperUI.FormatHoursCost(_wsLabor);

                foreach (Excel.ListColumn col in table.ListColumns) col.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                string[] noSummation = new string[] { "Used", "Parent Phase Group", "Phase Code", "Phase Desc", "Employee ID", "Description",
                                                      "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", phaseActualRate, "Rate", "MTD Actual Cost", "MTD Actuals" };
                foreach (string col in noSummation)
                {
                    try
                    {
                        table.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    }
                    catch (Exception ex) { throw new Exception("SetupLaborTab: " + ex.Message); }
                }

                column = table.ListColumns["Variance"];
                column.DataBodyRange.FormulaLocal = "=[@[Projected Remaining Total Cost]]-[@[Previous Remaining Cost]]";
                column.Range.Style = "Currency";

                HelperUI.ApplyVarianceFormat(column);

                table.HeaderRowRange.EntireRow.WrapText = true;
                table.HeaderRowRange.EntireRow.RowHeight = 40.00;
                table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                #region COLUMN WIDTHS
                LaborRateEdit.EntireColumn.ColumnWidth = 12;
                table.ListColumns["Used"].DataBodyRange.ColumnWidth = 3.50;
                table.ListColumns["Parent Phase Group"].DataBodyRange.ColumnWidth = 23.50;
                table.ListColumns["Phase Code"].DataBodyRange.ColumnWidth = 11.50;
                table.ListColumns["Phase Desc"].DataBodyRange.ColumnWidth = 25.00;

                table.ListColumns["Employee ID"].DataBodyRange.ColumnWidth = 8.00;
                table.ListColumns["Description"].DataBodyRange.ColumnWidth = 20.00;
                table.ListColumns["Projected Remaining Hours"].DataBodyRange.ColumnWidth = 9.00;
                table.ListColumns["Projected Remaining Manweeks"].DataBodyRange.ColumnWidth = 10.75;
                table.ListColumns["Projected Remaining Total Cost"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.ColumnWidth = 10.50;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Previous Remaining Cost"].DataBodyRange.ColumnWidth = 15.75;
                table.ListColumns["Variance"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns[phaseActualRate].DataBodyRange.ColumnWidth = 7;
                table.ListColumns["Rate"].DataBodyRange.ColumnWidth = 7;
                table.ListColumns["MTD Actual Cost"].DataBodyRange.ColumnWidth = 14.75;
                table.ListColumns["MTD Actuals"].DataBodyRange.ColumnWidth = 7.86;
                #endregion

                #region FIELD DESCRIPTIONS
                HelperUI.AddFieldDesc(_wsLabor, "Parent Phase Group", "Parent phase code grouping (roll up code)");
                HelperUI.AddFieldDesc(_wsLabor, "Phase Code", "Phase Code");
                HelperUI.AddFieldDesc(_wsLabor, "Phase Desc", "PM Project phase description");
                HelperUI.AddFieldDesc(_wsLabor, "Projected Remaining Total Cost", "Remaining Hours x Rate");
                HelperUI.AddFieldDesc(_wsLabor, "Employee ID", "Employee ID");
                HelperUI.AddFieldDesc(_wsLabor, "Description", "Description to held PM identify and track costs");
                HelperUI.AddFieldDesc(_wsLabor, "Projected Remaining Hours", "Sum of periodic hour estimates");
                HelperUI.AddFieldDesc(_wsLabor, "Projected Remaining Manweeks", "Sum of periodic hour estimates divided by 40");
                HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Hours Remaining", "Current Estimated Hours less Actual Hours (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Cost Remaining", "Current Estimated Cost less Actual Cost (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Previous Remaining Cost", "Projected Remaining Cost as of McKinstry Projections tool opening");
                HelperUI.AddFieldDesc(_wsLabor, "Variance", "Projected Remaining Total Cost less Previous Remaining Cost");
                HelperUI.AddFieldDesc(_wsLabor, phaseActualRate, "Actual cost per hour (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "Rate", "User Input for remaining. Default to Actual, or if null budgeted rate for PHASE CODE");
                HelperUI.AddFieldDesc(_wsLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current batch month (at phase code level)");
                HelperUI.AddFieldDesc(_wsLabor, "MTD Actuals", "Actual hours or manweeks for the current batch month (at phase code level)");
                #endregion

                HelperUI.MergeLabel(_wsLabor, "Used", "Description", "Phase Detail", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Projected Remaining Manweeks", "Projected Remaining Total Cost", "Projected Remaining To Complete", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", "Budgeted Remaining", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "Previous Remaining Cost", "Variance", "Previous", 1, 2);
                HelperUI.MergeLabel(_wsLabor, phaseActualRate, "Rate", "Rate", 1, 2);
                HelperUI.MergeLabel(_wsLabor, "MTD Actual Cost", "MTD Actuals", "BATCH MTD Actual", 1, 2);

                int c = table.ListColumns["Rate"].DataBodyRange.Column + 3;

                HelperUI.MergeLabel(_wsLabor, _wsLabor.Cells[rngHeaders.Row, c].Value, _wsLabor.Cells[rngHeaders.Row, table.ListColumns.Count].Value, "PROJECTED HOURS", 1, 2, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                // 'projected man weeks to complete' description
                rngStart = _wsLabor.Cells[rngHeaders.Row - 1, laborMonthStart];
                rngEnd   = _wsLabor.Cells[rngHeaders.Row - 1, table.ListColumns.Count];
                rngStart = _wsLabor.get_Range(rngStart, rngEnd);
                rngStart.Merge();
                rngStart.Value = "Projected hours or manweeks remaining to complete on the project.\nReminder: Don't forget to add MTD Actual Hours/manweeks (Column Q) plus remaining in your current month projections";
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

                // LABOR TIME: Manweeks <-> Hours
                double R2Col_left = _wsLabor.get_Range("R2").Left;
                double R1Col_height = _wsLabor.get_Range("R1").Height - 6;

                _wsLabor.get_Range("R1").Value = hours_weeks; // hours_weeks comes from SumTab setup

                string btnCaption = LaborTime == LaborEnum.Hours ? "Switch to Manweek/FTE Labor Entry" : "Switch to Hours Labor Entry";

                if (LaborTime == LaborEnum.Hours)
                {
                    btnCaption = "Switch to Manweek/FTE Labor Entry";
                }
                else
                {
                    btnCaption = "Switch to Hours Labor Entry";
                }

                // ADD MANWEEKS BUTTON
                btnConvertLaborTime = OLEObj.CreateOLEButton(_wsLabor, "btnManweeks", btnCaption, R2Col_left, 4, 160, R1Col_height, ToggleManweekHours_Click);

                table.ListColumns["Projected Remaining Manweeks"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
                table.ListColumns["MTD Actuals"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;

                // MONTHS SECTION LABEL
                LaborTimeChangeMonthsLabel();

                _wsLabor.get_Range("A3", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                _wsLabor.get_Range("A3", Type.Missing).EntireRow.Hidden = true;

                HelperUI.GroupColumns(_wsLabor, "Parent Phase Group", null, true);
                HelperUI.GroupColumns(_wsLabor, "Budgeted Phase Hours Remaining", "Variance", true);
                HelperUI.GroupColumns(_wsLabor, "Employee ID", "Description", false);

                // HelperUI.SortAscending(_wsLabor, "Phase" "Cost Type");

                _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].AddComment("If the phase code has projected remaining hours, previous remaining hours or a phase actual rate it will be shown on default.  Adjust column filter to see all rows.");
                _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;
                _wsLabor.Cells[table.TotalsRowRange.Row, 1].Value = "Total";

                // set key fields to read-only
                _wsLabor.Cells.Locked = false;
                _wsLabor.get_Range("A1:A3").EntireRow.Locked = true;
                table.DataBodyRange.Locked = true;
                LaborEmpDescEdit.Locked = false;
                LaborRateEdit.Locked = false;
                LaborMonthsEdit.Locked = false;
                rngHeaders.Locked = true;
                rngTotals.Locked = false;
                HelperUI.ProtectSheet(_wsLabor);

                _wsLabor.UsedRange.Font.Name = HelperUI.FontCalibri;
                _wsLabor.Tab.Color = HelperUI.DataEntryColor;
                HelperUI.PrintPageSetup(_wsLabor);

                // UDPATE LaborMonthsEdit for manweek capture to include possible previous month (gray column)
                rngMthStart = _wsLabor.Cells[rngHeaders.Row + 1, table.ListColumns[phaseActualRate].Index + 4];
                rngEnd      = _wsLabor.Cells[rngTotals.Row - 1, monthsLastCol];
                LaborMonthsEdit = _wsLabor.get_Range(rngMthStart, rngEnd);
            }
            catch (Exception e) { throw new Exception("SetupLaborTab: " + e.Message, e); }
            finally
            {
                _offsetFromPhseActRate = 4;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
        }

        public void LaborConditionalFormat(Excel.Worksheet _wsLabor, Excel.ListObject table, int fromRowCnt, int toRowCnt, Excel.Range target)
        {
            string[] _varianceColA1 = table.ListColumns["Variance"].Range.Address.Split('$');
            string[] _rateColA1 = LaborRateEdit.Address.Split('$');
            string[] _remHrsColA1 = table.ListColumns["Projected Remaining Hours"].Range.Address.Split('$');
            string[] _remCostA1 = table.ListColumns["Projected Remaining Total Cost"].Range.Address.Split('$');
            string[] _empIDA1 = table.ListColumns["Employee ID"].Range.Address.Split('$');
            string[] _phaseA1 = table.ListColumns["Phase Code"].Range.Address.Split('$');

            int phseActualRateCol = table.ListColumns["Phase Actual Rate"].DataBodyRange.Column;
            int budgetedHoursCol = table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.Column;
            int budgetedCostCol = table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Column;
            int MTDActualCost = table.ListColumns["MTD Actual Cost"].DataBodyRange.Column;
            int MTDActualHrs = table.ListColumns["MTD Actuals"].DataBodyRange.Column;
            int empIDCol = table.ListColumns["Employee ID"].DataBodyRange.Column;

            string phseSameAsAbove = "";
            string phseSameAsBelow = "";
            string varianceNotZero = "";
            int rowNum;
            //int periodStart = MTDActualHrs + 1;
            int periodEnd = table.ListColumns.Count;

            for (int i = fromRowCnt; i <= toRowCnt; i++)
            {
                rowNum = target.Row + i;
                varianceNotZero = "$" + _varianceColA1[1] + "$" + rowNum + " <> 0";

                // alphanumeric bright red highlight
                for (int col = laborMonthStart; col <= periodEnd; col++)
                {
                    Excel.Range cell = _wsLabor.Cells[rowNum, col];
                    Excel.FormatCondition cell_bad = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                "=ISERROR(VALUE(IF(SUBSTITUTE(" + cell.AddressLocal + ",\" \",\"\")=\"\",0,VALUE(" + cell.AddressLocal + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    cell_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                }

                // highlight row when there's a variance |OR| variance = 0 rate = 0 but rem hours not zero
                Excel.Range rngRow = _wsLabor.Range[_wsLabor.Cells[rowNum, laborMonthStart], _wsLabor.Cells[rowNum, periodEnd]];
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
                                        Type.Missing, "=AND(" + varianceNotZero + ", $" + _remCostA1[1] + rowNum + " <> 0)", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
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

                phaseActualRateCond.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                phaseActualRateCond2.Interior.Color = HelperUI.LightGrayHeaderRowColor;

                Excel.Range budgetedHours = _wsLabor.Cells[rowNum, budgetedHoursCol];
                Excel.FormatCondition budgetedHoursCond = (Excel.FormatCondition)budgetedHours.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsAbove,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                Excel.FormatCondition budgetedHoursCond2 = (Excel.FormatCondition)budgetedHours.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsBelow,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                budgetedHoursCond.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                budgetedHoursCond2.Interior.Color = HelperUI.LightGrayHeaderRowColor;

                Excel.Range budgetedCost = _wsLabor.Cells[rowNum, budgetedCostCol];
                Excel.FormatCondition budgetedCostCond = (Excel.FormatCondition)budgetedCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsAbove,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                Excel.FormatCondition budgetedCostCond2 = (Excel.FormatCondition)budgetedCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsBelow,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                budgetedCostCond.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                budgetedCostCond2.Interior.Color = HelperUI.LightGrayHeaderRowColor;

                Excel.Range mtdActualCost = _wsLabor.Cells[rowNum, MTDActualCost];
                Excel.FormatCondition mtdActualCostCond = (Excel.FormatCondition)mtdActualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsAbove,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                Excel.FormatCondition mtdActualCostCond2 = (Excel.FormatCondition)mtdActualCost.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsBelow,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                mtdActualCostCond.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                mtdActualCostCond2.Interior.Color = HelperUI.LightGrayHeaderRowColor;

                Excel.Range mtdActualHrs = _wsLabor.Cells[rowNum, MTDActualHrs];
                Excel.FormatCondition mtdActualHrsCond = (Excel.FormatCondition)mtdActualHrs.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsAbove,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                Excel.FormatCondition mtdActualHrsCond2 = (Excel.FormatCondition)mtdActualHrs.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                    Type.Missing, phseSameAsBelow,
                                                    Type.Missing, Type.Missing, Type.Missing, Type.Missing);

                mtdActualHrsCond.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                mtdActualHrsCond2.Interior.Color = HelperUI.LightGrayHeaderRowColor;
            }
        }

        /// <summary>
        /// Callback function for btnToggleManweeksHours
        /// </summary>
        private void ToggleManweekHours_Click()
        {
            try
            {
                if (LaborTime == LaborEnum.Hours)
                {
                    ConvertLaborTime(LaborEnum.Manweeks);
                    btnConvertLaborTime.Caption = "Switch to Hours Labor Entry";
                }
                else if (LaborTime == LaborEnum.Manweeks)
                {
                    ConvertLaborTime(LaborEnum.Hours);
                    btnConvertLaborTime.Caption = "Switch to Manweek/FTE Labor Entry";
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
        }

        private void ConvertLaborTime(LaborEnum laborTime)
        {
            Excel.Worksheet wsLabor = (Excel.Worksheet)LaborRateEdit.Parent;
            Excel.ListObject table = wsLabor.ListObjects[1];
            Excel.Range MTDActuals = table.ListColumns["MTD Actuals"].DataBodyRange;

            try
            {
                dynamic labor = LaborMonthsEdit.Value2;
                dynamic mtdActuals = MTDActuals.Value2;
                bool laborIsArray = labor.GetType() == typeof(object[,]);
                bool mtdActualsIsArray = mtdActuals.GetType() == typeof(object[,]);

                if (laborTime == LaborEnum.Manweeks)
                {
                    // convert hours to manweeks
                    decimal hours = 0;

                    if (laborIsArray)
                    {
                        // multiple rows
                        for (int i = 1; i <= labor.GetUpperBound(0); i++) // rows
                        {
                            for (int n = 1; n <= labor.GetUpperBound(1); n++) // columns
                            {
                                hours = Convert.ToDecimal(labor[i, n]);
                                labor[i, n] = hours / 40;
                            }
                        }
                    }
                    else
                    {
                        hours = Convert.ToDecimal(labor);
                        labor = hours / 40;
                    }

                    if (mtdActualsIsArray)
                    {
                        for (int i = 1; i <= mtdActuals.GetUpperBound(0); i++)
                        {
                            for (int n = 1; n <= mtdActuals.GetUpperBound(1); n++)
                            {
                                hours = Convert.ToDecimal(mtdActuals[i, 1]);
                                mtdActuals[i, 1] = hours / 40;
                            }
                        }
                    }
                    else
                    {
                        hours = Convert.ToDecimal(mtdActuals);
                        mtdActuals = hours / 40;
                    }
                }
                else if (laborTime == LaborEnum.Hours)
                {
                    // convert manweeks to hours
                    decimal hours = 0;

                    if (laborIsArray)
                    {
                        // multiple rows
                        for (int i = 1; i <= labor.GetUpperBound(0); i++) // rows
                        {
                            for (int n = 1; n <= labor.GetUpperBound(1); n++) // columns
                            {
                                hours = Convert.ToDecimal(labor[i, n]);
                                labor[i, n] = hours * 40;
                            }
                        }
                    }
                    else
                    {
                        hours = Convert.ToDecimal(labor);
                        labor = hours * 40;
                    }

                    if (mtdActualsIsArray)
                    {
                        for (int i = 1; i <= mtdActuals.GetUpperBound(0); i++)
                        {
                            for (int n = 1; n <= mtdActuals.GetUpperBound(1); n++)
                            {
                                hours = Convert.ToDecimal(mtdActuals[i, 1]);
                                mtdActuals[i, 1] = hours * 40;
                            }
                        }
                    }
                    else
                    {
                        hours = Convert.ToDecimal(mtdActuals);
                        mtdActuals = hours * 40;
                    }
                }

                RenderOFF();

                if (wsLabor.FilterMode) // for ShowAllData() to convert all cells
                {
                    PreserveFilters(ref wsLabor);

                    wsLabor.ShowAllData();

                    UpdateHours(MTDActuals, labor, mtdActuals, laborIsArray, mtdActualsIsArray);

                    // re-apply filters
                    foreach (Filter filter in _filters)
                    {
                        table.Range.AutoFilter(filter.Column, filter.Criteria1, Excel.XlAutoFilterOperator.xlFilterValues, filter.Criteria2, true);
                    }
                }
                else
                {
                    UpdateHours(MTDActuals, labor, mtdActuals, laborIsArray, mtdActualsIsArray);
                }

                wsLabor.get_Range("R1").Value = laborTime == LaborEnum.Hours ? "H" : "W";

                if (!saving)
                {
                    LaborTime = laborTime; //update LaborTime default
                    LaborTimeChangeMonthsLabel();
                }

            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (wsLabor != null) Marshal.ReleaseComObject(wsLabor); wsLabor = null;
                if (table != null) Marshal.ReleaseComObject(table); table = null;
                if (!isRendering) RenderON();
                _filters?.Clear();
            }
        }

        private static void PreserveFilters(ref Excel.Worksheet ws)
        {
            _filters = new List<Filter>();
            if (ws.ListObjects[1].AutoFilter == null) return;
            int column = 1;

            // preserve filters
            foreach (Excel.Filter f in ws.ListObjects[1].AutoFilter.Filters)
            {
                if (!f.On)
                {
                    ++column;
                    continue;
                }
                Filter filter = new Filter();

                try
                {
                    filter.Criteria1 = f.Criteria1;
                }
                catch (COMException)
                {
                    filter.Criteria1 = Type.Missing;
                }

                try
                {
                    filter.Criteria2 = f.Criteria2;
                }
                catch (COMException)
                {
                    filter.Criteria2 = Type.Missing;
                }

                filter.Column = column;

                _filters.Add(filter);
                ++column;
            }
        }

        private void UpdateHours(Excel.Range MTDActuals, dynamic labor, dynamic mtdActuals, bool laborIsArray, bool mtdActualsIsArray)
        {
            // update values
            if (laborIsArray)
            {
                LaborMonthsEdit.Value2 = labor;
            }
            else
            {
                LaborMonthsEdit.Value = labor;
            }

            if (mtdActualsIsArray)
            {
                MTDActuals.Value2 = mtdActuals;
            }
            else
            {
                MTDActuals.Value = mtdActuals;
            }
        }

        private void LaborTimeChangeMonthsLabel()
        {
            Excel.Worksheet _wsLabor = null;
            Excel.ListObject table = null;
            Excel.Range rngHeaders = null;
            Excel.Range rng = null;

            try
            {
                // MONTHS SECTION LABEL
                _wsLabor = LaborMonthsEdit.Parent;
                table = _wsLabor.ListObjects[1];
                rngHeaders = table.HeaderRowRange;

                rng = _wsLabor.Cells[rngHeaders.Row - 2, laborMonthStart];
                string main = LaborTime == LaborEnum.Hours ? "PROJECTED HOURS TO COMPLETE" : "PROJECTED MANWEEKS TO COMPLETE";
                string sub = "(INCLUDED ACTUAL HOURS/MANWEEKS IN CURRENT FINANCIAL MONTH PROJECTION)";
                rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
                rng.Characters[Start: main.Length + 1,
                              Length: sub.Length + 2].Font.Size = 8;

                int parentheses       = rng.Text.IndexOf("(");
                string first_line     = ((string)rng.Text).Substring(0, parentheses - 1);
                int manweeks_position = first_line.IndexOf("MANWEEKS");

                if (manweeks_position > 0 && LaborTime == LaborEnum.Manweeks)
                {
                    rng.Characters[Start: manweeks_position + 1,
                                  Length: "MANWEEKS".Length + 1].Font.Color = Excel.XlRgbColor.rgbRed;
                }
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (rngHeaders != null) Marshal.ReleaseComObject(rngHeaders); rngHeaders = null;
                if (table != null) Marshal.ReleaseComObject(table); table = null;
                if (_wsLabor != null) Marshal.ReleaseComObject(_wsLabor); _wsLabor = null;
            }

        }

        #endregion

        #region  NONLABOR SETUP

        private void SetupNonLaborTab2(Excel.Worksheet _wsNonLabor, out Excel.Range rngHeaders, out Excel.Range rngTotals, out Excel.Range rngStart,
            out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd, out string remainingCost)
        {
            _wsNonLabor.Cells.Locked = false;
            Excel.Range rng = null;
            try
            {
                _wsNonLabor.get_Range("A1:P1").Merge();
                _wsNonLabor.get_Range("A1").Formula = ("Non Labor Worksheet: " + JobGetTitle.GetTitle(JCCo, Job)).ToUpper(); ;
                _wsNonLabor.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                _wsNonLabor.get_Range("A1").Font.Bold = true;

                table = _wsNonLabor.ListObjects[1];
                rngHeaders = table.HeaderRowRange;
                rngTotals = table.TotalsRowRange;

                // USER EDITABLE AREA
                NonLaborWritable1 = table.ListColumns["Description"].DataBodyRange;
                NonLaborWritable1.Interior.Color = HelperUI.DataEntryColor;

                remainingCost = "Remaining Cost";
                column = table.ListColumns[remainingCost];
                //HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns[keyBeforeDataEntry].Index+1].Value);
                column.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                column.Range.Style = HelperUI.CurrencyStyle;

                // periods (titles - readonly)
                int periodEnd = rngHeaders.Columns.Count;
                cellEnd = _wsNonLabor.Cells[rngHeaders.Row, periodEnd];
                cellStart = _wsNonLabor.Cells[rngHeaders.Row, column.Index + _offsetFromRemCost];
                column.DataBodyRange.FormulaLocal = "=SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]])";

                // periods USER EDITABLE AREA
                nonLaborMonthStart = column.Index + _offsetFromRemCost;
                string startDate = table.ListColumns[nonLaborMonthStart].Name;
                rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, nonLaborMonthStart];

                DateTime startPeriod = DateTime.Parse(startDate);

                if ((MonthSearch.Year == startPeriod.Year && MonthSearch.Date.Month > startPeriod.Month) || MonthSearch.Year > startPeriod.Year)
                {
                    ++_offsetFromRemCost;
                    rngStart = _wsNonLabor.Range[rngStart, _wsNonLabor.Cells[rngTotals.Row - 1, nonLaborMonthStart]];
                    rngStart.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                    rngStart.Style = HelperUI.CurrencyStyle;
                    rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                    rngStart = _wsNonLabor.Cells[rngTotals.Row, nonLaborMonthStart];
                    rngStart.Style = HelperUI.CurrencyStyle;
                    rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                    rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, nonLaborMonthStart + 1];
                }
                else
                {
                    rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, nonLaborMonthStart];
                }

                rngEnd = _wsNonLabor.Cells[rngTotals.Row - 1, periodEnd];

                NonLaborWritable2 = _wsNonLabor.get_Range(rngStart, rngEnd);
                NonLaborWritable2.Style = HelperUI.CurrencyStyle;
                NonLaborWritable2.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                NonLaborWritable2.Interior.Color = HelperUI.DataEntryColor;
                NonLaborWritable2.EntireColumn.ColumnWidth = 14.57;

                HelperUI.SetAlphanumericNotAllowedRule(NonLaborWritable2);

                rngEnd = _wsNonLabor.Cells[rngTotals.Row, periodEnd];

                _wsNonLabor.get_Range(rngStart, rngEnd).Style = HelperUI.CurrencyStyle;
                _wsNonLabor.get_Range(rngStart, rngEnd).HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                NonLaborConditionalFormat(_wsNonLabor, table, 1, NonLaborWritable2.Rows.Count, rngHeaders);

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

                table.ListColumns["Used"].DataBodyRange.FormulaLocal = "=IF([@[Remaining Cost]]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@[Budgeted Phase Cost Remaining]]<>0,\"Y\",IF([@[Phase Open Committed]]<>0,\"Y\",IF([@[MTD Actual Cost]]<>0,\"Y\",\"N\")))))";

                //Formulas that Point to the Summary Tab
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.FormulaLocal =
                    "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
                    contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]])) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[JTD Actual Cost],tbl" +
                    contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]]))";

                table.ListColumns["Phase Open Committed"].DataBodyRange.Style = HelperUI.CurrencyStyle;
                table.ListColumns["Phase Open Committed"].DataBodyRange.FormulaLocal = "=SUMIFS(tbl" + contJobJectBatchSum_table.TableName +
                                                                                       "[Remaining Committed Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
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
                HelperUI.AddFieldDesc(_wsNonLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current batch month (at phase code level)");
                HelperUI.AddFieldDesc(_wsNonLabor, "Phase Open Committed", "Open committed cost aka Remaining Committed cost (at phase code level)");

                HelperUI.MergeLabel(_wsNonLabor, _wsNonLabor.Cells[rngHeaders.Row, nonLaborMonthStart].Value, _wsNonLabor.Cells[rngHeaders.Row, periodEnd].Value, "PROJECTED COST", horizAlign: Excel.XlHAlign.xlHAlignLeft);

                rngStart = _wsNonLabor.Cells[rngHeaders.Row - 1, nonLaborMonthStart];
                rngEnd = _wsNonLabor.Cells[rngHeaders.Row - 1, periodEnd];
                rngStart = _wsNonLabor.get_Range(rngStart, rngEnd);
                rngStart.Merge();
                rngStart.Value = "Projected cost remaining on the project by month\nReminder: Current month should be MTD Actual Costs plus remaining projected costs for the month)";
                rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                rngStart.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;

                rng = _wsNonLabor.Cells[rngHeaders.Row - 2, table.ListColumns["MTD Actual Cost"].Index + 1];
                string main = "PROJECTED COST";
                string sub = "(INCLUDE MTD ACTUAL COST IN CURRENT MONTH)";
                rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
                rng.Characters[Start: main.Length + 1, Length: sub.Length + 2].Font.Size = 8;

                HelperUI.MergeLabel(_wsNonLabor, "Used", "Description", "Phase Detail");
                HelperUI.MergeLabel(_wsNonLabor, "Budgeted Phase Cost Remaining", remainingCost, "Information");
                HelperUI.MergeLabel(_wsNonLabor, "MTD Actual Cost", "MTD Actual Cost", "BATCH MTD ACTUAL");

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
                _wsNonLabor.Cells.get_Range("A1:A3").EntireRow.Locked = true;
                table.DataBodyRange.Locked = true;
                table.TotalsRowRange.Locked = false;
                table.ListColumns["Description"].DataBodyRange.Locked = false;
                NonLaborWritable1.Locked = false;
                NonLaborWritable2.Locked = false;
                rngHeaders.Locked = true;
                _wsNonLabor.Tab.Color = HelperUI.DataEntryColor;
                HelperUI.ProtectSheet(_wsNonLabor);
            }
            catch (Exception e) { throw new Exception("SetupNonLaborTab: " + e.Message); }
            finally
            {
                _offsetFromRemCost = 2;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
        }

        public void NonLaborConditionalFormat(Excel.Worksheet _wsNonLabor, Excel.ListObject table, int fromRowCnt, int toRowCnt, Excel.Range target)
        {
            string[] _varianceCol = table.ListColumns["Variance"].Range.Address.Split('$');
            string[] _phase = table.ListColumns["Phase Code"].Range.Address.Split('$');
            string[] _costtype = table.ListColumns["Cost Type"].Range.Address.Split('$');
            int budgetedRemainingCostCol = table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Column;
            int phaseOpenCommittedCol = table.ListColumns["Phase Open Committed"].DataBodyRange.Column;
            int MTDActualCost = table.ListColumns["MTD Actual Cost"].DataBodyRange.Column;
            int periodEnd = table.ListColumns.Count;
            int cellAbove;
            int cellBelow;
            int rowNum;
            for (int i = fromRowCnt; i <= toRowCnt; i++)
            {
                rowNum = target.Row + i;

                // alphanumeric bright red highlight
                for (int col = nonLaborMonthStart; col <= periodEnd; col++)
                {
                    Excel.Range cell = _wsNonLabor.Cells[rowNum, col];
                    Excel.FormatCondition cell_bad = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(IF(SUBSTITUTE(" + cell.AddressLocal + ",\" \",\"\")=\"\",0,VALUE(" + cell.AddressLocal + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    cell_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
                }

                Excel.Range periodStart_to_End = _wsNonLabor.Range[_wsNonLabor.Cells[rowNum, nonLaborMonthStart], _wsNonLabor.Cells[rowNum, periodEnd]];
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
        }
        #endregion

        #region  REV SETUP

        private void SetupRevTab(Excel.Worksheet _ws, string sheetname)
        {
            Excel.Range marginTotal = null;
            Excel.Range batchDateCreated = null;
            Excel.Range projectedContractHeader = null;
            Excel.Range projectedContract = null;
            Excel.Range rngNotes = null;

            try
            {
                _ws = HelperUI.GetSheet(sheetname, false);
                _table = _ws.ListObjects[1];
                _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                _ws.Cells.Range["A1"].Formula = JobGetTitle.GetTitle(JCCo, _Contract) + " Revenue Worksheet";
                _ws.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
                _ws.Cells.Range["A1"].Font.Bold = true;
                _ws.Cells.Range["A1:N1"].Merge();
                _ws.Cells.Range["C2:D2"].Merge();

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
                _ws.Cells[aboveHeaders, projectedContract.Column].FormulaLocal = "=SUM(" + projectedContract.Address + ")";

                _ws.UsedRange.Font.Name = HelperUI.FontCalibri;

                RevWritable2 = _table.ListColumns["Margin Seek"].DataBodyRange;
                RevWritable2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.SoftBeige);

                HelperUI.SetAlphanumericNotAllowedRule(RevWritable2);

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

                    Excel.FormatCondition unbookedCond = (Excel.FormatCondition)_ws.Cells[r, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                                                            Type.Missing, "=$" + projecteContractCol[1] + "$" + r + " <> $" + prevprojContractCol[1] + "$" + r, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    unbookedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);

                    // Alphanumerics bad entries red
                    Excel.FormatCondition unbookedBad = (Excel.FormatCondition)_ws.Cells[r, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                              "=ISERROR(VALUE(SUBSTITUTE($" + _unbookedCol[1] + "$" + r + ",\" \",\"\")))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    unbookedBad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

                    Excel.FormatCondition marginSeekBad = (Excel.FormatCondition)_ws.Cells[r, RevWritable2.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
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

                rngNotes = _table.ListColumns["Notes"].DataBodyRange;
                rngNotes.Interior.Color = HelperUI.DataEntryColor;
                rngNotes.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                rngNotes.VerticalAlignment = Excel.XlVAlign.xlVAlignTop;
                rngNotes.ColumnWidth = 60.00;

                _table.DataBodyRange.EntireRow.RowHeight = 15;

                _table.ListColumns["PRG"].DataBodyRange.ColumnWidth = 9.00;
                _table.ListColumns["PRG Description"].DataBodyRange.ColumnWidth = 20.00;
                _table.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 8.5;
                _table.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 25.00;
                _table.ListColumns["Contract Item"].DataBodyRange.ColumnWidth = 10.00;
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
                HelperUI.MergeLabel(_ws, "Notes", "Notes", " ");

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
                HelperUI.AddFieldDesc(_ws, "Notes", "Contract Item Projection Notes");

                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].AddComment("Scratch pad to calculate margin adjustments. NOTE: This will not update your Cost Projections or Saved once the Revenue batch is posted");
                _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].Comment.Shape.TextFrame.AutoSize = true;

                _ws.get_Range("A4", Type.Missing).EntireRow.Group();
                _ws.get_Range("A4", Type.Missing).EntireRow.Hidden = true;

                _table.ListColumns["Previous Projected Contract"].DataBodyRange.EntireColumn.AutoFit();

                HelperUI.GroupColumns(_ws, "Margin Seek", "Margin Seek", true);

                HelperUI.PrintPageSetup(_ws);

                _table.ShowTotals = true;

                _table.ListColumns["Notes"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

                _ws.UsedRange.Locked = true;
                _table.TotalsRowRange.Locked = false;
                _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.Locked = false;
                _table.ListColumns["Margin Seek"].DataBodyRange.Locked = false;
                rngNotes.Locked = false;
                HelperUI.ProtectSheet(_ws, false, false);
                _ws.Tab.Color = HelperUI.DataEntryColor;

                _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;


            }
            catch (Exception ex) { throw new Exception("SetupRevTab: " + ex.Message); }
            finally
            {
                if (_table != null) Marshal.ReleaseComObject(_table);
                if (marginTotal != null) Marshal.ReleaseComObject(marginTotal);
                if (projectedContractHeader != null) Marshal.ReleaseComObject(projectedContractHeader);
                if (projectedContract != null) Marshal.ReleaseComObject(projectedContract);
                if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
                if (rngNotes != null) Marshal.ReleaseComObject(rngNotes);
            }
        }


        #endregion

        #endregion


        #region SAVE TO VIEWPOINT     

        private bool InsertCostProjectionsIntoJCPD2()
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
            DataTable dtJCPBETC = null;
            Dictionary<string, Type> etcColumns = null;
            string[] projSheetNames = { nonLaborSheet, laborSheet };
            StringBuilder sb = new StringBuilder();
            int nonlaborCount = 0;
            int laborCount = 0;
            byte costtype = 0x1;
            uint detSeq = 0;  // increments by 1 for each row

            List<int> manualETC_RowsWithValues = null;
            int visibleRows = 0;

            try
            {
                // Define SQL Table Schema
                dtJCPBETC = new DataTable("mckJCPBETC");
                etcColumns = new Dictionary<string, Type>
                                                    { {"JCCo",typeof(byte)}, {"Mth",typeof(DateTime)}, {"BatchId",typeof(uint)}, {"Job",typeof(string)}, {"DateTime",typeof(DateTime)}, {"Phase",typeof(string)},
                                                    {"CostType",typeof(byte)}, {"Hours",typeof(object)}, {"Rate",typeof(object)}, {"Amount",typeof(object)}};
                // Create the table
                foreach (KeyValuePair<string, Type> c in etcColumns)
                {
                    Column = new DataColumn(c.Key)
                    {
                        DataType = c.Value
                    };
                    dtJCPBETC.Columns.Add(Column);
                }

                _ws = HelperUI.GetSheet(costSumSheet, false);
                if (_ws == null) throw new Exception("No Cost Projections Summary tab found");

                ValidateLaborHoursMissingRate();

                ETCOverrideCount_AND_JTDActCostIsGreaterThanProjectedCost_Check(out visibleRows, out manualETC_RowsWithValues, dtJCPBETC);


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
                    Column = new DataColumn(c.Key)
                    {
                        DataType = c.Value
                    };
                    dtUnpivotedProj.Columns.Add(Column);
                }


                foreach (string sheetName in projSheetNames)
                {
                    _ws = HelperUI.GetSheet(sheetName + HelperUI.JobTrimDash(Job), true);
                    if (_ws == null) continue; //throw new Exception("Could not find sheet containing '" + sheetName + "'");


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

                            if (allRows[row, 1]?.ToString() == "Y")
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
                                object[] tblBatchSeqPhaseGroup = HelperData.GetBatchSeqPhaseGroup(JCCo, MonthSearch, Job, CostBatchId, phase, costtype);

                                batchSeq = Convert.ToUInt32(tblBatchSeqPhaseGroup[0]);
                                phseGroup = Convert.ToByte(tblBatchSeqPhaseGroup[1]);
                                Row["Co"] = JCCo;
                                Row["DetSeq"] = ++detSeq;
                                Row["Mth"] = MonthSearch; // DateTime.FromOADate((double)Month).ToShortDateString(); // Excel converts DateTime to Decimmal, we must revert to DB type

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


                if (dtUnpivotedProj?.Rows.Count > 0)
                {
                    totalRows = nonlaborCount + laborCount;

                    try
                    {
                        insertedRows = InsertCostBatchNonLaborJCPD.InsCostJCPD(JCCo, MonthSearch, CostBatchId, dtUnpivotedProj);
                        successInsert = insertedRows == totalRows;
                    }
                    catch (Exception ex)
                    {
                        sb.Append(ex.Message);
                    }
                }
                //Fix to allow removing of all detail rows after they are cleared from the worksheet
                else
                {
                    // batch already in JCPD; delete and re-insert batch with new values
                    DeleteBatchJCPD.DeleteBatchFromJCPD(JCCo, MonthSearch, costBatchId, out detSeq, out int olddeleted);
                }

                if (insertedRows != totalRows)
                {
                    throw new Exception("Cost Projection was NOT posted, please review the batch validation report in Viewpoint.\n\n" +
                                        "The most common issue is an invalid Employee ID.\n\n" +
                                        "If the problem persists, please contact support.");
                }

                if (manualETC_RowsWithValues != null && dtJCPBETC != null)
                {
                    UpdateJCPBwithSumData(manualETC_RowsWithValues.Count, visibleRows, dtJCPBETC, insertedRows);
                }

                if (btnFetchData.Text == "Saved")
                {
                    sb.Append("Cost Projection Successfully Saved.");

                    string job = HelperUI.JobTrimDash(Job);
                    _control_ws.Names.Item("LastSave_" + job).RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _control_ws.Names.Item("SaveUser_" + job).RefersToRange.Value = Login;
                }
                MessageBox.Show(sb.ToString());
                dtUnpivotedProj?.Clear();
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
                    LogProphecyAction.InsProphecyLog(Login, 17, JCCo, _Contract, Job, MonthSearch, CostBatchId, getEvilFunctionProd(ex), "OVR: " + manualETC_RowsWithValues.Count + " of " + visibleRows);
                }
                else
                {
                    LogProphecyAction.InsProphecyLog(Login, 17, JCCo, _Contract, Job, MonthSearch, CostBatchId, getEvilFunctionProd(ex));
                }
                ex.Data.Add(0, 17);
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

        private void UpdateJCIRwithSumData()
        {
            DataTable table = new DataTable();
            Excel.ListObject xltable = null;
            int updatedTotal = 0;
            try
            {
                _ws = HelperUI.GetSheet(revSheet, false);
                if (_ws == null)
                {
                    MessageBox.Show("No Revenue Projections Summary tab found");
                    return;
                }

                string contractItem = "Contract Item";
                string jectCV = "Projected Contract";
                string itemnotes = "Notes";

                xltable = _ws.ListObjects[1];
                int row = (from r in contJectRevenue_table.AsEnumerable()
                           where r.Field<decimal>("Posted Projected Cost") != r.Field<decimal>("Margin Seek")
                           select contJectRevenue_table.Rows.IndexOf(r)).FirstOrDefault();

                if (row != 0)
                {
                    MessageBox.Show("You've entered Projected Cost in the revenue worksheet that does not match the Posted Cost.\n"
                                    + "Open and post cost batch(es) to ensure projected margin is maintained.", "Projected Cost Variance", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    _ws.Cells[row, xltable.ListColumns["Posted Projected Cost"].Index].Activate();
                }
                //HelperUI.Alphanumeric_Check(xltable, "Unbooked Contract Adjustment");

                //int postedProjectedCost = xltable.ListColumns["Posted Projected Cost"].Index;
                //int marginSeek = xltable.ListColumns["Margin Seek"].Index;
                //int r = xltable.HeaderRowRange.Row + 1;
                //int end = xltable.TotalsRowRange.Row - 1;

                //for (int i = r; i <= end; i++)
                //{
                //    if (_ws.Cells[i, postedProjectedCost].Value != _ws.Cells[i, marginSeek].Value)
                //    {
                //        MessageBox.Show("You've entered Projected Cost in the revenue worksheet that does not match the Posted Cost.\n" +
                //                        "Open and post cost batch(es) to ensure projected margin is maintained.", "Projected Cost Variance", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                //        _ws.Cells[i, postedProjectedCost].Activate();
                //        break;
                //    }
                //}

                if (xltable.ListRows.Count > 1)
                {
                    object[,] items = xltable.ListColumns[contractItem].DataBodyRange.Value2;
                    object[,] jectCVamt = xltable.ListColumns[jectCV].DataBodyRange.Value2;
                    object[,] itemnotesVal = xltable.ListColumns[itemnotes].DataBodyRange.Value2;

                    table.Columns.Add(contractItem, typeof(string));
                    table.Columns.Add(jectCV, typeof(decimal));
                    table.Columns.Add(itemnotes, typeof(string));

                    int rowCount = items.GetUpperBound(0);
                    for (int i = 1; i <= rowCount; i++)
                    {
                        var _row = table.NewRow();
                        _row[contractItem] = items[i, 1];
                        _row[jectCV] = jectCVamt[i, 1];
                        _row[itemnotes] = itemnotesVal[i, 1];
                        table.Rows.Add(_row);
                    }
                }
                else if (xltable.ListRows.Count == 1)
                {
                    table.Columns.Add(contractItem, typeof(string));
                    table.Columns.Add(jectCV, typeof(decimal));
                    table.Columns.Add(itemnotes, typeof(string));

                    var __row = table.NewRow();
                    __row[contractItem] = xltable.ListColumns[contractItem].DataBodyRange.Value2;
                    __row[jectCV] = xltable.ListColumns[jectCV].DataBodyRange.Value2;
                    __row[itemnotes] = xltable.ListColumns[itemnotes].DataBodyRange.Value2;
                    table.Rows.Add(__row);
                }
                else
                {
                    MessageBox.Show("There are no records in the Revenue Projections Summary sheet");
                    return;
                }

                updatedTotal = Data.Viewpoint.JCUpdate.JCUpdateJCIR.SumUpdateJCIR(JCCo, MonthSearch, _Contract, RevBatchId, table, Login);

                if (updatedTotal == xltable.ListRows.Count)
                {
                    _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _control_ws.Names.Item("ContractSaveUser").RefersToRange.Value = Login;
                    Globals.ThisWorkbook.isRevDirty = false;
                    btnPostRev.Visible = true;
                    btnPostRev.Enabled = true;
                    btnFetchData.Text = "Saved";
                    MessageBox.Show("Revenue Projection Successfully Saved");
                    btnFetchData.Text = "Save Projections to Viewpoint";
                    btnFetchData.Enabled = true;
                }
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, 16);
                throw ex;
            }
            finally
            {
                if (xltable == null) Marshal.ReleaseComObject(xltable);
                if (_ws == null) Marshal.ReleaseComObject(_ws);
            }
        }

        // HOST-ITEM (worksheet added at design-time) verions of REVENUE WORKSHEET
        //private void UpdateJCIRwithSumData2()
        //{
        //    Excel.ListObject xltable = null;
        //    int updatedTotal = 0;
        //    try
        //    {
        //        if (contJectRevenue_table?.Rows.Count == 0)
        //        {
        //            throw new Exception("There are no records in the Revenue Projections Summary sheet");
        //        }

        //        xltable = Globals.Rev.ListObjects[1];

        //        int row = (from   r in contJectRevenue_table.AsEnumerable()
        //                   where  r.Field<decimal>("Posted Projected Cost") != r.Field<decimal>("Margin Seek")
        //                   select contJectRevenue_table.Rows.IndexOf(r)).FirstOrDefault();

        //        if (row != 0)
        //        {
        //            MessageBox.Show("You've entered Projected Cost in the revenue worksheet that does not match the Posted Cost.\n"
        //                            + "Open and post cost batch(es) to ensure projected margin is maintained.", "Projected Cost Variance", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        //            Globals.Rev.Cells[row, xltable.ListColumns["Posted Projected Cost"].Index].Activate();
        //        }

        //        updatedTotal = Data.Viewpoint.JCUpdate.JCUpdateJCIR.SumUpdateJCIR(JCCo, Month, _Contract, RevBatchId, contJectRevenue_table, Login);

        //        if (updatedTotal == xltable.ListRows.Count)
        //        {
        //            _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
        //            _control_ws.Names.Item("ContractSaveUser").RefersToRange.Value = Login;
        //            Globals.ThisWorkbook.isRevDirty = false;
        //            btnPostRev.Visible = true;
        //            btnPostRev.Enabled = true;
        //            btnFetchData.Text = "Saved";
        //            MessageBox.Show("Revenue Projection Successfully Saved");
        //            btnFetchData.Text = "Save Projections to Viewpoint";
        //            btnFetchData.Enabled = true;
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        ex.Data.Add(0, 16);
        //        throw ex;
        //    }
        //    finally
        //    {
        //        if (xltable != null) Marshal.ReleaseComObject(xltable);
        //        if (_ws != null) Marshal.ReleaseComObject(_ws);
        //    }
        //}

        private void ETCOverrideCount_AND_JTDActCostIsGreaterThanProjectedCost_Check(out int visibleRows, out List<int> manualETC_RowsWithValues, DataTable dtJCPBETC)
        {
            Excel.Range rng = null;
            Excel.Range badCell = null;
            try
            {
                // column positions relative to excel
                int JTDActualCost = _ws.ListObjects[1].ListColumns["JTD Actual Cost"].Index;
                int projectedCost = _ws.ListObjects[1].ListColumns["Projected Cost"].Index;
                int manualETCHours = _ws.ListObjects[1].ListColumns["Manual ETC Hours"].DataBodyRange.Column;
                int manualETC_CST_HR = _ws.ListObjects[1].ListColumns["Manual ETC CST/HR"].DataBodyRange.Column;
                int manualETCCost = _ws.ListObjects[1].ListColumns["Manual ETC Cost"].DataBodyRange.Column;
                int used = _ws.ListObjects[1].ListColumns["Used"].DataBodyRange.Column;
                int phase = _ws.ListObjects[1].ListColumns["Phase Code"].DataBodyRange.Column;
                int costype = _ws.ListObjects[1].ListColumns["Cost Type"].DataBodyRange.Column;
                byte costtype = 0x0;

                decimal value = 0;
                bool blowup = false;
                //bool missingHours = false;
                bool missingRate = false;
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

                        if (!_ws.Cells[i, manualETCCost].Locked && _ws.Cells[i, manualETCCost].Value2 != null
                            & (string)_ws.Cells[i, costype].Value != "L")
                        {
                            if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETCCost].Value), out value))
                            {
                                badCell = _ws.Cells[i, manualETCCost];
                                blowup = true;
                            }
                            else //if (value != 0)
                            {
                                DataRow row = dtJCPBETC.NewRow();
                                row["JCCo"] = JCCo;
                                row["Mth"] = MonthSearch;
                                row["BatchId"] = costBatchId;
                                row["Job"] = Job;
                                row["DateTime"] = DateTime.Now;
                                row["Phase"] = _ws.Cells[i, phase].Value;

                                switch ((string)_ws.Cells[i, costype].Value)
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

                                row["CostType"] = costtype;
                                row["Hours"] = (object)DBNull.Value;  //_ws.Cells[i, manualETCHours].Value == 0 ? (object)DBNull.Value : _ws.Cells[i, manualETCHours].Value;
                                row["Rate"] = (object)DBNull.Value; //_ws.Cells[i, manualETC_CST_HR].Value == 0 ? (object)DBNull.Value : _ws.Cells[i, manualETC_CST_HR].Value;
                                row["Amount"] = _ws.Cells[i, manualETCCost].Value;

                                dtJCPBETC.Rows.Add(row);
                                if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                            }
                        }
                        else if (!_ws.Cells[i, manualETCHours].Locked && _ws.Cells[i, manualETCHours].Value2 != null
                            & (string)_ws.Cells[i, costype].Value == "L")
                        {
                            if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETCHours].Value), out value))
                            {
                                badCell = _ws.Cells[i, manualETCHours];
                                blowup = true;
                            }
                            else //if (value != 0)
                            {
                                //if ((value == 0 || _ws.Cells[i, manualETCHours].Formula == "") && _ws.Cells[i, manualETC_CST_HR].Value > 0)
                                //{
                                //    badCell = _ws.Cells[i, manualETCHours];
                                //    missingHours = true;
                                //}
                                //else 
                                if (value > 0 && (_ws.Cells[i, manualETC_CST_HR].Value == 0 || _ws.Cells[i, manualETC_CST_HR].Formula == ""))
                                {
                                    badCell = _ws.Cells[i, manualETC_CST_HR];
                                    missingRate = true;
                                }
                                else
                                {
                                    DataRow row = dtJCPBETC.NewRow();
                                    row["JCCo"] = JCCo;
                                    row["Mth"] = MonthSearch;
                                    row["BatchId"] = costBatchId;
                                    row["Job"] = Job;
                                    row["DateTime"] = DateTime.Now;
                                    row["Phase"] = _ws.Cells[i, phase].Value;
                                    switch ((string)_ws.Cells[i, costype].Value)
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

                                    row["CostType"] = costtype;
                                    row["Hours"] = _ws.Cells[i, manualETCHours].Value;
                                    row["Rate"] = _ws.Cells[i, manualETC_CST_HR].Value;
                                    row["Amount"] = _ws.Cells[i, manualETCCost].Value;

                                    dtJCPBETC.Rows.Add(row);
                                    if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                                }
                            }
                        }

                        //Rate Should not count as an override
                        //if (!_ws.Cells[i, manualETC_CST_HR].Locked && _ws.Cells[i, manualETC_CST_HR].Value2 != null)
                        //{
                        //    if (!decimal.TryParse(Convert.ToString(_ws.Cells[i, manualETC_CST_HR].Value), out value))
                        //    {
                        //        badCell = _ws.Cells[i, manualETC_CST_HR];
                        //        blowup = true;
                        //    }
                        //    else if (value != 0)
                        //    {
                        //        if (!manualETC_RowsWithValues.Contains(i)) manualETC_RowsWithValues.Add(i);
                        //    }
                        //}
                        if (blowup || missingRate)
                        {
                            workbook.Activate();
                            badCell.Activate();
                            btnFetchData.Text = "Save Projections to Viewpoint";
                            btnFetchData.Enabled = true;
                            isInserting = false;
                        }

                        if (missingRate)
                        {
                            throw new Exception("You’ve entered hours without an hourly rate in Manual ETC entry.\n\nPlease review your entries.");
                        }

                        //if (missingHours)
                        //{
                        //    throw new Exception("You've entered Rate with missing Hours");
                        //}

                        if (blowup)
                        {
                            //_ws.Range[_ws.Cells[i, manualETCHours], _ws.Cells[i, manualETCCost]].EntireColumn.Hidden = false;  // BREAK UNDO - LeoG 9/8
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

        private void UpdateJCPBwithSumData(int manualETC_rowsWithValues, int manualETC_visibleRows, DataTable dtJCPBETC, int insertedRows)
        {
            DataTable table = new DataTable();
            Excel.ListObject xltable = null;
            int updatedTotal = 0;
            int rowCount = 0;


            try
            {
                _ws = HelperUI.GetSheet(costSumSheet, false);
                if (_ws == null) throw new Exception("No Cost Projections Summary tab found");

                string phaseCode = "Phase Code";
                string costType = "Cost Type";
                string jectHours = "Projected Hours";
                string jectCost = "Projected Cost";

                xltable = _ws.ListObjects[1];

                dynamic phse = xltable.ListColumns[phaseCode].DataBodyRange.Value2;
                dynamic type = xltable.ListColumns[costType].DataBodyRange.Value2;
                dynamic hours = xltable.ListColumns[jectHours].DataBodyRange.Value2;
                dynamic cost = xltable.ListColumns[jectCost].DataBodyRange.Value2;

                table.Columns.Add(phaseCode, typeof(string));
                table.Columns.Add(costType, typeof(char));
                table.Columns.Add(jectHours, typeof(decimal));
                table.Columns.Add(jectCost, typeof(decimal));

                if (phse.GetType() == typeof(Object[,]))
                {
                    // array version
                    rowCount = phse.GetUpperBound(0);

                    for (int i = 1; i <= rowCount; i++)
                    {
                        var row = table.NewRow();

                        row[phaseCode] = phse[i, 1];

                        switch (type[i, 1].ToString())
                        {
                            case "L":
                                row[costType] = 1;
                                break;
                            case "M":
                                row[costType] = 2;
                                break;
                            case "S":
                                row[costType] = 3;
                                break;
                            case "O":
                                row[costType] = 4;
                                break;
                            case "E":
                                row[costType] = 5;
                                break;
                        }

                        row[jectHours] = hours[i, 1];
                        row[jectCost] = cost[i, 1];
                        table.Rows.Add(row);
                    }
                }
                else
                {
                    // single string version | 1 liner
                    var row = table.NewRow();

                    row[phaseCode] = phse;

                    switch (type)
                    {
                        case "L":
                            row[costType] = 1;
                            break;
                        case "M":
                            row[costType] = 2;
                            break;
                        case "S":
                            row[costType] = 3;
                            break;
                        case "O":
                            row[costType] = 4;
                            break;
                        case "E":
                            row[costType] = 5;
                            break;
                    }

                    row[jectHours] = hours;
                    row[jectCost] = cost;
                    table.Rows.Add(row);
                    rowCount = table.Rows.Count;
                }

                updatedTotal = Data.Viewpoint.JCUpdate.JCUpdateJCPB.SumUpdateJCPB(JCCo, MonthSearch, Job, CostBatchId, table);

                saveManualETC = _ws.get_Range("AG" + "2").Value;

                saveManualETC = saveManualETC == "No" ? "N" : "Y";

                if (LaborRateEdit != null)
                {
                    hours_weeks = LaborTime == LaborEnum.Hours ? "H" : "W"; // ((Excel.Worksheet)LaborRateEdit.Parent).get_Range("R1").Value;
                }

                if (updatedTotal == rowCount)
                {
                    InsertCostBatchJCPBETC.InsCostJCPBETC(JCCo, MonthSearch, costBatchId, dtJCPBETC);

                    if (manualETC_rowsWithValues == 0)
                    {
                        LogProphecyAction.InsProphecyLog(Login, 4, JCCo, _Contract, Job, MonthSearch, CostBatchId, null, insertedRows + " on " + manualETC_visibleRows, saveManualETC, hours_weeks);
                    }
                    else
                    {
                        LogProphecyAction.InsProphecyLog(Login, 4, JCCo, _Contract, Job, MonthSearch, CostBatchId, null, "OVR: " + manualETC_rowsWithValues + " of " + manualETC_visibleRows, saveManualETC, hours_weeks);
                    }
                    Globals.ThisWorkbook.isCostDirty = false;
                    btnPostCost.Visible = true;
                    btnPostCost.Enabled = true;
                    btnFetchData.Text = "Saved";
                    btnFetchData.Enabled = false;

                }
                else
                {
                    throw new Exception("SumUpdateJCPB: there were errors saving your batch - access Viewpoint/JC Cost Projections to determine the issue");
                }

            }
            catch (Exception) { throw; }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }

        private void ValidateLaborHoursMissingRate()
        {
            Excel.Worksheet ws = null;
            Excel.ListObject table = null;
            //Excel.Range rngFrom = null;
            //Excel.Range rngTo = null;
            //Excel.Range rng = null;
            //Excel.Range laborMonthsEdit = null;

            try
            {
                ws = HelperUI.GetSheet(laborSheet + HelperUI.JobTrimDash(Job), true);
                table = ws.ListObjects[1];

                int rateCol = table.ListColumns["Rate"].Index;
                int usedCol = table.ListColumns["Used"].DataBodyRange.Column;
                int startRow = table.HeaderRowRange.Row + 1;
                int monthsLastCol = table.ListColumns.Count;

                // no gray column 
                //rngMthStart = _ws.Cells[startRow, table.ListColumns[phaseActualRate].Index + 4];
                //rngEnd      = _ws.Cells[rngTotals.Row - 1, monthsLastCol];
                //laborMonthsEdit = _ws.get_Range(rngMthStart, rngEnd);

                for (int i = startRow; i <= LaborMonthsEdit.Rows.Count; i++)
                {
                    if (ws.Cells[i, usedCol].Text == "Y")
                    {
                        if ((ws.Cells[i, rateCol].Value == 0 || ws.Cells[i, rateCol].Formula == "") && HelperUI.SumRow(LaborMonthsEdit.Value2, i - startRow + 1) > 0)
                        {
                            // missing rate
                            workbook.Activate();
                            ws.Activate();
                            ws.Cells[i, rateCol].Activate();
                            btnFetchData.Text = "Save Projections to Viewpoint";
                            btnFetchData.Enabled = true;
                            isInserting = false;
                            throw new Exception("You’ve entered projected labor without an hourly rate in the Labor Detail tab.\n\nPlease review your entries.");
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            finally
            {
                //if (rngTo != null) Marshal.ReleaseComObject(rngTo); rngTo = null;
                //if (rngFrom != null) Marshal.ReleaseComObject(rngFrom); rngFrom = null;
                //if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (table != null) Marshal.ReleaseComObject(table); table = null;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
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

                if (PostRev.PostRevBatch(JCCo, MonthSearch, RevBatchId, Login, _Contract))
                {
                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);

                    btnPostRev.Text = "Posted!";
                    btnPostRev.Refresh();

                    MessageBox.Show("Revenue Projection Successfully Posted");

                    _control_ws.Names.Item("ContractPostUser").RefersToRange.Value = Login;
                    _control_ws.Names.Item("ContractLastPost").RefersToRange.Value = HelperUI.DateTimeShortAMPM;

                    //_ws = HelperUI.GetSheet(revSheet, false);
                    //workbook.Application.DisplayAlerts = false;
                    //_ws?.Delete();
                    //workbook.Application.DisplayAlerts = true;
                    btnPostRev.Text = "&Post Rev Batch";

                    RefreshRev(Job);

                    DeleteRevProjectionTab();

                    CostSum_ProjectedMargin_Fill();

                    Globals.ThisWorkbook.EnableSheetChangeEvent(true);

                    _ws = HelperUI.GetSheet(lastContractNoDash);
                    _ws?.Activate();
                    //t2.Stop(); MessageBox.Show(string.Format("Time elapsed: {0:hh\\:mm\\:ss\\:ff}", t2.Elapsed));
                }
            }
            catch (Exception ex)
            {
                object _code = 9; // ERROR default
                if (ex.Data.Count > 0) _code = ex.Data[ex.Data.Count - 1];
                byte code = Convert.ToByte(_code);

                if (code == 9)
                {
                    LogProphecyAction.InsProphecyLog(Login, code, JCCo, _Contract, null, MonthSearch, RevBatchId, ErrorTxt: ex.Message,
                                                     Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                    ShowErr(ex);
                }
                else if (code == 1)
                {
                    LogProphecyAction.InsProphecyLog(Login, code, JCCo, _Contract, null, MonthSearch, RevBatchId, ErrorTxt: "WIP refreshing",
                                                     Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                    //ShowErr(ex, "This contract was unable to load a Projected Revenue Curve.  This is a known issue.\n\n" +
                    //            "We recommend using the MCK Projected Future Revenue report as an alternative.\n\n" +
                    //            "The Resource & Project Management (RPM) platform will eventually be replacing this functionality.");
                    ShowErr(ex, "Unable to refresh data of the selected contract, likely because the WIP is currently refreshing.\n\n" +
                                "Please retry in a few minutes.\n\n" +
                                "If the issue persists, please contact a system administrator.");

                }
                else
                {
                    Globals.ThisWorkbook.isRevDirty = null;
                    btnPostRev.Text = "&Post Rev Batch";
                    btnPostRev.Enabled = true;
                    MessageBox.Show("Revenue Projection was NOT posted:"
                                    + "\nPlease review the batch validation report in Viewpoint."
                                    + "\n\nIf the problem persists, please contact support.");
                    //Possible failure reason: connectivity, wrong employee ID used
                }

            }
            finally
            {
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                workbook.Application.DisplayAlerts = true;
                RenderON();
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }

        private void btnPostCost_Click(object sender, EventArgs e)
        {
            try
            {
                btnPostCost.Text = "Posting in progress";
                btnPostCost.Enabled = false;
                bool success = false;

               // _ws = HelperUI.GetSheet(laborSheet + HelperUI.JobTrimDash(Job), true);
                if (LaborRateEdit != null)
                {
                    hours_weeks = ((Excel.Worksheet)LaborRateEdit.Parent).get_Range("R1").Value;
                }

                try
                {
                    success = PostCost.PostCostBatch(JCCo, MonthSearch, CostBatchId);
                }
                catch (Exception ex)
                {
                    ex.Data.Add(0, 15);
                    throw ex;
                }

                if (success)
                {
                    btnPostCost.Enabled = false;
                    btnPostCost.Text = "Posted!";
                    btnPostCost.Refresh();

                    MessageBox.Show("Cost Projection Successfully Posted");

                    //btnPostCost.Text = "Updating Reports..";
                    //btnPostCost.Refresh();

                    RenderOFF();
                    LogProphecyAction.InsProphecyLog(Login, 11, JCCo, _Contract, Job, MonthSearch, CostBatchId, null, null, saveManualETC, hours_weeks);

                    btnPostCost.Refresh();

                    Globals.ThisWorkbook.EnableSheetChangeEvent(false);

                    string job = HelperUI.JobTrimDash(Job);
                    _control_ws.Names.Item("LastPost_" + job).RefersToRange.Value = HelperUI.DateTimeShortAMPM;
                    _control_ws.Names.Item("PostUser_" + job).RefersToRange.Value = Login;

                    workbook.Application.DisplayAlerts = false;
                    foreach (Excel.Worksheet _ws in workbook.Worksheets)
                    {
                        if (_ws.Name.Contains(costSumSheet) || _ws.Name.Contains(laborSheet) || _ws.Name.Contains(nonLaborSheet) || _ws.Name.Contains(subcontracts) || _ws.Name.Contains(pos))
                        {
                            _ws.Delete();
                        }
                    }
                    workbook.Application.DisplayAlerts = true;

                    Globals.ThisWorkbook.isCostDirty = null;
                    //btnPostCost.Text = "&Post Cost Batch";

                    RefreshCost(Job);

                    CostBatchId = 0;

                    Globals.ThisWorkbook.EnableSheetChangeEvent(true);

                    _ws = HelperUI.GetSheet("-" + job);
                    _ws?.Activate();

                    //Added by JZ 8-25 to make button visible after posting a cost projection
                    btnFetchData.Text = "Generate Cost Projection";
                    btnFetchData.Visible = true;
                    btnPostCost.Visible = false;
                    cboMonth.Enabled = true;
                    lastRevProjectedMonth = MonthSearch;
                    cboJobs.Text = Job;
                }
            }
            catch (Exception ex)
            {
                object _code = 9; // ERROR default
                if (ex.Data.Count > 0) _code = ex.Data[ex.Data.Count - 1];
                byte code = Convert.ToByte(_code);

                if (code == 15)
                {
                    LogProphecyAction.InsProphecyLog(Login, code, JCCo, _Contract, Job, MonthSearch, CostBatchId, ErrorTxt: ex.Message, HoursWeeks: hours_weeks);
                    Globals.ThisWorkbook.isCostDirty = null;
                    btnPostCost.Enabled = true;
                    btnPostCost.Text = "&Post Cost Batch";
                    //Possible failure reason: connectivity, wrong employee ID used
                    MessageBox.Show("Cost Projection was NOT posted, please review the batch validation report in Viewpoint.\n\n" +
                                    "The most common issue is an invalid Employee ID.\n\n" +
                                    "If the problem persists, please contact support.");
                }
                else //error after successful post
                {
                    LogProphecyAction.InsProphecyLog(Login, code, JCCo, _Contract, Job, MonthSearch, CostBatchId, ErrorTxt: ex.Message,
                                                     Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version, HoursWeeks: hours_weeks);
                    ShowErr(ex);
                }
            }
            finally
            {
                Globals.ThisWorkbook.EnableSheetChangeEvent(true);
                workbook.Application.DisplayAlerts = true;
                btnPostCost.Text = "&Post Cost Batch";
                RenderON();

                if (_ws != null) Marshal.ReleaseComObject(_ws);
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
                DisableGridlines();
                _ws = HelperUI.GetSheet(revCurve);
                if (_ws != null) BuildPRGPivot_RevCurve(_ws);

                _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            }
            catch (Exception ex)
            {
                //if (ex.Message.Contains("GetContractPRG Exception") ||
                //    ex.Message.Contains("GetContractPRGPivot Exception") ||
                //    ex.Message.Contains("GetContractPRGTable: Timeout expired.") ||
                //    ex.Message.Contains("GetContractPRGTable: Transaction"))
                //{

                ex.Data.Add(0, 1);
                throw ex;
            }
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

                DataTable table = ContractRefresh.GetContractPostRefresh(JCCo, _Contract);
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

                DisableGridlines();

                _ws = HelperUI.GetSheet(revCurve);
                if (_ws != null) BuildPRGPivot_RevCurve(_ws);

                _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (_ws != null) Marshal.ReleaseComObject(_ws);
            }
        }
        #endregion


        #region CANCEL BATCH

        internal void btnCancelRevBatch_Click(object sender, EventArgs e, bool prompt = true)
        {
            string msg = "";

            if (RevBatchId > 0)
            {
                DialogResult r = DialogResult.Yes;

                if (prompt)
                {
                    OpenBatches.HighlightBatchRow(RevBatchId);

                    r = MessageBox.Show("Are you sure you want to cancel batch " + RevBatchId  + "? ", "Cancel Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                }

                if (r == DialogResult.Yes)
                {
                    try
                    {
                        if (DeleteRevBatch.DeleteBatchRev(JCCo, lastRevProjectedMonth, RevBatchId))
                        {
                            LogProphecyAction.InsProphecyLog(Login, 12, JCCo, _Contract, null, lastRevProjectedMonth, RevBatchId);

                            msg = "Revenue Batch " + RevBatchId + " was successfully cancelled";
                            DeleteRevProjectionTab();
                        }
                        else
                        {
                            msg = "Revenue Batch was NOT cancelled.  Please retry or log in to the Viewpoint application to cancel the batch.\n\nIf problem persists contact support. ";
                            //Possible failure reason: connectivity, cancelled via VP application
                        }
                        OpenBatches.RefreshOpenBatchesUI();
                        OpenBatches.HighlightBatchRow(0);
                        MessageBox.Show(msg);
                    }
                    catch (Exception ex)
                    {
                        LogProphecyAction.InsProphecyLog(Login, 12, JCCo, _Contract, null, lastRevProjectedMonth, RevBatchId, ex.Message);
                        ShowErr(ex);
                    }
                    finally
                    {
                        Application.UseWaitCursor = false;
                    }
                }

                if (msg == "") OpenBatches.HighlightBatchRow(0);
            }
        }

        internal void btnCancelCostBatch_Click(object sender, EventArgs e, bool prompt)
        {
            string msg = "";

            if (CostBatchId > 0)
            {
                DialogResult r = DialogResult.Yes;

                if (prompt)
                {
                    OpenBatches.HighlightBatchRow(CostBatchId);

                    r = MessageBox.Show("Are you sure you want to cancel " + CostBatchId + "? ", "Cancel Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                }

                if (r == DialogResult.Yes)
                {
                    try
                    {
                        Application.UseWaitCursor = true;
                        if (DeleteCostBatch.DeleteBatchCost(JCCo, lastCostProjectedMonth, CostBatchId))
                        {
                            LogProphecyAction.InsProphecyLog(Login, 10, JCCo, _Contract, Job, lastCostProjectedMonth, CostBatchId);

                            workbook.Application.DisplayAlerts = false;
                            foreach (Excel.Worksheet _ws in workbook.Worksheets)
                            {
                                if (_ws.Name.Contains(costSumSheet) || _ws.Name.Contains(laborSheet) || _ws.Name.Contains(nonLaborSheet) || _ws.Name.Contains(subcontracts) || _ws.Name.Contains(pos))
                                {
                                    _ws.Delete();
                                }
                            }
                            workbook.Application.DisplayAlerts = true;
                            msg = "Cost Batch " + CostBatchId + " was successfully cancelled";
                            btnCancelCostBatch.Enabled = false;
                            btnCancelCostBatch.Text = "Cancel Cost Batch: ";
                            CostBatchId = 0;
                            OpenBatches.RefreshOpenBatchesUI();
                        }
                        else
                        {
                            msg = "Cost Batch was NOT cancelled.  Please retry or log in to the Viewpoint to cancel the batch.\n\n  If problem persists contact support. ";
                            //Possible failure reason: connectivity, cancelled via VP application
                        }
                        OpenBatches.HighlightBatchRow(0);
                        MessageBox.Show(msg);
                    }
                    catch (Exception ex)
                    {
                        LogProphecyAction.InsProphecyLog(Login, 10, JCCo, _Contract, Job, lastCostProjectedMonth, CostBatchId, ex.Message);
                        ShowErr(ex);
                    }
                    finally
                    {
                        Application.UseWaitCursor = false;
                    }
                }

                if (msg == "") OpenBatches.HighlightBatchRow(0);
            }
        }

        #endregion


        #region OPEN BATCHES

        private void btnOpenBatches_Click(object sender, EventArgs e)
        {
            string orig_text = btnOpenBatches.Text;
            btnOpenBatches.Text = "Processing...";
            btnOpenBatches.Enabled = false;

            try
            {
                OpenBatches.RefreshOpenBatchesUI(true);
            }
            catch (Exception ex) { ShowErr(ex); }
            finally
            {
                tmrRestoreButtonText.Interval = 200;
                tmrRestoreButtonText.Tag = new object[] { btnOpenBatches, orig_text };
                tmrRestoreButtonText.Enabled = true;
                cboJobs.Focus();
                txtBoxContract.Focus();
            }
        }

        //internal void RefreshOpenBatchesUI(bool notify = true)
        //{
        //    Excel.Range rng = null;
        //    string btnName = "";

        //    try
        //    {
        //        ClearOpenBatches(Globals.ControlSheet.OpenBatchesStartCol, Globals.ControlSheet.OpenBatchesEndCol);

        //        openBatches = OpenBatches.GetOpenBatches(Login);

        //        if (openBatches.Count == 0 && notify)
        //        {
        //            MessageBox.Show("You have no open batches");
        //            return;
        //        }

        //        // are there more buttons than batch rows ?
        //        int lastButtonRow = open_batches_row_offset + openBatches.Count;
        //        btnName = "btnCancel" + lastButtonRow;
                
        //        if (Globals.ControlSheet.Controls.Contains(btnName))
        //        {
        //            // yes, remove orphane buttons
        //            Button btn = (Button)Globals.ControlSheet.Controls[btnName];
        //            btn.Click -= Globals.ControlSheet.btnCancel_Click;
        //            Globals.ControlSheet.Unprotect(ETCOverviewActionPane.pwd);
        //            Globals.ControlSheet.Controls.Remove(btn.Name);
        //            btn.Dispose();
        //            HelperUI.ProtectSheet(Globals.ControlSheet.InnerObject);
        //        }

        //        foreach (Batch b in openBatches)
        //        {
        //            // put row in worksheet
        //            object[] row = { b.ContractOrJob, b.BatchId, b.ProjectionMonth, b.Type };
        //            _control_ws.get_Range(Globals.ControlSheet.OpenBatchesStartCol + open_batches_row_offset + ":" + Globals.ControlSheet.OpenBatchesEndCol + open_batches_row_offset).Value2 = row;
                    
        //            // corresponding button cell
        //            rng = _control_ws.get_Range("L" + open_batches_row_offset);

        //            btnName = "btnCancel" + open_batches_row_offset;

        //            if (!(Globals.ControlSheet.Controls.Contains(btnName)))
        //            {
        //                // doesn't exist, create it
        //                Button btn = new Button
        //                {
        //                    Text = "Cancel",
        //                    Name = "btnCancel" + open_batches_row_offset,
        //                    Tag = open_batches_row_offset,
        //                };

        //                btn.Click += Globals.ControlSheet.btnCancel_Click;

        //                Globals.ControlSheet.Controls.AddControl(btn, rng, btn.Name);
        //            }
        //            else
        //            {
        //                // get existing button
        //                Control _btn = (Control)Globals.ControlSheet.Controls[btnName];
        //                Button btn = (Button)_btn;

        //                // if not in correct position, move to corresponding batch row 
        //                if ((int)btn.Tag != open_batches_row_offset)
        //                {
        //                    btn.Tag = open_batches_row_offset;
        //                    btn.Location = RangeToPoint.GetCellPosition(rng);
        //                }

        //            }
        //            ++open_batches_row_offset;
        //        }

        //        _control_ws.get_Range("H10").Activate();
        //    }
        //    catch (Exception)
        //    {
        //        throw;
        //    }
        //    finally
        //    {
        //        open_batches_row_offset = _control_ws.Names.Item("ContractNumber").RefersToRange.Row;
        //    }
        //}

        //internal void ClearOpenBatches(string colStart, string colEnd)
        //{
        //    _control_ws.Activate();
        //    open_batches_row_offset = _control_ws.Names.Item("ContractNumber").RefersToRange.Row;
        //    _control_ws.get_Range(colStart + open_batches_row_offset + ":" + colEnd + "35").Value = "";
        //    _control_ws.get_Range("A3").Activate();
        //}

        #endregion


        #region ACTION PANE's CONTROL RESPONSE

        public string[] FetchContractList()
        {
            contractList = ContractList.GetContractList(JCCo, _Contract);

            return contractList
                  .Select(x => x.TrimContractId)
                  .ToArray();

            //contractList_table = ContractList.GetContractList(JCCo, Contract);
            //// LINQ method pulls Title from a DT into a string array...
            //return contractList_table
            //          .AsEnumerable()
            //          .Select<DataRow, String>(x => x.Field<String>("TrimContract"))
            //          .ToArray();
        }

        internal bool ValidateContract_RefreshJobs()
        {
            if (txtBoxContract.Text == "") return false;

            errorProvider1.Clear();

            if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-"; // auto-correct contract

            Refresh_cboJobs(txtBoxContract.Text);

            return true;
        }

        /// <summary>
        /// Sets active Co and refresh jobs
        /// </summary>
        /// <param name="contract"></param>
        /// <returns></returns>
        internal bool Refresh_cboJobs(string contract)
        {
            // Get corresponding company for selected contract
            Contract c = contractList.Where(x => x.TrimContractId == contract || x.ContractId == contract)?.FirstOrDefault();

            if (c == null)
            {
                cboJobs.DataSource = null;
                cboJobs.SelectedItem = "";
                errorProvider1.SetIconAlignment(txtBoxContract, ErrorIconAlignment.MiddleRight);
                errorProvider1.SetError(txtBoxContract, "Select a Contract from the list");
                return false;
            }

            prevContract = txtBoxContract.Text;

            JCCo = c.JCCo;
            _Contract = c.ContractId;

            cboJobs.Enabled = true;
            cboJobs.DataSource = null;
            cboJobs.Items.Clear();
            //cboJobs.Items.Add("All Projects");
            cboJobs.DataSource = c.Projects;
            cboJobs.Refresh();

            if (!(cboJobs.Items.Contains(cboJobs.SelectedItem)))
            {
                cboJobs.SelectedItem = allprojects;
                cboJobs.SelectedIndex = 0;
            }
            else
            {
                cboJobs.SelectedIndex = cboJobs.Items.IndexOf(cboJobs.SelectedItem);
            }
            cboJobs.Refresh();
            return true;
        }

        private void txtBoxContract_Leave(object sender, EventArgs e) => ValidateContract_RefreshJobs();

        // Allows hitting enter to invoke button click
        private void txtBoxContract_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                this.btnFetchData_Click(sender, null);

                //if (txtBoxContract.Text != "")
                //{
                //    if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";

                //    if (ValidateContract_RefreshJobs()) 
                //}
                //else
                //{
                //    errorProvider1.SetIconAlignment(txtBoxContract, ErrorIconAlignment.MiddleRight);
                //    errorProvider1.SetError(txtBoxContract, "Select a Contract from the list");
                //}
            }
        }

        // clear Project when Contract is empty
        private void txtBoxContract_TextChanged(object sender, EventArgs e)
        {
            if (txtBoxContract.Text == "")
            {
                _Contract = null;
                cboJobs.DataSource = null;
                cboJobs.Enabled = false;
            }
            else { cboJobs.Enabled = true; }
        }

        private void cboJobs_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                if (!txtBoxContract.Text.Contains("-")) txtBoxContract.Text += "-";

                e.Handled = true;

                if (!cboJobs.Text.Contains(lastContractNoDash) && cboJobs.SelectedIndex == 0)
                {
                    cboJobs.SelectedIndex = 0;
                    cboJobs.Text = allprojects;
                }

                this.btnFetchData_Click(sender, null);
            }
        }

        private void dpMonth_IndexChanged(object sender, EventArgs e)
        {
            errorProvider1.Clear();
            MonthSearch = DateTime.Parse(cboMonth.SelectedItem.ToString());
        }

        private void LoadContractProphecyHistory()
        {
            _control_ws.Names.Item("ContractNumber").RefersToRange.Value = txtBoxContract.Text;
            _control_ws.Names.Item("ContractName").RefersToRange.Value = JobGetTitle.GetTitle(JCCo, txtBoxContract.Text);
            _control_ws.Names.Item("ContractName").RefersToRange.EntireColumn.AutoFit();

            jobAudit_list = ContractJectAudit.GetProjectionAudit(JCCo, _Contract);

            if (jobAudit_list.Count == 0) return; // no projection history

            // Update Contract's revenue 
            ProjectionAudit _job = jobAudit_list.Where(x => x.Job == DBNull.Value).FirstOrDefault();
            if (_job != null)
            {
                _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = _job.LastSave != DBNull.Value ? _job.LastSave : "—";
                _control_ws.Names.Item("ContractSaveUser").RefersToRange.Value = _job.SaveUser; // != DBNull.Value ? _job.SaveUser : "";
                _control_ws.Names.Item("ContractLastPost").RefersToRange.Value = _job.LastPost != DBNull.Value ? _job.LastPost : "—";
                _control_ws.Names.Item("ContractPostUser").RefersToRange.Value = _job.PostUser; // != DBNull.Value ? _job.PostUser : "";
            }

            // Update jobs
            int job_start = -1, job_last = 0;

            if (Job != null)
            {
                // single job
                ProjectionAudit job_audit = jobAudit_list.Where(x => x.Job.ToString() == Job).FirstOrDefault();
                if (job_audit == null) return;
                job_start = job_last = jobAudit_list.IndexOf(job_audit);
            }
            else if (jobAudit_list.Count > 0) // all jobs
            {
                job_last = jobAudit_list.Count - 1;
                job_start = job_last == 0 ? 0 : 1; 
            }

            if (job_start >= 0)
            {
                for (int i = job_start; i <= job_last; i++)
                {
                    _job = jobAudit_list[i];

                    //Cost
                    if (jobAudit_list[i].Job != DBNull.Value)
                    {
                        string _pn = HelperUI.JobTrimDash(jobAudit_list[i].Job.ToString());
                        if (_pn != null)
                        {
                            _control_ws.Names.Item("LastSave_" + _pn).RefersToRange.Value = _job.LastSave != DBNull.Value ? _job.LastSave : "—";
                            _control_ws.Names.Item("SaveUser_" + _pn).RefersToRange.Value = _job.SaveUser != DBNull.Value ? _job.SaveUser : "";
                            _control_ws.Names.Item("LastPost_" + _pn).RefersToRange.Value = _job.LastPost != DBNull.Value ? _job.LastPost : "—";
                            _control_ws.Names.Item("PostUser_" + _pn).RefersToRange.Value = _job.PostUser != DBNull.Value ? _job.PostUser : "";
                        }
                    }
                }
            }
        }

        // paint font on Dropdown menus 
        private void cboBoxes_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString()
                                   , e.Font
                                   , brush
                                   , e.Bounds
                                   , System.Drawing.StringFormat.GenericDefault
                                  );
            e.DrawFocusRectangle();
        }

        // switch Project and Month backcolors on enable/disable
        private void ComboboxSwitchBackColor_EnabledChanged(object sender, EventArgs e)
        {
            ComboBox c = (ComboBox)sender;
            c.BackColor = c.Enabled == false ? System.Drawing.Color.LightGray : System.Drawing.SystemColors.Info;
        }


        /// <summary>
        /// Restores buttons to their original text. Just send the button and orignal text via the timer's tag as object [0]=button, [1]=origText
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void tmrRestoreButtonText_Tick(object sender, EventArgs e)
        {
            object[] objects = (object[])tmrRestoreButtonText.Tag;
            Button button = (Button)objects[0];
            button.Text = (string)objects[1];
            button.Enabled = true;
            tmrRestoreButtonText.Enabled = false;
        }

        #endregion


        #region  SAVE COST DETAIL / FUTURE CURVE OFFLINE

        public delegate void CopySheetsOffline(string filename, string job, object[] logData);
        public CopySheetsOffline copyCostDetailsOffline = new CopySheetsOffline(ETCOverviewActionPane.CopyCostDetailOffline);
        public CopySheetsOffline copyFutureCurveOffline = new CopySheetsOffline(ETCOverviewActionPane.CopyFutureCurveOffline);

        private void btnCopy_CostDetail_FutureCurve_Offline_Click(object sender, EventArgs e)
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
                    saveFileDialog1.FileName = "Future Curve " + _Contract + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);
                }

                DialogResult action = saveFileDialog1.ShowDialog();

                if (action == DialogResult.OK)
                {
                    object[] logData = { Login, JCCo, _Contract, Job, MonthSearch, CostBatchId };

                    copySheetsOffline(saveFileDialog1.FileName, cboJobs.Text, logData);

                    tmrRestoreButtonText.Tag = new object[] { btnCopyDetailOffline, orig_text };
                    btnCopyDetailOffline.Text = "Copied";
                    tmrRestoreButtonText.Enabled = true;
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
                ShowErr(ex);
            }
        }

        public static void CopyCostDetailOffline(string fullPathFilename, string Job, object[] logData)
        {
            if (HelperUI.SheetExists(costSumSheet, false))
            {
                Excel.Worksheet wsTo = null;
                Excel.Worksheet wsFrom = null;
                Excel.Workbook wkbFrom = null;
                Excel.Workbook wkbTo = null;
                Excel.ListObject tableTo = null;
                Excel.ListObject tableFrom = null;
                Excel.Range manualETCcost = null;
                string job = HelperUI.JobTrimDash(Job);
                string report = "-" + job;
                string costSum = ETCOverviewActionPane.costSumSheet + job;
                string labor = ETCOverviewActionPane.laborSheet + job;
                string nonlabor = ETCOverviewActionPane.nonLaborSheet + job;
                string _subcontract = ETCOverviewActionPane.subcontracts + job;
                string _POs = ETCOverviewActionPane.pos + job;
                string Login = (string)logData[0];
                byte JCCo = (byte)logData[1];
                string Contract = (string)logData[2];
                DateTime Month = (DateTime)logData[4];
                uint CostBatchId = (uint)logData[5];
                string contract = Contract.Replace(" ", "").Replace("-", "");
                string contractTabName = Contract.Replace("-", "");
                try
                {
                    RenderOFF();

                    wkbFrom = Globals.ThisWorkbook.Worksheets.Parent;
                    wkbTo = wkbFrom.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                    wkbFrom.Sheets[contractTabName].Copy(After: wkbTo.Sheets["Sheet1"]);
                    wkbFrom.Sheets[report].Copy(After: wkbTo.Sheets[contractTabName]);
                    wkbFrom.Sheets[costSum].Copy(After: wkbTo.Sheets[report]);
                    wkbFrom.Sheets[labor].Copy(After: wkbTo.Sheets[costSum]);
                    wkbFrom.Sheets[nonlabor].Copy(After: wkbTo.Sheets[labor]);

                    wkbTo.Application.DisplayAlerts = false;

                    wkbTo.Sheets["Sheet1"].Delete();

                    wsFrom = HelperUI.GetSheet(_subcontract);
                    if (wsFrom != null)
                    {
                        wsFrom.Copy(After: wkbTo.Sheets[nonlabor]);
                        wkbTo.Sheets[_subcontract].Unprotect(ETCOverviewActionPane.pwd);
                    }

                    wsFrom = HelperUI.GetSheet(_POs);
                    if (wsFrom != null)
                    {
                        wsFrom.Copy(After: wkbTo.Sheets[nonlabor]);
                        wkbTo.Sheets[_POs].Unprotect(ETCOverviewActionPane.pwd);
                    }

                    wkbTo.Sheets[costSum].Activate();
                    wkbTo.Application.Calculation = Excel.XlCalculation.xlCalculationManual;

                    string workbookName = "\'" + Globals.ThisWorkbook.FullName + "\'!";
                    string formula;

                    // CostSum copy column formulas
                    wsFrom = wkbFrom.Sheets[costSum];
                    tableFrom = wsFrom.ListObjects[1];
                    wsTo = wkbTo.Sheets[costSum];
                    wsTo.Names.Item("NewProjectedMargin").RefersToRange.Formula = wsTo.Names.Item("NewProjectedMargin").RefersToRange.Value;

                    tableTo = wsTo.ListObjects[1];

                    PreserveFilters(ref wsTo);

                    tableTo.AutoFilter.ShowAllData();

                    string[] newWorkbook_columns_formulas = { "Used" , "Projected Remaining Hours","Projected Remaining Manweeks", "Projected Remaining Total Cost", "Remaining CST/HR", "Projected Hours", "Projected Cost" , "Change in Hours", "Change in Cost",
                                                             "Change from LM Projected Hours", "Change from LM Projected Cost", "Over/Under Hours", "Over/Under Cost" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTo.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTo.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }

                    // Manual ETC Cost can contain formula and values; save both
                    manualETCcost = tableTo.ListColumns["Manual ETC Cost"].DataBodyRange;

                    foreach (Excel.Range cell in manualETCcost)
                    {
                        wsTo.get_Range(cell.Address).FormulaR1C1 = cell.Locked ? ((string)cell.FormulaR1C1).Replace(workbookName, "") : cell.Value;
                    }

                    // re-apply filters
                    foreach (Filter filter in _filters)
                    {
                        tableTo.Range.AutoFilter(filter.Column, filter.Criteria1, Excel.XlAutoFilterOperator.xlFilterValues, filter.Criteria2, true);
                    }

                    // Labor columns w/ formulas
                    wsTo    = wkbTo.Worksheets[labor];
                    tableTo = wsTo.ListObjects[1];

                    PreserveFilters(ref wsTo);

                    tableTo.AutoFilter.ShowAllData();

                    newWorkbook_columns_formulas = new string[] { "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", "Phase Actual Rate" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTo.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTo.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }

                    // re-apply filters
                    foreach (Filter filter in _filters)
                    {
                        tableTo.Range.AutoFilter(filter.Column, filter.Criteria1, Excel.XlAutoFilterOperator.xlFilterValues, filter.Criteria2, true);
                    }

                    // Non-labor columns w/ formulas
                    wsTo = wkbTo.Worksheets[nonlabor];
                    tableTo = wsTo.ListObjects[1];

                    PreserveFilters(ref wsTo);

                    tableTo.AutoFilter.ShowAllData();

                    newWorkbook_columns_formulas = new string[] { "Budgeted Phase Cost Remaining", "Phase Open Committed" };

                    foreach (string column in newWorkbook_columns_formulas)
                    {
                        formula = tableTo.ListColumns[column].DataBodyRange.FormulaR1C1[1, 1];
                        tableTo.ListColumns[column].DataBodyRange.FormulaR1C1 = formula.Replace(workbookName, "");
                    }


                    // re-apply filters
                    foreach (Filter filter in _filters)
                    {
                        tableTo.Range.AutoFilter(filter.Column, filter.Criteria1, Excel.XlAutoFilterOperator.xlFilterValues, filter.Criteria2, true);
                    }

                    wkbTo.Sheets[contractTabName].Unprotect(ETCOverviewActionPane.pwd);
                    wkbTo.Sheets[report].Unprotect(ETCOverviewActionPane.pwd);
                    wkbTo.Sheets[labor].Unprotect(ETCOverviewActionPane.pwd);
                    wkbTo.Sheets[nonlabor].Unprotect(ETCOverviewActionPane.pwd);
                    wkbTo.Application.Calculation = Excel.XlCalculation.xlCalculationAutomatic;

                    wkbFrom.ForceFullCalculation = true;
                    wkbTo.Close(true, fullPathFilename, Type.Missing);

                }
                catch (Exception ex)
                {
                    LogProphecyAction.InsProphecyLog(Login, 9, JCCo, Contract, Job, Month, CostBatchId, getEvilFunctionProd(ex), "CopyCostDetailOffline");
                    throw;
                }
                finally
                {
                    RenderON();
                    wkbFrom.Application.DisplayAlerts = true;
                    if (wkbTo != null) Marshal.ReleaseComObject(wkbTo);
                    if (wkbFrom != null) Marshal.ReleaseComObject(wkbFrom);
                    if (wsTo != null) Marshal.ReleaseComObject(wsTo);
                    if (wsFrom != null) Marshal.ReleaseComObject(wsFrom);
                    if (tableTo != null) Marshal.ReleaseComObject(tableTo);
                    if (tableFrom != null) Marshal.ReleaseComObject(tableFrom);
                    if (manualETCcost != null) Marshal.ReleaseComObject(manualETCcost);
                }
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
                LogProphecyAction.InsProphecyLog(Login, 9, JCCo, Contract, null, null, 0x0, getEvilFunctionProd(ex), "CopyFutureCurveOffline");
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

        #endregion


        #region ERROR HANDLING

        private void ReportErrOut(Exception ex)
        {
            if (ex == null) return;

            if (ex.Message.Contains("GetContractPRGTable") ||
                ex.Message.Contains("Timeout expired") ||
                ex.Message.Contains("WIP may be refreshing") ||
                ex.Message.Contains("GetContractPRGTable: Transaction") ||
                ex.Message.Contains("GetContractPRGPivotTable"))
            {
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, MonthSearch, RevBatchId, ErrorTxt: "WIP refreshing",
                                 Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                ShowErr(ex, "Unable to refresh all data for the selected contract because the WIP is currently refreshing.\n\n" +
                            "Please try again in a few minutes.\n\n" +
                            "If the issue persists, please contact a system administrator.");
            }
            else if (ex.Data.Count > 0)
            {
                byte errcode = Convert.ToByte(ex.Data[0]);

                Log_and_ShowErr(ex, errcode);
            }
            else
            {
                LogProphecyAction.InsProphecyLog(Login, 1, JCCo, _Contract, Job, ErrorTxt: getEvilFunctionProd(ex),
                                  Details: ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version);
                ShowErr(ex);
            }
            btnFetchData.Text = "&Get Contract && Projects";
            btnFetchData.Refresh();

            workbook.Application.DisplayAlerts = false;
            if (workbook.Application.WindowState == Excel.XlWindowState.xlMinimized)
            {
                workbook.Application.WindowState = Excel.XlWindowState.xlNormal; // otherwise if minimized, crashes on .Delete() below
            }
            foreach (Excel.Worksheet _ws in workbook.Worksheets)
            {
                if (_ws.Name != "Control" && !_ws.Name.Contains(revSheet)) _ws.Delete();
            }
            workbook.Application.DisplayAlerts = true;

            RevBatchId = 0;
            CostBatchId = 0;
            Globals.ThisWorkbook.isRevDirty = null;
            Globals.ThisWorkbook.isCostDirty = null;
            ClearControlSheet();
        }

        private void CostJectErrOut(Exception ex)
        {
            if (ex == null) return;
            // if not using generi "ERROR" 9, use other
            object _errcode = 9;
            if (ex.Data.Count > 0)
            {
                _errcode = ex.Data[0];
            }
            byte errcode = Convert.ToByte(_errcode);

            Log_and_ShowErr(ex, errcode);

            if (errcode == 17) return; // on save error, leave sheets

            workbook.Application.DisplayAlerts = false;
            if (workbook.Application.WindowState == Excel.XlWindowState.xlMinimized)
            {
                workbook.Application.WindowState = Excel.XlWindowState.xlNormal; // otherwise if minimized, crashes on .Delete() below
            }
            foreach (Excel.Worksheet _ws in workbook.Worksheets)
            {
                if (_ws.Name.Contains(costSumSheet) || _ws.Name.Contains(laborSheet) || _ws.Name.Contains(nonLaborSheet))
                {
                    _ws.Delete();
                }
            }
            workbook.Application.DisplayAlerts = true;

            CostBatchId = 0;
            Globals.ThisWorkbook.isCostDirty = null;
        }

        private void RevJectErrOut(Exception ex)
        {
            if (ex == null) return;

            object _errcode = 9;
            if (ex.Data.Count > 0)
            {
                _errcode = ex.Data[0];
            }
            byte errcode = Convert.ToByte(_errcode);

            Log_and_ShowErr(ex, errcode);

            if (errcode == 16) return; // on save error, leave sheet

            DeleteRevProjectionTab();

            //workbook.Application.DisplayAlerts = false;

            //if (workbook.Application.WindowState == Excel.XlWindowState.xlMinimized)
            //{
            //    workbook.Application.WindowState = Excel.XlWindowState.xlNormal; // otherwise if minimized, crashes on .Delete() below
            //}
            //foreach (Excel.Worksheet _ws in workbook.Worksheets)
            //{
            //    if (_ws.Name.Contains(revSheet))
            //    {
            //        _ws.Delete();
            //    }
            //}
            //workbook.Application.DisplayAlerts = true;

            _ws = HelperUI.GetSheet(lastContractNoDash, true);
            _ws?.Activate();
        }

        /// <summary>
        /// Provides users with more meaningful error messages when they tab over to other sheets while invoking Prophecy actions
        /// </summary>
        /// <param name="ex"></param>
        /// <param name="code"></param>
        private void Log_and_ShowErr(Exception ex, byte code)
        {
            if (ex == null) return;

            string detail = null;
            string errToUser = null;
            string errLog = null;
            bool wrongSheetFocus = false;
            bool saveUserErrToDetail = ex.Data.Count == 2;

            string action = null;

            // show proper root action action to user
            if (code == 1)
            {
                action = "report creation";
            }
            else if (code == 3)
            {
                action = "Cost projection";
            }
            else if (code == 6)
            {
                action = "Revenue projection";
            }
            else if (code == 16 || code == 17)
            {
                action = "saving the projection";
            }

            if (action != null) // loading cost or rev
            {
                // curate message to user when they initiate processing but then select a different worksheet
                wrongSheetFocus = ex.Message.Contains("Invalid index. (Exception from HRESULT: 0x8002000B (DISP_E_BADINDEX))") ||
                                    ex.Message.Contains("Exception from HRESULT: 0x800A03EC") ||
                                    ex.Message.Contains("Activate method of Range class failed") ||
                                    //ex.Message.Contains("Object reference not set to an instance of an object.") ||
                                    ex.Message.Contains("Select method of Range class failed") ||
                                    ex.Message.Contains("Attempted to read or write protected memory. This is often an indication that other memory is corrupt.") ||
                                    ex.Message.Contains("Unable to set the FreezePanes property of the Window class") ||
                                    ex.Message.Contains("ForwardCallToInvokeMember") ? true : false;
                errToUser = wrongSheetFocus ? "Error: Unable to complete " + action + ":\n\n" +
                                            "Try again, this time allow the projection to complete prior to accessing a different Excel worksheet." : ex.Message;
            }

            if (saveUserErrToDetail)
            {
                detail = ex.Data[1].ToString(); // log custom error detail
            }
            else  // active sheet name w / version
            {
                detail = ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version;
            }

            // set ErrText log
            if (wrongSheetFocus)
            {
                errLog = "Diff sheet selected while processing";
            }
            else if (saveUserErrToDetail)
            {
                errLog = null;
            }
            else
            {
                errLog = ex.Message;
            }

            LogProphecyAction.InsProphecyLog(Login, code, JCCo, _Contract, Job, ErrorTxt: errLog, Details: detail);
            ShowErr(ex, errToUser);  // facing user
        }

        internal void ShowErr(Exception ex = null, string customErr = null, string title = "Failure!")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);

        }

        private static string getEvilFunctionProd(Exception ex)
        {
            if (ex == null) return null;

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

            return err_evil_line;
        }


        #endregion


        #region SAVE WORKBOOK

        public bool ClearWorkbook_SavePrompt() => SavePrompt(deleteSheets: true);

        public bool SavePrompt(bool deleteSheets)
        {
            if (HelperUI.SheetExists(lastContractNoDash, false))
            {
                DialogResult action;

                if (RevBatchId > 0 && CostBatchId > 0 && !alreadyPrompted)
                {
                    MessageBox.Show("You have open batches that have not been saved.  Please save or cancel your batches.", "Open Batches", MessageBoxButtons.OK, MessageBoxIcon.Question);
                    _control_ws.Activate();
                    alreadyPrompted = true;
                    return false;
                }
                else if (!alreadyPrompted)
                {
                    _ws = HelperUI.GetSheet(revSheet, false);
                    if (_ws != null && Globals.ThisWorkbook.isRevDirty == true)
                    {
                        action = MessageBox.Show("Would you like to save your Revenue projections to Viewpoint?", "Save Revenue Projections", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                        if (action == DialogResult.Cancel) return false;
                        if (action == DialogResult.Yes)
                        {
                            userOKtoSaveRev = true;
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
                            saveFileDialog1.FileName = Job + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);
                            action = saveFileDialog1.ShowDialog();
                            if (action == DialogResult.OK)
                            {
                                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Worksheets) ws.Unprotect(ETCOverviewActionPane.pwd);

                                Globals.ThisWorkbook.alreadyPrompted = true;
                                Globals.ThisWorkbook.RemoveCustomization();
                                Globals.ThisWorkbook.SaveAs(saveFileDialog1.FileName);
                            }
                            else if (action == DialogResult.Cancel)
                            {
                                return false;
                            }
                        }
                        catch (Exception ex) { ShowErr(ex); }
                    }
                }
                if (deleteSheets)
                {
                    workbook.Application.DisplayAlerts = false;
                    //foreach (Excel.Worksheet _ws in workbook.Worksheets)
                    //{
                    //    if (_ws.Name != "Control" && !_ws.Name.Contains("Rev-")) _ws.Delete();
                    //}
                    foreach (Excel.Worksheet _ws in workbook.Worksheets)
                    {
                        if (_ws.Name != "Control") _ws.Delete();
                    }
                    workbook.Application.DisplayAlerts = true;
                    DeleteRevProjectionTab(false);

                    CostBatchId = 0;
                    Globals.ThisWorkbook.isCostDirty = null;
                    ClearControlSheet();
                    Globals.ThisWorkbook.laborUserInsertedRowCount?.Clear();
                    Globals.ThisWorkbook.nonLaborUserInsertedRowCount?.Clear();
                }
            }
            return true;
        }

        #endregion


        #region ALLOW SORTING ON PROTECTED SHEETS
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
                catch (Exception)
                {
                    tmrWaitSortWinClose.Enabled = false;
                    Globals.ThisWorkbook.isSorting = false;
                }
                finally
                {
                    if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                }
            }
        }

        #endregion


        // lessen CPU consumption / speed things up
        private static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;

        private static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        private void ClearControlSheet()
        {
            foreach (Excel.Name n in _control_ws.Names)
            {
                n.RefersToRange.Value = "";

                if (n.Name.Contains("_") ||
                    n.Name.Contains("LastSave_") ||
                    n.Name.Contains("SaveUser_") ||
                    n.Name.Contains("LastPost_") ||
                    n.Name.Contains("PostUser_"))
                {
                    n.Delete(); continue;
                }
            }

            _control_ws.Names.Item("ViewpointLogin").RefersToRange.Value = Login;
            _control_ws.Names.Item("TimeOpening").RefersToRange.Value = HelperUI.DateTimeShortAMPM;
            _control_ws.Names.Item("TimeLastRefresh").RefersToRange.Value = "—";
            _control_ws.Names.Item("ContractLastSave").RefersToRange.Value = "—";
            _control_ws.Names.Item("ContractLastPost").RefersToRange.Value = "—";
            _control_ws.get_Range("A15:B24").Value = "";  // Contract Number / Name
            _control_ws.get_Range("C15:C24").Value = "—"; // Last Save
            _control_ws.get_Range("D15:D24").Value = "";  // Save By
            _control_ws.get_Range("E15:E24").Value = "—"; // Last Post
            _control_ws.get_Range("F15:F24").Value = "";  // Post By
        }

        private void DeleteRevProjectionTab(bool delete = true)
        {
            //if (Globals.Rev.Visible == Excel.XlSheetVisibility.xlSheetVisible)
            //{
            //    Globals.Rev.Unprotect(pwd);
            //    Globals.Rev.Controls.Remove("Rev_Projection");
            //    Globals.Rev.UsedRange.EntireRow.Delete();
            //    Globals.Rev.Name = ETCOverviewActionPane.revSheet;
            //    Globals.Rev.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
            //    Globals.Rev.UsedRange.ClearOutline();
            //}
            if (delete)
            {
                workbook.Application.DisplayAlerts = false;

                if (workbook.Application.WindowState == Excel.XlWindowState.xlMinimized)
                {
                    workbook.Application.WindowState = Excel.XlWindowState.xlNormal; // if minimized, restore or it crashes on .Delete() below
                }
                _ws = HelperUI.GetSheet(revSheet, false);
                if (_ws != null) _ws.Delete();

                workbook.Application.DisplayAlerts = true;
            }
            contJectRevenue_table = null;
            RevBatchId = 0;
            Globals.ThisWorkbook.isRevDirty = null;

            btnCancelRevBatch.Enabled = false;
            btnCancelRevBatch.Text = "Cancel Rev Batch: ";
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
    }
}
