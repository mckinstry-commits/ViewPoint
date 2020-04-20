using System;
using System.Windows.Forms;
using McKinstry.Data.Viewpoint;
//using Mckinstry.VSTO;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKinstry.ETC.Template
{
    public partial class ControlSheet
    {
        internal string OpenBatchesStartCol { get; set; }
        internal string OpenBatchesEndCol { get; set; }

        private void Sheet1_Startup(object sender, System.EventArgs e)
        {
            try
            {
                Globals.ThisWorkbook._myActionPane._control_ws = HelperUI.GetSheet(ETCOverviewActionPane.controlSheet);

                this.Names.Item("ViewpointLogin").RefersToRange.Value = Globals.ThisWorkbook._myActionPane.Login = UserProfile.GetVPUserName(null, null);

                //Stopwatch t2 = new Stopwatch(); t2.Start();

                this.Names.Item("TimeOpening").RefersToRange.Value = HelperUI.DateTimeShortAMPM;

                this.Cells[3, 3].Font.Size = 26;

                if (Data.Viewpoint.HelperData._conn_string == "Server=VPSTAGINGAG\\VIEWPOINT;Database=Viewpoint;Trusted_Connection=True;")
                {
                    this.Cells[3, 3].Value = "Viewpoint Staging";
                    this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                    this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                }
                if (Data.Viewpoint.HelperData._conn_string.Contains("MCKTESTSQL05"))
                {
                    this.Cells[3, 3].Value = "Viewpoint DEV";
                    this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                    this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                }
                if (Data.Viewpoint.HelperData._conn_string.Contains("ViewpointTraining"))
                {
                    this.Cells[3, 3].Value = "Viewpoint Training";
                    this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                    this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                }
                if (Data.Viewpoint.HelperData._conn_string.Contains("SEA-STGSQL02"))
                {
                    this.Cells[3, 3].Value = "Upgrade Dev";
                    this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                    this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                }
                if (Data.Viewpoint.HelperData._conn_string.Contains("SEA-STGSQL01"))
                {
                    this.Cells[3, 3].Value = "Project Stk";
                    this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                    this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                }

                // Start / end column A1 style used for 'My Open Batches'
                OpenBatches.OpenBatchesRowOffset = this.Names.Item("ContractNumber").RefersToRange.Row;
                string colStart = this.Names.Item("RevJectContract").RefersToRange.AddressLocal;
                OpenBatchesStartCol = colStart.Split('$')[1];

                colStart = this.Names.Item("RevJectType").RefersToRange.AddressLocal;
                OpenBatchesEndCol = colStart.Split('$')[1];

                this.Cells.Locked = true;
                HelperUI.ProtectSheet(Globals.ControlSheet.InnerObject, false, false);
                this.Activate();

            }
            catch (Exception)
            {
                throw;
            }

            //Globals.ThisWorkbook._myActionPane.t2.Stop(); MessageBox.Show(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", Globals.ThisWorkbook._myActionPane.t2.Elapsed.ToString()));
        }

        private void Sheet1_Shutdown(object sender, System.EventArgs e) { }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.btnToggleActionPane.Click += new System.EventHandler(this.btnToggleActionPane_Click);
            this.Startup += new System.EventHandler(this.Sheet1_Startup);
            this.Shutdown += new System.EventHandler(this.Sheet1_Shutdown);

        }

        #endregion


        private void btnToggleActionPane_Click(object sender, EventArgs e)
        {
            try
            {
                this.Application.DisplayDocumentActionTaskPane = true;
            }
            catch (Exception) { }; //let it go
        }

        internal void btnCancel_Click(object sender, EventArgs e)
        {
            Button btn = sender as Button;
            int row = (int)btn.Tag; // row it's on
            bool success = false;

            // get from Excel
            string batchID = get_Range("I" + row).Formula;
            uint batchid = uint.Parse(batchID);

            OpenBatches.HighlightBatchRow(batchid);

            DialogResult r = MessageBox.Show("Are you sure you want to cancel batch " + batchID + "?", "Cancel Batch", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

            if (r == DialogResult.Yes)
            {
                try
                {
                    // get batch from memory to avoid slow COM calls
                    Data.Models.Viewpoint.Batch batch = OpenBatches.MyOpenBatches.Find(b => b.BatchId == batchid);

                    // for logging only
                    string login = Globals.ThisWorkbook._myActionPane.Login;
                    string job = batch.ContractOrJob;
                    string contract = HelperUI.JobTrimDash(job);

                    if (batch.Type == "Cost")
                    {
                        // if batch is open in Excel, also deletes associated batch sheets
                        if (Globals.ThisWorkbook._myActionPane.CostBatchId == batchid)
                        {
                            Globals.ThisWorkbook._myActionPane.btnCancelCostBatch_Click(sender, e, false); // repurpose
                            success = true;
                        }
                        else
                        {
                            success = OpenBatches.CancelCostBatch(batch.JCCo, batch.ProjectionMonth, batch.BatchId, login, contract, job);
                        }
                    }
                    else
                    if (batch.Type == "Revenue")
                    {
                        if (Globals.ThisWorkbook._myActionPane.RevBatchId == batchid)
                        {
                            Globals.ThisWorkbook._myActionPane.btnCancelRevBatch_Click(sender, e, false);
                            success = true;
                        }
                        else
                        {
                            success = OpenBatches.CancelRevBatch(batch.JCCo, batch.ProjectionMonth, batch.BatchId, login, contract, job);
                        }
                    }

                    if (success) 
                    {
                        // refresh the grid and buttons
                        OpenBatches.RefreshOpenBatchesUI();
                    }
                }
                catch (Exception ex)
                {
                    Globals.ThisWorkbook._myActionPane.ShowErr(ex);
                }
            }
            else
            {
                OpenBatches.HighlightBatchRow(0);
            }
        }
    }
}
