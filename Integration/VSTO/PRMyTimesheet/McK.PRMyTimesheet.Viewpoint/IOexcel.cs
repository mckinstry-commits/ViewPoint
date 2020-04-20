using System;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace McK.PRMyTimesheet.Viewpoint
{
    internal static class IOexcel
    {
        //internal static Excel.Workbook thisWorkbook => Globals.ThisWorkbook.Worksheets.Parent;

        /// <summary>
        /// Copies Worksheet to a new Workbook, if wsSource is null, ThisWorkbook's active sheet is copied
        /// </summary>
        /// <param name="wsSource">Worksheet to copy. If not specified, ThisWorkbook's active sheet is copied.</param>
        /// <param name="saveAsName">Workbook file name</param>
        /// <param name="copyEntireWorkbook">Entire workbook is copied.</param>
        /// <returns></returns>
        public static bool CopyOffline(Excel.Worksheet wsSource = null, string saveAsName = null, bool copyEntireWorkbook = true)
        {
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            Excel.Worksheet wsSrc = null;
            Excel.Workbook wkbDest = null;
            Excel.Workbook wkbSrc = null;
            bool cancel = false;

            try
            {
                wsSrc = wsSource ?? Globals.ThisWorkbook.Application.ActiveSheet;
                wkbSrc = wsSrc.Parent;

                DialogResult action;
                saveFileDialog.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                saveFileDialog.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                saveFileDialog.RestoreDirectory = false;
                saveFileDialog.FileName = saveAsName ?? wsSrc.Name + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today) + ".xlsx";

                action = saveFileDialog.ShowDialog();

                if (action == DialogResult.OK)
                {
                    Globals.ThisWorkbook.Application.ScreenUpdating = false;

                    // create a new Workbook
                    wkbDest = wsSrc.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                    wsSrc.Application.DisplayAlerts = false;

                    if (copyEntireWorkbook)
                    {
                        // copy over preserving ordinals
                        for (int i = wkbSrc.Sheets.Count; i > 0 ; i--)
                        {
                            wkbSrc.Sheets[i].Copy(After: wkbDest.Sheets["Sheet1"]);
                        }
                    }
                    else
                    {
                        wsSrc.Copy(After: wkbDest.ActiveSheet);
                    }

                    // Save workbook to user specified path
                    ((Excel.Worksheet)wkbDest.Sheets["Sheet1"]).Delete();

                    wkbDest.SaveAs(saveFileDialog.FileName);
                    wkbDest.Close();

                    cancel = false;
                }
                else if (action == DialogResult.Cancel)
                {
                    cancel = true;
                }
            }
            catch (Exception)
            {
                if (wkbDest != null) wkbDest.Close(false); 
                throw;
            }
            finally
            {
                Globals.ThisWorkbook.Application.ScreenUpdating = true;
                //wkbFrom.Application.DisplayAlerts = true;

                if (wkbDest != null) Marshal.ReleaseComObject(wkbDest);
                if (wsSrc != null) Marshal.ReleaseComObject(wsSrc);
            }
            return cancel;
        }

        public static bool SavePrompt(Excel.Workbook workbook, string saveAsName = null)
        {
            DialogResult action;
            bool cancel = false;

            if (!workbook.Saved)
            {
                action = MessageBox.Show("Would you like to save a copy of the workbook for future reference?", "Save Workbook", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                if (action == DialogResult.Cancel) cancel = true;
                if (action == DialogResult.No)
                {
                    workbook.Saved = true;
                    cancel = false;
                }
                if (action == DialogResult.Yes)
                {
                    IOexcel.CopyOffline(workbook.ActiveSheet, saveAsName, true);
                    workbook.Saved = true;
                    cancel = false;
                }
            }
            return cancel;
        }

        /// <summary>
        /// Returns a tmp.PDF file version of the worksheet
        /// </summary>
        /// <param name="worksheet"></param>
        /// <returns></returns>
        public static string GetWorksheetAsPDF(Excel.Worksheet worksheet)
        {
            Excel.Worksheet wsDest = null;
            Excel.Worksheet wsSrc = null;
            Excel.Workbook wkbDest = null;
            string tempPDF = "";

            try
            {
                //wkbFrom = thisWorkbook;
                wkbDest = worksheet.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                worksheet.Application.DisplayAlerts = false;

                worksheet.Copy(After: wkbDest.Sheets["Sheet1"]);
                wkbDest.Sheets["Sheet1"].Delete();

                tempPDF = System.IO.Path.GetTempPath() + worksheet.Name + ".pdf";

                wkbDest.Save();

                // also valid in Office 2007 and Office 2010
                wkbDest.ExportAsFixedFormat(Excel.XlFixedFormatType.xlTypePDF, tempPDF);
                wkbDest.Close();
            }
            //catch (System.IO.IOException ex)
            //{
            //    ShowErr(ex.Message);
            //}
            catch (Exception ex)
            {
                throw ex;
            }
            finally
            {
                worksheet.Application.DisplayAlerts = true;

                if (wkbDest != null) Marshal.ReleaseComObject(wkbDest);
                if (wsDest != null) Marshal.ReleaseComObject(wsDest);
                if (wsSrc != null) Marshal.ReleaseComObject(wsSrc);
            }

            return tempPDF;

            //foreach (Excel.Worksheet _ws in workbook.Worksheets)
            //{
            //    if ( !_ws.Name.Contains(Globals.McK.Name) || !_ws.Name.Contains(Globals.Invoice.Name) )
            //    {
            //        wkbFrom.Sheets[_ws.Name].Copy(After: wkbTo.Sheets["Sheet1"]);
            //    }
            //}
            //wkbFrom.Sheets[((Excel.Worksheet)wkbFrom.ActiveSheet).Name].Copy(After: wkbTo.Sheets["Sheet1"]);

        }
    }
}
