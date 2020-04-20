using McKinstry.Data.Models.Viewpoint;
using McKinstry.Data.Viewpoint;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using GetOpenBatches = McKinstry.Data.Viewpoint.OpenBatches;

namespace McKinstry.ETC.Template
{
    internal static class OpenBatches
    {
        internal static  Excel.Worksheet _control_ws = null;

        internal static Excel.Range LastHighlightedRange { get; set; }

        internal static List<Batch> MyOpenBatches { get; set; }

        internal static int OpenBatchesRowOffset { get; set; }

        internal static void RefreshOpenBatchesUI(bool notify = false)
        {
            Excel.Range rng = null;
            Excel.Worksheet lastSheetIWasOn = null;
            string btnName = "";
            int openBatchesRowOffset = OpenBatchesRowOffset;

            try
            {
                _control_ws = Globals.ControlSheet.InnerObject;

                ClearOpenBatches(_control_ws, OpenBatchesRowOffset);

                MyOpenBatches = GetOpenBatches.GetOpenBatches(Globals.ThisWorkbook._myActionPane.Login);

                if (MyOpenBatches.Count == 0 && notify)
                {
                    MessageBox.Show("You have no open batches");
                    return;
                }

                lastSheetIWasOn = Globals.ThisWorkbook.ActiveSheet as Excel.Worksheet;

                // are there more buttons than batch rows ?
                int lastButtonRow = OpenBatchesRowOffset + MyOpenBatches.Count;
                btnName = "btnCancel" + lastButtonRow;

                // remove orphane buttons
                if (Globals.ControlSheet.Controls.Contains(btnName))
                {
                    Button btn = (Button)Globals.ControlSheet.Controls[btnName];
                    btn.Click -= Globals.ControlSheet.btnCancel_Click;
                    Globals.ControlSheet.Unprotect(ETCOverviewActionPane.pwd);
                    Globals.ControlSheet.Controls.Remove(btn.Name);
                    btn.Dispose();
                    HelperUI.ProtectSheet(Globals.ControlSheet.InnerObject);
                }

                // creat / update buttons
                foreach (Batch b in MyOpenBatches)
                {
                    // put batch row in worksheet
                    object[] row = { b.ContractOrJob, b.BatchId, b.ProjectionMonth, b.Type };
                    _control_ws.get_Range(Globals.ControlSheet.OpenBatchesStartCol + openBatchesRowOffset + ":" + Globals.ControlSheet.OpenBatchesEndCol + openBatchesRowOffset).Value2 = row;

                    // corresponding button cell
                    rng = _control_ws.get_Range("L" + openBatchesRowOffset);

                    btnName = "btnCancel" + openBatchesRowOffset;

                    if (!(Globals.ControlSheet.Controls.Contains(btnName)))
                    {
                        // button doesn't exist, create it
                        Button btn = new Button
                        {
                            Text = "Cancel",
                            Name = "btnCancel" + openBatchesRowOffset,
                            Tag = openBatchesRowOffset,
                        };

                        btn.Click += Globals.ControlSheet.btnCancel_Click;

                        Globals.ControlSheet.Controls.AddControl(btn, rng, btn.Name);
                    }
                    else
                    {
                        // get existing button
                        Control _btn = (Control)Globals.ControlSheet.Controls[btnName];
                        Button btn = (Button)_btn;

                        // if not in correct position, move to corresponding batch row 
                        if ((int)btn.Tag != openBatchesRowOffset)
                        {
                            btn.Tag = openBatchesRowOffset;
                            btn.Location = RangeToPoint.GetCellPosition(rng);
                        }

                    }
                    ++openBatchesRowOffset;
                }

                // creating buttons forces control sheet activation
                if (lastSheetIWasOn == _control_ws)
                {
                    _control_ws.get_Range("H10").Activate(); // focus 'My Open Batches' area
                }
                else
                {
                    lastSheetIWasOn.Activate(); // retain focus after generating projection
                }
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (_control_ws != null) Marshal.ReleaseComObject(_control_ws);
                if (lastSheetIWasOn != null) Marshal.ReleaseComObject(lastSheetIWasOn);
            }
        }


