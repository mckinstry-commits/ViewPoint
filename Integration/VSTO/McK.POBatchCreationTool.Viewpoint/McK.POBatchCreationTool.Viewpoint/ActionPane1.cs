using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

/* Uninstall before installing different environment version */
namespace McK.POBatchCreationTool.Viewpoint
{
    /*****************************************************************************************************************;
                                                                                                                    
                                             McKinstry McK.POBatchCreationTool.Viewpoint                                                   
                                                                                                                      
                                               copyright McKinstry 2018                                                
                                                                                                                    
        This Microsoft Excel VSTO solution was developed by McKinstry in 2018 in order to faciliate bulk-loading          
        POs into Vista by Viewpoint.  This software is the property of McKinstry and                              
        requires express written permission to be used by any Non-McKinstry employee or entity                      
                                                                                                                    
        Release                  Date           Details                                               
        1.0 Initial Development  3.29.18        Prototype Dev:      Leo Gurdian                       
                                                Viewpoint/SQL Dev:  Arun Thomas / Leo Gurdian 
                                                Project Manager:    Jean Nichols                      
                                                Excel VSTO Dev:     Leo Gurdian       
                                                
        1.0.0.1     Critical    4.4.18      - convert udMCKPONumber to PO request # to insert into VP batch          
        1.0.0.2     small       4.5.18      - StagePOs err hanlding; if 1 PO fails, continue inserting rest of POs
                                            - Batch now appears in 'PO Batch Process' F4 look up (SQL flag)
                                            - Upon Batch Creation, an email notification goes to Arun, Jean, Kevin and Leo
        1.0.03      critical    12.19.2018  - valid MCK POs not passing through due to missing JCCo so removed Company JCCo=POCo condition                          
    ********************************************************************************************************************/

partial class ActionPane1 : UserControl
    {
        public Dictionary<byte, string> companyDict = new Dictionary<byte, string>();
        public Excel.Worksheet _ws = null;

        internal static string POsheet => "PO Batch Creation";

        private uint? batchId;
        private string Month { get; set; }
        private byte _jcco;
        private bool success = false;
        private int lastRow;

        // This also sets JCCo's corresponding open months
        public byte JCCo
        {
            get => _jcco; set
            {
                if (_jcco != value)
                    {
                    // only display valid months
                    cboMonth.SuspendLayout();
                    cboMonth.Enabled = true;
                    cboMonth.DataSource = JCBatchAllowedDates.GetValidMonths(value);
                    cboMonth.SelectedIndex = -1;
                    cboMonth.ResumeLayout();
                    _jcco = value;
                }
            }
        }

        public ActionPane1()
        {
            InitializeComponent();


            if (HelperData._conn_string.Contains("MCKTESTSQL05", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Text = "Dev";
            }
            else if (HelperData._conn_string.Contains("VPSTAGINGAG", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Text = "Staging";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL01", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Text = "Project";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL02", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Text = "Upgrade";
            }
            else if (HelperData._conn_string.Contains("MCKTESTSQL01", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Text = "Training";
            }
            else if (HelperData._conn_string.Contains("VIEWPOINTAG", StringComparison.OrdinalIgnoreCase))
            {
                lblEnvironment.Visible = false;
            }
            else
            {
                lblEnvironment.Text = "Unspecified";
            }

            companyDict = CompanyList.GetCompanyList();
            cboCompany.DataSource = companyDict.Select(kv => kv.Value).ToList();
            cboCompany.SelectedIndex = -1;

            cboMonth.FormatString = "MM/yyyy";

            lblVersion.Text = "v." + this.ProductVersion;
        }

        #region UI FIELD CONTROLS

        // validates panel fields
        private bool IsValidFields()
        {
            bool missingField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCompany, "Select a Company");
                missingField = true;
            }

            if (cboMonth.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboMonth, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboMonth, "Select a Month ");
                missingField = true;
            }

            if (missingField)
            {
                btnCreateBatch.Enabled = true;
                return false;
            }

            return true;
        }

        // update company
        private void cboCompany_Leave(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboCompany.SelectedIndex == -1) {  errorProvider1.SetError(cboCompany, "Select a Company from the list"); return; }

