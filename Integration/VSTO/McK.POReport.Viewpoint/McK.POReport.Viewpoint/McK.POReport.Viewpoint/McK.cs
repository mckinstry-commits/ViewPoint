using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using McK.Data.Viewpoint;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.POReport.Viewpoint
{
    public partial class McK
    {
        private void Home_Startup(object sender, System.EventArgs e)
        {
            string env = "";

            Globals.PO.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
            Globals.TandC.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
            Globals.TandCEquip.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

            Globals.ThisWorkbook.Names.Item("AppName").RefersToRange.Formula = "McK PO Report " + Globals.ThisWorkbook._actionPane.ProductVersion;

            if (HelperData._conn_string.Contains("MCKTESTSQL05", StringComparison.OrdinalIgnoreCase))
            {
                env = "Dev";
            }
            else if (HelperData._conn_string.Contains("VPSTAGINGAG", StringComparison.OrdinalIgnoreCase))
            {
                env = "Stg";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL01", StringComparison.OrdinalIgnoreCase))
            {
                env = "Proj";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL02", StringComparison.OrdinalIgnoreCase))
            {
                env = "Upg";
            }
            else if (HelperData._conn_string.Contains("MCKTESTSQL01", StringComparison.OrdinalIgnoreCase))
            {
                env = "Trng";
            }
            else if (HelperData._conn_string.Contains("VIEWPOINTAG", StringComparison.OrdinalIgnoreCase))
            {
                env = "";
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Interior.ColorIndex = 2; // white
            }
            else
            {
                env = "Unspecified";
            }

            Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = env;

            Globals.ThisWorkbook._actionPane.lblAppName.Text = env != "" ? "(" + env + ")" : "Prod.";

        }

        //private void Home_Shutdown(object sender, System.EventArgs e)
        //{
        //}

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(Home_Startup);
            //this.Shutdown += new System.EventHandler(Home_Shutdown);
        }

        #endregion

    }
}
