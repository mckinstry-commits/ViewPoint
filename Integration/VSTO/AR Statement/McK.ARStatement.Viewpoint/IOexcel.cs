using System;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;
using System.IO;

namespace McK.ARStatement.Viewpoint
{
    internal static class IOexcel
    {
        //internal static Excel.Workbook thisWorkbook => Globals.ThisWorkbook.Worksheets.Parent;

        /// <summary>
        /// Copies Worksheet or Workbook to a new Workbook, if wsSource is null, active sheet is used.
        /// </summary>
        /// <param name="wsSource">Worksheet to copy. If not specified, ThisWorkbook's active sheet is copied.</param>
        /// <param name="saveAsName">Workbook file name</param>
        /// <param name="copyEntireWorkbook">Entire workbook is copied.</param>
        /// <returns></returns>
        public static bool CopyOfflineAsExcel(Excel.Worksheet wsSource = null, string saveAsName = null, bool copyEntireWorkbook = true)
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
                        foreach (Excel.Worksheet ws in wkbSrc.Sheets)
                        {
                            if (ws == Globals.BaseStatement.InnerObject ||
                                ws == Globals.Customers.InnerObject ||
                                ws == Globals.MCK.InnerObject ||
                                ws == Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook._myActionPane.SheetName_StatementsGrid]) continue;

                            ws.Copy(After: wkbDest.Sheets["Sheet1"]);
                        }
                    }
                    else
                    {
                        wsSrc.Copy(After: wkbDest.ActiveSheet);
                    }

                    ((Excel.Worksheet)wkbDest.Sheets["Sheet1"]).Delete();

                    // Save workbook to user specified path
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

        public static bool CopyPDFToFolder(string PDFfullFilePath, string copyToPathFullFileName)
        {
            bool success = false;

            try
            {
                if (File.Exists(PDFfullFilePath))
                {
                    File.Copy(PDFfullFilePath, copyToPathFullFileName, true);
                    success = true;
                }

            }
            catch (Exception)
            {
                throw;
            }
            return success;
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
                    IOexcel.CopyOfflineAsExcel(workbook.ActiveSheet, saveAsName, true);
                    workbook.Saved = true;
                    cancel = false;
                }
            }
            return cancel;
        }

        /// <summary>
        /// Returns a tmp.PDF file version of the worksheet. Also valid in Office 2007 and Office 2010
        /// </summary>
        /// <param name="worksheet"></param>
        /// <returns>full file path + name</returns>
        public static string GetWorksheetAsPDF(Excel.Worksheet worksheet, string fileName = null)
        {
            string tempPDF = "";

            try
            {
                tempPDF = System.IO.Path.GetTempPath() + fileName ?? worksheet.Name;
                tempPDF += ".pdf";
                worksheet.ExportAsFixedFormat(Excel.XlFixedFormatType.xlTypePDF, tempPDF);
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return tempPDF;
        }
    }
}
