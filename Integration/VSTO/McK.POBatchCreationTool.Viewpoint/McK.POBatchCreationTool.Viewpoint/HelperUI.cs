using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.POBatchCreationTool.Viewpoint
{
    public static class HelperUI
    {

        public const string pwd = "HowardSnow";

        public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(pwd, true, Type.Missing, Type.Missing, true, true, true,
                  Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }

        internal static Excel.ListObject FormatAsTable(Excel.Range SourceRange, string TableName, bool showTotals = true, bool bandedRows = false)
        {
            Excel.ListObject table;

            ShowBorderGridLines(SourceRange.Borders);

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

        #region Formatting
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

        internal static void ShowBorderGridLines(Excel.Borders _borders)
        {
            _borders[Excel.XlBordersIndex.xlEdgeLeft].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeRight].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders[Excel.XlBordersIndex.xlEdgeBottom].LineStyle = Excel.XlLineStyle.xlContinuous;
            _borders.Color = Color.Black;
        }

        internal static string StringFormat => "@";
        internal static string DateFormatMMDDYY => "MM/dd/yy";
        internal static string DateFormatMMYY => "MM/yy";

        internal static uint TwentyFontSizePageHeader => 20;

        internal static Color RedNegColor => McKColor(McKColors.Red);

        internal static Color NavyBlueTotalRowColor => McKColor(McKColors.NavyBlue);

        internal static Color NavyBlueHeaderRowColor => McKColor(McKColors.NavyBlue);
        internal static Color WhiteHeaderFontColor => McKColor(McKColors.White);
        internal static Color WhiteFontColor => McKColor(McKColors.White);

        internal static Color GrayDarkColor => McKColor(McKColors.GrayDark);
        internal static Color LightGrayHeaderRowColor => McKColor(McKColors.LightGray);
        internal static Color SoftBlackHeaderFontColor => McKColor(McKColors.SoftBlack);

        internal enum McKColors
        {
            NavyBlue
            , Gray
            , GrayDark
            , LightGray
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

                case McKColors.LightGray: return Color.FromArgb(192, 195, 204);

                case McKColors.GrayDark: return Color.FromArgb(219, 219, 219);

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
        #endregion

    }
}
