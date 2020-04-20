using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    public partial class McK
    {
        private void Home_Startup(object sender, System.EventArgs e)
        {
            string env = "";

            Globals.Invoice.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

            this.get_Range("F25").Formula = "JB Detailed Progress Invoice " + Globals.ThisWorkbook._actionPane.ProductVersion;

            // cater for all environments 
            if (Globals.ThisWorkbook._actionPane.ProductName.Contains("-Dev"))
            {
                env = "Dev";
            }
            else if (Globals.ThisWorkbook._actionPane.ProductName.Contains("-Stg"))
            {
                env = "Stg";
            }
            else
            {
                env = "Prod.";
            }

            if (env != "")
            {

                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Formula = env;
            }
            else // Prod
            {
                Globals.ThisWorkbook.Names.Item("Environment").RefersToRange.Interior.ColorIndex = 2;
            }
            Globals.ThisWorkbook._actionPane.lblEnvironment.Text = env;
            //Globals.ThisWorkbook._actionPane.lblAppName.Text = env != "" ? "(" + env + ")" : "Prod.";
        }

        private void Home_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(Home_Startup);
            this.Shutdown += new System.EventHandler(Home_Shutdown);
        }

        #endregion

    }
}
