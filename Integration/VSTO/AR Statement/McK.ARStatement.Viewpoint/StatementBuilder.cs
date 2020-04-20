using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using McK.Data.Viewpoint;

namespace McK.ARStatement.Viewpoint
{
    internal static class StatementBuilder
    {
        public static bool ToExcel(List<dynamic> tblStatements, bool withPreview)
        {
            Excel.Worksheet ws = null;
            Excel.Range rng = null;
            Excel.Range rngCurrentBucket = null;
            Excel.Range rngLastPgDetailRowStart = null;
            bool success = false;
            string customerNum = "";
            uint companyNum;
            int detailCnt = 0;
            bool usePg2 = false;
            bool usePg3OrMore = false;
            const int pg1MaxDetailRowCnt = 25; // when 28 rows, "page 2 template" is used, page 1 will fit exactly 28 rows and page 2 will have buckets on page 2 with blank details)
            const int lastPgDetailRowCnt = 29;
            int currentPgDetailRowLimit;      // Excel's row number set below 
            const int pg2ExtraDetailRows = 3;
            const int maxDetailRowsPerPgNoBuckets = lastPgDetailRowCnt + pg2ExtraDetailRows;
            const int numRowsBetweenPagesTilNextDetailLine = 14;
            const int lastPgRowStartOffsetFromHeader = 1;

            HelperUI.RenderOFF();

            try
            {
                if (!tblStatements.Any()) return false;

                int rowAt;
                int invDateCol;
                int invNumCol;
                int jobWOAgrCol;
                int invDescCol;
                int invDueDateCol;
                int invAmtCol;
                int balDueCol;

                var uniqueCustomers = tblStatements.OrderBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer Sort Name"]).Value)
                                                   .GroupBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value)
                                                   .Distinct();

                if (!uniqueCustomers.Any()) return false;

                // create tabs for each statement
                foreach (var _statementDetail in uniqueCustomers)
                {
                    // if Send or Preview has no Y, skip
                    if (!_statementDetail.Where(n =>
                                                    (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                           ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase) 
                                                    ||
                                                    (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                           ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Preview Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))
                                                    .Any()) continue;

                    // make a Key-Value of the table to retrive columns with spaces in the name
                    IDictionary<string, object> statement = (IDictionary<string, object>)_statementDetail.FirstOrDefault();

                    customerNum = ((KeyValuePair<string, object>)statement["Customer No."]).Value.GetType() == typeof(DBNull) ? string.Empty : ((KeyValuePair<string, object>)statement["Customer No."]).Value.ToString();
                    companyNum = ((KeyValuePair<string, object>)statement["ARCo"]).Value.GetType() == typeof(DBNull) ? '\0' : Convert.ToUInt32(((KeyValuePair<string, object>)statement["ARCo"]).Value);

                    ws = HelperUI.GetSheet(customerNum);

                    HelperUI.AlertOff();
                    if (ws != null)
                    {
                        ws.Delete();
                    }
                    HelperUI.AlertON();

                    // check row count without traversing
                    usePg2 = _statementDetail.Skip(pg1MaxDetailRowCnt).Any(); 
                    usePg3OrMore = _statementDetail.Skip((pg1MaxDetailRowCnt + lastPgDetailRowCnt)).Any(); 

                    // create sheet from template 
                    if (!usePg2)
                    {
                        // 1 page template
                        //pg1LastDetailRow = 40;
                        Globals.BaseStatement.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.BaseStatement.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Index);
                        rowAt = Globals.BaseStatement.Names.Item("InvoiceDate").RefersToRange.Row;
                        invDateCol = Globals.BaseStatement.Names.Item("InvoiceDate").RefersToRange.Column;
                        invNumCol = Globals.BaseStatement.Names.Item("Invoice").RefersToRange.Column;
                        jobWOAgrCol = Globals.BaseStatement.Names.Item("JobWOAgr").RefersToRange.Column;
                        invDescCol = Globals.BaseStatement.Names.Item("Description").RefersToRange.Column;
                        invDueDateCol = Globals.BaseStatement.Names.Item("DueDate").RefersToRange.Column;
                        invAmtCol = Globals.BaseStatement.Names.Item("InvoiceAmt").RefersToRange.Column;
                        balDueCol = Globals.BaseStatement.Names.Item("LineBalanceDue").RefersToRange.Column;
                    }
                    else
                    {
                        // 2+ page template (pg 3+ are dynamically created)
                        //pg1LastDetailRow = 43;
                        int maxRowsPerPageAfter1stPg = 0;
                        int pgCnt_Between1stAndLastPg = 0;
                        int pgCnt = 1;

                        detailCnt = _statementDetail.Count();
                        maxRowsPerPageAfter1stPg = detailCnt - pg1MaxDetailRowCnt;

                        if (usePg3OrMore)
                        {
                            // determine how many "in-between" pages will be between 1st page and last page.
                            pgCnt_Between1stAndLastPg = Convert.ToInt32(Math.Round(Convert.ToDecimal(maxRowsPerPageAfter1stPg / maxDetailRowsPerPgNoBuckets), MidpointRounding.AwayFromZero));

                            var remainingRows = maxRowsPerPageAfter1stPg % maxDetailRowsPerPgNoBuckets;

                            // if remaining rows overflow, add 1 extra page
                            pgCnt_Between1stAndLastPg += remainingRows == 0 ? 0 : 1;
                            pgCnt += pgCnt_Between1stAndLastPg; // save page count
                            pgCnt_Between1stAndLastPg--; // remove last page
                        }

                        Globals.BaseStatementPg2.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                        Globals.BaseStatementPg2.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet);
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Index);
                        rowAt = Globals.BaseStatementPg2.Names.Item("InvoiceDate").RefersToRange.Row;
                        invDateCol = Globals.BaseStatementPg2.Names.Item("InvoiceDate").RefersToRange.Column;
                        invNumCol = Globals.BaseStatementPg2.Names.Item("Invoice").RefersToRange.Column;
                        jobWOAgrCol = Globals.BaseStatementPg2.Names.Item("JobWOAgr").RefersToRange.Column;
                        invDescCol = Globals.BaseStatementPg2.Names.Item("Description").RefersToRange.Column;
                        invDueDateCol = Globals.BaseStatementPg2.Names.Item("DueDate").RefersToRange.Column;
                        invAmtCol = Globals.BaseStatementPg2.Names.Item("InvoiceAmt").RefersToRange.Column;
                        balDueCol = Globals.BaseStatementPg2.Names.Item("LineBalanceDue").RefersToRange.Column;

