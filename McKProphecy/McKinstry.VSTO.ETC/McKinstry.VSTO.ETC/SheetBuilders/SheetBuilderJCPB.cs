using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Windows.Forms;
using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
//using Mckinstry.VSTO;
using System.Runtime.InteropServices;
using System.Reflection;
using System.Diagnostics;

namespace McKinstry.ETC.Template
{
    public static class SheetBuilderJCPB
    {
        public static void BuildTable(Excel.Worksheet sheet, DataTable table, int LastCellOffsetStartRow = 3)
        {
            int _row = sheet.UsedRange.SpecialCells(Microsoft.Office.Interop.Excel.XlCellType.xlCellTypeLastCell).Row;
            int startRow = _row + LastCellOffsetStartRow;
            int startCol = 1;
            Excel.Range rngExcel = null;

            try
            {
                Excel.Range _rng = (Excel.Range)sheet.Range[sheet.Cells[startRow, 1], sheet.Cells[startRow + table.Rows.Count, table.Columns.Count]];

                Excel.ListObject listObject = HelperUI.FormatAsTable(_rng, "tbl" + table.TableName); 

                for (int col = 0; col < table.Columns.Count; col++)
                {
                    string colType = table.Columns[col].DataType.Name;
                    string colName = table.Columns[col].ColumnName;

                    if (colName != "Manual ETC Hours" /*&& colName != "Manual ETC CST/HR"*/ && colName != "Manual ETC Cost")
                    {
                        switch (colType)
                        {
                            case "Double":
                                listObject.ListColumns[col + 1].DataBodyRange.Style = HelperUI.CurrencyStyle;
                                listObject.ListColumns[col + 1].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                                listObject.ListColumns[col + 1].Total.Style = HelperUI.CurrencyStyle;
                                break;
                            case "Decimal":
                                listObject.ListColumns[col + 1].DataBodyRange.Style = HelperUI.CurrencyStyle;
                                listObject.ListColumns[col + 1].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                                listObject.ListColumns[col + 1].Total.Style = HelperUI.CurrencyStyle;
                                break;
                            case "UInt64":
                                listObject.ListColumns[col + 1].DataBodyRange.Style = HelperUI.CurrencyStyle;
                                listObject.ListColumns[col + 1].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                                listObject.ListColumns[col + 1].Total.Style = HelperUI.CurrencyStyle;
                                break;
                            case "DateTime":
                                listObject.ListColumns[col + 1].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                                break;
                            case "TimeSpan":
                                listObject.ListColumns[col + 1].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                                listObject.ListColumns[col + 1].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationNone;
                                listObject.ListColumns[col + 1].Total.NumberFormat = HelperUI.DateFormatMMDDYY;
                                break;
                            default:
                                break;
                        }
                    }

                    int totalRows = table.Rows.Count;
                    if (totalRows == 0) return;

                   
                    //if (colName == "Batch MTD Actual Cost")
                    //{
                    //    colName = "Batch" + Char(13) + ;
                    //}

                    sheet.Cells[startRow, startCol + col].Value = colName;
                    string[,] clnDataString;
                    object[,] clnDataDecimal;
                    object[,] clnDataObject;
                    int[,] clnDataInt;

                    rngExcel = sheet.Cells[(startRow + 1), col + 1];
                    rngExcel = rngExcel.get_Resize(totalRows, 1);

                    if (colName == "Manual ETC Hours" || /*colName == "Manual ETC CST/HR" ||*/ colName == "Manual ETC Cost")
                    {
                        clnDataObject = new object[totalRows, 1];
                        for (int row = 0; row < totalRows; row++)
                        {
                            var value = table.Rows[row][col];
                            if (value != DBNull.Value)
                            {
                                clnDataObject[row, 0] = Convert.ToDouble(value);
                            }
                            else clnDataObject[row, 0] = "";
                        }
                        rngExcel.set_Value(Missing.Value, clnDataObject);
                        //break;
                    }
                    else
                    {
                        switch (colType)
                        {
                            case "Decimal":
                                clnDataDecimal = new object[totalRows, 1];
                                for (int row = 0; row < totalRows; row++)
                                {
                                    var value = table.Rows[row][col];
                                    if (value != DBNull.Value)
                                    {
                                        clnDataDecimal[row, 0] = Convert.ToDecimal(value);
                                    }
                                    //else clnDataDouble[row, 0] = "";
                                }
                                rngExcel.set_Value(Missing.Value, clnDataDecimal);
                                break;
                            case "Int32":
                                if (colName == "Employee ID") goto default;

                                clnDataInt = new int[totalRows, 1];
                                for (int row = 0; row < totalRows; row++)
                                {
                                    var value = table.Rows[row][col];
                                    if (value != DBNull.Value)
                                    {
                                        clnDataInt[row, 0] = Convert.ToInt32(value);
                                    }
                                }
                                rngExcel.set_Value(Missing.Value, clnDataInt);
                                break;
                            case "String":
                                clnDataString = new string[totalRows, 1];
                                for (int row = 0; row < totalRows; row++)
                                {
                                    clnDataString[row, 0] = table.Rows[row][col].ToString();
                                }
                                rngExcel.set_Value(Missing.Value, clnDataString);
                                break;

                            default:
                                clnDataString = new string[totalRows, 1];
                                for (int row = 0; row < totalRows; row++)
                                {
                                    clnDataString[row, 0] = table.Rows[row][col].ToString();
                                }
                                rngExcel.set_Value(Missing.Value, clnDataString);
                                break;
                        }
                    }
                }

                //string colName;
                //int totalRows = table.Rows.Count;

                //for (int col = 0; col < table.Columns.Count; col++)
                //{

                //}
            }
            catch (Exception) { throw; }
        }
    }

}
