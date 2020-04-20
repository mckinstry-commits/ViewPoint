using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace McK.JBDetailedProgressInvoice.Viewpoint
{
    internal static class Invoices
    {
        public static uint Unique { get; set; }

        public static bool ToExcel(List<dynamic> table)
        {
            Excel.Worksheet ws = null;
            Excel.Worksheet wsItem = null;
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            Excel.Range rngCurrContractAmt = null;

            Excel.Range rngSubtotalBilledToDate = null;
            Excel.Range rngBilledToDate = null;
            Excel.Range rngSubtotalLessRetainage = null;
            Excel.Range rngLessRetainage = null;
            Excel.Range rngPrevBillApplication = null;
            Excel.Range rngLessPrevApplication = null;
            Excel.Range rngTotalDue = null;
            Excel.Range rngTotals = null;
            Excel.Range rngTaxAmt = null;
            Excel.Range rngCurrRetention = null;

            Excel.Range rngItems = null;
            Excel.ListObject xlTable = null;
            Excel.Shape xlTextBox = null;
            bool success = false;
            Excel.Range rngFooter = null;
            Excel.Range rngItem = null;
            dynamic colorDefault; 

            try
            {
                Globals.Invoice.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                // clean up previous invoice sheets
                Globals.ThisWorkbook.Application.DisplayAlerts = false;
                foreach (Excel.Worksheet _ws in Globals.ThisWorkbook.Sheets)
                {
                    if (_ws.Name != Globals.McK.Name && _ws.Name != Globals.Invoice.Name) _ws.Delete();
                }
                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                string invoice = "";
                int detailFrom = 20;    // detail line item starting row
                int detailCnt = 0;
                int detailStartRow = 0;      // top header rows + detail row count
                int detailLastRow = 0; 
                const int colCnt = 12;            // detail line item column count
                int currContractAmtCol = 3;
                int totalComplStoredToDateCol = 9;
                int perctComplete = 10;
                int notesLineBreakCnt = 0;
                decimal rowHeight = 15m;
                //int notesOffset = 0;
                decimal notesHeight = 0;
                decimal tax = 0;
                var uniqueInvoices = table.GroupBy(r => r.InvoiceJBIN.Value).Distinct();
                Unique = Convert.ToUInt32(uniqueInvoices.Count());
                string content = "";
                // loop invoices
                foreach (var _invoice in uniqueInvoices)
                {
                    dynamic inv = _invoice.First();

                    invoice = inv.InvoiceJBIN.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvoiceJBIN.Value.Replace(" ", "");
                    tax = inv.InvTax.Value + inv.PrevTax.Value;
                    int addTaxLine = (tax > 0 ? 1 : 0);

                    // Only calc when invoice changes
                    if (HelperUI.GetSheet(invoice) == null)
                    {
                        // create sheet from template
                        Globals.Invoice.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                        ws.Name = invoice + "-ALL";

                        // plug in header level values
                        #region TOP LEFT: Customer Contact

                        xlTextBox = ws.Shapes.Item("txtCustomerAddress");

                        // curate DBNULL values as empty strings
                        var customerName = inv.Name.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Name.Value;
                        var billAddress = inv.BillAddress.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillAddress.Value;
                        var billAddress2 = inv.BillAddress2.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillAddress2.Value;
                        var billCity = inv.BillCity.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillCity.Value;
                        var billState = inv.BillState.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillState.Value;
                        var billZip = inv.BillZip.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillZip.Value;

                        content = customerName
                                        + "\n"
                                        + billAddress
                                        + (billAddress2 == "" ? "" : "\n" + billAddress2)
                                        + "\n"
                                        + billCity + ", " + billState + " " + billZip;

                        xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text = content;

                        #endregion

                        #region MIDDLE LEFT: HEADER: customer reference id & Contract number

                        int customerNumber = inv.Customer.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Customer.Value;
                        string customerReference = inv.CustomerReference.Value.GetType() == typeof(DBNull) ? string.Empty : inv.CustomerReference.Value;
                        string customerContract = inv.Contract.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Contract.Value;
                        string descriptionJCCM = inv.DescriptionJCCM.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DescriptionJCCM.Value;

                        #region NOTES
                        string textLine = "";
                        StringBuilder notes = new StringBuilder(inv.NotesJCCI.Value.GetType() == typeof(DBNull) ? string.Empty : inv.NotesJCCI.Value);

                        if (inv.NotesJBIT.Value.GetType() != typeof(DBNull))
                        {
                            textLine = notes.Length > 0 ? "\n" + new String(' ', 13) + inv.NotesJBIT.Value : inv.NotesJBIT.Value;
                            notes.Append(textLine);
                        }

                        if (inv.BillNotes.Value.GetType() != typeof(DBNull))
                        {
                            textLine = notes.Length > 0 ? "\n" + new String(' ', 13) + inv.BillNotes.Value : inv.BillNotes.Value;
                            notes.Append(textLine);
                        }

                        if (inv.NotesJBIN.Value.GetType() != typeof(DBNull))
                        {
                            textLine = notes.Length > 0 ? "\n" + inv.NotesJBIN.Value : inv.NotesJBIN.Value;
                            notes.Append(textLine);
                        }

                        content = notes.ToString().Replace("\t", new string(' ', 5));
                        notesLineBreakCnt = content.Count(x => x == '\n');

                        //if (notesLineBreakCnt > 0)
                        //{
                        //    notesHeight = ;// + .5m;
                        //    notesHeight = notesLineBreakCnt > 1 ? rowHeight * notesLineBreakCnt + (rowHeight / 2) : rowHeight * notesLineBreakCnt + rowHeight;
                        //}
                        notesHeight = notesLineBreakCnt > 1 ? rowHeight * notesLineBreakCnt + (.125m) : rowHeight * notesLineBreakCnt + rowHeight;

                        #endregion

                        int rowAt = 15;
                        rng = ws.get_Range("A" + rowAt);
                        rng.Font.Size = 9;
                        rng.Font.Name = "Arial Narrow";
                        rng.Formula = customerReference == "" ? "" : "Customer Reference #: " + customerReference + "";
                        rng.Characters[Type.Missing, "Customer Reference #:".Length].Font.Bold = true;

                        rowAt += 1;

                        rng = ws.get_Range("A" + rowAt);
                        rng.Font.Size = 9;
                        rng.Font.Name = "Arial Narrow";
                        rng.Formula = "Contract: " + customerContract + " " + descriptionJCCM;
                        rng.Characters[Type.Missing, "Contract:".Length].Font.Bold = true;

                        rowAt += 1;

                        rng = ws.get_Range("A" + rowAt);
                        rng.Font.Size = 9;
                        rng.Font.Name = "Arial Narrow";
                        rng.Formula = "Customer Number: " + customerNumber;
                        rng.Characters[Type.Missing, "Customer Number:".Length].Font.Bold = true;

                        rowAt += 1;

                        rng = ws.get_Range("A" + rowAt + ":I" + rowAt);
                        rng.Merge();
                        rng.Font.Size = 9;
                        rng.Font.Name = "Arial Narrow";
                        rng.Formula = notes.Length > 0 ? "Notes: " + content : string.Empty;
                        rng.Characters[Type.Missing, "Notes:".Length].Font.Bold = true;
                        rng.VerticalAlignment = Excel.XlVAlign.xlVAlignTop;
                        rng.RowHeight = notesHeight;// == 0 ? rowHeight : notesHeight;

                        #endregion

                        #region TOP RIGHT HEADER (invoice number, date, period, cust ref, due date, pymt terms, etc.)

                        string invDate = inv.InvDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvDate.Value.ToString().Substring(0, inv.InvDate.Value.ToString().IndexOf(" "));  // remove time stamp
                        var application = inv.Application.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Application.Value;
                        string fromDate = inv.FromDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.FromDate.Value.ToString().Substring(0, inv.FromDate.Value.ToString().IndexOf(" ")); // remove time stamp
                        var toDate = inv.ToDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ToDate.Value.ToString().Substring(0, inv.ToDate.Value.ToString().IndexOf(" "));
                        var dueDate = inv.DueDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DueDate.Value.ToString().Substring(0, inv.DueDate.Value.ToString().IndexOf(" "));
                        var descriptionHQPT = inv.DescriptionHQPT.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DescriptionHQPT.Value;

                        content = "Invoice:                 " + invoice + "\n"
                                + "Invoice Date:        " + invDate + "\n"
                                + "Application #:       " + application + "\n"
                                + "Period Start:         " + fromDate + "\n"
                                + "Period End:          " + toDate + "\n" +
                                   Environment.NewLine
                                + "Invoice Due Date: " + dueDate + "\n"
                                + "Payment Terms:    " + descriptionHQPT;

                        xlTextBox = ws.Shapes.Item("txtBoxTopRightHeader");
                        xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text = content;
                        xlTextBox.TextFrame.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                        #endregion

                        //HelperUI.PrintPageSetup(ws, inv.FedTaxId.Value);
                    }

                    //grpDetailByItem = grpInvoices.GroupBy(r => r.ItemJCCI);
                    IEnumerable<IGrouping<string, DetailRow>> grpDetailByItem = null;

                    // loop detail rows
                    foreach (dynamic row in _invoice)
                    {
                        // get invoice detail rows
                        var grpInvoices = table.GroupBy(r => new
                        {
                            #region fields
                            r.InvoiceJBIN,
                            r.ItemJCCI,
                            r.DescriptionJBIS,
                            r.CurrContract,
                            r.ChgOrderAmt,
                            r.PrevAmtJBIN,
                            r.PrevAmt,
                            r.AmtBilled,
                            r.WCRetg,
                            r.PrevRetgJBIS,
                            r.PrevRetgReleased,
                            r.RetgBilled,
                            r.RetgRelJBIS,
                            r.PrevRetgTaxJBIS,
                            r.PrevRetgTaxRelJBIS,
                            r.RetgTaxJBIS,
                            r.RetgTaxRelJBIS,
                            r.PrevSM,
                            r.SM,
                            r.InvTotal,
                            r.PrevRetgJBIN,
                            r.PrevRRel,
                            r.InvRetg,
                            r.RetgRelJBIN,
                            r.PrevRetgTaxJBIN,
                            r.PrevRetgTaxRelJBIN,
                            r.RetgTaxJBIN,
                            r.RetgTaxRelJBIN,
                            r.PrevDue,
                            r.InvDue,
                            r.TaxAmtJBIT
                            //r.InvTax,
                            //r.PrevTax
                            #endregion
                        })
                        .Where(i => i.Key.InvoiceJBIN.Value.Replace(" ", "") == invoice) // invoice specific
                        .Select(r => new DetailRow()
                        {
                            InvoiceJBIN = r.Key.InvoiceJBIN.Value,
                            ItemJCCI = r.Key.ItemJCCI.Value,
                            DescriptionJBIS = r.Key.DescriptionJBIS.Value,
                            CurrContract = r.Key.CurrContract.Value,
                            CurrContractAmt = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value,
                            ChgOrderAmt = r.Key.ChgOrderAmt.Value,
                            BalanceToFinish = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value - r.Key.PrevAmt.Value - r.Key.AmtBilled.Value,
                            CurrRetention = r.Key.WCRetg.Value,
                            JTDRetention = (r.Key.PrevRetgJBIS.Value - r.Key.PrevRetgReleased.Value) + (r.Key.RetgBilled.Value - r.Key.RetgRelJBIS.Value)
                                            +
                                           (r.Key.PrevRetgTaxJBIS.Value - r.Key.PrevRetgTaxRelJBIS.Value) + (r.Key.RetgTaxJBIS.Value - r.Key.RetgTaxRelJBIS.Value),
                            StoredMaterials = r.Key.PrevSM.Value + r.Key.SM.Value,
                            TotalComplToDate = r.Key.AmtBilled.Value + r.Key.PrevAmt.Value,
                            PerctCompleted = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value != 0 ?
                                                (r.Key.AmtBilled.Value + r.Key.PrevAmt.Value / (r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value)) * 100
                                                : 0,
                            InvTotal = r.Key.InvTotal.Value,
                            AmtBilled = r.Key.AmtBilled.Value,
                            PrevAmt = r.Key.PrevAmt.Value,
                            PrevAmtJBIN = r.Key.PrevAmtJBIN.Value,
                            PrevRetgJBIN = r.Key.PrevRetgJBIN.Value,
                            PrevRRel = r.Key.PrevRRel.Value,
                            InvRetg = r.Key.InvRetg.Value,
                            RetgRelJBIN = r.Key.RetgRelJBIN.Value,
                            PrevRetgTaxJBIN = r.Key.PrevRetgTaxJBIN.Value,
                            PrevRetgTaxRelJBIN = r.Key.PrevRetgTaxRelJBIN.Value,
                            RetgTaxJBIN = r.Key.RetgTaxJBIN.Value,
                            RetgTaxRelJBIN = r.Key.RetgTaxRelJBIN.Value,
                            RetgRelJBIS = r.Key.RetgRelJBIS.Value,
                            PrevDue = r.Key.PrevDue.Value,
                            InvDue = r.Key.InvDue.Value,
                            TaxAmtJBIT = r.Key.TaxAmtJBIT.Value
                            //InvTax = r.Key.InvTax.Value + r.Key.PrevTax.Value
                        });

                        grpDetailByItem = grpInvoices.GroupBy(r => r.ItemJCCI);

                        // allocate detail rows array to write to Excel in 1 atomic operation
                        detailCnt = grpDetailByItem.Count();               // detail row count
                        object[,] rows = new object[detailCnt, colCnt];    // to store detail row data
                        detailStartRow = detailFrom + detailCnt - 1;            // top header rows + detail row count
                        detailLastRow = detailStartRow + 1;

                        #region GET LINE ITEM VALUES

                        int arrRow = 0;
                        int xlRow = detailFrom;
                        foreach (var grpDetail in grpDetailByItem)
                        {
                            // create detail row array
                            object[] fields = { grpDetail.Max(n => n.ItemJCCI)
                                                    , grpDetail.Max(n => n.DescriptionJBIS)
                                                    , grpDetail.Sum(n => n.CurrContractAmt)
                                                    , grpDetail.Sum(n => n.ChgOrderAmt)
                                                    , "=C" + xlRow + "-I" + xlRow                                      //grpDetail.Sum(n => n.BalanceToFinish)
                                                    , grpDetail.Sum(n => n.CurrRetention)
                                                    , grpDetail.Sum(n => n.JTDRetention)
                                                    , grpDetail.Sum(n => n.StoredMaterials)
                                                    , grpDetail.Sum(n => n.TotalComplToDate)
                                                    , "=IF(C" + xlRow + " > 0, +I" + xlRow + " / C" + xlRow + ", 0)"    // perctComplete
                                                    , grpDetail.Sum(n => n.PrevAmt)
                                                    , grpDetail.Sum(n => n.AmtBilled)
                                                  };

                            // fill detail row array
                            for (int col = 0; col < colCnt; col++)
                            {
                                rows[arrRow, col] = fields[col];
                            }
                            ++arrRow; // point to next row
                            ++xlRow;
                        }

                        #endregion

                        #region MIDDLE: DETAIL FORMAT

                        // format rows
                        rng = ws.get_Range("A" + detailFrom);
                        rng2 = ws.Cells[detailLastRow, colCnt];
                        rng = ws.get_Range(rng, rng2);
                        rng.Font.Size = 8.5;
                        rng.Font.Name = "Arial Narrow";
                        rng.NumberFormat = HelperUI.Number;
                        ws.get_Range("J" + detailLastRow).NumberFormat = HelperUI.PercentFormat;

                        // enable filtering
                        rng = ws.get_Range("A" + (detailFrom - 1));
                        rng2 = ws.Cells[detailStartRow, colCnt];
                        rng = ws.get_Range(rng, rng2);
                        rng.AutoFilter(2, Type.Missing);

                        // format Item column as text BEFORE putting values in
                        rng = ws.Cells[(detailFrom), 1];
                        rng2 = ws.Cells[detailStartRow, 2];
                        rngItems = ws.get_Range(rng, rng2);
                        rngItems.NumberFormat = "@";

                        // percent completed
                        rng = ws.Cells[(detailFrom), 10];
                        rng2 = ws.Cells[detailStartRow, 10];
                        rng = ws.get_Range(rng, rng2);
                        rng.NumberFormat = HelperUI.PercentFormat;

                        // get item list
                        rngItems = ws.get_Range("A" + detailFrom + ":A" + (detailLastRow - 1));
                        rngItems.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

                        //foreach (Excel.Range cel in rngItems)
                        //{
                        //    int itemm = 0;
                        //    int.TryParse(cel.Formula, out itemm);
                        //    rngItems.HorizontalAlignment = itemm != 0 ? Excel.XlHAlign.xlHAlignCenter : Excel.XlHAlign.xlHAlignLeft;
                        //}

                        #endregion

                        #region ADD DETAIL SUBTOTAL

                        if (detailCnt > 0)
                        {
                            rng = ws.get_Range("C" + detailLastRow);
                            rng2 = ws.Cells[detailLastRow, colCnt];
                            rng = ws.get_Range(rng, rng2);
                            rng.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                            rng.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;

                            foreach (Excel.Range c in rng)
                            {
                                rng = ws.Cells[detailFrom, c.Column];
                                rng2 = ws.Cells[detailStartRow, c.Column];
                                rng = ws.get_Range(rng, rng2);
                                c.Formula = "=SUBTOTAL(109," + rng.Address + ")";
                            }

                            // % Complete formula
                            rng = ws.Cells[detailLastRow, perctComplete];
                            rng.NumberFormat = HelperUI.PercentFormat;
                            rngSubtotalBilledToDate = ws.Cells[detailLastRow, totalComplStoredToDateCol];
                            rngCurrContractAmt = ws.Cells[detailLastRow, currContractAmtCol];
                            rng.Formula = "=IF(" + rngCurrContractAmt.Address + " <> 0, " + rngSubtotalBilledToDate.Address + " / " + rngCurrContractAmt.Address + ", 0)";
                        }

                        #endregion

                        #region WRITE LINE ITEMS TO EXCEL

                        // set item line detail rows
                        rng = ws.get_Range("A" + detailFrom);
                        rng2 = ws.Cells[(detailFrom + detailCnt - 1), colCnt];
                        rng = ws.get_Range(rng, rng2);
                        rng.set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, rows);

                        #endregion
                    }

                    #region FOOTER & TOTALS

                    // used for setting footer and totals
                    List<int> pgInsertFooterRows = new List<int>();
                    int pgBreakCnt = ws.HPageBreaks.Count;
                    int pgCnt = pgBreakCnt + 1;
                    bool pgBleed = false;
                    int totalsRowCnt = 5;
                    int pgBreakRow;
                    decimal itemCnt = Convert.ToDecimal(detailCnt) + pgCnt + 1; // consider footer rows
                    decimal thresholdBeforeTotalsBleeed; // to new page 
                    int lastFooterRow = 0;
                    int rowCntPerPgBreak = 35; // after 1st page
                    int lastItemRow = ws.Cells.SpecialCells(Excel.XlCellType.xlCellTypeLastCell, Type.Missing).Row + 1;
                    int footerRow = 39; // single page footer row
                                        //depending how much cell contents push down, adjust footer row
                    if (notesLineBreakCnt == 1)
                    {
                        footerRow -= (notesLineBreakCnt - 2) + 2;
                    }
                    else
                    if (notesLineBreakCnt > 1)
                    {
                        footerRow -= (notesLineBreakCnt - 2) + 1;
                    }

                    if (pgBreakCnt > 0)
                    {
                        rng = ws.get_Range("A" + (ws.HPageBreaks[1].Location.Row - 1));
                        pgBreakRow = rng.Row; // already considers note rows push; calculated by Excel
                        int headerRowCnt = 19;
                        int lastItemPg1 = pgBreakRow - headerRowCnt;

                        // how many pages will fit items after page 1 ?
                        decimal pgsRequiredToFitItems = (itemCnt - lastItemPg1) / pgBreakRow;

                        // what's the percentage row count threshold that will overflow totals to a new page?
                        thresholdBeforeTotalsBleeed = Convert.ToDecimal((pgBreakRow - totalsRowCnt - addTaxLine - 1)) / Convert.ToDecimal(pgBreakRow);

                        // will the last page surpass bleed threshold ?
                        pgBleed = Math.Abs(pgsRequiredToFitItems >= 1 ? pgsRequiredToFitItems - Convert.ToDecimal(pgCnt - 1) : pgsRequiredToFitItems) > thresholdBeforeTotalsBleeed;

                        // save all page break row numbers
                        foreach (Excel.HPageBreak b in ws.HPageBreaks)
                        {
                            pgInsertFooterRows.Add(b.Location.Row - 1);
                        }

                        // last page row count
                        int lastBreakRow = ws.HPageBreaks[ws.HPageBreaks.Count].Location.Row - 1;
                        // rows needed to fill up last page
                        int rowsNeededToFillNextPg = rowCntPerPgBreak - (lastItemRow - lastBreakRow);

                        lastFooterRow = (lastItemRow + rowsNeededToFillNextPg + 1);
                        pgInsertFooterRows.Add(lastFooterRow);
                        ++pgCnt;
                    }
                    else
                    {
                        pgInsertFooterRows.Add(footerRow);

                        // if totals won't fit in 1 pg, insert next page
                        if (footerRow - lastItemRow - 1 < totalsRowCnt + 1)
                        {
                            pgInsertFooterRows.Add(footerRow + rowCntPerPgBreak + 1);
                        }
                    }

                    string footer = "Telephone: 206.832.8799  E-Mail: AccountsReceivable@McKinstry.com  Federal ID:" + inv.FedTaxId.Value + "  Contractor Licenses:http://www.mckinstry.com/licenses  1.5% Interest Charged After Payment Due Date";

                    foreach (var footRow in pgInsertFooterRows)
                    {
                        InsertFooter(ws, colCnt, footer, footRow);
                    }

                    // CALC TOTALS STARTING ROW 
                    // totals are placed offset from footer
                    lastFooterRow = ws.Cells.SpecialCells(Excel.XlCellType.xlCellTypeLastCell, Type.Missing).Row;

                    int totalsStartRow = lastFooterRow - totalsRowCnt - addTaxLine;
                    // account for tax line, if present
                    int totalsLast = totalsStartRow + 3 + addTaxLine;

                    #endregion

                    #region SET SUBTOTAL FORMULAS AT BOTTOM
                    int col1 = colCnt - 2;
                    int col2 = colCnt - 1;

                    // totals bottom
                    rng = ws.Cells[totalsStartRow, colCnt - 2];
                    rng2 = ws.Cells[totalsStartRow + addTaxLine, colCnt];
                    rng = ws.get_Range(rng, rng2);
                    rng = ws.Cells[totalsStartRow, colCnt];
                    rng2 = ws.Cells[totalsLast, colCnt];
                    rng = ws.get_Range(rng, rng2);
                    rng.NumberFormat = HelperUI.Number;
                    rng.Font.Size = 8.5;
                    rng.Font.Name = "Arial Narrow";

                    // Total Billed To Date
                    rng = ws.Cells[totalsStartRow, col1];
                    rng2 = ws.Cells[totalsStartRow, col2];
                    rng = ws.get_Range(rng, rng2);
                    rng.Merge();
                    rng.Formula = "Total Billed To Date:";

                    rngSubtotalBilledToDate = ws.get_Range("I" + detailFrom + ":I" + detailStartRow);
                    rngBilledToDate = ws.Cells[totalsStartRow, colCnt];
                    rngBilledToDate.Formula = "=SUBTOTAL(109," + rngSubtotalBilledToDate.Address + ")"; // 109 = don't include filtered out lines

                    if (detailCnt > 1)
                    {
                        // UPDATE DETAIL: % Complete formula
                        rng = ws.Cells[detailFrom, currContractAmtCol];
                        rng2 = ws.Cells[detailStartRow, currContractAmtCol];
                        rngCurrContractAmt = ws.get_Range(rng, rng2);

                        rng = ws.Cells[detailLastRow, perctComplete];
                        rng.NumberFormat = HelperUI.PercentFormat;
                        rng.Formula = "=IF(SUBTOTAL(109," + rngCurrContractAmt.Address + ") <> 0, SUBTOTAL(109," + rngSubtotalBilledToDate.Address + ") / SUBTOTAL(109," + rngCurrContractAmt.Address + "))";
                    }

                    ++totalsStartRow;

                    // Total Tax To Date
                    if (tax > 0)
                    {
                        rng = ws.Cells[totalsStartRow, col1];
                        rng2 = ws.Cells[totalsStartRow, col2];
                        rng = ws.get_Range(rng, rng2);
                        rng.Merge();
                        rng.Formula = "Total Tax To Date:";

                        ws.Cells[totalsStartRow, colCnt].Formula = "=SUM(" + inv.InvTax.Value + "," + inv.PrevTax.Value + ")";

                        ++totalsStartRow;
                    }

                    // Less Retainage (Sum of JTD Retention Column)
                    rng = ws.Cells[totalsStartRow, col1];
                    rng2 = ws.Cells[totalsStartRow, col2];
                    rng = ws.get_Range(rng, rng2);
                    rng.Merge();
                    rng.Formula = "Less Retainage:";

                    rngSubtotalLessRetainage = ws.get_Range("G" + detailFrom + ":G" + detailStartRow);
                    rngLessRetainage = ws.Cells[totalsStartRow, colCnt];
                    rngLessRetainage.Formula = "=SUBTOTAL(109," + rngSubtotalLessRetainage.Address + ")";

                    ++totalsStartRow;

                    // Less Previous Application
                    rng = ws.Cells[totalsStartRow, col1];
                    rng2 = ws.Cells[totalsStartRow, col2];
                    rng = ws.get_Range(rng, rng2);
                    rng.Merge();
                    rng.Formula = "Less Previous Application:";

                    rngLessPrevApplication = ws.Cells[totalsStartRow, colCnt];

                    //if (inv.RetgRelJBIN.Value == 0)
                    //{
                    //    // if no retainage to be released, apply formula
                    //    rngPrevBillApplication = ws.get_Range("K" + detailFrom + ":K" + detailStartRow);
                    //    rngCurrRetention = ws.get_Range("F" + detailFrom + ":F" + detailStartRow);
                    //    //ws.Cells[totalsFrom, colCnt].Formula = "=SUBTOTAL(109," + rngPrevApplication.Address + ")";
                    //    rngLessPrevApplication.Formula = "=SUBTOTAL(109," + rngPrevBillApplication.Address + ") - SUBTOTAL(109," + rngSubtotalLessRetainage.Address + ") + SUBTOTAL(109," + rngCurrRetention.Address + ")";
                    //}

                    // Viewpoint calculated amt
                    rngLessPrevApplication.Formula = grpDetailByItem.Max(n => n.Max(i => i.PrevDue));

                    //++totalsFrom;

                    // Total Due This Invoice
                    rng = ws.Cells[totalsLast, col1];
                    rng2 = ws.Cells[totalsLast, colCnt - 1];
                    rng = ws.get_Range(rng, rng2);
                    rng.Merge();
                    rng.Formula = "Total Due This Invoice:";

                    rng = ws.get_Range("K" + detailFrom + ":K" + detailStartRow);
                    rngTotalDue = ws.Cells[totalsLast, colCnt];

                    if (tax > 0)
                    {
                        rngTotalDue.Formula = inv.InvDue.Value; // grpDetailByItem.Max(n => n.Max(i => i.InvDue));
                    }
                    else
                    {
                        rngTotalDue.Formula = "=+" + rngBilledToDate.Address + "-" + rngLessRetainage.Address + "-" + rngLessPrevApplication.Address;
                    }

                    rngTotalDue.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                    rngTotalDue.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;
                    rngTotalDue.Borders[Excel.XlBordersIndex.xlEdgeBottom].LineStyle = Excel.XlLineStyle.xlDouble;
                    rngTotalDue.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThick;

                    // bold Total Due label and $ amt
                    rng = ws.Cells[totalsLast, col1 - 1];
                    rng2 = ws.Cells[totalsLast, colCnt];
                    rngTotalDue = ws.get_Range(rng, rng2);
                    rngTotalDue.Font.Bold = true;

                    // format all totals
                    totalsStartRow = detailFrom + detailCnt + 2;
                    rng = ws.Cells[totalsStartRow, col1];
                    rng2 = ws.Cells[totalsLast, col2];
                    rng = ws.get_Range(rng, rng2);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    rng.Font.Size = 8.5;
                    rng.Font.Name = "Arial Narrow";

                    #endregion

                    //  ITEMS: clear xlNumberAsText error
                    foreach (Excel.Range cell in rngItems)
                    {
                        cell.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;
                    }

                    #region CLONE INVOICE x LINE ITEM COUNT

                    // totals
                    rngTotals = ws.get_Range(ws.get_Range("J" + totalsStartRow), 
                                             ws.get_Range("L" + totalsLast));

                    // destination total rows
                    totalsStartRow = footerRow - totalsRowCnt - addTaxLine - 1;
                    totalsLast = totalsStartRow + 3 + addTaxLine;

                    // footer
                    rngFooter = ws.get_Range("A" + footerRow);
                    int subtotalRow = detailFrom + 1;

                    // CREATE 1ST CLONE TO BASE ALL OTHER CLONES OFF OF
                    ws.Copy(After: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                    wsItem = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                    wsItem.Name = invoice + "-" + 1;

                    // delete detail
                    rng  = wsItem.get_Range("A" + detailFrom);
                    rng2 = wsItem.Cells.SpecialCells(Excel.XlCellType.xlCellTypeLastCell);
                    wsItem.get_Range(rng, rng2).EntireRow.Delete();

                    // find corresponding item to copy
                    var invo = grpDetailByItem.ElementAt(0);
                    string item = invo.Key;
                    rng = rngItems.Find(item, // key = item
                                        Type.Missing,
                                        Excel.XlFindLookIn.xlValues,
                                        Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows,
                                        Excel.XlSearchDirection.xlNext,
                                        false, Type.Missing, Type.Missing
                                        );

                    if (rng == null) continue;
                    rngItem = wsItem.get_Range("A" + detailFrom);

                    // copy item line
                    ws.get_Range("A" + rng.Row).EntireRow.Copy(rngItem);

                    #region ADD DETAIL SUBTOTAL
                    rng  = wsItem.get_Range("C" + detailFrom  + ":L" + detailFrom);
                    rng2 = wsItem.get_Range("C" + subtotalRow + ":L" + subtotalRow);
                    rng2.Font.Size = 8.5;
                    rng2.Font.Name = "Arial Narrow";
                    rng2.NumberFormat = HelperUI.Number;
                    rng2.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                    rng2.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;

                    foreach (Excel.Range c in rng2)
                    {
                        c.Formula = "=SUBTOTAL(109," + wsItem.Cells[detailFrom, c.Column].Address + ")";
                    }
                    // % Complete formula
                    rng = wsItem.get_Range("J" + subtotalRow);
                    rng.NumberFormat = HelperUI.PercentFormat;
                    rng.Formula = "=IF(C" + subtotalRow + " <> 0, I" + subtotalRow + " / C" + subtotalRow + ", 0)";
                    #endregion

                    #region APPEND ITEM TO INVOICE # INSIDE TEXT BOX
                    // get the invoice line inside text box
                    xlTextBox = wsItem.Shapes.Item("txtBoxTopRightHeader");
                    content = xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text;
                    int linebreak = content.IndexOf("Invoice Date:", 0);
                    string invoiceLine = content.Substring(0, linebreak - 1);

                    // append item ref to invoice # inside text box
                    content = content.Replace(invoiceLine, "Invoice:                 " + invoice + "-" + item.Replace(" ", ""));
                    xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text = content;
                    #endregion

                    #region COPY TOTALS
                    rngTotals.Copy(wsItem.get_Range("J" + totalsStartRow));

                    // totals will be placed at unwanted offset location.. move it above footer
                    rng = wsItem.UsedRange.Find("Total Billed To Date:",
                        Type.Missing,
                        Excel.XlFindLookIn.xlValues,
                        Excel.XlLookAt.xlWhole,
                        Excel.XlSearchOrder.xlByRows,
                        Excel.XlSearchDirection.xlNext,
                        false, Type.Missing, Type.Missing
                        );

                    DetailRow invRow = null;

                    // within same worksheet; move totals up
                    if (rng != null)
                    {
                        rng = wsItem.get_Range("J" + rng.Row);
                        rngTotalDue = wsItem.get_Range("L" + (rng.Row + 3 + addTaxLine));
                        rng = wsItem.get_Range(rng, rngTotalDue);

                        HelperUI.AlertOff();
                        rng.Cut(wsItem.get_Range("J" + totalsStartRow));
                        HelperUI.AlertON();

                        invRow = invo.First();

                        rngCurrRetention = wsItem.get_Range("F" + detailFrom);
                        //rngCurrRetention.Formula = "=SUBTOTAL(109," + rngCurrRetention.Address + ")";

                        rngBilledToDate  = wsItem.get_Range("L" + totalsStartRow);
                        rngLessRetainage = wsItem.get_Range("L" + (totalsStartRow + 1 + addTaxLine));
                        rngLessPrevApplication = wsItem.get_Range("L" + (totalsStartRow + 2 + addTaxLine));

                        string TotalDueFormula = "=" + rngBilledToDate.Address;

                        if (tax > 0)
                        {
                            wsItem.get_Range("J" + (rng.Row + addTaxLine)).Formula = "Tax Total:";

                            rngTaxAmt = wsItem.get_Range("L" + (totalsStartRow + addTaxLine));
                            rngTaxAmt.Formula = detailCnt > 1 ? invRow.TaxAmtJBIT: "=SUM(" + inv.InvTax.Value + "," + inv.PrevTax.Value + ")" ;

                            TotalDueFormula += "+" + rngTaxAmt.Address;
                        }

                        TotalDueFormula += "-" + rngLessPrevApplication.Address + "-" + rngCurrRetention.Address;

                        if (invRow.RetgRelJBIN > 0)
                        {
                            rngTotalDue.Formula = invRow.RetgRelJBIS;
                            rngLessPrevApplication.Formula = "=+" + rngBilledToDate.Address + "-" + rngLessRetainage.Address + "-" + rngTotalDue.Address;
                        }
                        else
                        {
                            rngLessPrevApplication.Formula = invRow.PrevAmt;
                            rngTotalDue.Formula = TotalDueFormula;
                        }
                    }

                    #endregion

                    // copy footer
                    rngFooter.EntireRow.Copy(wsItem.get_Range("A" + footerRow));

                    //  clear xlNumberAsText error in line items
                    rngItem.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;

                    colorDefault = wsItem.Tab.Color;

                    // color tab if total due > 0
                    if (rngTotalDue.Value > 0)
                    {
                        wsItem.Tab.Color = System.Drawing.Color.FromArgb(248, 230, 201); // (Excel.XlColorIndex)19; //orange
                    }

                    // MINIMAL CLONE: BASE ALL CLONES OFF OF 1ST CLONE (FOR EFFICIENCY)
                    for (int i = 2; i <= detailCnt; i++)
                    {
                        // CLONE
                        wsItem.Copy(After: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        wsItem = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                        wsItem.Name = invoice + "-" + i;

                        // find corresponding item to copy
                        invo = grpDetailByItem.ElementAt(i - 1);
                        item = invo.Key;
                        rng = rngItems.Find(item, // key = item
                                            Type.Missing,
                                            Excel.XlFindLookIn.xlValues,
                                            Excel.XlLookAt.xlWhole,
                                            Excel.XlSearchOrder.xlByRows,
                                            Excel.XlSearchDirection.xlNext,
                                            false, Type.Missing, Type.Missing
                                            );

                        if (rng == null) continue;
                        rngItem = wsItem.get_Range("A" + detailFrom);

                        // copy item line
                        ws.get_Range("A" + rng.Row).EntireRow.Copy(rngItem);

                        #region APPEND ITEM TO INVOICE # INSIDE TEXT BOX
                        // get the invoice line inside text box
                        xlTextBox = wsItem.Shapes.Item("txtBoxTopRightHeader");
                        content = xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text;
                        linebreak = content.IndexOf("Invoice Date:", 0);
                        invoiceLine = content.Substring(0, linebreak - 1);

                        // append item ref to invoice # inside text box
                        content = content.Replace(invoiceLine, "Invoice:                 " + invoice + "-" + item.Replace(" ", ""));
                        xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text = content;
                        #endregion

                        rng = wsItem.UsedRange.Find("Total Due This Invoice:",
                                               Type.Missing,
                                               Excel.XlFindLookIn.xlValues,
                                               Excel.XlLookAt.xlWhole,
                                               Excel.XlSearchOrder.xlByRows,
                                               Excel.XlSearchDirection.xlNext,
                                               false, Type.Missing, Type.Missing
                                               );

                        if (rng == null) continue;

                        invRow = invo.First();

                        rngCurrRetention    = wsItem.get_Range("F" + detailFrom);
                        rngBilledToDate     = wsItem.get_Range("L" + totalsStartRow);
                        rngLessRetainage    = wsItem.get_Range("L" + (totalsStartRow + 1 + addTaxLine));
                        rngLessPrevApplication = wsItem.get_Range("L" + (totalsStartRow + 2 + addTaxLine));
                        rngTotalDue = wsItem.get_Range("L" + rng.Row);

                        if (tax > 0)
                        {
                            rngTaxAmt = wsItem.get_Range("L" + (totalsStartRow + addTaxLine));
                            rngTaxAmt.Formula = invRow.TaxAmtJBIT;
                        }

                        if (invRow.RetgRelJBIN > 0)
                        {
                            rngTotalDue.Formula = invRow.RetgRelJBIS;
                            rngLessPrevApplication.Formula = "=+" + rngBilledToDate.Address + "-" + rngLessRetainage.Address + "-" + rngTotalDue.Address;
                        }
                        else
                        {
                            rngLessPrevApplication.Formula = invRow.PrevAmt;
                        }

                        //rngTotalDue.Formula = invRow.AmtBilled;

                        //  clear xlNumberAsText error in line items
                        rngItem.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;

                        if (rngTotalDue.Value > 0)
                        {
                            wsItem.Tab.Color = System.Drawing.Color.FromArgb(248, 230, 201);  //orange
                        }
                        else
                        {
                            wsItem.Tab.Color = colorDefault;
                        }
                    }
                    #endregion

                    // 'invoice #-ALL' default landing worksheet 
                    ws = HelperUI.GetSheet(invoice + "-ALL");
                    ((Excel.Workbook)ws.Parent).Activate();
                    ws.Activate();
                }

                success = true;

                HelperUI.GetSheet(invoice + "-ALL").get_Range("A7").Select();
            }
            catch (Exception)
            {
                success = false;
                //Globals.Invoice.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                //Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                throw;
            }
            finally
            {
                Globals.Invoice.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                HelperUI.AlertON();
                HelperUI.RenderON();

                if (success)
                {
                    Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                }
                else if (Globals.ThisWorkbook.Sheets.Count < 3) Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVisible;

                #region CLEAN UP
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (rng2 != null) Marshal.ReleaseComObject(rng2);
                if (rngSubtotalBilledToDate != null) Marshal.ReleaseComObject(rngSubtotalBilledToDate);
                if (rngSubtotalLessRetainage != null) Marshal.ReleaseComObject(rngSubtotalLessRetainage);
                if (rngPrevBillApplication != null) Marshal.ReleaseComObject(rngPrevBillApplication);
                if (rngTotalDue != null) Marshal.ReleaseComObject(rngTotalDue);
                if (rngItems != null) Marshal.ReleaseComObject(rngItems);
                if (xlTextBox != null) Marshal.ReleaseComObject(xlTextBox);
                if (xlTable != null) Marshal.ReleaseComObject(xlTable);
                if (ws != null) Marshal.ReleaseComObject(ws);
                if (rngFooter != null) Marshal.ReleaseComObject(rngFooter);;
                if (rngTotals != null) Marshal.ReleaseComObject(rngTotals);
                if (rngCurrRetention != null) Marshal.ReleaseComObject(rngCurrRetention);
                if (rngTaxAmt != null) Marshal.ReleaseComObject(rngTaxAmt);
                #endregion

            }
            return success;
        }

        private static void InsertFooter(Excel.Worksheet ws, int colCnt, string footer, int footerRow)
        {
            Excel.Range rng = null;
            Excel.Range rng2 = null;

            try
            {
                rng = ws.get_Range("A" + footerRow);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng = ws.get_Range("A" + footerRow);
                rng.Formula = footer;
                rng.Font.Size = 8.5;
                rng.Font.Name = "Arial Narrow";

                // TELEPHONE:
                int start = 0;
                rng.Characters[start, "Telephone:".Length].Font.Bold = true;

                // E-MAIL:
                start = ((string)rng.Text).IndexOf("E-Mail:", start);
                rng.Characters[start, "E-Mail:".Length].Font.Bold = true;

                // FEDERAL ID:
                start = ((string)rng.Text).IndexOf("Federal ID:", start);
                rng.Characters[start, "E-Mail:".Length].Font.Bold = true;

                // CONTRACTOR LICENSES:
                start = ((string)rng.Text).IndexOf("Contractor Licenses:", start);
                rng.Characters[start, "Contractor Licenses:".Length].Font.Bold = true;

                rng = ws.get_Range("A" + footerRow);
                rng2 = ws.Cells[footerRow, colCnt];
                rng = ws.get_Range(rng, rng2);
                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                rng.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                rng.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;
                HelperUI.AlertOff();
                rng.Merge();
                HelperUI.AlertON();
                ws.Names.Add("Footer" + footerRow, rng);
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (rng2 != null) Marshal.ReleaseComObject(rng2); rng2 = null;
            }
        }
    }
}
