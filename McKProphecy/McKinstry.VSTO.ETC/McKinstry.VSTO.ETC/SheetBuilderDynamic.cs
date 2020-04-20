using System;
using System.Data;
using Excel = Microsoft.Office.Interop.Excel;
using System.Reflection;
//using McK.Data.Viewpoint;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Linq;

namespace McKinstry.ETC.Template
{
    public static class SheetBuilderDynamic2
    {
        /// <summary>
        /// Builds an Excel Table from a List of dynamic Expando Objects. 
        /// Columns are added dynamically to Expand Objects from SqlDataReader which means we don't have to specify them before hand.
        /// </summary>
        /// <param name="ws">Excel worksheet to place the Excel ListOject (table)</param>
        /// <param name="table">ExpandObject List of Key Value pairs of Field names and sub KV(field value, datatype)</param>
        /// <param name="tableName">Name to assign the Excel Table</param>
        /// <param name="offsetFromLastUsedCell">Row to start the table at in worksheet</param>
        public static void BuildTable(Excel.Worksheet ws, List<dynamic> table, string tableName, int offsetFromLastUsedCell = 3)
        {
            if (table.Count == 0) return;

            int _row = ws.UsedRange.SpecialCells(Excel.XlCellType.xlCellTypeLastCell).Row;
            int headerRow = _row + offsetFromLastUsedCell;
            int totalRows = table.Count;
            Excel.Range _rng = null;
            Excel.Range _rng2 = null;
            Excel.ListObject listObject = null;

            try
            {
                IDictionary<string, object> fields = table[0];

                // set table header column names
                _rng  = ws.Cells[headerRow, 1];
                _rng2 = ws.Cells[headerRow + totalRows, fields.Keys.Count];
                _rng  = ws.get_Range(_rng, _rng2);

                listObject = HelperUI.FormatAsTable(_rng, "tbl" + tableName);
                listObject.ShowTotals = false;

                // get any one of the rows
                IDictionary<string, Object> any_row = table.First();

                // format table columns based on data types
                uint col = 1;
                foreach (KeyValuePair<string, object> _field in any_row) 
                {
                    listObject.ListColumns[col].Name = _field.Key; // rename table columns

                    KeyValuePair <object, string> value_datatype = (KeyValuePair<object, string>)_field.Value; // KV(field value, datatype)
                    if (value_datatype.Value == "String" || value_datatype.Value == "Double" || value_datatype.Value == "Byte" || value_datatype.Value == "Int16" ||
                                  _field.Key == "Factor" || _field.Key == "EarnCode")
                    {
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.StringFormat;
                        listObject.ListColumns[col].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    }
                    else if (value_datatype.Value == "Decimal")
                    {
                        listObject.ListColumns[col].DataBodyRange.Style = HelperUI.CurrencyStyle;
                    }
                    else if (value_datatype.Value == "DateTime")
                    {
                        listObject.ListColumns[col].DataBodyRange.NumberFormat = HelperUI.DateFormatMMDDYY;
                        listObject.ListColumns[col].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    }
                    ++col;
                }

                // set field values
                col = 0;
                _row = 0;
                foreach (IDictionary<string, Object> row_kv in table) // loop list
                {
                    ++_row;
                    foreach (KeyValuePair<string, object> _field in row_kv) // loop expando object -> Property name and KV(field value, datatype)
                    {
                        ++col;

                        ws.Cells[headerRow, col].Value = _field.Key; // column name

                        KeyValuePair<object, string> value_datatype = (KeyValuePair<object, string>)_field.Value;

                        if (_field.Key == "Factor")
                        {
                            ws.Cells[headerRow + _row, col].Formula = value_datatype.Key.ToString(); // field value
                        }
                        else
                        {
                            ws.Cells[headerRow + _row, col].Formula = value_datatype.Key; // field value
                        }
                    }
                    col = 0;
                }

                listObject.ListColumns["Errmsg"].DataBodyRange.Interior.Color = HelperUI.RedNegColor;
                listObject.ListColumns["Errmsg"].DataBodyRange.EntireColumn.AutoFit();
            }
            catch (Exception ex) {
                    if (ex.Data.Count == 0) ex.Data.Add(0, "BuildTable");
                    throw ex;
            }
            finally
            {
                if (listObject != null) Marshal.ReleaseComObject(listObject); listObject = null;
                if (_rng != null) Marshal.ReleaseComObject(_rng); _rng = null;
                if (_rng2 != null) Marshal.ReleaseComObject(_rng2); _rng2 = null;
            }
        }
    }
}