            JCCo = companyDict.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }

        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                JCCo = 0;
                cboCompany.SelectedIndex = -1;
            }
        }

        // update month
        private void cboMonth_SelectedIndexChanged(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboMonth.SelectedIndex != -1) Month = (string)cboMonth.SelectedItem;
        }

        // allow enter key invoke button
        private void btnCreateBatch_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) btnCreateBatch_Click(sender, null);
        }

        // paint font on Dropdown menus
        private void cboBoxes_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }

        #endregion


        private void btnCreateBatch_Click(object sender, EventArgs e)
        {
            btnCreateBatch.Enabled = false;
            string btnOrigText = btnCreateBatch.Text;
            btnCreateBatch.Text = "Processing...";
            Application.UseWaitCursor = true;

            try
            {

                if (!IsValidFields()) return;

                if (POLoad())
                {
                    cboCompany.DrawMode = DrawMode.Normal;
                    cboCompany.Enabled = false;

                    cboMonth.DrawMode = DrawMode.Normal;
                    cboMonth.Enabled = false;

                    btnCreateBatch.Enabled = false;

                    try
                    {
                        Globals.ThisWorkbook._myActionPane._ws.Unprotect(HelperUI.pwd);
                        Globals.ThisWorkbook._myActionPane._ws.get_Range("A2:A" + Globals.ThisWorkbook._myActionPane._ws.Cells.Rows.Count).Interior.Color = HelperUI.GrayDarkColor;
                        Globals.ThisWorkbook._myActionPane._ws.Cells.Locked = true;
                        HelperUI.ProtectSheet(Globals.ThisWorkbook._myActionPane._ws);
                    }
                    catch (Exception) { throw; }
                }
                else
                {
                    MessageBox.Show(null, "There were errors validating the batch", "Validation Failed!", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }

            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 2)
                {
                    List<string> failedPOList = (List<string>)ex.Data[1];

                    string failedPOs = failedPOList.Count <= 57 ? String.Join("\n", failedPOList) : "--too many to list--";

                    MessageBox.Show(this, ex.Data[0] + failedPOs, "Failed POs:", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                MessageBox.Show(this, ex.Message, "Failed POs:", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                Application.UseWaitCursor = false;
                if (success)
                {
                    success = false;
                    btnCreateBatch.Enabled = false;
                    btnCreateBatch.Text = "Done!";
                }
                else
                {
                    btnCreateBatch.Enabled = true;
                    btnCreateBatch.Text = btnOrigText;
                    _ws.Unprotect(HelperUI.pwd);
                }
            }
        }

        private bool POLoad()
        {
            Excel.Worksheet wsErr = null;
            Excel.ListObject xlTable = null;

            try
            {
                lastRow = _ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                dynamic POs = _ws.get_Range("A2:A" + lastRow).Value2;

                if (POs == null)
                {
                    _ws.get_Range("A2").Select();
                    throw new Exception("Input POs in the yellow area");
                }

                // 1. create VP batch
                batchId = Batch.CreateBatch(JCCo, Month);
                if (batchId == 0) throw new Exception("Failed to create batch");

                lblBatch.Text = batchId.ToString();

                // 2.Inserts POs into staging table
                List<string> failedPOs = Batch.StagePOs(JCCo, Month, batchId, POs);
                if (failedPOs?.Count > 0)
                {
                    string msg = "Failed staging POs:\n";
                    Exception ex = new Exception();
                    ex.Data[0] = msg + new string('-', msg.Length - 2) + "\n";
                    ex.Data[1] = failedPOs;
                    throw ex;
                }

                // 3. process the batch
                Batch.ValidateBatch(batchId);

                // 4. insert validated POs into VP Batch
                lblRecordCnt.Text = Batch.InsertGoodPOsIntoVPBatch(JCCo, Month, batchId).ToString();
                success = true;

                List<dynamic> table = Batch.GetPOBatchErrors(batchId);

                // display error report
                if (table.Count > 0)
                {
                    wsErr = Globals.ThisWorkbook.Sheets.Add(After: Globals.ThisWorkbook.ActiveSheet);
                    if (wsErr != null)
                    {
                        HelperUI.RenderOFF();

                        string tableName = "Failed PO Validation";
                        wsErr.get_Range("A1:I1").Merge();
                        wsErr.get_Range("A1").Formula = tableName;
                        wsErr.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                        wsErr.get_Range("A1").Font.Bold = true;
                        wsErr.get_Range("A1").Font.Name = "Calibri";
                        wsErr.get_Range("A1").EntireRow.RowHeight = 36;
                        wsErr.get_Range("A1").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        wsErr.get_Range("A1").VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                        wsErr.get_Range("A3").Activate();
                        wsErr.Name = "Batch Errors " + batchId;
                        wsErr.Activate();
                        wsErr.Application.ActiveWindow.DisplayGridlines = false;

                        xlTable = SheetBuilderDynamic.BuildTable(wsErr, table, tableName, 1);
                        xlTable.ListColumns["ErrMsg"].DataBodyRange.Interior.Color = HelperUI.RedNegColor;
                        xlTable.ListColumns["ErrMsg"].DataBodyRange.EntireColumn.AutoFit();
                        xlTable.ListColumns["BatchMth"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMYY;
                        HelperUI.MergeLabel(wsErr, "JCCo", "ErrDate", tableName, 1, 1, horizAlign: Excel.XlHAlign.xlHAlignLeft);
                    }

                    MessageBox.Show(null, "There were validation errors", "Failed POs", MessageBoxButtons.OK, MessageBoxIcon.Error);

                }
            }
            catch (Exception) { throw; }
            finally
            {
                HelperUI.RenderON();
                if (wsErr != null) Marshal.ReleaseComObject(wsErr);
                if (xlTable != null) Marshal.ReleaseComObject(xlTable);
            }
            return success;
        }

        private void btnReset_Click(object sender, EventArgs e)
        {
            _jcco = 0x0;

            lblBatch.Text = "";
            lblRecordCnt.Text = "";

            btnCreateBatch.Enabled = true;
            btnCreateBatch.Text = "Create Batch";

            cboCompany.Enabled = true;
            cboCompany.SelectedIndex = -1;
            cboCompany.DrawMode = DrawMode.OwnerDrawFixed;

            cboMonth.Enabled = true;
            cboMonth.SelectedIndex = -1;
            cboMonth.DataSource = null;
            cboMonth.DrawMode = DrawMode.OwnerDrawFixed;

            try
            {
                // clone sheet from hidden template
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.Base.Copy(after: Globals.ThisWorkbook.Sheets["Base"]);
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                Globals.ThisWorkbook.Application.DisplayAlerts = false;
                    
                    ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[POsheet]).Delete();

                    // delete error reports
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name != Globals.Base.Name && ws.Name.Contains("Batch Errors")) ws.Delete();
                    }

                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                _ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[2];
                _ws.Name = POsheet;
                _ws.Cells.Locked = true;
                _ws.get_Range("A1").EntireColumn.Locked = false;
                _ws.get_Range("A1").Locked = true;
                HelperUI.ProtectSheet(_ws);
            }
            catch (Exception) { throw; }
        }

    }
}
