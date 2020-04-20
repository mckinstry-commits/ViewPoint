using System;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using System.Data;
using System.Runtime.InteropServices;
using McK.Data.Viewpoint;
using System.Linq;
using McK.Models.Viewpoint;
using Mck.Data.Viewpoint;

namespace McK.GMA.Viewpoint
{
    /*****************************************************************************************************************;
                                                                                                                   
                                             McKinstry GMA (Gross Margin Analysis)                                 
                                                                                                                    
                                                copyright McKinstry 2017                                                
                                                                                                                   
        This Microsoft Excel VSTO solution was developed by McKinstry in 2017 in order to faciliate Gross          
        margin analysis within Vista by Viewpoint.  This software is the property of McKinstry and               
        requires express written permission to be used by any Non-McKinstry employee or entity                     
                                                                                                                    
        Release                      Date                     Details                                              
        -------                      ----                     -------                                             
        1.0 Initial Dev      1/06/2017                Prototype Dev:      Leo Gurdian                      
                                                              Viewpoint/SQL Dev:  Jonathan Ziebell                 
                                                              Project Manager:    Genevieve Guinn                
                                                              Excel VSTO Dev:     Leo Gurdian                      
                                                                                                                 
       1.0.0.1               4/21/2017                - updated formulas, template clones
                                                              no GMA jobs displayed in fading text on Panel
                                                              GetJobGMATable now dynamically get fields/data into data structure (don't need field positions)
       1.0.0.2               5/26/2017                - added: staff, union, shop burden rates
                                                              - formatting per "GMA notes GG_12MAY.xls" - Gen
                                                              - cond. format blue on changed cells
                                                              - formula for Projected Markup fixed to Min Rev - Cost / Cost
                                                              - Formula for Projected Gross Margin to Markup / Markup + 1
       1.0.0.3               6/7/2017                  - Added SmallTools_CST
                                                              - Updated D47 formula, removed TOTALCOST, renamed ProjCost to ProjFinalCost
       1.0.0.4               6/8/2017                  - Updated Sum sheet's total PROJECTED MCK MARKUP and PROJECTED MCK GROSS MARGIN's formula to ref ProjFinalCost
                                                              - Fixed when only 1 project is pulled, total PROJECTED MCK MARKUP's formula correctly references the total column
       1.0.0.5               6/16/2017                 - # 514 - Formatted E35:E49 as %
                                                       - # 515 - D58 Formual =  " PROJECTED BILLING BASED ON COST"
                                                       - # 516 - If GMAX = no, B60 Formula = (PROJECTED FIINAL CONTRACT - PROJECTED FINAL COST)/PROJECTEDFINAL COST
                                                       - # 517 - Summary: A19 formula = "PROJECTED BILLING BASED ON COST"
                                                       - # 518 - Summary: unhide Rows 22 and 23
                                                       - # 519 - Summary: A22 formual = "PROJECTED FINAL COST (PRG)
                                                       - # 520 - Summary: A23 formula "PROJECTED FINAL BILLING"
                                                       - # 521 - Summary: Individual columns; If GMAX = yes, row 23 = smaller number of Row 19 and Row 21, else row 23 = row 21.
                                                       - # 522 - Summary: Add a GMAX row at top to display "YES or NO"
     1.0.0.6                6/21/2017                  - # 480 - Added ability to create a "Blank GMA" for new Contract/Projects
     1.0.1.0                6/21/2017                          - removed "Create Blank GMA" button; use btnGMA instead
                                                               - removed second contract input textbox, use txtContract instead
                                                               - Added "new/blank GMA" check box to toggle "Load GMA data" and "Create Blank GMA"
     1.1.0.0                6/22/2017                   # 524 - FIX: Exclamation alerts on "new/blank contract": (2 scenarios)
                                                                      1) Load a GMA contract, check "new/blank contract", enter a "new/blank contract" then tab over
                                                                      2) Load a GMA contract, enter a "new/blank contract", check "new/blank contract"
                                                         # 523 - FIX: Controls' tab order is wrong
                                                         # 525 - "Value of -1 is not a valid index" after tab over from valid contract
                                                                      1) Load valid GMA contract 2) Enter a "new/blank" contract 3) Tab over 4) Enter a valid GMA contract 5) Tab over
                                                         ----  - Added "Contract Name"

    1.1.1.0                 6/28/2017                    # 526 - Blank GM – add formula to Cell B28 = B26+B27
                                                         # 527 - Contract GM – format cells C31:C33 as Number w/ comma (1000 separator)
    1.1.1.0                 6/30/2017                    #     - Remove all "Prophecy" label references from "Blank GMA"
    1.1.1.2                 7/11/2017                    #     - format Cell 25 to number w/ comma separator
                                                               - enter key on Contract Name and # Projects (up/down) boxes invokes create new/blank GMA 
    1.1.1.3                 9/14/2017                          - remembers last 'offline save to' path      
                                                         # 536 - Allow comment insertions while still keeping tool protected    
    1.1.1.4                 10/1/2017                    # 544 - Chng cell D49 formula to C49-b49 
                            10/12/2017                   # 545 - Deploy GMA Tool to Staging
    1.1.2.0                 11/10/2017         Axosoft  101225 • Added logging 
    *******************************************************************************************************************/

    partial class ActionsPaneGMA : UserControl
    {
        internal const string gmaSheet = "MCK Gross Margin";

        internal const string pwd = "gmax";
        public byte JCCo { get; set; }
        public string Contract { get; set; }
        public string Job { get; set; }
        public string Login { get; set; }

        public Contracts contractList = new Contracts();

        // used to extract projectName and descriptions
        Dictionary<string, string> contractJobsList = null;

        public static Excel.Workbook workbook => Globals.ThisWorkbook.Worksheets.Parent;

