using System;
using System.Data;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using McK.Data.Viewpoint;
using System.Runtime.InteropServices;
using System.Linq;
using System.Drawing;
using System.IO;
using MSForms = Microsoft.Vbe.Interop.Forms;

namespace McK.PRMyTimesheet.Viewpoint
{
    partial class ActionPane : UserControl
    {
        /*****************************************************************************************************************;

                                               McK.PRMyTimesheet.Viewpoint                                 

                                                copyright McKinstry 2018                                              

        This Microsoft Excel VSTO solution was developed by McKinstry in 2018 to batch PRMyTimesheet data to a Payroll batch in Viewpoint.
        This software is the property of McKinstry and requires express written permission to be used by any Non-McKinstry employee or entity                     

        Import MyTimesheet data and process through a Viewpoint derived stored procedure vspPRMyTimesheetSend -> McKvspPRMyTimesheetSend
        Pay Sequence sets are batched into separate PR batches. 


        Release             Date       Details                                              
        -------             ----        -------                                             
        1.0.0.0 Initial Dev 06.05.18    Viewpoint/SQL Dev:  Leo Gurdian
                                        Project Manager:    Theresa Parker
                                        Excel VSTO Dev:     Leo Gurdian                    
                            07.13.18    Init pub to Upgrade  (auto-import method)   
                            08.14.18    leverages a slightly modified version of (PRMyTimesheetSend method)   
                            09.19.18    BUG (line 557) coTabList null object access error
        1.0.0.2             09.24.18    Enabled "Include Batched" checkbox
                            10.11.18    LG - LIVE IN PROD!!
        1.0.0.6             11.09.18    LG -    Renamed 'Approved' tab to 'Ready to Send'
                                            •	Renamed 'Unapproved' tab to 'No ready'
                                            •	Renamed 'Co-[#] Approved' to 'Co_[#]_Summary'
                                            •	Removed 'Partially Approved' tab
                                            •	Disabled 'Include Batched Timesheets' checkbox
                                            •	Added Status, Approved, ApprovedBy, ApprovedOn from PRMyTimesheetDetail to Ready to Send and No ready reports:

        *******************************************************************************************************************/

        //internal const string pwd = "HowardSnow";

        // Worksheets
        private const string unappr_timesheets = "Not Ready";
        private const string appr_timesheets = "Ready to Send";
        private const string summary_worksheet = "Summary";

        //Excel.Worksheet _summary_ws = null;
        internal Excel.Worksheet Summary_ws { get; set; }
        internal Excel.Worksheet _approved_ws = null;
        internal Excel.Range _productName = null;
        internal Excel.Range _dbSource = null;
        internal Excel.Shape _logo = null;

        // SQL query input params
        private byte? prco;
        private byte? prgroup;
        private DateTime prenddate;
        private DateTime prstartdate;
        private dynamic InclPaySeq => txtInclPaySeq.Text == "" || txtInclPaySeq.Text.EqualsIgnoreCase("any") ? null : txtInclPaySeq.Text;
        private dynamic ExclPaySeq => txtExclPaySeq.Text == "" || txtExclPaySeq.Text.EqualsIgnoreCase("none") ? null : txtExclPaySeq.Text;

        // SQL output tables
        private List<string> companyList = new List<string>();
        private List<dynamic> approved_timesheets = null;
        private List<dynamic> unapproved_timesheets = null;
        Dictionary<byte, string> prgroups = new Dictionary<byte, string>();

        internal dynamic tabColorDefault;

        private string active_Payseq_txtBox;

        ToolTip tt1 = new ToolTip(); // txtInclPaySeq
        ToolTip tt2 = new ToolTip(); // txtExclPaySeq

        Microsoft.Vbe.Interop.Forms.CommandButton CmdBtn;  // "Close Lookup" for pay sequnce


        public ActionPane()
        {
            InitializeComponent();

            if (HelperData._conn_string.ContainsIgnoreCase("SEA-STGSQL01"))
            {
                lblEnvironment.Text = "(Project)";
            }
            else if (HelperData._conn_string.ContainsIgnoreCase("SEA-STGSQL02")) 
            {
                lblEnvironment.Text = "(Upgrade)";
            }
            else if (HelperData._conn_string.ContainsIgnoreCase("MCKTESTSQL05"))
            {
                lblEnvironment.Text = "(Dev)";
            }
            else if (HelperData._conn_string.ContainsIgnoreCase("VPSTAGINGAG"))
            {
                lblEnvironment.Text = "(Staging)";
            }
            else if (HelperData._conn_string.ContainsIgnoreCase("VIEWPOINTAG"))
            {
                lblEnvironment.Visible = false;
            }
            else
            {
                lblEnvironment.Text = "Unspecified";
            }

            this.lblVersion.Text = "v." + this.ProductVersion;

            companyList = PRCompanies.GetPRCompanies();
            cboCompany.DataSource = companyList;
            cboCompany.SelectedIndex = 0;

            prgroups = PRGroups.GetPRGroups();
            cboPRGroup.DataSource = prgroups.Select(kv => kv.Value).ToList();
            cboPRGroup.SelectedIndex = 0;

        }

