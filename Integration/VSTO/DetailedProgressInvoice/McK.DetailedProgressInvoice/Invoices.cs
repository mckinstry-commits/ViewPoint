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
            Excel.Worksheet wsNewSheet = null;
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
            Excel.Range rngInvoiceBody = null;
            Excel.Range rngTotalsAndFooter = null;
            Excel.Range rngTaxAmt = null;
            Excel.Range rngCurrRetention = null;

            Excel.Range rngItemsPg1 = null;
            Excel.ListObject xlTable = null;
            Excel.Shape xlTextBox = null;
            bool success = false;
            Excel.Range rngFooter = null;
            Excel.Range rngItem = null;
            dynamic colorDefault;
            string invoice = "";
            int detailRowStart = 0;      // detail line item starting row
            int detailCnt = 0;
            int detailLastRow = 0;
            int lastCol = 11;            // detail line item column count
            int currContractAmtCol = 3;
            int totalComplStoredToDateCol = 8;
            int perctCompleteCol = 9;
            int notesLineCnt = 0;
            float rowHeight = 15;
            float notesHeight = 0;
            decimal tax = 0;
            string content = "";
            string companyName = "";
            dynamic companyNum;
            decimal bodyFontSize = 8.5m;
            string bodyfontFam = "Arial Narrow";

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


                var uniqueInvoices = table.GroupBy(r => r.InvoiceJBIN.Value).Distinct();
                Unique = Convert.ToUInt32(uniqueInvoices.Count());

                // we only need to get company once; get it from first invoice
                dynamic firstInv = uniqueInvoices.FirstOrDefault().FirstOrDefault();

                companyNum = firstInv.JBCo.Value.GetType() == typeof(DBNull) ? null : firstInv.JBCo.Value;

                var lstCo = Globals.ThisWorkbook._actionPane._lstCompanies.Where(n => n.HQCo == companyNum);

                if (lstCo.Any())
                {
                    var co = lstCo.FirstOrDefault();

                    int start = co.CompanyName.IndexOf("-") + 1;
                    //int end = co.IndexOf(":"); 
                    int end = co.CompanyName.Length;
                    companyName = co.CompanyName.Substring(start, end - start);
                }

                foreach (var _invoice in uniqueInvoices)
                {
                    dynamic inv = _invoice.First();

                    invoice = inv.InvoiceJBIN.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvoiceJBIN.Value.Replace(" ", "");
                    tax = inv.InvTax.Value + inv.PrevTax.Value;
                    int addTaxLine = (tax > 0 ? 1 : 0);

                    #region HEADER

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

                        //ws.Names.Item("CustomerName").RefersToRange.Formula = customerName;
                        //ws.Names.Item("Address1").RefersToRange.Formula = billAddress;

                        //// when address 2, move up city state and zip so there's not a blank cell in betwen
                        //if (billAddress2 == "")
                        //{
                        //    ws.Names.Item("Address2").RefersToRange.Formula = billCity + ", " + billState + ", " + billZip;
                        //}
                        //else
                        //{
                        //    ws.Names.Item("Address2").RefersToRange.Formula = billAddress2;
                        //    ws.Names.Item("CityStateZip").RefersToRange.Formula = billCity + ", " + billState + ", " + billZip;
                        //}

                        #endregion

                        #region MIDDLE LEFT: HEADER: customer reference id & Contract number

                        //int customerNumber = inv.Customer.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Customer.Value;
                        string customerContract = inv.Contract.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Contract.Value;
                        string customerReference = inv.CustomerReference.Value.GetType() == typeof(DBNull) ? string.Empty : inv.CustomerReference.Value;
                        string descriptionJCCM = inv.DescriptionJCCM.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DescriptionJCCM.Value;
                        string invoiceDescription = inv.InvDescription.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvDescription.Value;

                        content = "Contract #:                      " + customerContract + "\n"
                                + "Customer Reference #: " + customerReference + "\n"
                                + "Contract Description:    " + descriptionJCCM + "\n"+
                                   Environment.NewLine
                                + "Invoice Description:      " + invoiceDescription + "\n";

                        xlTextBox = ws.Shapes.Item("txtContract");
                        xlTextBox.TextFrame.Characters(Type.Missing, Type.Missing).Text = content;
                        xlTextBox.TextFrame.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                        string value = "Contract #:"; 

                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length).Font.Bold = true;

                        value = "Customer Reference #:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length+1).Font.Bold = true;

                        value = "Contract Description:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length+1).Font.Bold = true;

                        value = "Invoice Description:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length).Font.Bold = true;

                        #region NOTES

                        StringBuilder notes = new StringBuilder(inv.BillNotes.Value.GetType() == typeof(DBNull) ? string.Empty : inv.BillNotes.Value);

                        content = notes.ToString().Replace("\t", new string(' ', 5));
                        notesLineCnt = content.Count(x => x == '\n');

                        notesHeight = rowHeight * notesLineCnt + rowHeight;

                        #endregion

                        #region comment out 
                        //string value = "";

                        //rng = ws.Names.Item("ContractNo").RefersToRange;
                        //rng.Formula = value = "Contract #: " + customerContract;
                        //rng.Characters[value.IndexOf(":"), value.Length].Font.Bold = false;

                        //rng = ws.Names.Item("Customer_ReferenceNo").RefersToRange;
                        //rng.Formula = value = "Customer Reference #: " + customerReference;
                        //rng.Characters[value.IndexOf(":"), value.Length].Font.Bold = false;

                        //rng = ws.Names.Item("Contract_Description").RefersToRange;
                        //rng.Formula = value = "Contract Description: " + descriptionJCCM;
                        //rng.Characters[value.IndexOf(":"), value.Length].Font.Bold = false;

                        //ws.get_Range("A18").EntireRow.RowHeight = 7.5;

                        //rng = ws.Names.Item("Invoice_Description").RefersToRange;
                        //rng.Formula = value = "Invoice Description: " + invoiceDescription;
                        //rng.Characters[value.IndexOf(":"), value.Length].Font.Bold = false;

                        //rng = ws.Names.Item("Notes").RefersToRange;
                        //rng.Formula = value = "Notes: " + content;
                        //rng.Characters[value.IndexOf(":"), value.Length].Font.Bold = false;

                        #endregion

                        #endregion

                        #region TOP RIGHT HEADER (invoice number, date, period, cust ref, due date, pymt terms, etc.)

                        var customer = inv.Customer.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Customer.Value;
                        string invDate = inv.InvDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvDate.Value.ToString().Substring(0, inv.InvDate.Value.ToString().IndexOf(" "));  // remove time stamp
                        var application = inv.Application.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Application.Value;
                        string fromDate = inv.FromDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.FromDate.Value.ToString().Substring(0, inv.FromDate.Value.ToString().IndexOf(" ")); // remove time stamp
                        var toDate = inv.ToDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ToDate.Value.ToString().Substring(0, inv.ToDate.Value.ToString().IndexOf(" "));
                        var dueDate = inv.DueDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DueDate.Value.ToString().Substring(0, inv.DueDate.Value.ToString().IndexOf(" "));
                        var descriptionHQPT = inv.DescriptionHQPT.Value.GetType() == typeof(DBNull) ? string.Empty : inv.DescriptionHQPT.Value;

                        //ws.Names.Item("CustomerNo").RefersToRange.Formula = customer;
                        //ws.Names.Item("InvoiceNo").RefersToRange.Formula = invoice;
                        //ws.Names.Item("InvoiceDate").RefersToRange.Formula = invDate;
                        //ws.Names.Item("ApplicationNo").RefersToRange.Formula = application;
                        //ws.Names.Item("PeriodStart").RefersToRange.Formula = fromDate;
                        //ws.Names.Item("PeriodEnd").RefersToRange.Formula = toDate;
                        //ws.Names.Item("Invoice_DueDate").RefersToRange.Formula = dueDate;
                        //ws.Names.Item("Payment_Terms").RefersToRange.Formula = descriptionHQPT;

                        content = "Customer:            " + customer + "\n"
                                + "Invoice:                " + invoice + "\n"
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

                        value = "Customer:";

                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length).Font.Bold = true;

                        value = "Invoice:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Invoice Date:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Application #:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Period Start:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Period End:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Invoice Due Date:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length + 1).Font.Bold = true;

                        value = "Payment Terms:";
                        xlTextBox.TextFrame.Characters(content.IndexOf(value), value.Length).Font.Bold = true;
                        #endregion

                    }

                    #endregion

                    //grpDetailByItem = grpInvoices.GroupBy(r => r.ItemJCCI);
                    IEnumerable<IGrouping<string, DetailRow>> grpDetailByItem = null;

                    int offsetRowStart = 2;

                    detailRowStart = ws.Names.Item("Item").RefersToRange.Row + offsetRowStart; // detail row start

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
                            //r.InvRetg,
                            r.RetgRelJBIN,
                            r.PrevRetgTaxJBIN,
                            r.PrevRetgTaxRelJBIN,
                            r.RetgTaxJBIN,
                            r.RetgTaxRelJBIN,
                            r.PrevDue,
                            r.InvDue,
                            r.PctComplete,
                            r.TaxAmtJBIT
                            //r.InvTax,
                            //r.PrevTax
                            #endregion
                        })
                        .Where(i => i.Key.InvoiceJBIN.Value == invoice) // invoice specific
                        .Select(r => new DetailRow()
                        {
                            InvoiceJBIN = r.Key.InvoiceJBIN.Value,
                            ItemJCCI = r.Key.ItemJCCI.Value != (object)DBNull.Value ? r.Key.ItemJCCI.Value : "",
                            DescriptionJBIS = r.Key.DescriptionJBIS.Value != (object)DBNull.Value ? r.Key.DescriptionJBIS.Value : "",
                            CurrContract = r.Key.CurrContract.Value,
                            CurrContractAmt = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value,
                            ChgOrderAmt = r.Key.ChgOrderAmt.Value,
                            BalanceToFinish = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value - r.Key.PrevAmt.Value - r.Key.AmtBilled.Value,
                            CurrRetention =  r.Key.RetgBilled.Value, //TFS 5036 instead of JBIN.InvRetg (total), use retanaige breakdown (RetgBilled) - LG
                            JTDRetention = (r.Key.PrevRetgJBIS.Value - r.Key.PrevRetgReleased.Value) + (r.Key.RetgBilled.Value - r.Key.RetgRelJBIS.Value)
                                            +
                                           (r.Key.PrevRetgTaxJBIS.Value - r.Key.PrevRetgTaxRelJBIS.Value) + (r.Key.RetgTaxJBIS.Value - r.Key.RetgTaxRelJBIS.Value),
                            StoredMaterials = r.Key.PrevSM.Value + r.Key.SM.Value,
                            TotalComplToDate = r.Key.AmtBilled.Value + r.Key.PrevAmt.Value,
                            //PerctCompleted = r.Key.PctComplete.Value, // chng 9.10.19
                            PerctCompleted = r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value != 0 ?
                                                (r.Key.AmtBilled.Value + r.Key.PrevAmt.Value / (r.Key.CurrContract.Value + r.Key.ChgOrderAmt.Value)) * 100
                                                : 0,
                            InvTotal = r.Key.InvTotal.Value,
                            AmtBilled = r.Key.AmtBilled.Value,
                            PrevAmt = r.Key.PrevAmt.Value,
                            PrevAmtJBIN = r.Key.PrevAmtJBIN.Value,
                            PrevRetgJBIN = r.Key.PrevRetgJBIN.Value,
                            PrevRRel = r.Key.PrevRRel.Value,
                            //InvRetg = r.Key.InvRetg.Value,
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

                        detailCnt = grpDetailByItem.Count(); 

                        if (detailCnt == 0) throw new Exception("Invoices.ToExcel: Invoice " + invoice + " has no detail lines");
                        
                        // allocate detail rows array to write to Excel in 1 atomic operation
                        object[,] rows = new object[detailCnt, lastCol];    // to store detail row data
                        detailLastRow = detailRowStart + detailCnt + 1;  // 1 for the subtotals line

                        #region GET LINE ITEM VALUES

                        int arrRow = 0;
                        int xlRow = detailRowStart;

                        foreach (var grpDetail in grpDetailByItem)
                        {
                            // create detail row array (this is what the user sees in the grid)
                            object[] fields = { grpDetail.Max(n => n.ItemJCCI)
                                                    , grpDetail.Max(n => n.DescriptionJBIS)
                                                    , grpDetail.Sum(n => n.CurrContractAmt) // TFS 5424 reverted to Nov. 2018 logic
                                                    //, grpDetail.Sum(n => n.ChgOrderAmt)
                                                    , "=C" + xlRow + "-H" + xlRow          //grpDetail.Sum(n => n.BalanceToFinish)
                                                    , grpDetail.Sum(n => n.CurrRetention)
                                                    , grpDetail.Sum(n => n.JTDRetention)
                                                    , grpDetail.Sum(n => n.StoredMaterials)
                                                    , grpDetail.Sum(n => n.TotalComplToDate)
                                                    , "=IF(C" + xlRow + " > 0, +H" + xlRow + " / C" + xlRow + ", 0)"    // perctComplete formula
                                                    , grpDetail.Sum(n => n.PrevAmt)
                                                    , grpDetail.Sum(n => n.AmtBilled)
                                                  };

                            // fill detail row array
                            for (int col = 0; col < lastCol; col++)
                            {
                                rows[arrRow, col] = fields[col];
                            }
                            ++arrRow; // point to next row
                            ++xlRow;
                        }

                        #endregion

                        #region MIDDLE: DETAIL FORMAT

                        // detail line: NUMBERS
                        rng = ws.get_Range("C" + detailRowStart);
                        rng2 = ws.Cells[detailLastRow, lastCol];
                        rng = ws.get_Range(rng, rng2);
                        rng.Font.Size = bodyFontSize;
                        rng.Font.Name = bodyfontFam;
                        rng.NumberFormat = HelperUI.Number;

                        // detail line: TEXT 
                        rng = ws.get_Range("A" + detailRowStart);
                        rng2 = ws.get_Range("B" + detailLastRow);
                        rng = ws.get_Range(rng, rng2);
                        rng.Font.Size = bodyFontSize;
                        rng.Font.Name = bodyfontFam;
                        rng.NumberFormat = HelperUI.TextFormat;
                        rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        rng.VerticalAlignment = Excel.XlVAlign.xlVAlignBottom;

                        // detail line: Description align
                        //rng = ws.get_Range("B" + detailRowStart);
                        //rng2 = ws.get_Range("B" + detailLastRow);
                        //rng = ws.get_Range(rng, rng2);
                        //rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        //rng.VerticalAlignment = Excel.XlVAlign.xlVAlignTop;

                        // enable filtering
                        rng = ws.get_Range("A" + (detailRowStart - offsetRowStart));
                        rng2 = ws.Cells[detailRowStart, lastCol];
                        rng = ws.get_Range(rng, rng2);
                        rng.AutoFilter(2, Type.Missing);

                        // percent completed
                        rng = ws.Cells[detailRowStart, perctCompleteCol];
                        rng2 = ws.Cells[detailLastRow, perctCompleteCol];
                        rng = ws.get_Range(rng, rng2);
                        rng.NumberFormat = HelperUI.PercentFormat;

                        // get item list
                        rngItemsPg1 = ws.get_Range("A" + detailRowStart + ":A" + (detailLastRow - 1));

                        //ws.get_Range("B" + detailRowStart + ":B" + (detailLastRow - 1)).WrapText = true;

                        //foreach (Excel.Range cel in rngItems)
                        //{
                        //    int itemm = 0;
                        //    int.TryParse(cel.Formula, out itemm);
                        //    rngItems.HorizontalAlignment = itemm != 0 ? Excel.XlHAlign.xlHAlignCenter : Excel.XlHAlign.xlHAlignLeft;
                        //}

                        #endregion

                        #region ADD DETAIL SUBTOTAL

                        rng = ws.get_Range("C" + (detailLastRow-1));
                        rng2 = ws.Cells[(detailLastRow - 1), lastCol];
                        rng = ws.get_Range(rng, rng2);
                        rng.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                        rng.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;

                        foreach (Excel.Range c in rng)
                        {
                            rng = ws.Cells[detailRowStart, c.Column];
                            rng2 = ws.Cells[(detailLastRow-2), c.Column];
                            rng = ws.get_Range(rng, rng2);
                            c.Formula = "=SUBTOTAL(109," + rng.Address + ")";
                        }

                        // % Complete formula
                        rng = ws.Cells[(detailLastRow - 2), perctCompleteCol];
                        rng.NumberFormat = HelperUI.PercentFormat;
                        rngSubtotalBilledToDate = ws.Cells[(detailLastRow - 1), totalComplStoredToDateCol];
                        rngCurrContractAmt = ws.Cells[(detailLastRow - 1), currContractAmtCol];
                        //rng.Formula = "=IF(" + rngCurrContractAmt.Address + " <> 0, " + rngSubtotalBilledToDate.Address + " / " + rngCurrContractAmt.Address + ", 0)";
                        rng.Formula = "=IF(SUBTOTAL(109," + rngCurrContractAmt.Address + ") <> 0, SUBTOTAL(109," + rngSubtotalBilledToDate.Address + ") / SUBTOTAL(109," + rngCurrContractAmt.Address + "))";

                        #endregion

                        #region WRITE LINE ITEMS TO EXCEL

                        // set item line detail rows
                        rng = ws.get_Range("A" + detailRowStart);
                        rng2 = ws.Cells[(detailRowStart + detailCnt - 1), lastCol];
                        rng = ws.get_Range(rng, rng2);
                        rng.set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, rows);

                        #endregion

                        break;
                    }

                    #region FOOTER & TOTALS

                    // used for setting footer and totals
                    int pgBreakCnt = ws.HPageBreaks.Count;
                    int pgCnt = pgBreakCnt + 1;
                    int detailHeaderRowCnt = 3;
                    const int totalsRowCnt = 6;
                    const float footerRowCnt = 5.25f;
                    var footerRowCount = footerRowCnt % 1 == 0 ? footerRowCnt : (Convert.ToInt32(footerRowCnt)) + 1;
                    int lastFooterRow = 0;
                    int pg1FooterRow = 47; // single page footer row
                    int pg1FooterRowEnd = pg1FooterRow + Convert.ToInt32(footerRowCnt) - 2;
                    int totalsRowStart = 0;
                    int totalsRowEnd = 0;
                    int rowCntPerPgNoTotals = 40; // after 1st page
                    int insertFootAtRow = 0;
                    int insertHeaderAtRow = 0;


                    string direct_inquiries = "Direct Inquiries to ACCOUNTSRECEIVABLE@MCKINSTRY.COM or 206.832.8799";

                    direct_inquiries = direct_inquiries.PadRight(direct_inquiries.Length + 98);

                    if (pgBreakCnt > 0)
                    {
                        bool lastPgBleed = false;
                        int headerRowCnt = detailRowStart - 1;
                        float detailTotalCnt = Convert.ToSingle(detailCnt); // consider footer rows
                        int pg1PageBreak = 0;
                        int pgsTotal = 0;
                        //--rowCntPerPgNoTotals;
                        rowCntPerPgNoTotals = 36;

                        // total pgs needed after pg 1
                        pgsTotal = Convert.ToInt32(detailTotalCnt / rowCntPerPgNoTotals );

                        detailTotalCnt += (pgsTotal * Convert.ToInt32(footerRowCnt)) + (pgsTotal * detailHeaderRowCnt) - detailHeaderRowCnt;

                        #region will last page bleeds? keep just in case need later 12.10.2019 - LEO

                        // last page item percentage count
                        float lastPgPercentageItemCnt = (detailTotalCnt / rowCntPerPgNoTotals) % 1;

                        // will the last page surpass threshold ?
                        lastPgBleed = lastPgPercentageItemCnt > 0;
                        if (lastPgBleed) ++pgsTotal;

                        #endregion

                        // to be ble to retrive all page breaks, otherwise Excel will throw error
                        ws.Application.ActiveWindow.View = pgBreakCnt > 1 ? Excel.XlWindowView.xlPageBreakPreview : Excel.XlWindowView.xlNormalView;

                        // PG 1 FOOTER
                        pg1PageBreak = ws.HPageBreaks[1].Location.Row - 1;
                        insertFootAtRow = (pg1PageBreak + 1) - Convert.ToInt32(footerRowCnt) - 2;

                        InsertFooter(ws, ref lastCol, ref direct_inquiries, ref companyName, inv.FedTaxId.Value, insertFootAtRow);

                        // PG 2 DETAIL HEADER 
                        insertHeaderAtRow = ws.HPageBreaks[1].Location.Row - 1;

                        rng = ws.get_Range("A" + insertHeaderAtRow);
                        rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                        rng = ws.get_Range("A" + (detailRowStart - offsetRowStart));
                        rng.EntireRow.Copy(ws.get_Range("A" + insertHeaderAtRow));

                        pg1PageBreak = ws.HPageBreaks[1].Location.Row - 1;

                        // PG 2 FOOTER
                        insertFootAtRow = (pg1PageBreak * 2) - (Convert.ToInt32(footerRowCnt) * 2) - 1;

                        InsertFooter(ws, ref lastCol, ref direct_inquiries, ref companyName, inv.FedTaxId.Value, insertFootAtRow);

                        // PG 3+: footer/ header
                        for (int pg = 3; pg <= pgsTotal; pg++)
                        {
                            // calculate placement 
                            insertHeaderAtRow = (pg1FooterRow * (pg - 1)) + (Convert.ToInt32(footerRowCount)) + pg;
                            insertFootAtRow = insertHeaderAtRow + rowCntPerPgNoTotals + (Convert.ToInt32(footerRowCnt));

                            // insert footer
                            InsertFooter(ws, ref lastCol, ref direct_inquiries, ref companyName, inv.FedTaxId.Value, insertFootAtRow);

                            // insert detail header
                            rng = ws.get_Range("A" + insertHeaderAtRow);
                            rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                            rng = ws.get_Range("A" + (detailRowStart - offsetRowStart));
                            rng.EntireRow.Copy(ws.get_Range("A" + insertHeaderAtRow));
                        }

                        // return to normal view
                        ws.Application.ActiveWindow.View = Excel.XlWindowView.xlNormalView;
                    }
                    else
                    {
                        insertFootAtRow = pg1FooterRow + 3 - notesLineCnt;

                        InsertFooter(ws, ref lastCol, ref direct_inquiries, ref companyName, inv.FedTaxId.Value, insertFootAtRow);

                        // if pg1 bleeds, insert footer / totals on next page
                        if (detailCnt > 18)
                        {
                            insertHeaderAtRow = insertFootAtRow + (Convert.ToInt32(footerRowCount));

                            // insert detail page header 
                            rng = ws.get_Range("A" + insertHeaderAtRow);
                            rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                            rng = ws.get_Range("A" + (detailRowStart - offsetRowStart));
                            rng.EntireRow.Copy(ws.get_Range("A" + insertHeaderAtRow));

                            // insert footer
                            insertFootAtRow = insertHeaderAtRow + rowCntPerPgNoTotals - notesLineCnt + 2;
                            InsertFooter(ws, ref lastCol, ref direct_inquiries, ref companyName, inv.FedTaxId.Value, insertFootAtRow);
                        }
                    }

                    #endregion

                    // get last detail row 
                    var invoice_ = grpDetailByItem.Last();
                    string item = invoice_.Key;
                    rng = rngItemsPg1.Find(item, // key = item
                                        Type.Missing,
                                        Excel.XlFindLookIn.xlValues,
                                        Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows,
                                        Excel.XlSearchDirection.xlNext,
                                        false, Type.Missing, Type.Missing
                                        );

                    if (rng == null) continue;
                    detailLastRow = rng.Row;

                    // CALC TOTALS PLACEMENT
                    lastFooterRow = insertFootAtRow;
                    totalsRowStart = lastFooterRow - totalsRowCnt - 1;
                    totalsRowEnd = totalsRowStart + 3 + addTaxLine;

                    #region SET SUBTOTAL FORMULAS AT BOTTOM

                    //int col1 = colCnt - 1;
                    int totalsTextCol = lastCol - 1;

                    // totals bottom
                    rng = ws.Cells[totalsRowStart, totalsTextCol];
                    rng2 = ws.Cells[totalsRowEnd, lastCol];
                    rng = ws.get_Range(rng, rng2);
                    rng.Font.Size = bodyFontSize;
                    rng.Font.Name = bodyfontFam;

                    // totals $ amts
                    rng = ws.Cells[totalsRowStart, lastCol];
                    rng2 = ws.Cells[totalsRowEnd, lastCol];
                    rng = ws.get_Range(rng, rng2);
                    rng.NumberFormat = HelperUI.Number;

                    // Total Due label and $ amt
                    rng = ws.Cells[totalsRowEnd, totalsTextCol];
                    rng2 = ws.Cells[totalsRowEnd, lastCol];
                    rngTotalDue = ws.get_Range(rng, rng2);
                    rngTotalDue.Font.Bold = true;

                    // Total Billed To Date
                    rng = ws.Cells[totalsRowStart, totalsTextCol];
                    rng.Formula = "Total Billed To Date:";
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                    rngSubtotalBilledToDate = ws.get_Range("H" + detailRowStart + ":H" + detailLastRow);
                    rngBilledToDate = ws.Cells[totalsRowStart, lastCol];
                    rngBilledToDate.Formula = "=SUBTOTAL(109," + rngSubtotalBilledToDate.Address + ")"; // 109 = don't include filtered out lines

                    // UPDATE DETAIL: % Complete formula
                    rng = ws.Cells[detailRowStart, currContractAmtCol];
                    rng2 = ws.Cells[detailLastRow, currContractAmtCol];
                    rngCurrContractAmt = ws.get_Range(rng, rng2);

                    // set perct complete correctly; by up arrow select or calculated
                    rng = ws.get_Range("I" + insertFootAtRow);
                    rng.Select();
                    rng = ws.Application.Selection.End(Excel.XlDirection.xlUp);
                    if (rng.HasFormula)
                    {
                        detailLastRow = rng.Row; // pg 1 detail bleeds 
                    }
                    else
                    {
                        detailLastRow++; // pg 1 totals bleed w/ no detail
                    }

                    rng = ws.Cells[detailLastRow, perctCompleteCol];
                    rng.NumberFormat = HelperUI.PercentFormat;
                    rng.Formula = "=IF(SUBTOTAL(109," + rngCurrContractAmt.Address + ") <> 0, SUBTOTAL(109," + rngSubtotalBilledToDate.Address + ") / SUBTOTAL(109," + rngCurrContractAmt.Address + "),1)";

                    detailLastRow--;
                    totalsRowStart++;

                    // Total Tax To Date
                    if (tax > 0)
                    {
                        rng = ws.Cells[totalsRowStart, totalsTextCol];
                        rng.Formula = "Total Tax To Date:";

                        ws.Cells[totalsRowStart, lastCol].Formula = "=SUM(" + inv.InvTax.Value + "," + inv.PrevTax.Value + ")";

                        ++totalsRowStart;
                    }

                    // Less Retainage (Sum of JTD Retention Column)
                    rng = ws.Cells[totalsRowStart, totalsTextCol];
                    rng.Formula = "Less Retention:";

                    rngSubtotalLessRetainage = ws.get_Range("F" + detailRowStart + ":F" + detailLastRow);
                    rngLessRetainage = ws.Cells[totalsRowStart, lastCol];
                    rngLessRetainage.Formula = "=SUBTOTAL(109," + rngSubtotalLessRetainage.Address + ")";

                    ++totalsRowStart;

                    // Less Previous Application
                    rng = ws.Cells[totalsRowStart, totalsTextCol];
                    rng.Formula = "Less Previous Application:";

                    rngLessPrevApplication = ws.Cells[totalsRowStart, lastCol];

                    //if (inv.RetgRelJBIN.Value == 0)
                    //{
                    //    // if no retainage to be released, apply formula
                    //    rngPrevBillApplication = ws.get_Range("K" + detailFrom + ":K" + detailFrom);
                    //    rngCurrRetention = ws.get_Range("F" + detailFrom + ":F" + detailFrom);
                    //    //ws.Cells[totalsFrom, colCnt].Formula = "=SUBTOTAL(109," + rngPrevApplication.Address + ")";
                    //    rngLessPrevApplication.Formula = "=SUBTOTAL(109," + rngPrevBillApplication.Address + ") - SUBTOTAL(109," + rngSubtotalLessRetainage.Address + ") + SUBTOTAL(109," + rngCurrRetention.Address + ")";
                    //}

                    // Viewpoint calculated amt
                    rngLessPrevApplication.Formula = grpDetailByItem.Max(n => n.Max(i => i.PrevDue));

                    //++totalsFrom;

                    // Total Due This Invoice
                    rng = ws.Cells[totalsRowEnd, totalsTextCol];
                    rng.Formula = "INVOICE TOTAL:";
                    rng.Font.Bold = true;

                    //rng = ws.get_Range("K" + detailFrom + ":K" + detailFrom);
                    rngTotalDue = ws.Cells[totalsRowEnd, lastCol];

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

                    // format all totals
                    totalsRowStart = lastFooterRow - totalsRowCnt;
                    totalsRowEnd = totalsRowStart + 3 + addTaxLine;
                    rng  = ws.Cells[totalsRowStart, totalsTextCol];
                    rng2 = ws.Cells[totalsRowEnd, totalsTextCol];
                    rng = ws.get_Range(rng, rng2);
                    rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

                    #endregion

                    ws = HelperUI.GetSheet(invoice + "-ALL");

                    //  ITEMS: clear xlNumberAsText error
                    foreach (Excel.Range cell in rngItemsPg1)
                    {
                        cell.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;
                    }

                    // color tab if total due > 0
                    if (rngTotalDue.Value > 0)
                    {
                        ws.Tab.Color = System.Drawing.Color.FromArgb(248, 230, 201); // (Excel.XlColorIndex)19; //orange
                    }

                    //((Excel.Workbook)ws.Parent).Activate();

                    ws.Activate();
                    rngTotalDue.Select();

                    break;

                    #region CREATE 1 SHEET FOR EACH LINE ITEM. NEW SHEETS ARE CLONES OF THE 1ST SHEET.

                    // CREATE 1ST CLONE TO BASE ALL OTHER CLONES OFF OF
                    ws.Copy(After: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                    wsNewSheet = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                    wsNewSheet.Name = invoice + "-" + 1;

                    // delete detail
                    rng  = wsNewSheet.get_Range("A" + detailRowStart);
                    rng2 = wsNewSheet.Cells.SpecialCells(Excel.XlCellType.xlCellTypeLastCell);
                    wsNewSheet.get_Range(rng, rng2).EntireRow.Delete();

                    // find corresponding item to copy
                    var invo = grpDetailByItem.ElementAt(0);

                    item = invo.Key;

                    rng = rngItemsPg1.Find(item, // key = item
                                        Type.Missing,
                                        Excel.XlFindLookIn.xlValues,
                                        Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows,
                                        Excel.XlSearchDirection.xlNext,
                                        false, Type.Missing, Type.Missing
                                        );

                    if (rng == null) continue;

                    rngItem = wsNewSheet.get_Range("A" + detailRowStart);

                    // copy item line
                    ws.get_Range("A" + rng.Row).EntireRow.Copy(rngItem);

                    #region ADD DETAIL SUBTOTAL

                    int subtotalRow = detailRowStart + 1;
                    rng = wsNewSheet.get_Range("C" + detailRowStart  + ":K" + detailRowStart);
                    rng2 = wsNewSheet.get_Range("C" + subtotalRow + ":K" + subtotalRow);
                    rng2.Font.Size = 11;
                    rng2.Font.Name = "Arial";
                    rng2.NumberFormat = HelperUI.Number;
                    rng2.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                    rng2.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;

                    foreach (Excel.Range c in rng2)
                    {
                        c.Formula = "=SUBTOTAL(109," + wsNewSheet.Cells[detailRowStart, c.Column].Address + ")";
                    }

                    // % Complete formula
                    rng = wsNewSheet.get_Range("I" + subtotalRow);
                    rng.NumberFormat = HelperUI.PercentFormat;
                    rng.Formula = "=IF(C" + subtotalRow + " <> 0, H" + subtotalRow + " / C" + subtotalRow + ", 0)";

                    #endregion

                    wsNewSheet.Names.Item("InvoiceNo").RefersToRange.Formula = invoice + "-" + item.Replace(" ", "");


                    #region COPY FOOTER + TOTALS TO CLONED SHEET

                    // Totals + footer 
                    rngInvoiceBody = ws.get_Range(ws.get_Range("A" + totalsRowStart),
                                                  ws.get_Range("K" + (lastFooterRow + Convert.ToInt32(footerRowCnt) + 1)));

                    rngInvoiceBody = ws.get_Range(ws.get_Range("A" + totalsRowStart),
                                                  ws.get_Range("K" + (lastFooterRow + Convert.ToInt32(footerRowCnt) + 1)));

                    rngInvoiceBody.Copy(wsNewSheet.get_Range("A" + totalsRowStart));

                    // totals will be placed at unwanted offset location in the clone sheet.. move it above footer
                    rngBilledToDate = wsNewSheet.UsedRange.Find("Total Billed To Date:",
                        Type.Missing,
                        Excel.XlFindLookIn.xlValues,
                        Excel.XlLookAt.xlWhole,
                        Excel.XlSearchOrder.xlByRows,
                        Excel.XlSearchDirection.xlNext,
                        false, Type.Missing, Type.Missing
                        );

                    DetailRow invRow = null;

                    // within same worksheet; move totals / footer up
                    if (rngBilledToDate != null)
                    {
                        // copy totals + footer 
                        int lastRow = rngBilledToDate.Row + totalsRowCnt + Convert.ToInt32(footerRowCnt) + 1; 

                        rngTotalsAndFooter = wsNewSheet.get_Range("A" + rngBilledToDate.Row + ":K" + lastRow);

                        totalsRowStart = pg1FooterRow - totalsRowCnt - addTaxLine;

                        HelperUI.AlertOff();
                        rngTotalsAndFooter.Cut(wsNewSheet.get_Range("A" + totalsRowStart));
                        HelperUI.AlertON();

                        lastRow = totalsRowStart + totalsRowCnt + Convert.ToInt32(footerRowCnt);

                        wsNewSheet.get_Range("A" + lastRow).EntireRow.RowHeight = 12.75;        // Direct Inquiries, 17 pix 
                        wsNewSheet.get_Range("A" + (lastRow - 1)).EntireRow.RowHeight = 12;     // space, 16 pix 
                        wsNewSheet.get_Range("A" + (lastRow - 2)).EntireRow.RowHeight = 15.75;  // city state zip, 21 pix 
                        wsNewSheet.get_Range("A" + (lastRow - 3)).EntireRow.RowHeight = 15.75;  // PO BOX, 21 pix 
                        wsNewSheet.get_Range("A" + (lastRow - 4)).EntireRow.RowHeight = 15;     // REMIT 20 pix
                        wsNewSheet.get_Range("A" + (lastRow - 5)).EntireRow.RowHeight = 7.50;   // line separator 10 pixels

                        // merge / align footer cells (gets lost after copy)
                        rng = wsNewSheet.get_Range("I" + (lastRow - 3));  // PO BOX, 21 pix 
                        rng2 = wsNewSheet.get_Range("K" + (lastRow - 1)); // space, 16 pix 
                        rng = wsNewSheet.get_Range(rng, rng2);
                        rng.Merge();
                        rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                        invRow = invo.First();

                        totalsRowStart += addTaxLine;

                        // FIX totals' formulas
                        rngCurrRetention = wsNewSheet.get_Range("E" + detailRowStart);

                        // Point formulas to only look at first detail line item
                        rngBilledToDate = wsNewSheet.get_Range("K" + totalsRowStart);
                        rngBilledToDate.Formula = "=H" + detailRowStart;

                        rngLessRetainage = wsNewSheet.get_Range("K" + (totalsRowStart + 1));
                        rngLessRetainage.Formula = "=F" + detailRowStart;

                        rngLessPrevApplication = wsNewSheet.get_Range("K" + (totalsRowStart + 2));

                        string TotalDueFormula = "=" + rngBilledToDate.Address;

                        if (tax > 0)
                        {
                            wsNewSheet.get_Range("J" + (totalsRowStart + addTaxLine)).Formula = "Tax Total:";

                            rngTaxAmt = wsNewSheet.get_Range("K" + totalsRowStart);
                            rngTaxAmt.Formula = detailCnt > 1 ? invRow.TaxAmtJBIT: "=SUM(" + inv.InvTax.Value + "," + inv.PrevTax.Value + ")" ;

                            TotalDueFormula += "+" + rngTaxAmt.Address;
                        }

                        TotalDueFormula += "-" + rngLessPrevApplication.Address + "-" + rngCurrRetention.Address;

                        rngTotalDue = wsNewSheet.get_Range("K" + (totalsRowStart + 3 + addTaxLine));

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

                    //  clear xlNumberAsText error in line items
                    rngItem.Errors.get_Item(Excel.XlErrorChecks.xlNumberAsText).Ignore = true;

                    colorDefault = wsNewSheet.Tab.Color;

                    // color tab if total due > 0
                    if (rngTotalDue.Value > 0)
                    {
                        wsNewSheet.Tab.Color = System.Drawing.Color.FromArgb(248, 230, 201); // (Excel.XlColorIndex)19; //orange
                    }

                    //break;  // for testing

                    //detailCnt = grpDetailByItem.Count();               // detail row count

                    // BASE ALL CLONES OFF OF 1ST MINIMAL CLONE:  (FOR EFFICIENCY)
                    for (int i = 2; i <= detailCnt; i++)
                    {
                        // CLONE
                        wsNewSheet.Copy(After: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        wsNewSheet = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                        wsNewSheet.Name = invoice + "-" + i;

                        // find corresponding item to copy
                        invo = grpDetailByItem.ElementAt(i - 1);
                        item = invo.Key;
                        rng = rngItemsPg1.Find(item, // key = item
                                            Type.Missing,
                                            Excel.XlFindLookIn.xlValues,
                                            Excel.XlLookAt.xlWhole,
                                            Excel.XlSearchOrder.xlByRows,
                                            Excel.XlSearchDirection.xlNext,
                                            false, Type.Missing, Type.Missing
                                            );

                        if (rng == null) continue;

                        rngItem = wsNewSheet.get_Range("A" + detailRowStart);

                        // copy item line
                        ws.get_Range("A" + rng.Row).EntireRow.Copy(rngItem);

                        wsNewSheet.Names.Item("InvoiceNo").RefersToRange.Formula = invoice + "-" + item.Replace(" ", "");

                        rng = wsNewSheet.UsedRange.Find("INVOICE TOTAL:",
                                               Type.Missing,
                                               Excel.XlFindLookIn.xlValues,
                                               Excel.XlLookAt.xlWhole,
                                               Excel.XlSearchOrder.xlByRows,
                                               Excel.XlSearchDirection.xlNext,
                                               false, Type.Missing, Type.Missing
                                               );

                        if (rng == null) continue;

                        invRow = invo.First();

                        rngCurrRetention    = wsNewSheet.get_Range("E" + detailRowStart);
                        rngBilledToDate     = wsNewSheet.get_Range("K" + totalsRowStart);
                        rngLessRetainage    = wsNewSheet.get_Range("K" + (totalsRowStart + 1 + addTaxLine));
                        rngLessPrevApplication = wsNewSheet.get_Range("K" + (totalsRowStart + 2 + addTaxLine));
                        rngTotalDue = wsNewSheet.get_Range("K" + rng.Row);

                        if (tax > 0)
                        {
                            rngTaxAmt = wsNewSheet.get_Range("K" + (totalsRowStart + addTaxLine));
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

                        //orange or default
                        wsNewSheet.Tab.Color = rngTotalDue.Value > 0 ? System.Drawing.Color.FromArgb(248, 230, 201) : colorDefault;  

                    }
                    #endregion

                    // 'invoice #-ALL' default landing worksheet 
                    ws = HelperUI.GetSheet(invoice + "-ALL");

                    ((Excel.Workbook)ws.Parent).Activate();

                    ws.Activate();
                }

                success = true;

                //HelperUI.GetSheet(invoice + "-ALL").Names.Item("Invoice_DueDate").RefersToRange.Activate();
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
                if (rngItemsPg1 != null) Marshal.ReleaseComObject(rngItemsPg1);
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

        private static void InsertFooter(Excel.Worksheet ws, ref int colCnt, ref string footer, ref string companyName, string fedTaxId, int footerRow)
        {
            Excel.Range rng = null;
            Excel.Range rng2 = null;

            try
            {

                rng = ws.get_Range("A" + footerRow);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                // adjust rows' height above footer
                //ws.get_Range("A" + (footerRow - 4)).EntireRow.RowHeight = 16.50;   // line up, 22 pix
                //ws.get_Range("A" + (footerRow - 3)).EntireRow.RowHeight = 16.50;   // line up, 22 pix
                //ws.get_Range("A" + (footerRow - 2)).EntireRow.RowHeight = 15.75;   // line up, 21 pix
                //ws.get_Range("A" + (footerRow - 1)).EntireRow.RowHeight = 15.75;   // line above sep, 21 pix

                // line separator above footer
                rng = ws.get_Range("A" + footerRow);
                rng2 = ws.Cells[footerRow, colCnt];
                rng = ws.get_Range(rng, rng2);
                rng.Borders[Excel.XlBordersIndex.xlEdgeTop].LineStyle = Excel.XlLineStyle.xlContinuous;
                rng.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;
                rng.EntireRow.RowHeight = 7.50;    // line separator 10 pixels

                // REMIT TO: McKinstry Lockbox
                rng = ws.get_Range("A" + (footerRow + 1));
                rng.Formula = "REMIT TO:";
                rng = ws.get_Range("B" + (footerRow + 1));
                rng.Formula = "McKinstry Lockbox";
                rng.EntireRow.RowHeight = 15;    // REMIT 20 pix

                // PO Box 3895
                rng = ws.get_Range("B" + (footerRow + 2));
                rng.Formula = "PO Box 3895";
                rng.EntireRow.RowHeight = 15.75; // PO BOX, 21 pix

                // Seattle, WA 98124
                rng = ws.get_Range("B" + (footerRow + 3));
                rng.Formula = "Seattle, WA 98124";
                rng.EntireRow.RowHeight = 15.75; // city state zip, 21 pix 

                // 1 row space
                ws.get_Range("A" + (footerRow + 4)).EntireRow.RowHeight = 12;    // space below, 16 pix 

                rng  = ws.get_Range("A" + (footerRow + 1));
                rng2 = ws.get_Range("B" + (footerRow + 3));
                rng = ws.get_Range(rng, rng2);
                rng.Font.Size = 12;
                rng.Font.Name = "Arial";
                rng.Font.Bold = true;

                // footer - COMPANY INFO
                rng  = ws.get_Range("I" + (footerRow + 2));
                rng2 = ws.get_Range("K" + (footerRow + 4));
                rng = ws.get_Range(rng, rng2);
                rng.Merge();
                rng.Formula = companyName + "\n" +
                              "Federal ID " + fedTaxId + "\n" +
                              "Contractor Licenses www.mckinstry.com/licenses" + "\n" +
                              "1.5% Interest after 30 days";
                rng.VerticalAlignment = Excel.XlVAlign.xlVAlignTop;
                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                rng.Font.Size = 8;
                rng.Font.Name = "Arial";

                // DIRECT INQUIRIES 
                rng = ws.get_Range("A" + (footerRow + 5));
                rng.Formula = footer;
                rng.Font.Size = 10;
                rng.Font.Name = "Arial";
                rng.Font.Bold = true;
                rng.EntireRow.RowHeight = 12.75; // Direct Inquiries, 17 pix 

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
