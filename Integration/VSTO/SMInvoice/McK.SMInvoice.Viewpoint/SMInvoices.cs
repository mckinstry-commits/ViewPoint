using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using McK.Data.Viewpoint;

namespace McK.SMInvoice.Viewpoint
{
    internal static class SMInvoices
    {
        /// <summary>
        /// Creates an Excel tab with invoice header and detail. Invoice Detail gets called inside
        /// </summary>
        /// <param name="tblInvoices">Invoice header list table</param>
        /// <param name="tblRecipients"></param>
        /// <param name="detailTandM"></param>
        /// <returns>success</returns>
        public static bool ToExcel(List<dynamic> tblInvoices, List<dynamic> tblRecipients, bool? detailTandM)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xlTable = null;
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            Excel.Range rngLineType = null;
            List<dynamic> tbldetail = null;

            bool success = false;
            string invoiceNumber = "";
            string invoiceType = "";
            string agreement = "";
            uint companyNum ;
            dynamic workOrders ="";
            string customerPO = "";
            string payterms = "";
            List<string> WOs;
            dynamic multiDivision = false;

            try
            {
                Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                var uniqueInvoices = tblInvoices.GroupBy(r => r.InvoiceNumber.Value).Distinct();

                foreach (var _invoice in uniqueInvoices)
                {
                    dynamic inv = _invoice.First();

                    invoiceNumber = inv.InvoiceNumber.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvoiceNumber.Value.Replace(" ", "");
                    invoiceType   = inv.InvoiceType.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvoiceType.Value.Replace(" ", "");

                    // Only calc when BaseInvoice changes
                    if (HelperUI.GetSheet(invoiceNumber) == null)
                    {
                        // create sheet from template
                        if (invoiceType == "W")
                        {
                            Globals.BaseInvoice.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.BaseInvoice.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Worksheets.get_Item(ActionPane1.Recipients_TabName));
                            ws = Globals.ThisWorkbook.Worksheets.get_Item(((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Index);

                            workOrders = inv.WorkOrders.Value.GetType() == typeof(DBNull) ? string.Empty : inv.WorkOrders.Value;

                            ws.Names.Item("WorkOrder").RefersToRange.Formula = workOrders;

                            #region DIRECT INQUIRIES TO

                            string email = Email.GetSendFromEmail(tblRecipients, invoiceNumber);
                            email = email == "" ? "Billing@Mckinstry.com" : email;

                            string phone = Phone.GetBillingPhone(tblRecipients, invoiceNumber);
                            phone = phone == "" ? "206-832-8799" : phone;

                            ws.Names.Item("MCKINSTRY_EMAIL_PHONE").RefersToRange.Formula = "DIRECT INQUIRIES TO " + email.ToUpper() + " PHONE " + phone.ToUpper();

                            #endregion
                        }
                        else if (invoiceType == "A")
                        {
                            Globals.BaseAgreement.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                            Globals.BaseAgreement.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Worksheets.get_Item(ActionPane1.Recipients_TabName));
                            ws = Globals.ThisWorkbook.Worksheets.get_Item(((Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet).Index);

                            agreement = inv.Agreement.Value.GetType() == typeof(DBNull) ? string.Empty : inv.Agreement.Value.Replace(" ", "");
                            multiDivision = inv.MultiDivision.Value.GetType() == typeof(DBNull) ? null : inv.MultiDivision.Value;
                            ws.Names.Item("AgreementNumber").RefersToRange.Value = agreement;
                        }

                        ws.Name = invoiceNumber;

                        #region INVOICE HEADER (COMMON FIELDS)

                        var invoiceDate = inv.InvoiceDate.Value.GetType() == typeof(DBNull) ? string.Empty : inv.InvoiceDate.Value.ToString().Substring(0, inv.InvoiceDate.Value.ToString().IndexOf(" "));  // remove time stamp
                        companyNum = inv.SMCo.Value.GetType() == typeof(DBNull) ? '\0' : Convert.ToUInt32(inv.SMCo.Value);
                        customerPO = inv.CustomerPO.Value.GetType() == typeof(DBNull) ? string.Empty : inv.CustomerPO.Value;
                        payterms = inv.PayTerms.Value.GetType() == typeof(DBNull) ? string.Empty : inv.PayTerms.Value;

                        ws.Names.Item("InvoiceNumber").RefersToRange.Value = invoiceNumber;
                        ws.Names.Item("InvoiceDate").RefersToRange.Value = invoiceDate;
                        ws.Names.Item("PayTerms").RefersToRange.Value = payterms;
                        ws.Names.Item("CustomerPO").RefersToRange.Value = customerPO;

                        #region CUSTOMER INFORMATION (COMMON FIELDS)

                        int? customerNumber = inv.BillToCustomer.Value.GetType() == typeof(DBNull) ? null : inv.BillToCustomer.Value;
                        string serviceSiteDescription = inv.ServiceSiteDescription.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ServiceSiteDescription.Value;
                        string serviceSiteAddress = inv.ServiceSiteAddress.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ServiceSiteAddress.Value;
                        string serviceSiteCity = inv.ServiceSiteCity.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ServiceSiteCity.Value;
                        string serviceSiteState = inv.ServiceSiteState.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ServiceSiteState.Value;
                        string serviceSiteZip = inv.ServiceSiteZip.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ServiceSiteZip.Value;

                        //ws.Names.Item("CustomerName").RefersToRange.Value = customerName;
                        //ws.Names.Item("ContractYN").RefersToRange.Value = customerContactYN;
                        ws.Names.Item("CustomerNumber").RefersToRange.Value = customerNumber;
                        ws.Names.Item("ServiceSiteDescription").RefersToRange.Value = serviceSiteDescription;
                        ws.Names.Item("ServiceSiteAddress").RefersToRange.Value = serviceSiteAddress;
                        ws.Names.Item("ServiceSiteCityStateZip").RefersToRange.Value = serviceSiteCity + ", " + serviceSiteState + ", " + serviceSiteZip;

                        #endregion

                        #region BILL TO:

                        var billName = inv.MailingName.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingName.Value;
                        var billAddress1 = inv.MailingAddress1.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingAddress1.Value;
                        var billAddress2 = inv.MailingAddress2.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingAddress2.Value;
                        var billCity = inv.MailingCity.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingCity.Value;
                        var billState = inv.MailingState.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingState.Value;
                        var billZip = inv.MailingPostalCode.Value.GetType() == typeof(DBNull) ? string.Empty : inv.MailingPostalCode.Value;

                        ws.Names.Item("MailingName").RefersToRange.Value = billName;
                        ws.Names.Item("MailingAddress1").RefersToRange.Value = billAddress1;

                        if (billAddress2 != "")
                        {
                            ws.Names.Item("MailingAddress2").RefersToRange.Value = billAddress2;
                            ws.Names.Item("MailingCityStateZip").RefersToRange.Value = billCity + ", " + billState + ", " + billZip;
                        }
                        else
                        {
                            // move up so it doesn't look weird
                            ws.Names.Item("MailingAddress2").RefersToRange.Value = billCity + ", " + billState + ", " + billZip;
                        }

                        #endregion

                        #endregion

                        #region INVOICE DETAIL

                        decimal taxtotal = 0;

                        if (invoiceType == "W")
                        {
                            WOs = new List<string>();

                            // if multiple WO to an invoice, it's a comma-separated list, just grab the first one to get detail below
                            if (workOrders != "")
                            {
                                rng = ws.Names.Item("WorkOrder").RefersToRange;

                                if (((string)workOrders).Contains(","))
                                {
                                    WOs = ((string)workOrders).Split(',').ToList();
                                    rng.AddComment(workOrders);
                                    rng.Interior.Color = HelperUI.YellowLight;
                                }
                                else
                                {
                                    WOs.Add(workOrders);
                                }
                                rng.Value = WOs.First();
                            }

                            int rowAt = ws.Names.Item("WorkCompletedLineTypeDescription").RefersToRange.Row - 1;
                            int typeCol = ws.Names.Item("LineType").RefersToRange.Column;
                            int descCol = ws.Names.Item("WorkCompletedLineTypeDescription").RefersToRange.Column;
                            int rateCol = ws.Names.Item("WorkCompletedPrice").RefersToRange.Column;
                            int qtyCol = ws.Names.Item("WorkCompletedBillQuantity").RefersToRange.Column;
                            int totalPriceCol = ws.Names.Item("TotalPrice").RefersToRange.Column;
                            int lastDetailRow = ws.Names.Item("Subtotal").RefersToRange.Row - 1;

                            // populate detail rows
                            foreach (var wo in WOs)
                            {
                                tbldetail = InvoicePreview.GetInvoiceDetailWO(inv.SMCo.Value, wo, invoiceNumber, detailTandM);

                                if (tbldetail.Count > 0)
                                {
                                    var detail = tbldetail.First();

                                    #region DESCRIPTION OF WORK

                                    string woDesc = detail.WorkOrderDesc.Value.GetType() == typeof(DBNull) ? string.Empty : detail.WorkOrderDesc.Value;

                                    if (woDesc.Trim() != "")
                                    {
                                        ws.Names.Item("ScopeDescAndDetail").RefersToRange.Value = woDesc; 
                                    }
                                    #endregion

                                    var f = tbldetail.Where(n => (n.PriceMethod.Value.GetType() == typeof(DBNull) ? string.Empty : n.PriceMethod.Value) == "F");
                                    dynamic flatPrice = null;

                                    if (f.Skip(0).Any())
                                    {
                                        flatPrice = f.First();
                                    }

                                    foreach (dynamic row in tbldetail)
                                    {
                                        var division = row.Division.Value.GetType() == typeof(DBNull) ? string.Empty : row.Division.Value;
                                        var type = row.Type.Value.GetType() == typeof(DBNull) ? string.Empty : row.Type.Value;
                                        var desc = row.Description.Value.GetType() == typeof(DBNull) ? string.Empty : row.Description.Value;
                                        var qty = row.Qty.Value.GetType() == typeof(DBNull) ? 0 : row.Qty.Value;
                                        var rate = row.Rate.Value.GetType() == typeof(DBNull) ? 0 : row.Rate.Value;
                                        var price = row.Price.Value.GetType() == typeof(DBNull) ? 0 : row.Price.Value;
                                        taxtotal += row.Tax.Value.GetType() == typeof(DBNull) ? 0 : row.Tax.Value;

                                        ++rowAt;

                                        if (flatPrice != null)
                                        {
                                            // Flat Price Detail body: expand named range to fit scope description - TFS 4501
                                            rng = ws.Names.Item("WorkCompletedLineTypeDescription").RefersToRange;
                                            rng.UnMerge();
                                            rng = ws.get_Range("C" + rowAt + ":" + "H" + lastDetailRow);
                                            rng.Merge();
                                            rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                                            rng.Value = flatPrice.Description.Value;
                                            ws.Cells[rowAt, qtyCol].Value = 1;
                                            ws.Cells[rowAt, rateCol].Value = flatPrice.Price.Value;

                                            // TFS 4172 - FIRE ONLY
                                            if (division.Equals("FIRE"))
                                            {
                                                // Add a Drop Down to Select from either Testing & Inspection or Repair Service
                                                rng.Validation.Delete();
                                                rng.Validation.Add(
                                                                    Excel.XlDVType.xlValidateList,
                                                                    Excel.XlDVAlertStyle.xlValidAlertInformation,
                                                                    Excel.XlFormatConditionOperator.xlBetween,
                                                                    "Material Order,Tenant Improvement,Testing & Inspection,Service Repair",
                                                                    Type.Missing);
                                                rng.Validation.IgnoreBlank = true;
                                                rng.Validation.InCellDropdown = true;

                                                // remove 3 rows from detail body
                                                ws.get_Range("A20").EntireRow.Delete();
                                                ws.get_Range("A20").EntireRow.Delete();
                                                ws.get_Range("A20").EntireRow.Delete();

                                                // add 3 rows to Work Performed
                                                ws.get_Range("A18").EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                                                ws.get_Range("A18").EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                                                ws.get_Range("A18").EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

                                                // Work Performed: redefine named range
                                                rng = ws.Names.Item("ScopeDescAndDetail").RefersToRange;
                                                rng.UnMerge();
                                                rng = ws.get_Range("B16:P20");
                                                rng.Merge();
                                                rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

                                                ws.Names.Item("WorkCompletedLineTypeDescription").RefersToRange.Activate();
                                            }

                                            ws.Names.Item("LineType").RefersToRange.Value = type;
                                            ws.Names.Item("ServiceSite").RefersToRange.Value = row.ServiceSite.Value;
                                            //  END - FIRE ONLY

                                            flatPrice = null;
                                            break;
                                        }

                                        if (rowAt <= 32)
                                        {
                                            ws.Cells[rowAt, typeCol].Value = type;
                                            ws.Cells[rowAt, descCol].Value = desc; 
                                            ws.Cells[rowAt, qtyCol].Value = qty;
                                        }
                                        else
                                        {
                                            // TODO: place footer at bottom of page on overflow
                                            rng = ws.get_Range("A33").EntireRow;
                                            ws.get_Range("A" + rowAt).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, rng);
                                            ws.get_Range("C" + rowAt + ":H" + rowAt).Merge();
                                            ws.get_Range("I" + rowAt + ":J" + rowAt).Merge();
                                            ws.get_Range("M" + rowAt + ":P" + rowAt).Merge();
                                            ws.get_Range("M" + rowAt).Formula = "=I" + rowAt + "*" + "K" + rowAt;
                                            ws.Cells[rowAt, typeCol].Value = type;
                                            ws.Cells[rowAt, descCol].Value = desc;
                                            ws.Cells[rowAt, qtyCol].Value = qty;
                                        }

                                        // TFS 4765 T&M "Hide Rate", Do Not Display Price or Quantity
                                        if (type.ToString().Equals("Labor", StringComparison.OrdinalIgnoreCase))
                                        {
                                            ws.Cells[rowAt, rateCol].Value = rate > 0 && qty > 0 ? rate : null;
                                            ws.Cells[rowAt, totalPriceCol].Value = price;
                                        }
                                        else
                                        {
                                            ws.Cells[rowAt, rateCol].Value = rate > 0 && qty > 0 ? rate : price;
                                        }
                                    }
                                    ws.Names.Item("WorkCompletedTaxAmt").RefersToRange.Value = taxtotal;
                                }
                            }
                        }
                        else if (invoiceType == "A")
                        {
                            tbldetail = InvoicePreview.GetAgreementInvoiceDetail(inv.SMCo.Value, agreement, invoiceNumber);

                            if (tbldetail.Count > 0)
                            {

                                //if (!_invoice.Skip(1).Any()) 
                                if (multiDivision == "N")
                                {
                                    // Agreement IS NOT multi-division
                                    var contractValue = inv.ContractValue.Value.GetType() == typeof(DBNull) ? string.Empty : inv.ContractValue.Value;
                                    var previouslyBilled = inv.PreviouslyBilled.Value.GetType() == typeof(DBNull) ? string.Empty : inv.PreviouslyBilled.Value;
                                    ws.Names.Item("ContractValue").RefersToRange.Value = contractValue;
                                    ws.Names.Item("PreviouslyBilled").RefersToRange.Value = previouslyBilled;
                                }
                                else // Agreement is Multi-Division, Remove the Insert Box except PO # - TFS 4003
                                {
                                    rng = ws.Names.Item("Header_Left_Box").RefersToRange;
                                    rng.Clear();
                                    HelperUI.ClearBorderAround(rng);

                                    // get cell above detail box
                                    rng2 = ws.Names.Item("BillingPeriod").RefersToRange;  // row 22
                                    rng2 = ws.get_Range("B" + (rng2.Row - 2));          // move up 2 rows
                                    rng2.EntireRow.AutoFit();

                                    // move CustomerPO above detail box
                                    rng = ws.Names.Item("CustomerPO").RefersToRange;    // row 16
                                    ws.get_Range("B" + rng.Row + ":" + "F" + rng.Row).Cut(rng2);

                                }

                                var detail = tbldetail.First();

                                string period = detail.BillingPeriod.Value.GetType() == typeof(DBNull) ? string.Empty : detail.BillingPeriod.Value;
                                ws.Names.Item("BillingPeriod").RefersToRange.Value = period;

                                var price = detail.BasePrice.Value.GetType() == typeof(DBNull) ? string.Empty : detail.BasePrice.Value;
                                ws.Names.Item("BasePrice").RefersToRange.Value = price;

                                var tax = detail.Tax.Value.GetType() == typeof(DBNull) ? 0 : detail.Tax.Value;
                                ws.Names.Item("TaxAmount").RefersToRange.Value = tax;

                            }
                        }

                        tbldetail = null;

                        #endregion

                        #region FOOTER

                        var table = Globals.ThisWorkbook._myActionPane._tblCompanies.Where(n => n.HQCo == companyNum);

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
                        #endregion

                        // fit to 1 page
                        ws.PageSetup.PrintArea = ws.UsedRange.AddressLocal;
                        ws.PageSetup.Zoom = false;
                        ws.PageSetup.FitToPagesWide = 1;
                        ws.PageSetup.FitToPagesTall = 1;

                        // color tab if total due > 0
                        if (ws.Names.Item("TotalDue").RefersToRange.Value > 0)
                        {
                            ws.Tab.Color = System.Drawing.Color.FromArgb(248, 230, 201); // (Excel.XlColorIndex)19; //orange
                        }
                    }
                }

                success = true;
            }
            catch (Exception)
            {
                success = false;
                if (ws != null)
                {
                    HelperUI.AlertOff();
                    ws.Delete();
                    HelperUI.AlertON();
                }
                throw;
            }
            finally
            {
                Globals.BaseInvoice.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.BaseAgreement.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                HelperUI.AlertON();
                HelperUI.RenderON();

                if (success)
                {
                    Globals.MCK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                }

                #region CLEAN UP
                if (xlTable != null) Marshal.ReleaseComObject(xlTable);
                if (rngLineType != null) Marshal.ReleaseComObject(rngLineType);
                if (rng != null) Marshal.ReleaseComObject(rng);
                if (rng2 != null) Marshal.ReleaseComObject(rng2);
                if (ws != null) Marshal.ReleaseComObject(ws);
                #endregion

            }
            return success;
        }
    }
}
