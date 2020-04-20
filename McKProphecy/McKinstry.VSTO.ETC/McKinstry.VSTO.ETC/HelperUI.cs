using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using Office = Microsoft.Office.Core;
//using Excelo = Microsoft.Office.Tools.Excel;
using Excel = Microsoft.Office.Interop.Excel;
using Microsoft.Office.Tools.Excel;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Windows.Forms;
using System.Drawing.Printing;

namespace McKinstry.ETC.Template
{
    public static class HelperUI
    {

        #region NUMBER FORMATS

        public static string PercentFormat => "###,##.##%_);_(* (###,##.##%);_(* \" - \"??_);_(@_)";
        //public static string CurrencyFormat
        //{
        //    get
        //    {
        //        return "_($* #,##0.00_);_($* (#,##0.00);_($* \" - \"??_);_(@_)";
        //    }
        //}

        public static string CurrencyStyle => "Currency";  // is Accounting

        public static string CurrencyFormatCondensed => "$#,##0.00;$(#,##0.00);$\" - \"??;(_(@_)";

        public static string GeneralFormat => "General;(#,##0.0);;@";
        public static string NumberFormat2Decimals => "#,##0.##;(#,##0.##);;@";

        public static string NumberFormat => "#,##0.0;(#,##0.0);0;@";


        public static string StringFormat => "@";

        public static string DateFormatMMDDYY => "MM/dd/yy";
        public static string DateFormatMMDDYYYY => "MM/dd/yyyy";
        public static string DateFormatMDYYhmmAMPM => "m/d/yy h:mm AM/PM";
        public static string DateFormatMDYYYYhmmAMPM => "m/d/yyyy h:mm AM/PM";

        public static string DateTimeShortAMPM => string.Format("{0:M/dd/yy h:mm:ss tt}", DateTime.Now);

        #endregion

        #region SHEETS HANDLING

        public static void CreateTitleHeader(Excel.Worksheet ws, string title)
        {
            ws.get_Range("A1:S1").Merge();
            ws.get_Range("A1").Formula = title;
            ws.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
            ws.get_Range("A1").Font.Bold = true;
        }

        public static void PrintPageSetup(Excel.Worksheet ws)
        {
            try
            {
                ws.PageSetup.Orientation = Excel.XlPageOrientation.xlLandscape;
                ws.DisplayPageBreaks = false;
                ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperTabloid;
                ws.PageSetup.FitToPagesWide = 1;
                ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
                ws.PageSetup.TopMargin = .75;
                ws.PageSetup.BottomMargin = .75;
                ws.PageSetup.LeftMargin = .25;
                ws.PageSetup.RightMargin = .25;
                ws.PageSetup.HeaderMargin = .3;
                ws.PageSetup.FooterMargin = .3;
                ws.PageSetup.Order = Excel.XlOrder.xlDownThenOver;
                ws.PageSetup.CenterFooter = "&P / &N";
            }
            catch { }
        }

        public static void PrintPage_RevCurveSetup(Excel.Worksheet ws)
        {
            try
            {
                ws.PageSetup.Orientation = Excel.XlPageOrientation.xlLandscape;
                ws.DisplayPageBreaks = false;
                ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperTabloid;
                ws.PageSetup.FitToPagesWide = 1;
                ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal.Substring(0,ws.UsedRange.AddressLocal.LastIndexOf('$')) + "$35";
                ws.PageSetup.TopMargin = .75;
                ws.PageSetup.BottomMargin = .75;
                ws.PageSetup.LeftMargin = .25;
                ws.PageSetup.RightMargin = .25;
                ws.PageSetup.HeaderMargin = .3;
                ws.PageSetup.FooterMargin = .3;
                ws.PageSetup.Order = Excel.XlOrder.xlDownThenOver;
                ws.PageSetup.CenterFooter = "&P / &N";
            }
            catch { }
        }

