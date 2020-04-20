using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using Microsoft.Office.Tools.Excel;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.GMA.Viewpoint
{
    public partial class ThisWorkbook
    { 
        // Global Variable for Custom Action Pane
        internal ActionsPaneGMA _myActionPane = new ActionsPaneGMA();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            this.Application.CommandBars["Task Pane"].Width = 150;// HelperUI.GetDynamicPaneWidth();

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }
            Globals.Summary.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
        }

        //private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        //{
        //}

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                Cancel = _myActionPane.SavePrompt();
                if (ActionsPaneGMA.workbook != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(ActionsPaneGMA.workbook);
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