        private string lastContractNoDash = null;
        private const string allprojects = "All Projects";
        private string prevContract = "";
        private bool sumSheetCreated = false;
        private string lastDirectory = "";

        public ActionsPaneGMA()
        {
            InitializeComponent();
            try
            {
                HelperData.AppName = this.ProductName;

                if (this.ProductName.Contains("-Dev"))
                {
                    lblAppName.Text = "Dev";
                }
                else if (this.ProductName.Contains("-Stg"))
                {
                    lblAppName.Text = "Staging";
                }
                else if (this.ProductName.Contains("-Trng"))
                {
                    lblAppName.Text = "Training";
                }
                else
                {
                    lblAppName.Text = "Prod.";
                }

                // Get contract list and setup autocomplete feature
                this.txtViewpointContract.AutoCompleteSource = AutoCompleteSource.CustomSource;
                this.txtViewpointContract.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                AutoCompleteStringCollection collection = new AutoCompleteStringCollection();

                string[] list = FetchContractList();
                collection.AddRange(list);

                txtViewpointContract.AutoCompleteCustomSource = collection;
                txtViewpointContract.Enabled = true;
                //txtBoxContract.Text = "104150-"; /// test 
                lblVersion.Text = "v" + this.ProductVersion;

                HelperData.VSTO_Version = this.ProductVersion;
                HelperData.VPuser = Profile.GetVP_UserName();

            }
            catch (Exception ex) {

                if (ex.Data.Count == 0) ex.Data.Add(0, "ActionsPaneGMA");
                ShowErr(ex);
            }
        }

        #region LOAD GMA / CREATE NEW/BLANK GMA

        private void btnGMA_Click(object sender, EventArgs e)
        {
            if (btnGMA.Text == "Get GMA Data")
            {
                #region validate fields
                if (!Set_JCCo_Contract_Jobs())
                {
                    errorProvider1.SetIconAlignment(txtViewpointContract, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtViewpointContract, "Select a Contract");
                    btnGMA.Enabled = true;
                    return;
                }

                if (!txtViewpointContract.Text.Contains("-")) txtViewpointContract.Text += "-";

                if (txtViewpointContract.Text != Contract) cboJobs.Text = "All Projects";
                #endregion

                GMALog.LogAction(GMALog.Action.REPORT, JCCo, txtViewpointContract.Text, cboJobs.SelectedItem.ToString());

                btnGMA.Tag = btnGMA.Text;
                btnGMA.Text = "Processing...";
                btnGMA.Refresh();
                btnGMA.Enabled = false;
                Excel.Worksheet gma = null;

                try
                {
                    // refresh contract job list projectName and descriptions
                    if (contractJobsList == null)
                    {
                        contractJobsList = ContractJobs.GetContractJobTable(JCCo, Contract, null);
                    }
                    else if (cboJobs.Items.Count > 0)
                    {
                        if (!contractJobsList.ContainsKey(cboJobs.Items[1].ToString()))
                        {
                            contractJobsList = ContractJobs.GetContractJobTable(JCCo, Contract, null);
                        }
                    }

                    RenderOFF();
                    Globals.GMA.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                    Globals.GMABLANK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                    Globals.ThisWorkbook.Application.DisplayAlerts = false;
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name != "Summary" && ws.Name != Globals.GMA.Name && ws.Name != Globals.GMABLANK.Name) ws.Delete();
                    }
                    Globals.ThisWorkbook.Application.DisplayAlerts = true;

                    LoadGMA(gma);
                    tmrUpdateButtonText.Enabled = true;
                }
                catch (Exception ex)
                {
                    GMALog.LogAction(GMALog.Action.ERROR, JCCo, txtViewpointContract.Text, cboJobs.SelectedItem.ToString(), GetActiveSheet_Version(), ex.Message);

                    if (ex.Data.Count == 0) ex.Data.Add(0, "btnGMA_Click");
                    ShowErr(ex);
                }
                finally
                {
                    RenderON();
                    btnGMA.Text = btnGMA.Tag.ToString();
                    btnGMA.Refresh();
                    btnGMA.Enabled = true;
                    Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    if (sumSheetCreated) Globals.GMA.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    if (gma != null) Marshal.ReleaseComObject(gma); gma = null;
                    sumSheetCreated = false;
                }
            }
            else if (btnGMA.Text == "Create Blank GMA")
            {
                GMALog.LogAction(GMALog.Action.NEW_CONTRACT, JCCo, null, updownJobCnt.Value.ToString(), txtNewContractName.Text);

                Contract = txtViewpointContract.Text == "" ? "Contract-" : txtViewpointContract.Text;
                btnGMA.Tag = btnGMA.Text;
                btnGMA.Text = "Processing...";
                btnGMA.Refresh();
                btnGMA.Enabled = false;
                Excel.Worksheet gma = null;
                RenderOFF();

                try
                {
                    Globals.GMABLANK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                    Globals.GMA.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                    Globals.ThisWorkbook.Application.DisplayAlerts = false;
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name != Globals.Summary.Name && ws.Name != Globals.GMA.Name && ws.Name != Globals.GMABLANK.Name) ws.Delete();
                    }
                    Globals.ThisWorkbook.Application.DisplayAlerts = true;

