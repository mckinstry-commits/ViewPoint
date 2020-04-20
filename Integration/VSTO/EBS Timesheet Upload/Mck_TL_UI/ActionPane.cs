using System;
using System.Data;
using System.Collections.Generic;
using System.Text;
using System.Windows.Forms;
using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using McK.Data.Viewpoint;
using System.Runtime.InteropServices;
using System.Linq;

namespace Mck_TL_UI
{
    partial class ActionPane : UserControl
    {
        /*****************************************************************************************************************;

                                                  EBS Timesheet Load                                 

                                                copyright McKinstry 2017                                                

        This Microsoft Excel VSTO solution was developed by McKinstry in 2017 in order to upload EBS timesheet data to Viewpoint.  
        This software is the property of McKinstry and requires express written permission to be used by any Non-McKinstry employee or entity                     

                                             Axosoft # 101049

        Release                      Date                     Details                                              
        -------                      ----                     -------                                             
        1.0.0.0 Initial Dev         8/25/2017                 Viewpoint/SQL Dev:  Leo Gurdian  / Theresa Parker  
                                                              Project Manager:    Theresa Parker               
                                                              Excel VSTO Dev:     Jonathan Ziebell                    

        1.0.1.0                     10/31/2017              - change file name format to:  ‘EBSTimesheet_VP_Import’ DATETIME ‘.csv’. 
                                                            - Remove blank row at the end of the csv file
                                                            - change 'save to' production path: \\MCKVIEWPOINT\viewpoint Repository\bulk inserts\ETL\PR\EBS\AutoImport
        1.0.1.2                                             - prod path was missing backslash.  also updated staging path.
        1.0.1.3                     11/7/2017               - append backslash if missing from URI path
                                                            - check if URI path exists (non-blocking thread)
        1.0.1.4                     11/29/2017              - Remove the column headers on the Detail tab as VP import is reading as row data
                                                            - Protect the Detail tab from user input
                                                            - disable drawing on import & upload
                                                            - added solution name, version and environment labels
                                                            - NetPath can now handle rooted paths
        1.0.1.5                     12/6/2017              - Fix Hours format to represent negative numbers with a negative symbol as VP import rejects parentheses. 
        1.0.1.7                     12/6/2017              - upped label font size and expanded 'em, form autoscale to DPI
        1.0.1.8                     1/11/2018              - group Company tabs; one row per employee w/ total Hours per week      
                                                           - signed w/ McKinstry certificate
                                                              
        *******************************************************************************************************************/

        internal const string pwd = "ebs";

        internal Excel.Worksheet summary_ws = null;
        internal Excel.Range productName = null;
        internal Excel.Range dbSource = null;

