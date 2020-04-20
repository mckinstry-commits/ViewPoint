using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.GMA.Viewpoint
{
    public static class HelperUI
    {
        //public static int GetDynamicPaneWidth()
        //{
        //    System.Drawing.Rectangle screen = Screen.FromControl((Control)Globals.ThisWorkbook._myActionPane).Bounds;
        //    int width;

        //    switch (screen.Width)
        //    {
        //        case 1920:
        //            width = 100; // desk monitor
        //            break;
        //        case 1280:
        //            width = 245; // laptop montitor
        //            break;
        //        case 1024:
        //            width = 248; // smaller devices
        //            break;
        //        default:
        //            width = 242;
        //            break;
        //    }
        //    return width;
        //}
        public static string JobTrimDash(string job) => job.Split('-')[1];

        #region SHEETS
        public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(ActionsPaneGMA.pwd, false, Type.Missing, Type.Missing, true, true, true,
                  true, true, allowInsertRows, Type.Missing, true, allowDelRows, true, true, Type.Missing);
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

        public static bool SheetExists(string sheetName, bool extactMatch = true)
        {
            if (sheetName == "" || sheetName == null) return false;

            switch (extactMatch)
            {
                case true:

                    foreach (Excel.Worksheet ws in Globals.ThisWorkbook.Sheets)
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

        public static void PrintPage_GMAXSetup(Excel.Worksheet ws)
        {
            ws.PageSetup.Orientation = Excel.XlPageOrientation.xlPortrait;
            try
            {
                ws.DisplayPageBreaks = false;
                ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperTabloid;
            }
            catch { }
            ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
            ws.PageSetup.Zoom = false;
            ws.PageSetup.TopMargin = .75;
            ws.PageSetup.BottomMargin = .75;
            ws.PageSetup.LeftMargin = .7;
            ws.PageSetup.RightMargin = .7;
            ws.PageSetup.HeaderMargin = .3;
            ws.PageSetup.FooterMargin = .3;
            ws.PageSetup.CenterFooter = "&P / &N";
            ws.PageSetup.CenterHorizontally = true;
            ws.PageSetup.FitToPagesTall = 1;
            ws.PageSetup.FitToPagesWide = 1;
        }

        #endregion

        #region STYLE
        public static string PercentFormat => "0.00%_);_(* (0.00%);_(* \" - \"??_);_(@_)";
        public static string CurrencyStyle => "Currency";  // is Accounting
        public static string NumberFormat => "#,##0.0;(#,##0.0);0;@";

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
        public static Color NavyBlueHeaderRowColor => McKColor(McKColors.NavyBlue);
        public static Color WhiteFontColor => McKColor(McKColors.White);
        public static Color GrayBreakDownHeaderRowColor => McKColor(McKColors.Gray);
        #endregion
    }
}
