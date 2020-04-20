using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;
using System.Runtime.InteropServices;


namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    public partial class Invoice
    {
        private void Sheet1_Startup(object sender, System.EventArgs e)
        {
            //object missing = System.Type.Missing;

            //// Get starting detail row number and column count 
            //try
            //{
            //   // ws = (Excel.Worksheet) Globals.ThisWorkbook.Application.Sheets[2];
            //    rng = UsedRange.Find("*", missing,
            //                            Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
            //                            Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, missing,
            //                            missing, missing);
            //    if (rng != null)
            //    {
            //        startDetailRow = (uint)rng.Row + 1;
            //        colCnt = rng.End[Excel.XlDirection.xlToRight].Column;
            //        detailRowsFound = true;
                    
            //    }
            //}
            //catch (Exception)
            //{
            //    throw;
            //}
            //finally
            //{
            //    //if (rng != null) Marshal.ReleaseComObject(rng); rng = null;   
            //}

        }

        private void Sheet1_Shutdown(object sender, System.EventArgs e) { }

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
