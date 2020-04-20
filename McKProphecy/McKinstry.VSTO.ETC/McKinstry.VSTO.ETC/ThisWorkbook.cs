using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
//using Microsoft.Office.Tools.Excel;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;
using McKinstry.ETC.Template;
using System.Globalization;
using System.Threading;
using System.Reflection;
using McKinstry.Data.Viewpoint;
using System.Runtime.InteropServices;
using System.Diagnostics;
//using Mckinstry.VSTO;

namespace McKinstry.ETC.Template
{
    public partial class ThisWorkbook
    {

        // Global Variable for Custom Action Pane
        internal ETCOverviewActionPane _myActionPane = new ETCOverviewActionPane();

        public int PivotNonLaborRowCount { get; set; }
        public int PivotLaborRowCount { get; set; }

        /* default phasecode descriptions to autocremented numbers (1..2..3..)
           resets after Save to Viewpoint                                      
        */
        public Dictionary<string, int> laborUserInsertedRowCount { get; set; }
        public Dictionary<string, int> nonLaborUserInsertedRowCount { get; set; }

        public bool sortDialogVisible { get; set; }

        public bool isSorting { get; set; }

        public bool alreadyPrompted { get; set; } // saving

        public bool? isRevDirty { get; set; }

        public bool? isCostDirty { get; set; }

        private string[] tmpFormula = new string[2]; // needed in ThisWorkbook_SheetChanged

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            #region Task Pane Alignment

            // set action pane width depending on screen resolution
            System.Drawing.Rectangle screen = Screen.FromControl((Control)_myActionPane).Bounds;
            int width;

            switch (screen.Width)
            {
                case 1920:
                    width = 145; // desk monitor
                    break;
                case 1280:
                    width = 165; // laptop montitor
                    break;
                case 1024:
                    width = 168; // smaller devices
                    break;
                default:
                    width = 160;
                    break;
            }