        /// <summary>
        /// Import approved, unapproved and partially approved Timesheets from Viewpoint 
        /// and dynamically create tabs.  Allows approved timesheets to be send to a Payroll Batch.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnGetTimesheets_Click(object sender, EventArgs e)
        {
            string orig_text = btnGetTimesheets.Text;
            btnGetTimesheets.Text = "Processing...";
            btnGetTimesheets.Enabled = false;
            Excel.ListObject xltable = null;

            Excel.Worksheet unapproved_ws = null;
            Excel.Worksheet excluded_ws = null;
            //Excel.Worksheet sht = null;
            //Excel.Range rng = null;
            //Excel.Range rngFound = null;
            //Excel.Range rngEmployees = null;
            //Excel.Range rng1 = null;
            //Excel.Range rng2 = null;
            //Excel.Range rng3 = null;

            int sumStartCol = 4;
            bool approvedExists = false;
            bool unapprovedExists = false;
            bool errout = false;

            //List<dynamic> partiallyApprovedTimesheets = null;
            List<Excel.Worksheet> coTabList = null;

            try
            {
                errout = !IsValidFields();
                if (errout) throw new Exception("Invalid fields");

                if (txtInclPaySeq.Text == "") txtInclPaySeq.Text = "any";
                if (txtExclPaySeq.Text == "") txtExclPaySeq.Text = "none";

                HelperUI.RenderOFF();

                if (Summary_ws.ListObjects?.Count == 1) Summary_ws.ListObjects[1].Delete();

                // delete tabs (previous queries)
                HelperUI.AlertOff();

                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws == Summary_ws) continue;
                    ws.Delete();
                }

                HelperUI.AlertON();

                // UNAPPROVED TIMESHEETS THAT ALSO EXISTS IN APPROVED TIMESHEETS (partially approved)
                //Dictionary<int, int> partialApprTimesheetsEmplyIDs = new Dictionary<int, int>();

                // UNAPPROVED TIMESHEETS
                unapproved_timesheets = TimesheetDetail.GetMyTimesheetsUnapprv(prco, prgroup, prenddate, payseqincl: InclPaySeq, payseqexcl: ExclPaySeq);