                    LoadBlankGMA(gma);
                }
                catch (Exception ex)
                {
                    GMALog.LogAction(GMALog.Action.NEW_CONTRACT, JCCo, null, updownJobCnt.Value.ToString(), GetActiveSheet_Version() + ": " + txtNewContractName.Text , ex.Message);
                    if (ex.Data.Count == 0) ex.Data.Add(0, "btnBlankGMA_Click");

                    ShowErr(ex);
                }
                finally
                {
                    RenderON();
                    btnGMA.Text = btnGMA.Tag.ToString();
                    btnGMA.Refresh();
                    btnGMA.Enabled = true;
                    Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    if (sumSheetCreated) Globals.GMABLANK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                    if (gma != null) Marshal.ReleaseComObject(gma); gma = null;
                    sumSheetCreated = false;
                }
            }
        }
        private string GetJobList()
        {
            Excel.Worksheet gma = null;
            StringBuilder jobs = new StringBuilder("S");
            
            try
            {
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws.Name != Globals.GMA.Name && 
                        ws.Name != Globals.GMABLANK.Name &&
                        !ws.Name.Contains("Summary")
                       )
                    {
                        int i = ws.Name.IndexOf("-");
                        if (i != -1)
                        {
                            string job = ws.Name.Substring(i + 1, 3);
                            if (Int32.TryParse(job, out i))
                            {
                                jobs.Append(","+i);
                            }
                        }
                    }
                }

                return jobs.ToString();
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (gma != null) Marshal.ReleaseComObject(gma); gma = null;
            }
        }

        /// <summary>
        /// Populate Project(s) w / GMA data from Viewpoint
        /// </summary>
        /// <param name=gmaSheet></param>
        /// <remarks>_factoryMode means building multiple tabs</remarks>
        private void LoadGMA(Excel.Worksheet gma)
        {
            Excel.Worksheet wsSum = null;
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            StringBuilder jobs_no_data = null;
            uint sumCol = 2;

            try
            {
                //wsSum = Globals.ThisWorkbook.Sheets[sumSheet];
                uint jobs_with_GMA = 0;
                int job_start;
                int jobsCnt;

                if (Job == allprojects)
                {
                    job_start = 1;
                    jobsCnt = cboJobs.Items.Count - 1;
                }
                else
                {
                    job_start = jobsCnt = cboJobs.SelectedIndex;
                }

                for (int i = job_start; i <= jobsCnt; i++)
                {
                    string _job = cboJobs.Items[i].ToString();
                    List<dynamic> table = JobGMA.GetJobGMATable(JCCo, _job);

                    if (table.Count > 0)
                    {
                        ++jobs_with_GMA;
                        string tabName = "GMA-" + HelperUI.JobTrimDash(_job);

                        if (!sumSheetCreated)
                        {
                            Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.Summary.Copy(after: Globals.ThisWorkbook.Sheets[1]);
                            wsSum = Globals.ThisWorkbook.Sheets[2];
                            wsSum.Name = Contract + "Summary";
                            Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                            sumSheetCreated = true;
                        }

                        Globals.GMA.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        gma = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count-1];
                        gma.get_Range("A3").Select();
                        gma.Name = tabName;

                        var projectName = contractJobsList.Where(x => x.Key == _job).FirstOrDefault().Value;
                        gma.get_Range("A1").Formula = "GROSS MARGIN ANALYSIS: " + _job + " " + projectName;

                        var job = table.Where(row => row.Job == _job).FirstOrDefault();

                        #region Set Cell Values

                        gma.Names.Item("ActualStaffBurden").RefersToRange.Value = job.ActualStaffBurden;
                        gma.Names.Item("ContractActualFieldBurden").RefersToRange.Value = job.ContractActualFieldBurden;
                        gma.Names.Item("ContractShopBurden").RefersToRange.Value = job.ContractShopBurden;
                        gma.Names.Item("BaseFee").RefersToRange.Value = job.BaseFee;
                        gma.Names.Item("BandO").RefersToRange.Value = job.BandO;
                        gma.Names.Item("GLI").RefersToRange.Value = job.GLI;
                        gma.Names.Item("SmallTools").RefersToRange.Value = job.SmallTools;
                        gma.Names.Item("Warranty").RefersToRange.Value = job.Warranty;
                        gma.Names.Item("Bond").RefersToRange.Value = job.Bond;

                        gma.Names.Item("Assumptions").RefersToRange.Value = job.Assumptions;

                        gma.Names.Item("TB_Staff").RefersToRange.Value = job.TB_Staff;
                        gma.Names.Item("TB_Field").RefersToRange.Value = job.TB_Field;
                        gma.Names.Item("TB_Shop").RefersToRange.Value = job.TB_Shop;
                        gma.Names.Item("UF_Field").RefersToRange.Value = job.UF_Field;
                        gma.Names.Item("UF_Shop").RefersToRange.Value = job.UF_Shop;

                        gma.Names.Item("ProjHours").RefersToRange.Value = job.ProjHours;
                        gma.Names.Item("ProjLabrCost").RefersToRange.Value = job.ProjLabrCost;
                        gma.Names.Item("ProjNonLCost").RefersToRange.Value = job.ProjNonLCost;
                        gma.Names.Item("ProjFinalCost").RefersToRange.Value = job.ProjCost;

                        gma.Names.Item("Staff_HRS").RefersToRange.Value = job.Staff_HRS;
                        gma.Names.Item("Field_HRS").RefersToRange.Value = job.Field_HRS;
                        gma.Names.Item("Shop_HRS").RefersToRange.Value = job.Shop_HRS;
                        gma.Names.Item("Staff_HRS_1").RefersToRange.Value = job.Staff_HRS;
                        gma.Names.Item("Field_HRS_1").RefersToRange.Value = job.Field_HRS;
                        gma.Names.Item("Shop_HRS_1").RefersToRange.Value  = job.Shop_HRS;

                        gma.Names.Item("Staff_Labor_Rate").RefersToRange.Value = job.StaffLabor;
                        gma.Names.Item("Union_Labor_Rate").RefersToRange.Value = job.UnionLabor;
                        gma.Names.Item("Shop_Labor_Rate").RefersToRange.Value = job.ShopLabor;

                        gma.Names.Item("EquipCost").RefersToRange.Value = job.EquipCost;
                        gma.Names.Item("SmallTools_CST").RefersToRange.Value = job.SmallTools_CST;

                        gma.Names.Item("BondAmt").RefersToRange.Value = job.Bond_CST;
                        gma.Names.Item("JECTED_FINAL_CONTRACT_PRG").RefersToRange.Value = job.ProjRev;

                        #endregion

                        #region On editable cell change highlight blue
                        SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Field").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Staff").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Shop").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("Staff_HRS").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("Field_HRS").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("Shop_HRS").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("BondAmt").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("JECTED_FINAL_CONTRACT_PRG").RefersToRange);
                        SetConditionalFormatBlueOnChange(gma.Names.Item("Assumptions").RefersToRange, true);

                        SetConditionalFormatBlueOnChange(gma.get_Range("C19"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("D19"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("D39"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("B41"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("C41"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("B42"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("C43"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("D44"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("B47"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("B49"));
                        SetConditionalFormatBlueOnChange(gma.get_Range("C49"));
                        #endregion

                        if (job.GMAX == "Y")
                        {
                            ((Excel.OptionButton)gma.OptionButtons("gmaxYes")).Value = true;
                        }
                        else
                        {
                            ((Excel.OptionButton)gma.OptionButtons("gmaxNo")).Value = true;
                        }

                        #region SUMMARY SHEET
                        // update Summary sheet
                        rng = wsSum.Cells[4, sumCol];
                        rng.Value = _job;
                        rng.Font.Bold = true;

                        // GMAX
                        wsSum.Cells[6, sumCol].Formula = "=IF('" + tabName + @"'!B9 = 1, ""YES"", ""NO"")";

                        // HOURS
                        wsSum.Cells[8, sumCol].Formula = "='" + tabName + "'!B31";
                        wsSum.Cells[9, sumCol].Formula = "='" + tabName + "'!B32";
                        wsSum.Cells[10, sumCol].Formula = "='" + tabName + "'!B33";

                        //TOTALS
                        wsSum.Cells[12, sumCol].Formula = "='" + tabName + "'!C51";
                        wsSum.Cells[13, sumCol].Formula = "='" + tabName + "'!C52";
                        wsSum.Cells[14, sumCol].Formula = "='" + tabName + "'!C53";
                        wsSum.Cells[15, sumCol].Formula = "='" + tabName + "'!C54";
                        wsSum.Cells[16, sumCol].Formula = "='" + tabName + "'!C55";
                        wsSum.Cells[17, sumCol].Formula = "='" + tabName + "'!C56";
                        wsSum.Cells[18, sumCol].Formula = "='" + tabName + "'!C57";
                        wsSum.Cells[19, sumCol].Formula = "='" + tabName + "'!C58";

                        wsSum.Cells[21, sumCol].Formula = "='" + tabName + "'!B59";
                        wsSum.Cells[22, sumCol].Formula = "='" + tabName + "'!ProjFinalCost";

                        // PROJECTED FINAL BILLING
                        wsSum.Cells[23, sumCol].Formula = "=IF(" + wsSum.Cells[6, sumCol].Address + @"=""YES""," +
                                                          "MIN(" + wsSum.Cells[21, sumCol].Address + "," + wsSum.Cells[19, sumCol].Address + ")" + // GMAX = YES
                                                            "," + wsSum.Cells[21, sumCol].Address + ")";                                             // GMAX = NO

                        wsSum.Cells[24, sumCol].Formula = "='" + tabName + "'!B60"; // PROJECTED MCK MARK UP
                        wsSum.Cells[25, sumCol].Formula = "='" + tabName + "'!B61"; // PROJECTED MCK GROSS MARGIN

                        // PROJECTED FINAL BILLING
                        rng  = wsSum.Cells[19, sumCol];
                        rng2 = wsSum.Cells[21, sumCol];
                        Excel.FormatCondition jectedFinalBill_GreaterThan_jectedFinalContract = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                                                "=" + rng.Address + ">" + rng2.Address,
                                                                                                Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        jectedFinalBill_GreaterThan_jectedFinalContract.Font.Color = 192;
                        jectedFinalBill_GreaterThan_jectedFinalContract.Font.Bold = true;

                        rng = wsSum.Cells[19, sumCol];
                        rng2 = wsSum.Cells[21, sumCol];
                        Excel.FormatCondition jectedFinalBill_GreaterThan_jectedFinalContract1 = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                                                "=" + rng.Address + "<" + rng2.Address,
                                                                                                Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                        jectedFinalBill_GreaterThan_jectedFinalContract1.Font.ThemeColor = Excel.XlThemeColor.xlThemeColorAccent6;
                        jectedFinalBill_GreaterThan_jectedFinalContract1.Font.TintAndShade = -0.249977111m;
                        jectedFinalBill_GreaterThan_jectedFinalContract1.Font.Bold = true;

                        ++sumCol;
                        #endregion

                        HelperUI.ProtectSheet(gma, false, false);
                        //LogProphecyAction.InsProphecyLog(Login, 18, _jcco, Contract, Job, null, CostBatchId);
                    }
                    else
                    {
                        string msg = "No GMA available\nfor:";
                        jobs_no_data = jobs_no_data ?? new StringBuilder(msg + "\n" + new string('-', msg.Length - 10) + "\n");
                        jobs_no_data.AppendLine(_job);
                    }
                }

                if (wsSum != null)
                {
                    UpdateSummary(wsSum, rng, rng2, jobs_with_GMA);
                    btnCopyGMAoffline.Enabled = true;
                }
                else
                {
                    btnCopyGMAoffline.Enabled = false;
                }

                btnGMA.Text = "Done!";

                if (jobs_no_data != null)
                {
                    if (Globals.ThisWorkbook.Sheets.Count == 2)
                    {
                        //Globals.GMA.Cells.Select();
                        Globals.GMA.Cells.get_Range("1:62,A3:E3").Select();
                        Globals.GMA.Cells.get_Range("A3").Activate();
                    }
                    lblListNoGMAs.ForeColor = System.Drawing.Color.Black;
                    lblListNoGMAs.Visible = true;
                    tmrFadeLabel.Start();
                    lblListNoGMAs.Text = jobs_no_data.ToString();
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "LoadGMA");
                throw ex;
            }
            finally
            {
                if (wsSum != null) Marshal.ReleaseComObject(wsSum); wsSum = null;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                
            }
        }

        /// <summary>
        /// Create a blank GMA worksheet for estimates
        /// </summary>
        /// <param name="gma"></param>
        private void LoadBlankGMA(Excel.Worksheet gma)
        {
            Excel.Worksheet wsSum = null;
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            uint sumCol = 2;

            try
            {
                int job_start = 1;
                int jobsCnt = Convert.ToInt32(this.updownJobCnt.Value);

                for (int i = job_start; i <= jobsCnt; i++)
                {
                    string tabName = "GMA-00" + i;

                    if (!sumSheetCreated)
                    {
                        Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.Summary.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                        wsSum = Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count];

                        wsSum.Name = txtNewContractName.Text.Substring(0, txtNewContractName.Text.Length > 23 ? 23 : txtNewContractName.Text.Length) + "-Summary"; // tab limit = 31 chars
                        Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                        sumSheetCreated = true;
                    }

                    Globals.GMABLANK.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                    gma = Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count];
                    gma.Activate();
                    gma.get_Range("A3").Select();
                    gma.Name = tabName;
                    ((Excel.OptionButton)gma.OptionButtons("gmaxNo")).Value = true;

                    #region Changed cells highlight blue
                    gma.get_Range("A1:G1").Merge();
                    SetConditionalFormatBlueOnChange(gma.get_Range("A1"), true);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ActualStaffBurden").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ContractActualFieldBurden").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ContractShopBurden").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("BaseFee").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("BandO").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("GLI").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("SmallTools").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Warranty").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Bond").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.get_Range("B9"));

                    SetConditionalFormatBlueOnChange(gma.Names.Item("ProjHours").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ProjLabrCost").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ProjNonLCost").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("ProjFinalCost").RefersToRange);

                    SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Field").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Staff").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("TB_Shop").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Staff_HRS").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Field_HRS").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Shop_HRS").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("BondAmt").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("JECTED_FINAL_CONTRACT_PRG").RefersToRange);
                    SetConditionalFormatBlueOnChange(gma.Names.Item("Assumptions").RefersToRange, true);

                    SetConditionalFormatBlueOnChange(gma.get_Range("C19"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("D19"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("D39"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("B41"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("C41"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("B42"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("C43"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("D44"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("B47"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("B49"));
                    SetConditionalFormatBlueOnChange(gma.get_Range("C49"));
                    #endregion

                    #region SUMMARY SHEET
                    // update Summary sheet
                    rng = wsSum.Cells[4, sumCol];
                    rng.Value = tabName;
                    rng.Font.Bold = true;

                    // GMAX
                    wsSum.Cells[6, sumCol].Formula = "=IF('" + tabName + @"'!B9 = 1, ""YES"", ""NO"")";

                    // HOURS
                    wsSum.Cells[8, sumCol].Formula = "='" + tabName + "'!Staff_HRS";
                    wsSum.Cells[9, sumCol].Formula = "='" + tabName + "'!Field_HRS";
                    wsSum.Cells[10, sumCol].Formula = "='" + tabName + "'!Shop_HRS";

                    //TOTALS
                    wsSum.Cells[12, sumCol].Formula = "='" + tabName + "'!C51";
                    wsSum.Cells[13, sumCol].Formula = "='" + tabName + "'!C52";
                    wsSum.Cells[14, sumCol].Formula = "='" + tabName + "'!C53";
                    wsSum.Cells[15, sumCol].Formula = "='" + tabName + "'!C54";
                    wsSum.Cells[16, sumCol].Formula = "='" + tabName + "'!C55";
                    wsSum.Cells[17, sumCol].Formula = "='" + tabName + "'!C56";
                    wsSum.Cells[18, sumCol].Formula = "='" + tabName + "'!C57";
                    wsSum.Cells[19, sumCol].Formula = "='" + tabName + "'!C58";

                    wsSum.Cells[21, sumCol].Formula = "='" + tabName + "'!B59";
                    wsSum.Cells[22, sumCol].Formula = "='" + tabName + "'!ProjFinalCost";

                    // PROJECTED FINAL BILLING
                    wsSum.Cells[23, sumCol].Formula = "=IF(" + wsSum.Cells[6, sumCol].Address + @"=""YES""," +
                                                        "MIN(" + wsSum.Cells[21, sumCol].Address + "," + wsSum.Cells[19, sumCol].Address + ")" + // GMAX = YES
                                                        "," + wsSum.Cells[21, sumCol].Address + ")";                                             // GMAX = NO

                    wsSum.Cells[24, sumCol].Formula = "='" + tabName + "'!B60"; // PROJECTED MCK MARK UP
                    wsSum.Cells[25, sumCol].Formula = "='" + tabName + "'!B61"; // PROJECTED MCK GROSS MARGIN

                    // PROJECTED FINAL BILLING
                    rng = wsSum.Cells[19, sumCol];
                    rng2 = wsSum.Cells[21, sumCol];
                    Excel.FormatCondition jectedFinalBill_GreaterThan_jectedFinalContract = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                                            "=" + rng.Address + ">" + rng2.Address,
                                                                                            Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    jectedFinalBill_GreaterThan_jectedFinalContract.Font.Color = 192;
                    jectedFinalBill_GreaterThan_jectedFinalContract.Font.Bold = true;

                    rng = wsSum.Cells[19, sumCol];
                    rng2 = wsSum.Cells[21, sumCol];
                    Excel.FormatCondition jectedFinalBill_GreaterThan_jectedFinalContract1 = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                                            "=" + rng.Address + "<" + rng2.Address,
                                                                                            Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    jectedFinalBill_GreaterThan_jectedFinalContract1.Font.ThemeColor = Excel.XlThemeColor.xlThemeColorAccent6;
                    jectedFinalBill_GreaterThan_jectedFinalContract1.Font.TintAndShade = -0.249977111m;
                    jectedFinalBill_GreaterThan_jectedFinalContract1.Font.Bold = true;

                    ++sumCol;
                    #endregion

                    HelperUI.ProtectSheet(gma, false, false);
                }

                if (wsSum != null)
                {
                    UpdateSummary(wsSum, rng, rng2, Convert.ToUInt32(jobsCnt));
                    btnCopyGMAoffline.Enabled = true;
                }
                else
                {
                    btnCopyGMAoffline.Enabled = false;
                }

                btnGMA.Text = "Done!";
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "LoadBlankGMA");
                throw ex;
            }
            finally
            {
                if (wsSum != null) Marshal.ReleaseComObject(wsSum); wsSum = null;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;

            }
        }

        #endregion


        #region EXCEL SHEET UPDATE

        private void SetConditionalFormatBlueOnChange(Excel.Range cell, bool asText = false)
        {
            var origValue = !asText ? cell.Value ?? 0 : "\"" + cell.Formula + "\"";
            // Rate blue highlight when there's a variance
            Excel.FormatCondition onChanged = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlCellValue,
                                  Excel.XlFormatConditionOperator.xlNotEqual, "=" + origValue, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
            onChanged.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
            onChanged.Font.Bold = true;
        }
        private void UpdateSummary(Excel.Worksheet wsSum, Excel.Range rng, Excel.Range rng2, uint jobs_with_GMA)
        {
            try
            {
                wsSum.Activate();

                // SUMMARY TITLE HEADER
                if (!ckbNewBlankContract.Checked)
                {
                    wsSum.get_Range("A1").Formula = "GROSS MARGIN ANALYSIS SUMMARY: " + Contract + " " + JobGetTitle.GetTitle(JCCo, Contract).Replace(" - " + Contract, "");
                }
                else
                {
                    wsSum.get_Range("A1").Formula = "GROSS MARGIN ANALYSIS SUMMARY: " + txtNewContractName.Text; // BLANK GMA
                }

                // SET JOB HEADER
                uint totalCol = jobs_with_GMA + 2;
                rng = wsSum.Cells[4, totalCol];
                rng.Value = Contract;
                rng.Font.Bold = true;

                // FORMAT LABOR HOURS
                rng  = wsSum.get_Range("B8");
                rng2 = wsSum.Cells[10, totalCol - 1];
                FormatCellsGray(wsSum, rng, rng2);

                rng  = wsSum.Cells[8, totalCol];
                rng2 = wsSum.Cells[10, totalCol];
                FormatCellsBlueWhite(wsSum, rng, rng2);
                wsSum.get_Range("B8", rng2).NumberFormat        = HelperUI.NumberFormat;
                wsSum.get_Range("B8", rng2).HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                // ADD TOTALS SUM
                for (int row = 8; row <= 10; row++)
                {
                    wsSum.Cells[row, totalCol].Formula = "=SUM(" + wsSum.Cells[row, 2].Address + ":" + wsSum.Cells[row, jobs_with_GMA + 1].Address + ")";
                }

                // FORMAT TOTALS
                rng  = wsSum.get_Range("B12");
                rng2 = wsSum.Cells[19, totalCol - 1];
                FormatCellsGray(wsSum, rng, rng2);

                rng  = wsSum.Cells[12, totalCol];
                rng2 = wsSum.Cells[19, totalCol];
                FormatCellsBlueWhite(wsSum, rng, rng2);

                wsSum.get_Range("B12", rng2).Style = HelperUI.CurrencyStyle;

                // FORMAT PROJECTED FINAL CONTRACT (PRG)
                rng = wsSum.get_Range("B21");
                rng2 = wsSum.Cells[25, totalCol - 1];
                FormatCellsGray(wsSum, rng, rng2);

                rng  = wsSum.Cells[21, totalCol];
                rng2 = wsSum.Cells[25, totalCol];
                FormatCellsBlueWhite(wsSum, rng, rng2);

                rng2 = wsSum.Cells[23, totalCol];
                wsSum.get_Range("B21", rng2).Style = HelperUI.CurrencyStyle;

                // ADD TOTALS SUM
                for (int row = 12; row <= 19; row++)
                {
                    wsSum.Cells[row, totalCol].Formula = "=SUM(" + wsSum.Cells[row, 2].Address + ":" + wsSum.Cells[row, jobs_with_GMA + 1].Address + ")";
                }

                // FORMAT last two % rows
                rng2 = wsSum.Cells[25, totalCol];
                wsSum.get_Range("B24", rng2).NumberFormat = HelperUI.PercentFormat;
                wsSum.get_Range("B24", rng2).HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                // ADD TOTALS SUM
                for (int row = 21; row <= 23; row++)
                {
                    wsSum.Cells[row, totalCol].Formula = "=SUM(" + wsSum.Cells[row, 2].Address + ":" + wsSum.Cells[row, jobs_with_GMA + 1].Address + ")";
                }

                // PROJECTED MCK MARK UP
                wsSum.Cells[24, totalCol].Formula = "=(" + wsSum.Cells[23, totalCol].Address + "-" + wsSum.Cells[22, totalCol].Address + ")/" + wsSum.Cells[22, totalCol].Address;

                // PROJECTED MCK GROSS MARGIN
                wsSum.Cells[25, totalCol].Formula = "=" + wsSum.Cells[24, totalCol].Address + "/ (" + wsSum.Cells[24, totalCol].Address + "+ 1)";

                // PROJECTED FINAL BILLING
                rng = wsSum.Cells[19, totalCol];
                rng2 = wsSum.Cells[21, totalCol];
                Excel.FormatCondition jectedFinalBilling_GreaterThan_jectedFinalContract = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                                                            "=" + rng.Address + ">" + rng2.Address,
                                                                                            Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                jectedFinalBilling_GreaterThan_jectedFinalContract.Interior.Color = 192;
                jectedFinalBilling_GreaterThan_jectedFinalContract.Font.Color = HelperUI.WhiteFontColor;
                jectedFinalBilling_GreaterThan_jectedFinalContract.Font.Bold = true;

                //wsSum.get_Range("A20:A21").EntireRow.Hidden = true;
                wsSum.Activate();
                wsSum.UsedRange.Locked = true;
                if (ckbNewBlankContract.Checked)
                {
                    wsSum.get_Range("A1:K1").Merge();
                    SetConditionalFormatBlueOnChange(wsSum.get_Range("A1"), true);
                    wsSum.get_Range("A1:K1").Locked = false;
                    wsSum.get_Range("A1:K1").Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorAccent6;
                    wsSum.get_Range("A1:K1").Interior.TintAndShade = 0.799981688894314f;
                }
                wsSum.get_Range("A1").Activate();
                HelperUI.ProtectSheet(wsSum, true, false);
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "UpdateSummary");
                throw ex;
            }
        }
        private static Excel.Range FormatCellsBlueWhite(Excel.Worksheet wsSum, Excel.Range rng, Excel.Range rng2)
        {
            rng = wsSum.get_Range(rng, rng2);
            rng.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
            rng.Font.Color = HelperUI.WhiteFontColor;
            rng.Font.Bold = true;
            rng.Cells.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            rng.Cells.Borders.Weight = Excel.XlBorderWeight.xlThin;
            rng.Cells.Borders.Color = HelperUI.GrayBreakDownHeaderRowColor;
            rng.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
            rng.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.GrayBreakDownHeaderRowColor;
            rng.Font.Size = 10;
            return rng;
        }
        private static Excel.Range FormatCellsGray(Excel.Worksheet wsSum, Excel.Range rng, Excel.Range rng2)
        {
            rng = wsSum.get_Range(rng, rng2);
            rng.Interior.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
            rng.Interior.TintAndShade = -4.99893185216834E-02;
            rng.Cells.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            rng.Cells.Borders.Weight = Excel.XlBorderWeight.xlThin;
            rng.Cells.Borders.Color = HelperUI.WhiteFontColor;
            rng.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
            rng.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.WhiteFontColor;
            rng.Font.Size = 10;
            return rng;
        }

        #endregion


        #region PANEL'S CONTROL RESPONSE

        public string[] FetchContractList()
        {
            contractList = ContractList.GetContractList(JCCo, Contract);

            return contractList
                  .Select(x => x.TrimContractId)
                  .ToArray();
        }

        private bool Set_JCCo_Contract_Jobs()
        {
            if (txtViewpointContract.Text == "" || ckbNewBlankContract.Checked) return false;

            errorProvider1.Clear();

            if (!txtViewpointContract.Text.Contains("-")) txtViewpointContract.Text += "-"; // auto-correct contract

            // Get corresponding company for selected contract
            Contract c = contractList.Where(x => x.TrimContractId == txtViewpointContract.Text)?.FirstOrDefault();

            if (c == null)
            {
                cboJobs.DataSource = null;
                cboJobs.SelectedItem = "";
                errorProvider1.SetError(txtViewpointContract, "Select a Contract");
                return false;
            }

            prevContract = txtViewpointContract.Text;

            JCCo = c.JCCo;
            Contract = c.ContractId;

            cboJobs.DataSource = null;
            cboJobs.Items.Clear();
            cboJobs.Items.Add("All Projects");

            cboJobs.DataSource = c.Projects;
            cboJobs.SelectedItem = allprojects;
            cboJobs.SelectedIndex = 0;
            
            return true;
        }

        private void txtBoxContract_Leave(object sender, EventArgs e) => Set_JCCo_Contract_Jobs();

        // Enter key on contract box fetches data
        private void txtBoxContract_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                if (!txtViewpointContract.Text.Contains("-")) txtViewpointContract.Text += "-";

                e.Handled = true;
                Set_JCCo_Contract_Jobs();
                if (!cboJobs.Text.Contains(txtViewpointContract.Text)) cboJobs.Text = allprojects;
                this.btnGMA_Click(btnGMA, null);
            }
        }

        private void ckbBlankContract_CheckedChanged(object sender, EventArgs e)
        {
            if (ckbNewBlankContract.Checked)
            {
                errorProvider1.Clear();
                updownJobCnt.Enabled = true;
                txtNewContractName.Enabled = true;
                lblContractName.Enabled = true;
                lblJobsCnt.Enabled = true;
                txtViewpointContract.Enabled = false;
                cboJobs.Enabled = false;
                lblJobs.Enabled = false;
                btnGMA.Text = "Create Blank GMA";
            }
            else
            {
                updownJobCnt.Enabled = false;
                txtNewContractName.Enabled = false;
                lblContractName.Enabled = false;
                txtViewpointContract.Enabled = true;
                lblJobs.Enabled = true;
                cboJobs.Enabled = true;
                btnGMA.Text = "Get GMA Data";
            }
        }

        #region Highlight Contract number on focus

        private void txtContractNumber_MouseClick(object sender, MouseEventArgs e)
        {
            txtViewpointContract.SelectionStart = 0;
            txtViewpointContract.SelectionLength = txtViewpointContract.Text.Length;
        }

        private void txtContractNumber_Enter(object sender, EventArgs e) => txtContractNumber_MouseClick(sender, null); //emulate click

        #endregion

        // Enter key on button fetches data
        private void btnGMA_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                this.btnGMA_Click(sender, null);
            }
        }

        private void cboJobs_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;

                if (ckbNewBlankContract.Checked)
                {
                    if (lastContractNoDash != null)
                    {
                        if (!cboJobs.Text.Contains(lastContractNoDash) && cboJobs.SelectedIndex == 0) cboJobs.Text = allprojects;
                    }
                }
                this.btnGMA_Click(btnGMA, null);
            }
        }

        private void cboJobs_SelectedIndexChanged(object sender, EventArgs e) => Job = cboJobs.Text;

        // reset button's to orig text
        private void tmrUpdateButtonText_Tick(object sender, EventArgs e)
        {
            btnGMA.Text = btnGMA.Tag.ToString();
            tmrUpdateButtonText.Enabled = false;
        }

        #endregion

        // lessen CPU consumption / speed things up
        private static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        private static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;


        #region SAVE OFFFLINE

        private void btnCopyGMAoffline_Click(object sender, EventArgs e)
        {
            btnCopyGMAoffline.Tag = btnCopyGMAoffline.Text;
            btnCopyGMAoffline.Text = "Saving...";
            btnCopyGMAoffline.Refresh();
            btnCopyGMAoffline.Enabled = false;
            try
            {
                SaveOffline();
            }
            catch (Exception ex)
            {
                if (ckbNewBlankContract.Checked)
                {
                    GMALog.LogAction(GMALog.Action.ERROR, JCCo, null, updownJobCnt.Value.ToString(), GetActiveSheet_Version() + ": " + txtNewContractName.Text, ex.Message);
                }
                else
                {
                    GMALog.LogAction(GMALog.Action.ERROR, JCCo, txtViewpointContract.Text, GetJobList(), GetActiveSheet_Version(), ex.Message);
                }
                ShowErr(ex);
            }
            finally
            {
                btnCopyGMAoffline.Text = btnCopyGMAoffline.Tag.ToString();
                btnCopyGMAoffline.Refresh();
                btnCopyGMAoffline.Enabled = true;
            }
        }

        private bool SaveOffline()
        {
            try
            {
                DialogResult action;

                saveFileDialog1.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                saveFileDialog1.InitialDirectory = lastDirectory == "" ? Environment.GetFolderPath(Environment.SpecialFolder.Personal) : lastDirectory;
                saveFileDialog1.RestoreDirectory = false;

                string init_title = workbook.Sheets.Count > 1 ? "GMA-" + Contract : Globals.ThisWorkbook.Sheets[1].Name;
                saveFileDialog1.FileName = init_title + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);

                action = saveFileDialog1.ShowDialog();
                if (action == DialogResult.OK)
                {
                    if (ckbNewBlankContract.Checked)
                    {
                        GMALog.LogAction(GMALog.Action.COPY_OFFLINE, JCCo, null, GetJobList(), txtNewContractName.Text);
                    }
                    else
                    {
                        GMALog.LogAction(GMALog.Action.COPY_OFFLINE, JCCo, txtViewpointContract.Text, GetJobList());
                    }
                    // save the selected directory locally
                    lastDirectory = System.IO.Path.GetFullPath(saveFileDialog1.FileName);
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Worksheets) ws.Unprotect(ActionsPaneGMA.pwd);
                    Globals.ThisWorkbook.RemoveCustomization();
                    workbook.SaveAs(saveFileDialog1.FileName);
                    return false;
                }
                else if (action == DialogResult.Cancel)
                {
                    return true;
                }
            }
            catch (Exception) { throw; }
            return false;
        }

        public bool SavePrompt()
        {
            // there's at least 1 GMA
            DialogResult action;

            if (!workbook.Saved)
            {
                action = MessageBox.Show("Would you like to save a copy of the workbook for future reference?", "Save Workbook", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                if (action == DialogResult.Cancel) return true;
                if (action == DialogResult.No) workbook.Saved = true;
                if (action == DialogResult.Yes)
                {
                    workbook.Saved = true;
                    return SaveOffline();
                }
            }
            return false;
        }

        #endregion

        private void ShowErr(Exception ex)
        {
            //string msg = null;
            //MessageBoxIcon icon = MessageBoxIcon.Error;
            //if (ex.Data.Count == 2)
            //{
            //    //msg = ex.Data[1].ToString();
            //    //icon = MessageBoxIcon.Information;
            //}
            //else
            //{
            //    msg = ex.Message;
            //}
            MessageBox.Show(this, ex.Message, ex.Data.Count > 0 ? ex.Data[0].ToString(): "Whoops.." , MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        private void tmrFadeLabel_Tick(object sender, EventArgs e)
        {
            int fadingSpeed = 3;
            lblListNoGMAs.ForeColor = System.Drawing.Color.FromArgb(lblListNoGMAs.ForeColor.R + fadingSpeed, lblListNoGMAs.ForeColor.G + fadingSpeed, lblListNoGMAs.ForeColor.B + fadingSpeed);

            if (lblListNoGMAs.ForeColor.R >= this.BackColor.R)
            {
                tmrFadeLabel.Stop();
                lblListNoGMAs.ForeColor = this.BackColor;
                lblListNoGMAs.Visible = false;
                lblListNoGMAs.ForeColor = System.Drawing.Color.Black;
            }
        }

        private void updownJobCnt_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                this.btnGMA_Click(btnGMA, null);
            }
        }

        private void txtContractName_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                this.btnGMA_Click(btnGMA, null);
            }
        }

        private string GetActiveSheet_Version()
        {
            workbook.Activate();
            return ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version;
        }

    }
}
