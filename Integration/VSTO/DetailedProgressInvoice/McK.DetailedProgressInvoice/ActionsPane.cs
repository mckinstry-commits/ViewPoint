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
 1.2.1.7            4/12/2018       - PROD Rel. Added Released Retention (RetgRelJBIS) and tax (TaxAmtJBIT) to breakdown contract item sub-invoice
 
 1.2.1.8            09.24.2018      - replaced Excel's built-in page count with own custom to remedy uneven left-right margins.
 1.2.1.11           11.27.2018      - page # now in footer
                                    - Footer maintains within the page, doesn’t bleed to next page anymore
                                    - Bill Month is now optional; no longer required to query invoices 
                                    - Fixed error:  when Item description is blank, now displays items 
 1.2.1.12           8.25.2019       - Fix Logic on How Retention is Populating from Stored Materials on MCK JB Detailed Progress Invoice (Behind SM/Tax Tab) TFS 5036
                                    • Made into 2 version of the VSTO; 1 for Prod and 1 for Test - 4457
                                        o	The “test version” lives in 1 central location (STAGING) and is shared amongst Dev, Staging, Project, and Upgrade
                                        o	Easily switch test environment quickly, eliminating the need to uninstall/reinstall 
                                        o	Only uninstall when switching between PROD and TEST environments
                                        o	Saves network disk space as it's no more redundant copies in four different places
                                        o	Easier to deploy and test
                                        o	More manageable and scalable  
 1.2.2.1            9.10.2019       - Fix TFS 5036
 1.2.2.2            9.11.2019       - TFS 5036 STG: Ready for Prod 
                                            • fix % Complete (instead of value, use formula) and CurrContract pulled from JBIS - Leo Gurdian
                                            • % Complete format is now 0.00% instead of “-“ for zero percentage
                            *** PROD RELEASE *** 9.12.2019
 1.2.2.4            9.18.2019   DEV     - TFS 5423 aligned "Customer #" header label
                                        - TFS 5423 format "Previous Billing Application" as number
                                        - TFS 5424 Fixed the details / totals not matching crystal report
 1.2.2.6            9.18.2019   STG     - TFS 5424 - 'Current Contract Amt' now matches crystal report
                                                   - Detail Description now wraps
                                        - TFS 5423 2 different City & States listed as the Billing Address - fixed
                                        - TFS 5531 - Fix TOTALS formula range (hot-fix PROD 9.30.2019)
1.2.2.7             X X X X     DEV/STG     - TFS 5037 - NEW TEMPLATE
2.0.0.1             X X X X     DEV/STG     - TFS 5037 - 3 & 4 pg support, removed item desc text wrap
                                            - TFS 5037 Nth pages support
