using System;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;
using System.IO;

namespace McK.SMInvoice.Viewpoint
{
    internal abstract class IOexcel
    {
        /// <summary>
        /// Copies Worksheet or Workbook to a new Workbook, if wsSource is null, active sheet is used.
        /// </summary>
        /// <param name="wsSource">Worksheet to copy. If not specified, ThisWorkbook's active sheet is copied.</param>
        /// <param name="saveAsName">Workbook file name</param>
        /// <param name="copyEntireWorkbook">Entire workbook is copied.</param>
        /// <returns></returns>
        public static bool SaveWorksheetOffline(Excel.Worksheet wsSource = null, string saveAsName = null, bool copyEntireWorkbook = true)
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
                            if (ws == Globals.BaseInvoiceList.InnerObject ||
                                ws == Globals.BaseSearch.InnerObject ||
                                ws == Globals.Customers.InnerObject ||
                                ws == Globals.MCK.InnerObject ||
                                ws == Globals.ThisWorkbook.Sheets[ActionPane1.SMInvoices_TabName]) continue;

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

        /// <summary>
        /// Copies a file a specified folder location
        /// </summary>
        /// <param name="fullFilePath"></param>
        /// <param name="copyToPathFullFileName"></param>
        /// <returns></returns>
        public static bool CopyFileToFolder(string fullFilePath, string copyToPathFullFileName)
        {
            bool success = false;

            try
            {
                if (File.Exists(fullFilePath))
                {
                    File.Copy(fullFilePath, copyToPathFullFileName, true);
                    success = true;
                }

            }
            catch (Exception)
            {
                throw;
            }
            return success;
        }

        /// <summary>
        /// Returns a tmp.PDF file version of the worksheet
        /// </summary>
        /// <param name="worksheet"></param>
        /// <returns></returns>
        public static string GetWorksheetAsPDF(Excel.Worksheet worksheet)
        {
            string tempPDF = "";

            try
            {
                worksheet.Application.DisplayAlerts = false;

                tempPDF = System.IO.Path.GetTempPath() + worksheet.Name + ".pdf";

                worksheet.ExportAsFixedFormat(Excel.XlFixedFormatType.xlTypePDF, tempPDF);

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
            }

            return tempPDF;
        }

        public static void OpenSpreadsheet(string fullFileLocationPath)
        {
            try
            {
                Globals.ThisWorkbook.Application.Workbooks.Open(fullFileLocationPath);
            }
            catch (Exception)
            {
                throw;
            }
        }
    }
}
