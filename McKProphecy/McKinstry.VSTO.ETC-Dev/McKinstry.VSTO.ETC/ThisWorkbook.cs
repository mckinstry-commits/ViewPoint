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

        public int pivotNonLaborRowCount;
        public int pivotLaborRowCount;
        public Dictionary<string, int> laborUserInsertedRowCount = new Dictionary<string, int>();
        public Dictionary<string, int> nonLaborUserInsertedRowCount = new Dictionary<string, int>();
        public bool sortDialogVisible;
        public bool isSorting;

        public bool? isRevDirty { get; set; }

        public bool? isCostDirty { get; set; }

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            this.Application.CommandBars["Task Pane"].Width = 140;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }

            isRevDirty = null;
            isCostDirty = null;

            this.Application.ActiveWindow.DisplayGridlines = false;

            foreach (Excel.Worksheet ws in this.Worksheets)
            {
                if (ws.Name != "Control" || ws.Name.Contains("GMAX")) ws.Unprotect(ETCOverviewActionPane.pwd);
                
                if (ws.Name.StartsWith("Labor") || ws.Name.StartsWith("NonLabor"))
                {
                    HelperUI.ProtectSheet(ws);
                }
                else
                {
                    HelperUI.ProtectSheet(ws, false, false);
                }
                HelperUI.PrintPageSetup(ws);
            }

            if (((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Name != "Control")
            {
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.cboJobs.Enabled = false;
            }

            Application.AutoCorrect.AutoFillFormulasInLists = false;
            _myActionPane.txtBoxContract.Focus();
            //Globals.ThisWorkbook.ActionsPane.Clear();
            //Globals.ThisWorkbook.ActionsPane.Visible = true;
            //Globals.ThisWorkbook.ActionsPane.AutoRecover = true;
            //Globals.ThisWorkbook.ActionsPane.OrientationChanged += new EventHandler(ActionsPane_OrientationChanged); ResetStackOrder();
        }

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

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e) {
        }

        //#region UNDO functionality using own stack
        //public string[] tmpFormula = new string[2]; 

        //public Stack<KeyValuePair<string, string>> UndoList = new Stack<KeyValuePair<string, string>>();
        //public Stack<dynamic> UndoParentList = new Stack<dynamic>();
        //#endregion

        public string[] tmpFormula = new string[2]; // needed in ThisWorkbook_SheetChanged

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

            // UNDO FUNCTIONALITY TO HIGHLIGHT CELL ON CHANGE *WORKING* 7/25
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
                // REPAINT INTERIOR ON CUT CELLS - WORK BUT BREAKS UNDO 9/1 Leo Gurdian
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

                if (table.ListRows.Count > pivotLaborRowCount)
                {
                    // user INSERTING row
                    _ws.Unprotect(ETCOverviewActionPane.pwd);
                    EnableSheetChangeEvent(false);

                    int MTDActualHrsCol = table.ListColumns["MTD Actual Hours"].DataBodyRange.Column;

                    for (int i = 1; i <= MTDActualHrsCol; i++)
                    {
                        _ws.Cells[Target.Row, i].FormulaLocal = _ws.Cells[Target.Row + 1, i].FormulaLocal;
                    }

                    int descColNum = table.ListColumns["Description"].Index;
                    string phseCode = _ws.Cells[Target.Row, table.ListColumns["Phase Code"].Index].Value2; 

                    if (!(laborUserInsertedRowCount.ContainsKey(phseCode)))
                    {
                        _ws.Cells[Target.Row, descColNum].FormulaLocal = 1;
                        laborUserInsertedRowCount.Add(phseCode, 1);
                    }
                    else
                    {
                        int increment;
                        laborUserInsertedRowCount.TryGetValue(phseCode, out increment);
                        increment += 1;
                        _ws.Cells[Target.Row, descColNum].FormulaLocal = increment;
                        laborUserInsertedRowCount[phseCode] = increment;
                    }

                   _myActionPane.LaborConditionalFormat(_ws, table, 0, 1, Target);

                    EnableSheetChangeEvent(true);
                   HelperUI.ProtectSheet(_ws);
                    pivotLaborRowCount = table.ListRows.Count;
                }
                else if (table.ListRows.Count < pivotLaborRowCount)
                {
                    // user DELETING row
                    pivotLaborRowCount = table.ListRows.Count;
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
                if (table.ListRows.Count > pivotNonLaborRowCount)
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
                    pivotNonLaborRowCount = table.ListRows.Count;
                }
                else if (table.ListRows.Count < pivotNonLaborRowCount)
                {
                    // user DELETING row
                    pivotNonLaborRowCount = table.ListRows.Count;
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

        public void EnableSheetCalculate(bool eventOn)
        {
            if (eventOn)
            { this.SheetCalculate += new Excel.WorkbookEvents_SheetCalculateEventHandler(ThisWorkbook_SheetCalculate); }
            else
            { this.SheetCalculate -= new Excel.WorkbookEvents_SheetCalculateEventHandler(ThisWorkbook_SheetCalculate); }
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
        /// adjust action pane's controls on different tab activation
        /// </summary>
        /// <param name="sh"></param>
        private void ThisWorkbook_SheetActivate(object sh)  
        {
            if (_myActionPane.txtBoxContract.Text == "") return;
            _myActionPane._ws = (Excel.Worksheet)sh;

            _myActionPane.btnFetchData.Visible = true;
            _myActionPane.btnFetchData.Enabled = true;
            _myActionPane.btnCancelRevBatch.Enabled = false;
            _myActionPane.btnCancelCostBatch.Enabled = false;
            _myActionPane.btnPostCost.Visible = false;
            _myActionPane.btnPostRev.Visible = false;
            _myActionPane.errorProvider1.Clear();
            _myActionPane.groupPost.Visible = false;
            _myActionPane.btnGMAX.Visible = false;
            _myActionPane.lblMonth.Visible = true;
            _myActionPane.btnCopyDetailOffline.Visible = false;
            _myActionPane.btnProjectedRevCurve.Visible = false;
            //_myActionPane.btnPOReport.Visible = false;

            if (HelperUI.IsTextPosNumeric(_myActionPane._ws.Name)) 
            {
                _myActionPane.btnFetchData.Text = "Generate Revenue Projection";
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.cboJobs.Text = "";
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = true;
                _myActionPane.btnFetchData.Enabled = true;
                //_myActionPane.btnProjectedRevCurve.Visible = true;
            }
            else if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.laborSheet) || _myActionPane._ws.Name.Contains(ETCOverviewActionPane.nonLaborSheet))
            {
                _myActionPane.cboJobs.Text = _myActionPane.Job;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.btnFetchData.Visible = false;
                _myActionPane.cboMonth.Text = (DateTime.Parse(this.Names.Item("CostJectMonth").RefersToRange.Value2)).ToString("MM/yyyy");
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
                            _myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostRev.Enabled = false;
                            break;
                        }
                    case true:
                        {
                            _myActionPane.btnFetchData.Enabled = true;
                            _myActionPane.btnPostRev.Enabled = false;
                            break;
                        }
                    case false:
                        {
                            _myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostRev.Enabled = true;
                            break;
                        }
                }
                _myActionPane.btnPostRev.Visible = true;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.cboMonth.Enabled = false;
            }
            else if (_myActionPane._ws.Name.Contains(ETCOverviewActionPane.costSumSheet))
            {
                _myActionPane.btnFetchData.Text = "Save Projections to Viewpoint";
                _myActionPane.btnPostCost.Visible = true;
                _myActionPane.btnCopyDetailOffline.Visible = true;
                _myActionPane.btnCopyDetailOffline.Text = "Copy Cost Detail Offline";
                _myActionPane.btnCopyDetailOffline.Tag = _myActionPane.copyCostDetailsOffline;
                //_myActionPane.btnPOReport.Visible = true;
                switch (isCostDirty)
                {
                    case null:
                        {
                            _myActionPane.btnFetchData.Enabled = false;
                            _myActionPane.btnPostCost.Enabled = false;
                            break;
                        }
                    case true:
                        {
                            _myActionPane.btnFetchData.Enabled = true;
                            _myActionPane.btnPostCost.Enabled = false;
                            break;
                        }
                    case false:
                        {
                            _myActionPane.btnFetchData.Enabled = false;
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
                if(this.Names.Item("CostJectMonth").RefersToRange.Value2 != null){
                    _myActionPane.cboMonth.Text = (DateTime.Parse(this.Names.Item("CostJectMonth").RefersToRange.Value2)).ToString("MM/yyyy"); }
                }
            else if (_myActionPane._ws.Name.Contains("GMAX-"))
            {
                _myActionPane.cboJobs.Text = _myActionPane.Contract + _myActionPane._ws.Name.Split('-')[1];
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.btnFetchData.Visible = false;
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.lblMonth.Visible = false;
                _myActionPane.cboMonth.Visible = false;
                _myActionPane.cboMonth.Enabled = false;
                _myActionPane.btnGMAX.Visible = false;
                _myActionPane.btnCopyDetailOffline.Text = "Copy GMAX Worksheet Offline";
                _myActionPane.btnCopyDetailOffline.Visible = true;
                _myActionPane.btnCopyDetailOffline.Tag = _myActionPane.copyGMAXOffline;
            }
            else if (_myActionPane._ws.Name.Contains("-"))
            {
                _myActionPane.btnFetchData.Text = "Generate Cost Projection";
                _myActionPane.txtBoxContract.Enabled = false;
                _myActionPane.cboMonth.Visible = true;
                _myActionPane.cboMonth.Enabled = true;
                _myActionPane.cboJobs.Enabled = false;
                _myActionPane.cboJobs.Text = _myActionPane.Contract + _myActionPane._ws.Name.Replace("-", "");
                if (_myActionPane._ws.Names.Item("GMAX").RefersToRange.Value == "Yes")
                {
                    _myActionPane.btnGMAX.Visible = true;
                    _myActionPane.btnGMAX.Tag = _myActionPane._ws.Name;
                    _myActionPane.btnCopyDetailOffline.Tag = _myActionPane.copyCostDetailsOffline;
                }
            }
            else if (_myActionPane._ws.Name.Equals("Control"))
            {
                _myActionPane.btnFetchData.Text = _myActionPane.cboJobs.Text == "" ? "Get Contract  && Projects" : "Get Contract  && Project";
                _myActionPane.cboJobs.Enabled = true;
                _myActionPane.txtBoxContract.Enabled = true;
                _myActionPane.cboMonth.Visible = false;
                _myActionPane.lblMonth.Visible = false;
                _myActionPane.groupPost.Visible = true;

                _myActionPane.btnCancelRevBatch.Enabled = _myActionPane.RevBatchId != 0;
                _myActionPane.btnCancelRevBatch.Text = "Cancel Rev Batch: " + (_myActionPane.RevBatchId == 0 ? "" : _myActionPane.RevBatchId.ToString());

                _myActionPane.btnCancelCostBatch.Enabled = _myActionPane.CostBatchId != 0;
                _myActionPane.btnCancelCostBatch.Text = "Cancel Cost Batch: " + (_myActionPane.CostBatchId == 0 ? "" : _myActionPane.CostBatchId.ToString());
                _myActionPane.cboJobs.Text = _myActionPane.lastJobSearched;
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

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                Cancel = !_myActionPane.SavePrompt(deleteSheets: false);
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
        }

        #endregion

    }
}
