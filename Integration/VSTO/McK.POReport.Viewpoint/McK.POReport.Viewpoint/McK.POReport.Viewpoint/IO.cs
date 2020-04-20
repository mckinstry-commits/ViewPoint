﻿using System;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
//using Mck.Data.Viewpoint;
using System.Runtime.InteropServices;
using Mck.Data.Viewpoint;

namespace McK.POReport.Viewpoint
{
    internal static class IO
    {
        internal static Excel.Workbook thisWorkbook => Globals.ThisWorkbook.Worksheets.Parent;

        public static bool CopyOffline(dynamic po, string wkbName = "")
        {
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            Excel.Workbook wkbFrom = thisWorkbook;
            Excel.Workbook wkbTo = null;
            Excel.Worksheet ws = null;

            try
            {
                DialogResult action;

                saveFileDialog.Filter = "Excel Workbook (*.xlsx) | *.xlsx"; //"Excel Template (*.xltx) | *.xltx"; 
                saveFileDialog.InitialDirectory = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                saveFileDialog.RestoreDirectory = false;
                saveFileDialog.FileName = wkbName + " " + string.Format("{0:M-dd-yyyy}", DateTime.Today) + ".xlsx";

                action = saveFileDialog.ShowDialog();

                if (action == DialogResult.OK)
                {
                    if (po.fullLogging) POLog.LogAction(POLog.Action.COPY_OFFLINE, po.JCCo, po.POFrom, po.POTo, po.DateFrom, po.DateTo, Globals.ThisWorkbook.Application.Version);

                    HelperUI.RenderOFF();

                    // Clone workbook
                    wkbTo = wkbFrom.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                    wkbFrom.Application.DisplayAlerts = false;

                    //foreach (Excel.Worksheet ws in wkbFrom.Sheets)
                    //{
                    //    if (!ws.Name.Contains(Globals.McK.Name)
                    //        && !ws.Name.Contains(Globals.PO.Name)
                    //        && !ws.Name.Contains(Globals.TandC.Name)
                    //        && !ws.Name.Contains(Globals.TandCEquip.Name)
                    //       )
                    //    {
                    //        ws.Copy(After: wkbTo.Sheets["Sheet1"]);
                    //    }
                    //}

                    for (int i = wkbFrom.Sheets.Count; i >= 1; i--)
                    {
                        ws = (Excel.Worksheet) wkbFrom.Sheets[i];
                        if (   !ws.Name.Contains(Globals.McK.Name)
                            && !ws.Name.Contains(Globals.PO.Name)
                            && !ws.Name.Contains(Globals.TandC.Name)
                            && !ws.Name.Contains(Globals.TandCEquip.Name)
                           )
                        {
                            ws.Copy(After: wkbTo.Sheets["Sheet1"]);
                        }
                    }

                    ((Excel.Worksheet)wkbTo.Sheets["Sheet1"]).Delete();

                    // Save workbook to user specified path
                    wkbTo.SaveAs(saveFileDialog.FileName);
                    wkbTo.Close();

                    return false;
                }
                else if (action == DialogResult.Cancel)
                {
                    return true;
                }
            }
            catch (Exception)
            {
                if (wkbTo != null) wkbTo.Close(false); 
                throw;
            }
            finally
            {
                HelperUI.RenderON();
                wkbFrom.Application.DisplayAlerts = true;

                if (wkbTo != null) Marshal.ReleaseComObject(wkbTo);
                if (wkbFrom != null) Marshal.ReleaseComObject(wkbFrom);
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
            return false;
        }

        public static bool SavePrompt(Excel.Workbook workbook, dynamic vsto, string wkbName = "")
        {
            // there's at least 1 PO
            DialogResult action;

            if (!workbook.Saved)
            {
                action = MessageBox.Show("Would you like to save a copy of the workbook for future reference?", "Save Workbook", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Question);
                if (action == DialogResult.Cancel) return true;
                if (action == DialogResult.No) workbook.Saved = true;
                if (action == DialogResult.Yes)
                {
                    CopyOffline(vsto, wkbName);
                    return workbook.Saved = true;
                }
            }
            return false;
        }

        public static string GetWorkbookAsPDF()
        {
            Excel.Worksheet wsTo = null;
            Excel.Worksheet wsFrom = null;
            Excel.Workbook wkbFrom = null;
            Excel.Workbook wkbTo = null;
            string tempPDF = "";

            try
            {
                wkbFrom = thisWorkbook;
                wkbTo = wkbFrom.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                wkbFrom.Application.DisplayAlerts = false;

                for (int i = wkbFrom.Sheets.Count; i >= 1; i--)
                {
                    wsFrom = (Excel.Worksheet) wkbFrom.Sheets[i];
                    if (!wsFrom.Name.Contains(Globals.McK.Name)
                        && !wsFrom.Name.Contains(Globals.PO.Name)
                        && !wsFrom.Name.Contains(Globals.TandC.Name)
                        && !wsFrom.Name.Contains(Globals.TandCEquip.Name)
                       )
                    {
                        wsFrom.Copy(After: wkbTo.Sheets["Sheet1"]);
                    }
                }

                //wkbFrom.ActiveSheet.Copy(After: wkbTo.Sheets["Sheet1"]);
                wkbTo.Sheets["Sheet1"].Delete();

                tempPDF = System.IO.Path.GetTempPath() + "PO " + wkbTo.ActiveSheet.Name + ".pdf";

                //wkbTo.SaveAs(tempFile);

                wkbTo.Save();

                // also valid in Office 2007 and Office 2010
                wkbTo.ExportAsFixedFormat(Excel.XlFixedFormatType.xlTypePDF, tempPDF);

                wkbTo.Close();

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
                wkbFrom.Application.DisplayAlerts = true;

                if (wkbTo != null) Marshal.ReleaseComObject(wkbTo);
                if (wkbFrom != null) Marshal.ReleaseComObject(wkbFrom);
                if (wsTo != null) Marshal.ReleaseComObject(wsTo);
                if (wsFrom != null) Marshal.ReleaseComObject(wsFrom);
            }

            return tempPDF;
        }
    }
}
