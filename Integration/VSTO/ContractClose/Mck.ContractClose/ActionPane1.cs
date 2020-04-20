using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKContractClose
{
    /*****************************************************************************************************************
                                                                                                                    
                                             McKinstry ContractClose                                                
                                                                                                                      
                                            copyright McKinstry 2017                                                
                                                                                                                    
        This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate closing          
        contracts within Vista by Viewpoint.  This software is the property of McKinstry and                        
        requires express written permission to be used by any Non-McKinstry employee or entity                      
                                                                                                                    
        Release                      Date                     Details                                               
        1.0 Initial Development      12/23/2016               Prototype Dev:      Leo Gurdian                       
                                                              Viewpoint/SQL Dev:  Arun Thomas                       
                                                              Excel VSTO Dev:     Leo Gurdian                       
                                                                                                                    
        1.0.1.0 sql timeout          1/05/2017                10 min SQL command time out to allow processing       
                                                                                                                    
        1.0.1.1 flavor apps          1/19/2017                Support side-by-side installation w/out collision of staging vs. production 
                                                              1 code base for Prod and Staging                                            
                                                              2 GUIDs in csproj - Prod | Stg                                              
        1.0.1.2 small change         2/13/2017                Trng version deployed                                                       
        1.0.1.3 small change         3/25/2017                Limit Co list only to what user has access to         
                                                              Template cloning for new batches                      
                                                              -Trng sql conn string changed to MCKSQLTEST01         
        1.0.1.3 small change         4/19/2017                Add new UPGRADE environment flavor version   
        1.0.1.5 small change         10/5/2019      - updated sign certificate
                                                    - convert VSTO design to "Drop-down menu" environment selection
                                                    - published to Apple (upgrade)
    //*****************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        public static System.Configuration.AppSettingsReader _config => new System.Configuration.AppSettingsReader();

        internal List<dynamic> _lstCompanies; // to fill _dictCompany
        internal Dictionary<dynamic, dynamic> _dictCompany = new Dictionary<dynamic, dynamic>(); // combobox source
        internal Excel._Worksheet _ws = null;
        internal static string tabName { get => "Contract Close"; }

        private uint? batchId;
        private char closeType;
        private bool success = false;
        private int lastRow;

        private string Month { get; set; }
        private byte _jcco;

        //setting JCCo also sets cboMonth with corresponding months
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

            /* DEPLOY TO DEV ENVIRONMENTS */
            cboTargetEnvironment.Items.Add("Dev");
            cboTargetEnvironment.Items.Add("Staging");
            cboTargetEnvironment.Items.Add("Project");
            cboTargetEnvironment.Items.Add("Upgrade");

            /* DEPLOY TO PROD */
            //cboTargetEnvironment.Items.Add("Prod");

            try
            {

                if (cboTargetEnvironment.Items.Count > 0) cboTargetEnvironment.SelectedIndex = 0; // RefreshTargetEnvironment() is called on change

                if ((string)cboTargetEnvironment.SelectedItem == "Prod") cboTargetEnvironment.Visible = false;

                lblVersion.Text = "v." + this.ProductVersion;

                cboMonth.FormatString = "MM/yyyy";

                cboCloseType.Items.Add("S - Soft Close");
                cboCloseType.Items.Add("F - Final Close");
            }
            catch (Exception)
            {
                throw;
            }
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

            if (cboCloseType.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCloseType, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCloseType, "Select a Close Type ");
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

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetError(cboCompany, "Select a Company from the list");
                return;
            }

            JCCo = _dictCompany.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }

        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                JCCo = 0;
                cboCompany.SelectedIndex = -1;
                cboCloseType.SelectedIndex = -1;
            }
        }

        // update month
        private void cboMonth_SelectedIndexChanged(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboMonth.SelectedIndex != -1)
            {
                Month = cboMonth.SelectedItem.ToString();
            }
        }

        private void cboCloseType_SelectedIndexChanged(object sender, EventArgs e)
        {
            closeType = cboCloseType.SelectedItem != null ? cboCloseType.SelectedItem.ToString().Substring(0, 1).ToCharArray()[0] : '\0';
            errorProvider1.Clear();
        }

        // allow enter key invoke button
        private void btnCreateBatch_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) btnCreateBatch_Click(sender, null);
        }

        // paint font on Dropdown menus
        private void cboBoxes_DrawItemBlack(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }
        private void cboBoxes_DrawItemYellow(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow; // <--- only difference
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

                if (ContractClose())
                {
                    cboCompany.DrawMode = DrawMode.Normal;
                    cboCompany.Enabled = false;

                    cboMonth.DrawMode = DrawMode.Normal;
                    cboMonth.Enabled = false;

                    cboCloseType.DrawMode = DrawMode.Normal;
                    cboCloseType.Enabled = false;
                    btnCreateBatch.Enabled = false;

                    try
                    {
                        _ws.Unprotect(HelperUI.pwd);
                        _ws.get_Range("A2:A500").Interior.Color = HelperUI.GrayDarkColor;
                        _ws.Cells.Locked = true;
                        HelperUI.ProtectSheet(_ws);
                    }
                    catch (Exception) { throw; }
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 2)
                {
                    List<string> failedContractList = (List<string>)ex.Data[1];

                    string failedContracts = failedContractList.Count <= 57 ? String.Join("\n", failedContractList) : "--too many to list--";
                    
                    MessageBox.Show(this, ex.Data[0] + failedContracts, "Failed Contract(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                MessageBox.Show(this, ex.Message, "Failed Contract(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
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

        private bool ContractClose()
        {
            Excel.Worksheet ws = null;

            try
            {
                // grab the user-input range
                ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[tabName];

                lastRow = ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;

                dynamic contracts = ws.get_Range("A2:A" + lastRow).Value2;

                if (contracts == null)
                {
                    ws.get_Range("A2").Select();
                    throw new Exception("Input Contracts in the yellow area");
                }

                // 1. create batch
                batchId = CloseBatch.MCKspContractCloseBatch(JCCo, Month, closeType);
                if (batchId == 0) throw new Exception("Failed to create batch");

                lblBatch.Text = batchId.ToString();

                // 2. contracts insert into batch
                List<string> failedContracts = CloseInsert.MCKspContractCloseInsert(JCCo, Month, closeType, batchId, contracts);
                if (failedContracts?.Count > 0)
                {
                    string msg = "Failed inserting Contract(s):\n";
                    Exception ex = new Exception();
                    ex.Data[0] = msg + new string('-', msg.Length - 2) + "\n";
                    ex.Data[1] = failedContracts;
                    throw ex;
                }

                // 3. process the batch
                int recordsProccessed = CloseProcess.MCKspContractCloseProcess(JCCo, Month, closeType, batchId);

                lblRecordCnt.Text = recordsProccessed.ToString();
                success = true;
            }
            catch (Exception) { throw;}
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

            cboCloseType.Enabled = true;
            cboCloseType.SelectedIndex = -1;
            cboCloseType.DrawMode = DrawMode.OwnerDrawFixed;

            try
            {
                // clone sheet from hidden template
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.Base.Copy(after: Globals.ThisWorkbook.Sheets["Base"]);
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                Globals.ThisWorkbook.Application.DisplayAlerts = false;

                ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[3]).Delete();

                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                _ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[2];
                _ws.Name = tabName;
                _ws.Cells.Locked = true;
                _ws.get_Range("A1").EntireColumn.Locked = false;
                _ws.get_Range("A1").Locked = true;
                HelperUI.ProtectSheet(_ws);
            }
            catch (Exception) { throw; }
        }

        private void cboTargetEnvironment_SelectedIndexChanged(object sender, EventArgs e) => RefreshTargetEnvironment();

        private void RefreshTargetEnvironment()
        {
            string environ = (string)cboTargetEnvironment.SelectedItem;

            try
            {
                switch (environ)
                {
                    case "Dev":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionDev");
                        break;
                    case "Staging":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionStg");
                        break;
                    case "Project":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionProj");
                        break;
                    case "Upgrade":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionUpg");
                        break;
                    case "Prod":
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionProd");
                        break;
                    default:
                        HelperData.AddUpdateAppSettings(HelperData.TargetEnvironment, "ViewpointConnectionDev");
                        break;
                }

                _lstCompanies = Companies.GetCompanyList();
                _dictCompany = _lstCompanies.ToDictionary(n => n.HQCo, n => n.CompanyName);

                cboCompany.DataSource = _dictCompany.Select(kv => kv.Value).ToList();

                if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;
                cboCompany_Leave(null, null);

                //if (Globals.ThisWorkbook != null) Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = environ;
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }

        }

    }
}