        private static void ClearOpenBatches(Excel.Worksheet _control_ws, int open_batches_row_offset)
        {
            int clearUpToTwentyRows = 35;  // open_batches_row_offset = 12  so.. 35 - 12 = 20
            _control_ws.get_Range(Globals.ControlSheet.OpenBatchesStartCol + open_batches_row_offset + ":" + Globals.ControlSheet.OpenBatchesEndCol + clearUpToTwentyRows).Value = "";
        }

        public static bool CancelCostBatch(byte JCCo, DateTime lastCostProjectedMonth, uint costBatchId, string login, string contract, string job)
        {
            string msg = "";
            bool success = false;

            try
            {
                if (Data.Viewpoint.JCDelete.DeleteCostBatch.DeleteBatchCost(JCCo, lastCostProjectedMonth, costBatchId))
                {
                    LogProphecyAction.InsProphecyLog(login, 10, JCCo, contract, job, lastCostProjectedMonth, costBatchId);
                    msg = "Cost Batch " + costBatchId + " was successfully cancelled";
                    success = true;
                }
                else
                {
                    msg = "Cost Batch was NOT cancelled.  Please retry or log in to the Viewpoint to cancel the batch.\n\n  If problem persists contact support. ";
                    //Possible failure reason: connectivity, cancelled via VP application
                }
                HighlightBatchRow(0);
                MessageBox.Show(msg);
                return success;
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(login, 10, JCCo, contract, job, lastCostProjectedMonth, costBatchId, ex.Message);
                throw;
            }
        }

        public static bool CancelRevBatch(byte JCCo, DateTime lastRevProjectedMonth, uint revBatchId, string login, string contract, string job)
        {
            string msg = "";
            bool success = false;

            try
            {
                if (Data.Viewpoint.JCDelete.DeleteRevBatch.DeleteBatchRev(JCCo, lastRevProjectedMonth, revBatchId))
                {
                    LogProphecyAction.InsProphecyLog(login, 12, JCCo, contract, job, lastRevProjectedMonth, revBatchId);
                    msg = "Revenue Batch " + revBatchId + " was successfully cancelled";
                    success = true;
                }
                else
                {
                    msg = "Revenue Batch was NOT cancelled.  Please retry or log in to the Viewpoint to cancel the batch.\n\n  If problem persists contact support. ";
                    //Possible failure reason: connectivity, cancelled via VP application
                }
                HighlightBatchRow(0);
                MessageBox.Show(msg);
                return success;
            }
            catch (Exception ex)
            {
                LogProphecyAction.InsProphecyLog(login, 12, JCCo, contract, job, lastRevProjectedMonth, revBatchId, ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Highlights the open batch row in question.  
        /// </summary>
        /// <param name="batchID">valid batch id or zero reveses highlight</param>
        public static void HighlightBatchRow(uint batchID = 0x0)
        {
            try
            {
                if (batchID != 0x0)
                {
                    if (MyOpenBatches != null)
                    {
                        Batch batch = MyOpenBatches.Where(b => b.BatchId == batchID)?.First();

                        if (batch != null)
                        {
                            int batchRow = OpenBatchesRowOffset + MyOpenBatches.IndexOf(batch);

                            LastHighlightedRange = _control_ws.get_Range(Globals.ControlSheet.OpenBatchesStartCol + batchRow + ":" + Globals.ControlSheet.OpenBatchesEndCol + batchRow);

                            HelperUI.ColorAllBorders(LastHighlightedRange, HelperUI.McKColor(HelperUI.McKColors.Orange));
                        }
                    }
                }
                else
                {
                    HelperUI.ColorAllBorders(LastHighlightedRange, HelperUI.McKColor(HelperUI.McKColors.White));
                }

            }
            catch (Exception ex)
            {
                Globals.ThisWorkbook._myActionPane.ShowErr(ex);
            }
        }
    }
}
