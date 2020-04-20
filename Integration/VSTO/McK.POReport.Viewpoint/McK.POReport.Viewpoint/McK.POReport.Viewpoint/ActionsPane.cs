using McK.Data.Viewpoint;
using System;
using System.Collections.Generic;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using Outlook = Microsoft.Office.Interop.Outlook;
using System.Runtime.InteropServices;
using System.Linq;
using Mck.Data.Viewpoint;
using System.Dynamic;
using System.IO;

namespace McK.POReport.Viewpoint
{
    /*****************************************************************************************************************;
                                         McKinstry Detailed Progress PO Report                          
                                            copyright McKinstry 2017                                                

    Pulls invoices grouped together from JC Contract Items (JCCI).  

    AUTHORS:
    Prototype Excel VSTO:   Leo Gurdian                      
    Viewpoint/SQL Dev:      Leo Gurdian                           
    Project Manager:        Jean Nichols                

    DEPENDENCY:             MCKspPOReport

    Release                  Publish Date       Details                                              
    -------                  ------------           -------                                             
    1.0.0.0                  1.23.2018              - Alpha prototype;
                                                       FEATURES:
                                                        Produces a single or range of POs
                                                        Printer friendly
                                                        Header w/ logo
                                                        Detail Rows
                                                        Totals; formulas                                                          
                                                        Save offline 
                                                        Send via Email as PDF
    1.0.0.1                 1.31.2018           + Logo
                                                + Order Date range search
                                                + Vendor # ( Supplier # ) 
                                                + Email extract from ATTN field into sep. field
                                                + Phone extract from ATTN field into sep. field
                                                + Printer Page Setup (if no printer, app still usable)
    1.0.0.2                 2.13.2018           + Refresh Existing PO Worksheet(s) button
                                                    - Prompt "What would you like to refresh?" 
                                                        - External McK POs ** BULK REFRESH SUPPORTED ** 
                                                        - Currently loaded PO
                                                    - McK PO template validation
                                                    - Error handling
                                                + Show all Note's content w/ carriage returns or long continuous text
    1.0.0.3                 2.14.2018           Copy offline bug fix (log write). 
                                                Template:
                                                    - print setup 
                                                        - show header in all pages
                                                        - fit all columns in 1 page
                                                    - Merge input fields
   1.0.0.4                  2.19.2018           Template reduced from 41MB to 360KB!!!
                                                Note_POHD added
                                                Project Phase Code column expanded
                                                Rename PDF to "PO" #
                                                Rename FOB to "Title Transfer"
                                                [optimization] header values don't unnecessarily repeatedly set on each line item iteration
                                                [optimization] refactored functions used by 'Get POs' and 'Refresh Existing POs':  Set Header, Detail and Detail Names
                                                [optimization] Cleaned up HelperUI, dropped SheetBuilderDynamic
   1.0.0.8              3.5.2018        T&Cs added
 * *******************************************************************************************************************/

    partial class ActionsPane : UserControl
    {
        public Excel.Workbook workbook => Globals.ThisWorkbook.Worksheets.Parent;

        private Dictionary<byte, string> companyList = new Dictionary<byte, string>();
        private byte JCCo;
        private dynamic dateFrom;
        private dynamic dateTo;
        public string lastDirectory = "";
        public bool fullLogging = true;

        public ActionsPane()
        {
            InitializeComponent();

            // ENVIRONMENTS connection strings are set in sheet McK.cs

            HelperData.VSTO_Version = this.ProductVersion;      // for logging
            this.lblVersion.Text = "v." + this.ProductVersion;

            HelperData.VPuser = Profile.GetVP_UserName();

            companyList = CompanyList.GetCompanyList();

            cboCompany.DataSource = companyList.Select(kv => kv.Value).ToList();
            //cboCompany.SelectedIndex = -1;

            #region Test Data
            //txtDateFrom.Text = "10/17";
            //txtDateTo.Text = "10/17";

            // TAX / 13 DETAIL ROWS
            //txtInvoiceFrom.Text = "20015581";
            //txtInvoiceTo.Text = "20015581";

            // 12 DETAIL ROWS
            //txtInvoiceFrom.Text = "10045850";
            //txtInvoiceTo.Text = "10045850";
            //cboCompany.SelectedIndex = 0;

            //txtInvoiceFrom.Text = "10045053";
            //txtInvoiceTo.Text = "10045053";

            // BIll notes
            //txtInvoiceFrom.Text = "10045812";
            //txtInvoiceTo.Text = "10045812";

            //txtInvoiceFrom.Text = "10011266";
            //txtInvoiceTo.Text = "10011266";

            // also uncomment test line under ThisWorkbook_Startup() to invoke automatic
            #endregion
        }