                if (unapproved_timesheets.Count > 0)
                {
                    unapprovedExists = true;

                    unapproved_ws = Globals.ThisWorkbook.Worksheets.Add(After: Globals.ThisWorkbook.ActiveSheet);
                    unapproved_ws.Application.ActiveWindow.DisplayGridlines = false;
                    unapproved_ws.Name = unappr_timesheets;
                    unapproved_ws.Tab.Color = HelperUI.OrangePastel;
                   
                    xltable = SheetBuilderDynamic.BuildTable(unapproved_ws, unapproved_timesheets, unappr_timesheets, atRow: 1, showTotals: true, bandedRows: true);

                    xltable.ListColumns["PaySeq"].TotalsCalculation     = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["Memo"].TotalsCalculation       = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["LineType"].TotalsCalculation   = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["Hours"].TotalsCalculation      = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                    xltable.ListColumns["Approved"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["Scope"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["PayType"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["PaySeq"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.HeaderRowRange.HorizontalAlignment          = Excel.XlHAlign.xlHAlignLeft;
                    xltable.DataBodyRange.EntireColumn.AutoFit();

                    IgnoreNumberAsTextErrorCheck(xltable, "Craft");
                    IgnoreNumberAsTextErrorCheck(xltable, "PayType");
                    IgnoreNumberAsTextErrorCheck(xltable, "Class");

                }

                // APPROVED TIMESHEETS: CREATE SUMMARY, EMPLOYEE HOURS BY WEEK, PARTIAL APPROVAL REPORT
                approved_timesheets = TimesheetDetail.GetMyTimesheetsApprv(prco, prgroup, prenddate, posted: chkBatched.Checked, payseqincl: InclPaySeq, payseqexcl: ExclPaySeq);

                if (approved_timesheets.Count > 0)
                {
                    approvedExists = true;

                    // BUILD APPROVED TIMESHEETS REPORT
                    _approved_ws = Globals.ThisWorkbook.Worksheets.Add(After: Summary_ws);
                    _approved_ws.Application.ActiveWindow.DisplayGridlines = false;
                    _approved_ws.Name = appr_timesheets;
                    _approved_ws.Tab.Color = HelperUI.GreenPastel; 

                    xltable = SheetBuilderDynamic.BuildTable(_approved_ws, approved_timesheets, appr_timesheets, atRow: 1, showTotals: true, bandedRows: true);

                    xltable.ListColumns["PaySeq"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["Memo"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["LineType"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                    xltable.ListColumns["Hours"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                    xltable.ListColumns["Approved"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["Scope"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["PayType"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["PaySeq"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    xltable.DataBodyRange.EntireColumn.AutoFit();

                    IgnoreNumberAsTextErrorCheck(xltable, "Craft");
                    IgnoreNumberAsTextErrorCheck(xltable, "PayType");
                    IgnoreNumberAsTextErrorCheck(xltable, "Class");

                    // COMMENETED CODE BELOW NOT USED, JUST ANOTHER WAY
                    #region COLLECTS UNIQUE EMPLOYEE IDs TO BE USED IN THE APPROACH BELOW TO "MOVE" ROW-BY-ROW FROM 'APPROVED' TO 'PARTIALLY APPROVED' SHEET. NOT USED; SQL USED INSTEAD.
                    //var unapprovedUniqueEmployeeIDs = unapproved_timesheets.GroupBy(x => new { x.PRCo, x.Employee })
                    //                                            .Select(x => x.FirstOrDefault());

                    //foreach (var i in unapprovedUniqueEmployeeIDs)
                    //{
                    //    var prco = i.PRCo.Value;
                    //    var emplyId = i.Employee.Value;

                    //    foreach (var timesheet_entry in approved_timesheets.Where(x => x.PRCo.Value == prco &&
                    //                                                                   x.Employee.Value == emplyId).Distinct())
                    //    {
                    //        partialApprTimesheetsEmplyIDs.Add(emplyId, prco);
                    //    }
                    //}
                    #endregion

                    #region EMPLOYEE HOURS BY WEEK

                    var grpApproved = approved_timesheets.GroupBy(c => c.PRCo).Select(g => g.FirstOrDefault());

                    coTabList = new List<Excel.Worksheet>();

                    // create tabs for each PRCo
                    foreach (var timesht in grpApproved)
                    {
                       // tranform group to list<dynamic> table
                       var grpEmployeeHrsByWeek = approved_timesheets.GroupBy(x => new { x.PRCo, x.Employee })
                                    .Select(g => new
                                    {
                                        PRCo = g.Key.PRCo.Value,
                                        Employee = g.Key.Employee.Value,
                                        WeekHrs = g.Sum(n => (decimal)n.Hours.Value),
                                    }
                                    ).Where(n => n.PRCo == timesht.PRCo.Value).Cast<dynamic>().ToList();

                        if (grpEmployeeHrsByWeek.Count > 0)
                        {
                            List<dynamic> detail = new List<dynamic>();

                            foreach (var empl in grpEmployeeHrsByWeek)
                            {
                                #region RETIRE 11/06 per Theresap conv w/ Payroll (don't need partial approv tab)
                                //var excludePartialApprTimesheet = partialApprTimesheetsEmplyIDs.Where(x => x.Key == empl.Employee && x.Value == empl.PRCo);
                                //if (excludePartialApprTimesheet.Count() == 0)
                                //{
                                //    var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;
                                //    row.Add("Company", new KeyValuePair<string, object>(typeof(byte).ToString(), empl.PRCo));
                                //    row.Add("Employee", new KeyValuePair<string, object>(typeof(long).ToString(), empl.Employee));
                                //    row.Add("WeekHrs", new KeyValuePair<string, object>(typeof(decimal).ToString(), empl.WeekHrs));
                                //    detail.Add(row);
                                //}
                                #endregion

                                var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;
                                row.Add("Company", new KeyValuePair<string, object>(typeof(byte).ToString(), empl.PRCo));
                                row.Add("Employee", new KeyValuePair<string, object>(typeof(long).ToString(), empl.Employee));
                                row.Add("WeekHrs", new KeyValuePair<string, object>(typeof(decimal).ToString(), empl.WeekHrs));

                                detail.Add(row);
                            }

                            Excel.Worksheet sht = Globals.ThisWorkbook.Worksheets.Add(After: Summary_ws);
                            sht.Application.ActiveWindow.DisplayGridlines = false;
                            sht.Name = "Co" + "_" + timesht.PRCo.Value + "_" + summary_worksheet;
                            sht.Tab.Color = HelperUI.GreenPastel;
                            coTabList.Add(sht);

                            xltable = SheetBuilderDynamic.BuildTable(sht, detail, sht.Name, atRow: 1, showTotals: true, bandedRows: true);
                            xltable.ListColumns["WeekHrs"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                            xltable.ListColumns["Employee"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationCount;
                        }
                    }

                    #endregion

                    _approved_ws.UsedRange.Locked = true;
                    //HelperUI.ProtectSheet(_approved_ws, false, false);

                    // reveal summary
                    #region Summary

                    // NOT USED, JUST ANOTHER WAY
                    #region IDENTIFY PARTIAL APPROVED TIMESHEETS IN APPROVED TIMESHEETS (not used; SQL used instead)
                    //List<dynamic> partialApprTimesheets = new List<dynamic>();

                    //// identify partial approved timesheets in approved timesheets
                    //foreach (var i in partialApprTimesheetsEmplyIDs)
                    //{
                    //    var emplyId = i.Key;
                    //    var prco = i.Value;

                    //    foreach (var timesheet_entry in approved_timesheets.Where(x => x.PRCo.Value     == prco && 
                    //                                                                   x.Employee.Value == emplyId))
                    //    {
                    //        partialApprTimesheets.Add(timesheet_entry);
                    //    }
                    //}

                    //// remove partial approved timesheets from approved timesheets
                    //foreach (var timesheet_entry in partialApprTimesheets)
                    //{
                    //    approved_timesheets.Remove(timesheet_entry);
                    //}
                    #endregion

                    var grpSummaryByCo = approved_timesheets.GroupBy(x => x.PRCo);

                    List<dynamic> timesheet_summary = new List<dynamic>();

                    foreach (var prco in grpSummaryByCo)
                    {
                        var co = prco.First().PRCo.Value;
                        var grpCo = approved_timesheets.Where(x => x.PRCo.Value == co);
                        int rowCnt = grpCo.Count();
                        var hrs = grpCo.Sum(n => (decimal)n.Hours.Value);

                        var row = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>;
                        row.Add("Company", new KeyValuePair<string, object>(typeof(byte).ToString(), co));
                        row.Add("Rows", new KeyValuePair<string, object>(typeof(long).ToString(), rowCnt));
                        row.Add("Hours", new KeyValuePair<string, object>(typeof(decimal).ToString(), hrs));

                        timesheet_summary.Add(row);
                    }

                    // draw summary totals on summary tab
                    xltable = SheetBuilderDynamic.BuildTable(Summary_ws, timesheet_summary, "Timesheet_Summary", atRow: 13, atColumn: sumStartCol, showTotals: true, bandedRows: true);

                    xltable.ListColumns["Hours"].DataBodyRange.NumberFormat = HelperUI.NumberFormat;
                    xltable.ListColumns["Rows"].DataBodyRange.NumberFormat = HelperUI.NumberFormatx;
                    xltable.ListColumns["Hours"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                    xltable.ListColumns["Rows"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                    xltable.ListColumns["Company"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
                    xltable.ListColumns["Rows"].DataBodyRange.EntireColumn.ColumnWidth = 7.00;
                    xltable.ListColumns["Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;

                    xltable.ListColumns["Company"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["Rows"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                    xltable.DataBodyRange.Font.Size = 11;

                    Summary_ws.get_Range("E15").HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    Summary_ws.get_Range("E14").NumberFormat = HelperUI.NumberFormatx;
                    Summary_ws.get_Range("F14").NumberFormat = HelperUI.NumberFormat;

                    #endregion
                    
                }

                //  RETIRED 11/06 per Theresap conv with Payroll
                #region PARTIAL APPROVAL REPORT

                //// RULE: only allow fully approved timesheets to be loaded, otherwise, exclude
                //partiallyApprovedTimesheets = TimesheetDetail.PartiallyApproved(prco, prgroup, prenddate, approved: true, payseqincl: InclPaySeq, payseqexcl: ExclPaySeq);

                //if (partiallyApprovedTimesheets.Count > 0)
                //{
                //    excluded_ws = Globals.ThisWorkbook.Worksheets.Add(After: unapproved_ws ?? Globals.ThisWorkbook.ActiveSheet);
                //    excluded_ws.Application.ActiveWindow.DisplayGridlines = false;
                //    excluded_ws.Name = "Partially_Approved";
                //    excluded_ws.Tab.Color = HelperUI.OrangePastel;

                //    xltable = SheetBuilderDynamic.BuildTable(excluded_ws, partiallyApprovedTimesheets, "Partially_Approved", atRow: 1, showTotals: true, bandedRows: true);
                //    xltable.ListColumns["PaySeq"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                //    xltable.ListColumns["Hours"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                //    xltable.ListColumns["PREndDate"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                //    xltable.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                //    xltable.DataBodyRange.EntireColumn.AutoFit();

                //    #region THIS APPROACH "MOVES" ROW-BY-ROW FROM 'APPROVED' TO 'PARTIALLY APPROVED' SHEET; NOT USED; SQL USED INSTEAD.
                //    // RULE: only allow fully approved timesheets to be loaded, otherwise, exclude

                //    //xltable = approved_ws.ListObjects[1];
                //    //rngEmployees = xltable.ListColumns["Employee"].Range;

                //    //// unique employee ids
                //    //List<int> deleteRows = new List<int>();

                //    //foreach (var i in partialApprTimesheetsEmplyIDs)
                //    //{
                //    //    rngFound = rngEmployees.Find(i.Key, // Employee
                //    //                            Type.Missing,
                //    //                            Excel.XlFindLookIn.xlValues,
                //    //                            Excel.XlLookAt.xlWhole,
                //    //                            Excel.XlSearchOrder.xlByRows,
                //    //                            Excel.XlSearchDirection.xlNext,
                //    //                            false, Type.Missing, Type.Missing
                //    //                            );
                //    //    int firstFoundRow = rngFound.Row;

                //    //    while (rngFound != null)
                //    //    {
                //    //        // mark to move after loop exit
                //    //        deleteRows.Add(rngFound.Row); 

                //    //        rngFound = rngEmployees.Find(i.Key, // Employee
                //    //                            rngFound,
                //    //                            Excel.XlFindLookIn.xlValues,
                //    //                            Excel.XlLookAt.xlWhole,
                //    //                            Excel.XlSearchOrder.xlByRows,
                //    //                            Excel.XlSearchDirection.xlNext,
                //    //                            false, Type.Missing, Type.Missing
                //    //                            );
                //    //        if (rngFound.Row == firstFoundRow) rngFound = null; //exit once it wraps back to first find
                //    //    }
                //    //}

                //    //excluded_ws = Globals.ThisWorkbook.Worksheets.Add(After: unapproved_ws);
                //    //excluded_ws.Application.ActiveWindow.DisplayGridlines = false;
                //    //excluded_ws.Tab.Color = orange; // tan orange
                //    //excluded_ws.Name = "Partially_Approved";

                //    //int lastCol = xltable.ListColumns.Count;

                //    //// title 
                //    //rng1 = excluded_ws.get_Range("A1");
                //    //rng2 = excluded_ws.Cells[1, lastCol];
                //    //rng1 = excluded_ws.get_Range(rng1, rng2);
                //    //rng1.Merge();
                //    //rng1.Font.Size = 14;
                //    //rng1.Formula = "Excluded Partially Approved Timesheets";
                //    //rng1.EntireRow.RowHeight = 25;
                //    //rng1.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                //    //rng1.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;

                //    //// copy table header
                //    //rng1 = excluded_ws.get_Range("A2");
                //    //rng2 = excluded_ws.Cells[2, lastCol];
                //    //rng1 = excluded_ws.get_Range(rng1, rng2);
                //    ////rng1.Value2 = xltable.HeaderRowRange.Value2;
                //    //xltable.HeaderRowRange.Copy(rng1);

                //    //int lastRow = 2;

                //    //Marshal.ReleaseComObject(rng1);
                //    //Marshal.ReleaseComObject(rng2);

                //    // move partially approved timesheets to 'Exclude' tab
                //    //foreach (var row in deleteRows)
                //    //{
                //    //    // copy from:
                //    //    rng1 = approved_ws.get_Range("A" + row);
                //    //    rng2 = approved_ws.Cells[row, lastCol];
                //    //    rng2 = approved_ws.get_Range(rng1, rng2);

                //    //    // copy to:
                //    //    rng1 = excluded_ws.get_Range("A" + row);
                //    //    rng3 = excluded_ws.Cells[(lastRow + 1), lastCol];
                //    //    rng3 = excluded_ws.get_Range(rng1, rng3);
                //    //    rng2.Copy(rng3);

                //    //    lastRow = excluded_ws.Cells.SpecialCells(Excel.XlCellType.xlCellTypeLastCell, Type.Missing).Row;
                //    //}

                //    // delete source rows
                //    //foreach (var row in deleteRows)
                //    //{
                //    //    approved_ws.get_Range("A" + row, Type.Missing).EntireRow.Delete();
                //    //}

                //    //int rowCnt = deleteRows.Count-1;

                //    //for (int i = rowCnt; i >= 0; i--)
                //    //{
                //    //    approved_ws.get_Range("A" + deleteRows[i], Type.Missing).EntireRow.Delete();
                //    //}

                //    // Create table
                //    //rng1 = excluded_ws.get_Range("A2");
                //    //rng2 = excluded_ws.Cells[lastRow, lastCol];
                //    //rng1 = excluded_ws.get_Range(rng1, rng2);

                //    //xltable= HelperUI.FormatAsTable(rng1, "Excluded_Load", bandedRows:true);
                //    #endregion

                //    // yellow box on the summary page
                //    rng = Summary_ws.Names.Item("alertBox").RefersToRange;

                //    rng.Hyperlinks.Add(rng, "#" + excluded_ws.Name + "!A1", Type.Missing, Type.Missing, Type.Missing);
                //    rng.Font.Underline = Excel.XlUnderlineStyle.xlUnderlineStyleNone;
                //    rng.Formula = "There are partially approved timesheets that will be exluded from loading.\n>Click here<";
                //    rng.Style = "Note";
                //    rng.Font.Size = 12;
                //    rng.Font.Color = Excel.XlRgbColor.rgbGray;
                //    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                //}
                //else
                //{
                //    rng = Summary_ws.Names.Item("alertBox").RefersToRange;
                //    rng.Hyperlinks.Delete();
                //    rng.Formula = "";
                //}
                #endregion

            }
            catch (Exception ex)
            {
                errOut(ex);
                ShowLandingPage();

                approved_timesheets?.Clear();
                unapproved_timesheets?.Clear();
            }
            finally
            {
                HelperUI.RenderON();

                btnGetTimesheets.Enabled = true;
                btnGetTimesheets.Text = orig_text;

                if (!errout)
                {

                    Globals.ThisWorkbook.Activate(); // in case user switched to another workbook, bring back focus

                    if (excluded_ws != null)
                    {
                        excluded_ws.Activate();
                        excluded_ws.get_Range("A1").Select();
                    }
                    if (coTabList?.Count > 0)
                    {
                        foreach (var ws in coTabList)
                        {
                            ws.Activate();
                            ws.get_Range("A1").Select();
                            Marshal.ReleaseComObject(ws);
                        }
                    }
                    Summary_ws.Activate();
                    Summary_ws.get_Range("A1").Select();

                    if (approvedExists)
                    {
                        btnBatchApprvTimesheets.Enabled = true;
                        Summary_ws.Tab.Color = HelperUI.GreenPastel;
                        ShowLandingPage(false);
                        MessageBox.Show("Done!");
                    }
                    else if (unapprovedExists )
                    {
                        unapproved_ws.Activate();
                        btnBatchApprvTimesheets.Enabled = false;
                        ShowLandingPage();
                        MessageBox.Show("Done!");
                    }
                    else
                    {
                        if (!approvedExists && !unapprovedExists)
                        {
                            ShowLandingPage();
                        }
                        Summary_ws.Tab.Color = tabColorDefault;
                        btnBatchApprvTimesheets.Enabled = false;
                        MessageBox.Show("No fully approved data found.");
                    }

                }

                #region CLEAN UP
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (_approved_ws != null) Marshal.ReleaseComObject(_approved_ws);
                if (unapproved_ws != null) Marshal.ReleaseComObject(unapproved_ws);
                //if (sht != null) Marshal.ReleaseComObject(sht);
                //if (rngEmployees != null) Marshal.ReleaseComObject(rngEmployees);
                //if (rng1 != null) Marshal.ReleaseComObject(rng1);
                //if (rng2 != null) Marshal.ReleaseComObject(rng2);
                //if (rng3 != null) Marshal.ReleaseComObject(rng3);
                #endregion
            }
        }

        /// <summary>
        /// clear xlNumberAsText error in line items
        /// </summary>
        /// <param name="xltable"></param>
        /// <param name="columnName"></param>
        private static void IgnoreNumberAsTextErrorCheck(Excel.ListObject xltable, string columnName)
        {
            Excel.Range rng = xltable.ListColumns[columnName].DataBodyRange;

            foreach (Excel.Range r in rng)
            {
                r.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;
                Marshal.ReleaseComObject(r);
            }
        }

        /// <summary>
        /// only show landing screen logo if query data is missing
        /// </summary>
        /// <param name="show"></param>
        internal void ShowLandingPage(bool show = true)
        {
            if (_logo != null && show)
            {
                _logo.Visible                   = Office.MsoTriState.msoCTrue;
                _productName.Font.ThemeColor    = Excel.XlThemeColor.xlThemeColorDark2;
                _productName.Font.TintAndShade  = -0.499984741;
                _dbSource.Font.ThemeColor       = Excel.XlThemeColor.xlThemeColorDark1;
                _dbSource.Font.TintAndShade     = -0.349986267;
            }
            else
            {
                _logo.Visible           = Office.MsoTriState.msoFalse;
                _productName.Font.Color = Excel.XlRgbColor.rgbWhite;
                _dbSource.Font.Color    = Excel.XlRgbColor.rgbWhite;
            }
        }

        private void btnBatchApprvTimesheets_Click(object sender, EventArgs e)
        {
            string orig_text = btnBatchApprvTimesheets.Text;
            btnBatchApprvTimesheets.Text = "Uploading...";
            btnBatchApprvTimesheets.Enabled = false;

            //Excel.ListObject xltable = null;
            Excel.Worksheet ws = null;

            string errmsg = "No approved timesheet data present.\n" + "" +
                            "Click 'Get Timesheets' first, then 'Batch Approved Timesheets'.\n\n" +
                            "If problem persists, contact support.";

            bool success = false;

            HelperUI.RenderOFF();
            dynamic grpUniquePaySeqList = null; 

            try
            {
                if (approved_timesheets == null || approved_timesheets.Count == 0)    errOut(title: errmsg);

                // get only unique timesheets payseq sets
                grpUniquePaySeqList = approved_timesheets.GroupBy(x => new { x.PRCo, x.PRGroup, x.PREndDate, x.PaySeq })
                            .Select(g => new
                            {
                                PRCo        = g.Key.PRCo.Value,
                                PRGroup     = g.Key.PRGroup.Value,
                                PRStartDate = (DateTime.Parse(g.Key.PREndDate.Value.ToString()).AddDays(-6)),
                                PREndDate   = g.Key.PREndDate.Value,
                                PaySeq      = g.Key.PaySeq.Value
                            }
                            ).Cast<dynamic>().ToList();


                // sql outputs created batch info
                List<string> batches = new List<string>();

                #region TEST
                //string msg = "Created Batch:\n\n" + "PR Company: 1   Month: 05/18   Batch#: 4555\n\n";
                //batches.Add(msg);
                //batches.Add(msg);
                //batches.Add(msg);
                #endregion

                // process payseq sets 
                foreach (var s in grpUniquePaySeqList)
                {
                    var output = TimesheetDetail.SendApprovedTimesheetsToPRBatch
                                                 (
                                                    Convert.ToByte(s.PRCo), 
                                                    s.PRGroup, 
                                                    s.PRStartDate, 
                                                    s.PREndDate, 
                                                    s.PaySeq
                                                 );
                    batches.Add(output + "\n\n");
                }

                success = true;

                if (batches.Count > 0)  // show batch info results
                {
                    Globals.ThisWorkbook.Activate();

                    _approved_ws.Activate();

                    HelperUI.DeleteSheet("Batches");

                    ws = Globals.ThisWorkbook.Sheets.Add(After: _approved_ws);
                    ws.Name = "Batches";
                    ws.Application.ActiveWindow.DisplayGridlines = false;
                    ws.get_Range("A1").EntireColumn.ColumnWidth = 40;

                    for (int i = 1; i <= batches.Count; i++)
                    {
                        ws.get_Range("A" + i).Formula = batches[i - 1];
                    }
                }

            }
            catch (Exception ex)
            {
                errOut(ex);
            }
            finally
            {
                btnBatchApprvTimesheets.Enabled = true;
                btnBatchApprvTimesheets.Text = orig_text;

                HelperUI.RenderON();

                if (success) MessageBox.Show("Timesheets successfully sent to PR Batch" + (grpUniquePaySeqList.Count > 1 ? "es" : "") + "!");

            }
        }

        private void btnCopyWkbOffline_Click(object sender, EventArgs e)
        {
            string orig_text = btnCopyWkbOffline.Text;
            btnCopyWkbOffline.Text = "Saving...";
            btnCopyWkbOffline.Enabled = false;

            try
            {
                string wkbSaveAsName = "McK PRMyTimesheets " + string.Format("{0:M-dd-yyyy}", DateTime.Today) + " " + DateTime.Now.ToString("hh:mm:ss tt").Replace(":", "") + ".xlsx";

                // when CopyOffline returns false, it means user didn't cancel and succeeded saving
                if (!IOexcel.CopyOffline(saveAsName: wkbSaveAsName))
                {
                    ShowInfo(customErr: "Saved!", title: "Copy Workbook Offline");
                }
            }
            catch (Exception ex)
            {
                errOut(ex);
            }
            finally
            {
                btnCopyWkbOffline.Enabled = true;
                btnCopyWkbOffline.Text = orig_text;
            }
        }

        #region UI CONTROLS

        // update / validate company
        private void cboCompany_Leave(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetError(cboCompany, "Select a PR Company from the list");
                return;
            }
        }
        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                prco = null;
                cboCompany.SelectedIndex = -1;
            }
        }
        private void cboCompany_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (cboCompany.SelectedIndex != -1) errorProvider1.SetError(cboCompany, "");

            var selectedCo = cboCompany.SelectedValue.ToString();

            prco = selectedCo == "Any" ? null : (byte?) byte.Parse(companyList.FirstOrDefault(x => x == selectedCo));
        }

        /// <summary>
        /// When pr group is 'Any', set pr group to null, else pass the pr group value
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void cboPRGroup_Leave(object sender, EventArgs e)
        {
            string selectedGroup = cboPRGroup.SelectedValue.ToString();

            prgroup = selectedGroup == "Any" ? (byte?)null :  prgroups.FirstOrDefault(x => x.Value == selectedGroup).Key;
        }

        /// <summary>
        /// Allow enter key to invoke import
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void tiggerEnter_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                btnGetTimesheets_Click(sender, null);
            }
        }

        /// <summary>
        /// Paint font on Dropdown menus when using custom backcolor
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
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

        /// <summary>
        /// Calculate PR End Date from PR Start Date and enfore "Pay period must start on a Monday" rule
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void txtStartDate_TextChanged(object sender, EventArgs e)
        {
            string digits = txtStartDate.Text.Replace("/", "");

            if (digits.Length == 6)
            {
                if (DateTime.TryParse(txtStartDate.Text, out prstartdate))
                {
                    lblDayOfWeek.Text = prstartdate.DayOfWeek.ToString();

                    if (prstartdate.DayOfWeek != DayOfWeek.Monday)
                    {
                        errorProvider1.SetIconAlignment(txtStartDate, ErrorIconAlignment.MiddleLeft);
                        errorProvider1.SetError(txtStartDate, "Pay period must start on a Monday");
                        txtEndDate.Text = "";
                        return;
                    }

                    prenddate = prstartdate.AddDays(6);
                    txtEndDate.Text = prenddate.ToString("MM/dd/yy", System.Globalization.CultureInfo.InvariantCulture);
                    errorProvider1.SetError(txtStartDate, "");
                    errorProvider1.SetError(txtEndDate, "");
                }
            }
            else
            {
                lblDayOfWeek.Text = "";
            }
        }
        #endregion


        #region field validation

        // validates fields with alert
        private bool IsValidFields()
        {
            bool isValidField = false;
            bool badEndDate = false;

            // PR COMPANY
            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCompany, "Select a PR Company");
                isValidField = true;
            }
            else
            {
                errorProvider1.SetError(cboCompany, "");
            }

            // PR END DATE
            if (!DateTime.TryParse(txtEndDate.Text, out prenddate))
            {
                errorProvider1.SetIconAlignment(txtEndDate, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(txtEndDate, "Input PR End Date MM/DD/YY");
                badEndDate = true;
            }
            else
            {
                errorProvider1.SetError(txtEndDate, "");
            }
           
            // PR START DATE -- OPTIONAL (calculated from End Date)
            if (!DateTime.TryParse(txtStartDate.Text, out prstartdate) && !badEndDate)
            {
                prstartdate = prenddate.AddDays(-6);
                txtStartDate.Text = prstartdate.ToString("MM/dd/yy", System.Globalization.CultureInfo.InvariantCulture);
            }

            var payseqincl = txtInclPaySeq.Text;

            isValidField = IsPaySeqFilterValid(txtInclPaySeq);

            isValidField = IsPaySeqFilterValid(txtExclPaySeq);

            if (isValidField || badEndDate) return false;

            return true;
        }
        private bool IsPaySeqFilterValid(object sender)
        {
            TextBox tb = (TextBox)sender;

            string correctInput = tb.Name == "txtInclPaySeq" ? "any" : "none";

            bool isValidField = false;

            var splitStr = tb.Text.Split(',');

            if (splitStr.Length == 1)
            {
                if (!splitStr[0].EqualsIgnoreCase(correctInput) && splitStr[0] != "" && !int.TryParse(splitStr[0], out int n))
                {
                    errorProvider1.SetError(tb, "Invalid input. Press F4 for lookup.");
                    isValidField = true;
                }
            }
            else // does array contain all digits?
            {
                foreach (var val in splitStr)
                {
                    if (!int.TryParse(val, out int n))
                    {
                        errorProvider1.SetError(tb, "Invalid input. Press F4 for lookup.");
                        isValidField = true;
                        break;
                    }
                }
            }

            if (!isValidField)
            {
                errorProvider1.SetError(tb, "");
            }
            return isValidField;
        }

        #endregion


        #region PAY SEQ. F4 LOOKUP (INCL/EXCL FILTERS)

        private void txtPaySeq_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F4)
            {
                Excel.ListObject xltable = null;
                Excel.Worksheet ws = null;

                HelperUI.AlertOff();
                HelperUI.RenderOFF();
                List<dynamic> table = null;

                try
                {
                    active_Payseq_txtBox = ((TextBox)sender).Name;

                    table = PaySequenceLookup.GetPaySequences();

                    if (table?.Count > 0)
                    {
                        Globals.ThisWorkbook.Activate();

                        HelperUI.DeleteSheet("Pay Sequences");

                        ws = Globals.ThisWorkbook.Sheets.Add(Before: Summary_ws);
                        ws.Name = "Pay Sequences";
                        ws.Application.ActiveWindow.DisplayGridlines = false;
                        ws.get_Range("A1").EntireColumn.ColumnWidth = 40;

                        xltable = SheetBuilderDynamic.BuildTable(ws, table, "tblPaySequences", atRow: 1, showTotals: false, bandedRows: true);

                        ws.SelectionChange += PaySeqLookup_SelectionChange;

                        xltable.ListColumns["PaySeq"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                        ws.get_Range("A:B").EntireColumn.AutoFit();

                        CreateCloseLookupButton(ws);
                    }
                    else
                    {
                        ShowInfo(customErr: "No records found!");
                    }
                }
                catch (Exception ex)
                {
                    errOut(ex);
                }
                finally
                {
                    Application.UseWaitCursor = false;
                    HelperUI.AlertON();
                    HelperUI.RenderON();
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (ws != null) Marshal.ReleaseComObject(ws);
                }
            }
        }

        private void CreateCloseLookupButton(Excel.Worksheet ws)
        {
            // insert button shape
            Excel.Shape cmdButton = ws.Shapes.AddOLEObject("Forms.CommandButton.1", Type.Missing, false, false, Type.Missing, Type.Missing, Type.Missing, ws.get_Range("C1").Left+3, 5, 100, 50);
            cmdButton.Name = "btn";

            // bind and wire it up
            CmdBtn = (Microsoft.Vbe.Interop.Forms.CommandButton)Microsoft.VisualBasic.CompilerServices.NewLateBinding.LateGet(ws, null, "btn", new object[0], null, null, null);
            CmdBtn.Caption = "Close Lookup";
            CmdBtn.Click += new MSForms.CommandButtonEvents_ClickEventHandler(ClosePayseqLookup_Click);
        }

        private void ClosePayseqLookup_Click()
        {
            Excel.Worksheet ws = null;

            try
            {
                ws = Globals.ThisWorkbook.Sheets["Pay Sequences"];
                ws.SelectionChange -= PaySeqLookup_SelectionChange;
                HelperUI.DeleteSheet(ws.Name);

            }
            catch (Exception) { }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
        }

        /// <summary>
        /// Selected pay seq. cells will be displayed in textbox
        /// </summary>
        /// <remarks>This handles both incl. & excl. textboxes</remarks>
        /// <param name="Target"></param>
        private void PaySeqLookup_SelectionChange(Excel.Range Target)
        {
            Excel.ListObject xltable = null;
            Excel.Worksheet ws = null;
            Excel.Range rngTableBody = null;
            string payseqlist = "";

            try
            {
                ws = Target.Parent;

                if (ws.ListObjects.Count > 0)
                {
                    xltable = ws.ListObjects[1];
                    rngTableBody = xltable.DataBodyRange;

                    TextBox txtBox = active_Payseq_txtBox == "txtInclPaySeq" ? txtInclPaySeq : txtExclPaySeq;

                    if (Target.Application.Intersect(rngTableBody, Target) != null)
                    {
                        // show pay sequence(s) on the textbox..
                        int counter = 0;

                        if (Target.Count > 1)
                        {
                            foreach (Excel.Range c in Target.Cells)
                            {
                                counter++;
                                payseqlist += ws.get_Range("A" + c.Row).Formula + (counter != Target.Count ? "," : "");
                            }
                        }
                        else
                        {
                            payseqlist = ws.get_Range("A" + Target.Row).Formula;
                        }

                        txtBox.Text = payseqlist;

                        // make font size smaller on larger list
                        if (txtBox.Text.Length > 14)
                        {
                            txtBox.Font = new Font(txtBox.Font.FontFamily, 6.75f);

                        }
                        else
                        {
                            txtBox.Font = new Font(txtBox.Font.FontFamily, 9.75f);
                        }

                    }
                    else
                    {
                        txtBox.Text = txtBox.Name == "txtInclPaySeq" ? "any" : "none";
                        txtBox.Font = new Font(txtBox.Font.FontFamily, 9.75f);
                    }
                }
            }
            catch (Exception)
            {
                //errOut(ex); // let it go..
            }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
            }
        }

        private void txtBoxPaySeq_MouseHover(object sender, EventArgs e)
        {
            TextBox tb = (TextBox)sender;
            ToolTip tt = tb.Name == "txtInclPaySeq" ? tt1 : tt2; 
            tt.IsBalloon = true;
            tt.InitialDelay = 0;
            tt.ShowAlways = true;
            tt.UseAnimation = true;
            tt.SetToolTip(tb, tb.Text);
        }

        private void txtPaySeq_TextChanged(object sender, EventArgs e) => IsPaySeqFilterValid(sender);

        #endregion


        private void errOut(Exception ex = null, string customErr = null, string title = "Oops")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        internal void ShowInfo(Exception ex = null, string customErr = null, string title = "Look")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void txtInclPaySeq_MouseLeave(object sender, EventArgs e)
        {
            tt1.RemoveAll();
            tt2.RemoveAll();
        }


        //private void AlignColumns(Excel.ListObject xltable)
        //{
        //    xltable.ListColumns["PRCo"].DataBodyRange.EntireColumn.ColumnWidth = 4.25;
        //    xltable.ListColumns["Employee"].DataBodyRange.EntireColumn.ColumnWidth = 9.38;
        //    xltable.ListColumns["WeekHrs"].DataBodyRange.EntireColumn.ColumnWidth = 8.63;

        //    // BODY CENTER
        //    string[] alignColumns = new string[] { "PRCo", "WeekHrs" };

        //    foreach (var column in alignColumns)
        //    {
        //        xltable.ListColumns[column].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
        //    }

        //    xltable.ListColumns["Employee"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
        //}
    }
}
