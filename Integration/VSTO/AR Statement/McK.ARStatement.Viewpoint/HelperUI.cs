using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.ARStatement.Viewpoint
{
    internal static class HelperUI
    {
        public static Excel.ListObject CreateWorksheetFromList(List<dynamic> tableList, string tableName, string sheetName, string A1Title, string placeAfterSheet, int offsetFromLastUsedCell = 0)
        {
            Excel.ListObject xltable = null;
            Excel.Worksheet ws = null;
            Excel.Range rng = null;

            try
            {
                Globals.ThisWorkbook.Sheets.Add(After: Globals.ThisWorkbook.Sheets[placeAfterSheet]);
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                ws.Name = sheetName != "" ? sheetName : ws.Name;
                ws.Application.ActiveWindow.DisplayGridlines = false;

                if (A1Title != "")
                {
                    // Set Title
                    rng = ws.get_Range("A1");
                    rng.EntireRow.RowHeight = 27.75;
                    rng.Font.Size = 20;
                    rng.Formula = A1Title;
                }

                xltable = SheetBuilderDynamic.BuildTable(ws, tableList, tableName, offsetFromLastUsedCell, bandedRows: true);

            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
            return xltable;
        }

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

        internal static string AccountingNoSign = @"_(* #,##0.00_);_(* (#,##0.00);_(* ""-""??_);_(@_)";

        internal static string PhoneNumber = "[<=9999999]###-####;(###) ###-####";

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
                if (from.Row > offsetRowUpFromTableHeader)
                {
                    from = ws.Cells[from.Row - offsetRowUpFromTableHeader, from.Column];
                    to = ws.Cells[to.Row - offsetRowUpFromTableHeader, to.Column];
                }
                else
                {
                    from = ws.Cells[from.Row, from.Column];
                    to = ws.Cells[to.Row, to.Column];
                }
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
        public static Color LighterGray => Color.FromArgb(190, 190, 190);
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



        public static string GetColumnName(int index)
        {
            const byte BASE = 'Z' - 'A' + 1;
            string name = String.Empty;
            do
            {
                name = Convert.ToChar('A' + index % BASE) + name;
                index = index / BASE - 1;
            } while (index >= 0);
            return name;
        }

        internal static void Grid_ConditionalFormat(Excel.ListObject table)
        {
            Excel.Worksheet ws = null;
            Excel.Range cell = null;
            Excel.Range sendYNcell = null;
            Excel.Range billEmail = null;
            Excel.Range sendYN = null;
            Excel.Range previewYN = null;

            int rowAt;
            int toRowCnt;

            try
            {
                ws = table.Parent;
                toRowCnt = table.ListRows.Count;

                // DeliverTo Email But No Email Provided
                billEmail = table.ListColumns["Statement Email"].Range;
                var billEmailSplit = billEmail.Address.Split('$');
                var deliveryMethodSplit = table.ListColumns["Customer Delivery Method"].Range.Address.Split('$');

                //  Send Statement = Y make yellow
                sendYN = table.ListColumns["Send Statement Y/N"].Range;
                var sendYNsplit = sendYN.Address.Split('$');

                // Preview Statement Y/N
                previewYN = table.ListColumns["Preview Statement Y/N"].Range;
                var previewYNSplit = previewYN.Address.Split('$');

                for (int i = 1; i <= toRowCnt; i++)
                {
                    rowAt = billEmail.Row + i;

                    // Delivery Methods is email but no billing email provided. SEARCH is NOT case-sensitive.
                    cell = ws.Cells[rowAt, billEmail.Column];
                    sendYNcell = ws.Cells[rowAt, sendYN.Column];

                    //if ((string)sendYNcell.Formula != String.Empty)   // commented to let all the detail rows have formatting
                    //{
                    var missingBillEmailCond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                "=AND($" + billEmailSplit[1] + rowAt + " =\"\","  // email is missing
                                                            + "ISNUMBER(SEARCH(\"Email\",$" + deliveryMethodSplit[1] + rowAt + "))," // delivery method is Email
                                                            + "$" + sendYNsplit[1] + rowAt + "=\"Y\"" + // Send Statement = Y
                                                        ")"
                                                , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    missingBillEmailCond.Interior.Color = HelperUI.Red;
                    missingBillEmailCond.Font.Bold = true;
                    //}

                    // make yellow when Send Statement = Y (don't apply cond. empty cells)
                    //cell = ws.Cells[rowAt, sendYN.Column];

                    //if (((string)cell2.Formula) != String.Empty)  // commented to let all the detail rows have formatting
                    //{
                    var reqSendYNcond = (Excel.FormatCondition)sendYNcell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                            "=$" + sendYNsplit[1] + rowAt + "=\"Y\""
                                            , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    reqSendYNcond.Interior.Color = HelperUI.YellowLight;
                    reqSendYNcond.Font.Bold = true;
                    //}

                    // make yellow when Preview Statement = Y 
                    cell = ws.Cells[rowAt, previewYN.Column];

                    //if ((string)cell.Formula != String.Empty)      // commented to let all the detail rows have formatting
                    //{
                    var previewYNcond = (Excel.FormatCondition)cell.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
                                                "=$" + previewYNSplit[1] + rowAt + "=\"Y\""
                                                , Type.Missing, Type.Missing, Type.Missing, Type.Missing);
                    previewYNcond.Interior.Color = HelperUI.YellowLight;
                    previewYNcond.Font.Bold = true;
                    //}
                }
            }
            catch (Exception)
            {
                // let it go.. no big deal if this fails..
            }
            finally
            {
                if (billEmail != null) Marshal.ReleaseComObject(billEmail);
                if (sendYN != null) Marshal.ReleaseComObject(sendYN);
                if (cell != null) Marshal.ReleaseComObject(cell);
                if (ws != null) Marshal.ReleaseComObject(ws);
            }
        }

        internal static void Grid_ColumnFormat(Excel.ListObject xltable)
        {
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            Excel.Worksheet _wsStatements  = null;

            try
            {
                xltable.Range.EntireColumn.AutoFit();
                _wsStatements = xltable.Parent;

                #region FORMAT COLUMNS

                xltable.ListColumns["ARCo"].DataBodyRange.EntireColumn.ColumnWidth = 6;
                xltable.ListColumns["AR Customer Group"].DataBodyRange.EntireColumn.ColumnWidth = 7;
                //xlTable.ListColumns["Combine Customer Numbers"].DataBodyRange.EntireColumn.ColumnWidth = 10.11;
                xltable.ListColumns["Customer No."].DataBodyRange.EntireColumn.ColumnWidth = 7;
                xltable.ListColumns["Invoice# / CheckNo"].DataBodyRange.EntireColumn.ColumnWidth = 9.89;
                xltable.ListColumns["Through Date"].DataBodyRange.EntireColumn.ColumnWidth = 6.75; // 9.89;
                xltable.ListColumns["Invoice Date"].DataBodyRange.EntireColumn.ColumnWidth = 7.75;
                xltable.ListColumns["Invoice Due Date"].DataBodyRange.EntireColumn.ColumnWidth = 8.88;
                xltable.ListColumns["Send Statement Y/N"].DataBodyRange.EntireColumn.ColumnWidth = 9.22;
                xltable.ListColumns["Preview Statement Y/N"].DataBodyRange.EntireColumn.ColumnWidth = 9;
                xltable.ListColumns["Statement Email"].DataBodyRange.EntireColumn.ColumnWidth = 23;
                xltable.ListColumns["Customer Delivery Method"].DataBodyRange.EntireColumn.ColumnWidth = 9.44;
                xltable.ListColumns["Statement Month"].DataBodyRange.EntireColumn.ColumnWidth = 8.78;

                xltable.ListColumns["GL Dept Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Customer Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Customer Sort Name"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Statement Email"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                xltable.ListColumns["Contract Description"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                //xlTable.ListColumns["# of Invoices"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                rng = xltable.ListColumns["Bill To Address"].DataBodyRange;
                rng2 = xltable.ListColumns["Bill To City"].DataBodyRange;
                rng = _wsStatements.get_Range(rng, rng2);
                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                xltable.HeaderRowRange.EntireRow.AutoFit();

                #endregion

                // decided not to sort because it throws off the customer sections from the return sql
                //if (selectedCoKey == 0)
                //{
                //    xlTable.Sort.SortFields.Add(xlTable.ListColumns["ARCo"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                //}
                //xlTable.Sort.SortFields.Add(xlTable.ListColumns[" "].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                //xlTable.Sort.SortFields.Add(xlTable.ListColumns["Invoice# / CheckNo"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                //xlTable.Sort.SortFields.Add(xlTable.ListColumns["Invoice Date"].DataBodyRange, Excel.XlSortOn.xlSortOnValues, Excel.XlSortOrder.xlAscending);
                //xlTable.Sort.Apply();

                HelperUI.MergeLabel(_wsStatements, xltable.ListColumns[1].Name, xltable.ListColumns[xltable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                _wsStatements.Application.ActiveWindow.SplitRow = 3;
                _wsStatements.Application.ActiveWindow.FreezePanes = true;
                _wsStatements.Application.ErrorCheckingOptions.NumberAsText = false;
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (rng2 != null) Marshal.ReleaseComObject(rng2);
            }
        }

    }
}