2.0.1.0             x x x x     DEV/STG   TFS 5037 - revert to textboxes for header sections
 * *******************************************************************************************************************/

    partial class ActionsPane : UserControl
    {
        public static System.Configuration.AppSettingsReader _config => new System.Configuration.AppSettingsReader();

        public Excel.Workbook workbook => Globals.ThisWorkbook.Worksheets.Parent;

        internal Dictionary<dynamic, dynamic> _companyDict = new Dictionary<dynamic, dynamic>(); // combobox source
        internal List<dynamic> _lstCompanies; // fills _companyDict

        private byte JCCo;
        private dynamic dateFrom;
        private dynamic dateTo;
        public string lastDirectory = "";
        public bool fullLogging = false;
    
        public ActionsPane()
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
                if (cboTargetEnvironment.Items.Count > 0) cboTargetEnvironment.SelectedIndex = 1;  // RefreshTargetEnvironment() -> RefreshCompanies() & RefreshDivisons() are called on change
                if ((string)cboTargetEnvironment.SelectedItem == "Prod") cboTargetEnvironment.Visible = false;

                HelperData.VSTO_Version = this.ProductVersion;
                this.lblVersion.Text = "v." + this.ProductVersion;

                HelperData.VPuser = Profile.GetVP_UserName();
                cboSortBy.SelectedIndex =  0;
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }

            //TargetPoint = Cursor.Position;

            #region Test Data

            //txtInvoiceFrom.Text = "  10028884";
            //txtInvoiceTo.Text = "  10028884";

            //txtDateFrom.Text = "10/17";
            //txtDateTo.Text = "10/17";

            // TAX / 13 DETAIL ROWS
            //txtInvoiceFrom.Text = "20015581";
            //txtInvoiceTo.Text = "20015581";

            // 12 DETAIL ROWS
            //txtInvoiceFrom.Text = "10045850";
            //txtInvoiceTo.Text = "10045850";
            //cboCompany.SelectedIndex = 0;

            //txtInvoiceFrom.Text = "  10029810";
            //txtInvoiceTo.Text = "  10029810";

            //txtInvoiceFrom.Text = "10045053";
            //txtInvoiceTo.Text = "10045053";

            // BIll notes
            //txtInvoiceFrom.Text = "10045812";
            //txtInvoiceTo.Text = "10045812";

            //txtInvoiceFrom.Text = "10029810";
            //txtInvoiceTo.Text = "10029810";

            //// PG 5
            //txtInvoiceFrom.Text = "10008881";
            //txtInvoiceTo.Text = "10008881";

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
                        MessageBox.Show(null, "Completed successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
                else
                {
                    MessageBox.Show(null, "No data found!", "Failed", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                if (ex?.Message != "invalid fields")
                {
                    DetailInvoiceLog.LogAction(DetailInvoiceLog.Action.ERROR, JCCo, txtInvoiceFrom.Text, txtInvoiceTo.Text, dateFrom, dateTo, GetSheet_Version(), ex.Message);
                    HelperUI.ShowErr(ex);
                }
            }
            finally
            {
                btnGetInvoices.Text = btnGetInvoices.Tag.ToString();
                btnGetInvoices.Enabled = true;
                btnGetInvoices.Refresh();
                HelperUI.RenderON();
                dateFrom = null;
                dateTo = null;
            }
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

            JCCo = _companyDict.FirstOrDefault(x => x.Value == cboCompany.SelectedValue.ToString()).Key;
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

        /// <summary>
        /// handles cboTargetEnvironment with black background
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void cboTargetEnvironment_DrawItem(object sender, DrawItemEventArgs e)
        {
            if (e.Index == -1) return;
            ComboBox cboBox = (ComboBox)sender;
            var brush = System.Drawing.Brushes.Yellow;
            e.DrawBackground();
            e.Graphics.DrawString(cboBox.Items[e.Index].ToString(), e.Font, brush, e.Bounds, System.Drawing.StringFormat.GenericDefault);
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
                    dateTo = dt.AddDays(DateTime.DaysInMonth(dt.Year, dt.Month) - 1);
                    //dt = dateTo;
                    errorProvider1.SetError(txtDateTo, "");
                }
            }

            if (txtInvoiceFrom.Text == "" & (dateFrom == null & dateTo == null) )
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
                if (txtInvoiceTo.Text == "" & (dateFrom == null & dateTo == null))
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
                HelperUI.ShowErr(ex);
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

                tempPDF = IO.GetWorksheetAsPDF((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);

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
                HelperUI.ShowErr(ex);
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

                RefreshCompanies();

                if (Globals.ThisWorkbook != null) Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = environ;
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
        }

        private void RefreshCompanies()
        {
            _lstCompanies = Companies.GetCompanyList();
            _companyDict = _lstCompanies.ToDictionary(n => n.HQCo, n => n.CompanyName);

            cboCompany.DataSource = _companyDict.Select(kv => kv.Value).ToList();

            if (cboCompany.Items.Count > 0) cboCompany.SelectedIndex = 0;
        }

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



        //public string GetVSTO_Version()
        //{
        //    System.Reflection.Assembly assembly = System.Reflection.Assembly.GetExecutingAssembly();
        //    FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(assembly.Location);
        //    return fvi.FileVersion;
        //}

    }
}