        public ActionPane()
        {
            InitializeComponent();

            string env = "";

            if (HelperData._conn_string.Contains("VIEWPOINTAG"))
            {
                env = "(Prod)";
            }
            else if (HelperData._conn_string.Contains("VPSTAGINGAG"))
            {
                env = "(Staging)";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL01"))
            {
                env = "(Project)";
            }
            else if (HelperData._conn_string.Contains("SEA-STGSQL02"))
            {
                env = "(Upgrade)";
            }
            else if (HelperData._conn_string.Contains("MCKTESTSQL05"))
            {
                env = "(Dev)";
            }
            this.lblEnvironment.Text = env;
            this.lblVersion.Text = "v." + this.ProductVersion;
        }

        private void btn_Import_Click(object sender, EventArgs e)
        {
            string orig_text = btn_Import.Text;
            btn_Import.Text = "Processing...";
            btn_Import.Enabled = false;
            Excel.ListObject xltable = null;
            Excel.Worksheet co1_ws = null;
            Excel.Worksheet co20_ws = null;
            Excel.Worksheet detail_ws = null;
            Excel.Shape xlTextBox = null;

            int sumStartCol = 4;
            int sumTotalsRow;

            try
            {
                co1_ws = Globals.sht_Co1.InnerObject;
                co20_ws = Globals.sht_Co20.InnerObject;
                detail_ws = Globals.sht_Detail.InnerObject;
                //summary_ws = Globals.sht_Summary.InnerObject; // set in ThisWorkbook_Startup

                HelperUI.RenderOFF();

                var timesheet_summary = TimeSheetSummary.GetTimeSheetSummary();

                if (timesheet_summary.Count == 0)
                {
                    MessageBox.Show("No Rows found on Summary Timesheet table");
                    return;
                }

                if (detail_ws.ProtectionMode) detail_ws.Unprotect(ActionPane.pwd);

                //DELETE EXISTING TABLES IF PRESENT
                foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                {
                    if (ws.ListObjects.Count == 1)
                    {
                        // to prevent adding 1 extra row each time 
                        if (ws.Name.Contains("Sum"))
                        {
                            sumTotalsRow = ws.ListObjects[1].TotalsRowRange.Row; 
                            ws.ListObjects[1].Delete();                          // doesn't delete totals row
                            ws.Cells[sumTotalsRow, sumStartCol].EntireRow.Delete(); // dtotals row
                        }
                        else
                        {
                            ws.ListObjects[1].Delete();
                        }
                    }
                }

                // Summary
                xltable = SheetBuilderDynamic.BuildTable(summary_ws, timesheet_summary, "Timesheet_Summary", 13, sumStartCol, true, true);

                xltable.ListColumns["Hours"].DataBodyRange.NumberFormat = HelperUI.NumberFormat;
                xltable.ListColumns["Rows"].DataBodyRange.NumberFormat = HelperUI.NumberFormatx;

                xltable.ListColumns["Hours"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                xltable.ListColumns["Rows"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

                xltable.ListColumns["Company"].DataBodyRange.EntireColumn.ColumnWidth = 14.00;
                xltable.ListColumns["Rows"].DataBodyRange.EntireColumn.ColumnWidth = 14.00;
                xltable.ListColumns["Hours"].DataBodyRange.EntireColumn.ColumnWidth = 14.00;

                xltable.DataBodyRange.Font.Size = 11;

                summary_ws.get_Range("B7").NumberFormat = HelperUI.NumberFormatx;
                summary_ws.get_Range("C7").NumberFormat = HelperUI.NumberFormat;

                // Detail
                var timesheet_detail = TimeSheetDetail.GetTimeSheetDetail_ViewpointImport();
                xltable = SheetBuilderDynamic.BuildTable(detail_ws, timesheet_detail, "Timesheet_Detail", 1, 1, false, true);


                List<dynamic> table = TimeSheetDetail.GetEmployeeHrsByWeek();

                // Co 1
                var Co1_Detail = (dynamic)table.Where(r => r.Co.Value == 1).ToList();

                xltable =  SheetBuilderDynamic.BuildTable(co1_ws, Co1_Detail, "Co1Detail", 1, 1, false, true);

                AlignColumns(xltable);

                //throw new Exception("Test crash!");

                // CO 20
                var Co20_Detail = table.Where(r => r.Co.Value == 20).ToList();

                xltable = SheetBuilderDynamic.BuildTable(co20_ws, Co20_Detail, "Co20Detail", 1, 1, false, true);

                AlignColumns(xltable);

                #region retired code
                //Co1_Detail = Timesheet_Detail.Clone();
                //Co20_Detail = Timesheet_Detail.Clone();

                //var rowArray = Timesheet_Detail.Select("[1-Co] = 1");
                //foreach (DataRow row in rowArray)
                //{
                //    Co1_Detail.ImportRow(row);
                //}

                //rowArray = Timesheet_Detail.Select("[1-Co] = 20");
                //foreach (DataRow row in rowArray)
                //{
                //    Co20_Detail.ImportRow(row);
                //}


                //if (Co1_Detail.Rows.Count > 0)
                //{
                //    Co1_Detail.xltableName = "Co1Detail";

                //    SheetBuilder.BuildGenericTable(_Co1_ws, Co1_Detail, 0);
                //    xltable = _Co1_ws.ListObjects[1];
                //    xltable.ListColumns["9-Hours"].DataBodyRange.NumberFormat = HelperUI.NumberFormat;
                //    //xltable.ListColumns["2-Employee"].DataBodyRange.NumberFormat = HelperUI.NumberFormats;
                //    //xltable.ListColumns["5-JCCo"].DataBodyRange.NumberFormat = HelperUI.NumberFormats;
                //    xltable.ListColumns["3-PREndDate"].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;

                //    xltable.ShowTotals = false;

                //}

                //if (Co20_Detail.Rows.Count > 0)
                //{
                //    Co20_Detail.xltableName = "Co20Detail";

                //    SheetBuilder.BuildGenericTable(_Co20_ws, Co20_Detail, 0);

                //    xltable = _Co20_ws.ListObjects[1];
                //    xltable.ListColumns["9-Hours"].DataBodyRange.NumberFormat = HelperUI.NumberFormat;
                //    xltable.ShowTotals = false;
                //}

                //if (Co1_Detail.Rows.Count > 0)
                //{
                //    if (Co20_Detail.Rows.Count > 0)
                //    {
                //        SheetBuilder.BuildGenericTable(_Detail_ws, Timesheet_Detail, 0);
                //        xltable = _Detail_ws.ListObjects[1];
                //        xltable.ListColumns["9-Hours"].DataBodyRange.NumberFormat = HelperUI.NumberFormat;
                //        xltable.ShowTotals = false;
                //    }
                //}
                #endregion 

                // default cell selects
                ((Excel.Workbook)Globals.ThisWorkbook.Worksheets.Parent).Activate();
                co1_ws.Activate();
                co1_ws.get_Range("A1").Select();
                co20_ws.Activate();
                co20_ws.get_Range("A1").Select();

                summary_ws.Activate();
                xltable = summary_ws.ListObjects[1];
                sumTotalsRow = xltable.TotalsRowRange.Row;
                summary_ws.Cells[sumTotalsRow, sumStartCol].Select();

                xlTextBox = summary_ws.Shapes.Item("picLogo");
                if (xlTextBox != null) xlTextBox.Visible = Office.MsoTriState.msoFalse;

                productName.Font.Color = Excel.XlRgbColor.rgbWhite;
                dbSource.Font.Color = Excel.XlRgbColor.rgbWhite;

                detail_ws.UsedRange.Locked = true;
                HelperUI.ProtectSheet(detail_ws, false, false);

                btn_Upload.Enabled = true;

            }
            catch (Exception ex)
            {
                ShowErr(ex);

                btn_Upload.Enabled = false;
                xlTextBox = summary_ws.Shapes.Item("picLogo");
                if (xlTextBox != null) xlTextBox.Visible = Office.MsoTriState.msoCTrue;

                productName.Font.ThemeColor = Excel.XlThemeColor.xlThemeColorDark2;
                productName.Font.TintAndShade = -0.499984741;

                dbSource.Font.ThemeColor = Excel.XlThemeColor.xlThemeColorDark1;
                dbSource.Font.TintAndShade = -0.349986267;

            }
            finally
            {
                HelperUI.RenderON();

                btn_Import.Enabled = true;
                btn_Import.Text = orig_text;

                if (xltable != null) Marshal.ReleaseComObject(xltable); xltable = null;
                if (co1_ws != null) Marshal.ReleaseComObject(co1_ws); co1_ws = null;
                if (co20_ws != null) Marshal.ReleaseComObject(co20_ws); co20_ws = null;
                if (detail_ws != null) Marshal.ReleaseComObject(detail_ws); detail_ws = null;
            }
        }

        private void AlignColumns(Excel.ListObject xltable)
        {
            xltable.ListColumns["Co"].DataBodyRange.EntireColumn.ColumnWidth = 4.25;
            xltable.ListColumns["Employee"].DataBodyRange.EntireColumn.ColumnWidth = 9.38;
            xltable.ListColumns["WeekHrs"].DataBodyRange.EntireColumn.ColumnWidth = 8.63;

            // BODY CENTER
            string[]  alignColumns = new string[] { "Co", "WeekHrs" };

            foreach (var column in alignColumns)
            {
                xltable.ListColumns[column].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
            }

            xltable.ListColumns["Employee"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
        }

        private void btn_Upload_Click(object sender, EventArgs e)
        {
            string orig_text = btn_Upload.Text;
            btn_Upload.Text = "Uploading...";
            btn_Upload.Enabled = false;

            Excel.Workbook wkbSource = null;
            Excel.Workbook wkbTarget = null;
            Excel.Worksheet ws = null;
            Excel.Worksheet detail_ws = null;

            string uploadFile = "";
            string path = "";

            try
            {
                detail_ws = Globals.sht_Detail.InnerObject;

                if (detail_ws.ListObjects.Count == 0)
                {
                    throw new Exception("No timesheet detail data present. Click 'Import' first, then 'Upload'.\n\nIf problem persists, contact support.");
                }

                string fileName = "EBSTimesheet_VP_Import";
                fileName += DateTime.Now.ToString().Replace("/", "").Replace(":", "").Replace(" ", "");  // SAMPLE: 8/3/2017 2:37:12 PM -> 83201723712PM

                if (HelperData._conn_string.Contains("VIEWPOINTAG"))
                {
                    path = @"\\MCKVIEWPOINT\viewpoint Repository\bulk inserts\ETL\PR\EBS\AutoImport\";
                }
                else if (HelperData._conn_string.Contains("VPSTAGINGAG"))
                {
                    //path = "C:\\test";
                    path = @"\\sestgviewpoint\viewpoint Repository\bulk inserts\ETL\PR\EBS\AutoImport\";
                }

                // append backslash if missing
                if (!path.EndsWith("\\"))
                {
                    path += "\\";
                }

                uploadFile = path + fileName + ".csv";

                if (!NetPath.Exists(path)) throw new Exception("Network path does not exist:\n" + System.IO.Path.GetDirectoryName(path));

                HelperUI.RenderOFF();

                wkbSource = Globals.ThisWorkbook.Worksheets.Parent;
                wkbTarget = wkbSource.Application.Workbooks.Add(Excel.XlWBATemplate.xlWBATWorksheet);

                //detail_ws.Unprotect(ActionPane.pwd);

                detail_ws.Copy(After: wkbTarget.Sheets["Sheet1"]);

                ws = wkbTarget.Sheets["DetailData"];

                ws.ListObjects[1].Unlist(); // convert table to range to delete header

                ws.get_Range("A1", Type.Missing).EntireRow.Delete(Excel.XlDeleteShiftDirection.xlShiftUp);

                // To avoid having and 'empty' row at bottom of CSV file
                #region RESET THE USED RANGE

                object missing = System.Type.Missing;

                int myLastRow = ws.Cells.Find("*", ws.Cells[1],
                                            Excel.XlFindLookIn.xlFormulas, Excel.XlLookAt.xlWhole,
                                            Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlPrevious, missing,
                                            missing, missing).Row;

                int myLastCol = ws.Cells.Find("*", ws.Cells[1],
                                Excel.XlFindLookIn.xlFormulas, Excel.XlLookAt.xlWhole,
                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlPrevious, missing,
                                missing, missing).Column;

                if (myLastCol * myLastRow == 0)
                {
                    ws.Columns.Delete();
                }
                else
                {
                    ws.Range[ws.Cells[myLastRow + 1, 1], ws.Cells[ws.Rows.Count, 1]].EntireRow.Delete();
                    ws.Range[ws.Cells[1, myLastCol + 1], ws.Cells[1, ws.Columns.Count]].EntireColumn.Delete();
                }

                #endregion

                wkbTarget.Sheets["Sheet1"].Delete();

                wkbTarget.SaveAs(uploadFile, Microsoft.Office.Interop.Excel.XlFileFormat.xlCSVWindows, Type.Missing, Type.Missing, false, false, Microsoft.Office.Interop.Excel.XlSaveAsAccessMode.xlExclusive, Microsoft.Office.Interop.Excel.XlSaveConflictResolution.xlLocalSessionChanges, false, Type.Missing, Type.Missing, Type.Missing);

                wkbTarget.Close(false, Type.Missing, Type.Missing);

                MessageBox.Show("File uploaded successfully!");
            }
            catch (Exception ex)
            {
                wkbTarget?.Close(false);
                ShowErr(ex);
            }
            finally
            {
                HelperUI.RenderON();

                btn_Upload.Enabled = true;
                btn_Upload.Text = orig_text;

                //detail_ws.UsedRange.Locked = true;
                //HelperUI.ProtectSheet(detail_ws, false, false);

                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                if (wkbSource != null) Marshal.ReleaseComObject(wkbSource); wkbSource = null;
                if (wkbTarget != null) Marshal.ReleaseComObject(wkbTarget); wkbTarget = null;
            }
        }

        private void ShowErr(Exception ex = null, string customErr = null, string title = "Failure!")
        {
            string err = customErr ?? ex.Message;

            MessageBox.Show(this, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

    }
}