        internal void btnGetPOs_Click(object sender, EventArgs e)
        {
            btnGetPOs.Tag = btnGetPOs.Text;
            btnGetPOs.Text = "Processing...";
            btnGetPOs.Refresh();
            btnGetPOs.Enabled = false;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            List<dynamic> table = null;

            try
            {
                if (!IsValidFields()) throw new Exception("invalid fields");

                // get company
                JCCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));

                // get PO data
                table = GetPOs.GetPOReport(JCCo, txtPOFrom.Text, txtPOTo.Text, dateFrom, dateTo);

                // write it Excel
                if (table.Count > 0)
                {
                    if (fullLogging) POLog.LogAction(POLog.Action.REPORT, JCCo, txtPOFrom.Text, (txtPOTo.Text != txtPOFrom.Text ? txtPOTo.Text : null), dateFrom, (dateTo != dateFrom ? dateFrom : null));

                    if (POs.ToNewExcel(table))
                    {
                        btnCopyOffline.Enabled = true;
                        btnEmail.Enabled = true;
                        if (fullLogging) MessageBox.Show(null, "PO ready!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
                else
                {
                    if (fullLogging) MessageBox.Show(null, "PO not found!", "Failed", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                if (ex.Message != "invalid fields")
                {
                    //POLog.LogAction(POLog.Action.ERROR, JCCo, txtPOFrom.Text, txtPOTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
                    ShowErr(ex);
                }
                if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;
            }
            finally
            {
                btnGetPOs.Text = btnGetPOs.Tag.ToString();
                btnGetPOs.Enabled = true;
                btnGetPOs.Refresh();
                HelperUI.RenderON();
            }
        }

        internal void btnRefresh_Click(object sender, EventArgs e)
        {
            btnRefresh.Tag = btnRefresh.Text;
            btnRefresh.Text = "Processing...";
            btnRefresh.Refresh();
            btnRefresh.Enabled = false;

            HelperUI.AlertOff();
            //HelperUI.RenderOFF();
            List<dynamic> table = null;
            Excel.Worksheet ws = null;
            List<Excel.Worksheet> sheetsToRefresh = new List<Excel.Worksheet>();
            List<Excel.Worksheet> sheetsInvalidTemplate = null;
            List<string> POsNoData= null;
            List<string> POsRefreshed= null;
            bool refreshCurrentPO = false;
            string invalidTemplate = "";
            string noData = "";
            dynamic po = null;

            try
            {
                // refreshing existing file or loaded currenlty PO ?
                DialogResult action;
                bool showOpenFileDialog = false;
                bool openPOtab = Globals.McK.Visible == Excel.XlSheetVisibility.xlSheetVisible ? false : true;
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;

                if (openPOtab)
                {
                    action = MessageBox.Show("Yes -> Refresh external McK PO Worksheet(s).\n\n" +
                                             "No -> Refresh currently loaded PO: " + ws.Name +
                                             "\n\nOnly header and detail will be refreshed.\nAny existing changes are preserved.", "What would you like to refresh?", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                    if (action == DialogResult.Cancel) return;
                    if (action == DialogResult.No) // refresh current PO
                    {
                        refreshCurrentPO = true;
                        sheetsToRefresh.Add(ws);
                    }
                    if (action == DialogResult.Yes) // refresh file
                    {
                        showOpenFileDialog = true;
                    }
                }
                else
                {
                    showOpenFileDialog = true;
                }

                if (showOpenFileDialog)
                {
                    openFileDialog1.Title = "Select McK PO Worksheet";
                    openFileDialog1.FileName = "";
                    openFileDialog1.Filter = "Excel Workbook (*.xlsx) | *.xlsx";
                    openFileDialog1.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                    openFileDialog1.RestoreDirectory = true;
                    openFileDialog1.CheckFileExists = true;
                    openFileDialog1.CheckPathExists = true;
                    openFileDialog1.Multiselect = true;

                    action = openFileDialog1.ShowDialog();
                    if (action == DialogResult.OK)
                    {
                        if (openFileDialog1.FileNames.Count() == 0) return; // Cancel

                        foreach (String fullFilePath in openFileDialog1.FileNames)
                        {
                            ws = GetSheetToRefresh(fullFilePath);
                            sheetsToRefresh.Add(ws);
                        }
                    }
                    else { return; }
                }

                // refresh the collected sheets 
                foreach (var sheet in sheetsToRefresh)
                {
                    if (!IsValidTemplate(sheet))
                    {
                        if (sheetsInvalidTemplate == null) sheetsInvalidTemplate = new List<Excel.Worksheet>();
                        sheetsInvalidTemplate.Add(sheet);
                        continue;
                    }

                    po = GetQueryFieldsFromSheet(sheet);

                    // get PO data
                    table = GetPOs.GetPOReport(po.JCCo, po.PO, po.PO, po.OrderDate, po.OrderDate);

                    bool success = false;
                    // PO found ?
                    if (table.Count > 0)
                    {
                        if (fullLogging) POLog.LogAction(POLog.Action.REFRESH, po.JCCo, po.PO, null, po.OrderDate, null);

                        // REFRESH sheet
                        success = POs.ToExistingExcel(table, sheet);
                        if (success)
                        {
                            // add to list of success
                            if (POsRefreshed == null) POsRefreshed = new List<string>();
                            POsRefreshed.Add(po.PO);
                        }
                    }

                    if (!success)
                    {
                        if (POsNoData == null) POsNoData = new List<string>();
                        POsNoData.Add(po.PO);
                    }
                }

                // what could go wrong..
                string err = "";
                if (sheetsInvalidTemplate != null || POsNoData != null)
                {
                    // FAIL !
                    if (sheetsInvalidTemplate?.Count > 0)
                    {
                        invalidTemplate = "Invalid McK PO template:\n" +
                                          "--------------------------\n" +
                                           string.Join("\n", sheetsInvalidTemplate.Select(x => x.Name).Cast<string>());
                    }
                    invalidTemplate += invalidTemplate != "" ? "\n\n" : "";

                    if (POsNoData?.Count > 0)
                    {
                        noData = "No data found:\n" +
                                 "--------------\n" +
                                  string.Join("\n", POsNoData.ToArray());
                    }

                    err = "There were issues refreshing the following POs:\n\n" +
                                    invalidTemplate +
                                    noData;
                }

                string msg = "";
                if (POsRefreshed != null)
                {
                    // SUCCESS!!
                    msg = "The following POs were refreshed:\n" +
                        "---------------------------------\n" +
                        string.Join("\n", POsRefreshed.ToArray());
                }

                // show success / failure
                if (msg != "" && err == "")
                {
                    // SUCCESS, NO ERRORS
                    MessageBox.Show(null, msg, "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else if (msg != "" && err != "")
                {
                    // SOME SUCCESS
                    MessageBox.Show(null, msg + "\n\n\n" + err, "Some Success", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                }
                else if (msg == "" && err != "")
                {
                    // ALL FAILED!
                    throw new Exception(err); 
                }
            }
            catch (Exception ex)
            {
                // scrubb off err to pevent logging 'PO not found' or 'invalid template' cases
                string err = ex.Message;
                       err = err.Replace("There were issues refreshing the following POs:\n\n", "");
                       err = noData != "" ? err.Replace(noData, "") : err;
                       err = err.Trim();

                if (invalidTemplate != "")
                { 
                    invalidTemplate = invalidTemplate.Replace("\n\n", "");
                    err = err.Replace(invalidTemplate, "");
                    err = err.Trim();
                }

                // invalid user-input errs not logged
                if (err != "invalid fields" && err != "")
                {
                    err = err.Replace("--------------------------", "");  //Invalid McK PO template
                    POLog.LogAction(POLog.Action.ERROR, po.JCCo, po.PO, null, po.OrderDate, null, GetSheet_Version(), err);
                }
                ShowErr(ex);
            }
            finally
            {
                //HelperUI.RenderON();
                btnRefresh.Text = btnRefresh.Tag.ToString();
                btnRefresh.Enabled = true;
                btnRefresh.Refresh();

                #region CLEAN UP

                // Close invalid sheets
                if (sheetsInvalidTemplate != null && !refreshCurrentPO)
                {
                    foreach (var sheet in sheetsInvalidTemplate)
                    {
                        ((Excel.Workbook)sheet.Parent).Close();
                    }
                }

                if (sheetsToRefresh?.Count > 0)
                {
                    foreach (Excel.Worksheet sh in sheetsToRefresh)
                    {
                        if (sh != null) Marshal.ReleaseComObject(sh);
                    }
                    sheetsToRefresh.Clear();
                }

                if (sheetsInvalidTemplate?.Count > 0)
                {
                    foreach (Excel.Worksheet sh in sheetsInvalidTemplate)
                    {
                        if (sh != null) Marshal.ReleaseComObject(sh);
                    }
                    sheetsInvalidTemplate.Clear();
                }

                POsNoData?.Clear();

                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;

                #endregion
            }
        }


        /// <summary>
        /// Opens the sheet to be refreshed and leaves it open
        /// </summary>
        /// <param name="fullFilePath"></param>
        /// <returns></returns>
        private Excel.Worksheet GetSheetToRefresh(string fullFilePath = "")
        {
            Excel.Application xlApp = null;
            Excel.Workbook wkbFrom = null;
            Excel.Worksheet ws = null;

            try
            {
                if (fullFilePath != "")
                {
                    //if (!NetPath.PathExists(fileLocation)) throw new Exception("Network path does not exist:\n" + System.IO.Path.GetDirectoryName(fileLocation));
                    xlApp = Globals.ThisWorkbook.Application;
                    wkbFrom = xlApp.Workbooks.Open(fullFilePath);

                    //  CONSIDER: Support multiple POs in 1 workbook ?
                    ws = (Excel.Worksheet)wkbFrom.Sheets[1];
                }
            }
            catch (Exception ex)
            {
                ShowErr(ex);
            }
            return ws;
        }
    
        /// <summary>
        /// Validate Worksheet has presumed <see cref="Excel.Names"/>
        /// </summary>
        /// <param name="ws">Worksheet to check</param>
        /// <returns>True if valid, else false</returns>
        private bool IsValidTemplate(Excel.Worksheet ws)
        {
           //if (ws == null) throw new Exception("Error accessing worksheet")
            bool invalidSheet = false;

            try
            {
                // named ranges that should exist in worksheet
                List<string> presumedNames = new List<string>() { "udMCKPONumber_POHD"
                                                                , "OrderDate_POHD"
                                                                , "Name_APVM"
                                                                , "Address_APVM"
                                                                , "City_State_Zip_APVM"
                                                                , "Attention_POHD"
                                                                , "Vendor_POHD"
                                                                , "PayTerms_HQPT"
                                                                , "Description_udFOB"
                                                                , "Description_udShipMethod"
                                                                , "ServiceSite_SMWorkOrder"
                                                                , "Description_SMServiceSite"
                                                                , "Address_POHD"
                                                                , "City_State_Zip_Country_POHD"
                                                                , "Phone"
                                                                , "Email"
                                                                , "ShipIns_POHD"
                                                                , "Name_HQCO"
                                                                , "Address_HQCO"
                                                                , "City_State_Zip_HQCO"
                                                                , "OrigTax_POIT"
                };

                // presumed names exist ?
                string namedInSheet;
                foreach (dynamic c in ws.Names)
                {
                    namedInSheet = c.Name.ToString().Split('!')[1];

                    // compare presumed names in worksheet
                    if (presumedNames.Exists(name => name == namedInSheet))
                    {
                        // check name off the list
                        presumedNames.Remove(namedInSheet);
                    }

                    // conclude correct template, when all names checked off 
                    invalidSheet = presumedNames.Count == 0;
                    if (invalidSheet) break;
                }
            }
            catch (Exception )
            {
                throw;
            }
            return invalidSheet;
        }

        /// <summary>
        /// Get necessary field values to query PO data
        /// </summary>
        /// <param name="ws"></param>
        /// <returns><see cref="DynamicObject"/> with JCCo, PO, OrderDate properties</returns>
        private dynamic GetQueryFieldsFromSheet(Excel.Worksheet ws)
        {
            if (ws == null) throw new Exception("Unable to get header fields from PO worksheet.");
            dynamic po = new ExpandoObject();

            try
            {
                // read fields from sheet
                po.JCCo = Convert.ToByte(ws.get_Range("A1").Formula);
                po.PO = ws.get_Range("udMCKPONumber_POHD", Type.Missing).Formula;
                po.OrderDate = DateTime.FromOADate(Convert.ToDouble(ws.get_Range("OrderDate_POHD", Type.Missing).Formula)).ToString("MM/dd/yy");
            }
            catch (Exception)
            {
                throw;
            }
            return po;
        }

        private string GetSheet_Version()
        {
            workbook.Activate();
            return ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version;
        }

        #region UI FIELD CONTROLS

        // update / validate company
        private void cboCompany_Leave(object sender, EventArgs e)
        {
            errorProvider1.Clear();

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetError(cboCompany, "Select a Company from the list");
                return;
            }

            JCCo = companyList.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
        }
        private void cboCompany_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyData == Keys.Delete)
            {
                JCCo = 0;
                cboCompany.SelectedIndex = -1;
            }
        }
        private void cboCompany_Validating(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();
        private void cboCompany_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (cboCompany.SelectedIndex != -1) errorProvider1.SetError(cboCompany, "");
        }

        // allow enter key invoke button
        private void tiggerEnter_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyValue == (char)Keys.Enter)
            {
                e.Handled = true;
                btnGetPOs_Click(sender, null);
            }
        }

        // paint font on Dropdown menus 
        private void cboBoxes_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Black;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString()
                                   , e.Font
                                   , brush
                                   , e.Bounds
                                   , System.Drawing.StringFormat.GenericDefault
                                  );
            e.DrawFocusRectangle();
        }