                        rngCurrentBucket = ws.Names.Item("Current").RefersToRange;

                        // Page 3+ Formatting 6.5.19 tfs 4580 LG
                        #region  CLONE PAGE 2 TO MAKE "MIDDLE" PAGE TEMPLATE WITH NO AGING BUCKETS AND 3 EXTRA DETAIL ROWS

                        if (pgCnt_Between1stAndLastPg > 0)
                        {
                            // set page on last page 
                            ws.get_Range("R50").Value = pgCnt;

                            // copy PAGE 2
                            ws.get_Range("A46:T90").EntireRow.Copy(); // EntireRow also copies formatting

                            // insert as MIDDLE PAGE
                            rng = ws.get_Range("A46");
                            rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, rng);

                            //ws.get_Range("A91:A134").EntireRow.AutoFit();

                            #region REPLACE AGING BUCKETS WITH NEW DETAIL ROWS

                            // remove aging buckets
                            ws.get_Range("A86:A87").EntireRow.Delete();

                            // replace aging buckets with 2 blank rows
                            int startFromRow = 82;
                            rng = ws.get_Range("A" + startFromRow + ":A84").EntireRow;
                            rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, rng);

                            for (int i = startFromRow; i <= 84; i++)
                            {
                                ws.get_Range("B" + i + ":C" + i).Merge();
                                ws.get_Range("D" + i + ":E" + i).Merge();
                                ws.get_Range("F" + i + ":G" + i).Merge();
                                ws.get_Range("H" + i + ":N" + i).Merge();
                                ws.get_Range("O" + i + ":P" + i).Merge();
                                ws.get_Range("Q" + i + ":R" + i).Merge();
                                ws.get_Range("S" + i + ":T" + i).Merge();
                            }

                            #endregion

                            // Invoices Through from pg1
                            ws.get_Range("R49").Formula = "=R5";

