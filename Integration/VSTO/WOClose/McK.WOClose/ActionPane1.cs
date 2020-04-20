using System;
using System.Collections.Generic;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using System.Data;
using System.Linq;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace McKWOClose
{

    #region HOW TO PUBLISH
    /*
      To Publish in Visual Studio:
            1.	Change Solution GUID in .csproj (GUIDs comments indicate environments)
            2.	Change Assembly Name
                o	Project Properties > Application > Assembly Name: _________
            3.	Add Remove Programs:  
                o	Project Properties > Publish > Options > Description > Product name: _________ (e.g. McKPOClose-Stg)
            4.	SQL connection string? 
                o	Project Properties > Application > Assembly Information> Product: _______ (e.g. McKPOClose-Stg)
                o	For Staging, “-Stg” append to Product Name
                o	For Production, remove “-Stg”
            (see HelperData._conn_string for logic)
    */
    #endregion

    /****************************************************************************************************************
                                             McKinstry McKWOClose                                                   
                                            Copyright McKinstry 2018                                                
                                                                                                                    
        This Microsoft Excel VSTO solution was developed by McKinstry in 2016 in order to faciliate closing          
        WOs within Vista by Viewpoint.  This software is the property of McKinstry and                              
        requires express written permission to be used by any Non-McKinstry employee or entity                      
                                                                                                                    
        Release                      Date                     Details                                               
        1.0 Initial Development      12/29/2016               Prototype Dev:      Leo Gurdian                       
                                                              Viewpoint/SQL Dev:  Arun Thomas                       
                                                              Project Manager:    Jean Nichols                      
                                                              Excel VSTO Dev:     Leo Gurdian                       
                                                              Viewpoint/WIP Dev:  Arun Thomas                       
                                                                                                                    
        1.0.0 sql timeout            1/05/2017                added 10 min SQL command time out to allow processing 
                                                                                                                    
        1.0.1.1 small change         1/19/2017                SQL connect string based off ProductName Prod|Staging 
                                                              1 code base for Prod and Staging                      
                                                              2 GUIDs in csproj - Prod | Staging                    
                                                                                                                    
        1.0.1.2 small change         2/8/2017                  Change button text to "Post Batch"                   
                                                                                                                    
                                                              2 GUIDs in csproj - Prod | Stg                        
        1.0.1.2 small change         2/13/2017                Trng version deployed                                 
                                                                                                                    
        1.0.1.3 small change         3/25/2017                Limit Co list only to what user has access to         
                                                              Template cloning for new batches                      
                                                              -Trng sql conn string changed to MCKSQLTEST01         
        1.0.1.4 small change         4/19/2017                Add new UPGRADE environment version
                                                              baseline template      
        1.0.1.5 med change          03/26/2019      BUG fix: "Cannot implicitly convert type 'double' to object[*,*]'
                                                    NEW error report - let's user know why it failed
    ****************************************************************************************************************/

    partial class ActionPane1 : UserControl
    {
        public static System.Configuration.AppSettingsReader _config => new System.Configuration.AppSettingsReader();

        public Dictionary<byte, string> companyDict = new Dictionary<byte, string>();
        public Excel.Worksheet _ws = null;
        public static string WOsheet => "WO Close";

        private string batchId;
        private char closeType;
        private string Month { get; set; }
        private byte _jcco;
        private bool success = false;
        private int lastRow;

        private List<dynamic> _tblErrors = null;

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

            #region ENVIRONMENTS CONNECTION STRING
            // App name sets data layer connection string
            if (ProductName.Contains("-Stg", StringComparison.OrdinalIgnoreCase))
            {
                HelperData._conn_string = (string)_config.GetValue("ViewpointConnectionStg", typeof(string));
                lblAppName.Text = "(Staging)";
            }
            else if (ProductName.Contains("-Proj", StringComparison.OrdinalIgnoreCase))
            {
                HelperData._conn_string = (string)_config.GetValue("ViewpointConnectionProj", typeof(string));
                lblAppName.Text = "(Project)";
            }
            else if (ProductName.Contains("-Upg", StringComparison.OrdinalIgnoreCase))
            {
                HelperData._conn_string = (string)_config.GetValue("ViewpointConnectionUpg", typeof(string));
                lblAppName.Text = "(Upgrade)";
            }
            else if (ProductName.Contains("-Trng", StringComparison.OrdinalIgnoreCase))
            {
                HelperData._conn_string = (string)_config.GetValue("ViewpointConnectionTrng", typeof(string));
                lblAppName.Text = "(Training)";
            }
            else
            {
                HelperData._conn_string = (string)_config.GetValue("ViewpointConnectionProd", typeof(string));
                lblAppName.Visible = false;
            }
            #endregion

            companyDict = CompanyList.GetCompanyList();
            cboCompany.DataSource = companyDict?.Select(kv => kv.Value).ToList();
            cboCompany.SelectedIndex = -1;

            cboMonth.FormatString = "MM/yyyy";

            cboCloseType.Items.Add("C - Close");
            cboCloseType.SelectedIndex = 0;

            lblVersion.Text = "v." + this.ProductVersion;
        }


        #region UI FIELD CONTROLS

        // validates panel fields
        private bool isValidFields()
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
                btnPostBatch.Enabled = true;
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

            JCCo = companyDict.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
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
            if (e.KeyValue == (char)Keys.Enter) btnPostBatch_Click(sender, null);
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


        private void btnPostBatch_Click(object sender, EventArgs e)
        {
            btnPostBatch.Enabled = false;
            string btnOrigText = btnPostBatch.Text;
            btnPostBatch.Text = "Processing...";
            btnPostBatch.Refresh();
            Application.UseWaitCursor = true;

            try
            {
                if (!isValidFields()) return;

                if (WOsClose())
                {
                    cboCompany.DrawMode = DrawMode.Normal;
                    cboCompany.Enabled = false;

                    cboMonth.DrawMode = DrawMode.Normal;
                    cboMonth.Enabled = false;

                    cboCloseType.DrawMode = DrawMode.Normal;
                    cboCloseType.Enabled = false;
                    btnPostBatch.Enabled = false;

                    try
                    {
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[WOsheet]).Unprotect(HelperUI.pwd);
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[WOsheet]).get_Range("A2:A500" ).Interior.Color = HelperUI.GrayDarkColor;
                        ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[WOsheet]).Cells.Locked = true;
                        HelperUI.ProtectSheet(Globals.ThisWorkbook.Sheets[WOsheet]);
                    }
                    catch (Exception) { throw; }
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 2)
                {
                    List<string> failedWOList = (List<string>)ex.Data[1];
                    string failedWOs = "";
                    if (failedWOList.Count <= 57)
                    {
                        failedWOs = String.Join("\n", failedWOList);
                    }
                    MessageBox.Show(this, ex.Data[0] + failedWOs, "Failed WO(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                MessageBox.Show(this, ex.Message, "Failed WO(s):", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                Application.UseWaitCursor = false;
                if (success)
                {
                    success = false;
                    btnPostBatch.Enabled = false;
                    btnPostBatch.Text = "Done!";
                }
                else
                {
                    btnPostBatch.Enabled = true;
                    btnPostBatch.Text = btnOrigText;
                    ((Excel.Worksheet)Globals.ThisWorkbook.Sheets[WOsheet]).Unprotect(HelperUI.pwd);
                }
            }
        }

        private bool WOsClose()
        {
            try
            {
                // grab the user-input range
                lastRow = _ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                dynamic WOs = _ws.get_Range("A2:A" + lastRow).Value2;

                if (WOs == null)
                {
                    _ws.get_Range("A2").Select();
                    throw new Exception("Input WOs in the yellow area");
                }

                // 1. insert WOs into batch
                CloseInsert.MCKspWOCloseInsert(JCCo, Month, WOs);

                // 2. process the batch
                _tblErrors = ProcessBatch.MCKspWOCloseProcess(JCCo, Month);

                // 3. get batch number 
                lblBatch.Text = batchId = Batch.GetLastBatchNum();

                int errCnt = 0;
                int totalCnt = 0;

                if (_tblErrors?.Count > 0)
                {
                    ShowValidationErrReports(_tblErrors);
                    errCnt = _tblErrors.Count();
                }

                if (WOs.GetType() == typeof(Object[,]))
                {
                    totalCnt = WOs.GetUpperBound(0); // multiple WOs
                }
                else
                {
                    totalCnt = 1;
                }

                int recordsPassed = totalCnt - errCnt;

                lblRecordCnt.Text = recordsPassed.ToString() + '/'+ totalCnt;
                success = true;
            }
            catch (Exception ex) { ShowErr(ex); }
            return success;
        }

        private void btnReset_Click(object sender, EventArgs e)
        {
            _jcco = 0x0;

            lblBatch.Text = "";
            lblRecordCnt.Text = "";

            btnPostBatch.Enabled = true;
            btnPostBatch.Text = "Post Batch";

            cboCompany.Enabled = true;
            cboCompany.SelectedIndex = -1;
            cboCompany.DrawMode = DrawMode.OwnerDrawFixed;

            cboMonth.Enabled = true;
            cboMonth.SelectedIndex = -1;
            cboMonth.DataSource = null;
            cboMonth.DrawMode = DrawMode.OwnerDrawFixed;

            cboCloseType.Enabled = true;
            cboCloseType.SelectedIndex = 0;
            cboCloseType.DrawMode = DrawMode.OwnerDrawFixed;



            try
            {

                lastRow = _ws.get_Range("A1").SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                if (lastRow == 0) return;

                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVisible;

                Globals.ThisWorkbook.Application.DisplayAlerts = false;

                // delete error reports
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws.Name != Globals.Base.Name // "Base"
                        && ws.Name.Contains("Batch Errors") 
                        || ws.Name == WOsheet)
                        ws.Delete();
                }

                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                // clone sheet from hidden template
                Globals.Base.Copy(after: Globals.ThisWorkbook.Sheets[Globals.Base.Index]);
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                RenameProtectNewSheet();
            }
            catch (Exception ex) { ShowErr(ex); }
        }

        internal void RenameProtectNewSheet()
        {
            try
            {
                _ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.Base.Index + 1];
                _ws.Name = WOsheet;
                _ws.Cells.Locked = true;
                _ws.get_Range("A1").EntireColumn.Locked = false;
                _ws.get_Range("A1").Locked = true;
                HelperUI.ProtectSheet(_ws);
            }
            catch (Exception) { throw; }
        }

        private void ShowValidationErrReports(List<dynamic> tblerrors)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xltable = null;
            string tabName = "Batch Errors " + batchId;

            try
            {
                HelperUI.DeleteSheet(tabName);

                HelperUI.RenderOFF();

                Globals.ThisWorkbook.Sheets.Add(After: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                ws.get_Range("A1:G1").Merge();
                ws.get_Range("A1").Formula = tabName;
                ws.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                ws.get_Range("A1").Font.Bold = true;
                ws.get_Range("A1").Font.Name = "Calibri";
                ws.get_Range("A1").EntireRow.RowHeight = 36;
                ws.get_Range("A1").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                ws.get_Range("A1").VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                ws.get_Range("A3").Activate();
                ws.Name = tabName;
                ws.Application.ActiveWindow.DisplayGridlines = false;

                xltable = SheetBuilderDynamic.BuildTable(ws, tblerrors, "tblErrors", 1);
                xltable.ListColumns["Errmsg"].DataBodyRange.Interior.Color = HelperUI.RedNegColor;
                xltable.ListColumns["Errmsg"].DataBodyRange.EntireColumn.AutoFit();
                xltable.ListColumns["ErrDate"].DataBodyRange.EntireColumn.AutoFit();
                xltable.ListColumns["ErrDate"].DataBodyRange.EntireColumn.AutoFit();
                xltable.ListColumns["CloseStatus"].DataBodyRange.EntireColumn.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["CloseStatus"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                xltable.ListColumns["CloseStatus"].DataBodyRange.EntireColumn.AutoFit();
                HelperUI.MergeLabel(ws, "SMCo", "Errmsg", "Failed Processing Batch " + batchId, 1, 1, horizAlign: Excel.XlHAlign.xlHAlignLeft);

            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "ShowValidationErrReports");
                ShowErr(ex);
            }
            finally
            {
                HelperUI.RenderON();
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                if (xltable != null) Marshal.ReleaseComObject(xltable); xltable = null;
            }
            
        }

        private void ShowErr(Exception ex) => MessageBox.Show(ex.Message);
    }
}