        // highlight textboxes' text on focus
        private void txtBoxHighlight_On_Enter(object sender, EventArgs e)
        {
            dynamic textbox = null; // handles 'TextBox' and 'MaskedTextBox'

            if (sender.GetType() == typeof(TextBox))
            {
                textbox = (TextBox)sender;
            }
            else if (sender.GetType() == typeof(MaskedTextBox))
            {
                textbox = (MaskedTextBox)sender;
            }

            textbox?.SelectAll();
        }

        // auto-set defaults
        private void txtPOFrom_TextChanged(object sender, EventArgs e)
        {
            txtPOTo.Text = txtPOFrom.Text;
            IsFieldsFilled();
        }

        private void txtDateFrom_TextChanged(object sender, EventArgs e)
        {
            txtDateTo.Text = txtDateFrom.Text;
            IsFieldsFilled();
        }

        #endregion

        #region field validation
        // only enable GetInvoice button once all fields are validated
        private void TextBoxes_TextChanged(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();
        private void txtPOFrom_Validating(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();
        private void txtPOTo_Validating(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();

        // validates fields quietely as user fills out the form allowing button to be enabled once all fields are filled
        private bool IsFieldsFilled()
        {
            bool badField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                badField = true;
            }

            if (txtPOFrom.Text == "" && txtPOFrom.Text.Length < 6)
            {
                badField = true;
            }
            else
            {
                errorProvider1.SetError(txtPOFrom, "");
            }

            if (txtPOTo.Text == "" && txtPOTo.Text.Length < 6)
            {
                badField = true;
            }
            else
            {
                errorProvider1.SetError(txtPOTo, "");
            }

            if (badField) return false;

            btnGetPOs.Enabled = true;
            return true;
        }

        // validates fields with alert
        private bool IsValidFields()
        {
            bool badField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                errorProvider1.SetIconAlignment(cboCompany, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(cboCompany, "Select a Company");
                badField = true;
            }
            else
            {
                errorProvider1.SetError(cboCompany, "");
            }

            if (txtPOFrom.Text == "")
            {
                errorProvider1.SetIconAlignment(txtPOFrom, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(txtPOFrom, "Input the START PO");
                badField = true;
            }
            else
            {
                txtPOFrom.Text = txtPOFrom.Text.Replace(" ", "");
                errorProvider1.SetError(txtPOFrom, "");
            }

            if (txtPOTo.Text == "")
            {
                txtPOTo.Text = txtPOFrom.Text;
                if (txtPOTo.Text == "")
                {
                    errorProvider1.SetIconAlignment(txtPOTo, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtPOTo, "Input the ENDING PO");
                    badField = true;
                }
                else
                {
                    txtPOTo.Text = txtPOTo.Text.Replace(" ", "");
                    errorProvider1.SetError(txtPOTo, "");
                }
            }

            #region ORDER DATE
            // START ORDER DATE

            if (txtDateFrom.Text.Length == 8)
            {
                DateTime dt;
                if (!DateTime.TryParse(txtDateFrom.Text, out dt))
                {
                    errorProvider1.SetIconAlignment(txtDateFrom, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtDateFrom, "Input START Order Date in MM/DD/YY format.");
                    badField = true;
                }
                else
                {
                    dateFrom = dt;
                    errorProvider1.SetError(txtDateFrom, "");
                }
            }

            // ENDING ORDER DATE

            if (txtDateTo.Text.Length == 8)
            {
                DateTime dt;
                if (!DateTime.TryParse(txtDateTo.Text, out dt))
                {
                    errorProvider1.SetIconAlignment(txtDateTo, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtDateTo, "Input ENDING Order Date in MM/DD/YY format.");
                    badField = true;
                }
                else
                {
                    dateTo = dt;
                    errorProvider1.SetError(txtDateTo, "");
                }
            }

            #endregion

            if (badField)
            {
                //btnGetInvoices.Enabled = true;
                return false;
            }

            return true;
        }


        #endregion

        #region SAVE OFFFLINE

        private void btnCopyOffline_Click(object sender, EventArgs e)
        {
            string orig_text = btnCopyOffline.Text;
            tmrRestoreButtonText.Tag = new object[] { btnCopyOffline, orig_text };
            btnCopyOffline.Text = "Saving...";
            btnCopyOffline.Refresh();
            btnCopyOffline.Enabled = false;

            try
            {
                string wkbName = "McK PO" + (POs.UniquePOs > 1 ? "s " + txtPOFrom.Text + " - " + txtPOTo.Text : " " + txtPOFrom.Text);

                if (IO.CopyOffline(GetUIFields(), wkbName)) btnCopyOffline.Text = "Copied!";
            }
            catch (Exception ex)
            {
                POLog.LogAction(POLog.Action.ERROR, JCCo, txtPOFrom.Text, txtPOTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
                ShowErr(ex);
            }
            finally
            {
                tmrRestoreButtonText.Enabled = true;
                btnCopyOffline.Enabled = true;
            }
        }

        internal dynamic GetUIFields()
        {
            dynamic po = new ExpandoObject();
            po.JCCo = JCCo;
            po.POFrom = txtPOFrom.Text;
            po.POTo = txtPOTo.Text;
            po.DateFrom = dateFrom;
            po.DateTo = dateTo;
            po.fullLogging = fullLogging;
            return po;
        }

        private void btnEmail_Click(object sender, EventArgs e)
        {
            Outlook.Application oApp = null;
            Outlook.MailItem mail = null;
            string tempPDF = "";

            string orig_text = btnEmail.Text;
            tmrRestoreButtonText.Tag = new object[] { btnEmail, orig_text };
            btnEmail.Text = "...";
            btnEmail.Refresh();
            btnEmail.Enabled = false;

            try
            {
                HelperUI.RenderOFF();

                if (fullLogging) POLog.LogAction(POLog.Action.EMAIL, JCCo, txtPOFrom.Text, txtPOTo.Text, dateFrom, dateTo, Globals.ThisWorkbook.Application.Version);

                tempPDF = IO.GetWorkbookAsPDF();

                if (File.Exists(tempPDF))
                {
                    oApp = new Outlook.Application();

                    mail = oApp.CreateItem(Outlook.OlItemType.olMailItem) as Outlook.MailItem;

                    mail.Subject = "McK PO " + workbook.ActiveSheet.Name;
                    mail.Display(false);
                    mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, Type.Missing, Type.Missing);

                    btnEmail.Text = "Email Ready!";
                }
            }
            catch (Exception ex)
            {
                POLog.LogAction(POLog.Action.ERROR, JCCo, txtPOFrom.Text, txtPOTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
                ShowErr(ex);
            }
            finally
            {
                HelperUI.RenderON();

                tmrRestoreButtonText.Enabled = true;
                btnEmail.Enabled = true;

                if (oApp != null) Marshal.ReleaseComObject(oApp);
                if (mail != null) Marshal.ReleaseComObject(mail);
                if (File.Exists(tempPDF)) File.Delete(tempPDF);
            }

        }

        /// <summary>
        /// Restores buttons to their original text. Just send the button and orignal text via the timer's tag as object [0]=button, [1]=origText
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void tmrRestoreButtonText_Tick(object sender, EventArgs e)
        {
            object[] objects = (object[])tmrRestoreButtonText.Tag;
            Button button = (Button)objects[0];
            button.Text = (string)objects[1];
            button.Enabled = true;
            tmrRestoreButtonText.Enabled = false;
        }

        #endregion

        private void ShowErr(Exception ex = null, string customErr = null, string title = "Failure!")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
