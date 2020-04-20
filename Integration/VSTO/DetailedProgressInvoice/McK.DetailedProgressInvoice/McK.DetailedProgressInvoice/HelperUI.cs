using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    internal static class HelperUI
    {
        internal static Excel.Worksheet GetSheet(string sheetName, bool extactMatch = true)
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
            try
            {
                ws = Globals.ThisWorkbook.Worksheets.get_Item(sheetName);
                ws?.Delete();
                return true;
            }
            catch { return false; }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        #region CELL FORMAT
        internal static string PercentFormat => "###,##.00%_);_(* (###,##.00%);_(* \" - \"??_);_(@_)";

        internal static string CurrencyStyle => "Currency";  // is Accounting
        internal static string GeneralFormat => "General;(#,##0.0);;@";
        //internal static string NumberBlankZeros => "#,##0.00;_(* -###,##.##;;_(@_)";
        internal static string Number           => "#,##0.00;_(* -###,##.00;0.00;";
        internal static string DateFormatMMDDYY => "MM/dd/yy";
        internal static string StringFormat => "@";
        #endregion

        // Lower CPU consumption / speed things up
        internal static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        internal static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        #region STYLE / FORMAT

        internal static Excel.ListObject FormatAsTable(Excel.Range SourceRange, string TableName, bool showTotals = true, bool bandedRows = false, Excel.XlYesNoGuess hasHeaders = Excel.XlYesNoGuess.xlYes)
        {
            //ShowGridLines(SourceRange.Borders);

            //SourceRange.Style = "Normal";
            Excel.ListObject table = SourceRange.Worksheet.ListObjects.Add(Excel.XlListObjectSourceType.xlSrcRange, SourceRange, Type.Missing, hasHeaders, Type.Missing);
            table.Name = TableName;

            //if (bandedRows)
            //{
            //    table.TableStyle = "TableStyleLight16";
            //}
            table.Range.Style = "Normal";

            table.Range.Font.Size = 9;
            //table.HeaderRowRange.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
            //table.HeaderRowRange.Font.Color = HelperUI.WhiteHeaderFontColor;
            table.HeaderRowRange.Font.Size = 10;
            table.HeaderRowRange.Font.Bold = true;
            table.HeaderRowRange.WrapText = true;
            //table.HeaderRowRange.Rows.RowHeight = 15;
            //table.HeaderRowRange.EntireColumn.AutoFit();

            //table.DataBodyRange.Interior.Color = HelperUI.WhiteFontColor;
            //table.DataBodyRange.Font.Color = HelperUI.McKColor(McKColors.Black);

            if (showTotals)
            {
                table.ShowTotals = true;
                //table.TotalsRowRange.Interior.Color = HelperUI.NavyBlueTotalRowColor;
                //table.TotalsRowRange.Font.Color = HelperUI.WhiteFontColor;
                table.TotalsRowRange.Font.Size = 10;
                table.TotalsRowRange.Font.Italic = false;
                table.TotalsRowRange.Font.Bold = true;
                table.TotalsRowRange.RowHeight = 15.75;
            }
            return table;
        }

        internal static void ShowGridLines(Excel.Borders _borders)
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

        internal static uint TwentyFontSizePageHeader => 20;

        #region COLORS

        internal static int ColorToInt(Color color) => ColorTranslator.ToWin32(color);
        internal enum McKColors
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
        internal static Color McKColor(McKColors color)
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

                //case McKColors.Orange:    return  Color.FromArgb(207, 103, 51);

                //case McKColors.Olive:     return  Color.FromArgb(154, 150, 60);

                //case McKColors.Peacock:   return  Color.FromArgb(0, 132, 142);

                //case McKColors.Burgandy:  return  Color.FromArgb(107, 56, 59);

                //case McKColors.Lime:      return  Color.FromArgb(177, 198, 86);

                //case McKColors.Jade:      return  Color.FromArgb(115, 183, 149);

                default: return Color.White;
            }
        }
        internal static Color WhiteDownHeaderFontColor => McKColor(McKColors.White);
        internal static Color GrayBreakDownHeaderRowColor => McKColor(McKColors.Gray);
        internal static Color LightGrayHeaderRowColor => McKColor(McKColors.LightGray);
        internal static Color SoftBlackHeaderFontColor => McKColor(McKColors.SoftBlack);
        internal static Color NavyBlueHeaderRowColor => McKColor(McKColors.NavyBlue);
        internal static Color WhiteHeaderFontColor => McKColor(McKColors.White);
        internal static Color NavyBlueTotalRowColor => McKColor(McKColors.NavyBlue);
        internal static Color WhiteFontColor => McKColor(McKColors.White);
        internal static Color DataEntryColor => McKColor(McKColors.Yellow);
        internal static Color RedNegColor => McKColor(McKColors.Red);
        internal static Color GreenPosColor => McKColor(McKColors.Green);
        internal static Color CellBorderColor => McKColor(McKColors.LightGray);

        #endregion

        #endregion

        internal static void AlertOff() => Globals.ThisWorkbook.Application.DisplayAlerts = false;
        internal static void AlertON() => Globals.ThisWorkbook.Application.DisplayAlerts = true;

        public static void PrintPageSetup(Excel.Worksheet ws, string FedTaxId, string footer = "")
        {
            ws.PageSetup.Orientation = Excel.XlPageOrientation.xlLandscape;
            try
            {
                ws.DisplayPageBreaks = false;
                ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperLetter;
            }
            catch { }
            //ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
            ws.PageSetup.Zoom = false;
            ws.PageSetup.FitToPagesTall = false;
            ws.PageSetup.FitToPagesWide = 1;
            //ws.PageSetup.AlignMarginsHeaderFooter = false;
            ws.PageSetup.TopMargin = .75;
            ws.PageSetup.BottomMargin = .75;
            ws.PageSetup.LeftMargin = .25;
            ws.PageSetup.RightMargin = .25;
            ws.PageSetup.HeaderMargin = .3;
            ws.PageSetup.FooterMargin = .3;
            ws.PageSetup.CenterHorizontally = true;


            #region FOOTER
            //ws.PageSetup.LeftFooter = footer + FedTaxId;
            ws.PageSetup.RightFooter = "Page &P of &N";
            #endregion
        }
    }
}
