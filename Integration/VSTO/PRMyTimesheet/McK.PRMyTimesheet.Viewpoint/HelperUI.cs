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

namespace McK.PRMyTimesheet.Viewpoint
{
    public static class HelperUI
    {

        #region NUMBER FORMATS
        public static string CurrencyStyle => "Currency";  // is Accounting
        public static string NumberFormat => "#,##0.00;-#,##0.00;0;@";

        public static string NumberFormatx => "#,##0;-#,##0;0;@";
        public static string DateFormatMMDDYY => "MM/dd/yy";

        internal static string StringFormat => "@";
        #region UNUSED
        //public static string PercentFormat => "###,##.##%_);_(* (###,##.##%);_(* \" - \"??_);_(@_)";
        //public static string CurrencyFormat
        //{
        //    get
        //    {
        //        return "_($* #,##0.00_);_($* (#,##0.00);_($* \" - \"??_);_(@_)";
        //    }
        //}

        //public static string DateTimeShortAMPM
        //{
        //    get
        //    {
        //        return string.Format("{0:M/dd/yy h:mm:ss tt}", DateTime.Now);
        //    }
        //}

        //public static string CurrencyFormatCondensed => "$#,##0.00;$(#,##0.00);$\" - \"??;(_(@_)";

        //public static string GeneralFormat => "General;(#,##0.0);;@";

        //public static string NumberFormats => "0;(0);0;@";

        //public static string StringFormat => "@";

        //public static string DateFormatMMDDYYYY => "MM/dd/yyyy";
        //public static string DateFormatMDYYhmmAMPM => "m/d/yy h:mm AM/PM";
        //public static string DateFormatMDYYYYhmmAMPM => "m/d/yyyy h:mm AM/PM";
        #endregion

        #endregion

        #region SHEETS HANDLING


        internal static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        internal static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        internal static void AlertOff() => Globals.ThisWorkbook.Application.DisplayAlerts = false;
        internal static void AlertON() => Globals.ThisWorkbook.Application.DisplayAlerts = true;

        //public static Excel.Worksheet GetSheet(string sheetName)
        //{
        //    Excel.Worksheet ws = null;
        //    AlertOff();

        //    try
        //    {
        //        ws = Globals.ThisWorkbook.Worksheets.get_Item(sheetName);
        //        return ws;
        //    }
        //    catch { return null; }
        //    finally
        //    {
        //        AlertON();
        //    }
        //}

        internal static bool DeleteSheet(string sheetName)
        {
            Excel.Worksheet ws = null;
            AlertOff();

            try
            {
                ws = Globals.ThisWorkbook.Worksheets.get_Item(sheetName);
                ws?.Delete();
                return true;
            }
            catch { return false; }
            finally
            {
                AlertON();
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        //public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        //{
        //    _ws.EnableOutlining = true;
        //    _ws.Protect(ActionPane.pwd, false, Type.Missing, Type.Missing, true, true, true,
        //                Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        //}

        // Lower CPU consumption / speed things up

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


        internal static void MergeLabel(Excel.Worksheet ws, string fromCell, string ToCell, string caption, uint tableId = 1, uint offsetRowUpFromTableHeader = 2,
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
                from.Formula = caption?.ToUpper();
                from.Cells.HorizontalAlignment = horizAlign;
                from.Cells.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                from.RowHeight = rowHeight;
                from.Interior.PatternColorIndex = Excel.XlColorIndex.xlColorIndexAutomatic;
                from.Interior.Color = HelperUI.LightGray;
                from.Font.Color = HelperUI.SoftBlack;
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


        internal static Excel.ListObject FormatAsTable(Excel.Range SourceRange, string TableName, bool showTotals = true, bool bandedRows = false)
        {
            Excel.ListObject table;
            
            ShowGridLines(SourceRange.Borders);

            SourceRange.Style = "Normal";
            table = SourceRange.Worksheet.ListObjects.Add(Excel.XlListObjectSourceType.xlSrcRange, SourceRange, Type.Missing, Excel.XlYesNoGuess.xlYes, Type.Missing);
            table.Name = TableName;

            if (bandedRows)
            {
                table.TableStyle = "TableStyleLight16";
            }
            table.Range.Font.Size = 9;
            table.HeaderRowRange.Interior.Color = HelperUI.NavyBlue;
            table.HeaderRowRange.Font.Color = HelperUI.White;
            table.HeaderRowRange.Font.Size = 10;
            table.HeaderRowRange.Font.Bold = true;
            table.HeaderRowRange.WrapText = true;
            table.HeaderRowRange.Rows.RowHeight = 15;
            table.HeaderRowRange.EntireColumn.AutoFit();

            if (showTotals)
            {
                table.ShowTotals = true;
                table.TotalsRowRange.Interior.Color = HelperUI.NavyBlue;
                table.TotalsRowRange.Font.Color = HelperUI.White;
                table.TotalsRowRange.Font.Size = 12;
                table.TotalsRowRange.Font.Italic = false;
                table.TotalsRowRange.Font.Bold = true;
                table.TotalsRowRange.RowHeight = 15.75;
            }
            return table;
        }

        //public static int ColorToInt(Color color) => ColorTranslator.ToWin32(color);

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


        //public static string FontCalibri => "Calibri";


        #region FONT SIZES

        public static uint TwentyFontSizePageHeader => 20;
        public static int FourteenBreakDownHeaderFontSize => 14;
        public static int TwelveFontSizeHeader => 12;
        public static int TenSizeFontSecondHeaderRow => 10;
        public static int TwelveFontSizeTotal => 12;

        #endregion 
        

        #region COLORS

        public static Color LightGray => Color.FromArgb(192, 195, 204);
        public static Color SoftBlack => Color.FromArgb(32, 31, 32);
        public static Color NavyBlue => Color.FromArgb(10, 63, 84);
        public static Color White => Color.FromArgb(255, 255, 255);
        public static Color OrangePastel => Color.FromArgb(255, 204, 153); 
        public static Color GreenPastel  => Color.FromArgb(204, 255, 153); 
        public static Color YellowLight => Color.FromArgb(248, 230, 201);
        #endregion

        #endregion

    }
}
