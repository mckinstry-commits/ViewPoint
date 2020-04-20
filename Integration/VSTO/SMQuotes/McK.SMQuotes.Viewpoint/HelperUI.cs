using System;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.SMQuotes.Viewpoint
{
    internal static class HelperUI
    {
        internal static string AccountingNoSign = @"_(* #,##0.00_);_(* (#,##0.00);_(* ""-""??_);_(@_)";

        internal static string PhoneNumber = "[<=9999999]###-####;(###) ###-####";

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

        #region CELL FORMAT
        internal static string PercentFormat => "###,##.00%_);_(* (###,##.00%);_(* \" - \"??_);_(@_)";

        internal static string CurrencyStyle => "Currency";  // is Accounting
        internal static string GeneralFormat => "General;(#,##0.0);;@";
        //internal static string NumberBlankZeros => "#,##0.00;_(* -###,##.##;;_(@_)";
        internal static string Number => "#,##0.00;_(* -###,##.00;0.00;";
        internal static string DateFormatMMDDYY => "MM/dd/yy";
        internal static string DateFormatMMYY => "MM/yy";
        internal static string StringFormat => "@";

        #endregion

        // Lower CPU consumption / speed things up
        internal static void RenderOFF() => Globals.ThisWorkbook.Application.ScreenUpdating = false;
        internal static void RenderON() => Globals.ThisWorkbook.Application.ScreenUpdating = true;

        #region STYLE / FORMAT

        internal static Excel.ListObject FormatAsTable(Excel.Range SourceRange, string TableName, bool showTotals = true, bool bandedRows = false, Excel.XlYesNoGuess hasHeaders = Excel.XlYesNoGuess.xlYes)
        {
            ShowGridLines(SourceRange.Borders);

            //SourceRange.Style = "Normal";
            Excel.ListObject table = SourceRange.Worksheet.ListObjects.Add(Excel.XlListObjectSourceType.xlSrcRange, SourceRange, Type.Missing, hasHeaders, Type.Missing);
            table.Name = TableName;

            if (bandedRows)
            {
                table.TableStyle = "TableStyleLight16";
            }
            //table.Range.Style = "Normal";

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
        public static Color GreenPastel => Color.FromArgb(204, 255, 153);
        public static Color YellowDim => Color.FromArgb(248, 230, 201);
        public static dynamic YellowLight => 13434879;
        public static Color Red => Color.FromArgb(255, 189, 189);
        #endregion

        #endregion

        internal static void AlertOff() => Globals.ThisWorkbook.Application.DisplayAlerts = false;
        internal static void AlertON() => Globals.ThisWorkbook.Application.DisplayAlerts = true;

        #region UNUSED

        //public static void PrintPage_Setup(Excel.Worksheet ws)
        //{
        //    try
        //    {
        //        ws.PageSetup.Orientation = Excel.XlPageOrientation.xlPortrait;
        //        ws.DisplayPageBreaks = false;
        //        ws.PageSetup.PaperSize = Excel.XlPaperSize.xlPaperLetter;
        //        ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
        //        ws.PageSetup.Zoom = false;
        //        ws.PageSetup.TopMargin = .75;
        //        ws.PageSetup.BottomMargin = .75;
        //        ws.PageSetup.LeftMargin = .7;
        //        ws.PageSetup.RightMargin = .7;
        //        ws.PageSetup.HeaderMargin = .3;
        //        ws.PageSetup.FooterMargin = .3;
        //        ws.PageSetup.CenterFooter = "&P / &N";
        //        ws.PageSetup.CenterHorizontally = true;
        //        ws.PageSetup.FitToPagesTall = 1;
        //        ws.PageSetup.FitToPagesWide = 1;
        //    }
        //    catch { } // let it go..

        //}

        //public static void PrintPageSetup(Excel.Worksheet ws, string footer = "")
        //{
        //    ws.PageSetup.Orientation = Excel.XlPageOrientation.xlLandscape;
        //    try
        //    {
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


        //        #region FOOTER
        //        ws.PageSetup.RightFooter = "Page &P of &N";
        //        #endregion
        //    }
        //    catch { } // don't halt program if Printer is not detected
        //}

        #endregion

        public static void Recipients_ConditionalFormat(Excel.ListObject table)
        {
            Excel.Worksheet ws = null;
            Excel.Range cell = null;
            Excel.Range sendFrom = null;
            Excel.Range billEmail = null;
            Excel.Range reqWO = null;
            Excel.Range reqInspRpt = null;
            Excel.Range reqSignoff = null;
            Excel.Range reqLienRelease = null;
            Excel.Range reqCertPayroll = null;

            int rowAt;
            int toRowCnt;

            try
            {
                ws       = table.Parent;
                toRowCnt = table.ListRows.Count;

                // DeliverTo Email But No Email Provided
                billEmail = table.ListColumns["Bill Email"].Range;
                var billEmailSplit  = billEmail.Address.Split('$');
                var deliveryMethodSplit = table.ListColumns["Delivery Method"].Range.Address.Split('$');

                //  send from
                sendFrom = table.ListColumns["Send From"].Range;
                var sendFromSplit = sendFrom.Address.Split('$');

                //  req. WO 
                reqWO = table.ListColumns["Required WO With Billing"].Range;
                var reqWOsplit = reqWO.Address.Split('$');

                // req. inpect rpt  
                reqInspRpt = table.ListColumns["Require Inspection Report With Billing"].Range;
                var reqInspRptSplit = reqInspRpt.Address.Split('$');

                // req. sign off  
                reqSignoff = table.ListColumns["Sign Off Required"].Range;
                var reqSignoffSplit = reqSignoff.Address.Split('$');

                // req. lien release
                reqLienRelease = table.ListColumns["Lien Release"].Range;
                var reqLienRelSplit = reqLienRelease.Address.Split('$');

                // req. certified payroll
                reqCertPayroll = table.ListColumns["Certified Payroll"].Range;
                var reqCertPayrollSplit = reqCertPayroll.Address.Split('$');

                for (int i = 1; i <= toRowCnt; i++)
                {
                    rowAt = billEmail.Row + i;

                    // Delivery Methods is email but no billing email provided. SEARCH is NOT case-sensitive.
                    cell = ws.Cells[rowAt, billEmail.Column];

                    var missingBillEmailCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                    "=AND($" + billEmailSplit[1] + rowAt + " =\"\"," + "ISNUMBER(SEARCH(\"Emails\",$" + deliveryMethodSplit[1] + rowAt + ")))"
                                                    , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    missingBillEmailCond.Interior.Color = HelperUI.Red;
                    missingBillEmailCond.Font.Bold = true;


                    // send from
                    cell = ws.Cells[rowAt, sendFrom.Column];

                    var sendFromcond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                        "=AND($" + sendFromSplit[1] + rowAt + " =\"\"," + "ISNUMBER(SEARCH(\"Emails\",$" + deliveryMethodSplit[1] + rowAt + ")))"
                                        , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    sendFromcond.Interior.Color = HelperUI.Red;
                    sendFromcond.Font.Bold = true;

                    // req. WO  
                    cell = ws.Cells[rowAt, reqWO.Column];

                    var needAttachWOcond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                            "=ISNUMBER(SEARCH(\"Y\",$" + reqWOsplit[1] + rowAt + "))"
                                            , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    needAttachWOcond.Interior.Color = HelperUI.YellowLight;
                    needAttachWOcond.Font.Bold = true;

                    // req. inpect rpt  
                    cell = ws.Cells[rowAt, reqInspRpt.Column];

                    var needAttachInspectRptCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                    "=ISNUMBER(SEARCH(\"Y\",$" + reqInspRptSplit[1] + rowAt + "))"
                                    , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    needAttachInspectRptCond.Interior.Color = HelperUI.YellowLight;
                    needAttachInspectRptCond.Font.Bold = true;

                    // req. sign off  
                    cell = ws.Cells[rowAt, reqSignoff.Column];

                    var needAttachSignoffCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                    "=ISNUMBER(SEARCH(\"Y\",$" + reqSignoffSplit[1] + rowAt + "))"
                                    , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    needAttachSignoffCond.Interior.Color = HelperUI.YellowLight;
                    needAttachSignoffCond.Font.Bold = true;

                    // req. lien release
                    cell = ws.Cells[rowAt, reqLienRelease.Column];

                    var needAttachLienRelCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                    "=ISNUMBER(SEARCH(\"Y\",$" + reqLienRelSplit[1] + rowAt + "))"
                                    , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    needAttachLienRelCond.Interior.Color = HelperUI.YellowLight;
                    needAttachLienRelCond.Font.Bold = true;

                    // req. certified payroll
                    cell = ws.Cells[rowAt, reqCertPayroll.Column];

                    var needAttachCertPayrollCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                    "=ISNUMBER(SEARCH(\"Y\",$" + reqCertPayrollSplit[1] + rowAt + "))"
                                    , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    needAttachCertPayrollCond.Interior.Color = HelperUI.YellowLight;
                    needAttachCertPayrollCond.Font.Bold = true;
                }
            }
            catch (Exception ex)
            {
                // let it go.. no big deal if this fails..
                HelperUI.ShowErr(ex);
            }
            finally
            {
                if (billEmail != null) Marshal.ReleaseComObject(billEmail);
                if (reqWO != null) Marshal.ReleaseComObject(reqWO);
                if (cell != null) Marshal.ReleaseComObject(cell);
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
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

            StringBuilder text = new StringBuilder(content);
            string contentConsiderTabs = text.ToString().Replace("\t", new string(' ', 5));
            int textLineBreakCnt = RegEx.GetCarriageReturnCount(contentConsiderTabs);

            int charCnt = contentConsiderTabs.ToArray().Count();

            if (charCnt > charCntVisibleInFirstRow && textLineBreakCnt == 0)
            {
                // Continuous text longer than visible chars in the first line of the cell and no carriage returns.
                // Wrap text / autofit does'nt automatically expand row height on merged cells.
                textLineBreakCnt = charCnt / charCntVisibleInFirstRow;
            }

            // fix when a line wraps, it needs extra row height
            rowHeight = textLineBreakCnt > 1 ? (rowHeight * textLineBreakCnt) : rowHeight * textLineBreakCnt + rowHeight;
            //rowHeight = charCnt / notesLineBreakCnt - 1;

            //decimal rowHeight2 = (charCnt / charCntVisibleInFirstRow) * rowHeight;
            //rowHeight = rowHeight1 > rowHeight2 ? rowHeight1 : rowHeight2;

            return rowHeight;
        }


        #region SHOW ERRORS

        internal static void ShowErr(Exception ex = null, string text = null, string title = "Oops!")
        {
            string err = text ?? (ex?.Message != "" ? ex.Message : "Something went wrong");

            MessageBox.Show(null, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        internal static void ShowInfo(Exception ex = null, string msg = null, string title = "SM Invoice")
        {
            string err = msg ?? ex.Message;

            MessageBox.Show(null, err, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        internal static void errOut(Exception ex = null, string title = "Oops") => MessageBox.Show(null, ex?.Message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        #endregion
    }
}
