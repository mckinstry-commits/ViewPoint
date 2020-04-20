 --//private bool GenerateRevenueProjections2()
 --       //{
 --       //    isRendering = true;
 --       //    bool success = false;


 --       //    if (Globals.Rev.Visible == Excel.XlSheetVisibility.xlSheetVisible)
 --       //    {
 --       //        MessageBox.Show("Only 1 Revenue batch can be open at a time. \n\nPlease post the other batch before attempting to open a Revenue batch for this project.");
 --       //        return false;
 --       //    }

 --       //    if (Login == "")
 --       //    {
 --       //        MessageBox.Show("Unable to validate you as a valid user in Viewpoint.\n" +
 --       //                                         "Make sure Viewpoint is online and check your access.");
 --       //        return false;
 --       //    }

 --       //    Pivot = "MONTH";

 --       //    try
 --       //    {
 --       //        success = ProjectRevenue.GenerateRevenueProjection(JCCo, _Contract, Month, Login, out revBatchId, out revBatchDateCreated);
 --       //        RevBatchId = revBatchId;
 --       //        if (success)
 --       //        {
 --       //            contJectRevenue_table = ConJectBatchSummary.GetConJectBatchSumTable(JCCo, _Contract, Month);
 --       //            RenderOFF();

 --       //            if (contJectRevenue_table.Rows.Count > 0)
 --       //            {
 --       //                string sheetname = "Rev-" + _Contract;

 --       //                if (Globals.Rev.Visible == Excel.XlSheetVisibility.xlSheetVeryHidden)
 --       //                {
 --       //                    Globals.Rev.Visible = Excel.XlSheetVisibility.xlSheetVisible;
 --       //                }

 --       //                Excel.Worksheet _ws = Globals.ThisWorkbook.Sheets[ETCOverviewActionPane.revSheet];
 --       //                _ws.Name = sheetname;
 --       //                Globals.Rev.Move(after: (Excel.Worksheet)Globals.ThisWorkbook.Worksheets[lastContractNoDash]);

 --       //                //_ws.EnableCalculation = false;
 --       //                //_ws.Application.EnableEvents = false;

 --       //                Excelo.ListObject listVSTObject = HelperUI.BindDataTableToExcel(Globals.Factory.GetVstoObject(_ws), contJectRevenue_table, "A4", "Rev_Projection");

 --       //                HelperUI.FormatAsVSTOtable(listVSTObject);

 --       //                _ws.Activate();

 --       //                SetupRevTab2(_ws);

 --       //                //_ws.EnableCalculation = true;
 --       //                //_ws.Application.EnableEvents = true;

 --       //                HelperUI.FormatHoursCost(_ws);
 --       //                DisableGridlines(_ws);
 --       //                HelperUI.FreezePane(_ws, "JC Dept");
 --       //                _ws.get_Range("A1").Activate();
 --       //                btnFetchData.Enabled = true;
 --       //            }
 --       //        }
 --       //    }
 --       //    catch (Exception ex)
 --       //    {
 --       //        RevJectErrOut(ex);
 --       //        return false;
 --       //    }
 --       //    finally
 --       //    {
 --       //        RenderON();
 --       //    }

 --       //    return true;
 --       //}

 --       //private bool GenerateCostProjections()
 --       //{
 --       //    isRendering = true;

 --       //    if (HelperUI.SheetExists(costSumSheet, false))
 --       //    {
 --       //        throw new Exception("Only 1 cost batch can be open at a time. \n\nPlease post the other batch before attempting to open a cost batch for this project.");
 --       //    }

 --       //    if (Login == "") throw new Exception("Unable to validate you as a valid user in Viewpoint.\nMake sure Viewpoint is online and check your access.");

 --       //    Excel.Worksheet _wsSum = null;
 --       //    Excel.Worksheet _wsNonLabor = null;
 --       //    Excel.Worksheet _wsLabor = null;
 --       //    Excel.Range rngHeaders = null;
 --       //    Excel.Range rngTotals = null;
 --       //    Excel.Range rngTopLeft = null;
 --       //    Excel.Range rngBottomRight = null;
 --       //    Excel.ListObject table = null;
 --       //    Excel.ListColumn column = null;
 --       //    Excel.Range cellStart = null;
 --       //    Excel.Range cellEnd = null;
 --       //    Excel.Range grpMonths = null;
 --       //    string colBeforeEntry = "";

 --       //    try
 --       //    {
 --       //        Pivot = "MONTH";
 --       //        bool success = false;
 --       //        string newSheetName = "";
 --       //        Job = cboJobs.Text;

 --       //        //Stopwatch t2 = new Stopwatch(); t2.Start();
 --       //        success = JobJectCostProj.GenerateCostProjection(JCCo, _Contract, Job, Month, Login, out costBatchId, out costBatchDateCreated, out newProjection);
 --       //        CostBatchId = costBatchId;
 --       //        //t2.Stop(); MessageBox.Show(string.Format("Time elapsed: {0:hh\\:mm\\:ss\\:ff}", t2.Elapsed));

 --       //        if (success)
 --       //        {

 --       //            // Summary tab
 --       //            contJobJectBatchSum_table = JobJectBatchSummary.GetJobJectBatchSummaryTable(JCCo, Job, Month);
 --       //            RenderOFF();
 --       //            string job = HelperUI.JobTrimDash(Job);

 --       //            if (contJobJectBatchSum_table.Rows.Count > 0)
 --       //            {
 --       //                newSheetName = costSumSheet + job;

 --       //                _wsSum = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

 --       //                SheetBuilderJCPB.BuildTable(_wsSum, contJobJectBatchSum_table);

 --       //                SetupSumTab(_wsSum, newSheetName);

 --       //                // NonLabor tab
 --       //                contJobJectBatchNonLabor_table = JobJectBatchNonLabor.GetJobJectBatchNonLaborTable(JCCo, Job, Pivot);

 --       //                if (contJobJectBatchNonLabor_table.Rows.Count > 0)
 --       //                {
 --       //                    newSheetName = nonLaborSheet + job;
 --       //                    _wsNonLabor = HelperUI.AddSheet(newSheetName, workbook.ActiveSheet);

 --       //                    SheetBuilder.BuildGenericTable(_wsNonLabor, contJobJectBatchNonLabor_table);
 --       //                    Globals.ThisWorkbook.PivotNonLaborRowCount = contJobJectBatchNonLabor_table.Rows.Count;

 --       //                    SetupNonLaborTab(_wsNonLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd, out colBeforeEntry);
 --       //                }

 --       //                // Labor tab
 --       //                LaborPivot = LaborPivotSearch.GetLaborPivot(JCCo, Job);
 --       //                contJobJectBatchLabor_table = JobJectBatchLabor.GetJobJectBatchLaborTable(JCCo, Job, LaborPivot);

 --       //                if (contJobJectBatchLabor_table.Rows.Count > 0)
 --       //                {
 --       //                    newSheetName = laborSheet + job;

 --       //                    _wsLabor = HelperUI.AddSheet(newSheetName, _wsSum);

 --       //                    SheetBuilder.BuildGenericTable(_wsLabor, contJobJectBatchLabor_table);

 --       //                    Globals.ThisWorkbook.PivotLaborRowCount = contJobJectBatchLabor_table.Rows.Count;

 --       //                    SetupLaborTab(_wsSum, _wsNonLabor, _wsLabor, out rngHeaders, out rngTotals, out rngTopLeft, out rngBottomRight, out table, out column, out cellStart, out cellEnd);
 --       //                }

 --       //                SetSumTabFormulas(_wsSum);
 --       //                workbook.Activate();

 --       //                _wsLabor.Activate();
 --       //                _wsLabor.Application.ActiveWindow.DisplayGridlines = false;
 --       //                _wsLabor.Range["A1"].Activate();
 --       //                HelperUI.FreezePane(_wsLabor, "Employee ID");
 --       //                HelperUI.ApplyUsedFilter(_wsLabor, "Used", 1);

 --       //                _wsNonLabor.Activate();
 --       //                _wsNonLabor.Application.ActiveWindow.DisplayGridlines = false;
 --       //                _wsNonLabor.Range["A1"].Activate();
 --       //                HelperUI.FreezePane(_wsNonLabor, "Description");
 --       //                HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[_wsNonLabor.ListObjects[1].HeaderRowRange.Row, periodStartNonLabor].Value);
 --       //                HelperUI.ApplyUsedFilter(_wsNonLabor, "Used");

 --       //                _wsSum.Activate();
 --       //                _wsSum.Application.ActiveWindow.DisplayGridlines = false;
 --       //                _wsSum.Range["A1"].Activate();
 --       //                HelperUI.FreezePane(_wsSum, "Original Hours");
 --       //                HelperUI.ApplyUsedFilter(_wsSum, "Used", 1);
 --       //            }
 --       //            else
 --       //            {
 --       //                MessageBox.Show("Please review your project set up and/or contact Viewpoint Training for assistance.", "Summary", MessageBoxButtons.OK, MessageBoxIcon.Information);
 --       //                return false;
 --       //            }
 --       //        }
 --       //    }
 --       //    catch (Exception) { throw; } // possible exceptions from the back-end or UI
 --       //    finally
 --       //    {
 --       //        //Globals.ThisWorkbook.EnableSheetChangeEvent(true);
 --       //        //Globals.ThisWorkbook.SheetSelectionChange += new Excel.WorkbookEvents_SheetSelectionChangeEventHandler(Globals.ThisWorkbook.ThisWorkbook_SheetSelectionChange);
 --       //        RenderON();

 --       //        if (_wsLabor != null) { Marshal.ReleaseComObject(_wsLabor); }
 --       //        if (_wsNonLabor != null) { Marshal.ReleaseComObject(_wsNonLabor); }
 --       //        if (rngHeaders != null) Marshal.ReleaseComObject(rngHeaders);
 --       //        if (rngTotals != null) Marshal.ReleaseComObject(rngTotals);
 --       //        if (rngTopLeft != null) Marshal.ReleaseComObject(rngTopLeft);
 --       //        if (rngBottomRight != null) Marshal.ReleaseComObject(rngBottomRight);
 --       //        if (table != null) Marshal.ReleaseComObject(table);
 --       //        if (column != null) Marshal.ReleaseComObject(column);
 --       //        if (cellStart != null) Marshal.ReleaseComObject(cellStart);
 --       //        if (cellEnd != null) Marshal.ReleaseComObject(cellEnd);
 --       //        if (grpMonths != null) Marshal.ReleaseComObject(grpMonths);
 --       //        if (_wsSum != null) Marshal.ReleaseComObject(_wsSum);
 --       //        if (_wsNonLabor != null) Marshal.ReleaseComObject(_wsNonLabor);
 --       //    }
 --       //    return true;
 --       //}
 
 
 --//private void SetupSumTab(Excel.Worksheet _ws, string sheetName)
 --       //{
 --       //    Excel.Range batchDateCreated = null;
 --       //    Excel.Range projectedCost = null;
 --       //    Excel.Range projectedMargin = null;
 --       //    Excel.Range useManualETC = null;

 --       //    try
 --       //    {
 --       //        _ws = HelperUI.GetSheet(sheetName, false);
 --       //        _table = _ws.ListObjects[1];
 --       //        _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

 --       //        HelperUI.CreateTitleHeader(_ws, JobGetTitle.GetTitle(JCCo, Job) + " Summary Worksheet");

 --       //        _ws.Cells.Range["A2"].Formula = "Batch Created on: ";
 --       //        _ws.Cells.Range["A2:D2"].Font.Color = HelperUI.McKColor(HelperUI.McKColors.Black);
 --       //        _ws.Cells.Range["D2"].NumberFormat = "d-mmm-yyyy h:mm AM/PM";
 --       //        _ws.Cells.Range["D2"].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        _ws.Cells.Range["D2"].Formula = costBatchDateCreated;
 --       //        _ws.Cells.Range["D2"].AddComment("All times Pacific");
 --       //        batchDateCreated = _ws.Cells.Range["A2:D2"];

 --       //        Excel.FormatCondition batchDateCreatedCond = (Excel.FormatCondition)batchDateCreated.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
 --       //                                            Type.Missing, "=IF(" + _ws.Cells.Range["D2"].Address + "=\"\",\"\"," + _ws.Cells.Range["D2"].Address + "< TODAY())",
 --       //                                            Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //        batchDateCreatedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
 --       //        batchDateCreatedCond.Font.Color = HelperUI.WhiteFontColor;
 --       //        batchDateCreatedCond.Font.Bold = true;

 --       //        int atRow = _table.HeaderRowRange.Row - 3;
 --       //        int currEstHrs = _table.ListColumns["Curr Est Hours"].Index;
 --       //        int JTDActualHrs = _table.ListColumns["JTD Actual Hours"].Index;
 --       //        projectedCost = _ws.Cells.Range[_ws.Cells[atRow, currEstHrs], _ws.Cells[atRow, (JTDActualHrs + 1)]];
 --       //        projectedCost.Font.Color = HelperUI.WhiteFontColor;
 --       //        projectedCost.Font.Bold = true;
 --       //        projectedCost.Font.Size = HelperUI.TwelveFontSizeHeader;
 --       //        projectedCost.Interior.Color = HelperUI.NavyBlueHeaderRowColor;

 --       //        projectedCost = _ws.Cells.Range[_ws.Cells[atRow, currEstHrs], _ws.Cells[atRow, currEstHrs + 1]];
 --       //        projectedCost.Merge();
 --       //        projectedCost.Formula = "New Projected Cost";
 --       //        projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
 --       //        projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;

 --       //        projectedCost = _ws.Cells.Range[_ws.Cells[atRow, JTDActualHrs], _ws.Cells[atRow, JTDActualHrs + 1]];
 --       //        projectedCost.Merge();
 --       //        _ws.Names.Add("NewProjectedCost", projectedCost);
 --       //        projectedCost.NumberFormat = HelperUI.CurrencyFormatCondensed;
 --       //        projectedCost.FormulaLocal = "=SUM(" + _table.ListColumns["Projected Cost"].DataBodyRange.Address + ")";
 --       //        projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 2;
 --       //        projectedCost.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThick;
 --       //        projectedCost.HorizontalAlignment = Excel.XlHAlign.xlHAlignRight;

 --       //        int actualCST_HR = _table.ListColumns["Actual CST/HR"].Index;
 --       //        int remCommittedCost = _table.ListColumns["Remaining Committed Cost"].Index;

 --       //        projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, actualCST_HR], _ws.Cells[atRow, remCommittedCost]];
 --       //        projectedMargin.Font.Color = HelperUI.WhiteFontColor;
 --       //        projectedMargin.Font.Bold = true;
 --       //        projectedMargin.Font.Size = HelperUI.TwelveFontSizeHeader;
 --       //        projectedMargin.Interior.Color = HelperUI.NavyBlueHeaderRowColor;

 --       //        _ws.Cells[atRow, actualCST_HR].AddComment("based on most recent posted revenue projection");
 --       //        projectedMargin = _ws.Cells.Range[_ws.Cells[atRow, actualCST_HR], _ws.Cells[atRow, actualCST_HR + 1]];
 --       //        projectedMargin.Merge();
 --       //        projectedMargin.Formula = "New Projected Margin";
 --       //        projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
 --       //        projectedMargin.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;

 --       //        projectedMargin = _ws.Cells[atRow, remCommittedCost];
 --       //        _ws.Names.Add("NewProjectedMargin", projectedMargin);

 --       //        //BEGIN Manual ETC Addition;
 --       //        useManualETC = _ws.get_Range("AA" + atRow + ":" + "AB" + atRow);
 --       //        useManualETC.Merge();
 --       //        useManualETC.Value = "Full Manual ETC:";
 --       //        useManualETC.Font.Color = HelperUI.WhiteFontColor;
 --       //        useManualETC.Font.Bold = true;
 --       //        useManualETC.Font.Size = HelperUI.TwelveFontSizeHeader;
 --       //        useManualETC.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
 --       //        useManualETC.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeLeft].ColorIndex = 2;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeLeft].Weight = Excel.XlBorderWeight.xlThick;

 --       //        useManualETC = _ws.get_Range("AC" + atRow);
 --       //        useManualETC.Validation.Add(Excel.XlDVType.xlValidateList, Excel.XlDVAlertStyle.xlValidAlertStop, Excel.XlFormatConditionOperator.xlBetween, "Yes, No");

 --       //        string job = _ws.Name.Substring(_ws.Name.IndexOf('-', 0, _ws.Name.Length));

 --       //        if (newProjection)
 --       //        {
 --       //            useManualETC.Value = Globals.ThisWorkbook.Application.Sheets[job].Names.Item("FullETCOverride").RefersToRange.Value; //get from report
 --       //        }
 --       //        else
 --       //        {
 --       //            useManualETC.Value = JobJectETC.GetFullETC(cboJobs.SelectedItem.ToString(), Month, costBatchId); //query log
 --       //        }
 --       //        useManualETC.Font.Bold = true;
 --       //        useManualETC.Font.Size = HelperUI.TwelveFontSizeHeader;
 --       //        useManualETC.Interior.Color = HelperUI.DataEntryColor;
 --       //        useManualETC.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeTop].ColorIndex = 1;
 --       //        useManualETC.Borders[Excel.XlBordersIndex.xlEdgeTop].Weight = Excel.XlBorderWeight.xlThin;
 --       //        useManualETC.Validation.ErrorTitle = "Invalid Selection";
 --       //        useManualETC.Validation.ErrorMessage = "For Manual ETC select Yes.\nFor Detail select No.";
 --       //        //END Manual ETC Addition;
 --       //        useManualETC.Application.EnableAutoComplete = false;

 --       //        CostSum_ProjectedMargin_Fill();

 --       //        HelperUI.AddFieldDesc(_ws, "Used", "See comment");
 --       //        HelperUI.AddFieldDesc(_ws, "Parent Phase Description", "Parent phase grouping");
 --       //        HelperUI.AddFieldDesc(_ws, "Phase Code", "Phase Code");
 --       //        HelperUI.AddFieldDesc(_ws, "Phase Description", "Phase description");
 --       //        HelperUI.AddFieldDesc(_ws, "Cost Type", "Cost Type");
 --       //        HelperUI.AddFieldDesc(_ws, "Original Hours", "Original Hours Estimate");
 --       //        HelperUI.AddFieldDesc(_ws, "Original Cost", "Original Cost Estimate");
 --       //        HelperUI.AddFieldDesc(_ws, "Appr CO Hours", "Approved and interfaced change order hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Appr CO Cost", "Approved and interfaced change order cost");
 --       //        HelperUI.AddFieldDesc(_ws, "PCO Hours", "Sum of pending change order (PCO) hours in Viewpoint");
 --       //        HelperUI.AddFieldDesc(_ws, "PCO Cost", "Sum of pending change order (PCO) cost");
 --       //        HelperUI.AddFieldDesc(_ws, "Curr Est Hours", "Original estimated hours plus interfaced change order hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Curr Est Cost", "Original estimate + interfaced change orders");
 --       //        HelperUI.AddFieldDesc(_ws, "JTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets)");
 --       //        HelperUI.AddFieldDesc(_ws, "Batch MTD Actual Hours", "Actual hours completed as entered through Payroll (timesheets) for the current batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "JTD Actual Cost", "Actual cost posted to the project");
 --       //        HelperUI.AddFieldDesc(_ws, "Batch MTD          Actual Cost", "Actual cost incurred on the project for the current batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "Total Hours - All Closed Months", "Actual hours incurred through the end of the prior closed month");
 --       //        HelperUI.AddFieldDesc(_ws, "Total Cost - All Closed Months", "Actual cost incurred through the end of the prior closed month");
 --       //        HelperUI.AddFieldDesc(_ws, "Actual CST/HR", "Actual cost divided by actual hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Total Committed Cost", "Total committments by phase/cost type");
 --       //        HelperUI.AddFieldDesc(_ws, "Remaining Hours", "Sum of hours on labor worksheet by phase");
 --       //        HelperUI.AddFieldDesc(_ws, "Remaining Cost", "Sum of remaining cost from labor and non-labor worksheet by phase");
 --       //        HelperUI.AddFieldDesc(_ws, "Remaining CST/HR", "Remaining cost divided by remaining hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Remaining Committed Cost", "Open or remaining committed cost (negative remaining committed cost may not reflect if there are multiple commitments on phase/CT)");
 --       //        HelperUI.AddFieldDesc(_ws, "JTD + Remaining Committed", "JTD Actual Cost + Remaining Committed Cost");
 --       //        HelperUI.AddFieldDesc(_ws, "Manual ETC Hours", "Labor only - Manual ETC Entry allows user to enter total remaining hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Manual ETC CST/HR", "Labor only - Manual ETC Entry allows user to enter remaining cost per hour");
 --       //        HelperUI.AddFieldDesc(_ws, "Manual ETC Cost", "Non-Labor only - Manual ETC Entry allows user to enter total remaining hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Projected Hours", "All Closed Months Hours + Remaining Hours - or - JTD Hours + Manual ETC hours (if used)");
 --       //        HelperUI.AddFieldDesc(_ws, "Projected Cost", "All Closed Months Cost + Remaining Cost - or - JTD Actual Cost + Manual ETC Cost (if used)");
 --       //        HelperUI.AddFieldDesc(_ws, "Actual Cost > Projected Cost", "If Actual Cost is greater than Projected Cost, the cell will highlight red and warn when saving");
 --       //        HelperUI.AddFieldDesc(_ws, "Prev Projected Hours", "Total hours projected from the lasted posted batch");
 --       //        HelperUI.AddFieldDesc(_ws, "Prev Projected Cost", "Total cost projected from the last posted batch");
 --       //        HelperUI.AddFieldDesc(_ws, "Change in Hours", "Change in total hours projected from last posted batch");
 --       //        HelperUI.AddFieldDesc(_ws, "Change in Cost", "Change in total cost projected from last posted batch");
 --       //        HelperUI.AddFieldDesc(_ws, "LM Projected Hours", "Hours projected at the end of the last batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "LM Projected Cost", "Cost projected at the end of the last batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "Change from LM Projected Hours", "Change in total hours projected from last batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "Change from LM Projected Cost", "Change in total cost projected from last batch month");
 --       //        HelperUI.AddFieldDesc(_ws, "Over/Under Hours", "Current estimated hours (including interfaced change orders) less total projected hours");
 --       //        HelperUI.AddFieldDesc(_ws, "Over/Under Cost", "Current estimated cost (including interfaced change orders) less total projected cost");

 --       //        HelperUI.MergeLabel(_ws, "Used", "Cost Type", "Phase Detail");
 --       //        HelperUI.MergeLabel(_ws, "Original Hours", "Original Cost", "Original Estimate (Budget)");
 --       //        HelperUI.MergeLabel(_ws, "Appr CO Hours", "PCO Cost", "Change Orders");
 --       //        HelperUI.MergeLabel(_ws, "Curr Est Hours", "Curr Est Cost", "Current Budget");
 --       //        HelperUI.MergeLabel(_ws, "JTD Actual Hours", "Total Committed Cost", "Actual");
 --       //        HelperUI.MergeLabel(_ws, "Remaining Hours", "Remaining CST/HR", "Remaining (ETC) from Worksheet");
 --       //        HelperUI.MergeLabel(_ws, "Remaining Committed Cost", "Remaining Committed Cost", "Remaining Committed");
 --       //        HelperUI.MergeLabel(_ws, "JTD + Remaining Committed", "Manual ETC Cost", "Manual ETC Entry");
 --       //        HelperUI.MergeLabel(_ws, "Projected Hours", "Actual Cost > Projected Cost", "Projected @ Completion");
 --       //        HelperUI.MergeLabel(_ws, "Prev Projected Hours", "Prev Projected Cost", "Prev Projection ");
 --       //        HelperUI.MergeLabel(_ws, "Change in Hours", "Change in Cost", "Change from Previous Projection");
 --       //        HelperUI.MergeLabel(_ws, "LM Projected Hours", "LM Projected Cost", "Last Month");
 --       //        HelperUI.MergeLabel(_ws, "Change from LM Projected Hours", "Change from LM Projected Cost", "Change from Last Month");
 --       //        HelperUI.MergeLabel(_ws, "Over/Under Hours", "Over/Under Cost", "Over/Under Current Estimate");

 --       //        _ws.get_Range("A4", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //        _ws.get_Range("A4", Type.Missing).EntireRow.Hidden = true;
 --       //        _ws.get_Range("B5", Type.Missing).EntireColumn.Hidden = true;

 --       //        _table.ShowTotals = true;

 --       //        _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

 --       //        _table.ListColumns["Manual ETC Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
 --       //        _table.ListColumns["Manual ETC CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        _table.ListColumns["Remaining CST/HR"].DataBodyRange.Style = HelperUI.CurrencyStyle;

 --       //        _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].AddComment("If the phase code has no budgeted, actual or projected cost it is hidden. Adjust column filter to see all rows.");
 --       //        _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;

 --       //        CostSumWritable = _ws.Range[_ws.Cells[_table.HeaderRowRange.Row + 1, _table.ListColumns["Manual ETC Hours"].Index],
 --       //                                   _ws.Cells[_table.TotalsRowRange.Row - 1, _table.ListColumns["Manual ETC Cost"].Index]];

 --       //        CostSumWritable.Interior.Color = HelperUI.DataEntryColor;

 --       //        HelperUI.FormatHoursCost(_ws);

 --       //        foreach (Excel.ListColumn col in _table.ListColumns)
 --       //        {
 --       //            col.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
 --       //        }

 --       //        string[] noSummation = new string[] { "Used", "Parent Phase Description", "Phase Code", "Phase Description", "Cost Type", "Actual CST/HR", "Remaining CST/HR", "Manual ETC CST/HR" };
 --       //        foreach (string col in noSummation)
 --       //        {
 --       //            try
 --       //            {
 --       //                _table.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
 --       //            }
 --       //            catch (Exception) { }
 --       //        }
 --       //        _table.HeaderRowRange.EntireRow.WrapText = true;
 --       //        _table.HeaderRowRange.EntireRow.RowHeight = 30.00;
 --       //        _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

 --       //        _table.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        projectedCost = _table.ListColumns["Projected Cost"].DataBodyRange;
 --       //        projectedCost.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
 --       //        projectedCost.Font.Color = HelperUI.WhiteFontColor;
 --       //        projectedCost.Font.Bold = true;
 --       //        projectedCost.Cells.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
 --       //        projectedCost.Cells.Borders.Weight = Excel.XlBorderWeight.xlThin;
 --       //        projectedCost.Cells.Borders.Color = HelperUI.GrayBreakDownHeaderRowColor;
 --       //        projectedCost.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
 --       //        projectedCost.Cells.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.GrayBreakDownHeaderRowColor;

 --       //        _ws.Cells.Locked = false;
 --       //        _ws.Range["A1:A3"].EntireRow.Locked = true;
 --       //        useManualETC.Locked = false;
 --       //        _table.HeaderRowRange.Locked = true;
 --       //        _table.DataBodyRange.Locked = true;
 --       //        _table.TotalsRowRange.Locked = false;
 --       //        CostSumWritable.Locked = false;

 --       //        int costTypeCol = _table.ListColumns["Cost Type"].Index;
 --       //        int tblHeadRow = _table.HeaderRowRange.Row;

 --       //        Excel.Range manualETCCost = _table.ListColumns["Manual ETC Cost"].DataBodyRange;
 --       //        Excel.Range manualETCHours = _table.ListColumns["Manual ETC Hours"].DataBodyRange;
 --       //        Excel.Range manualETC_CST_HR = _table.ListColumns["Manual ETC CST/HR"].DataBodyRange;

 --       //        //Attempt to Resolve Enter of ZERO value
 --       //        //manualETCHours.Value = "";
 --       //        //manualETCCost.Value = "";
 --       //        //if (manualETCCost == ".02") manualETCCost.Value = "";

 --       //        manualETCHours.NumberFormat = HelperUI.NumberFormat;

 --       //        string[] _manualETCCost = manualETCCost.Address.Split('$');
 --       //        string[] _manualETCHours = manualETCHours.Address.Split('$');
 --       //        string[] _manualETC_CST_HR = manualETC_CST_HR.Address.Split('$');
 --       //        int row;
 --       //        for (int i = 1; i <= CostSumWritable.Rows.Count; i++)
 --       //        {
 --       //            row = tblHeadRow + i;

 --       //            if (_ws.Cells[row, costTypeCol].Value == "L")
 --       //            {
 --       //                _ws.Cells[row, manualETCCost.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
 --       //                _ws.Cells[row, manualETCCost.Column].Locked = true;
 --       //                _ws.Cells[row, manualETCCost.Column].FormulaLocal = "=IF([@[Manual ETC Hours]]<>\"\",[@[Manual ETC Hours]]*[@[Manual ETC CST/HR]],\"\")";

 --       //                // Alphanumeric entries red
 --       //                Excel.FormatCondition manualETCHrs_bad = (Excel.FormatCondition)_ws.Cells[row, manualETCHours.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                                          "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETCHours[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETCHours[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //                manualETCHrs_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

 --       //                Excel.FormatCondition manualETC_CST_HR_bad = (Excel.FormatCondition)_ws.Cells[row, manualETC_CST_HR.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                   "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETC_CST_HR[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETC_CST_HR[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //                manualETC_CST_HR_bad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

 --       //                Excel.FormatCondition manualETCHrs_manualETC_CST_HR_Cond = (Excel.FormatCondition)_ws.Cells.Range[_ws.Cells[row, manualETCHours.Column], _ws.Cells[row, manualETC_CST_HR.Column]].FormatConditions.Add(
 --       //                                                            Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                                            "=AND(IF(SUBSTITUTE($" + _manualETCHours[1] + "$" + row + ",\" \",\"\")<>\"\",TRUE,FALSE),NOT(ISERROR(VALUE(" + _manualETCHours[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //                manualETCHrs_manualETC_CST_HR_Cond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
 --       //            }
 --       //            else
 --       //            {
 --       //                _ws.Cells[row, manualETCHours.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
 --       //                _ws.Cells[row, manualETCHours.Column].Locked = true;
 --       //                _ws.Cells[row, manualETC_CST_HR.Column].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.LightGray);
 --       //                _ws.Cells[row, manualETC_CST_HR.Column].Locked = true;

 --       //                Excel.FormatCondition manualETCCost_BAD = (Excel.FormatCondition)_ws.Cells[row, manualETCCost.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                   "=ISERROR(VALUE(IF(SUBSTITUTE($" + _manualETCCost[1] + "$" + row + ",\" \",\"\")=\"\",0,VALUE(" + _manualETCCost[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //                manualETCCost_BAD.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

 --       //                Excel.FormatCondition manualETCCostCond = (Excel.FormatCondition)_ws.Cells[row, manualETCCost.Column].FormatConditions.Add(
 --       //                                    Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                    "=AND(IF(SUBSTITUTE($" + _manualETCCost[1] + "$" + row + ",\" \",\"\")<>\"\",TRUE,FALSE),NOT(ISERROR(VALUE(" + _manualETCCost[1] + "$" + row + "))))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);

 --       //                manualETCCostCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);
 --       //            }
 --       //        }

 --       //        _ws.Cells[_table.TotalsRowRange.Row, 1].Value = "Total";
 --       //        _ws.UsedRange.Font.Name = HelperUI.FontCalibri;
 --       //        _ws.Tab.Color = HelperUI.DataEntryColor;

 --       //        _table.ListColumns["Used"].DataBodyRange.EntireColumn.ColumnWidth = 3.50;
 --       //        _table.ListColumns["Parent Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 23.50;
 --       //        _table.ListColumns["Phase Code"].DataBodyRange.EntireColumn.ColumnWidth = 11.50;
 --       //        _table.ListColumns["Phase Description"].DataBodyRange.EntireColumn.ColumnWidth = 25.00;
 --       //        _table.ListColumns["Cost Type"].DataBodyRange.EntireColumn.ColumnWidth = 6.00;

 --       //        _table.ListColumns["Original Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Original Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Appr CO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Appr Co Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;
 --       //        _table.ListColumns["PCO Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["PCO Cost"].DataBodyRange.EntireColumn.ColumnWidth = 13.00;
 --       //        _table.ListColumns["Curr Est Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Curr Est Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["JTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Batch MTD Actual Hours"].DataBodyRange.EntireColumn.ColumnWidth = 12.00;
 --       //        _table.ListColumns["JTD Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Batch MTD          Actual Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

 --       //        _table.ListColumns["Total Hours - All Closed Months"].DataBodyRange.EntireColumn.ColumnWidth = 15.00;
 --       //        _table.ListColumns["Total Cost - All Closed Months"].DataBodyRange.EntireColumn.ColumnWidth = 15.00;

 --       //        _table.ListColumns["Actual CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Total Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
 --       //        _table.ListColumns["Remaining Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
 --       //        _table.ListColumns["Remaining Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Remaining CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 8.30;
 --       //        _table.ListColumns["Remaining Committed Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;
 --       //        _table.ListColumns["JTD + Remaining Committed"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Manual ETC Hours"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
 --       //        _table.ListColumns["Manual ETC CST/HR"].DataBodyRange.EntireColumn.ColumnWidth = 9.00;
 --       //        _table.ListColumns["Manual ETC Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Actual Cost > Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 14.75;

 --       //        _table.ListColumns["Prev Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 11.70;
 --       //        _table.ListColumns["Prev Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 17.70;
 --       //        _table.ListColumns["Change in Hours"].DataBodyRange.EntireColumn.ColumnWidth = 8.00;
 --       //        _table.ListColumns["Change in Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["LM Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.50;
 --       //        _table.ListColumns["LM Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 16.75;
 --       //        _table.ListColumns["Change from LM Projected Hours"].DataBodyRange.EntireColumn.ColumnWidth = 15.00;
 --       //        _table.ListColumns["Change from LM Projected Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.ColumnWidth = 10.00;
 --       //        _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.ColumnWidth = 15.75;

 --       //        _table.ListColumns["Over/Under Hours"].DataBodyRange.EntireColumn.AutoFit();
 --       //        _table.ListColumns["Over/Under Cost"].DataBodyRange.EntireColumn.AutoFit();

 --       //        HelperUI.PrintPageSetup(_ws);

 --       //    }
 --       //    catch (Exception ex) { throw new Exception("SetupSumTab: " + ex.Message); }
 --       //    finally
 --       //    {
 --       //        if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
 --       //        if (_table != null) Marshal.ReleaseComObject(_table);
 --       //        if (projectedCost != null) Marshal.ReleaseComObject(projectedCost);
 --       //        if (projectedMargin != null) Marshal.ReleaseComObject(projectedMargin);
 --       //        //if (useManualETC != null) Marshal.ReleaseComObject(useManualETC);
 --       //    }
 --       //}
		
		
	--	/* DEPRECATED CODE PRE- HelperUI.SetAlphanumericNotAllowedRule */
 --       //private void SetupLaborTab(Excel.Worksheet _wsSum, Excel.Worksheet _wsNonLabor, Excel.Worksheet _wsLabor, out Excel.Range rngHeaders,
 --       //    out Excel.Range rngTotals, out Excel.Range rngStart, out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd)
 --       //{
 --       //    Excel.Range rng = null;
 --       //    try
 --       //    {
 --       //        HelperUI.CreateTitleHeader(_wsLabor, "LABOR WORKSHEET: " + (JobGetTitle.GetTitle(JCCo, Job)).ToUpper());

 --       //        table = _wsLabor.ListObjects[1];
 --       //        rngHeaders = table.HeaderRowRange;
 --       //        rngTotals = table.TotalsRowRange;

 --       //        HelperUI.FormatHoursCost(_wsLabor);

 --       //        // USER EDITABLE CELLS
 --       //        LaborEmpDescEdit = table.ListColumns["Employee ID"].DataBodyRange;
 --       //        LaborEmpDescEdit.NumberFormat = "General";
 --       //        LaborEmpDescEdit = _wsLabor.Range[LaborEmpDescEdit, table.ListColumns["Description"].DataBodyRange];
 --       //        LaborEmpDescEdit.Interior.Color = HelperUI.DataEntryColor;

 --       //        LaborRateEdit = table.ListColumns["Rate"].DataBodyRange;
 --       //        LaborRateEdit.EntireColumn.Style = HelperUI.CurrencyStyle;
 --       //        LaborRateEdit.Interior.Color = HelperUI.DataEntryColor;

 --       //        string phaseActualRate = "Phase Actual Rate";

 --       //        table.ListColumns[phaseActualRate].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns[phaseActualRate].Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //        // MONTHS body
 --       //        periodStartLabor = table.ListColumns[phaseActualRate].Index + _offsetFromPhseActRate;
 --       //        string startDate = table.ListColumns[periodStartLabor].Name;
 --       //        rngStart = _wsLabor.Cells[rngHeaders.Row + 1, periodStartLabor];

 --       //        DateTime startPeriod = DateTime.Parse(startDate);

 --       //        // if the starting month is less than the projection month, gray it out and make read-only
 --       //        if ((Month.Year == startPeriod.Year && Month.Date.Month > startPeriod.Month) || Month.Year > startPeriod.Year)
 --       //        {
 --       //            ++_offsetFromPhseActRate;
 --       //            rng = _wsLabor.Cells[rngTotals.Row - 1, periodStartLabor];
 --       //            rngStart = _wsLabor.get_Range(rngStart, rng);
 --       //            rngStart.Interior.Color = HelperUI.LightGrayHeaderRowColor;
 --       //            rngStart.NumberFormat = HelperUI.GeneralFormat;
 --       //            rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //            rngStart = _wsLabor.Cells[rngTotals.Row, periodStartLabor];
 --       //            rngStart.NumberFormat = HelperUI.GeneralFormat;
 --       //            rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //            rngStart = _wsLabor.Cells[rngHeaders.Row + 1, periodStartLabor + 1];
 --       //        }
 --       //        else
 --       //        {
 --       //            rngStart = _wsLabor.Cells[rngHeaders.Row + 1, periodStartLabor];
 --       //        }

 --       //        int periodEnd = rngHeaders.Columns.Count;
 --       //        rngEnd = _wsLabor.Cells[rngTotals.Row - 1, periodEnd];

 --       //        LaborMonthsEdit = _wsLabor.Range[rngStart, rngEnd];
 --       //        LaborMonthsEdit.NumberFormat = HelperUI.GeneralFormat;
 --       //        LaborMonthsEdit.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        LaborMonthsEdit.Interior.Color = HelperUI.DataEntryColor;

 --       //        rngEnd = _wsLabor.Cells[rngTotals.Row, periodEnd];

 --       //        _wsLabor.get_Range(rngStart, rngEnd).NumberFormat = HelperUI.GeneralFormat;
 --       //        _wsLabor.get_Range(rngStart, rngEnd).HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //        LaborConditionalFormat(_wsLabor, table, 1, LaborMonthsEdit.Rows.Count, rngHeaders);

 --       //        //Labor Tab Formulas that refer to the Summary Tab
 --       //        table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
 --       //        table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.FormulaLocal =
 --       //             "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Hours],tbl" + contJobJectBatchSum_table.TableName +
 --       //             "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName +
 --       //             "[JTD Actual Hours],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\"))";

 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.FormulaLocal =
 --       //                "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@Phase Code],tbl" +
 --       //            contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[JTD Actual Cost],tbl" +
 --       //                contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\"))";

 --       //        column = table.ListColumns[phaseActualRate];
 --       //        column.DataBodyRange.FormulaLocal = "=AVERAGEIFS(tbl" + contJobJectBatchSum_table.TableName +
 --       //                                            "[Actual CST/HR],tbl" + contJobJectBatchSum_table.TableName +
 --       //                                            "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],\"L\")";

 --       //        column = table.ListColumns["Remaining Hours"];
 --       //        cellStart = _wsLabor.Cells[rngHeaders.Row, periodStartLabor];
 --       //        cellEnd = _wsLabor.Cells[rngHeaders.Row, rngHeaders.Columns.Count];
 --       //        column.DataBodyRange.FormulaLocal = "=SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]])";

 --       //        table.ListColumns["Remaining Cost"].DataBodyRange.FormulaLocal = "=[@[Remaining Hours]]*[@Rate]";

 --       //        table.ListColumns["Previous Remaining Cost"].DataBodyRange.Value2 = table.ListColumns["Remaining Cost"].DataBodyRange.Value2;


 --       //        table.ListColumns["Used"].DataBodyRange.FormulaLocal =
 --       //            "=IF([@Remaining Hours]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@Phase Actual Rate]<>0,\"Y\",IF([@Rate]<>0,\"Y\",IF([@[Budgeted Phase Hours Remaining]]<>0,\"Y\",IF([@Budgeted Phase Cost Remaining]<>0,\"Y\",IF([@MTD Actual Cost]<>0,\"Y\",IF([@MTD Actual Hours]<>0,\"Y\",\"N\"))))))))";

 --       //        //HelperUI.FormatHoursCost(_wsLabor);

 --       //        foreach (Excel.ListColumn col in table.ListColumns) col.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

 --       //        string[] noSummation = new string[] { "Used", "Parent Phase Group", "Phase Code", "Phase Desc", "Employee ID", "Description",
 --       //                                              "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", phaseActualRate, "Rate", "MTD Actual Cost", "MTD Actual Hours" };
 --       //        foreach (string col in noSummation)
 --       //        {
 --       //            try
 --       //            {
 --       //                table.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
 --       //            }
 --       //            catch (Exception ex) { throw new Exception("SetupLaborTab: " + ex.Message); }
 --       //        }

 --       //        column = table.ListColumns["Variance"];
 --       //        column.DataBodyRange.FormulaLocal = "=[@[Remaining Cost]]-[@[Previous Remaining Cost]]";
 --       //        column.Range.Style = "Currency";

 --       //        HelperUI.ApplyVarianceFormat(column);

 --       //        table.HeaderRowRange.EntireRow.WrapText = true;
 --       //        table.HeaderRowRange.EntireRow.RowHeight = 30.00;
 --       //        table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

 --       //        table.ListColumns["Used"].DataBodyRange.ColumnWidth = 3.50;
 --       //        table.ListColumns["Parent Phase Group"].DataBodyRange.ColumnWidth = 23.50;
 --       //        table.ListColumns["Phase Code"].DataBodyRange.ColumnWidth = 11.50;
 --       //        table.ListColumns["Phase Desc"].DataBodyRange.ColumnWidth = 25.00;

 --       //        table.ListColumns["Employee ID"].DataBodyRange.ColumnWidth = 8.00;
 --       //        table.ListColumns["Description"].DataBodyRange.ColumnWidth = 20.00;
 --       //        table.ListColumns["Remaining Hours"].DataBodyRange.ColumnWidth = 9.00;
 --       //        table.ListColumns["Remaining Cost"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns["Budgeted Phase Hours Remaining"].DataBodyRange.ColumnWidth = 15.50;
 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns["Previous Remaining Cost"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns["Variance"].DataBodyRange.ColumnWidth = 14.75;
 --       //        table.ListColumns[phaseActualRate].DataBodyRange.ColumnWidth = 10.00;
 --       //        table.ListColumns["Rate"].DataBodyRange.ColumnWidth = 10.00;
 --       //        table.ListColumns["MTD Actual Cost"].DataBodyRange.ColumnWidth = 14.75;
 --       //        table.ListColumns["MTD Actual Hours"].DataBodyRange.ColumnWidth = 10.00;

 --       //        HelperUI.AddFieldDesc(_wsLabor, "Parent Phase Group", "Parent phase code grouping (roll up code)");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Phase Code", "Phase Code");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Phase Desc", "PM Project phase description");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Remaining Cost", "Remaining Hours x Rate");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Employee ID", "Employee ID");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Description", "Description to held PM identify and track costs");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Remaining Hours", "Sum of periodic hour estimates");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Hours Remaining", "Current Estimated Hours less Actual Hours (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Budgeted Phase Cost Remaining", "Current Estimated Cost less Actual Cost (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Previous Remaining Cost", "Projected Remaining Cost as of McKinstry Projections tool opening");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Variance", "Remaining Cost less Previous Remaining Cost");
 --       //        HelperUI.AddFieldDesc(_wsLabor, phaseActualRate, "Actual cost per hour (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "Rate", "User Input for remaining. Default to Actual, or if null budgeted rate for PHASE CODE");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current batch month (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsLabor, "MTD Actual Hours", "Actual hours for the current batch month (at phase code level)");

 --       //        HelperUI.MergeLabel(_wsLabor, "Used", "Description", "Phase Detail", 1, 2);
 --       //        HelperUI.MergeLabel(_wsLabor, "Remaining Hours", "Remaining Cost", "Projected Remaining", 1, 2);
 --       //        HelperUI.MergeLabel(_wsLabor, "Budgeted Phase Hours Remaining", "Budgeted Phase Cost Remaining", "Budgeted Remaining", 1, 2);
 --       //        HelperUI.MergeLabel(_wsLabor, "Previous Remaining Cost", "Variance", "Previous", 1, 2);
 --       //        HelperUI.MergeLabel(_wsLabor, phaseActualRate, "Rate", "Rate", 1, 2);
 --       //        HelperUI.MergeLabel(_wsLabor, "MTD Actual Cost", "MTD Actual Hours", "BATCH MTD Actual", 1, 2);

 --       //        int c = table.ListColumns["Rate"].DataBodyRange.Column + 3;

 --       //        HelperUI.MergeLabel(_wsLabor, _wsLabor.Cells[rngHeaders.Row, c].Value, _wsLabor.Cells[rngHeaders.Row, table.ListColumns.Count].Value, "PROJECTED HOURS", 1, 2, horizAlign: Excel.XlHAlign.xlHAlignLeft);

 --       //        rngStart = _wsLabor.Range[_wsLabor.Cells[rngHeaders.Row - 1, periodStartLabor], _wsLabor.Cells[rngHeaders.Row - 1, table.ListColumns.Count]];
 --       //        rngStart.Merge();
 --       //        rngStart.Value = "Projected hours remaining on the project by week/month\nReminder: Current month should be MTD Actual Hours plus remaining hours for the month)";
 --       //        rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        rngStart.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;

 --       //        rngStart.Columns.ColumnWidth = 11;

 --       //        if (LaborPivot == "MTH")
 --       //        {
 --       //            foreach (Excel.Range col in rngStart.Columns)
 --       //            {
 --       //                rng = _wsLabor.Cells[rngHeaders.Row, col.Column];
 --       //                rng.AddComment(HelperUI.GetWeeksInMonth(DateTime.Parse(rng.Text), DayOfWeek.Sunday) + " Payroll Weeks");
 --       //            }
 --       //        }

 --       //        rng = _wsLabor.Cells[rngHeaders.Row - 2, periodStartLabor];
 --       //        string main = "PROJECTED HOURS";
 --       //        string sub = "(INCLUDE MTD ACTUAL HOURS IN CURRENT MONTH)";
 --       //        rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
 --       //        rng.Characters[Start: main.Length + 1, Length: sub.Length + 2].Font.Size = 8;

 --       //        _wsLabor.get_Range("A3", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //        _wsLabor.get_Range("A3", Type.Missing).EntireRow.Hidden = true;

 --       //        HelperUI.GroupColumns(_wsLabor, "Parent Phase Group", null, true);
 --       //        HelperUI.GroupColumns(_wsLabor, "Budgeted Phase Hours Remaining", "Variance", true);
 --       //        HelperUI.GroupColumns(_wsLabor, "Employee ID", "Description", false);

 --       //        // HelperUI.SortAscending(_wsLabor, "Phase" "Cost Type");
 --       //        table.ListColumns["Rate"].DataBodyRange.EntireColumn.ColumnWidth = 12;

 --       //        _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].AddComment("If the phase code has projected remaining hours, previous remaining hours or a phase actual rate it will be shown on default.  Adjust column filter to see all rows.");
 --       //        _wsLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;
 --       //        _wsLabor.Cells[table.TotalsRowRange.Row, 1].Value = "Total";

 --       //        // set key fields to read-only
 --       //        _wsLabor.Cells.Locked = false;
 --       //        _wsLabor.Range["A1:A3"].EntireRow.Locked = true;
 --       //        table.DataBodyRange.Locked = true;
 --       //        LaborEmpDescEdit.Locked = false;
 --       //        LaborRateEdit.Locked = false;
 --       //        LaborMonthsEdit.Locked = false;
 --       //        rngHeaders.Locked = true;
 --       //        rngTotals.Locked = false;
 --       //        HelperUI.ProtectSheet(_wsLabor);

 --       //        // Summary tab formulas that ref Labor tab
 --       //        _wsSum.ListObjects[1].ListColumns["Remaining Hours"].DataBodyRange.NumberFormat = HelperUI.GeneralFormat;
 --       //        _wsSum.ListObjects[1].ListColumns["Remaining Hours"].DataBodyRange.FormulaLocal =
 --       //            "=IF([@[Cost Type]]=\"L\",SUMIFS(" + table.Name + "[Remaining Hours]," + table.Name + "[Phase Code],[@[Phase Code]]),\" \")";

 --       //        _wsSum.ListObjects[1].ListColumns["Remaining Cost"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        _wsSum.ListObjects[1].ListColumns["Remaining Cost"].DataBodyRange.FormulaLocal =
 --       //            "=IF([@[Cost Type]]=\"L\",SUMIFS(" + table.Name + "[Remaining Cost]," + table.Name + "[Phase Code],[@[Phase Code]]),SUMIFS("
 --       //            + _wsNonLabor.ListObjects[1].Name + "[Remaining Cost]," + _wsNonLabor.ListObjects[1].Name + "[Phase Code],[@[Phase Code]]," + _wsNonLabor.ListObjects[1].Name + "[Cost Type],[@[Cost Type]]))";

 --       //        _wsLabor.UsedRange.Font.Name = HelperUI.FontCalibri;
 --       //        _wsLabor.Tab.Color = HelperUI.DataEntryColor;
 --       //        HelperUI.PrintPageSetup(_wsLabor);

 --       //    }
 --       //    catch (Exception e) { throw new Exception("SetupLaborTab: " + e.Message, e); }
 --       //    finally
 --       //    {
 --       //        _offsetFromPhseActRate = 4;
 --       //        if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
 --       //    }
 --       //}


 --/* PRE- HelperUI.SetAlphanumericNotAllowedRule */
 --       //private void SetupNonLaborTab(Excel.Worksheet _wsNonLabor, out Excel.Range rngHeaders, out Excel.Range rngTotals, out Excel.Range rngStart,
 --       //    out Excel.Range rngEnd, out Excel.ListObject table, out Excel.ListColumn column, out Excel.Range cellStart, out Excel.Range cellEnd, out string remainingCost)
 --       //{
 --       //    _wsNonLabor.Cells.Locked = false;
 --       //    Excel.Range rng = null;
 --       //    try
 --       //    {
 --       //        HelperUI.CreateTitleHeader(_wsNonLabor, "NON LABOR WORKSHEET: " + (JobGetTitle.GetTitle(JCCo, Job)).ToUpper());

 --       //        table = _wsNonLabor.ListObjects[1];
 --       //        rngHeaders = _wsNonLabor.ListObjects[1].HeaderRowRange;
 --       //        rngTotals = _wsNonLabor.ListObjects[1].TotalsRowRange;

 --       //        // USER EDITABLE AREA
 --       //        NonLaborWritable1 = table.ListColumns["Description"].DataBodyRange;
 --       //        NonLaborWritable1.Interior.Color = HelperUI.DataEntryColor;

 --       //        // 'Description' validation rule
 --       //        string[] _descriptionCol = NonLaborWritable1.Address.Split('$');
 --       //        string range = _descriptionCol.Length > 3 ? _descriptionCol[1] + _descriptionCol[2] + _descriptionCol[3] + _descriptionCol[4] : _descriptionCol[1] + _descriptionCol[2];

 --       //        RevWritable1.Validation.Add(Excel.XlDVType.xlValidateCustom,
 --       //                                    Excel.XlDVAlertStyle.xlValidAlertStop,
 --       //                                    Type.Missing, "=IsNumber(Trim(" + range + ")*1)");
 --       //        RevWritable1.Validation.ErrorTitle = "Woops!";
 --       //        RevWritable1.Validation.ErrorMessage = "Non-numeric values are not allowed, please update your entry";

 --       //        remainingCost = "Remaining Cost";
 --       //        column = table.ListColumns[remainingCost];
 --       //        //HelperUI.FreezePane(_wsNonLabor, _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns[keyBeforeDataEntry].Index+1].Value);
 --       //        column.TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
 --       //        column.Range.Style = HelperUI.CurrencyStyle;

 --       //        // periods (titles - readonly)
 --       //        int periodEnd = rngHeaders.Columns.Count;
 --       //        cellEnd = _wsNonLabor.Cells[rngHeaders.Row, periodEnd];
 --       //        cellStart = _wsNonLabor.Cells[rngHeaders.Row, column.Index + _offsetFromRemCost];
 --       //        column.DataBodyRange.FormulaLocal = "=SUM(" + table.Name + "[@[" + cellStart.Formula + "]:[" + cellEnd.Formula + "]])";

 --       //        // periods editable area
 --       //        periodStartNonLabor = table.ListColumns[remainingCost].Index + _offsetFromRemCost;
 --       //        string startDate = table.ListColumns[periodStartNonLabor].Name;
 --       //        rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, periodStartNonLabor];

 --       //        DateTime startPeriod = DateTime.Parse(startDate);

 --       //        if ((Month.Year == startPeriod.Year && Month.Date.Month > startPeriod.Month) || Month.Year > startPeriod.Year)
 --       //        {
 --       //            ++_offsetFromRemCost;
 --       //            rngStart = _wsNonLabor.Range[rngStart, _wsNonLabor.Cells[rngTotals.Row - 1, periodStartNonLabor]];
 --       //            rngStart.Interior.Color = HelperUI.LightGrayHeaderRowColor;
 --       //            rngStart.Style = HelperUI.CurrencyStyle;
 --       //            rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //            rngStart = _wsNonLabor.Cells[rngTotals.Row, periodStartNonLabor];
 --       //            rngStart.Style = HelperUI.CurrencyStyle;
 --       //            rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //            rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, periodStartNonLabor + 1];
 --       //        }
 --       //        else
 --       //        {
 --       //            rngStart = _wsNonLabor.Cells[rngHeaders.Row + 1, periodStartNonLabor];
 --       //        }

 --       //        rngEnd = _wsNonLabor.Cells[rngTotals.Row - 1, periodEnd];

 --       //        NonLaborWritable2 = _wsNonLabor.Range[rngStart, rngEnd];
 --       //        NonLaborWritable2.Style = HelperUI.CurrencyStyle;
 --       //        NonLaborWritable2.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        NonLaborWritable2.Interior.Color = HelperUI.DataEntryColor;
 --       //        NonLaborWritable2.EntireColumn.ColumnWidth = 14.57;

 --       //        rngEnd = _wsNonLabor.Cells[rngTotals.Row, periodEnd];

 --       //        _wsNonLabor.Range[rngStart, rngEnd].Style = HelperUI.CurrencyStyle;
 --       //        _wsNonLabor.Range[rngStart, rngEnd].HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //        NonLaborConditionalFormat(_wsNonLabor, table, 1, NonLaborWritable2.Rows.Count, rngHeaders);

 --       //        table.ListColumns["MTD Actual Cost"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;

 --       //        table.ListColumns["Previous Remaining Cost"].DataBodyRange.Value2 = column.DataBodyRange.Value2;
 --       //        table.ListColumns["Previous Remaining Cost"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns["Previous Remaining Cost"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;

 --       //        // Insert formulas & format
 --       //        column = table.ListColumns["Variance"];
 --       //        table.ListColumns["Variance"].DataBodyRange.FormulaLocal = "=[@[Remaining Cost]]-[@[Previous Remaining Cost]]";
 --       //        table.ListColumns["Variance"].Range.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns["Variance"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
 --       //        table.ListColumns["Variance"].Range.Cells.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //        table.ListColumns["Used"].DataBodyRange.FormulaLocal = "=IF([@[Remaining Cost]]<>0,\"Y\",IF([@[Previous Remaining Cost]]<>0,\"Y\",IF([@[Budgeted Phase Cost Remaining]]<>0,\"Y\",IF([@[Phase Open Committed]]<>0,\"Y\",IF([@[MTD Actual Cost]]<>0,\"Y\",\"N\")))))";

 --       //        //Formulas that Point to the Summary Tab
 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.FormulaLocal =
 --       //            "=(SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Curr Est Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
 --       //            contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]])) - (SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[JTD Actual Cost],tbl" +
 --       //            contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" + contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]]))";

 --       //        table.ListColumns["Phase Open Committed"].DataBodyRange.Style = HelperUI.CurrencyStyle;
 --       //        table.ListColumns["Phase Open Committed"].DataBodyRange.FormulaLocal =
 --       //            "=SUMIFS(tbl" + contJobJectBatchSum_table.TableName + "[Remaining Committed Cost],tbl" + contJobJectBatchSum_table.TableName + "[Phase Code],[@[Phase Code]],tbl" +
 --       //            contJobJectBatchSum_table.TableName + "[Cost Type],[@[Cost Type]])";

 --       //        HelperUI.ApplyVarianceFormat(column);

 --       //        table.ListColumns["Cost Type"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        table.ListColumns["Used"].DataBodyRange.ColumnWidth = 3.50;
 --       //        table.ListColumns["Parent Phase Group"].DataBodyRange.ColumnWidth = 23.50;
 --       //        table.ListColumns["Phase Code"].DataBodyRange.ColumnWidth = 11.50;
 --       //        table.ListColumns["Phase Desc"].DataBodyRange.ColumnWidth = 25.00;
 --       //        table.ListColumns["Cost Type"].DataBodyRange.ColumnWidth = 6.50;
 --       //        table.ListColumns["Description"].DataBodyRange.ColumnWidth = 20.00;
 --       //        table.ListColumns["Budgeted Phase Cost Remaining"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns["Previous Remaining Cost"].DataBodyRange.ColumnWidth = 14.75;
 --       //        table.ListColumns["MTD Actual Cost"].DataBodyRange.ColumnWidth = 14.75;
 --       //        table.ListColumns["Variance"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns["Phase Open Committed"].DataBodyRange.ColumnWidth = 15.75;
 --       //        table.ListColumns[remainingCost].DataBodyRange.ColumnWidth = 14.75;

 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Used", "Used");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Parent Phase Group", "Parent phase code grouping (roll up code)");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Phase Code", "Phase Code");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Phase Desc", "PM Project phase description");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Cost Type", "Cost Type");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Description", "Description to held PM identify and track costs");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Budgeted Phase Cost Remaining", "Budgeted Remaining Cost (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Previous Remaining Cost", "Projected Remaining Cost as of McKinstry Projections tool opening");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Variance", "Remaining Cost less Previous Remaining Cost");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Remaining Cost", "Sum of monthly cost estimates");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "MTD Actual Cost", "Actual cost incurred on the project for the current batch month (at phase code level)");
 --       //        HelperUI.AddFieldDesc(_wsNonLabor, "Phase Open Committed", "Open committed cost aka Remaining Committed cost (at phase code level)");

 --       //        HelperUI.MergeLabel(_wsNonLabor, _wsNonLabor.Cells[rngHeaders.Row, periodStartNonLabor].Value, _wsNonLabor.Cells[rngHeaders.Row, periodEnd].Value, "PROJECTED COST", horizAlign: Excel.XlHAlign.xlHAlignLeft);

 --       //        rngStart = _wsNonLabor.Range[_wsNonLabor.Cells[rngHeaders.Row - 1, periodStartNonLabor], _wsNonLabor.Cells[rngHeaders.Row - 1, periodEnd]];
 --       //        rngStart.Merge();
 --       //        rngStart.Value = "Projected cost remaining on the project by month\nReminder: Current month should be MTD Actual Costs plus remaining projected costs for the month)";
 --       //        rngStart.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        rngStart.VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;

 --       //        rng = _wsNonLabor.Cells[rngHeaders.Row - 2, table.ListColumns["MTD Actual Cost"].Index + 1];
 --       //        string main = "PROJECTED COST";
 --       //        string sub = "(INCLUDE MTD ACTUAL COST IN CURRENT MONTH)";
 --       //        rng.FormulaR1C1 = main + System.Environment.NewLine + sub;
 --       //        rng.Characters[Start: main.Length + 1, Length: sub.Length + 2].Font.Size = 8;

 --       //        HelperUI.MergeLabel(_wsNonLabor, "Used", "Description", "Phase Detail");
 --       //        HelperUI.MergeLabel(_wsNonLabor, "Budgeted Phase Cost Remaining", remainingCost, "Information");
 --       //        HelperUI.MergeLabel(_wsNonLabor, "MTD Actual Cost", "MTD Actual Cost", "BATCH MTD ACTUAL");

 --       //        _wsNonLabor.get_Range("A3", Type.Missing).EntireRow.Group(Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //        _wsNonLabor.get_Range("A3", Type.Missing).EntireRow.Hidden = true;

 --       //        HelperUI.SortAscending(_wsNonLabor, "Phase Code", "Cost Type");

 --       //        HelperUI.GroupColumns(_wsNonLabor, "Parent Phase Group", null, true);
 --       //        HelperUI.GroupColumns(_wsNonLabor, "Budgeted Phase Cost Remaining", "Variance", true);

 --       //        _wsNonLabor.UsedRange.Font.Name = HelperUI.FontCalibri;

 --       //        table.HeaderRowRange.EntireRow.RowHeight = 30.00;
 --       //        table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        table.HeaderRowRange.EntireRow.WrapText = true;
 --       //        table.HeaderRowRange.EntireRow.AutoFit();

 --       //        _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].AddComment("If the phase code has no budgeted, MTD actual or projected cost, the row is hidden.  Adjust column filder to see all rows.");
 --       //        _wsNonLabor.Cells[table.HeaderRowRange.Row, table.ListColumns["Used"].Index].Comment.Shape.TextFrame.AutoSize = true;

 --       //        HelperUI.PrintPageSetup(_wsNonLabor);

 --       //        // set key fields to read-only
 --       //        _wsNonLabor.Cells.Range["A1:A3"].EntireRow.Locked = true;
 --       //        table.DataBodyRange.Locked = true;
 --       //        table.TotalsRowRange.Locked = false;
 --       //        table.ListColumns["Description"].DataBodyRange.Locked = false;
 --       //        NonLaborWritable1.Locked = false;
 --       //        NonLaborWritable2.Locked = false;
 --       //        rngHeaders.Locked = true;
 --       //        HelperUI.ProtectSheet(_wsNonLabor);

 --       //        _wsNonLabor.Tab.Color = HelperUI.DataEntryColor;

 --       //    }
 --       //    catch (Exception e) { throw new Exception("SetupNonLaborTab: " + e.Message); }
 --       //    finally
 --       //    {
 --       //        _offsetFromRemCost = 2;
 --       //        if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
 --       //    }
 --       //}


 --        //private void SetupRevTab2(Excel.Worksheet _ws)
 --       //{

 --       //    Excel.Range marginTotal = null;
 --       //    Excel.Range batchDateCreated = null;
 --       //    Excel.Range projectedContractHeader = null;
 --       //    Excel.Range projectedContract = null;
 --       //    try
 --       //    {
 --       //        Excelo.ListObject _table = Globals.Factory.GetVstoObject(_ws.ListObjects[1]);
 --       //        _ws.get_Range("A1", Type.Missing).EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);

 --       //        _ws.Cells.Range["A1"].Formula = JobGetTitle.GetTitle(JCCo, _Contract) + " Revenue Worksheet";
 --       //        _ws.Cells.Range["A1"].Font.Size = HelperUI.TwentyFontSizePageHeader;
 --       //        _ws.Cells.Range["A1"].Font.Bold = true;
 --       //        _ws.Cells.Range["A1:N1"].Merge();

 --       //        _ws.Cells.Range["A2"].Formula = "Batch Created on: ";
 --       //        _ws.Cells.Range["A2:C2"].Font.Color = HelperUI.SoftBlackHeaderFontColor;
 --       //        _ws.Cells.Range["C2"].NumberFormat = "d-mmm-yyyy h:mm AM/PM";
 --       //        _ws.Cells.Range["C2"].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        _ws.Cells.Range["C2"].Formula = revBatchDateCreated;
 --       //        _ws.Cells.Range["C2"].AddComment("All times Pacific");
 --       //        batchDateCreated = _ws.Cells.Range["A2:C2"];

 --       //        Excel.FormatCondition batchDateCreatedCond = (Excel.FormatCondition)batchDateCreated.FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
 --       //                                            Type.Missing, "=IF(" + _ws.Cells.Range["C2"].Address + "=\"\",\"\"," + _ws.Cells.Range["C2"].Address + "< TODAY())",
 --       //                                            Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //        batchDateCreatedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
 --       //        batchDateCreatedCond.Font.Color = HelperUI.WhiteFontColor;
 --       //        batchDateCreatedCond.Font.Bold = true;

 --       //        //  columns setup
 --       //        int aboveHeaders = _table.HeaderRowRange.Row - 3;
 --       //        int currContract = _table.ListColumns["Current Contract"].Index;

 --       //        projectedContract = _table.ListColumns["Projected Contract"].DataBodyRange;
 --       //        projectedContract.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
 --       //        projectedContract.Font.Color = HelperUI.WhiteFontColor;
 --       //        projectedContract.Font.Bold = true;
 --       //        projectedContract.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
 --       //        projectedContract.Borders.Weight = Excel.XlBorderWeight.xlThin;
 --       //        projectedContract.Borders.Color = HelperUI.GrayBreakDownHeaderRowColor;
 --       //        projectedContract.Borders[Excel.XlBordersIndex.xlEdgeBottom].Weight = Excel.XlBorderWeight.xlThin;
 --       //        projectedContract.Borders[Excel.XlBordersIndex.xlEdgeBottom].Color = HelperUI.GrayBreakDownHeaderRowColor;

 --       //        projectedContractHeader = _ws.Cells.Range[_ws.Cells[aboveHeaders, currContract], _ws.Cells[aboveHeaders, projectedContract.Column]];
 --       //        projectedContractHeader.Font.Color = HelperUI.WhiteFontColor;
 --       //        projectedContractHeader.Font.Bold = true;
 --       //        projectedContractHeader.Font.Size = HelperUI.TwelveFontSizeHeader;
 --       //        projectedContractHeader.Interior.Color = HelperUI.NavyBlueHeaderRowColor;
 --       //        _ws.Cells[aboveHeaders, currContract].Formula = "New Projected Contract ";
 --       //        _ws.Cells[aboveHeaders, currContract].HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //        _ws.Cells[aboveHeaders, currContract + 1].Borders[Excel.XlBordersIndex.xlEdgeRight].ColorIndex = 1;
 --       //        _ws.Cells[aboveHeaders, currContract + 1].Borders[Excel.XlBordersIndex.xlEdgeRight].Weight = Excel.XlBorderWeight.xlThin;
 --       //        _ws.Cells[aboveHeaders, projectedContract.Column].Style = HelperUI.CurrencyStyle;
 --       //        _ws.Cells[aboveHeaders, projectedContract.Column].FormulaLocal = "=SUM(" + projectedContract.Address + ")";

 --       //        _ws.UsedRange.Font.Name = HelperUI.FontCalibri;

 --       //        RevWritable2 = _table.ListColumns["Margin Seek"].DataBodyRange;
 --       //        RevWritable2.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.SoftBeige);

 --       //        _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.Interior.Color = HelperUI.DataEntryColor; //light yellow

 --       //        contJectRevenue_table.Columns["Projected Contract"].Expression = "[Current Contract] + [Unbooked Contract Adjustment]";

 --       //        // format $ columns
 --       //        _ws.Cells.get_Range("G" + _table.HeaderRowRange.Row, "M" + _table.TotalsRowRange.Row).NumberFormat = HelperUI.CurrencyFormatCondensed;
 --       //        _ws.Cells.get_Range("G" + _table.HeaderRowRange.Row, "M" + _table.TotalsRowRange.Row).Style = HelperUI.CurrencyStyle;

 --       //        contJectRevenue_table.Columns["Projected Contract Item Margin %"].Expression = "IIF([Projected Contract]<=0,0,([Projected Contract]-[Margin Seek])/[Projected Contract])";
 --       //        _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.NumberFormat = "###,##.##%";

 --       //        int col = _table.ListColumns["Projected Contract Item Margin %"].Index;
 --       //        int row = _table.TotalsRowRange.Row;
 --       //        marginTotal = _ws.Cells[row, col];
 --       //        marginTotal.FormulaLocal = "=IF(" + _table.Name + "[[#Totals],[Projected Contract]]<=0,\"0\",(" + _table.Name + "[[#Totals],[Projected Contract]]-" + _table.Name +
 --       //                                                         "[[#Totals],[Margin Seek]])/" + _table.Name + "[[#Totals],[Projected Contract]])";
 --       //        marginTotal.NumberFormat = HelperUI.PercentFormat;

 --       //        RevWritable1 = _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange;

 --       //        string[] _unbookedCol = RevWritable1.Address.Split('$');
 --       //        string[] projecteContractCol = projectedContract.Address.Split('$');
 --       //        string[] postedProjectedCostCol = _table.ListColumns["Posted Projected Cost"].DataBodyRange.Address.Split('$');
 --       //        string[] prevprojContractCol = _table.ListColumns["Previous Projected Contract"].DataBodyRange.Address.Split('$');

 --       //        for (int i = 1; i <= RevWritable1.Rows.Count; i++)
 --       //        {
 --       //            int r = _table.HeaderRowRange.Row + i;

 --       //            Excel.FormatCondition unbookedCond = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression,
 --       //                                                    Type.Missing, "=$" + projecteContractCol[1] + "$" + r + " <> $" + prevprojContractCol[1] + "$" + r, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //            unbookedCond.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.AquaBlue);

 --       //            //Alphanumerics bad entries red
 --       //            Excel.FormatCondition unbookedBad = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable1.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                                      "=ISERROR(VALUE(SUBSTITUTE($" + _unbookedCol[1] + "$" + r + ",\" \",\"\")))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //            unbookedBad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);

 --       //            Excel.FormatCondition marginSeekBad = (Excel.FormatCondition)_ws.Cells[_table.HeaderRowRange.Row + i, RevWritable2.Column].FormatConditions.Add(Excel.XlFormatConditionType.xlExpression, Type.Missing,
 --       //                                                      "=ISERROR(VALUE(SUBSTITUTE($" + _unbookedCol[1] + "$" + r + ",\" \",\"\")))", Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
 --       //            marginSeekBad.Interior.Color = HelperUI.McKColor(HelperUI.McKColors.BrightRed);
 --       //        }

 --       //        string[] applySumTotal = { "Current Contract", "Future CO", "Unbooked Contract Adjustment", "Previous Projected Contract", "Projected Contract", "Margin Seek" };

 --       //        foreach (string colName in applySumTotal)
 --       //        {
 --       //            _table.ListColumns[colName].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
 --       //        }

 --       //        _table.ListColumns["JC Dept"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        _table.ListColumns["Contract Item"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
 --       //        _table.TotalsRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;

 --       //        _table.HeaderRowRange.EntireRow.RowHeight = 30.00;
 --       //        _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;

 --       //        _table.ListColumns["PRG"].DataBodyRange.ColumnWidth = 9.00;
 --       //        _table.ListColumns["PRG Description"].DataBodyRange.ColumnWidth = 20.00;
 --       //        _table.ListColumns["JC Dept"].DataBodyRange.ColumnWidth = 19.43;
 --       //        _table.ListColumns["JC Dept Description"].DataBodyRange.ColumnWidth = 25.00;
 --       //        _table.ListColumns["Contract Item"].DataBodyRange.ColumnWidth = 12.00;
 --       //        _table.ListColumns["Description"].DataBodyRange.ColumnWidth = 25.00;
 --       //        _table.ListColumns["Future CO"].DataBodyRange.ColumnWidth = 14.75;

 --       //        _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.ColumnWidth = 16.75;
 --       //        _table.ListColumns["Current Contract"].DataBodyRange.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Previous Projected Contract"].DataBodyRange.ColumnWidth = 15.75;
 --       //        projectedContract.ColumnWidth = 15.75;
 --       //        _table.ListColumns["Posted Projected Cost"].DataBodyRange.ColumnWidth = 16.00;
 --       //        _table.ListColumns["Margin Seek"].DataBodyRange.ColumnWidth = 16.00;
 --       //        _table.ListColumns["Projected Contract Item Margin %"].DataBodyRange.ColumnWidth = 15.14;

 --       //        HelperUI.MergeLabel(_ws, "PRG", "Description", "Details");
 --       //        HelperUI.MergeLabel(_ws, "Future CO", "Unbooked Contract Adjustment", "Changes");
 --       //        HelperUI.MergeLabel(_ws, "Current Contract", "Projected Contract", "Contract");
 --       //        HelperUI.MergeLabel(_ws, "Posted Projected Cost", "Margin Seek", "Cost");
 --       //        HelperUI.MergeLabel(_ws, "Projected Contract Item Margin %", "Projected Contract Item Margin %", "Margin");

 --       //        HelperUI.AddFieldDesc(_ws, "PRG", "Project Revenue Group (Project Number) linked to the contract item");
 --       //        HelperUI.AddFieldDesc(_ws, "PRG Description", "Project Description");
 --       //        HelperUI.AddFieldDesc(_ws, "JC Dept", "Job cost department");
 --       //        HelperUI.AddFieldDesc(_ws, "JC Dept Description", "Department description");
 --       //        HelperUI.AddFieldDesc(_ws, "Contract Item", "Contract Item");
 --       //        HelperUI.AddFieldDesc(_ws, "Description", "Contract Item Description");
 --       //        HelperUI.AddFieldDesc(_ws, "Future CO", "Change orders in Viewpoint that have not been interfaced (reference only)");
 --       //        HelperUI.AddFieldDesc(_ws, "Unbooked Contract Adjustment", "Anticipated changes in contract value (include Future CO if applicable)");
 --       //        HelperUI.AddFieldDesc(_ws, "Current Contract", "Current contract value including interfaced change orders");
 --       //        HelperUI.AddFieldDesc(_ws, "Previous Projected Contract", "Projected contract item value from last revenue projection");
 --       //        HelperUI.AddFieldDesc(_ws, "Projected Contract", "Projected contract value (revenue) at contract completion");
 --       //        HelperUI.AddFieldDesc(_ws, "Posted Projected Cost", "Sum of all posted projected cost for phase codes mapping to this contract item");
 --       //        HelperUI.AddFieldDesc(_ws, "Margin Seek", "See comment");
 --       //        HelperUI.AddFieldDesc(_ws, "Projected Contract Item Margin %", "Projected contract value compared to posted projected cost or margin seek at an item level");

 --       //        _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].AddComment("Scratch pad to calculate margin adjustments. NOTE: This will not update your Cost Projections or Saved once the Revenue batch is posted");
 --       //        _ws.Cells[_table.HeaderRowRange.Row, _table.ListColumns["Margin Seek"].Index].Comment.Shape.TextFrame.AutoSize = true;

 --       //        _ws.get_Range("A4", Type.Missing).EntireRow.Group();
 --       //        _ws.get_Range("A4", Type.Missing).EntireRow.Hidden = true;

 --       //        _table.ListColumns["Previous Projected Contract"].DataBodyRange.EntireColumn.AutoFit();

 --       //        HelperUI.GroupColumns(_ws, "Margin Seek", "Margin Seek", true);

 --       //        HelperUI.PrintPageSetup(_ws);

 --       //        _table.ShowTotals = true;
 --       //        _ws.UsedRange.Locked = true;
 --       //        _table.TotalsRowRange.Locked = false;
 --       //        _table.ListColumns["Unbooked Contract Adjustment"].DataBodyRange.Locked = false;
 --       //        _table.ListColumns["Margin Seek"].DataBodyRange.Locked = false;
 --       //        HelperUI.ProtectSheet(_ws);
 --       //        _ws.Tab.Color = HelperUI.DataEntryColor;

 --       //        _table.HeaderRowRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
 --       //    }
 --       //    catch (Exception ex)
 --       //    {
 --       //        throw new Exception("SetupRevTab: " + ex.Message);
 --       //    }
 --       //    finally
 --       //    {
 --       //        //if (_table != null) Marshal.ReleaseComObject(_table);
 --       //        if (marginTotal != null) Marshal.ReleaseComObject(marginTotal);
 --       //        if (projectedContractHeader != null) Marshal.ReleaseComObject(projectedContractHeader);
 --       //        if (projectedContract != null) Marshal.ReleaseComObject(projectedContract);
 --       //        if (batchDateCreated != null) Marshal.ReleaseComObject(batchDateCreated);
 --       //    }
 --       //}
 
 
 
 
 --//private bool InsertCostProjectionsIntoJCPD()
 --       //{
 --       //    if (isInserting) return false;
 --       //    isInserting = true;
 --       //    int insertedRows = 0;
 --       //    int totalRows = 0;
 --       //    bool successInsert = false;

 --       //    object cellVal = null;
 --       //    Dictionary<string, Type> columns = null;
 --       //    DataTable dtUnpivotedProj = null;
 --       //    DataColumn Column;
 --       //    DataRow Row;
 --       //    string[] projSheetNames = { nonLaborSheet, laborSheet };
 --       //    StringBuilder sb = new StringBuilder();
 --       //    int nonlaborCount = 0;
 --       //    int laborCount = 0;
 --       //    byte costtype = 0x1;
 --       //    uint detSeq = 0;  // increments by 1 for each row

 --       //    //if (JCCo == 0)
 --       //    //{
 --       //    //    if (!Set_JCCo_Contract()) return false;
 --       //    //}
 --       //    List<int> manualETC_RowsWithValues = null;
 --       //    int visibleRows = 0;

 --       //    try
 --       //    {
 --       //        _ws = HelperUI.GetSheet(laborSheet, false);
 --       //        Excel.ListObject xltable = _ws.ListObjects[1];
 --       //        int used = xltable.ListColumns["Used"].DataBodyRange.Column;

 --       //        HelperUI.Alphanumeric_Check(xltable, "Employee ID", used);
 --       //        HelperUI.Alphanumeric_Check(xltable, "Rate", used);

 --       //        int periodStart = xltable.ListColumns["MTD Actual Hours"].DataBodyRange.Column + 1;
 --       //        int periodEnd = xltable.HeaderRowRange.Columns.Count;

 --       //        for (int i = periodStart; i <= periodEnd; i++)
 --       //        {
 --       //            HelperUI.Alphanumeric_Check(xltable, xltable.ListColumns[i].Name, used);
 --       //        }

 --       //        _ws = HelperUI.GetSheet(nonLaborSheet, false);
 --       //        xltable = _ws.ListObjects[1];
 --       //        used = xltable.ListColumns["Used"].DataBodyRange.Column;
 --       //        periodStart = xltable.ListColumns["MTD Actual Cost"].DataBodyRange.Column + 1;
 --       //        periodEnd = xltable.HeaderRowRange.Columns.Count;

 --       //        for (int i = periodStart; i <= periodEnd; i++)
 --       //        {
 --       //            HelperUI.Alphanumeric_Check(xltable, xltable.ListColumns[i].Name, used);
 --       //        }

 --       //        _ws = HelperUI.GetSheet(costSumSheet, false);
 --       //        xltable = _ws.ListObjects[1];
 --       //        used = xltable.ListColumns["Used"].DataBodyRange.Column;

 --       //        HelperUI.Alphanumeric_Check(xltable, "Manual ETC Hours", used);
 --       //        HelperUI.Alphanumeric_Check(xltable, "Manual ETC CST/HR", used);
 --       //        HelperUI.Alphanumeric_Check(xltable, "Manual ETC Cost", used);

 --       //        // Define SQL Table Schema
 --       //        DataTable dtJCPBETC = new DataTable("mckJCPBETC");
 --       //        Dictionary<string, Type> etcColumns = new Dictionary<string, Type>
 --       //                                            { {"JCCo",typeof(byte)}, {"Mth",typeof(DateTime)}, {"BatchId",typeof(uint)}, {"Job",typeof(string)}, {"DateTime",typeof(DateTime)}, {"Phase",typeof(string)},
 --       //                                            {"CostType",typeof(byte)}, {"Hours",typeof(object)}, {"Rate",typeof(object)}, {"Amount",typeof(object)} };
 --       //        // Create the table
 --       //        foreach (KeyValuePair<string, Type> c in etcColumns)
 --       //        {
 --       //            Column = new DataColumn(c.Key);
 --       //            Column.DataType = c.Value;
 --       //            dtJCPBETC.Columns.Add(Column);
 --       //        }

 --       //        ETCOverrideCount_AND_JTDActCostIsGreaterThanProjectedCost_Check(out visibleRows, out manualETC_RowsWithValues, dtJCPBETC);

 --       //        // Define SQL Table Schema
 --       //        dtUnpivotedProj = new DataTable("JCPD");
 --       //        columns = new Dictionary<string, Type>
 --       //                    { {"Co",typeof(byte)}, {"DetSeq",typeof(uint) }, {"Mth",typeof(DateTime)}, {"BatchId",typeof(uint)}, {"BatchSeq",typeof(uint)}, {"Source",typeof(string)},
 --       //                    {"JCTransType",typeof(string)}, {"TransType",typeof(char)}, {"ResTrans",typeof(uint)}, {"Job",typeof(string)}, {"PhaseGroup",typeof(byte)}, {"Phase",typeof(string)},
 --       //                    {"CostType",typeof(byte)}, {"BudgetCode",typeof(string)}, {"EMCo",typeof(byte)}, {"Equipment",typeof(string)}, {"PRCo",typeof(byte)}, {"Craft",typeof(string)},
 --       //                    {"Class",typeof(string)}, {"Employee",typeof(uint)}, {"Description",typeof(string)}, {"DetMth",typeof(DateTime)}, {"FromDate",typeof(DateTime)},
 --       //                    {"ToDate",typeof(DateTime)}, {"Quantity",typeof(decimal)}, {"Units",typeof(decimal)}, {"UM",typeof(string)}, {"UnitHours",typeof(decimal)}, {"Hours",typeof(decimal)},
 --       //                    {"Rate",typeof(decimal)}, {"UnitCost",typeof(decimal)}, {"Amount",typeof(decimal)}, {"Notes",typeof(string)} };

 --       //        // Create the table
 --       //        foreach (KeyValuePair<string, Type> c in columns)
 --       //        {
 --       //            Column = new DataColumn(c.Key);
 --       //            Column.DataType = c.Value;
 --       //            dtUnpivotedProj.Columns.Add(Column);
 --       //        }

 --       //        foreach (string sheetName in projSheetNames)
 --       //        {
 --       //            _ws = HelperUI.GetSheet(sheetName, false);

 --       //            if (_ws == null) throw new Exception("Could not find sheet containing '" + sheetName + "'");

 --       //            object[,] allRows = _ws.ListObjects[1].DataBodyRange.Value2;
 --       //            object[,] colNames = _ws.ListObjects[1].HeaderRowRange.Value2;

 --       //            string lastKeyField;

 --       //            if (sheetName == nonLaborSheet)
 --       //            {

 --       //                Pivot = "MONTH";
 --       //                lastKeyField = "Remaining Cost";
 --       //            }
 --       //            else
 --       //            {

 --       //                if (LaborPivot == "WK")
 --       //                {
 --       //                    Pivot = "WEEK";
 --       //                }
 --       //                else if (LaborPivot == "MTH")
 --       //                {
 --       //                    Pivot = "MONTH";
 --       //                }

 --       //                lastKeyField = "Phase Actual Rate";
 --       //                costtype = 0x1;
 --       //            }

 --       //            int iLastKeyField = Enumerable.Range(1, colNames.GetUpperBound(1))
 --       //                          .Where(i => (string)colNames[1, i] == lastKeyField)
 --       //                          .Select(i => i)
 --       //                          .FirstOrDefault();

 --       //            int FromDateCol;
 --       //            int totalHeaderColCount;
 --       //            int rateOffset;
 --       //            int offsetPosition;
 --       //            if (sheetName == nonLaborSheet)
 --       //            {
 --       //                rateOffset = _offsetFromRemCost;
 --       //                offsetPosition = 0;
 --       //            }
 --       //            else
 --       //            {
 --       //                rateOffset = _offsetFromPhseActRate;
 --       //                offsetPosition = 1;
 --       //            }
 --       //            totalHeaderColCount = iLastKeyField + offsetPosition;
 --       //            FromDateCol = iLastKeyField + rateOffset;

 --       //            int ToDateCol = allRows.GetUpperBound(1);
 --       //            int totalNumberOfRows = allRows.GetUpperBound(0);

 --       //            // Add rows from Excel Pivot
 --       //            for (int row = 1; row <= totalNumberOfRows; row++)
 --       //            {
 --       //                // key header fields
 --       //                byte phseGroup;
 --       //                uint batchSeq;
 --       //                string phase = null;
 --       //                string description = null;
 --       //                decimal rate = 0;
 --       //                object employee = null;

 --       //                // unpivot and fill DataTable from user input and default values
 --       //                for (int colAmt = FromDateCol; colAmt <= ToDateCol; colAmt++)
 --       //                {
 --       //                    decimal amt;
 --       //                    Decimal.TryParse(allRows[row, colAmt]?.ToString(), out amt);

 --       //                    if (amt != 0)
 --       //                    {
 --       //                        Row = dtUnpivotedProj.NewRow();

 --       //                        // populate header row data into SQL-like table
 --       //                        for (int col = 1; col <= totalHeaderColCount; col++)
 --       //                        {
 --       //                            string colName = (string)colNames[1, col];

 --       //                            if ((columns.ContainsKey(colName)) || colName == "Cost Type" || colName == "Phase Code" || colName == "Employee ID")
 --       //                            {
 --       //                                cellVal = allRows[row, col] ?? DBNull.Value;
 --       //                                switch (colName)
 --       //                                {
 --       //                                    case "Phase Code":
 --       //                                        phase = cellVal.ToString();
 --       //                                        colName = "Phase";
 --       //                                        break;
 --       //                                    case "Cost Type":
 --       //                                        switch (cellVal.ToString())
 --       //                                        {
 --       //                                            case "L":
 --       //                                                costtype = 0x1;
 --       //                                                break;
 --       //                                            case "M":
 --       //                                                costtype = 0x2;
 --       //                                                break;
 --       //                                            case "S":
 --       //                                                costtype = 0x3;
 --       //                                                break;
 --       //                                            case "O":
 --       //                                                costtype = 0x4;
 --       //                                                break;
 --       //                                            case "E":
 --       //                                                costtype = 0x5;
 --       //                                                break;
 --       //                                        }
 --       //                                        colName = "CostType";
 --       //                                        cellVal = costtype;

 --       //                                        break;
 --       //                                    case "Employee ID":
 --       //                                        uint id;

 --       //                                        if (UInt32.TryParse(cellVal?.ToString(), out id))
 --       //                                        {
 --       //                                            employee = id;
 --       //                                        }
 --       //                                        else
 --       //                                        {
 --       //                                            employee = DBNull.Value;
 --       //                                        }
 --       //                                        colName = "Employee";
 --       //                                        break;
 --       //                                    case "Description":
 --       //                                        description = cellVal.ToString();
 --       //                                        break;
 --       //                                    case "Rate":
 --       //                                        Decimal.TryParse(allRows[row, FromDateCol - rateOffset + offsetPosition]?.ToString(), out rate);
 --       //                                        break;
 --       //                                }
 --       //                                Row[colName] = cellVal;

 --       //                            }
 --       //                        }

 --       //                        // query SQL for BatchSeq & PhaseGroup
 --       //                        object[] tblBatchSeqPhaseGroup = HelperData.GetBatchSeqPhaseGroup(JCCo, Month, Job, CostBatchId, phase, costtype);

 --       //                        batchSeq = Convert.ToUInt32(tblBatchSeqPhaseGroup[0]);
 --       //                        phseGroup = Convert.ToByte(tblBatchSeqPhaseGroup[1]);
 --       //                        Row["Co"] = JCCo;
 --       //                        Row["DetSeq"] = ++detSeq;
 --       //                        Row["Mth"] = Month; // DateTime.FromOADate((double)Month).ToShortDateString(); // Excel converts DateTime to Decimmal, we must revert to DB type

 --       //                        DateTime ToDate = DateTime.Parse(colNames[1, colAmt]?.ToString());
 --       //                        DateTime FromDate = DateTime.Now;
 --       //                        DateTime DetMth = DateTime.Now;

 --       //                        Row["BatchId"] = CostBatchId;
 --       //                        Row["BatchSeq"] = batchSeq;
 --       //                        Row["Source"] = "JC Projctn";
 --       //                        Row["TransType"] = "A";
 --       //                        Row["JCTransType"] = "PB";
 --       //                        Row["ResTrans"] = DBNull.Value;
 --       //                        Row["Job"] = Job;
 --       //                        Row["PhaseGroup"] = phseGroup;
 --       //                        Row["Phase"] = phase;
 --       //                        Row["CostType"] = costtype;
 --       //                        Row["BudgetCode"] = DBNull.Value;
 --       //                        Row["EMCo"] = DBNull.Value;
 --       //                        Row["Equipment"] = DBNull.Value;
 --       //                        Row["PRCo"] = JCCo;
 --       //                        Row["Craft"] = DBNull.Value;
 --       //                        Row["Class"] = DBNull.Value;
 --       //                        switch (Pivot)
 --       //                        {
 --       //                            case "MONTH":
 --       //                                //ToDate = new DateTime(FromDate.Year, FromDate.Month, DateTime.DaysInMonth(FromDate.Year, FromDate.Month));
 --       //                                FromDate = new DateTime(ToDate.Year, ToDate.Month, 1);
 --       //                                Row["FromDate"] = FromDate;
 --       //                                Row["ToDate"] = ToDate;
 --       //                                break;
 --       //                            case "WEEK":
 --       //                                FromDate = ToDate.AddDays(-6);
 --       //                                Row["FromDate"] = FromDate;
 --       //                                Row["ToDate"] = ToDate;
 --       //                                break;
 --       //                        }

 --       //                        switch (sheetName)
 --       //                        {
 --       //                            case nonLaborSheet:
 --       //                                Row["UM"] = "LS";
 --       //                                Row["Hours"] = DBNull.Value;
 --       //                                Row["Rate"] = DBNull.Value;
 --       //                                Row["Amount"] = amt;
 --       //                                Row["Employee"] = DBNull.Value;
 --       //                                break;
 --       //                            case laborSheet:
 --       //                                Row["UM"] = "HRS";
 --       //                                Row["Hours"] = amt; //this is really 'hours'
 --       //                                Row["Amount"] = amt * rate;
 --       //                                Row["Employee"] = employee;
 --       //                                break;
 --       //                        }

 --       //                        Row["DetMth"] = new DateTime(ToDate.Year, ToDate.Month, 1);
 --       //                        Row["Quantity"] = DBNull.Value;
 --       //                        Row["Units"] = DBNull.Value;

 --       //                        Row["UnitHours"] = DBNull.Value;

 --       //                        Row["UnitCost"] = DBNull.Value;

 --       //                        Row["Notes"] = @"";
 --       //                        dtUnpivotedProj.Rows.Add(Row);
 --       //                    }
 --       //                    // no amount; skip, don't add row
 --       //                }
 --       //            }
 --       //            if (sheetName == nonLaborSheet)
 --       //            {
 --       //                nonlaborCount = dtUnpivotedProj.Rows.Count;
 --       //            }
 --       //            else
 --       //            {
 --       //                laborCount = dtUnpivotedProj.Rows.Count - nonlaborCount;
 --       //            }
 --       //        }

 --       //        if (dtUnpivotedProj.Rows.Count > 0)
 --       //        {
 --       //            totalRows = nonlaborCount + laborCount;

 --       //            try
 --       //            {
 --       //                insertedRows = InsertCostBatchNonLaborJCPD.InsCostJCPD(JCCo, Month, CostBatchId, dtUnpivotedProj);
 --       //                successInsert = insertedRows == totalRows;
 --       //            }
 --       //            catch (Exception ex)
 --       //            {
 --       //                sb.Append(ex.Message);
 --       //            }
 --       //        }
 --       //        //Fix to allow removing of all detail rows after they are cleared from the worksheet
 --       //        else
 --       //        {
 --       //            int olddeleted;
 --       //            // batch already in JCPD; delete and re-insert batch with new values
 --       //            DeleteBatchJCPD.DeleteBatchFromJCPD(JCCo, Month, costBatchId, out detSeq, out olddeleted);
 --       //        }

 --       //        if (insertedRows != totalRows) { throw new Exception("Cost Projection was NOT saved, please retry.  If problem persists contact support."); }

 --       //        UpdateJCPBwithSumData(manualETC_RowsWithValues.Count, visibleRows, dtJCPBETC, insertedRows);

 --       //        if (btnFetchData.Text == "Saved")
 --       //        {
 --       //            sb.Append("Cost Projection Successfully Saved.");

 --       //            string job = HelperUI.JobTrimDash(Job);
 --       //            _control_ws.Names.Item("LastSave_" + job).RefersToRange.Value = HelperUI.DateTimeShortAMPM;
 --       //            _control_ws.Names.Item("SaveUser_" + job).RefersToRange.Value = Login;
 --       //        }

 --       //        MessageBox.Show(sb.ToString());
 --       //        dtUnpivotedProj.Clear();
 --       //        return true;
 --       //        // FOR TESTING ONLY simulate SQl DataTable to Excel
 --       //        //string sheet_name = String.Format("Projections_{0}_TEST", Job.Replace("-", "_"));
 --       //        //Excel.Worksheet _ws = HelperUI.AddSheet(workbook, sheet_name, workbook.ActiveSheet);
 --       //        //SheetBuilder.BuildGenericTable(_ws, dtUnpivotedProj);
 --       //    }
 --       //    catch (Exception ex)
 --       //    {
 --       //        if (manualETC_RowsWithValues != null)
 --       //        {
 --       //            LogProphecyAction.InsProphecyLog(Login, 17, JCCo, _Contract, Job, Month, CostBatchId, getEvilFunctionProd(ex), "OVR: " + manualETC_RowsWithValues.Count + " of " + visibleRows);
 --       //        }
 --       //        else
 --       //        {
 --       //            LogProphecyAction.InsProphecyLog(Login, 17, JCCo, _Contract, Job, Month, CostBatchId, getEvilFunctionProd(ex));
 --       //        }
 --       //        throw;
 --       //    }
 --       //    finally
 --       //    {
 --       //        if (_ws != null) Marshal.ReleaseComObject(_ws);
 --       //        cellVal = null;
 --       //        columns?.Clear();
 --       //        columns = null;
 --       //        dtUnpivotedProj?.Clear();
 --       //        dtUnpivotedProj = null;
 --       //        Column = null;
 --       //        Row = null;
 --       //        sb.Clear();
 --       //        manualETC_RowsWithValues?.Clear();
 --       //        manualETC_RowsWithValues = null;
 --       //    }
 --       //}