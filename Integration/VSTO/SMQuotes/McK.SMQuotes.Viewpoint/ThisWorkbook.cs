using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using System.Windows.Forms;

namespace McK.SMQuotes.Viewpoint
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane1 _myActionPane = new ActionPane1();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            string title = "";
            string env = "";

            // Add Custom Action Pane to Excel application context   
            ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            Application.CommandBars["Task Pane"].Width = 240;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)Application.Top + 100;
            }

            try
            {
                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.BaseQuotes.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.Customers.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.QuoteStandard.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.QuoteDetail.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.MCK.Environment.Formula =_myActionPane.Environ;
            }
            catch (System.Exception) { throw; }

            RadioButton rdoBtn = (RadioButton)Globals.Customers.Controls["rdoActiveCustomers"];
            rdoBtn.Checked = true;
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            rdoBtn = (RadioButton)Globals.Customers.Controls["rdoARCustomers"];
            rdoBtn.CheckedChanged += _myActionPane.RdoBtnGetCustomers_CheckedChanged;

            title = Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula;

            Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula = title + " v." + _myActionPane.ProductVersion;

            env = (string)_myActionPane.cboTargetEnvironment.SelectedItem;

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

            if (tab.Contains(ActionPane1.SMQuotes_TabName))
            {
                bool thereAreOpenQuotes = false;

                foreach (Excel.Worksheet w in this.Worksheets)
                {
                    if (int.TryParse(w.Name.Trim(), out int tryInt))
                    {
                        thereAreOpenQuotes = true;
                        break;
                    }
                }

                if (thereAreOpenQuotes)
                {
                    _myActionPane.btnPreview.Enabled = true;
                    _myActionPane.btnPreview.Text = "Preview Quote" + (_myActionPane.MoreThanOneQuoteSelected ? "s " : "");
                    _myActionPane.btnPreview.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnEmail.Enabled = true;
                    _myActionPane.btnEmail.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnSave.Enabled = true;
                    _myActionPane.btnSave.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnPrint.Enabled = true;
                    _myActionPane.btnPrint.BackColor = System.Drawing.Color.Honeydew;
                }
                else
                {
                    _myActionPane.btnPreview.Enabled = false;
                    _myActionPane.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;

                    _myActionPane.btnEmail.Enabled = false;
                    _myActionPane.btnEmail.BackColor = System.Drawing.SystemColors.ControlLight;

                    _myActionPane.btnSave.Enabled = false;
                    _myActionPane.btnSave.BackColor = System.Drawing.SystemColors.ControlLight;

                    _myActionPane.btnPrint.Enabled = false;
                    _myActionPane.btnPrint.BackColor = System.Drawing.SystemColors.ControlLight;
                }

            }
            else if (tab.Contains(Globals.BaseQuotes.Name))
            {
                _myActionPane.btnPreview.Enabled = false;
                _myActionPane.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;

            }
            else
            {
                if (int.TryParse(tab.Trim(), out int tryInt))
                {

                    _myActionPane.btnEmail.Enabled = true;
                    _myActionPane.btnEmail.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnPrint.Enabled = true;
                    _myActionPane.btnPrint.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnSave.Enabled = true;
                    _myActionPane.btnSave.BackColor = System.Drawing.Color.Honeydew;

                    _myActionPane.btnPreview.Enabled = true;
                    _myActionPane.btnPreview.BackColor = System.Drawing.SystemColors.ControlLight;

                    _myActionPane.btnGetQuotes.Enabled = true;
                    _myActionPane.btnGetQuotes.BackColor = System.Drawing.Color.Honeydew;

                }
            }
        }

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                string wkbSaveAsName = "McK SM Quote" + (_myActionPane.MoreThanOneQuoteSelected ? "s" : " " + ((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Name.Trim());

                Cancel = IOexcel.SavePrompt(Globals.ThisWorkbook.Worksheets.Parent, wkbSaveAsName);

                if (_myActionPane._wsQuotes != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane._wsQuotes);
            }
            catch (System.Exception) { }
        }

    }
}
