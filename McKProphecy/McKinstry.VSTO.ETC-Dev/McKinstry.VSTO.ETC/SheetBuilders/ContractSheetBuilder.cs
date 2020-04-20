using Mckinstry.VSTO;
using System;
using System.Data;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKinstry.ETC.Template
{
    public static class ContractSheetBuilder
    {
        public static Excel.Worksheet BuildContractHeader(Excel.Worksheet sheet, DataTable contractHeader)
        {

            try
            {
                sheet.Cells[4,2].Value = contractHeader.Columns[0].ColumnName;
                sheet.Cells[5,2].Value = contractHeader.Rows[0].Field<byte>("JCCo").ToString();

                sheet.Cells[4,3].Value = contractHeader.Columns[1].ColumnName;
                sheet.Names.Add("hdrContractNumber", sheet.Cells[5,3]);
                sheet.Range["hdrContractNumber"].Value = contractHeader.Rows[0].Field<string>("Contract");

                sheet.Cells[4,4].Value = contractHeader.Columns[2].ColumnName;
                sheet.Cells[5,4].Value = contractHeader.Rows[0].Field<string>("ContractDescription");

                Excel.Range _tmpRange = sheet.Range[sheet.Cells[4,2], sheet.Cells[4,4]];
                _tmpRange.Font.Bold = false;
                _tmpRange.Font.Italic = true;
                _tmpRange.Font.Size = 11;
                _tmpRange.Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue70);
                _tmpRange.Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
                _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;

                _tmpRange = sheet.Range[sheet.Cells[4, 2], sheet.Cells[5, 4]];
                _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
                _tmpRange.Font.Bold = true;
                _tmpRange.Font.Size = 12;
                _tmpRange.EntireColumn.AutoFit();

                _tmpRange = sheet.Range[sheet.Cells[4, 2], sheet.Cells[5, 4]];
                _tmpRange.EntireColumn.AutoFit();

                sheet.Cells[1, 1].Select();

                return sheet;

            }
            catch (Exception e)
            {
                throw new Exception("BuildContractHeader: Error Writing UserProfile to Control Sheet", e);
            }
        }

        public static int BuildContractItemTable(Excel.Worksheet sheet, DataTable contractItems)
        {
            int _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;
            int startRow;
            int startCol;

            startRow = _row + 3;


            Excel.Range _tmpRange = sheet.Range[sheet.Cells[startRow, 2], sheet.Cells[startRow, 2+ contractItems.Columns.Count-1]];

            _tmpRange.Merge(true);
            sheet.Names.Add("hdrContractItemLbl", _tmpRange);
            _tmpRange.Value = "Contract Items";
            _tmpRange.Font.Bold = true;
            _tmpRange.Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue);
            _tmpRange.Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
            _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;

            _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;

            startRow = startRow + 1;
            startCol = 2;


            for (int col = 0; col < contractItems.Columns.Count; col++)
            {
                sheet.Cells[startRow, startCol + col].Value = contractItems.Columns[col].ColumnName;
            }

            startRow = startRow + 1;
            startCol = 2;

            for (int row = 0; row < contractItems.Rows.Count; row++)
            {
                for (int col = 0; col < contractItems.Columns.Count; col++)
                {
                    sheet.Cells[startRow + row, startCol + col].Value = contractItems.Rows[row][col].ToString();
                }
            }

            Excel.Range contract_item_rng = (Excel.Range)sheet.Range[sheet.Cells[startRow-1, 2], sheet.Cells[startRow -1 + contractItems.Rows.Count, 2 + contractItems.Columns.Count - 1]];

            Excel.ListObject contractListObject = HelperUI.FormatAsTable(contract_item_rng, string.Format("tbl{0}", contractItems.TableName), "McKinstry Table Style"); // "TableStyleMedium15"

            contractListObject.ListColumns["OrigContractAmt"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["ContractAmt"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["BilledAmt"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["ReceivedAmt"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["CurrentRetainAmt"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;

            contractListObject.ShowTotals = true;

            contractListObject.ListColumns["OrigContractAmt"].Total.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["ContractAmt"].Total.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["BilledAmt"].Total.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["ReceivedAmt"].Total.NumberFormat = HelperUI.CurrencyFormat;
            contractListObject.ListColumns["CurrentRetainAmt"].Total.NumberFormat = HelperUI.CurrencyFormat;

            contractListObject.ListColumns["OrigContractAmt"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            contractListObject.ListColumns["ContractAmt"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            contractListObject.ListColumns["BilledAmt"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            contractListObject.ListColumns["ReceivedAmt"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            contractListObject.ListColumns["CurrentRetainAmt"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;


            contractListObject.HeaderRowRange.EntireColumn.AutoFit();

            contract_item_rng = contractListObject.Range;
            contract_item_rng.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            contract_item_rng.Font.Size = 9;

            _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;

            sheet.Cells[4, 6].Value2 = string.Format("=tbl{0}[[#Headers],[OrigContractAmt]]", contractItems.TableName);
            sheet.Cells[5, 6].Value2 = string.Format("=tbl{0}[[#Totals],[OrigContractAmt]]", contractItems.TableName);
            sheet.Cells[5, 6].NumberFormat = HelperUI.CurrencyFormat;

            sheet.Cells[4, 7].Value2 = string.Format("=tbl{0}[[#Headers],[ContractAmt]]", contractItems.TableName);
            sheet.Cells[5, 7].Value2 = string.Format("=tbl{0}[[#Totals],[ContractAmt]]", contractItems.TableName);

            sheet.Cells[5, 7].NumberFormat = HelperUI.CurrencyFormat;

            _tmpRange = sheet.Range[sheet.Cells[4, 6], sheet.Cells[4, 7]];
            _tmpRange.Font.Size = 10;
            _tmpRange.Font.Bold = true;
            _tmpRange.Font.Italic = true;
            _tmpRange.Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue);
            _tmpRange.Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);

            _tmpRange = sheet.Range[sheet.Cells[4, 6], sheet.Cells[5, 7]];
            _tmpRange.HorizontalAlignment = Microsoft.Office.Interop.Excel.XlHAlign.xlHAlignRight;
            _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;

            sheet.Cells[1, 1].Select();

            return _row;

        }

        public static int BuildProjectsTable(Excel.Worksheet sheet, DataTable contractProjects)
        {
            int _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;
            int startRow;
            int startCol;

            startRow = _row + 3;

            Excel.Range _tmpRange = sheet.Range[sheet.Cells[startRow, 2], sheet.Cells[startRow, 2 + contractProjects.Columns.Count-1]];

            _tmpRange.Merge(true);
            sheet.Names.Add("hdrContractProjectsLbl", _tmpRange);
            _tmpRange.Value = "Associated Projects";
            _tmpRange.Font.Bold = true;
            _tmpRange.Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue);
            _tmpRange.Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);
            _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;

            _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;

            startRow = startRow + 1;
            startCol = 2;

            for (int col = 0; col < contractProjects.Columns.Count; col++)
            {
                sheet.Cells[startRow, startCol + col].Value = contractProjects.Columns[col].ColumnName;
            }

            startRow = startRow + 1;
            startCol = 2;

            for (int row = 0; row < contractProjects.Rows.Count; row++)
            {
                for (int col = 0; col < contractProjects.Columns.Count; col++)
                {
                    sheet.Cells[startRow + row, startCol + col].Value = contractProjects.Rows[row][col].ToString();
                }
            }

            Excel.Range project_rng = (Excel.Range)sheet.Range[sheet.Cells[startRow - 1, 2], sheet.Cells[startRow - 1 + contractProjects.Rows.Count, 2 + contractProjects.Columns.Count - 1]];
            
            Excel.ListObject projectListObject = HelperUI.FormatAsTable(project_rng, string.Format("tbl{0}", contractProjects.TableName), "McKinstry Table Style"); // "TableStyleMedium15"

            projectListObject.ListColumns["OrigCost"].DataBodyRange.NumberFormat = HelperUI.CurrencyFormat;
            projectListObject.ListColumns["OrigHours"].DataBodyRange.NumberFormat = "#,##0.00";
            projectListObject.ListColumns["OrigUnits"].DataBodyRange.NumberFormat = "#,##0.00";

            projectListObject.ShowTotals = true;

            projectListObject.ListColumns["OrigCost"].Total.NumberFormat = HelperUI.CurrencyFormat;
            projectListObject.ListColumns["OrigHours"].Total.NumberFormat = "#,##0.00";
            projectListObject.ListColumns["OrigUnits"].Total.NumberFormat = "#,##0.00";

            projectListObject.ListColumns["OrigCost"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            projectListObject.ListColumns["OrigHours"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            projectListObject.ListColumns["OrigUnits"].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
            projectListObject.HeaderRowRange.EntireColumn.AutoFit();

            project_rng = projectListObject.Range;
            project_rng.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;
            project_rng.Font.Size = 9;

            Excel.Worksheet curSheet = sheet;

            sheet.Cells[4, 8].Value2 = string.Format("=tbl{0}[[#Headers],[OrigCost]]", contractProjects.TableName);
            sheet.Cells[5, 8].Value2 = string.Format("=tbl{0}[[#Totals],[OrigCost]]", contractProjects.TableName);
            sheet.Cells[5, 8].NumberFormat = HelperUI.CurrencyFormat;

            _tmpRange = sheet.Range[sheet.Cells[4, 8], sheet.Cells[4, 8]];
            _tmpRange.Font.Size = 10;
            _tmpRange.Font.Bold = true;
            _tmpRange.Font.Italic = true;
            _tmpRange.Interior.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.Blue);
            _tmpRange.Font.Color = HelperUI.McKinstryColor(HelperUI.McKinstrColors.White);

            _tmpRange = sheet.Range[sheet.Cells[4, 8], sheet.Cells[5, 8]];
            _tmpRange.HorizontalAlignment = Microsoft.Office.Interop.Excel.XlHAlign.xlHAlignRight;
            _tmpRange.Borders.LineStyle = Excel.XlLineStyle.xlContinuous;

            sheet.Cells[1, 1].Select();

            return _row;

        }

        public static void FormatContractHeader(Excel.ListObject list)
        {

            foreach ( Excel.Range cell in list.HeaderRowRange )
            {
                string cellVal = cell.Value;

                Console.WriteLine(cellVal);

                switch ( cellVal )
                {
                    case "JCCo":
                        break;
                    case "Contract":
                        break;
                    default:
                        break;

                }
            }

        }
    }

}
