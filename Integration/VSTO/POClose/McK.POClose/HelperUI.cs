using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;

namespace McKPOClose
{
    public static class HelperUI
    {
        public const string pwd = "poclose";

        public static void ProtectSheet(Excel.Worksheet _ws, bool allowInsertRows = true, bool allowDelRows = true)
        {
            _ws.EnableOutlining = true;
            _ws.Protect(pwd, true, Type.Missing, Type.Missing, true, true, true,
                  Type.Missing, Type.Missing, allowInsertRows, Type.Missing, Type.Missing, allowDelRows, true, true, Type.Missing);
        }


        public static Color DataEntryColor { get { return McKColor(McKColors.Yellow); } }
        public static Color GrayDarkColor { get { return McKColor(McKColors.GrayDark); } }
        public static Color GrayLighterColor { get { return McKColor(McKColors.GrayLighter); } }

        public static Color NavyBlueColor { get { return McKColor(McKColors.NavyBlue); } }
        public static Color WhiteColor { get { return McKColor(McKColors.White); } }


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

        #region SHOW ERRORS

        internal static void ShowErr(Exception ex = null, string customErrMsg = null, string title = "Oops!")
        {
            string err = customErrMsg ?? (ex?.Message != "" ? ex.Message : "Something went wrong");

            MessageBox.Show(null, err, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        }

        internal static void ShowInfo(Exception ex = null, string msg = null, string title = "AR Statement")
        {
            string err = msg ?? ex.Message;

            MessageBox.Show(null, err, title, MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        internal static void errOut(Exception ex = null, string title = "Oops") => MessageBox.Show(null, ex?.Message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);
        #endregion
    }
}