        public static bool SheetExists(string sheetName, bool extactMatch = true)
        {
            if (sheetName == "" || sheetName == null) return false;
            
            switch (extactMatch)
            {
                case true:

                    foreach(Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name == sheetName) return true;
                    }
                    break;
                case false:

                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name.Contains(sheetName)) return true;
                    }
                    break;
            }
            return false;
        }

        public static Excel.Worksheet GetSheet(string sheetName, bool extactMatch = true)
        {
            if (sheetName == "" || sheetName == null) return null;

            switch (extactMatch)
            {
                case true:
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name == sheetName) return ws;
                    }
                    break;
                case false:
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
                    {
                        if (ws.Name.Contains(sheetName)) return ws;
                    }
                    break;
            }
            return null;
        }

        /// <summary>
        /// adds the sheet or returns it if already exists
        /// </summary>
        /// <param name="sheetName"></param>
        /// <param name="afterSheet"></param>
        /// <returns></returns>
        public static Excel.Worksheet AddSheet(string sheetName, Excel.Worksheet afterSheet, bool checkIfExists = true)
        {
            Excel.Worksheet newSheet = checkIfExists ? HelperUI.GetSheet(sheetName) : null;

            if (newSheet == null)
            {
                newSheet = Globals.ThisWorkbook.Sheets.Add(After: afterSheet);
                newSheet.Name = sheetName;
            }
            return newSheet;
        }

        public static bool DeleteSheet(this Excel.Workbook wbk, string sheetName)
        {
            bool retVal = false;


            for (int i = 1; i <= wbk.Worksheets.Count; i++)
            {
                if (((Excel.Worksheet)wbk.Worksheets[i]).Name == sheetName)
                {
                    wbk.Application.DisplayAlerts = false;
                    wbk.Worksheets[i].Delete();
                    wbk.Application.DisplayAlerts = true;
                    retVal = true;
                }
            }

            return retVal;
        }

        public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(ETCOverviewActionPane.pwd, true, Type.Missing, Type.Missing, true, true, true,
                  true, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }

        // can't do this due to MS BUG; behaviour differs versions
        //public static void CleanSheet(Excel.Worksheet ws)
        //{
        //    ws.Unprotect();
        //    foreach (Excel.ListObject lo in ws.ListObjects) lo.Delete();
        //    ws.UsedRange.Clear();
        //    ws.UsedRange.EntireRow.Hidden = false;
        //    ws.UsedRange.EntireRow.ClearOutline();
        //    ws.UsedRange.EntireRow.Delete();
        //    ws.UsedRange.EntireColumn.Hidden = false;
        //    ws.UsedRange.EntireColumn.ClearOutline();
        //    ws.UsedRange.EntireColumn.Delete();
        //    foreach (Excel.Name namedRange in ws.Names) namedRange.Delete();
        //}

        #endregion

        #region STYLE GUIDE

        //public const decimal TintShadeRed = 0.0m;

        private static void ShowGridLines(Excel.Borders _borders)
        {
            _borders[Excel.XlBordersIndex.xlEdgeLeft].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeRight].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeBottom].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders.Color = Color.Black;
        }

        public static Excel.ListObject FormatAsTable(Excel.Range SourceRange, string TableName)
        {
            Excel.ListObject newList;

            ShowGridLines(SourceRange.Borders);

            newList = SourceRange.Worksheet.ListObjects.Add(Microsoft.Office.Interop.Excel.XlListObjectSourceType.xlSrcRange,
                      SourceRange, System.Type.Missing, Microsoft.Office.Interop.Excel.XlYesNoGuess.xlYes, System.Type.Missing);

            newList.Name = TableName;
            newList.Range.Font.Size = 9;

            newList.HeaderRowRange.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
            newList.HeaderRowRange.Font.Color = HelperUI.WhiteHeaderFontColor;
            newList.HeaderRowRange.Font.Size = 10;
            newList.HeaderRowRange.Font.Bold = true;
            newList.HeaderRowRange.WrapText = true;
            newList.HeaderRowRange.Rows.RowHeight = 15;
            newList.HeaderRowRange.EntireColumn.AutoFit();

            newList.DataBodyRange.Interior.Color = HelperUI.WhiteFontColor;
            newList.DataBodyRange.Font.Color = HelperUI.McKColor(McKColors.Black);

            newList.ShowTotals = true;
            newList.TotalsRowRange.Interior.Color = HelperUI.NavyBlueTotalRowColor;
            newList.TotalsRowRange.Font.Color = HelperUI.WhiteFontColor;
            newList.TotalsRowRange.Font.Size = 12;
            newList.TotalsRowRange.Font.Italic = false;
            newList.TotalsRowRange.Font.Bold = true;
            newList.TotalsRowRange.RowHeight = 15.75;

            // SourceRange.Worksheet.ListObjects[TableName].TableStyle = TableStyleName;

            return newList;
        }

        public static int ColorToInt(Color color) => ColorTranslator.ToWin32(color);

        //public const string tableStyle = "McKinstry Table Style";
        //public static bool TableStyleExists(Excel.Workbook workbook, string styleName)
        //{
        //    foreach (Excel.TableStyle ts in workbook.TableStyles)
        //    {
        //        if (ts.Name == styleName)
        //        {
        //            return true;
        //        }
        //    }
        //    return false;
        //}

        //public static void CreateCustomTableStyle(Excel.Workbook workbook)
        //{
        //    if (!TableStyleExists(workbook, tableStyle))
        //    {
        //        Excel.TableStyle mckTableStyle = workbook.TableStyles.Add(tableStyle);

        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlHeaderRow].Interior.Color = HelperUI.SecondHeaderRowColor;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlHeaderRow].Font.Color = HelperUI.SecondHeaderFontColor;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlHeaderRow].Font.Size = 10;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlHeaderRow].Font.Bold = true;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlGrandTotalRow].Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue70);
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlGrandTotalRow].Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
        //        //// mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlGrandTotalRow].Font.Size = 11;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlGrandTotalRow].Font.Italic = true;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlGrandTotalRow].Font.Bold = true;

        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue70);
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
        //        ////mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Size = 11;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Italic = true;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Bold = true;

        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlRowStripe1].Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlRowStripe1].Font.Size = 9;
        //        //mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlRowStripe1].Font.Name = HelperUI.FontFamily;

        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Interior.Color = HelperUI.TotalRowColor;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Color = HelperUI.TotalFontColor;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Size = 12;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Italic = false;
        //        mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlTotalRow].Font.Bold = true;

        //        Excel.TableStyleElement _tse = mckTableStyle.TableStyleElements[Excel.XlTableStyleElementType.xlWholeTable];

        //        _tse.Borders.LineStyle = Excel.XlLineStyle.xlContinuous; ;
        //        _tse.Borders.Color = HelperUI.CellBorderColor;

        //        mckTableStyle.ShowAsAvailableTableStyle = true;
        //        mckTableStyle.ShowAsAvailablePivotTableStyle = true;
        //        //mckTableStyle.ShowAsAvailableSlicerStyle = true;
        //    }
        //}


        public static string FontCalibri => "Calibri";

        #region FONT SIZES
        public static uint TwentyFontSizePageHeader => 20;
        public static int FourteenBreakDownHeaderFontSize => 14;
        public static int TwelveFontSizeHeader => 12;
        public static int TenSizeFontSecondHeaderRow => 10;
        public static int TwelveFontSizeTotal => 12;
        #endregion 
        
        #region COLORS

        public enum McKColors
        {
            NavyBlue
            , Gray
            , LightGray
            , Yellow
            , Red
            , BrightRed
            , Green
            , SoftBlack
            , SoftBeige
            , AquaBlue

            , Blue
            , Blue70
            , LightBlue
            , Black
            , Orange
            , Olive
            , Peacock
            , Burgandy
            , Lime
            , Jade
            , White

        }
        public static Color McKColor(McKColors color)
        {
            switch (color)
            {
                case McKColors.NavyBlue: return Color.FromArgb(10, 63, 84);

                case McKColors.Gray: return Color.FromArgb(118, 131, 147);

                case McKColors.LightGray: return Color.FromArgb(192, 195, 204);

                case McKColors.Yellow: return Color.FromArgb(250, 237, 191);

                case McKColors.Red: return Color.FromArgb(255, 189, 189);

                case McKColors.BrightRed: return Color.FromArgb(255, 0, 0);

                case McKColors.Green: return Color.FromArgb(198, 224, 180);

                case McKColors.SoftBlack: return Color.FromArgb(32, 31, 32);

                case McKColors.SoftBeige: return Color.FromArgb(250, 240, 235);

                case McKColors.White: return Color.FromArgb(255, 255, 255);

                case McKColors.AquaBlue: return Color.FromArgb(205, 251, 255);

                case McKColors.Black: return Color.FromArgb(0, 0, 0);

                //case McKColors.Blue70:    return  Color.FromArgb(79, 100, 118);

                //case McKColors.LightBlue: return  Color.FromArgb(172, 194, 223);

                case McKColors.Orange: return Color.FromArgb(207, 103, 51);

                //case McKColors.Olive:     return  Color.FromArgb(154, 150, 60);

                //case McKColors.Peacock:   return  Color.FromArgb(0, 132, 142);

                //case McKColors.Burgandy:  return  Color.FromArgb(107, 56, 59);

                //case McKColors.Lime:      return  Color.FromArgb(177, 198, 86);

                //case McKColors.Jade:      return  Color.FromArgb(115, 183, 149);

                default: return Color.White;
            }
        }
        public static Color WhiteDownHeaderFontColor => McKColor(McKColors.White);
        public static Color GrayBreakDownHeaderRowColor => McKColor(McKColors.Gray);
        public static Color LightGrayHeaderRowColor => McKColor(McKColors.LightGray);
        public static Color SoftBlackHeaderFontColor => McKColor(McKColors.SoftBlack);
        public static Color NavyBlueHeaderRowColor => McKColor(McKColors.NavyBlue);
        public static Color WhiteHeaderFontColor => McKColor(McKColors.White);
        public static Color NavyBlueTotalRowColor => McKColor(McKColors.NavyBlue);
        public static Color WhiteFontColor => McKColor(McKColors.White);
        public static Color DataEntryColor => McKColor(McKColors.Yellow);
        public static Color RedNegColor => McKColor(McKColors.Red);
        public static Color GreenPosColor => McKColor(McKColors.Green);
        public static Color CellBorderColor => McKColor(McKColors.LightGray);
        #endregion

        #endregion


        //public static void ControlPageSetup(Excel.Worksheet ws)
        //{
        //    ws.PageSetup.Orientation = Excel.XlPageOrientation.xlPortrait;
        //    ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperLetter;
        //    ws.PageSetup.FitToPagesWide = 1;
        //    ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal[Type.Missing, Type.Missing, Excel.XlReferenceStyle.xlA1];
        //    ws.PageSetup.TopMargin = .75;
        //    ws.PageSetup.BottomMargin = .75;
        //    ws.PageSetup.LeftMargin = .7;
        //    ws.PageSetup.RightMargin = .7;
        //    ws.PageSetup.HeaderMargin = .3;
        //    ws.PageSetup.FooterMargin = .3;
        //}

        public static int GetWeeksInMonth(DateTime month, DayOfWeek dayToCount)
        {
            // first generate all dates in the month of 'date'
            IEnumerable<DateTime> dates = Enumerable.Range(1, DateTime.DaysInMonth(month.Year, month.Month)).Select(n => new DateTime(month.Year, month.Month, n));
            // then filter only the start of weeks
            IEnumerable<DateTime> weekends = from d in dates
                           where d.DayOfWeek == dayToCount
                           select d;
            return weekends.Count();
        }

        public static bool IsTextPosNumeric(string text)
        {
            int @int;
            if ((int.TryParse(text.Trim(), out @int)) && @int > 0) return true;
            
            return false;
        }

        public static void Alphanumeric_Check(Excel.ListObject xltable, string columnName, int? used = null)
        {
            decimal value = 0;

            if (used == null)
            {
                foreach (Excel.Range cell in xltable.ListColumns[columnName].DataBodyRange.Cells)
                {
                    if (cell.Value != null)
                    {
                        var val = Convert.ToString(cell.Value);
                        if (val != "")
                        {
                            if (!decimal.TryParse(val, out value))
                            {
                                cell.Parent.Activate();
                                cell.Activate();
                                throw new Exception("You've entered a non-numeric value in a highlighted red cell, please update your entry");
                            }
                        }
                    }
                }
            }
            else
            {
                foreach (Excel.Range cell in xltable.ListColumns[columnName].DataBodyRange.Cells)
                {
                    int r = cell.Row;
                    if (xltable.Parent.Cells[cell.Row, used].Formula != "N")
                    {
                        if (cell.Value != null)
                        {
                            var val = Convert.ToString(cell.Value);
                            if (val != "")
                            {
                                if (!decimal.TryParse(val, out value))
                                {
                                    cell.Parent.Activate();
                                    cell.Activate();
                                    throw new Exception("You have entered a non-numeric value in a highlihgted red cell, please update your entry");
                                }
                            }
                        }
                    }
                }
            }
        }

        public static Excel.Range GetCell(Excel.Worksheet ws, string cellText, object lookAfterCell = null)
        {
            lookAfterCell = lookAfterCell ?? Type.Missing;

            if (ws != null)
            {
                return ws.Cells.Find(cellText, lookAfterCell, Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole, Excel.XlSearchOrder.xlByColumns,
                                                    Excel.XlSearchDirection.xlNext, false, Type.Missing, Type.Missing);
            }

            return null;
        }

        public static void ApplyZeroAmtFilter(Excel.Worksheet sheet, string cellHeader, string cellHeader2 = null, int tableIndex = 1)
        {
            Excel.Range cellhead = GetCell(sheet, cellHeader);
            Excel.Range cellhead2 = null;
            Excel.Range _offset = null;
            Excel.ListObject table = sheet.ListObjects[tableIndex];

            try
            {
                int offset = 0;

                if (cellhead != null)
                {
                    // where is the table positioned in Excel ? (to allow proper ref to the fields)
                    _offset = cellhead.Offset[Type.Missing, cellhead.Column - table.ListColumns[cellHeader].Index];
                    offset = _offset.Column - cellhead.Column;

                    cellhead.AutoFilter(cellhead.Column - offset, ">0", Excel.XlAutoFilterOperator.xlFilterValues, Type.Missing, true);
                }

                if (cellHeader2 != null)
                {
                    cellhead2 = GetCell(sheet, cellHeader2, cellhead);
                    cellhead2.AutoFilter(cellhead2.Column - offset, ">0", Excel.XlAutoFilterOperator.xlFilterValues, Type.Missing, true);
                }
            }
            catch (Exception) { throw; }
            finally
            {
                if (cellhead != null) Marshal.ReleaseComObject(cellhead);
                if (cellhead2 != null) Marshal.ReleaseComObject(cellhead2);
                if (_offset != null) Marshal.ReleaseComObject(_offset);
                if (table != null) Marshal.ReleaseComObject(table);
            }
        }

        public static void ApplyUsedFilter(Excel.Worksheet sheet, string cellHeader, int tableIndex = 1)
        {
            Excel.Range cellhead = GetCell(sheet, cellHeader);
            Excel.Range _offset = null;
            Excel.ListObject table = sheet.ListObjects[tableIndex];

            try
            {
                int offset = 0;

                if (cellhead != null)
                {
                    // where is the table positioned in Excel ? (to allow proper ref to the fields)
                    _offset = cellhead.Offset[Type.Missing, cellhead.Column - table.ListColumns[cellHeader].Index];
                    offset = _offset.Column - cellhead.Column;

                    cellhead.AutoFilter(cellhead.Column - offset, "=Y", Excel.XlAutoFilterOperator.xlFilterValues, Type.Missing, true);
                }

            }
            catch (Exception) { throw; }
            finally
            {
                if (cellhead != null) Marshal.ReleaseComObject(cellhead);
                if (_offset != null) Marshal.ReleaseComObject(_offset);
                if (table != null) Marshal.ReleaseComObject(table);
            }
        }

        public static void ApplyVarianceFormat(Excel.ListColumn FormatMe)
        {

            Excel.FormatCondition NegCond = null;
            Excel.FormatCondition PosCond = null;

            NegCond = (Excel.FormatCondition)FormatMe.DataBodyRange.FormatConditions.Add(Excel.XlFormatConditionType.xlCellValue,
                                                                                            Excel.XlFormatConditionOperator.xlLess, "=0");
            NegCond.Interior.Color = HelperUI.GreenPosColor; // Light green 
            NegCond.Font.Bold = true;

            PosCond = (Excel.FormatCondition)FormatMe.DataBodyRange.FormatConditions.Add(Excel.XlFormatConditionType.xlCellValue,
                                                                             Excel.XlFormatConditionOperator.xlGreater, "=0");
            PosCond.Interior.Color = HelperUI.RedNegColor; // Light red 
            PosCond.Font.Bold = true;
        }

        //public static void SortDescending(Excel.Worksheet ws, string columnName, int tableIndex = 1)
        //{
        //    Excel.ListObject table = ws.ListObjects[tableIndex];
        //    Excel.ListColumn col = table.ListColumns[columnName];

        //    table.Range.Sort(col, Excel.XlSortOrder.xlDescending,
        //                      Type.Missing,
        //                      Type.Missing,
        //                      (dynamic)Type.Missing,
        //                      Type.Missing, 
        //                      (dynamic)Type.Missing,  // third sort key nothing, but it wants one
        //                      Excel.XlYesNoGuess.xlYes,
        //                      Type.Missing, false,
        //                      Excel.XlSortOrientation.xlSortColumns, 
        //                      Excel.XlSortMethod.xlPinYin,
        //                      Excel.XlSortDataOption.xlSortNormal,
        //                      Excel.XlSortDataOption.xlSortNormal,
        //                      Excel.XlSortDataOption.xlSortNormal);

        //    //cellhead.Sort(cellhead, Excel.XlSortOrder.xlDescending, Type.Missing, Type.Missing, (dynamic)Type.Missing, Type.Missing,
        //    //(dynamic)Type.Missing, (dynamic)Type.Missing, Type.Missing, Type.Missing, Excel.XlSortOrientation.xlSortColumns,
        //    //(dynamic)Type.Missing, (dynamic)Type.Missing, (dynamic)Type.Missing, (dynamic)Type.Missing);

        //    if (col != null) Marshal.ReleaseComObject(col);
        //    if (table != null) Marshal.ReleaseComObject(table);
        //}

        public static void SortAscending(Excel.Worksheet sheet, string firstCol, string secondCol = null, int tableIndex = 1)
        {
            Excel.ListObject table = sheet.ListObjects[tableIndex];
            Excel.ListColumn first = table.ListColumns[firstCol];

            var second = secondCol != null ? table.ListColumns[secondCol] : Type.Missing;

            table.Range.Sort(first, Excel.XlSortOrder.xlAscending,
                              second, Type.Missing, Excel.XlSortOrder.xlDescending,
                              Type.Missing, (dynamic)Type.Missing,  // third sort key nothing, but it wants one
                              Excel.XlYesNoGuess.xlGuess, Type.Missing, Type.Missing,
                              Excel.XlSortOrientation.xlSortColumns, Excel.XlSortMethod.xlPinYin,
                              Excel.XlSortDataOption.xlSortNormal,
                              Excel.XlSortDataOption.xlSortNormal,
                              Excel.XlSortDataOption.xlSortNormal);

            if (first != null) Marshal.ReleaseComObject(first);
            if (second != null && second.GetType() == typeof(Excel.ListColumn)) Marshal.ReleaseComObject(second);
            if (table != null) Marshal.ReleaseComObject(table);
        }

        public static void FreezePane(Excel.Worksheet sheet, string cellTitleToSpliFrom)
        {
            Excel.Range _rng = sheet.ListObjects[1].ListColumns[cellTitleToSpliFrom].Range; //HelperUI.GetCell(sheet, cellTitleToSpliFrom);

            if (_rng != null)
            {
                sheet.Parent.Activate();
                _rng = sheet.Cells[_rng.Row + 1, _rng.Column];
                _rng.Activate();
                sheet.Application.ActiveWindow.FreezePanes = true;
            }
        }

        public static void FormatHoursCost(Excel.Worksheet sheet, int tableIndex = 1)
        {
            Excel.ListObject table = null;
            try
            {
                table = sheet.ListObjects[tableIndex];

                foreach (Excel.ListColumn col in table.ListColumns)
                {
                    if (col.Name.Contains("Hour"))
                    {
                        col.Range.Cells.NumberFormat = HelperUI.GeneralFormat;
                        col.Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    }
                    else if (col.Name.Contains("Cost") && !(col.Name == "Cost Type" || col.Name == "CostType"))
                    {
                        col.DataBodyRange.Style = HelperUI.CurrencyStyle;
                    }
                }
            }
            finally { if (table != null) Marshal.ReleaseComObject(table);}
        }

        public static void GroupColumns(Excel.Worksheet ws, Excel.Range cellStart, Excel.Range cellEnd)
        {
            Excel.Range grpCols = null;

            try
            {
                grpCols = ws.Range[cellStart, cellEnd];
                grpCols.EntireColumn.Group();
                ws.EnableOutlining = true;
                grpCols.EntireColumn.Hidden = true;
            }
            catch (Exception) { throw; }
            finally
            {
                if (grpCols != null) Marshal.ReleaseComObject(grpCols);
            }
        }

        public static void GroupColumns(Excel.Worksheet ws, string fromCol, string toCol = null, bool hidden = true)
        {
            Excel.Range from = null;
            Excel.Range to = null;

            try
            {
                if (fromCol != "" && toCol != null)
                {
                    from = ws.ListObjects[1].ListColumns[fromCol].Range;
                    to = ws.ListObjects[1].ListColumns[toCol].Range;
                    ws.Range[from, to].EntireColumn.Group();
                    ws.Range[from, to].EntireColumn.Hidden = hidden;
                }
                else if (fromCol != "" || fromCol != null)
                {
                    from = ws.ListObjects[1].ListColumns[fromCol].Range;
                    ws.Range[from, from].EntireColumn.Group();
                    ws.Range[from, from].EntireColumn.Hidden = hidden;
                }
                ws.EnableOutlining = true;
            }
            catch (Exception ex) { throw new Exception("GroupColumns: failed setting " + ws.Name + " sheet.\nColumns: " + fromCol + " to " + toCol , ex); }
            finally
            {
                if (from != null) Marshal.ReleaseComObject(from);
                if (to != null) Marshal.ReleaseComObject(to);
            }
        }

        public static void MergeLabel(Excel.Worksheet ws, string fromCell, string ToCell, string label, uint tableId = 1, uint offsetRowUpFromTableHeader = 2, 
                                        double rowHeight = 30, uint fontSize = 12, Excel.XlHAlign horizAlign = Excel.XlHAlign.xlHAlignCenter)
        {
            Excel.Range from = ws.ListObjects[tableId].ListColumns[fromCell].Range;
            Excel.Range to = ws.ListObjects[tableId].ListColumns[ToCell].Range;

            try
            {
                from = ws.Cells[from.Row - offsetRowUpFromTableHeader, from.Column];
                to = ws.Cells[to.Row - offsetRowUpFromTableHeader, to.Column];
                from = ws.Range[from, to];
                from.Merge();
                from.WrapText = true;
                from.Formula = label.ToUpper();
                from.Cells.HorizontalAlignment = horizAlign;
                from.Cells.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                from.RowHeight = rowHeight;
                from.Interior.PatternColorIndex = Excel.XlColorIndex.xlColorIndexAutomatic;
                from.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                from.Font.Color = HelperUI.SoftBlackHeaderFontColor;
                from.Font.Bold = true;
                from.Font.Size = fontSize;
                from.Borders[Excel.XlBordersIndex.xlEdgeLeft].ColorIndex = 2;
                from.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 2;
                from.Borders[Excel.XlBordersIndex.xlEdgeTop].ColorIndex = 2;
                from.Borders[Excel.XlBordersIndex.xlEdgeLeft].Weight = Excel.XlBorderWeight.xlThick;
                from.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThick;
                from.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThick;
                from.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;

            }
            catch (Exception) { throw; }
            finally
            {
                if (from != null) Marshal.ReleaseComObject(from);
                if (to != null) Marshal.ReleaseComObject(to);
            }
        }

        //public static void ColorInteriorCell(Excel.Worksheet ws, string colName, uint tableId = 1, Excel.XlThemeColor interiorColor = Excel.XlThemeColor.xlThemeColorAccent6, uint rowHeight = 32)
        //{

        //    Excel.Range rng = ws.ListObjects[tableId].ListColumns[colName].Range;
        //    rng = ws.Cells[rng.Row, rng.Column];
        //    rng.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
        //    rng.Cells.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
        //    rng.RowHeight = rowHeight;
        //    rng.Interior.PatternColorIndex = Excel.XlColorIndex.xlColorIndexAutomatic;
        //    rng.Font.Color = ColorTranslator.ToOle(System.Drawing.Color.Black);
        //    rng.Interior.ThemeColor = interiorColor;
        //    rng.Interior.TintAndShade = 0.799981688894314;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeLeft].ColorIndex = 2;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 2;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeTop].ColorIndex = 2;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeLeft].Weight = Excel.XlBorderWeight.xlThick;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThick;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThick;
        //    rng.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
        //}

        public static void AddFieldDesc(Excel.Worksheet ws, string field, string description, uint rowOffset = 1, uint tableId = 1)
        {
            Excel.Range column = null;

            try
            {
                column = ws.ListObjects[tableId].ListColumns[field].Range;
                column = ws.Cells[column.Row - rowOffset, column.Column];
                column.Value = description;
                column.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                column.Cells.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                column.RowHeight = 31.5;
                column.WrapText = true;
                column.Rows.AutoFit();
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
            finally
            {
                if (column != null) Marshal.ReleaseComObject(column);
            }
        }

        public static string JobTrimDash(string job) => job?.Split('-')[1];

        public static void SetAlphanumericNotAllowedRule(Excel.Range range)
        {
            string[] _rangeA1 = range.Address.Split('$');
            string rangeA1 = _rangeA1.Length > 3 ? _rangeA1[1] + _rangeA1[2] + _rangeA1[3] + _rangeA1[4] : _rangeA1[1] + _rangeA1[2];

            range.Validation.Add(Excel.XlDVType.xlValidateCustom,
                                        Excel.XlDVAlertStyle.xlValidAlertStop,
                                        Type.Missing, "=IsNumber(Trim(" + rangeA1 + ")*1)");
            range.Validation.ErrorTitle = "Woops!";
            range.Validation.ErrorMessage = "Non-numeric values are not allowed, please update your entry";
        }

        // Sums up values from a Range.Value2 object array
        public static double SumRow(object[,] value2, int row)
        {
            double sum = 0;
            dynamic value;

            for (int i = row; i <= row; i++)
            {
                for (int n = 1; n <= value2.GetUpperBound(1); n++)
                {
                    value = value2[row, n];
                    if (value != null)
                    {
                        sum += value.GetType() == typeof(double) ? value : 0;
                    }
                }
            }
            return sum;
        }

        public static void ColorAllBorders(Excel.Range rng, Color color)
        {
            rng.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            rng.Borders.Color = color;
            rng.Borders.get_Item(Excel.XlBordersIndex.xlInsideVertical).LineStyle = Excel.XlLineStyle.xlContinuous;
            rng.Borders.get_Item(Excel.XlBordersIndex.xlInsideVertical).Color = WhiteFontColor;
        }

        //#region  VSTO
        //public static Excelo.ListObject BindDataTableToExcel(Excelo.Worksheet ws, DataTable bindDataTable, string A1StyleRange, string tableName)
        //{
        //    Excelo.ListObject listVSTObject = ws.Controls.AddListObject(ws.get_Range("A4"), tableName);

        //    HelperUI.ShowGridLines(ws.get_Range("A4").Borders);

        //    listVSTObject.DataSource = bindDataTable;
        //    listVSTObject.AutoSetDataBoundColumnHeaders = true;
        //    listVSTObject.DataBoundFormat = Microsoft.Office.Interop.Excel.XlRangeAutoFormat.xlRangeAutoFormatSimple;
        //    listVSTObject.ShowTableStyleRowStripes = false;
        //    listVSTObject.ShowTotals = true;
        //    listVSTObject.Name = tableName;

        //    return listVSTObject;
        //}

        //public static void FormatAsVSTOtable(Excelo.ListObject listVSTObject)
        //{
        //    listVSTObject.Range.Font.Size = 9;
        //    listVSTObject.HeaderRowRange.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
        //    listVSTObject.HeaderRowRange.Font.Color = HelperUI.WhiteHeaderFontColor;
        //    listVSTObject.HeaderRowRange.Font.Size = 10;
        //    listVSTObject.HeaderRowRange.Font.Bold = true;
        //    listVSTObject.HeaderRowRange.WrapText = true;
        //    listVSTObject.HeaderRowRange.Rows.RowHeight = 15;
        //    listVSTObject.HeaderRowRange.EntireColumn.AutoFit();

        //    if (listVSTObject.DataBodyRange != null)
        //    {
        //        listVSTObject.DataBodyRange.Interior.Color = HelperUI.WhiteFontColor;
        //        listVSTObject.DataBodyRange.Font.Color = HelperUI.McKColor(McKColors.Black);
        //    }
        //    listVSTObject.ShowTotals = true;
        //    listVSTObject.TotalsRowRange.Interior.Color = HelperUI.NavyBlueTotalRowColor;
        //    listVSTObject.TotalsRowRange.Font.Color = HelperUI.WhiteFontColor;
        //    listVSTObject.TotalsRowRange.Font.Size = 12;
        //    listVSTObject.TotalsRowRange.Font.Italic = false;
        //    listVSTObject.TotalsRowRange.Font.Bold = true;
        //    listVSTObject.TotalsRowRange.RowHeight = 15.75;
        //}
        //#endregion

        //public static void Hide_RDP_BlackBox()
        //{
        //    Process[] processess = Process.GetProcessesByName("mstsc");
        //    if (processess.Length > 0)
        //    {
        //        IntPtr appHandle = processess[0].MainWindowHandle;
        //        if (appHandle == IntPtr.Zero) return;

        //        IntPtr hwndChild = Native.FindWindow("RAIL_WINDOW", "Microsoft.VisualStudio.OfficeTools.Controls.PresentationManager+ParkingWindow (Work Resources)");
        //        if (hwndChild == IntPtr.Zero) return;

        //        Native.ShowWindow(hwndChild, 0);
        //    }
        //}

    }
}
