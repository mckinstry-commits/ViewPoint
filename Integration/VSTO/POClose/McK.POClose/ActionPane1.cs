using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace McKPOClose
{

    #region HOW TO PUBLISH
    /*
        Prod:
        b18c8e59-4f5c-42c5-afd9-794eb39e87fa
        \\mckviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McKPOClose

        Stg:
        218135B0-AA77-408F-8E32-8F0F6759AE61
        \\sestgviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McKPOClose

     * To Publish in Visual Studio:
            1.	Change Solution GUID in .csproj (GUIDs comments indicate environments)
            2.	Change Assembly Name
                o	Project Properties > Assembly Name: _________
            3.	Add Remove Programs:  
                o	Project Properties > Publish > Options > Description > Product name: _________ (e.g. McKPOClose-Stg)
            4.	SQL connection string? 
                o	Project Properties > Application > Assembly > Product: _______ (e.g. McKPOClose-Stg)
                o	For Staging, “-Stg” append to Product Name
                o	For Production, remove “-Stg”
            (see HelperData._conn_string for logic)
     */
    #endregion
    /* ***************************************************************************************************************;
                                                                                                                    
                                             McKinstry McKPOClose                                                   
                                                                                                                      
                                            copyright McKinstry 2017                                                
                                                                                                                    
        This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate closing          
        POs within Vista by Viewpoint.  This software is the property of McKinstry and                              
        requires express written permission to be used by any Non-McKinstry employee or entity                      
                                                                                                                    
        Release                      Date                     Details                                               
        1.0 Initial Development      12/29/2016               Prototype Dev:      Leo Gurdian                       
                                                              Viewpoint/SQL Dev:  Arun Thomas / Jonathan Ziebell    
                                                              Project Manager:    Jean Nichols                      
                                                              Excel VSTO Dev:     Leo Gurdian                       
                                                              Viewpoint/WIP Dev:  Arun Thomas                       
                                                                                                                    
        1.0.1 sql timeout            1/05/2017                added 10 min SQL command time out to allow processing 
                                                                                                                    
        1.0.1.1 flavor apps          1/19/2017                Support side-by-side installation w/out collision of staging vs. production  
                                                              1 code base for Prod and Staging                                            
                                                              2 GUIDs in csproj - Prod | Stg                                              
                                                                                                                                          
        1.0.1.2 small change         2/13/2017                Trng version deployed                                                       
        1.0.1.3 small change         3/21/2017                Limit Co list only to what user has access to Template cloning for new batches                                    
                                                              -Trng sql conn string changed to MCKSQLTEST01                               
        1.0.1.3 small change         4/19/2017                Add new UPGRADE environment flavor version / baseline template
        1.0.2.0 small change         10/25/2019         convert VSTO design to "Drop-down menu" environment selection
    //************************************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        public static System.Configuration.AppSettingsReader _config => new System.Configuration.AppSettingsReader();

        internal List<dynamic> _lstCompanies; // to fill _dictCompany
        internal Dictionary<dynamic, dynamic> _dictCompany = new Dictionary<dynamic, dynamic>(); // combobox source
        public Excel.Worksheet _ws = null;
        internal static string POsheet { get => "PO Close"; }

        private uint? batchId;
        private char closeType;
        private string Month { get; set; }
        private byte _jcco;
        private bool success = false;
        private int lastRow;

        //setting JCCo also sets cboMonth with corresponding months
        public byte JCCo
        {
            get => _jcco;
            set
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

                cboCloseType.Items.Add("C - Close");
                cboCloseType.SelectedIndex = 0;

            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
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

            if (cboCompany.SelectedIndex == -1) {  errorProvider1.SetError(cboCompany, "Select a Company from the list"); return; }

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

            if (cboMonth.SelectedIndex != -1) Month = (string)cboMonth.SelectedItem;
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
        private void cboBoxes_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
            e.DrawFocusRectangle();
        }
        private void cboBoxes_DrawItem1(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow;
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

                if (POsClose())
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
                        Globals.ThisWorkbook._myActionPane._ws.Unprotect(HelperUI.pwd);
                        Globals.ThisWorkbook._myActionPane._ws.get_Range("A2:A" + Globals.ThisWorkbook._myActionPane._ws.Cells.Rows.Count).Interior.Color = HelperUI.GrayDarkColor;
                        Globals.ThisWorkbook._myActionPane._ws.Cells.Locked = true;
                        HelperUI.ProtectSheet(Globals.ThisWorkbook._myActionPane._ws);
                    }
                    catch (Exception) { throw; }
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

        private bool POsClose()
        {
            try
            {
                lastRow = _ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                dynamic POs = _ws.get_Range("A2:A" + lastRow).Value2;

                if (POs == null)
                {
                    _ws.get_Range("A2").Select();
                    throw new Exception("Input POs in the yellow area");
                }

                // 1. create batch
                batchId = CloseBatch.MCKspPOCloseBatch(JCCo, Month, closeType);
                if (batchId == 0) throw new Exception("Failed to create batch");

                lblBatch.Text = batchId.ToString();

                // 2. POs insert into batch
                List<string> failedPOs = CloseInsert.MCKspPOCloseInsert(JCCo, Month, closeType, batchId, POs);
                if (failedPOs?.Count > 0)
                {
                    string msg = "Failed inserting PO(s):\n";
                    Exception ex = new Exception();
                    ex.Data[0] = msg + new string('-', msg.Length - 2) + "\n";
                    ex.Data[1] = failedPOs;
                    throw ex;
                }

                // 3. process the batch
                uint? recordsProccessed = CloseProcess.MCKspPOCloseProcess(JCCo, Month, closeType, batchId);

                lblRecordCnt.Text = recordsProccessed.ToString();
                success = true;
            }
            catch (Exception) { throw; }
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

                    ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[POsheet]).Delete();

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
