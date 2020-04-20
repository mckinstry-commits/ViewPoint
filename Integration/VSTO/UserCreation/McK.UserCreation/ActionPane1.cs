using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McKinstry.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace McKUserCreation
{
    #region HOW TO PUBLISH
    /*
        Prod:
        E4155FF1-6204-49A5-BD94-82E01D4B1F23
        \\mckviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McKUserCreation

        Stg:
        A9E0A303-D3AF-464D-B454-7F061837E1AF
        \\sestgviewpoint\Viewpoint Repository\Reports\Custom\TrustedAPP\VSTO\McKUserCreation
    */
    #endregion
    //*****************************************************************************************************************;
    //                                                                                                                *;
    //                                         McKinstry McKUserCreation                                              *;
    //                                                                                                                *;  
    //                                        copyright McKinstry 2017                                                *;
    //                                                                                                                *;
    //    This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate creating        *; 
    //    Users within Vista by Viewpoint.  This software is the property of McKinstry and                            *;
    //    requires express written permission to be used by any Non-McKinstry employee or entity                      *;
    //                                                                                                                *;
    //    Release                      Date                     Details                                               *;
    //    1.0 Initial Development      12/30/2016               Prototype Dev:      Leo Gurdian                       *;
    //                                                          Viewpoint/SQL Dev:  Arun Thomas                       *;
    //                                                          Project Manager:    Jean Nichols                      *;
    //                                                          Excel VSTO Dev:     Leo Gurdian                       *;____________________
    //                                                                                                                                      *;
    //    1.0.1.0 sql timeout          1/05/2017                added 10 min SQL command time out to allow processing                       *;
    //                                                                                                                                      *;
    //    1.0.1.1 flavor apps          1/19/2017                Support side-by-side installation w/out collision of staging vs. production *; 
    //                                                          1 code base for Prod and Staging                                            *;
    //                                                          2 GUIDs in csproj - Prod | Stg                                              *;
    //    1.0.1.1 small chng           2/13/2017                Trng version deployed                                                       *;
    //    1.0.1.2 structure            3/9/2017                 - Fixed AP/AR text in dropdown                                              *;
    //                                                          - Smarter more flexible capture of missing fields on occupied rows          *;
    //                                                          - Reset clearing is faster due to cloning from hidden template rather       *;
    //                                                            than sheet/cells manipulation, formatting, etc.                           *;
    //                                                          - hostitem namespace is now correctly referencing "McKUserCreation"         *;
    //***************************************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        public Dictionary<byte, string> companyDict = new Dictionary<byte, string>();

        public Excel.Range _rng { get; set; }

        public byte @switch = 0x0;
        private int blinkCounter = 0;

        private uint? batchId;
        private string role;
        private byte JCCo;
        private bool success = false;
        private int lastRow;

        public ActionPane1()
        {
            InitializeComponent();

            HelperData.AppName = this.ProductName;

            if (this.ProductName.Contains("-Stg"))
            {
                lblAppName.Text = "(Staging)";
            }
            else if (this.ProductName.Contains("-Trng"))
            {
                lblAppName.Text = "(Training)";
            }
            else
            {
                lblAppName.Text = "(Prod.)";
            }

            companyDict = CompanyList.GetCompanyList();
            cboCompany.DataSource = companyDict.Select(kv => kv.Value).ToList();
            cboCompany.SelectedIndex = -1;

            cboRole.Items.Add("PM - Project Mgmt");
            cboRole.Items.Add("AR - Accounts Receivables");
            cboRole.Items.Add("AP - Accounts Payable");
            cboRole.Items.Add("PR - Payroll");
            cboRole.Items.Add("GL - General Ledger");
            cboRole.Items.Add("SM - Service Mgmt");
            cboRole.Items.Add("SL - Subcontract Mgmt");
            cboRole.Items.Add("PO - Purchase Order Mgmt");
            cboRole.Items.Add("VT - Validation Team");
            cboRole.Items.Add("HD - Help Desk");

            lblVersion.Text = "v." + this.ProductVersion;

        }


        #region UI FIELD CONTROLS

        // validates contract, if so sets JCCo, Contract
        private bool IsValidFields()
        {
            bool missingField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);

                errorProvider1.SetError(cboCompany, "Select a Company");
                missingField = true;
            }

            if (cboRole.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboRole, ErrorIconAlignment.MiddleLeft);

                errorProvider1.SetError(cboRole, "Select a Role");
                missingField = true;
            }

            if (missingField)
            {
                btnPostUsers.Enabled = true;
                return false;
            }

            return true;
        }

        // update company
        private void cboCompany_Leave(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboCompany.SelectedIndex == -1) { errorProvider1.SetError(cboCompany, "Select a Company from the list"); return; }

            JCCo = companyDict.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }   

        // delete key press clears comboboxes
        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                JCCo = 0;
                cboCompany.SelectedIndex = -1;
                cboRole.SelectedIndex = -1;
            }
        }

        private void cboCloseType_SelectedIndexChanged(object sender, EventArgs e)
        {
            role = cboRole.SelectedItem != null ? cboRole.SelectedItem.ToString().Substring(0, 2) : null;
            errorProvider1.Clear();
        }

        // allow enter key invoke button
        private void btnPostUsers_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter) btnPostUsers_Click(sender, null);
            
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


        private void btnPostUsers_Click(object sender, EventArgs e)
        {
            btnPostUsers.Enabled = false;
            string btnOrigText = btnPostUsers.Text;
            btnPostUsers.Text = "Processing...";
            Application.UseWaitCursor = true;

            try
            {
                if (!IsValidFields()) return;

                if (PostUsers())
                {
                    cboCompany.DrawMode = DrawMode.Normal;
                    cboCompany.Enabled = false;

                    cboRole.DrawMode = DrawMode.Normal;
                    cboRole.Enabled = false;
                    btnPostUsers.Enabled = false;

                    try
                    {
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[2]).Unprotect(HelperUI.pwd);
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[2]).get_Range("A2:D" + ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[2]).Cells.Rows.Count).Interior.Color = HelperUI.GrayDarkColor;
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[2]).Cells.Locked = true;
                        HelperUI.ProtectSheet(Globals.ThisWorkbook.Application.Sheets["UserPost"]);
                    }
                    catch (Exception) { throw; }
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 2)
                {
                    List<string[]> failedUsersList = (List<string[]>)ex.Data[1];

                    System.Text.StringBuilder failedUsers = new System.Text.StringBuilder();

                    if (failedUsersList.Count <= 57)
                    {
                        for (int i = 0; i <= failedUsersList.Count - 1; i++)
                        {
                            string row = String.Join("\t", failedUsersList[i],0,3);
                            failedUsers.AppendLine(row);
                        }
                    }
                    else
                    {
                        failedUsers.Append("--too many to list--");
                    }

                    MessageBox.Show(this, ex.Data[0] + failedUsers.ToString(), "Failed User(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                MessageBox.Show(this, ex.Message, "Failed User(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                Application.UseWaitCursor = false;
                if (success)
                {
                    success = false;
                    btnPostUsers.Enabled = false;
                    btnPostUsers.Text = "Done!";
                }
                else
                {
                    btnPostUsers.Enabled = true;
                    btnPostUsers.Text = btnOrigText;
                    ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[2]).Unprotect(HelperUI.pwd);
                }
            }
        }
        // you could easily modify this code to handle 3D arrays, etc.

        private bool PostUsers()
        {
            Excel.Range userInputRows = null;
            Excel.Worksheet ws = null;
            List<uint> occupiedRowIndices;

            try
            {
                // grab the user-input range
                ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[2];

                lastRow           = ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                userInputRows     = ws.get_Range("A2:D" + lastRow);
                object[,] _userRows = null;

                // is there any user-input data?
                _rng = userInputRows.Find("*", Type.Missing,
                                        Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                        Type.Missing, Type.Missing);
                if (_rng != null)
                {
                    // check user-input for missing fields
                    _userRows = userInputRows.Value2;
                    _rng = _userRows.GetExcelMissingField_FromOccupiedRowsOnly(ws, out occupiedRowIndices);
                    
                    if (_rng != null)
                    {
                        // there are missing fields
                        _rng.Select();
                        tmrAlertCell.Enabled = true;
                        throw new Exception("Please enter data in the required field");
                    }
                }
                else //no data 
                {
                    userInputRows.Select();
                    _rng = ws.get_Range("A2:D" + lastRow);
                    tmrAlertCell.Enabled = true;
                    return false;
                }

                // 1. create user batch
                batchId = UserCreationBatch.MCKspVPUserCreationBatch(JCCo, role);
                if (batchId == 0) throw new Exception("Failed to create batch");

                lblBatch.Text = batchId.ToString();

                // 2. insert users into batch
                List<string[]> failedUsers = UserInsert.MCKspUserCreationInsert(JCCo, role, batchId, _userRows, occupiedRowIndices);
                if (failedUsers.Count > 0)
                {
                    string msg = "Failed inserting User(s):\n";
                    Exception ex = new Exception();
                    ex.Data[0] = msg + new string('-', msg.Length - 2) + "\n";
                    ex.Data[1] = failedUsers;
                    throw ex;
                }

                // 3. process the batch
                uint? recordsProccessed = UserCreationProcess.MCKspVPUserCreationProcess(JCCo, batchId);

                lblRecordCnt.Text = recordsProccessed.ToString();
                success = true;
            }
            catch (Exception) { throw; }
            finally
            {
                if (userInputRows != null) Marshal.ReleaseComObject(userInputRows); userInputRows = null;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
            return success;
        }

        /// <summary>
        /// Make sure there's data in all fields.  No nulls or blanks allowed on occupied rows.
        /// </summary>
        /// <param name="users"></param>
        private void btnReset_Click(object sender, EventArgs e)
        {
            JCCo = 0x0;

            lblBatch.Text = "";
            lblRecordCnt.Text = "";

            btnPostUsers.Text = "Post";
            cboCompany.Enabled = true;
            cboCompany.SelectedIndex = -1;
            cboCompany.DrawMode = DrawMode.OwnerDrawFixed;

            cboRole.Enabled = true;
            cboRole.SelectedIndex = -1;
            cboRole.DrawMode = DrawMode.OwnerDrawFixed;

            btnPostUsers.Enabled = true;
            Excel._Worksheet ws = null;

            try
            {
                // clone sheet from hidden template
                Globals.Sheet2.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.Sheet2.Copy(after: Globals.ThisWorkbook.Sheets["UserPostx"]);
                Globals.Sheet2.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                Globals.ThisWorkbook.Application.DisplayAlerts = false;

                    ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[3]).Delete();

                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[2];
                ws.Name = "UserPost";
                ws.Cells.Locked = true;
                ws.get_Range("A1:D1").EntireColumn.Locked = false;
                ws.get_Range("A1:D1").Locked = true;
                HelperUI.ProtectSheet(ws);
            }
            catch (Exception) { throw; }
            finally
            {
                if (_rng != null) Marshal.ReleaseComObject(_rng); _rng = null;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        /// <summary>
        /// Flash missing field
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void tmrAlertCell_Tick(object sender, EventArgs e)
        {
            try
            {
                if (blinkCounter <= 4)
                {
                    if (@switch == 0x0)
                    {
                        _rng.Interior.Color = HelperUI.RedColor;
                        blinkCounter++;
                        @switch = 0x1;
                        return;
                    }

                    _rng.Interior.Color = HelperUI.DataEntryColor;
                    blinkCounter++;
                    @switch = 0x0;
                }
                else
                {
                    tmrAlertCell.Enabled = false;
                    blinkCounter = 0;
                    _rng.Activate();
                }
            }
            catch (Exception) {
                blinkCounter = 0;
                tmrAlertCell.Enabled = false;
            }
        }
    }
}
