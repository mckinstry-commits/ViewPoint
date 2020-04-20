using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Drawing;

namespace McK.ARStatement.Viewpoint
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane1 _myActionPane = new ActionPane1();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;

            #region SCALE DOWN FONT SIZE WHEN 150% SCALE
            Application.CommandBars["Task Pane"].Width = 250;

            //float dpiX, dpiY;
            //System.Drawing.Graphics graphics = _myActionPane.CreateGraphics();
            //dpiX = graphics.DpiX;
            //dpiY = graphics.DpiY;

            //if (dpiX == 144) // 150%
            //{
            //    Application.CommandBars["Task Pane"].Width = 250;

            //    foreach(Label label in Globals.ThisWorkbook._myActionPane.Controls.OfType<Label>())
            //    {
            //        label.Font = new Font("Microsoft Sans Serif", 8, FontStyle.Bold);
            //    }
            //    foreach (MaskedTextBox textBox in Globals.ThisWorkbook._myActionPane.Controls.OfType<MaskedTextBox>())
            //    {
            //        textBox.Font = new Font("Microsoft Sans Serif", 8, FontStyle.Bold);
            //    }
            //}

            #endregion

            try
            {
                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVisible;

                Globals.BaseStatement.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseStatementPg2.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.Customers.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.MCK.Environment.Formula =_myActionPane.Environ;

            }
            catch (System.Exception) { throw; }

            RadioButton rdoBtn = (RadioButton)Globals.Customers.Controls["rdoActiveCustomers"];
            rdoBtn.Checked = true;
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            rdoBtn = (RadioButton)Globals.Customers.Controls["rdoARCustomers"];
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            string title = Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula;

            Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula = title + " v." + _myActionPane.ProductVersion;

            string env = (string)_myActionPane.cboTargetEnvironment.SelectedItem;

            if (env == "Prod")
            {
                Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Activate();
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = "";
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Interior.ColorIndex = 2;  // prod
            }
            else
            {
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = env;
            }

            //_myActionPane.btnGetStatement.PerformClick();
        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer

        /// <summary>
        /// Required method for Designer support - modify at your own risk
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisWorkbook_Startup);
            this.Shutdown += new System.EventHandler(ThisWorkbook_Shutdown);
            this.BeforeClose += new Excel.WorkbookEvents_BeforeCloseEventHandler(ThisWorkbook_BeforeClose);
            this.SheetChange += ThisWorkbook_SheetChange;
            this.SheetActivate += ThisWorkbook_SheetActivate;
        }

        #endregion


        /// <summary>
        /// When user changes values on grid, update the structure
        /// </summary>
        /// <param name="Sh"></param>
        /// <param name="Target"></param>
        internal void ThisWorkbook_SheetChange(object Sh, Excel.Range Target)
        {
            if (Sh == null || _myActionPane._wsStatements == null || _myActionPane._isBuildingTable) return;

            Excel.ListObject xltable = null;
            Excel.Worksheet ws = null;
            Excel.Range rng = null;
            long custNoCol = 0;
            long sendYNcol = 0;
            long previewYNcol = 0;
            long invNoCol = 0;
            long invDateCol = 0;
            long invAmtCol = 0;
            long contractDescCol = 0;
            int customerNo = 0;
            dynamic sendYN;
            dynamic prevYN;
            dynamic invNo;
            dynamic invDate;
            dynamic invAmt;
            dynamic contDesc;

            try
            {
                ws = (Excel.Worksheet)Sh;
                xltable = _myActionPane._wsStatements.ListObjects[1];

                if (ws.Name.ContainsIgnoreCase(_myActionPane.SheetName_StatementsGrid))
                {
                    if (xltable.ListColumns.Count > 0) // any data in grid?
                    {
                        custNoCol = xltable.ListColumns["Customer No."].Index;
                        sendYNcol = xltable.ListColumns["Send Statement Y/N"].Index;
                        previewYNcol = xltable.ListColumns["Preview Statement Y/N"].Index;
                        invNoCol = xltable.ListColumns["Invoice# / CheckNo"].Index;
                        invDateCol = xltable.ListColumns["Invoice Date"].Index;
                        invAmtCol = xltable.ListColumns["Invoice Amt"].Index;
                        contractDescCol = xltable.ListColumns["Contract Description"].Index;

                        if (Target.Application.Intersect(xltable.DataBodyRange, Target) != null) // is selection inside grid ?
                        {
                            rng = Target.Application.ActiveWindow.Selection;
                            if (rng.CountLarge > xltable.DataBodyRange.CountLarge) return;

                            long rowCnt = Convert.ToInt64(Target.Row) + Target.CountLarge - 1;
                            long colCnt = Target.Column + Target.Columns.Count - 1;

                            for (int col = Target.Column; col <= colCnt; col++)
                            {
                                if (col == sendYNcol) // SEND STATEMENT Y/N
                                {
                                    foreach (Excel.Range cell in Target)
                                    {
                                        // ignore filtered out rows (hidden rows)
                                        if (ws.Cells[cell.Row, sendYNcol].RowHeight == 0) continue; 

                                        customerNo = Convert.ToInt32(ws.Cells[cell.Row, custNoCol].Value);
                                        sendYN  = ws.Cells[cell.Row, sendYNcol].Value ?? DBNull.Value;
                                        invNo   = ws.Cells[cell.Row, invNoCol].Value ?? DBNull.Value;
                                        invDate = ws.Cells[cell.Row, invDateCol].Value ?? DBNull.Value;
                                        invAmt  = ws.Cells[cell.Row, invAmtCol].Value ?? DBNull.Value;
                                        contDesc = ws.Cells[cell.Row, contractDescCol].Value ?? "";

                                        var statementDetail = _myActionPane._lstSearchResults.Where(n =>
                                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value).GetType() != typeof(DBNull) &&
                                                                                             Convert.ToInt32(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value) == customerNo);
                                        if (!statementDetail.Any()) return;

                                        var sendYNrow = statementDetail.Where(n =>
                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice# / CheckNo"]).Value).GetType() != typeof(DBNull) &&
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice# / CheckNo"]).Value).ToString().Trim() == invNo.ToString().Trim()) &&

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value).GetType() != typeof(DBNull) &&
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value).ToString().Trim() == invDate.ToString().Trim()) &&

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Amt"]).Value).GetType() != typeof(DBNull) &&
                                                                             ((decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Amt"]).Value) == (decimal)invAmt) && // excel treats Amt as double

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract Description"]).Value).GetType() == typeof(DBNull) ? true :
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract Description"]).Value).ToString().Trim() == contDesc.ToString().Trim())
                                                                       ); 

                                        if (sendYNrow.Any())
                                        {
                                            foreach (var row in sendYNrow)
                                            {
                                                IDictionary<string, object> send = (IDictionary<string, object>)row;

                                                string datatype = ((KeyValuePair<string, object>)send["Send Statement Y/N"]).Key;

                                                KeyValuePair<string, object> updatedKV = new KeyValuePair<string, object>(datatype, sendYN);

                                                send["Send Statement Y/N"] = updatedKV;
                                            }
                                        }
                                    }
                                }
                                else if (col == previewYNcol) // PREVIEW STATEMENT Y/N
                                {
                                    foreach (Excel.Range cell in Target)
                                    {
                                        // ignore filtered out rows (hidden rows)
                                        if (ws.Cells[cell.Row, previewYNcol].RowHeight == 0) continue;

                                        customerNo = Convert.ToInt32(ws.Cells[cell.Row, custNoCol].Value);
                                        prevYN = ws.Cells[cell.Row, previewYNcol].Value ?? DBNull.Value;
                                        invNo = ws.Cells[cell.Row, invNoCol].Value ?? DBNull.Value;
                                        invDate = ws.Cells[cell.Row, invDateCol].Value ?? DBNull.Value;
                                        invAmt = ws.Cells[cell.Row, invAmtCol].Value ?? DBNull.Value;
                                        contDesc = ws.Cells[cell.Row, contractDescCol].Value ?? "";

                                        var statementDetail = _myActionPane._lstSearchResults.Where(n =>
                                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value).GetType() != typeof(DBNull) &&
                                                                                             Convert.ToInt32(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value) == customerNo);
                                        if (!statementDetail.Any()) return;


                                        var prevYNrow = statementDetail.Where(n =>
                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice# / CheckNo"]).Value).GetType() != typeof(DBNull) &&
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice# / CheckNo"]).Value).ToString().Trim() == invNo.ToString().Trim()) &&

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value).GetType() != typeof(DBNull) &&
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value).ToString().Trim() == invDate.ToString().Trim()) &&

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Amt"]).Value).GetType() != typeof(DBNull) &&
                                                                             ((decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Amt"]).Value) == (decimal)invAmt) && // excel treats Amt as double

                                                                             ((((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract Description"]).Value).GetType() == typeof(DBNull) ? true :
                                                                             (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract Description"]).Value).ToString().Trim() == contDesc.ToString().Trim())
                                                                       );
                                        if (prevYNrow.Any())
                                        {
                                            foreach (var row in prevYNrow)
                                            {
                                                IDictionary<string, object> prev = (IDictionary<string, object>)row;

                                                string datatype = ((KeyValuePair<string, object>)prev["Preview Statement Y/N"]).Key;

                                                KeyValuePair<string, object> updatedKV = new KeyValuePair<string, object>(datatype, prevYN);

                                                prev["Preview Statement Y/N"] = updatedKV;
                                            }
                                        }
                                    }
                                }
                            }

                            ToggleDeliverBtnOnSendReady();
                            TogglePreviewBtnOnPreviewReady();
                            ToggleMoveNCustomersBtn();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _myActionPane.errOut(ex);
            }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rng != null) Marshal.ReleaseComObject(rng);
            }
        }

        /// <summary>
        /// Enable/disable Deliver button on Send Y/N flags. Also Updates control panel w/ count of ready to be sent statements
        /// </summary>
        internal void ToggleDeliverBtnOnSendReady()
        {
            // Update control panel w/ count of ready to be sent statements
            var uniqueSendYCustomerCnt = Globals.ThisWorkbook._myActionPane._lstSearchResults?
                                                .Where(b =>
                                                        ((((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                        (((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))))
                                                .GroupBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value)
                                                .Distinct().Count();

            Globals.ThisWorkbook._myActionPane.lblRecCnt.Text = uniqueSendYCustomerCnt?.ToString();
            // -- end

            // update control panel deliver button
            var distinct = Globals.ThisWorkbook._myActionPane._lstSearchResults?
                                    .Where(n => (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) 
                                                &&
                                                ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))
                                    .Distinct().Select(n => n).ToList();

            var SendReady = distinct.Any();

            if (SendReady)
            {
                _myActionPane.btnDeliver.Enabled = true;
                _myActionPane.btnDeliver.BackColor = System.Drawing.Color.Honeydew;
            }
            else
            {
                _myActionPane.btnDeliver.Enabled = false;
                _myActionPane.btnDeliver.BackColor = System.Drawing.SystemColors.ControlLight;
            }
        }

        /// <summary>
        /// Enable/Disable Move N Customers button. Updates ActionPane1._noSendCustomers structure.
        /// </summary>
        internal void ToggleMoveNCustomersBtn()
        {
            // get all N customers
            Globals.ThisWorkbook._myActionPane._ienuSendNCustomers = Globals.ThisWorkbook._myActionPane._lstSearchResults?
                                        .Where(row =>
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                (((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value)).Equals("N", StringComparison.OrdinalIgnoreCase)))
                                                ||
                                                ((((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                                !(((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase)))
                                                ||
                                                (((KeyValuePair<string, object>)((IDictionary<string, object>)row)["Send Statement Y/N"]).Value).GetType() == typeof(DBNull));

            int recCount = Globals.ThisWorkbook._myActionPane._ienuSendNCustomers.Count();

            var noSendExist = recCount > 0;

            if (noSendExist)
            {
                _myActionPane.btnMoveNCustomers.Text = "Move " + recCount + " \"N\" Customers to NewTab →";
                _myActionPane.btnMoveNCustomers.Enabled = true;
                _myActionPane.btnMoveNCustomers.BackColor = System.Drawing.Color.Honeydew;
            }
            else
            {
                _myActionPane.btnMoveNCustomers.Text = "There are zero \"N\" Customers";
               _myActionPane.btnMoveNCustomers.Enabled = false;
                _myActionPane.btnMoveNCustomers.BackColor = System.Drawing.SystemColors.ControlLight;
            }

        }

        internal void TogglePreviewBtnOnPreviewReady()
        {
            var distinct = Globals.ThisWorkbook._myActionPane._lstSearchResults?
                                                            .Where(n => (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value).GetType() != typeof(DBNull)
                                                                        &&
                                                                        ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))
                                                            .Distinct().Select(n => n).ToList();

            var PreviewReady = distinct.Any();

            if (PreviewReady && _myActionPane.ckbPreview.Checked)
            {
                _myActionPane.btnPreview.Enabled = true;
                _myActionPane.btnPreview.BackColor = System.Drawing.Color.Honeydew;
            }
            else
            {
                _myActionPane.btnPreview.Enabled = false;
                _myActionPane.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
            }
        }

        internal void ThisWorkbook_SheetActivate(object Sh)
        {
            if (Sh == null) return;

            string tab = ((Excel.Worksheet)Sh).Name;

            if (tab.Contains(_myActionPane.SheetName_StatementsGrid))
            {
                ToggleDeliverBtnOnSendReady();
                ToggleDeliverBtnIfAnyPreviewReady();
            }
            else if (tab.Contains(Globals.BaseResults.Name))
            {
                _myActionPane.btnDeliver.Enabled = false;
                _myActionPane.btnDeliver.BackColor = System.Drawing.SystemColors.ControlLight;
            }
        }

        internal void ToggleDeliverBtnIfAnyPreviewReady()
        {
            // enable/disable Deliver button based on if there are any open Statements. Assumes Statement tab name is the Customer No.
            bool thereAreOpenStatements = false;

            foreach (Excel.Worksheet w in this.Worksheets)
            {
                if (int.TryParse(w.Name.Trim(), out int tryInt))
                {
                    thereAreOpenStatements = true;
                    break;
                }
            }

            if (thereAreOpenStatements)
            {
                _myActionPane.btnPreview.Enabled = true;
                _myActionPane.btnPreview.BackColor = System.Drawing.Color.Honeydew;
            }
            else
            {
                _myActionPane.btnPreview.Enabled = false;
                _myActionPane.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;
            }
        }

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                string wkbSaveAsName = "McK Statements "  + ((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Name.Trim();

                Cancel = IOexcel.SavePrompt(Globals.ThisWorkbook.Worksheets.Parent, wkbSaveAsName);

                if (_myActionPane._wsStatements != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane._wsStatements);
            }
            catch (System.Exception) { }
        }

    }
}
