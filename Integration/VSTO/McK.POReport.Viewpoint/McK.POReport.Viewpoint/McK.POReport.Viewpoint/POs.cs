using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;
using System.Linq;
using System.Text;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

namespace McK.POReport.Viewpoint
{
    internal static class POs
    {
        public static int UniquePOs { get; set; }

        public static bool ToNewExcel(List<dynamic> table)
        {
            Excel.Worksheet ws = null;
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            bool success = false;
        
            try
            {
                Globals.PO.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.TandC.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.TandCEquip.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;

                // clean up previous PO sheets
                Globals.ThisWorkbook.Application.DisplayAlerts = false;
                foreach (Excel.Worksheet _ws in Globals.ThisWorkbook.Sheets)
                {
                    if (    _ws.Name != Globals.McK.Name
                        &&  _ws.Name != Globals.PO.Name 
                        &&  _ws.Name != Globals.TandC.Name
                        &&  _ws.Name != Globals.TandCEquip.Name
                        )
                        _ws.Delete();
                }
                Globals.ThisWorkbook.Application.DisplayAlerts = true;

                var uniquePOs = table.GroupBy(r => r.udMCKPONumber_POHD.Value).Distinct();
                UniquePOs = Convert.ToInt32(uniquePOs.Count());

                // loop POs
                foreach (var _po in uniquePOs)
                {
                    dynamic po = _po.First();
                    string PONumber = po.udMCKPONumber_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.udMCKPONumber_POHD.Value.Replace(" ", "");

                    // create sheet from template / fill headers
                    if (HelperUI.GetSheet(PONumber) == null)
                    {
                        Globals.PO.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);

                        // T & C  (short)
                        Globals.TandC.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                        ws.Names.Item("PO_Header").RefersToRange.Formula = "PO: " + PONumber;
                        ws.Name = Globals.TandC.Name.Substring(0, Globals.TandC.Name.Length - 1); // stripp off the 1 at the end

                        // T & C Equipment  (Long)
                        Globals.TandCEquip.Copy(after: (Excel.Worksheet)Globals.ThisWorkbook.Sheets[Globals.ThisWorkbook.Sheets.Count]);
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count);
                        ws.Names.Item("PO_Header").RefersToRange.Formula = "PO: " + PONumber;
                        ws.Name = Globals.TandCEquip.Name.Substring(0, Globals.TandCEquip.Name.Length - 1);

                        // PO
                        ws = Globals.ThisWorkbook.Worksheets.get_Item(Globals.ThisWorkbook.Sheets.Count-2);
                        ws.Name = PONumber;
                        ws.Activate();

                        SetPOheaderValues(ws, po);
                    }

                    int itemCnt = _po.GroupBy(r => r.POItem_POIT.Value).Count();

                    // loop detail rows
                    foreach (dynamic row in _po)
                    {
                        // Get PO Item
                        short _poItem = row.POItem_POIT.Value.GetType() == typeof(DBNull) ? 0 : row.POItem_POIT.Value;
                        string poItem = _poItem == 0 ? string.Empty : row.POItem_POIT.Value.ToString();

                        SetDetailNames(ws, poItem);

                        SetDetailValues(ws, row, poItem);
                    }

                    if (po.Notes_POHD.Value.GetType() != typeof(DBNull))
                    {
                        #region SHOW ALL CONTENT ON MULTI-LINE NOTES
                        decimal rowHeight = HelperUI.GetRowHeightToFitContent(po.Notes_POHD.Value, charCntVisibleInFirstRow: 82);
                        // ROW HEIGHT CANNOT BE GREATER THAN 409
                        int rowHeightLimit = 409; // 27 rows with 15 pt. row height (default)
                        rowHeight = rowHeight <= rowHeightLimit ? rowHeight : rowHeightLimit;
                        ws.Names.Item("Notes_POHD").RefersToRange.EntireRow.RowHeight = rowHeight;
                        //else // e.g. PO # 18003028
                        //{
                        //    string desc_PMMF_Col = "V";
                        //    while (rowHeight >= 409)
                        //    {
                        //        // insert rows until all text may fit and be visible
                        //        int row = ws.Names.Item("Notes_POHD").RefersToRange.Row;
                        //        ws.get_Range("A" + row).EntireRow.Insert(Excel.XlDirection.xlUp, ws.Names.Item("Notes_POHD").RefersToRange.EntireRow);
                        //       // ws.Names.Add("Notes_POHD" + poItem, ws.get_Range(desc_PMMF_Col + row));

                        //    }
                        //}
                        #endregion
                    }

                    // delete 3 line item template cells
                    rng = ws.Names.Item("POItem_POIT").RefersToRange;
                    rng2 = ws.Names.Item("Phase_POIT").RefersToRange;
                    rng = ws.get_Range(rng, rng2);
                    rng.EntireRow.Delete();

                    // delete baseline names
                    List<string> baselineNames = new List<string> { "Description_POIT", "Job_POIT", "Notes_POIT", "OrigCost_POIT", "Phase_POIT", "POItem_POIT", "SMWorkOrder_POIT", "UM_POIT" };

                    foreach (string name in baselineNames)
                    {
                        ws.Names.Item(name).Delete();
                    }
                }
                success = true;
            }
            catch (Exception)
            {
                success = false;
                throw;
            }
            finally
            {
                Globals.PO.Visible      = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.TandC.Visible   = Excel.XlSheetVisibility.xlSheetVeryHidden;
                Globals.TandCEquip.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                HelperUI.AlertON();
                HelperUI.RenderON();

                if (success)
                {
                    Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
                }
                else if (Globals.ThisWorkbook.Sheets.Count < 5)
                {
                    // leave visible to user
                    Globals.McK.Visible = Excel.XlSheetVisibility.xlSheetVisible;
                }

                #region CLEAN UP
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (rng2 != null) Marshal.ReleaseComObject(rng2); rng2 = null;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                #endregion

            }
            return success;
        }

        public static bool ToExistingExcel(List<dynamic> table, Excel.Worksheet ws)
        {
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            bool success = false;
            bool recreateItems = false;

            try
            {
                var uniquePOs = table.GroupBy(r => r.udMCKPONumber_POHD.Value).Distinct();
                UniquePOs = Convert.ToInt32(uniquePOs.Count());

                // loop POs
                foreach (var _po in uniquePOs)
                {
                    dynamic po = _po.First();

                    string PO = po.udMCKPONumber_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.udMCKPONumber_POHD.Value.Replace(" ", "");

                    SetPOheaderValues(ws, po);

                    // item count in Viewpoint
                    int itemCnt = _po.GroupBy(r => r.POItem_POIT.Value).Count();

                    // item count in  worksheet
                    int wsItemCnt = 0;
                    foreach (Excel.Name n in ws.Names)
                    {
                        wsItemCnt += n.Name.Contains("POItem") ? 1 : 0;
                    }

                    // if item count changed from last time, recreate detail named ranges, else just plug in values
                    recreateItems = itemCnt != wsItemCnt;

                    if (recreateItems)
                    {
                        // delete all line items except Item 1 to be used as baseline for re-inserting all items
                        rng = ws.Names.Item("POItem_POIT" + 2).RefersToRange;
                        rng2 = ws.Names.Item("Phase_POIT" + itemCnt).RefersToRange;
                        rng = ws.get_Range(rng, rng2);
                        rng.EntireRow.Delete();

                        #region Baseline Item 1
                        // prep Item 1 for baseline
                        ws.Names.Item("POItem_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("quantity1").RefersToRange.Formula = "";
                        ws.Names.Item("UM_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("Description_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("Notes_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("OrigCost_POIT1").RefersToRange.Formula = 0;
                        ws.Names.Item("SMWorkOrder_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("Job_POIT1").RefersToRange.Formula = "";
                        ws.Names.Item("Phase_POIT1").RefersToRange.Formula = "";

                        // set Item 1 to mint baseline
                        ws.Names.Item("POItem_POIT1").Name = "POItem_POIT";
                        ws.Names.Item("quantity1").Name = "quantity";
                        ws.Names.Item("UM_POIT1").Name = "UM_POIT";
                        ws.Names.Item("Description_POIT1").Name = "Description_POIT";
                        ws.Names.Item("Notes_POIT1").Name = "Notes_POIT";
                        ws.Names.Item("OrigCost_POIT1").Name = "OrigCost_POIT";
                        ws.Names.Item("SMWorkOrder_POIT1").Name = "SMWorkOrder_POIT";
                        ws.Names.Item("Job_POIT1").Name = "Job_POIT";
                        ws.Names.Item("Phase_POIT1").Name = "Phase_POIT";
                        #endregion
                    }

                    // loop detail rows
                    foreach (dynamic row in _po)
                    {
                        // Get PO Item
                        short _poItem = row.POItem_POIT.Value.GetType() == typeof(DBNull) ? 0 : row.POItem_POIT.Value;
                        string poItem = _poItem == 0 ? string.Empty : row.POItem_POIT.Value.ToString();

                        if (recreateItems)
                        {
                            SetDetailNames(ws, poItem);
                        }

                        SetDetailValues(ws, row, poItem);

                        if (recreateItems)
                        {
                            // delete 3 line item template cells
                            rng = ws.Names.Item("POItem_POIT").RefersToRange;
                            rng2 = ws.Names.Item("Phase_POIT").RefersToRange;
                            rng = ws.get_Range(rng, rng2);
                            rng.EntireRow.Delete();

                            // Left align WO, Job and Phase_POIT 
                            rng = ws.Names.Item("SMWorkOrder_POIT" + 1).RefersToRange;
                            rng2 = ws.Names.Item("Phase_POIT" + itemCnt).RefersToRange;
                            rng = ws.get_Range(rng, rng2);
                            rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        }
                    }

                    if (po.Notes_POHD.Value.GetType() != typeof(DBNull))
                    {
                        #region SHOW ALL CONTENT ON MULTI-LINE NOTES
                        decimal rowHeight = HelperUI.GetRowHeightToFitContent(po.Notes_POHD.Value, charCntVisibleInFirstRow: 82);
                        // ROW HEIGHT CANNOT BE GREATER THAN 409
                        int rowHeightLimit = 409; // 27 rows with 15 pt. row height (default)
                        rowHeight = rowHeight <= rowHeightLimit ? rowHeight : rowHeightLimit;
                        ws.Names.Item("Notes_POHD").RefersToRange.EntireRow.RowHeight = rowHeight;
                        #endregion
                    }

                    //end PO detail, go to next PO
                }

                success = true;
            }
            catch (Exception)
            {
                success = false;
                //throw; // no bubble-up so we can just log failed PO and continue, see caller
            }
            finally
            {
                HelperUI.AlertON();
                HelperUI.RenderON();

                #region CLEAN UP
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (rng2 != null) Marshal.ReleaseComObject(rng2); rng2 = null;
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                #endregion

            }
            return success;
        }

        private static void SetPOheaderValues(Excel.Worksheet ws, dynamic po)
        {
            try
            {
                ws.get_Range("A1").Formula = po.JCCo.Value; // JCCo - used in 'refresh exsiting worksheet'

                string PO = po.udMCKPONumber_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.udMCKPONumber_POHD.Value.Replace(" ", "");
                        ws.get_Range("A1").Formula = po.JCCo.Value; // JCCo - used in 'refresh exsiting worksheet'

                ws.get_Range("udMCKPONumber_POHD", Type.Missing).Formula = PO;

                ws.get_Range("OrderDate_POHD").Formula = po.OrderDate_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.OrderDate_POHD.Value;
                ws.get_Range("Name_APVM").Formula = po.Name_APVM.Value.GetType() == typeof(DBNull) ? string.Empty : po.Name_APVM.Value;
                ws.get_Range("Address_APVM").Formula = po.Address_APVM.Value.GetType() == typeof(DBNull) ? string.Empty : po.Address_APVM.Value;

                string city = po.City_APVM.Value.GetType() == typeof(DBNull) ? string.Empty : po.City_APVM.Value;
                string state = po.State_APVM.Value.GetType() == typeof(DBNull) ? string.Empty : po.State_APVM.Value;
                string zip = po.Zip_APVM.Value.GetType() == typeof(DBNull) ? string.Empty : po.Zip_APVM.Value;
                ws.get_Range("City_State_Zip_APVM").Formula = (city += city != "" ? ", " : "") + state + " " + zip;

                ws.get_Range("Attention_POHD").Formula = po.Attention_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.Attention_POHD.Value;
                ws.get_Range("Vendor_POHD").Formula = po.Vendor_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.Vendor_POHD.Value;
                ws.get_Range("PayTerms_HQPT").Formula = po.PayTerms_HQPT.Value.GetType() == typeof(DBNull) ? string.Empty : po.PayTerms_HQPT.Value;
                ws.get_Range("Description_udFOB").Formula = po.Description_udFOB.Value.GetType() == typeof(DBNull) ? string.Empty : po.Description_udFOB.Value;
                ws.get_Range("Description_udShipMethod").Formula = po.Description_udShipMethod.Value.GetType() == typeof(DBNull) ? string.Empty : po.Description_udShipMethod.Value;
                ws.get_Range("ReqDate_POIT").Formula = po.ReqDate_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : po.ReqDate_POIT.Value;
                ws.get_Range("ServiceSite_SMWorkOrder").Formula = po.ServiceSite_SMWorkOrder.Value.GetType() == typeof(DBNull) ? string.Empty : po.ServiceSite_SMWorkOrder.Value;
                ws.get_Range("Description_SMServiceSite").Formula = po.Description_SMServiceSite.Value.GetType() == typeof(DBNull) ? string.Empty : po.Description_SMServiceSite.Value;
                ws.get_Range("Address_POHD").Formula = po.Address_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.Address_POHD.Value;

                city = po.City_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.City_POHD.Value;
                state = po.State_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.State_POHD.Value;
                zip = po.Zip_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.Zip_POHD.Value;
                string country = po.Country_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.Country_POHD.Value;

                ws.get_Range("City_State_Zip_Country_POHD").Formula = (city += city != "" ? ", " : "") + state + " " + zip + " " + country;

                ws.get_Range("ShipIns_POHD").Formula = po.ShipIns_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : po.ShipIns_POHD.Value;

                ws.get_Range("Name_HQCO").Formula = po.Name_HQCO.Value.GetType() == typeof(DBNull) ? string.Empty : po.Name_HQCO.Value;
                ws.get_Range("Address_HQCO").Formula = po.Address_HQCO.Value.GetType() == typeof(DBNull) ? string.Empty : po.Address_HQCO.Value;

                city = po.City_HQCO.Value.GetType() == typeof(DBNull) ? string.Empty : po.City_HQCO.Value;
                state = po.State_HQCO.Value.GetType() == typeof(DBNull) ? string.Empty : po.State_HQCO.Value;
                zip = po.Zip_HQCO.Value.GetType() == typeof(DBNull) ? string.Empty : po.Zip_HQCO.Value;
                ws.get_Range("City_State_Zip_HQCO").Formula = (city += city != "" ? ", " : "") + state + " " + zip;

                // extract phone numbers / emails from ATTN field
                string attn = ws.get_Range("Attention_POHD").Formula;
                attn = attn.Trim();

                if (attn != "")
                {
                    #region EXTRACT / SET PHONE NUMBER 

                    MatchCollection matches = RegEx.GetPhoneNumbers(attn);

                    if (matches.Count > 0)
                    {
                        StringBuilder sb = new StringBuilder();

                        // concat matches
                        foreach (Match match in matches)
                        {
                            sb.Append(sb.Length > 0 ? ";" + match.Value.ToString() : match.Value.ToString());
                            attn = attn.Replace(match.Value.ToString(), ""); // remove match from source
                        }

                        // strip off special characters 
                        string tel = new String(sb.ToString().Where(Char.IsDigit).ToArray());

                        // if prefixed w/ a digit, discard it.
                        ws.get_Range("Phone").Formula = tel.Length == 10 ? tel : tel.Substring(1, tel.Length - 1);
                        ws.get_Range("Attention_POHD").Formula = attn.Trim(); // update w/ removed matches
                        sb.Clear();
                    }
                    #endregion

                    #region EXTRACT / SET EMAIL

                    matches = RegEx.GetEmailAddress(attn);

                    if (matches.Count > 0)
                    {
                        StringBuilder sb = new StringBuilder();

                        // concat matches
                        foreach (Match match in matches)
                        {
                            sb.Append(sb.Length > 0 ? ";" + match.Value.ToString() : match.Value.ToString());
                            attn = attn.Replace(match.Value.ToString(), ""); // remove match from source
                        }

                        ws.get_Range("Email").Formula = sb.ToString().Trim();
                        ws.get_Range("Attention_POHD").Formula = attn.Trim();       // update w/ removed matches
                        sb.Clear();
                    }
                    #endregion
                }
            }
            catch (Exception)
            {
                throw;
            }
        }

        private static void SetDetailNames(Excel.Worksheet ws, string poItem)
        {
            Excel.Range rng = null;
            Excel.Range rng2 = null;
            Excel.Range rngA = null;
            Excel.Range rngB = null;
            Excel.Range rngInsertRow = null;
            Excel.Range rngItems = null;

            // detail refs
            int insertAtRow = 41;
            string item_Col = "B";
            string quantity_col = "F";
            string um_Col = "M";
            string origCost_Col = "BN";
            string desc_PMMF_Col = "V";
            string projPhaseCode_Col = "CF";
            string lastCol = "CL";

            try
            {
                // create unique named ranges for each field
                rngInsertRow = ws.get_Range("A" + insertAtRow).EntireRow;

                // Make room for entry
                rngInsertRow.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, Excel.XlInsertFormatOrigin.xlFormatFromLeftOrAbove);
                rngInsertRow.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, Excel.XlInsertFormatOrigin.xlFormatFromLeftOrAbove);
                rngInsertRow.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown, Excel.XlInsertFormatOrigin.xlFormatFromLeftOrAbove);

                // PO Item rows
                ws.Names.Add("POItem_POIT" + poItem, ws.get_Range(item_Col + insertAtRow));
                ws.Names.Add("UM_POIT" + poItem, ws.get_Range(um_Col + insertAtRow));
                ws.Names.Add("Description_POIT" + poItem, ws.get_Range(desc_PMMF_Col + insertAtRow));

                // Cost 
                ws.Names.Add("OrigCost_POIT" + poItem, ws.get_Range(origCost_Col + insertAtRow));

                ws.Names.Add("quantity" + poItem, ws.get_Range(quantity_col + insertAtRow));

                // WO
                ws.Names.Add("SMWorkOrder_POIT" + poItem, ws.get_Range(projPhaseCode_Col + insertAtRow));

                // Notes
                int atRow = (insertAtRow + 1);
                ws.Names.Add("Notes_POIT" + poItem, ws.get_Range(desc_PMMF_Col + (insertAtRow + 1)));

                // Job
                ws.Names.Add("Job_POIT" + poItem, ws.get_Range(projPhaseCode_Col + atRow));

                // Phase_POIT
                atRow = (insertAtRow + 2);
                ws.Names.Add("Phase_POIT" + poItem, ws.get_Range(projPhaseCode_Col + atRow));

                // clone line item format to newly inserted rows via direct copy to source (no clipboard)
                rng = ws.Names.Item("POItem_POIT").RefersToRange;
                rng2 = ws.Names.Item("Phase_POIT").RefersToRange;
                rng = ws.get_Range(rng, rng2);
                rngA = ws.Names.Item("POItem_POIT" + poItem).RefersToRange;
                rngB = ws.Names.Item("Phase_POIT" + poItem).RefersToRange;
                rngItems = ws.get_Range(rngA, rngB);
                rng.Copy(rngItems);

                // SMWorkOrder_POIT
                ws.get_Range(projPhaseCode_Col + insertAtRow, ws.get_Range(lastCol + insertAtRow)).Merge();
                // Job_POIT 
                atRow = (insertAtRow + 1);
                ws.get_Range(projPhaseCode_Col + atRow, ws.get_Range(lastCol + atRow)).Merge();
                // Phase_POIT
                atRow = (insertAtRow + 2);
                ws.get_Range(projPhaseCode_Col + atRow, ws.get_Range(lastCol + atRow)).Merge();

                // Left align WO, Job and Phase_POIT 
                ws.Names.Item("SMWorkOrder_POIT" + poItem).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                ws.Names.Item("Job_POIT" + poItem).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                ws.Names.Item("Phase_POIT" + poItem).RefersToRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                #region CLEAN UP
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
                if (rng2 != null) Marshal.ReleaseComObject(rng2); rng2 = null;
                if (rngA != null) Marshal.ReleaseComObject(rngA); rngA = null;
                if (rngB != null) Marshal.ReleaseComObject(rngB); rngB = null;
                if (rngItems != null) Marshal.ReleaseComObject(rngItems); rngItems = null;
                #endregion
            }

        }

        public static string GetColumnName(int index) // zero-based 
        {
            const byte BASE = 'Z' - 'A' + 1;
            string name = String.Empty;
            do
            {
                name = Convert.ToChar('A' + index % BASE) + name;
                index = index / BASE - 1; } while (index >= 0);
            return name;
        }

        private static void SetDetailValues(Excel.Worksheet ws, dynamic detRow, string poItem)
        {
            if (detRow.Notes_POIT.Value.GetType() != typeof(DBNull))
            {
                #region SHOW ALL CONTENT ON MULTI-LINE NOTES
                decimal rowHeight = HelperUI.GetRowHeightToFitContent(detRow.Notes_POIT.Value, charCntVisibleInFirstRow: 82);
                int rowHeightLimit = 409; // 27 rows with 15 pt. row height (default)
                rowHeight = rowHeight <= rowHeightLimit ? rowHeight : rowHeightLimit; 
                ws.Names.Item("Notes_POIT" + poItem).RefersToRange.EntireRow.RowHeight = rowHeight;
                #endregion
            }

            string val = detRow.Phase_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.Phase_POIT.Value;
            ws.Names.Item("Phase_POIT" + poItem).RefersToRange.Formula = val;

            val = detRow.Notes_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.Notes_POIT.Value;
            ws.Names.Item("Notes_POIT" + poItem).RefersToRange.Formula = val;

            val = detRow.Notes_POHD.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.Notes_POHD.Value;
            ws.Names.Item("Notes_POHD").RefersToRange.Formula = val;

            val = detRow.Job_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.Job_POIT.Value;
            ws.Names.Item("Job_POIT" + poItem).RefersToRange.Formula = val;

            ws.Names.Item("POItem_POIT" + poItem).RefersToRange.Formula = poItem;

            val = detRow.UM_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.UM_POIT.Value;
            ws.Names.Item("UM_POIT" + poItem).RefersToRange.Formula = val;

            val = detRow.Description_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.Description_POIT.Value;
            ws.Names.Item("Description_POIT" + poItem).RefersToRange.Formula = val;

            decimal amount = detRow.OrigCost_POIT.Value.GetType() == typeof(DBNull) ? 0 : detRow.OrigCost_POIT.Value;
            ws.Names.Item("OrigCost_POIT" + poItem).RefersToRange.Formula = amount;

            ws.Names.Item("quantity" + poItem).RefersToRange.Formula = 1;

            val = detRow.SMWorkOrder_POIT.Value.GetType() == typeof(DBNull) ? string.Empty : detRow.SMWorkOrder_POIT.Value.ToString();
            ws.Names.Item("SMWorkOrder_POIT" + poItem).RefersToRange.Formula = val;

            amount = detRow.OrigTax_POIT.Value.GetType() == typeof(DBNull) ? 0 : detRow.OrigTax_POIT.Value;
            ws.Names.Item("OrigTax_POIT").RefersToRange.Value += amount;
        }
    }
}
