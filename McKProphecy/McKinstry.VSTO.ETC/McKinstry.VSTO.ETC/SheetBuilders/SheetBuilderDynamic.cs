using System;
using System.Data;
using Excel = Microsoft.Office.Interop.Excel;
using McKinstry.Data.Models.Viewpoint;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Linq;

namespace McKinstry.ETC.Template
{
    public static class SheetBuilderDynamic
    {
        /// <summary>
        /// Builds an Excel Table from a List of dynamic Expando Objects. 
        /// Columns are added dynamically to Expand Objects from SqlDataReader which means we don't have to specify them before hand.
        /// </summary>
        /// <param name="ws">Excel worksheet to place the Excel ListOject (table)</param>
        /// <param name="table">ExpandObject List of Key Value pairs of Field names and sub KV(field value, datatype)</param>
        /// <param name="tableName">Name to assign the Excel Table</param>
        /// <param name="LastCellOffsetStartRow">Row to start the table at in worksheet</param>
        //public static void BuildTable_(Excel.Worksheet ws, List<dynamic> table, string tableName, int LastCellOffsetStartRow = 3)
        //{
        //    if (table.Count == 0) return;

        //    int _row = ws.UsedRange.SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
        //    int headerRow = _row + LastCellOffsetStartRow;
        //    int totalRows = table.Count;
        //    Excel.Range _rng = null;
        //    Excel.Range _rng2 = null;
        //    Excel.ListObject listObject = null;

        //    try
        //    {
        //        IDictionary<string, object> fields = table[0];

        //        // format worksheet header section
        //        _rng  = ws.Cells[headerRow-2, 1];
        //        _rng2 = ws.Cells[headerRow-2, fields.Keys.Count];
        //        _rng  = ws.get_Range(_rng, _rng2);
        //        _rng.Interior.Color         = HelperUI.LightGrayHeaderRowColor;
        //        _rng.NumberFormat           = HelperUI.GeneralFormat;
        //        _rng.HorizontalAlignment    = Excel.XlHAlign.xlHAlignCenter;
        //        _rng.EntireRow.RowHeight    = 30;
        //        _rng.Font.Color             = HelperUI.WhiteDownHeaderFontColor;
        //        _rng.Font.Size              = HelperUI.FourteenBreakDownHeaderFontSize;

        //        ws.get_Range("A3").EntireRow.Group();
        //        ws.get_Range("A3").EntireRow.Hidden = true;

        //        // set table header column names
        //        _rng = ws.Cells[headerRow, 1];
        //        _rng2 = ws.Cells[headerRow + totalRows, fields.Keys.Count];
        //        _rng = ws.get_Range(_rng, _rng2);

        //        listObject = HelperUI.FormatAsTable(_rng, "tbl" + tableName);

        //        // get any one of the rows
        //        IDictionary<string, Object> any_row = table.First();

        //        // format table columns based on data types
        //        uint col = 1;
        //        foreach (KeyValuePair<string, object> _field in any_row) // Column name, (datatype, value)
        //        {
        //            KeyValuePair<string, object> value_datatype = (KeyValuePair<string, object>)_field.Value;

        //            if (value_datatype.Key == "Decimal") 
        //            {
        //                listObject.ListColumns[col].DataBodyRange.Style = HelperUI.CurrencyStyle;
        //                listObject.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
        //                listObject.ListColumns[col].Total.Style = HelperUI.CurrencyStyle;
        //            }
        //            else if (value_datatype.Key == "DateTime")
        //            {
        //                listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
        //            }
        //            ++col;
        //        }

        //        // set field values
        //        col = 0;
        //        _row = 0;
        //        foreach (IDictionary<string, Object> row_kv in table) // loop list
        //        {
        //            ++_row;
        //            foreach (KeyValuePair<string, object> _field in row_kv) // loop expando object -> Column name, (datatype, value)
        //            {
        //                ++col;

        //                ws.Cells[headerRow, col].Value = _field.Key; // column name

        //                KeyValuePair<string, object> value_datatype = (KeyValuePair<string, object>)_field.Value;

        //                ws.Cells[headerRow + _row, col].Value = value_datatype.Value; // field value

