using System;
using System.Collections.Generic;
using Excel = Microsoft.Office.Interop.Excel;

namespace MCK.CraftClass.Viewpoint
{
    internal static class ArrayExtensions
    {
        /// <summary>
        /// Get indices of all rows to be loaded. Missing required fields are flagged. Skips blank rows.
        /// </summary>
        /// <param name="target">A range.Value2 (2-dimentional) Excel object array from input area</param>
        /// <param name="startRowData">Optional start row of data</param>
        /// <returns>A tuple of Excel.Range (missing fields) and a list of occupied row indices List(uint)</returns>
        internal static (Excel.Range cell, List<uint> loadRows) GetCraftClasses(this object[,] target, Excel.Worksheet wsTarget, uint startRowData = 3, bool loadAllRows = false)
        {
            List<uint> loadRows = new List<uint>(); // rows that will be put in the batch for processing

            try
            {
                int rows = target.GetUpperBound(0);
                int fields = target.GetUpperBound(1);

                for (uint row = 0; row < rows; row++)
                {
                    uint xlRow = row + 1;

                    if (!loadAllRows && string.Equals(target[xlRow, 1]?.ToString(), "N", StringComparison.CurrentCultureIgnoreCase)) continue; // skip rows w/ 'N' load filter

                    bool dirtyRow = false;
                    uint blankCellCol = 0;

                    for (uint col = 0; col <= fields; col++)
                    {
                        //  search fields for missing input
                        uint xlCol = col + 1;

                        uint _blankCellCol = target[xlRow, xlCol] == null || target[xlRow, xlCol].ToString() == "" ? xlCol : 0; // cell empty?

                        if (!dirtyRow) dirtyRow = _blankCellCol == 0;        // 0 = dirty cell

                        if (blankCellCol == 0) blankCellCol = _blankCellCol; // dirty column

                        // missing req. field ?
                        if (dirtyRow && blankCellCol > 0 && blankCellCol != 5) // 5 = 'Notes' field not required
                        {
                            return (wsTarget.Cells[row + startRowData, blankCellCol], loadRows); // trigger alert
                        }

                        // end of row ?
                        if (xlCol == fields && dirtyRow)
                        {
                            //System.Diagnostics.Debug.Print(xlRow.ToString());
                            loadRows.Add(xlRow); // pass validation
                            break;
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            return (null, loadRows);
        }


        /// <summary>
        /// Get 2-pairs from an Excel range (.Value2)
        /// </summary>
        /// <param name="excelRange"></param>
        /// <param name="startRowData"></param>
        /// <returns></returns>
        internal static Dictionary<uint, List<KeyValuePair<int, decimal>>> Get2Pairs(this object[,] excelRange, object[,] craftClass, List<uint> loadRows, uint startColNamedRange, uint startRowData = 3)
        {
            Dictionary<uint, List<KeyValuePair<int, decimal>>> _2pairs = new Dictionary<uint, List<KeyValuePair<int, decimal>>>();

            try
            {
                int rows = excelRange.GetUpperBound(0);      // start at 1, non-zero based (Excel)
                int fields = excelRange.GetUpperBound(1);    // ditto

                for (uint row = 0; row < rows; row++)
                {
                    bool dirtyRow = false;
                    uint _xlRow = row + 1;

                    // skip failed validation and 'no load' filtered rows
                    int idx = loadRows.IndexOf(_xlRow);
                    if (idx == -1) continue; 

                    // search fields for code / amount 
                    for (uint col = 1; col <= fields; col++)
                    {
                        var _code = excelRange[_xlRow, col]; // current cell

                        // cell has value ?
                        bool missingCode = _code == null || _code.ToString() == "";

                        //if (_blankCellCol > 0)
                        //{
                        //    continue;        // skip blank cells
                        //}
                        if (!dirtyRow)
                        {
                            dirtyRow = true; // zero = dirty
                        }

                        if (dirtyRow)
                        {
                            // is code or amt ?
                            if (col % 2 != 0)
                            {
                                // CODE:
                                if (col < fields) // is last field?
                                {
                                    // no..
                                    if (col + 1 > fields) return _2pairs; // reached the end of range

                                    // is amt available? 
                                    var _amt = excelRange[_xlRow, col + 1];
                                    bool missingRate = _amt == null || _amt.ToString() == "";

                                    // is code available ?
                                    if (missingCode && !missingRate)
                                    {
                                        uint offsetFromColA = startColNamedRange;
                                        Exception ex = new Exception();
                                        ex.Data.Add(0, "Oops");
                                        ex.Data.Add(1, "Missing code. See highlighted cell.");
                                        ex.Data.Add(3, new uint[] { _xlRow + 2, col + offsetFromColA - 1 }); // offset Excel row / column to highlight correct cell
                                        throw ex;
                                    }
                                    else if (!missingCode && missingRate)
                                    {
                                        uint offsetFromColA = startColNamedRange; 
                                        //if (fields == 64)       // dedns liabs
                                        //{
                                        //    offset = 79; 
                                        //}
                                        //else if (fields == 46)  // payrates
                                        //{
                                        //    offset = 14;
                                        //}
                                        //else if (fields == 12)  // addon earnings
                                        //{
                                        //    offset = 60;
                                        //}
                                        Exception ex = new Exception();
                                        ex.Data.Add(0, "Oops");
                                        ex.Data.Add(1, "Missing rate. See highlighted cell.");
                                        ex.Data.Add(3, new uint[] { _xlRow + 2, col + offsetFromColA }); // offset Excel row / column to highlight correct cell
                                        throw ex;
                                    }
                                    else if(missingCode && missingRate)
                                    {
                                        ++col;      // next pair
                                        continue;
                                    }
                                    // yes, add pair as SQL datatype values
                                    int.TryParse(_code.ToString(), out int code);
                                    decimal.TryParse(_amt.ToString(), out decimal amt);

                                    // is there a Dictionary entry for this row ?
                                    if (_2pairs.TryGetValue(_xlRow, out List<KeyValuePair<int, decimal>> kv))
                                    {
                                        kv.Add(new KeyValuePair<int, decimal>(code, amt)); // update row (key) w/ shift/rate
                                    }
                                    else
                                    {
                                        // add new row key entry w/ shift/rate
                                        kv = new List<KeyValuePair<int, decimal>>
                                        {
                                            new KeyValuePair<int, decimal>(code, amt)
                                        };
                                        _2pairs.Add(_xlRow, kv);
                                    }
                                    
                                }
                                ++col;  // skip rate cause already added
                                continue;
                            }
                            else
                            {
                                ++col;
                                continue; // skip rate
                            }
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            return _2pairs;
        }


        internal static Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> Get3Pairs(this object[,] excelRange, 
                                                                                                                                       Excel.Range _3pairheaders,
                                                                                                                                       object[,] craftClass, 
                                                                                                                                       List<uint> loadRows,
                                                                                                                                       uint startColNamedRange,
                                                                                                                                       uint startRowData = 3)
        {
            Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> _3pairs = new Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>>();
            List<uint> lstVariableColumnIndex = new List<uint>();

            try
            {
                // how many variables ?
                foreach (Excel.Range cell in _3pairheaders)
                {
                    if (((string)cell.Text).Contains("Variable"))
                    {
                        uint index_relativeTo_excelRange;
                        if (lstVariableColumnIndex.Count == 0)
                        {
                            lstVariableColumnIndex.Add(1);
                        }
                        else
                        {
                            index_relativeTo_excelRange = (uint)cell.Column - (uint)_3pairheaders.Column + 1;
                            lstVariableColumnIndex.Add(index_relativeTo_excelRange);
                        }
                    }
                }

                bool moreThan1Variable = lstVariableColumnIndex.Count > 1;

                int rows = excelRange.GetUpperBound(0);      // index starts at 1, non-zero based (Excel)
                int fields = excelRange.GetUpperBound(1);    // ditto

                for (uint row = 0; row < rows; row++)
                {
                    uint _xlRow = row + 1;
                    int currentVariable = 0;

                    // skip failed validation and 'no load' filter rows
                    int idx = loadRows.IndexOf(_xlRow);
                    if (idx == -1) continue;

                    foreach (var var in lstVariableColumnIndex)
                    {
                        // search 3 value pairs fields
                        for (uint col = var; col <= (var+6); col++)
                        {
                            var _cell = excelRange[_xlRow, col]; // current cell

                            bool isVariable = lstVariableColumnIndex.Contains(col);

                            if (col < fields) // make sure we're still inside the working range
                            {
                                object _factor = null;
                                object _amt = null;
                                bool missingCode = false; 

                                // check for missing code
                                //uint var = !moreThan1Variable ? 1 : lstVariableColumnIndex[lstVariableColumnIndex.Count-1]; // TFS 4747 fix incorrect "Missing code" error - 6.19.19 - Leo Gurdian - chng hard code index to dynamic ref to last Variable column. 

                                if (!moreThan1Variable)
                                {
                                    missingCode = excelRange[_xlRow, var] == null || excelRange[_xlRow, var].ToString() == "";
                                }
                                else
                                {
                                    bool isEntry = excelRange[_xlRow, (col + 1)] != null;

                                    missingCode = (excelRange[_xlRow, var] == null || excelRange[_xlRow, var].ToString() == "") & isEntry;
                                    //missingCode = (excelRange[_xlRow, col < var ? 1 : var ] == null || excelRange[_xlRow, col < var ? 1 : var].ToString() == "") & isEntry;
                                }

                                // get factor & amt pair values
                                if (isVariable)
                                {
                                    int.TryParse(_cell?.ToString(), out int variable);
                                    currentVariable = variable;
                                    _factor = excelRange[_xlRow, col + 1];
                                    _amt = excelRange[_xlRow, col + 2];
                                }
                                else
                                {
                                    if (col % 2 == 0)
                                    {
                                        // incoming column (col) is factor
                                        _factor = excelRange[_xlRow, col ];
                                        _amt    = excelRange[_xlRow, col + 1 ];
                                    }
                                    else
                                    {
                                        // incoming column (col) is amt
                                        if (!moreThan1Variable)
                                        {
                                            _factor = excelRange[_xlRow, col - 1];
                                            _amt = excelRange[_xlRow, col];
                                        }
                                        else
                                        {
                                            _factor = excelRange[_xlRow, col];
                                            _amt = excelRange[_xlRow, col + 1];
                                        }
                                    }
                                }

                                // error if code, factor or amount pairs are missing
                                bool missingFactor = _factor == null || _factor.ToString() == "";
                                bool missingAmt = _amt == null || _amt.ToString() == "";

                                if (missingFactor & missingAmt)
                                {
                                    // advance depending if col is a variable column or 2-pair Factor and Amount
                                    if (isVariable)
                                    {
                                        col += 2;    // move forward 3 cells
                                    }
                                    else if (!(lstVariableColumnIndex.Contains(col + 1))) // if next column is not a Variable
                                    {
                                        col += 1; //move forward 2 cells
                                    }
                                    continue;
                                }

                                if (missingCode || missingFactor || missingAmt)
                                {
                                    string msg = null; 
                                    uint offsetFromColA = 0;

                                    if (missingCode)
                                    {
                                        msg = "Missing code. See highlighted cell.";
                                    }
                                    else if (missingFactor)
                                    {
                                        msg = "Missing factor. See highlighted cell.";
                                    }
                                    else if (missingAmt)
                                    {
                                        msg = "Missing amount. See highlighted cell.";
                                    }

                                    // set cell ref to highlight 
                                    if (isVariable)
                                    {
                                        if (missingCode)
                                        {
                                            offsetFromColA = startColNamedRange - 1;
                                        }
                                        else if (missingFactor)
                                        {
                                            offsetFromColA = startColNamedRange;
                                        }
                                        else if (missingAmt)
                                        {
                                            offsetFromColA = startColNamedRange + 1;
                                        }
                                    }
                                    else
                                    {
                                        if (missingCode)
                                        {
                                            offsetFromColA = startColNamedRange - (col - var + 1);
                                        }
                                        else if (missingFactor)
                                        {
                                            offsetFromColA = startColNamedRange - 1;
                                        }
                                        else if (missingAmt)
                                        {
                                            offsetFromColA = startColNamedRange;
                                        }
                                        //  offsetFromColA = missingAmt ? startColNamedRange : startColNamedRange - 1;
                                    }
                                    Exception ex = new Exception();
                                    ex.Data.Add(0, "Oops");
                                    ex.Data.Add(1, msg);
                                    ex.Data.Add(3, new uint[] { _xlRow + 2, col + offsetFromColA }); // offset Excel row / column to highlight correct cell
                                    throw ex;
                                }
                            
                                // convert pairs as SQL datatype values
                                decimal.TryParse(_factor.ToString(), out decimal factor);
                                decimal.TryParse(_amt.ToString(), out decimal amt);

                                KeyValuePair<decimal, decimal> factor_and_amt = new KeyValuePair<decimal, decimal>(factor, amt);

                                // 3-pair entry exists for this row ?
                                if (_3pairs.TryGetValue(_xlRow, out List<KeyValuePair<int, KeyValuePair<decimal, decimal>>> kv))
                                {
                                    kv.Add(new KeyValuePair<int, KeyValuePair<decimal, decimal>>(currentVariable, factor_and_amt)); // add 3-pair values to row entry
                                }
                                else
                                {
                                    // add new row entry w/ 3-pair values
                                    kv = new List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>
                                    {
                                        new KeyValuePair<int, KeyValuePair<decimal, decimal>>(currentVariable, factor_and_amt)
                                    };
                                    _3pairs.Add(_xlRow, kv);
                                }
                            }

                            // advance depending if it's a variable column or 2-pair Factor and Amount
                            if (isVariable)
                            {
                                col += 2;    // move forward 3 cells
                            }
                            else if (!(lstVariableColumnIndex.Contains(col + 1))) // if next column is not a Variable
                            {
                                col += 1; // move forward 2 cells
                            }
                            continue;
                        }
                    }
                }
            }
            catch (Exception) {
                throw;
            }
            return _3pairs;
        }

        /// <summary>
        /// Converts Excel.Range.Value2 array to Dictionary for faster search
        /// </summary>
        /// <param name="xlValue2"></param>
        /// <returns>Dictionary of Key Value pairs (rows, values)</returns>
        internal static Dictionary<int, string> Cast(this object[,] xlValue2)
        {
            Dictionary<int, string> list = new Dictionary<int, string>(xlValue2.GetUpperBound(0));

            for (int i = 1; i < xlValue2.GetLength(0) + 1; i++)
            {
                list.Add(i, xlValue2.GetValue(i,1).ToString());
            }

            return list;
        }
    }
}
