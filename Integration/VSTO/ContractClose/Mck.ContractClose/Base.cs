﻿using System;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKContractClose
{
    public partial class Base
    {
        private void Base_Startup(object sender, System.EventArgs e)
        {
            // clone sheet from hidden template
            try
            {
                Globals.Base.Copy(after: Globals.ThisWorkbook.Sheets[Globals.Base.Index]);

                Globals.ThisWorkbook._myActionPane._ws = (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.Base.Index + 1];
                Globals.ThisWorkbook._myActionPane._ws.Name = ActionPane1.tabName;
                Globals.ThisWorkbook._myActionPane._ws.Cells.Locked = true;
                Globals.ThisWorkbook._myActionPane._ws.get_Range("A1:D1").EntireColumn.Locked = false;
                Globals.ThisWorkbook._myActionPane._ws.get_Range("A1:D1").Locked = true;
                HelperUI.ProtectSheet(Globals.ThisWorkbook._myActionPane._ws);
                Globals.Base.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
            }
            catch (Exception) { throw; }
        }

        private void Base_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(Base_Startup);
            this.Shutdown += new System.EventHandler(Base_Shutdown);
        }

        #endregion

    }
}