using Excel = Microsoft.Office.Interop.Excel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace McKinstry.ETC.Template
{
    public static class RangeToPoint
    {
        [DllImport("gdi32.dll")]
        static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
        [DllImport("user32.dll")]
        static extern IntPtr GetDC(IntPtr hWnd);
        [DllImport("user32.dll")]
        static extern bool ReleaseDC(IntPtr hWnd, IntPtr hDC);
        private const int LOGPIXELSX = 88;
        private const int LOGPIXELSY = 90;

        public static System.Drawing.Point GetCellPosition(Excel.Range range)
        {
            Excel.Worksheet ws = range.Worksheet;
            Excel.Application ExcelApp = ws.Parent;
            IntPtr hdc = GetDC((IntPtr)0);
            long px = GetDeviceCaps(hdc, LOGPIXELSX);
            long py = GetDeviceCaps(hdc, LOGPIXELSY);
            ReleaseDC((IntPtr)0, hdc);
            double zoom = ExcelApp.ActiveWindow.Zoom;

            var pointsPerInch = ExcelApp.Application.InchesToPoints(1); // usually 72 
            var zoomRatio = zoom / 100;
            var x = ExcelApp.ActiveWindow.PointsToScreenPixelsX(0);

            // Coordinates of current column 
            x = Convert.ToInt32(x + range.Left * zoomRatio * px / pointsPerInch);

            // Coordinates of next column 
            //x = Convert.ToInt32(x + (((Range)(ws.Columns)[range.Column]).Width + range.Left) * zoomRatio * px / pointsPerInch); 
            var y = ExcelApp.ActiveWindow.PointsToScreenPixelsY(0);
            y = Convert.ToInt32(y + range.Top * zoomRatio * py / pointsPerInch);

            Marshal.ReleaseComObject(ws);
            Marshal.ReleaseComObject(range);

            return new System.Drawing.Point(x, y);
        }
    }
}