        //            }
        //            col = 0;
        //        }
        //    }
        //    catch (Exception) { throw; }
        //    finally
        //    {
        //        if (listObject != null) Marshal.ReleaseComObject(listObject); listObject = null;
        //        if (_rng != null) Marshal.ReleaseComObject(_rng); _rng = null;
        //        if (_rng2 != null) Marshal.ReleaseComObject(_rng2); _rng2 = null;
        //    }
        //}

        public static void BuildTable(Excel.Worksheet ws, List<dynamic> table, string tableName, int LastCellOffsetStartRow = 3)
        {
            if (table.Count == 0) return;

            int _row = ws.UsedRange.SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
            int headerRow = _row + LastCellOffsetStartRow;
            int totalRows = table.Count;
            Excel.Range _rng = null;
            Excel.Range _rng2 = null;
            Excel.ListObject listObject = null;
            Excel.Range headers = null;

            try
            {
                // get any one of the rows
                IDictionary<string, Object> any_row = table.First();

                // format worksheet header section
                _rng = ws.Cells[headerRow - 2, 1];
                _rng2 = ws.Cells[headerRow - 2, any_row.Count];
                _rng = ws.get_Range(_rng, _rng2);
                _rng.Interior.Color = HelperUI.LightGrayHeaderRowColor;
                _rng.NumberFormat = HelperUI.GeneralFormat;
                _rng.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                _rng.EntireRow.RowHeight = 30;
                _rng.Font.Color = HelperUI.WhiteDownHeaderFontColor;
                _rng.Font.Size = HelperUI.FourteenBreakDownHeaderFontSize;

                ws.get_Range("A3").EntireRow.Group();
                ws.get_Range("A3").EntireRow.Hidden = true;

                // get table range
                _rng = ws.Cells[headerRow, 1];
                _rng2 = ws.Cells[headerRow + totalRows, any_row.Count];
                _rng = ws.get_Range(_rng, _rng2);

                // convert range to table
                listObject = HelperUI.FormatAsTable(_rng, "tbl" + tableName);

                // format table columns based on data types
                uint col = 1;
                foreach (KeyValuePair<string, object> _field in any_row) // column name, (datatype, value)
                {
                    KeyValuePair<string, object> datatype_value = (KeyValuePair<string, object>)_field.Value;

                    if (datatype_value.Key == "Decimal")
                    {
                        listObject.ListColumns[col].DataBodyRange.Style = HelperUI.CurrencyStyle;
                        listObject.ListColumns[col].TotalsCalculation = Excel.XlTotalsCalculation.xlTotalsCalculationSum;
                        listObject.ListColumns[col].Total.Style = HelperUI.CurrencyStyle;
                    }
                    else if (datatype_value.Key == "DateTime")
                    {
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                    }
                    ++col;
                }

                // prep COLUMN NAMES to insert into table headers (avoids slowly setting cell-by-cell)
                var _columns =  any_row.Select(column => column.Key).ToArray();

                object[,] columns = new object[1, _columns.Length];

                for (int i = 0; i <= _columns.Length-1; i++)
                {
                    columns[0, i] = _columns[i];
                }

                // get Excel table header range
                _rng = ws.Cells[headerRow, 1];
                _rng2 = ws.Cells[headerRow, any_row.Count];
                headers = ws.get_Range(_rng, _rng2);

                // set COLUMN headers in 1 atomic operation (fast!)
                headers.set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, columns);

                // prep ROWS to insert into table body
                object[,] rows = new object[totalRows, _columns.Length];

                // put all field values into array
                col = 0;
                _row = 0;
                foreach (IDictionary<string, Object> row_kv in table) // loop list
                {
                    foreach (KeyValuePair<string, object> _field in row_kv) // loop expando object -> column name, (datatype, value)
                    {
                        rows[_row, col] = ((KeyValuePair<string, object>)_field.Value).Value; // field value
                        ++col;
                    }
                    col = 0;
                    ++_row;
                }

                // set column name headers in Excel table in 1 atomic operation (fast!)
                listObject.DataBodyRange.set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, rows);
            }
            catch (Exception) { throw; }
            finally
            {
                if (listObject != null) Marshal.ReleaseComObject(listObject); listObject = null;
                if (_rng != null) Marshal.ReleaseComObject(_rng); _rng = null;
                if (_rng2 != null) Marshal.ReleaseComObject(_rng2); _rng2 = null;
                if (headers != null) Marshal.ReleaseComObject(headers); headers = null;
            }
        }
    }
}
