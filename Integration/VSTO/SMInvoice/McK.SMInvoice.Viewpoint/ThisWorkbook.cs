using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using System.Windows.Forms;

namespace McK.SMInvoice.Viewpoint
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane1 _myActionPane = new ActionPane1();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            Application.CommandBars["Task Pane"].Width = 237;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)Application.Top + 100;
            }

            try
            {
                Globals.BaseAgreement.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseInvoiceList.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.Customers.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                //Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
            }
            catch (System.Exception) { throw; }

            RadioButton rdoBtn = (RadioButton)Globals.Customers.Controls["rdoActiveCustomers"];
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            rdoBtn = (RadioButton)Globals.Customers.Controls["rdoARCustomers"];
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            string title = Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula;

            Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula = title + " v." + _myActionPane.ProductVersion;

            string env = (string)_myActionPane.cboTargetEnvironment.SelectedItem;

            if (env == "Prod")
            {
                Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Activate();
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = "";
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Interior.ColorIndex = 2;  // prod
            }
            else
            {
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = env;
            }

            //System.Windows.Forms.SendKeys.Send("{Down}");
            //_myActionPane.btnInputList.PerformClick();
        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer

        /// <summary>
        /// Required method for Designer support - modify at your own risk
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisWorkbook_Startup);
            this.Shutdown += new System.EventHandler(ThisWorkbook_Shutdown);
            this.BeforeClose += new Excel.WorkbookEvents_BeforeCloseEventHandler(ThisWorkbook_BeforeClose);
            this.SheetActivate += ThisWorkbook_SheetActivate;
        }
        #endregion

        internal void ThisWorkbook_SheetActivate(object Sh)
        {
            if (Sh == null) return;

            string tab = ((Excel.Worksheet)Sh).Name;

            if (tab.Contains(ActionPane1.SMInvoices_TabName))
            {
                _myActionPane.btnPreviewOrCopyOffline.Enabled = true;
                _myActionPane.btnPreviewOrCopyOffline.Text = "Preview Invoice" + (_myActionPane.MoreThanOneInvoiceSelected ? "s " : "");
                _myActionPane.btnPreviewOrCopyOffline.BackColor = System.Drawing.Color.Honeydew;

                _myActionPane.btnDeliverInvoices.Enabled = false;
                _myActionPane.btnDeliverInvoices.BackColor = System.Drawing.SystemColors.ControlLight;

            }
            else if (tab.Contains(Globals.BaseSearch.Name))
            {
                _myActionPane.btnDeliverInvoices.Enabled = false;
                _myActionPane.btnDeliverInvoices.BackColor = System.Drawing.SystemColors.ControlLight;
                _myActionPane.btnPreviewOrCopyOffline.Enabled = false;
                _myActionPane.btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;
            }
            else if (tab.Contains(ActionPane1.Recipients_TabName))
            {
                _myActionPane.btnDeliverInvoices.BackColor = System.Drawing.Color.Honeydew;
                _myActionPane.btnDeliverInvoices.Enabled = true;

                _myActionPane.btnPreviewOrCopyOffline.Enabled = true;
                _myActionPane.btnPreviewOrCopyOffline.Text = "Save Invoices Offline";
                _myActionPane.btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;

                _myActionPane.btnGetInvoices.BackColor = System.Drawing.SystemColors.ControlLight;
            }
            else
            {
                if (int.TryParse(tab.Trim(), out int tryInt))
                {
                    _myActionPane.btnDeliverInvoices.BackColor = System.Drawing.Color.Honeydew;
                    _myActionPane.btnDeliverInvoices.Enabled = true;

                    _myActionPane.btnPreviewOrCopyOffline.Enabled = true;
                    _myActionPane.btnPreviewOrCopyOffline.Text = "Save Invoices Offline";
                    _myActionPane.btnPreviewOrCopyOffline.BackColor = System.Drawing.SystemColors.ControlLight;

                    _myActionPane.btnGetInvoices.BackColor = System.Drawing.SystemColors.ControlLight;

                    //_myActionPane.btnPreviewOrCopyOffline.Focus();
                    //_myActionPane.btnPrint.Enabled = true;
                }
            }
        }

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                string wkbSaveAsName = "McK SM Invoice" + (_myActionPane.MoreThanOneInvoiceSelected ? "s" : " " + ((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Name.Trim());

                Cancel = SavePrompt(Globals.ThisWorkbook.Worksheets.Parent, wkbSaveAsName);

                if (_myActionPane._wsSMInvoices != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane._wsSMInvoices);
                if (_myActionPane._wsInvoiceInputListSearch != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane._wsInvoiceInputListSearch);
            }
            catch (System.Exception) { }
        }

        public static bool SavePrompt(Excel.Workbook workbook, string saveAsName = null)
        {
            DialogResult action;
            bool cancel = false;

            if (!workbook.Saved)
            {
                action = MessageBox.Show("Would you like to save a copy of the workbook for future reference?", "Save Workbook", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                if (action == DialogResult.Cancel) cancel = true;
                if (action == DialogResult.No)
                {
                    workbook.Saved = true;
                    cancel = false;
                }
                if (action == DialogResult.Yes)
                {
                    IOexcel.SaveWorksheetOffline(workbook.ActiveSheet, saveAsName, true);
                    workbook.Saved = true;
                    cancel = false;
                }
            }
            return cancel;
        }
    }
}
