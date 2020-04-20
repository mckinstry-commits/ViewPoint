using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKWOClose
{
    internal static partial class HelperUI
    {
        internal const string pwd = "HowardSnow";

        public static void ProtectSheet(Excel._Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(pwd, true, Type.Missing, Type.Missing, true, true, true,
                  Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }

        public static int GetDynamicPaneWidth()
        {
            System.Drawing.Rectangle screen = Screen.FromControl((Control)Globals.ThisWorkbook._myActionPane).Bounds;
            int width;

            switch (screen.Width)
            {
                case 1920:
                    width = 233; // desk monitor
                    break;
                case 1280:
                    width = 245; // laptop montitor
                    break;
                case 1024:
                    width = 248; // smaller devices
                    break;
                default:
                    width = 242;
                    break;
            }

            return width;
        }

        public static Excel.Worksheet GetSheet(string sheetName, bool extactMatch = true)
        {
            if (sheetName == "" || sheetName == null) return null;

            switch (extactMatch)
            {
                case true:
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Application.Sheets)
                    {
                        if (ws.Name == sheetName) return ws;
                    }
                    break;
                case false:
                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Application.Sheets)
                    {
                        if (ws.Name.Contains(sheetName)) return ws;
                    }
                    break;
            }
            return null;
        }
        internal static bool DeleteSheet(string sheetName)
        {
            Excel.Worksheet ws = null;
            AlertOff();

            try
            {
                ws = Globals.ThisWorkbook.Worksheets.get_Item(sheetName);
                ws.Delete();
                return true;
            }
            catch { return false; }
            finally
            {
                AlertON();
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
        }

        internal static void AlertOff() => Globals.ThisWorkbook.Application.DisplayAlerts = false;
        internal static void AlertON() => Globals.ThisWorkbook.Application.DisplayAlerts = true;

        #region CELL FORMAT
        internal static string CurrencyStyle => "Currency";  // is Accounting
        internal static string GeneralFormat => "General;(#,##0.0);;@";
        internal static string AccountingNoSign = @"_(* #,##0.0000_);_(* (#,##0.0000);_(* ""-""??_);_(@_)";
        internal static string DateFormatMMDDYY => "MM/dd/yy";
        internal static string StringFormat => "@";
        #endregion

        // lessen CPU consumption / speed things up
        internal static void RenderOFF()
        {
            try
            {
                Globals.ThisWorkbook.Application.ScreenUpdating = false;
            }
            catch { throw; }
        }
        internal static void RenderON()
        {
            try
            {
                Globals.ThisWorkbook.Application.ScreenUpdating = true;
            }
            catch { throw; }
        }
        internal static void MergeLabel(Excel.Worksheet ws, string fromCell, string ToCell, string caption, uint tableId = 1, uint offsetRowUpFromTableHeader = 2,
                                double rowHeight = 30, uint fontSize = 12, Excel.XlHAlign horizAlign = Excel.XlHAlign.xlHAlignCenter)
        {
            Excel.Range from = null;
            Excel.Range to = null;

            try
            {
                from = ws.ListObjects[tableId].ListColumns[fromCell].Range;
                to = ws.ListObjects[tableId].ListColumns[ToCell].Range;

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

        #region STYLE GUIDE

        internal static void ShowGridLines(Excel.Borders _borders)
        {
            _borders[Excel.XlBordersIndex.xlEdgeLeft].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeRight].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeBottom].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders.Color = Color.Black;
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
            table.HeaderRowRange.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
            table.HeaderRowRange.Font.Color = HelperUI.WhiteHeaderFontColor;
            table.HeaderRowRange.Font.Size = 10;
            table.HeaderRowRange.Font.Bold = true;
            table.HeaderRowRange.WrapText = true;
            table.HeaderRowRange.Rows.RowHeight = 15;
            table.HeaderRowRange.EntireColumn.AutoFit();

            //table.DataBodyRange.Interior.Color = HelperUI.WhiteFontColor;
            //table.DataBodyRange.Font.Color = HelperUI.McKColor(McKColors.Black);

            if (showTotals)
            {
                table.ShowTotals = true;
                table.TotalsRowRange.Interior.Color = HelperUI.NavyBlueTotalRowColor;
                table.TotalsRowRange.Font.Color = HelperUI.WhiteFontColor;
                table.TotalsRowRange.Font.Size = 12;
                table.TotalsRowRange.Font.Italic = false;
                table.TotalsRowRange.Font.Bold = true;
                table.TotalsRowRange.RowHeight = 15.75;
            }
            return table;
        }

        internal static uint TwentyFontSizePageHeader => 20;

        #region COLORS

        internal static int ColorToInt(Color color) => ColorTranslator.ToWin32(color);
        internal enum McKColors
        {
            NavyBlue
            , Gray
            , GrayLighter
            , GrayLight
            , GrayDark
            , Yellow
            , Red
            , BrightRed
            , Green
            , SoftBlack
            , SoftBeige
            , AquaBlue
            , White
            , Black
        }
        internal static Color McKColor(McKColors color)
        {
            switch (color)
            {
                case McKColors.NavyBlue: return Color.FromArgb(10, 63, 84);

                case McKColors.Gray: return Color.FromArgb(118, 131, 147);

                case McKColors.GrayLight: return Color.FromArgb(192, 195, 204);

                case McKColors.Yellow: return Color.FromArgb(250, 237, 191);

                case McKColors.Red: return Color.FromArgb(255, 189, 189);

                case McKColors.BrightRed: return Color.FromArgb(255, 0, 0);

                case McKColors.Green: return Color.FromArgb(198, 224, 180);

                case McKColors.SoftBlack: return Color.FromArgb(32, 31, 32);

                case McKColors.SoftBeige: return Color.FromArgb(250, 240, 235);

                case McKColors.White: return Color.FromArgb(255, 255, 255);

                case McKColors.AquaBlue: return Color.FromArgb(205, 251, 255);

                case McKColors.Black: return Color.FromArgb(0, 0, 0);

                default: return Color.White;
            }
        }
        internal static Color WhiteDownHeaderFontColor => McKColor(McKColors.White);
        internal static Color GrayDarkColor => McKColor(McKColors.GrayDark);
        internal static Color GrayBreakDownHeaderRowColor => McKColor(McKColors.Gray);
        internal static Color LightGrayHeaderRowColor => McKColor(McKColors.GrayLight);
        internal static Color SoftBlackHeaderFontColor => McKColor(McKColors.SoftBlack);
        internal static Color NavyBlueHeaderRowColor => McKColor(McKColors.NavyBlue);
        internal static Color WhiteHeaderFontColor => McKColor(McKColors.White);
        internal static Color NavyBlueTotalRowColor => McKColor(McKColors.NavyBlue);
        internal static Color WhiteFontColor => McKColor(McKColors.White);
        internal static Color DataEntryColor => McKColor(McKColors.Yellow);
        internal static Color RedNegColor => McKColor(McKColors.Red);
        internal static Color GreenPosColor => McKColor(McKColors.Green);
        internal static Color CellBorderColor => McKColor(McKColors.GrayLight);

        #endregion

        #endregion

    }
}
