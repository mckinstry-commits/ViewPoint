using Excel = Microsoft.Office.Interop.Excel;


using System.Windows.Forms;
using System;
using System.Runtime.InteropServices;

namespace McKUserCreation
{
    public partial class Sheet2
    {
        internal ActionPane1 _myActionPane = new ActionPane1();

        private void Sheet2_Startup(object sender, System.EventArgs e)
        {
            System.Drawing.Rectangle screen = Screen.FromControl((Control)_myActionPane).Bounds;
            int width;

            switch (screen.Width)
            {
                case 1920:
                    width = 233; // desk monitor
                    break;
                case 1280:
                    width = 245; // laptop montitor
                    break;
                case 1024:
                    width = 248; // smaller devices
                    break;
                default:
                    width = 242;
                    break;
            }
            this.Application.CommandBars["Task Pane"].Width = width;

            // clone sheet from hidden template
            Excel._Worksheet ws = null;

            try
            {
                Globals.Sheet2.Copy(after: Globals.ThisWorkbook.Sheets["UserPostx"]);

                ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[2];
                ws.Name = "UserPost";
                ws.Cells.Locked = true;
                ws.get_Range("A1:D1").EntireColumn.Locked = false;
                ws.get_Range("A1:D1").Locked = true;
                HelperUI.ProtectSheet(ws);
                Globals.Sheet2.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
            }
            catch (Exception) { throw; }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        private void Sheet2_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(Sheet2_Startup);
            this.Shutdown += new System.EventHandler(Sheet2_Shutdown);
        }

        #endregion

    }
}
