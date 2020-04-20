using System;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.POReport.Viewpoint
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

        /// <summary>
        /// Get what the row height should be to make content visible on Merged cells that do not autofit row height even with wrap text on
        /// </summary>
        /// <remarks>Uses Regex <see cref="System.Text.RegularExpressions"/> to detect carriage returns, if that fails it uses character count to solve for height</remarks>
        /// <param name="content">string text to be calculated</param>
        /// <param name="charCntVisibleInFirstRow">character count visible in first row</param>
        /// <returns></returns>
        public static decimal GetRowHeightToFitContent(string content, int charCntVisibleInFirstRow)
        {
            decimal rowHeight = 15m;

            StringBuilder notes = new StringBuilder(content);
            string contentConsiderTabs = notes.ToString().Replace("\t", new string(' ', 5));
            int notesLineBreakCnt = RegEx.GetCarriageReturnCount(contentConsiderTabs);

            int charCnt = contentConsiderTabs.ToArray().Count();

            if (charCnt > charCntVisibleInFirstRow && notesLineBreakCnt == 0)
            {
                // Continuous text longer than visible chars in the first line of the cell and no carriage returns.
                // Wrap text / autofit does'nt automatically expand row height on merged cells.
                notesLineBreakCnt = charCnt / charCntVisibleInFirstRow;
            }
            // fix when a line wraps, it needs extra row height
            rowHeight = notesLineBreakCnt > 1 ? (rowHeight * notesLineBreakCnt) : rowHeight * notesLineBreakCnt + rowHeight;
            //rowHeight = charCnt / notesLineBreakCnt - 1;

            //decimal rowHeight2 = (charCnt / charCntVisibleInFirstRow) * rowHeight;
            //rowHeight = rowHeight1 > rowHeight2 ? rowHeight1 : rowHeight2;

            return rowHeight;
        }

        #region CELL FORMAT
        internal static string DateFormatMMDDYY => "MM/dd/yy";

        #region NOT USED
        //internal static string PercentFormat => "###,##.00%_);_(* (###,##.00%);_(* \" - \"??_);_(@_)";
        //internal static string CurrencyStyle => "Currency";  // is Accounting
        //internal static string GeneralFormat => "General;(#,##0.0);;@";
        ////internal static string NumberBlankZeros => "#,##0.00;_(* -###,##.##;;_(@_)";
        //internal static string Number           => "#,##0.00;_(* -###,##.00;0.00;";
        //internal static string StringFormat => "@";
        #endregion

        #endregion

        // Lower CPU consumption / speed things up
        internal static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        internal static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        internal static void AlertOff() => Globals.ThisWorkbook.Application.DisplayAlerts = false;
        internal static void AlertON() => Globals.ThisWorkbook.Application.DisplayAlerts = true;

        //public static void PrintPageSetup(Excel.Worksheet ws, string footer = "")
        //{
        //    try
        //    {
        //        ws.PageSetup.Orientation = Excel.XlPageOrientation.xlLandscape;
        //        ws.DisplayPageBreaks = false;
        //        ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperLetter;
        //        //ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
        //        ws.PageSetup.Zoom = false;
        //        ws.PageSetup.FitToPagesTall = false;
        //        ws.PageSetup.FitToPagesWide = 1;
        //        //ws.PageSetup.AlignMarginsHeaderFooter = false;
        //        ws.PageSetup.TopMargin = .75;
        //        ws.PageSetup.BottomMargin = .75;
        //        ws.PageSetup.LeftMargin = .25;
        //        ws.PageSetup.RightMargin = .25;
        //        ws.PageSetup.HeaderMargin = .3;
        //        ws.PageSetup.FooterMargin = .3;
        //        ws.PageSetup.CenterHorizontally = true;
        //    }
        //    catch { }

        //    #region FOOTER
        //    //ws.PageSetup.LeftFooter = footer + FedTaxId;
        //    ws.PageSetup.RightFooter = "Page &P of &N";
        //    #endregion
        //}
    }
}
