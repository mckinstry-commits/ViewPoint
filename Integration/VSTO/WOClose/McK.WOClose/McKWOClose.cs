

namespace McKWOClose
{
    public partial class Sheet1
    {
        private void Sheet1_Startup(object sender, System.EventArgs e)
        {
            Globals.ThisWorkbook._myActionPane._ws = Globals.ThisWorkbook.Application.Sheets[this.Name];

            this.Cells.Locked = true;
            this.Cells.get_Range("A1").EntireColumn.Locked = false;
            this.Cells.get_Range("A1").Locked = true;
            HelperUI.ProtectSheet(Globals.ThisWorkbook._myActionPane._ws, true, true);

        }

        private void Sheet1_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(Sheet1_Startup);
            this.Shutdown += new System.EventHandler(Sheet1_Shutdown);
        }

        #endregion

    }
}