                            // Page No. 
                            ws.get_Range("R50").Value = pgCnt_Between1stAndLastPg + 1;

                            // set border on last row
                            ws.get_Range("B88:T88").Borders.get_Item(Excel.XlBordersIndex.xlEdgeBottom).LineStyle = Excel.XlLineStyle.xlContinuous;

                            pgCnt_Between1stAndLastPg--;
                        }

                        #endregion

                        #region INSERT ADDITIONAL MIDDLE PAGES

                        for (int i = 1; i <= pgCnt_Between1stAndLastPg; i++)
                        {
                            // copy MIDDLE PAGE (page 2)
                            ws.get_Range("A45:T89").EntireRow.Copy(); // EntireRow also copies formatting

                            // insert NEW MIDDLE PAGE
                            rng = ws.get_Range("A45");
                            rng.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, rng);

                            // point INVOICES THROUGH to PAGE 1
                            ws.get_Range("R49").Formula = "=R5";
                            ws.get_Range("R50").Value = pgCnt_Between1stAndLastPg - i + 2;

                            #region LOGO STUFF
                                //var picLogo = ws.Shapes.Item("Logo");
                                //float width = picLogo.Width;
                                //float height = picLogo.Height;

                                //for (int n = 1; n <= ws.Shapes.Count-1; n++)
                                //{
                                //    ws.Shapes.Item(n).Width = width;
                                //    ws.Shapes.Item(n).Width = height;
                                //}
                            #endregion
                        }

                        #endregion
                    }

                    ws.Name = customerNum;

                    // set last page start detail row
                    rng = ws.Names.Item("Current").RefersToRange.get_End(Excel.XlDirection.xlUp);
                    rng.get_End(Excel.XlDirection.xlUp).Select();

                    rngLastPgDetailRowStart = Globals.ThisWorkbook.Application.ActiveCell.Offset[lastPgRowStartOffsetFromHeader, 0];

                    // current page detail row limit
                    currentPgDetailRowLimit = ws.Names.Item("InvoiceDate").RefersToRange.End[Excel.XlDirection.xlDown].Row - 1;

                    #region GET HEADER VALUES

                    var statementMth = ((KeyValuePair<string, object>)statement["Statement Month"]).Value;
                    statementMth = statementMth.GetType() == typeof(DBNull) ? string.Empty : statementMth.ToString();  // remove time stamp

                    var throughDate = ((KeyValuePair<string, object>)statement["Through Date"]).Value;
                    throughDate = throughDate.GetType() == typeof(DBNull) ? string.Empty : throughDate;
                    
                    //var arco = statementDyn.ARCo.Value.GetType() == typeof(DBNull) ? null : statementDyn.ARCo.Value;

                    var arco = ((KeyValuePair<string, object>)statement["ARCo"]).Value;
                    arco = arco.GetType() == typeof(DBNull) ? string.Empty : arco;

                    var customerName = ((KeyValuePair<string, object>)statement["Customer Name"]).Value;
                    customerName = customerName.GetType() == typeof(DBNull) ? string.Empty : "  " + customerName;

                    //var billToName = ((KeyValuePair<string, object>)statement["Bill To Name"]).Value;
                    //billToName = billToName.GetType() == typeof(DBNull) ? string.Empty : "  " + billToName;

                    var billToAddress = ((KeyValuePair<string, object>)statement["Bill To Address"]).Value;
                    billToAddress = billToAddress.GetType() == typeof(DBNull) ? string.Empty : "  " + billToAddress;

                    var billToAddress2 = ((KeyValuePair<string, object>)statement["Bill To Address2"]).Value;
                    billToAddress2 = (billToAddress2.GetType() == typeof(DBNull) || billToAddress2.ToString().Trim() == string.Empty) ? string.Empty : "  " + billToAddress2;

                    var billToCity = ((KeyValuePair<string, object>)statement["Bill To City"]).Value;
                    billToCity = billToCity.GetType() == typeof(DBNull) ? string.Empty : "  " + billToCity;

                    var billToState = ((KeyValuePair<string, object>)statement["Bill To State"]).Value;
                    billToState = billToState.GetType() == typeof(DBNull) ? string.Empty : billToState;

                    var billToZip = ((KeyValuePair<string, object>)statement["Bill To Zip"]).Value;
                    billToZip = billToZip.GetType() == typeof(DBNull) ? string.Empty : billToZip;

                    ws.Names.Item("CustomerNo").RefersToRange.Value = customerNum;
                    ws.Names.Item("InvoicesThrough").RefersToRange.Value = throughDate;
                    ws.Names.Item("BillToAddress").RefersToRange.Value = customerName +
                                                                         ((string)billToAddress == string.Empty ? "" : "\n" + billToAddress) +
                                                                         ((string)billToAddress2 == string.Empty ? "" : "\n" + billToAddress2) +
                                                                         "\n" + billToCity + ", " + billToState + "  " + billToZip;

                    var arGroupType = ((string)((KeyValuePair<string, object>)statement["AR Customer Group"]).Value)[0];

                    ws.Names.Item("Inquiries_to_AR").RefersToRange.Value = arGroupType == 'C'
                                                                        || arGroupType == 'B'
                                                                        || arGroupType == 'X' ?
                                                                            "Direct Inquiries to " + ActionPane1.corpEmail + " or " + ActionPane1.corpPhone :      // CORP will process
                                                                            "Direct Inquiries to " + ActionPane1.serviceEmail + " or " + ActionPane1.servicePhone;  // SERVICE
                    #endregion

                    #region GET LINE ITEM VALUES

                    if (_statementDetail.Any())
                    {
                        int currRow = rowAt;

                        /* TFS 4138 consolidate detail by invoice and contract */
                        var grpInvoices = tblStatements.Where(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Customer No."]).Value.ToString() == customerNum)
                                                           .OrderBy(n => ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value)
                                                           .GroupBy(n => new
                                                           {
                                                               invDate = ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice Date"]).Value,
                                                               invNum = ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Invoice# / CheckNo"]).Value,
                                                               jobWOAgr = ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract#"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                                           ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract#"]).Value.ToString()
                                                                         + (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["WO#"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                                           ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["WO#"]).Value)
                                                                         + (((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Agreement"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                                           ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Agreement"]).Value),
                                                               invDesc = ((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Contract Description"]).Value,

                                                           })
                                                           .Select(g => new
                                                           {
                                                               invDate = g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Invoice Date"]).Value),
                                                               invNum = g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Invoice# / CheckNo"]).Value),
                                                               jobWOAgr = (string)g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Contract#"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                                                             ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Contract#"]).Value)
                                                                          + (string)g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["WO#"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                                                               ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["WO#"]).Value),
                                                               //+ (string)g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Agreement"]).Value.GetType() == typeof(DBNull) ? string.Empty :
                                                               //                     ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Agreement"]).Value),
                                                               invDesc = g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Contract Description"]).Value),
                                                               invDueDate = g.Max(r => ((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Invoice Due Date"]).Value),
                                                               invAmt = g.Sum(r => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Invoice Amt"]).Value),
                                                               balDue = g.Sum(r => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)r)["Balance Due"]).Value),
                                                           }).ToList();

                        // fill detail row values
                        foreach (dynamic detLine in grpInvoices)
                        {
                            ws.Cells[(currRow), invDateCol].Value   = detLine.invDate;
                            ws.Cells[(currRow), invNumCol].Value    = detLine.invNum;
                            ws.Cells[(currRow), jobWOAgrCol].Value  = detLine.jobWOAgr;
                            ws.Cells[(currRow), invDescCol].Value   = detLine.invDesc;
                            ws.Cells[(currRow), invDueDateCol].Value = detLine.invDueDate;
                            ws.Cells[(currRow), invAmtCol].Value    = detLine.invAmt;
                            ws.Cells[(currRow), balDueCol].Value    = detLine.balDue;

                            ++currRow;

                            if (currRow > currentPgDetailRowLimit)
                            {
                                // set next pg starting detail row
                                currRow = currentPgDetailRowLimit + numRowsBetweenPagesTilNextDetailLine;

                                rng = ws.get_Range("B" + currRow);

                                // have we reached the start of the last page ?
                                if (rngLastPgDetailRowStart.Row == (rng.Row + lastPgRowStartOffsetFromHeader))
                                {
                                    // set last page detail row limit
                                    currentPgDetailRowLimit = currRow + lastPgDetailRowCnt; // includes the aging buckets (2 rows)
                                    currRow += lastPgRowStartOffsetFromHeader;
                                }
                                else
                                {
                                    currentPgDetailRowLimit = currRow + maxDetailRowsPerPgNoBuckets - 1; // -1 to not include start row
                                }
                            }
                        }
                    }

                    #endregion

                    #region AGING BUCKETS

                    ws.Names.Item("Current").RefersToRange.Value = _statementDetail.Where(x => (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["Current"]).Value).GetType() != typeof(DBNull))
                                                                                     .Sum(n => (decimal)n.Current.Value);

                    ws.Names.Item("_1_30Days").RefersToRange.Value = _statementDetail.Where(x => (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["1-30 Days"]).Value).GetType() != typeof(DBNull))
                                                                                     .Sum(n => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["1-30 Days"]).Value);

                    ws.Names.Item("_31_60Days").RefersToRange.Value = _statementDetail.Where(x => (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["31-60 Days"]).Value).GetType() != typeof(DBNull))
                                                                                     .Sum(n => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["31-60 Days"]).Value);

                    ws.Names.Item("_61_90Days").RefersToRange.Value = _statementDetail.Where(x => (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["61-90 Days"]).Value).GetType() != typeof(DBNull))
                                                                                     .Sum(n => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["61-90 Days"]).Value);

                    ws.Names.Item("Over90Days").RefersToRange.Value = _statementDetail.Where(x => (((KeyValuePair<string, object>)((IDictionary<string, object>)x)["Over 90 Days"]).Value).GetType() != typeof(DBNull))
                                                                                     .Sum(n => (decimal)((KeyValuePair<string, object>)((IDictionary<string, object>)n)["Over 90 Days"]).Value);
                    #endregion

                    var table = Globals.ThisWorkbook._myActionPane._lstCompanies.Where(n => n.HQCo == companyNum);

                    // FOOTER
                    if (table.Any())
                    {
                        var co = table.FirstOrDefault();

                        int start = co.CompanyName.IndexOf("-") + 1;
                        //int end = co.IndexOf(":"); 
                        int end = co.CompanyName.Length;
                        var companyName = co.CompanyName.Substring(start, end - start);

                        companyName += "\nFEDERAL ID " + co.FedTaxId + "\n1.5% Interest After 30 Days";
                        ws.Names.Item("CompanyInfo").RefersToRange.Value = companyName;

                    }

                    ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;

                    // hide tab if user specified no preview
                    if (!withPreview ||

                        // Y takes precedence to show the statement when N is also specified
                        _statementDetail.Any(a =>
                                    ((((KeyValuePair<string, object>)((IDictionary<string, object>)a)["Preview Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                    ((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)a)["Preview Statement Y/N"]).Value)).Equals("N", StringComparison.OrdinalIgnoreCase))
                                     &&
                       _statementDetail.Any(b =>
                                    ((((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value).GetType() != typeof(DBNull) &&
                                    !(((string)(((KeyValuePair<string, object>)((IDictionary<string, object>)b)["Send Statement Y/N"]).Value)).Equals("Y", StringComparison.OrdinalIgnoreCase))))
                                     ||
                        _statementDetail.All(c =>
                                    (((KeyValuePair<string, object>)((IDictionary<string, object>)c)["Preview Statement Y/N"]).Value).GetType() == typeof(DBNull))
                                    ))
                    {
                        ws.Visible = Excel.XlSheetVisibility.xlSheetHidden;
                    }

                    ws.Tab.Color = System.Drawing.Color.Honeydew;
                    success = true;
                }

            }
            catch (Exception)
            {
                success = false;
                throw;
            }
            finally
            {
                Globals.BaseStatement.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseStatementPg2.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                HelperUI.AlertON();
                HelperUI.RenderON();

                if (success)
                {
                    Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                }

                #region CLEAN UP
                if (ws != null) Marshal.ReleaseComObject(ws);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (rngLastPgDetailRowStart != null) Marshal.ReleaseComObject(rngLastPgDetailRowStart);
                if (rngCurrentBucket != null) Marshal.ReleaseComObject(rngCurrentBucket);
                #endregion

            }
            return success;
        }
    }
}