            this.Application.CommandBars["Task Pane"].Width = width;

            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_myActionPane);
            //this.Application.CommandBars["Task Pane"].Width = 156;

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }

            //Globals.ThisWorkbook.ActionsPane.Clear();
            //Globals.ThisWorkbook.ActionsPane.Visible = true;
            //Globals.ThisWorkbook.ActionsPane.AutoRecover = true;
            //Globals.ThisWorkbook.ActionsPane.OrientationChanged += new EventHandler(ActionsPane_OrientationChanged); ResetStackOrder();
            #endregion

            isRevDirty = null;
            isCostDirty = null;

            Application.ActiveWindow.DisplayGridlines = false;
            Application.AutoCorrect.AutoFillFormulasInLists = false;
            _myActionPane.txtBoxContract.Focus();

            _myActionPane.open_batches_row_offset = this.Names.Item("ContractNumber").RefersToRange.Row;
            laborUserInsertedRowCount = new Dictionary<string, int>();
            nonLaborUserInsertedRowCount = new Dictionary<string, int>();
        }

        #region action pane orientation test
        //void ActionsPane_OrientationChanged(object sender, EventArgs e)
        //{
        //    ResetStackOrder();
        //}

        //// Readjust the stack order so that it matches the current orientation.
        //void ResetStackOrder()
        //{
        //    if (Globals.ThisWorkbook.ActionsPane.Orientation == Orientation.Horizontal &&
        //       (Globals.ThisWorkbook.ActionsPane.StackOrder == Microsoft.Office.Tools.StackStyle.FromTop ||
        //        Globals.ThisWorkbook.ActionsPane.StackOrder == Microsoft.Office.Tools.StackStyle.FromBottom))
        //    {
        //        Globals.ThisWorkbook.ActionsPane.StackOrder = Microsoft.Office.Tools.StackStyle.FromLeft;
        //        return;
        //    }

        //    if (Globals.ThisWorkbook.ActionsPane.Orientation == Orientation.Vertical &&
        //       (Globals.ThisWorkbook.ActionsPane.StackOrder == Microsoft.Office.Tools.StackStyle.FromLeft ||
        //        Globals.ThisWorkbook.ActionsPane.StackOrder == Microsoft.Office.Tools.StackStyle.FromRight))
        //    {
        //        Globals.ThisWorkbook.ActionsPane.StackOrder = Microsoft.Office.Tools.StackStyle.FromTop;
        //        this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
        //        this.Application.CommandBars["Task Pane"].Left = (int)this.Application.Width + 170;
        //    }
        //}
        #endregion

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e) {}

        #region UNDO functionality using own stack
        //public string[] tmpFormula = new string[2]; 

        //public Stack<KeyValuePair<string, string>> UndoList = new Stack<KeyValuePair<string, string>>();
        //public Stack<dynamic> UndoParentList = new Stack<dynamic>();
        #endregion

        private void ThisWorkbook_SheetChanged(object sh, Excel.Range Target)
        {
            if (_myActionPane.isRendering) return;
            Excel.Worksheet _ws = (Excel.Worksheet)sh;
            Excel.Range _rng = null;
            Excel.Range _rng2 = null;
            Excel.Range _rng3 = null;
            bool nonLabor = false;
            bool labor = false;
            bool costSum = false;
            bool rev = false;
            bool editCost = false;

            if (_ws.Name.Contains(ETCOverviewActionPane.nonLaborSheet))
            {
                _rng = _myActionPane.NonLaborWritable1;
                _rng2 = _myActionPane.NonLaborWritable2;
                nonLabor = true;
            }
            else if (_ws.Name.Contains(ETCOverviewActionPane.laborSheet))
            {
                _rng = _myActionPane.LaborEmpDescEdit;
                _rng2 = _myActionPane.LaborMonthsEdit;
                _rng3 = _myActionPane.LaborRateEdit;
                labor = true;
            }
            else if (_ws.Name.Contains(ETCOverviewActionPane.costSumSheet))
            {
                _rng = _myActionPane.CostSumWritable;
                costSum = true;
            }
            else if (_ws.Name.Contains(ETCOverviewActionPane.revSheet))
            {
                _rng = _myActionPane.RevWritable1;
                _rng2 = _myActionPane.RevWritable2;
                rev = true;
            }
            else
            {
                return;
            }

            // UNDO FUNCTIONALITY TO HIGHLIGHT CELL ON CHANGE *WORKING* 7/25/2016
            //if (nonLabor || labor)
            //{
            //    if (Target.Cells.Count == 1)
            //    {
            //        if (Application.Intersect(Target, _rng) != null || Application.Intersect(Target, _rng2) != null)
            //        {

            //            if (Target.Formula == tmpFormula[1]) return;

            //            UndoParentList.Push(Target.Parent);
            //            UndoList.Push(new KeyValuePair<string, string>(Target.AddressLocal, tmpFormula[1]));

            //            Target.Style = "Note";
            //            _myActionPane.btnCancelBatch.Enabled = true;
            //            return;
            //        }
            //    }
            //}

            // Flag sheet as 'dirty' when there's a change. (for save prompt)

            if (Target.Cells.Count == 1)
            {
                if (Target.Formula == tmpFormula[1])
                {
                    return;
                }
                // REPAINT INTERIOR ON CUT CELLS - WORK BUT BREAKS UNDO 9/1/2016 Leo Gurdian
                //else if(Target.Formula == "")
                //{
                //    string[] _varianceCol = _ws.ListObjects[1].ListColumns["Variance"].Range.Address.Split('$');

                //    Excel.Range rng = _ws.Range[_ws.Cells[Target.Row, Target.Column], _ws.Cells[Target.Row, _ws.ListObjects[1].HeaderRowRange.Columns.Count]];
                //    Excel.FormatCondition editAreaCond = (Excel.FormatCondition)rng.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
                //                                                Type.Missing, "=$" + _varianceCol[1] + "$" + Target.Row + " <> 0", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                //    editAreaCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
                //}
                if (labor)
                {
                    if (Application.Intersect(Target, _rng) != null || Application.Intersect(Target, _rng2) != null || Application.Intersect(Target, _rng3) != null)
                    {
                        editCost = true;
                    }
                }
                else if (nonLabor)
                {
                    if (Application.Intersect(Target, _rng) != null || Application.Intersect(Target, _rng2) != null)
                    {
                        editCost = true;
                    }
                }
                else if (costSum)
                {
                    if (Application.Intersect(Target, _rng) != null)
                    {
                        editCost = true;
                        _myActionPane.btnPostCost.Enabled = false;
                    }
                }
                else if(rev)
                {
                    if (Application.Intersect(Target, _rng) != null || Application.Intersect(Target, _rng2) != null)
                    {
                        isRevDirty = true;
                        _myActionPane.btnPostRev.Enabled = false;
                    }
                    _myActionPane.btnFetchData.Text = "Save Projections to Viewpoint";
                    _myActionPane.btnFetchData.Enabled = true;
                    return;
                }
                if (editCost)
                {
                    isCostDirty = true;
                    _myActionPane.btnFetchData.Text = "Save Projections to Viewpoint";
                    _myActionPane.btnFetchData.Enabled = true;
                    return;
                }
            }
            
            if (nonLabor)
            {
                InsertDelNonLaborRow(Target, _ws);
            }
            else if (labor)
            {
                InsertDelLaborRow(Target, _ws);
            }

            Marshal.ReleaseComObject(_ws);
            this.Application.DisplayAlerts = true;
        }

        public void InsertDelLaborRow(Excel.Range Target, Excel.Worksheet _ws)
        {
            if (_myActionPane.contJobJectBatchLabor_table.Rows.Count > 0)
            {
                Excel.ListObject table = _ws.ListObjects[1];

                if (table.ListRows.Count > PivotLaborRowCount)
                {
                    // user INSERTING row
                    _ws.Unprotect(ETCOverviewActionPane.pwd);
                    EnableSheetChangeEvent(false);

                    int phaseDesc = table.ListColumns["Phase Desc"].DataBodyRange.Column;

                    for (int i = 1; i <= phaseDesc; i++)
                    {
                        _ws.Cells[Target.Row, i].FormulaLocal = _ws.Cells[Target.Row + 1, i].FormulaLocal;
                    }

                    phaseDesc = phaseDesc + 3;
                    int MTDActualHrs = table.ListColumns["MTD Actuals"].DataBodyRange.Column;

                    for (int i = phaseDesc; i <= MTDActualHrs; i++)
                    {
                        _ws.Cells[Target.Row, i].FormulaLocal = _ws.Cells[Target.Row + 1, i].FormulaLocal;
                    }

                    int desc = table.ListColumns["Description"].Index;
                    string phseCode = _ws.Cells[Target.Row, table.ListColumns["Phase Code"].Index].Value2; 

                    if (!(laborUserInsertedRowCount.ContainsKey(phseCode)))
                    {
                        _ws.Cells[Target.Row, desc].FormulaLocal = 1;
                        laborUserInsertedRowCount.Add(phseCode, 1);
                    }
                    else
                    {
                        laborUserInsertedRowCount.TryGetValue(phseCode, out int increment);
                        ++increment;
                        _ws.Cells[Target.Row, desc].FormulaLocal = increment;
                        laborUserInsertedRowCount[phseCode] = increment;
                    }

                   _myActionPane.LaborConditionalFormat(_ws, table, 0, 1, Target);

                    EnableSheetChangeEvent(true);
                    HelperUI.ProtectSheet(_ws);
                    PivotLaborRowCount = table.ListRows.Count;
                }
                else if (table.ListRows.Count < PivotLaborRowCount)
                {
                    // user DELETING row
                    PivotLaborRowCount = table.ListRows.Count;
                   HelperUI.ProtectSheet(_ws);
                }
                if (table != null) Marshal.ReleaseComObject(table);
            }
        }

        public void InsertDelNonLaborRow(Excel.Range Target, Excel.Worksheet _ws)
        {
            if (_myActionPane.contJobJectBatchNonLabor_table.Rows.Count > 0)
            {
                Excel.ListObject table = _ws.ListObjects[1];
                if (table.ListRows.Count > PivotNonLaborRowCount)
                {
                    // user INSERTING row
                    _ws.Unprotect(ETCOverviewActionPane.pwd);
                    EnableSheetChangeEvent(false);

                    int remainingCost = table.ListColumns["MTD Actual Cost"].Range.Column;

                    for (int i = 1; i <= remainingCost; i++)
                    {
                        _ws.Cells[Target.Row, i].FormulaLocal = _ws.Cells[Target.Row + 1, i].FormulaLocal;
                    }

                    int descColNum = table.ListColumns["Description"].Index;
                    string phseCode = _ws.Cells[Target.Row, table.ListColumns["Phase Code"].Index].Value2;

                    if (!(nonLaborUserInsertedRowCount.ContainsKey(phseCode)))
                    {
                        _ws.Cells[Target.Row, descColNum].FormulaLocal = 1;
                        nonLaborUserInsertedRowCount.Add(phseCode, 1);
                    }
                    else
                    {
                        int increment;
                        nonLaborUserInsertedRowCount.TryGetValue(phseCode, out increment);
                        increment += 1;
                        _ws.Cells[Target.Row, descColNum].FormulaLocal = increment;
                        nonLaborUserInsertedRowCount[phseCode] = increment;
                    }

                    _myActionPane.NonLaborConditionalFormat(_ws, table, 0, 1, Target);

                    EnableSheetChangeEvent(true);
                   HelperUI.ProtectSheet(_ws);
                    PivotNonLaborRowCount = table.ListRows.Count;
                }
                else if (table.ListRows.Count < PivotNonLaborRowCount)
                {
                    // user DELETING row
                    PivotNonLaborRowCount = table.ListRows.Count;
                   HelperUI.ProtectSheet(_ws);
                }
                if (table != null) Marshal.ReleaseComObject(table);
            }
        }

        public void EnableSheetChangeEvent(bool eventOn)
        {
            if (eventOn)
            { this.SheetChange += new Excel.WorkbookEvents_SheetChangeEventHandler(ThisWorkbook_SheetChanged); }
            else
            { this.SheetChange -= new Excel.WorkbookEvents_SheetChangeEventHandler(ThisWorkbook_SheetChanged); }
        }

        /// <summary>
        /// re-protect sheets after sorting tables
        /// </summary>
        /// <param name="sh"></param>
        private void ThisWorkbook_SheetCalculate(object sh)
        {
            if (_myActionPane.isRendering || !isSorting) return;
            _myActionPane._ws = (Excel.Worksheet)sh;

            if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.laborSheet) || _myActionPane._ws.Name.Contains(ETCOverviewActionPane.nonLaborSheet))
            {
                HelperUI.ProtectSheet(_myActionPane._ws);
            }
            else
            {
                HelperUI.ProtectSheet(_myActionPane._ws, false, false);
            }
        }

        /// <summary>
        /// adjust pane 'views' on different tab activation
        /// </summary>
        /// <param name="sh"></param>
        public void ThisWorkbook_SheetActivate(object sh)  
        {
            //if (_myActionPane.txtBoxContract.Text == "") return;
            _myActionPane._ws = (Excel.Worksheet)sh;

            _myActionPane.btnFetchData.Visible = true;
            _myActionPane.btnFetchData.Enabled = true;
            _myActionPane.btnCancelRevBatch.Enabled = false;
            _myActionPane.btnCancelCostBatch.Enabled = false;
            _myActionPane.btnPostCost.Visible = false;
            _myActionPane.btnPostRev.Visible = false;
            _myActionPane.errorProvider1.Clear();
            _myActionPane.groupPost.Visible = false;
            _myActionPane.lblMonth.Visible = true;
            _myActionPane.btnCopyDetailOffline.Visible = false;
            _myActionPane.btnProjectedRevCurve.Visible = false;
            _myActionPane.btnOpenBatches.Visible = false;
            _myActionPane.btnSubcontracts.Visible = false;
            _myActionPane.btnPOs.Visible = false;

            if (HelperUI.IsTextPosNumeric(_myActionPane._ws.Name)) 
            {
                _myActionPane.btnFetchData.Text = "Generate Revenue Projection";
                _myActionPane.txtBoxContract.Enabled = false;
                //_myActionPane.cboJobs.Text = "";
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = true;
                _myActionPane.btnFetchData.Enabled = true;
                _myActionPane.btnProjectedRevCurve.Visible = true;

                // display contract-
                string job = _myActionPane._ws.get_Range("A1").Formula;
                int idx = job.IndexOf(':') + 2;
                if (idx != -1)
                {
                    job = job.Substring(idx, job.Length - idx);
                    job = job.Substring(0, job.IndexOf('-') + 1);
                    if (_myActionPane.cboJobs.DataSource == null)
                    {
                        // user cleared Contract box then switched to a report
                        _myActionPane.Refresh_cboJobs(job);
                    }
                    //_myActionPane.cboJobs.Text = "All Projects";
                    _myActionPane.txtBoxContract.Text = job;
                }
                else
                {
                    _myActionPane.txtBoxContract.Text = "";
                }
                _myActionPane.cboJobs.Text = ETCOverviewActionPane.allprojects;
                _myActionPane.cboJobs.Enabled = false;
            }
            else if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.laborSheet)      || 
                     _myActionPane._ws.Name.Contains(ETCOverviewActionPane.nonLaborSheet)    ||
                     _myActionPane._ws.Name.Contains(ETCOverviewActionPane.subcontracts)    ||
                     _myActionPane._ws.Name.Contains(ETCOverviewActionPane.pos))
            {
                _myActionPane.cboJobs.Text = _myActionPane.Job;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.btnFetchData.Visible = false;
                if (this.Names.Item("CostJectMonth").RefersToRange.Value2 != null)
                {
                    _myActionPane.cboMonth.Text = DateTime.FromOADate(this.Names.Item("CostJectMonth").RefersToRange.Value2).ToString("MM/yyyy");
                }
               // _myActionPane.cboMonth.Text = DateTime.FromOADate(this.Names.Item("CostJectMonth").RefersToRange.Value2).ToString("MM/yyyy");  //(DateTime.Parse((string)this.Names.Item("CostJectMonth").RefersToRange.Value2)).ToString("MM/yyyy");
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = false;
            }
            else if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.revSheet))
            {
                _myActionPane.btnFetchData.Text = "Save Projections to Viewpoint";
                switch (isRevDirty)
                {
                    case null:
                        {
                            //_myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostRev.Enabled = false;
                            break;
                        }
                    case true:
                        {
                            //_myActionPane.btnFetchData.Enabled = true;
                            _myActionPane.btnPostRev.Enabled = false;
                            break;
                        }
                    case false:
                        {
                            //_myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostRev.Enabled = true;
                            break;
                        }
                }
                _myActionPane.btnPostRev.Visible = true;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.cboMonth.Enabled = false;
                _myActionPane.cboMonth.Visible = true;
            }
            else if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.costSumSheet))
            {
                _myActionPane.btnFetchData.Text = "Save Projections to Viewpoint";
                _myActionPane.btnPostCost.Visible = true;
                _myActionPane.btnCopyDetailOffline.Visible = true;
                _myActionPane.btnCopyDetailOffline.Location = new System.Drawing.Point(8, 516);
                _myActionPane.btnCopyDetailOffline.Text = "Copy Cost Detail Offline";
                _myActionPane.btnCopyDetailOffline.Tag = _myActionPane.copyCostDetailsOffline;
                _myActionPane.btnFetchData.Enabled = true;
                switch (isCostDirty)
                {
                    case null:
                        {
                            //_myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostCost.Enabled = false;
                            break;
                        }
                    case true:
                        {
                            //_myActionPane.btnFetchData.Enabled = true;
                            _myActionPane.btnPostCost.Enabled = false;
                            break;
                        }
                    case false:
                        {
                            //_myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostCost.Enabled = true;
                            break;
                        }
                }
                //HelperUI.ApplyUsedFilter(_myActionPane._ws, "Used");  // BREAKS UNDO STACK (issue 237 deferred)
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.cboJobs.Text = _myActionPane.Job;
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = false;
                _myActionPane.btnSubcontracts.Visible = true;
                _myActionPane.btnPOs.Visible = true;
                if (this.Names.Item("CostJectMonth").RefersToRange.Value2 != null){
                    _myActionPane.cboMonth.Text = DateTime.FromOADate(this.Names.Item("CostJectMonth").RefersToRange.Value2).ToString("MM/yyyy");
                }
                }
            else if (_myActionPane._ws.Name.Contains("-"))
            {
                _myActionPane.btnFetchData.Text = "Generate Cost Projection";
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = true;
                _myActionPane.cboJobs.Enabled = false;

                // display corresponding contract / job
                string job = _myActionPane._ws.get_Range("A1").Formula;
                int idx = job.IndexOf(':') + 2;
                if (idx != -1)
                {
                    job = job.Substring(idx, job.Length - idx);
                    job = job.Substring(0, job.IndexOf('_'));
                    if (_myActionPane.cboJobs.DataSource == null) 
                    {
                        // user cleared Contract box then switched to a report
                        _myActionPane.txtBoxContract.Text = job.Substring(0, job.IndexOf('-') + 1);
                        _myActionPane.Refresh_cboJobs(_myActionPane.txtBoxContract.Text);
                    }
                    _myActionPane.cboJobs.Text = job;
                }
                else
                {
                    _myActionPane.txtBoxContract.Text = "";
                    _myActionPane.cboJobs.Text = "";
                }
            }
            else if (_myActionPane._ws.Name.Equals("Control"))
            {
                _myActionPane.btnFetchData.Text = _myActionPane.cboJobs.Text == "" ? "Get Contract  && Projects" : "Get Contract  && Project";
                _myActionPane.txtBoxContract.Enabled = true;
                _myActionPane.cboMonth.Visible = false;
                _myActionPane.lblMonth.Visible = false;
                _myActionPane.groupPost.Visible = true;

                _myActionPane.btnCancelRevBatch.Enabled = _myActionPane.RevBatchId != 0;
                _myActionPane.btnCancelRevBatch.Text = "Cancel Rev Batch: " + (_myActionPane.RevBatchId == 0 ? "" : _myActionPane.RevBatchId.ToString());

                _myActionPane.btnCancelCostBatch.Enabled = _myActionPane.CostBatchId != 0;
                _myActionPane.btnCancelCostBatch.Text = "Cancel Cost Batch: " + (_myActionPane.CostBatchId == 0 ? "" : _myActionPane.CostBatchId.ToString());

                _myActionPane.cboJobs.Enabled = true;
                _myActionPane.cboJobs.Text = _myActionPane.lastJobPulled ?? "All Projects";

                _myActionPane.btnOpenBatches.Visible = true;
                _myActionPane.txtBoxContract.Text = _myActionPane.prevContract;
                //_myActionPane.ValidateContract_RefreshJobs();
            }

            else if(_myActionPane._ws.Name.Equals(ETCOverviewActionPane.revCurve))
            {
                _myActionPane.btnFetchData.Visible = false;
                _myActionPane.cboMonth.Visible = false;
                _myActionPane.lblMonth.Visible = false;
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.txtBoxContract.Visible = true;
                _myActionPane.cboJobs.Text = "";
                _myActionPane.cboJobs.Visible = true;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.btnCopyDetailOffline.Visible = true;
                _myActionPane.btnCopyDetailOffline.Location = new System.Drawing.Point(8, 256);
                _myActionPane.btnCopyDetailOffline.Text = "Copy Rev Offline Detail";
                _myActionPane.btnCopyDetailOffline.Tag = _myActionPane.copyFutureCurveOffline;
            }
            else {
                _myActionPane.btnFetchData.Visible = false;
            }
        }

        public void ThisWorkbook_SheetBeforeRightClick(object sh, Excel.Range Target, ref bool Cancel)
        {
            _myActionPane._ws = (Excel.Worksheet)sh;

            if (_myActionPane._ws.Name.StartsWith(ETCOverviewActionPane.laborSheet) || _myActionPane._ws.Name.StartsWith(ETCOverviewActionPane.nonLaborSheet))
            {
                // is entire row select?
                if (Target.Rows.Count == 1 && Target.Columns.Count == _myActionPane._ws.Columns.Count)
                {
                    // disable alerts when deleting rows from protect cells
                    _myActionPane._ws.Unprotect(ETCOverviewActionPane.pwd);
                    //this.Application.DisplayAlerts = false;
                }
            }
        }

        private void ThisWorkbook_NewSheet(object sh) => this.EnableSheetChangeEvent(false);

        public void ThisWorkbook_SheetSelectionChange(object sh, Excel.Range Target)
        {
            if (Target.Cells.CountLarge == 1)
            {
                tmpFormula[0] = Target.AddressLocal; //[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1, false, Type.Missing];
                tmpFormula[1] = Target.Formula;
            }
        }

        public void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                Cancel = !_myActionPane.SavePrompt(deleteSheets: false);
                if (!Cancel)
                {
                    if (_myActionPane._control_ws != null) Marshal.ReleaseComObject(_myActionPane._control_ws);
                    if (_myActionPane._ws != null) Marshal.ReleaseComObject(_myActionPane._ws);
                    if (_myActionPane._table != null) Marshal.ReleaseComObject(_myActionPane._table);
                    if (_myActionPane.LaborEmpDescEdit != null) Marshal.ReleaseComObject(_myActionPane.LaborEmpDescEdit);
                    if (_myActionPane.LaborMonthsEdit != null) Marshal.ReleaseComObject(_myActionPane.LaborMonthsEdit);
                    if (_myActionPane.NonLaborWritable1 != null) Marshal.ReleaseComObject(_myActionPane.NonLaborWritable1);
                    if (_myActionPane.NonLaborWritable2 != null) Marshal.ReleaseComObject(_myActionPane.NonLaborWritable2);
                    if (_myActionPane.CostSumWritable != null) Marshal.ReleaseComObject(_myActionPane.CostSumWritable);
                    if (_myActionPane.RevWritable1 != null) Marshal.ReleaseComObject(_myActionPane.RevWritable1);
                    if (_myActionPane.RevWritable2 != null) Marshal.ReleaseComObject(_myActionPane.RevWritable2);
                    if (OpenBatches.LastHighlightedRange != null) Marshal.ReleaseComObject(OpenBatches.LastHighlightedRange);
                }
            }
            catch (Exception) { }
        }
        
        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisWorkbook_Startup);
            this.Shutdown += new System.EventHandler(ThisWorkbook_Shutdown);
            this.SheetActivate += new Excel.WorkbookEvents_SheetActivateEventHandler(ThisWorkbook_SheetActivate);
            this.SheetChange += new Excel.WorkbookEvents_SheetChangeEventHandler(ThisWorkbook_SheetChanged);
            this.SheetBeforeRightClick += new Excel.WorkbookEvents_SheetBeforeRightClickEventHandler(ThisWorkbook_SheetBeforeRightClick);
            this.NewSheet += new Excel.WorkbookEvents_NewSheetEventHandler (ThisWorkbook_NewSheet);
            this.BeforeClose += new Excel.WorkbookEvents_BeforeCloseEventHandler(ThisWorkbook_BeforeClose);
            this.SheetCalculate += new Excel.WorkbookEvents_SheetCalculateEventHandler(ThisWorkbook_SheetCalculate); // re-protect sheets after sorting tables
            this.BeforeSave += ThisWorkbook_BeforeSave;
        }

        private void ThisWorkbook_BeforeSave(bool SaveAsUI, ref bool Cancel)
        {
            if (alreadyPrompted == true) return;

            Cancel = alreadyPrompted = true;

            _myActionPane.saveFileDialog1.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
            _myActionPane.saveFileDialog1.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);

            string jobOrContract = "";
            if (_myActionPane.Job == "" || _myActionPane.Job == null)
            {
                jobOrContract = _myActionPane._Contract;
            }
            else
            {
                jobOrContract = _myActionPane.Job;
            }
            _myActionPane.saveFileDialog1.FileName = jobOrContract + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today);

            if (_myActionPane.saveFileDialog1.ShowDialog() == DialogResult.OK)
            {
                foreach (Excel.Worksheet ws in this.Worksheets) ws.Unprotect(ETCOverviewActionPane.pwd);

                Globals.ThisWorkbook.Application.DisplayAlerts = false;
                Globals.ThisWorkbook.RemoveCustomization();
                Globals.ThisWorkbook.SaveAs(_myActionPane.saveFileDialog1.FileName);
                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                // Close Backstage
                Thread.Sleep(1000);
                SendKeys.SendWait("%");
                SendKeys.SendWait("{ESC}");
                Thread.Sleep(400);
                SendKeys.SendWait("%");
            }
            else
            {
                alreadyPrompted = false;
            }
        }

        #endregion
    }
}
