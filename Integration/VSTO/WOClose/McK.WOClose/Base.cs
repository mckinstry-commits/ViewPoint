using Excel = Microsoft.Office.Interop.Excel;
using System;
using System.Runtime.InteropServices;

namespace McKWOClose
{
    public partial class Sheet1
    {
        private void Sheet1_Startup(object sender, System.EventArgs e)
        {
            this.Application.CommandBars["Task Pane"].Width = HelperUI.GetDynamicPaneWidth();

            // clone sheet from hidden template
            try
            {
                Globals.Base.Copy(after: Globals.ThisWorkbook.Sheets[Globals.Base.Index]);
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.ThisWorkbook._myActionPane.RenameProtectNewSheet();
            }
            catch (Exception) { throw; }
        }

        private void Sheet1_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void internalStartup()
        {
            this.Startup += new System.EventHandler(Sheet1_Startup);
            this.Shutdown += new System.EventHandler(Sheet1_Shutdown);
        }

        #endregion

    }
}
