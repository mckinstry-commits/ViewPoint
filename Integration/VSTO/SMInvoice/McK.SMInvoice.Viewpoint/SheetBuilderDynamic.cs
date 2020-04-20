using System;
using System.Data;
using Excel = Microsoft.Office.Interop.Excel;
using System.Reflection;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Linq;

namespace McK.SMInvoice.Viewpoint
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
        /// <param name="offsetFromLastUsedCell">Row to start the table at in worksheet</param>
        public static Excel.ListObject BuildTable(Excel.Worksheet ws, List<dynamic> table, string tableName, int offsetFromLastUsedCell = 3, bool showTotals = true, bool bandedRows = false, int headerRow = 0)

        {
            if (table.Count == 0) return null;
            int totalRows = table.Count;

            int _row = 0;

            if (headerRow == 0)
            {
                _row = ws.UsedRange.SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
                headerRow = _row + offsetFromLastUsedCell;
            }

            Excel.Range _rng = null;
            Excel.Range _rng2 = null;
            Excel.ListObject listObject = null;
            Excel.Range headers = null;

            try
            {
                // get any one of the rows
                IDictionary<string, Object> any_row = table.First();

                // set table header column names
                _rng  = ws.Cells[headerRow, 1];
                _rng2 = ws.Cells[headerRow + totalRows, any_row.Count];
                _rng  = ws.get_Range(_rng, _rng2);

                listObject = HelperUI.FormatAsTable(_rng, tableName, showTotals: showTotals, bandedRows: bandedRows);
                listObject.ShowTotals = false;

                // format table columns based on data types
                uint col = 1;
                foreach (KeyValuePair<string, object> _field in any_row) 
                {
                    KeyValuePair <string, object> datatype_value = (KeyValuePair<string, object>)_field.Value; // (datatype, value)

                    if (datatype_value.Key == "System.String" || datatype_value.Key == "System.Double" || datatype_value.Key == "System.Byte" || _field.Key == "Work Orders")
                    {
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.StringFormat;
                        listObject.ListColumns[col].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    }
                    else if (datatype_value.Key == "System.Decimal")
                    {
                        listObject.ListColumns[col].DataBodyRange.Style = "Comma";//  HelperUI.CurrencyStyle;
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.AccountingNoSign;
                    }
                    else if (datatype_value.Key == "System.DateTime")
                    {
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                        listObject.ListColumns[col].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    }
                    ++col;
                }

                // prep COLUMN NAMES to insert into table headers (avoids slowly setting cell-by-cell)
                var _columns = any_row.Select(column => column.Key).ToArray();

                object[,] columns = new object[1, _columns.Length];

                for (int i = 0; i <= _columns.Length - 1; i++)
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

                return listObject;
            }
            catch (Exception ex) {
                    if (ex.Data.Count == 0) ex.Data.Add(0, "SheetBuilderDynamic.BuildTable");
                    throw ex;
            }
            finally
            {
                //if (listObject != null) Marshal.ReleaseComObject(listObject); listObject = null;
                if (_rng != null) Marshal.ReleaseComObject(_rng); _rng = null;
                if (_rng2 != null) Marshal.ReleaseComObject(_rng2); _rng2 = null;
                if (headers != null) Marshal.ReleaseComObject(headers); headers = null;
            }
        }
    }
}
