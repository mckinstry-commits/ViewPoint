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

namespace Mck_TL_UI
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

        //public static Excel.Worksheet GetSheet(string sheetName, bool extactMatch = true)
        //{
        //    if (sheetName == "" || sheetName == null) return null;

        //    switch (extactMatch)
        //    {
        //        case true:
        //            foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
        //            {
        //                if (ws.Name == sheetName) return ws;
        //            }
        //            break;
        //        case false:
        //            foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
        //            {
        //                if (ws.Name.Contains(sheetName)) return ws;
        //            }
        //            break;
        //    }
        //    return null;
        //}

        public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(ActionPane.pwd, false, Type.Missing, Type.Missing, true, true, true,
                        Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }

        // Lower CPU consumption / speed things up
        internal static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        internal static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

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

                //case McKColors.Orange:    return  Color.FromArgb(207, 103, 51);

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

    }
}
