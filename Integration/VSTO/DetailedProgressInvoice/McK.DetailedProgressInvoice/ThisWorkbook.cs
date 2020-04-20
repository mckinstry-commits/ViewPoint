using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    public partial class ThisWorkbook
    {
        internal ActionsPane _actionPane = new ActionsPane();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_actionPane);

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            this.Application.CommandBars["Task Pane"].Width = 175;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }

            Globals.Invoice.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

            string title = Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula;

            Globals.ThisWorkbook.Names.Item("Title").RefersToRange.Formula = title + " v." + _actionPane.ProductVersion;

            string env = (string)_actionPane.cboTargetEnvironment.SelectedItem;

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

            // TEST 
            //_actionPane.btnGetInvoices_Click(null, null);
        }

        //private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        //{
        //}

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                if (Invoices.Unique != 0)
                {
                    string wkbName = "McK Detail Invoice"; 
                    wkbName += Invoices.Unique > 1 ? "s " + _actionPane.txtInvoiceFrom.Text + " - " + _actionPane.txtInvoiceTo.Text : " " + _actionPane.txtInvoiceFrom.Text;

                    Cancel = IO.SavePrompt(_actionPane.workbook, _actionPane.GetUIFields(), wkbName);
                    if (_actionPane.workbook != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_actionPane.workbook);
                }
            }
            catch (Exception) { }
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisWorkbook_Startup);
            //this.Shutdown += new System.EventHandler(ThisWorkbook_Shutdown);
            this.BeforeClose += new Excel.WorkbookEvents_BeforeCloseEventHandler(ThisWorkbook_BeforeClose);
        }

        #endregion

    }
}
