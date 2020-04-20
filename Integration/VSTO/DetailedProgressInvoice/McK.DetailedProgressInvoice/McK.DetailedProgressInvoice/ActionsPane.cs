using McK.Data.Viewpoint;
using System;
using System.Collections.Generic;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using Outlook = Microsoft.Office.Interop.Outlook;
using System.Runtime.InteropServices;
using System.Linq;
using Mck.Data.Viewpoint;
using System.Diagnostics;
using System.Dynamic;
using System.IO;

// Change SolutionID in McK.DetailedProgressInvoice.csproj to specify environment

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    /*****************************************************************************************************************;
                                         McKinstry Detailed Progress Invoice Report                          
                                            copyright McKinstry 2017                                                

    Pulls invoices grouped together from JC Contract Items (JCCI).  

    AUTHORS:
    Prototype Excel VSTO:   Leo Gurdian                      
    Viewpoint/SQL Dev:      Leo Gurdian                           
    Project Manager:        Jean Nichols                


    DEPENDENCY:             MCKspGetDetailedProgressInvoices

    Release                  Publish Date                Details                                              
    -------                  ------------                -------                                             
    1.0.0.0                  10/11/2017                 - Init prototype;
                                                           FEATURES:
                                                            Produces a single or range of invoices (no limit set)
                                                            Printer friendly
                                                            Header w/ logo
                                                            Detail Rows
                                                            Totals
                                                            Footer
    1.1.0.0                  10/27/2017                     Formulas added
                                                            Save offline 
                                                            Align Totals textbox w/ total numbers when filtering results 
                                                            Clone Invoice x line item count 
                                                            Invoice text changed to completed + (line item number) 
                                                            Footer now visible on sheet (don’t have to print preview)
   1.1.1.0                   10/30/2017                 - added logging for troubleshooting & usage metrics
                                                        - updated save offline
                                                        - prompt save on exit if invoice exists
   1.1.1.1                   11/3/2017                  - Cell's formatting 
   1.1.1.2                   11/10/2017                 - Bill month no longer required
                                                        - Show tax if present
                                                        - Show line items subtotals
   1.1.1.3                  11/10/2017                  - Show notes 
                                                        - Offline copy fixed error
   1.1.1.4                  11/20/2017                  - show tax at invoice level, not detail level
                                                        - formatting totals
                                                        - Less Previous Application Total formula reworked
                                                        - Show sub total even if only 1 line item
                                                        - Create an -ALL TAB and then -1, -2, -3 etc. so original invoice details are preserved.
                                                        - <<<<<<<<<<<<<<<   handle > 10 detail items; overflow (post pone) >>>>>>>>>>>>>>>>>
  1.1.1.5                   11/21/2017                  - Added Customer Number
                                                        - updated total due formula
                                                        - added 'invoice not found' error msg
                                                        - footer dynamically positions depending on notes' break lines
  1.1.1.6                   11/22/2017                  - When there's tax 'Total Due' = JBIN.InvDue ..else = Total Billed to Date - Less Retainage - Less Previous Application
                                                        - SQL - fix Sort by issue when Invoice is Alphanumeric
                                                        - % Complete subtotal set to % format
                                                        - Notes is now tab '\t' friendly.  Excel don't know how to translate '\t' - this is fixed.
  1.2.0.0                  11/28-29/2017                - Save offline doesn't strip off VSTO code but clones / saves invoice(s) to new workbook
                                                        - Send via EMail: attaches workbook as PDF and opens outlook email preview

                           11/30/2017                   - LIVE IN PROD !!!
                        
  1.2.0.1                   1/12/2018                   - 'invoice #-ALL' tab defaults as landing worksheet 
                                                        - Bold Line underneath McKinstry Logo now consistent with Lines in Column B – Column L
  1.2.0.2                   2/12/2018                   - 'Total Due' correctly calculated when there's Retainage to be Released
                                                        -  1st Load page shows environment source
  1.2.1.1                   2/26/2018                   - Place Totals on bottom right of page. 
                                                          Place Custom footer on bottom of each page
                                                          Display header accross print pages
                                                          Filter invoice clones to only show it's respective item 
 1.2.1.2            3/5/2018        - fix footer / totals placement
 1.2.1.3            3/5/2018        - fix footer / totals placement when won't fit in 1 pg
 1.2.1.4            3/6/2018        - item worksheets contain
                                        - only pertinent item
                                        - totals bottom right
                                        - footer bottom
1.2.1.7             4/12/2018       - Added Released Retention (RetgRelJBIS) and tax (TaxAmtJBIT) to breakdown contract item sub-invoice
                                    
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

            HelperData.AppName = this.ProductName;

            HelperData.VSTO_Version     = this.ProductVersion;
            this.lblVersion.Text = "v." + this.ProductVersion;

            HelperData.VPuser = Profile.GetVP_UserName();

            companyList = CompanyList.GetCompanyList();

            cboCompany.DataSource = companyList.Select(kv => kv.Value).ToList();
            //cboCompany.SelectedIndex = -1;
            cboSortBy.SelectedIndex = 1;

            TargetPoint = Cursor.Position;

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

        internal void btnGetInvoices_Click(object sender, EventArgs e)
        {
            btnGetInvoices.Tag = btnGetInvoices.Text;
            btnGetInvoices.Text = "Processing...";
            btnGetInvoices.Refresh();
            btnGetInvoices.Enabled = false;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            List<dynamic> table = null;

            try
            {
                if (!IsValidFields()) throw new Exception("invalid fields");

                // get company
                JCCo = Convert.ToByte(cboCompany.Text.Substring(0, cboCompany.SelectedItem.ToString().IndexOf("-")));
                string sort = cboSortBy.Text.Substring(0, 1);

                // get invoices data
                table = global::McK.Data.Viewpoint.Invoices.GetDetailProgressInvoices(JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, sort);

                // write it Excel
                if (table.Count > 0)
                {
                    if (fullLogging) DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.REPORT, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo);

                    if (global::McK.JBDetailedProgressInvoice.Viewpoint.Invoices.ToExcel(table))
                    {
                        btnCopyOffline.Enabled = true;
                        btnEmail.Enabled = true;
                        if (fullLogging) MessageBox.Show(null, "Invoice request completed successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
                else
                {
                    if (fullLogging) MessageBox.Show(null, "Invoice not found!", "Failed", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                if (ex.Message != "invalid fields")
                {
                    DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.ERROR, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
                    ShowErr(ex);
                }
            }
            finally
            {
                btnGetInvoices.Text = btnGetInvoices.Tag.ToString();
                btnGetInvoices.Enabled = true;
                btnGetInvoices.Refresh();
                HelperUI.RenderON();
            }
        }


        private string GetSheet_Version()
        {
            workbook.Activate();
            return ((Excel.Worksheet)workbook.Application.ActiveSheet).Name + ": " + Globals.ThisWorkbook.Application.Version;
        }

        //public string GetVSTO_Version()
        //{
        //    System.Reflection.Assembly assembly = System.Reflection.Assembly.GetExecutingAssembly();
        //    FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);
        //    return fvi.FileVersion;
        //}

        private void ShowErr(Exception ex = null, string customErr = null, string title = "Failure!")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
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
                btnGetInvoices_Click(sender, null);
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
        private void txtStartInvoice_TextChanged(object sender, EventArgs e)
        {
            txtInvoiceTo.Text = txtInvoiceFrom.Text;
            IsFieldsFilled();
        }

        private void txtStartBillMonth_TextChanged(object sender, EventArgs e)
        {
            txtDateTo.Text = txtDateFrom.Text;
            IsFieldsFilled();
        }

        #endregion

        #region field validation
        // only enable GetInvoice button once all fields are validated
        private void TextBoxes_TextChanged(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();
        private void txtStartInvoice_Validating(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();
        private void txtEndInvoice_Validating(object sender, System.ComponentModel.CancelEventArgs e) => IsFieldsFilled();

        // validates fields quietely as user fills out the form allowing button to be enabled once all fields are filled
        private bool IsFieldsFilled()
        {
            bool badField = false;

            if (cboCompany.SelectedIndex == -1)
            {
                badField = true;
            }

            if (txtInvoiceFrom.Text == "" && txtInvoiceFrom.Text.Length < 6)
            {
                badField = true;
            }
            else
            {
                errorProvider1.SetError(txtInvoiceFrom, "");
            }

            if (txtInvoiceTo.Text == "" && txtInvoiceTo.Text.Length < 6)
            {
                badField = true;
            }
            else
            {
                errorProvider1.SetError(txtInvoiceTo, "");
            }

            //if (!DateTime.TryParse(txtStartBillMonth.Text, out dateFrom) || txtStartBillMonth.Text.Length < 5)
            //{
            //    badField = true;
            //}
            //else
            //{
            //    errorProvider1.SetError(txtStartBillMonth, "");
            //}

            //if (!DateTime.TryParse(txtEndBillMonth.Text, out dateTo) || txtEndBillMonth.Text.Length < 5)
            //{
            //    badField = true;
            //}
            //else
            //{
            //    errorProvider1.SetError(txtEndBillMonth, "");
            //}

            if (cboSortBy.SelectedIndex == -1)
            {
                btnGetInvoices.Enabled = false;
                badField = true;
            }

            if (badField) return false;

            btnGetInvoices.Enabled = true;
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

            // START BILL MONTH
            string _mth = txtDateFrom.Text.Replace("/", "");
            string mth = "";
            string yr = "";

            if (_mth.Length == 4)
            {
                mth = _mth.Substring(0, 2);
                yr = _mth.ToString().Substring(2, 2);
                DateTime dt;
                if (!DateTime.TryParse(mth + "/01/" + yr, out dt))
                {
                    errorProvider1.SetIconAlignment(txtDateFrom, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtDateFrom, "Input START Bill Month in MM/YY format.");
                    badField = true;
                }
                else
                {
                    dateFrom = dt;
                    errorProvider1.SetError(txtDateFrom, "");
                }
            }

            _mth = txtDateTo.Text.Replace("/", "");

            if (_mth.Length == 4)
            {
                mth = _mth.Substring(0, 2);
                yr = _mth.ToString().Substring(2, 2);
                DateTime dt;
                // END BILL MONTH
                if (!DateTime.TryParse(mth + "/01/" + yr, out dt))
                {
                    errorProvider1.SetIconAlignment(txtDateTo, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtDateTo, "Input ENDING Bill Month in MM/YY format.");
                    badField = true;
                }
                else
                {
                    dateTo = dateTo.AddDays(DateTime.DaysInMonth(dateTo.Year, dateTo.Month) - 1);
                    dt = dateTo;
                    errorProvider1.SetError(txtDateTo, "");
                }
            }

            if (txtInvoiceFrom.Text == "")
            {
                errorProvider1.SetIconAlignment(txtInvoiceFrom, ErrorIconAlignment.MiddleLeft);
                errorProvider1.SetError(txtInvoiceFrom, "Input the START Invoice");
                badField = true;
            }
            else
            {
                txtInvoiceFrom.Text = txtInvoiceFrom.Text.Replace(" ", "");
                errorProvider1.SetError(txtInvoiceFrom, "");
            }

            if (txtInvoiceTo.Text == "")
            {
                txtInvoiceTo.Text = txtInvoiceFrom.Text;
                if (txtInvoiceTo.Text == "")
                {
                    errorProvider1.SetIconAlignment(txtInvoiceTo, ErrorIconAlignment.MiddleLeft);
                    errorProvider1.SetError(txtInvoiceTo, "Input the ENDING Invoice");
                    badField = true;
                }
                else
                {
                    txtInvoiceTo.Text = txtInvoiceTo.Text.Replace(" ", "");
                    errorProvider1.SetError(txtInvoiceTo, "");
                }
            }

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
                string wkbName = "McK Detailed Progress Invoice" + (Invoices.Unique > 1 ? "s " + txtInvoiceFrom.Text + " - " + txtInvoiceTo.Text: " " + txtInvoiceFrom.Text);

                IO.CopyOffline(GetUIFields(), wkbName);

                btnCopyOffline.Text = "Copied!";
            }
            catch (Exception ex)
            {
                DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.ERROR, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
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
            dynamic app = new ExpandoObject();
            app.JCCo = JCCo;
            app.InvoiceFrom = txtInvoiceFrom.Text;
            app.InvoiceTo = txtInvoiceTo.Text;
            app.dateFrom = dateFrom;
            app.dateTo = dateTo;
            app.fullLogging = fullLogging;
            return app;
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

                if (fullLogging) DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.EMAIL, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, Globals.ThisWorkbook.Application.Version);

                tempPDF = IO.GetWorkbookAsPDF();

                if (File.Exists(tempPDF))
                {
                    oApp = new Outlook.Application();

                    mail = oApp.CreateItem(Outlook.OlItemType.olMailItem) as Outlook.MailItem;

                    mail.Subject = "McK Detailed Progress Invoice " + workbook.ActiveSheet.Name;
                    mail.Display(false);
                    mail.Attachments.Add(tempPDF, Outlook.OlAttachmentType.olByValue, Type.Missing, Type.Missing);

                    btnEmail.Text = "Email Ready!";
                }
            }
            catch (Exception ex)
            {
                DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.ERROR, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
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

        static double Angle = 0d;
        static System.Drawing.Point TargetPoint;

        private void timer1_Tick(object sender, EventArgs e)
        {
            double Radius = System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width / 3;
            Angle += Math.PI / 30;
            Cursor.Position = new System.Drawing.Point((int)(System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width / 2 + Math.Cos(Angle) * Radius), (int)(System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height / 2 + Math.Sin(Angle) * Radius));
            TargetPoint = Cursor.Position;
        }

        #endregion


        //private bool FormatDataAsTable(Excel.Worksheet ws, string tableName, string headerRowA1Style, string lastRowA1Style, Excel.XlYesNoGuess hasHeaders = Excel.XlYesNoGuess.xlYes)
        //{
        //    Excel.Range rng = null;
        //    Excel.Range rng2 = null;

        //    try
        //    {
        //        // get area range to become a table
        //        rng = ws.get_Range(headerRowA1Style);
        //        rng2 = ws.get_Range(lastRowA1Style);
        //        //rng2 = rng.End[Excel.XlDirection.xlToRight].End[Excel.XlDirection.xlDown];

        //        // format area range as table
        //        rng = ws.get_Range(rng, rng2);
        //        Excel.ListObject listObject = HelperUI.FormatAsTable(rng, tableName, true, false, hasHeaders:  Excel.XlYesNoGuess.xlYes);
        //        return true;
        //    }
        //    catch (Exception ex)
        //    {
        //        ShowErr(ex, title: ws.Name + " failure!");
        //        return false;
        //    }
        //    finally
        //    {
        //        if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
        //        if (rng2 != null) Marshal.ReleaseComObject(rng2); rng2 = null;
        //    }
        //}

    }
}
