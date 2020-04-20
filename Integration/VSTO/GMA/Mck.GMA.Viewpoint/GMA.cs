using Excel = Microsoft.Office.Interop.Excel;

namespace McK.GMA.Viewpoint
{
    public partial class GMA
    {
        private void GMA_Startup(object sender, System.EventArgs e)
        {
           Cells.Locked = false;
           UsedRange.Locked = true;
           get_Range("C19:D19").Locked = false;
           get_Range("B18:D18").Locked = false;
           get_Range("B31:B33").Locked = false;
           get_Range("D39").Locked = false;
           get_Range("B41:C41").Locked = false;
           get_Range("B42").Locked = false;
           get_Range("C43").Locked = false;
           get_Range("D44").Locked = false;
           get_Range("B47:B49").Locked = false;
           get_Range("C49").Locked = false;
           get_Range("B59").Locked = false;
           get_Range("B10:E10").Locked = false;

            Excel.Worksheet ws = Globals.ThisWorkbook.Sheets[Globals.GMA.Name];
            HelperUI.ProtectSheet(ws, false, false);
            HelperUI.PrintPage_GMAXSetup(ws);
            Globals.GMABLANK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
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
            this.Startup += new System.EventHandler(GMA_Startup);
            this.Shutdown += new System.EventHandler(Sheet2_Shutdown);
        }

        #endregion

    }
}
