using System;
using System.Collections.Generic;
using System.Drawing;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKUserCreation
{
    public static class HelperUI
    {
        public const string pwd = "HowardSnow";

        public static void ProtectSheet(Excel._Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(pwd, true, Type.Missing, Type.Missing, true, true, true,
                  Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }

        #region STYLE GUIDE
        public static Color DataEntryColor { get { return McKColor(McKColors.Yellow); } }
        public static Color GrayDarkColor { get { return McKColor(McKColors.GrayDark); } }
        public static Color GrayLighterColor { get { return McKColor(McKColors.GrayLighter); } }

        public static Color NavyBlueColor { get { return McKColor(McKColors.NavyBlue); } }
        public static Color WhiteColor { get { return McKColor(McKColors.White); } }
        public static Color BlackColor { get { return McKColor(McKColors.SoftBlack); } }

        public static Color RedColor { get { return McKColor(McKColors.Red); } }

        public enum McKColors
        {
            NavyBlue
            , Gray
            , GrayLighter
            , GrayLight
            , GrayDark
            , Yellow
            , Red
            , BrightRed
            , Green
            , SoftBlack
            , SoftBeige
            , AquaBlue
            , White
        }

        public static Color McKColor(McKColors color)
        {
            switch (color)
            {
                case McKColors.NavyBlue: return Color.FromArgb(10, 63, 84);

                case McKColors.GrayLighter: return Color.FromArgb(231, 230, 230);

                case McKColors.Gray: return Color.FromArgb(118, 131, 147);

                case McKColors.GrayLight: return Color.FromArgb(192, 195, 204);

                case McKColors.GrayDark: return Color.FromArgb(219, 219, 219);

                case McKColors.Yellow: return Color.FromArgb(250, 237, 191);

                case McKColors.Red: return Color.FromArgb(255, 189, 189);

                case McKColors.BrightRed: return Color.FromArgb(255, 0, 0);

                case McKColors.Green: return Color.FromArgb(198, 224, 180);

                case McKColors.SoftBlack: return Color.FromArgb(32, 31, 32);

                case McKColors.SoftBeige: return Color.FromArgb(250, 240, 235);

                case McKColors.White: return Color.FromArgb(255, 255, 255);

                case McKColors.AquaBlue: return Color.FromArgb(205, 251, 255);

                default: return Color.White;
            }
        }

        #endregion
    }

    public static class ArrayHelper
    {
        /// <summary>
        /// Get missing fields in occupied rows along w/ indeces to all occupied rows
        /// </summary>
        /// <param name="target">2-dimentional array mirror of user-input area</param>
        /// <param name="occupiedRowIndices">Out param of indeces of user-input rows </param>
        /// <returns>An Excel.Range of a missing field, null if no missing fieldsd.  </returns>
        public static Excel.Range GetExcelMissingField_FromOccupiedRowsOnly(this object[,] target, Excel.Worksheet wsTarget, out List<uint> occupiedRowIndices)
        {
            try
            {
                int rows   = target.GetUpperBound(0);
                int fields = target.GetUpperBound(1);
                occupiedRowIndices = new List<uint>();

                for (uint row = 0; row < rows; row++)
                {
                    //  search the fields for missing input
                    bool dirtyRow = false;
                    uint blankCellCol = 0;

                    for (uint col = 1; col <= fields; col++)
                    {
                        uint _blankCellCol = 0;
                        _blankCellCol = target[row + 1, col] == null || (string)target[row + 1, col] == "" ? col : 0;

                        // only need 1 instance of dirtyRow and blankCellCol to trigger alert
                        if (!dirtyRow) 
                        {
                            dirtyRow = _blankCellCol == 0; // flag the row
                        }

                        if (blankCellCol == 0)
                        {
                            blankCellCol = _blankCellCol; // remember the column
                        }

                        // missing field ?
                        if (dirtyRow && blankCellCol > 0)
                        {
                            return wsTarget.Cells[row + 2, blankCellCol];
                        }
                        if (col == 4 && dirtyRow)
                        {
                            occupiedRowIndices.Add(row + 1);
                        }
                    }
                }
            }
            catch (Exception) { throw; }
            return null;
        }
    }
}
