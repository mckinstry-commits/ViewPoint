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

namespace McKinstry.ETC.Template
{
    public static class ControlSheetBuilder
    {

        public static void BuildUserProfile(string username)
        {
            Excel.Worksheet _control_ws = null;

            try
            {
                 = username;
            }
            catch (Exception e)
            {
                throw new Exception("BuildUserProfile: Error writting username to Control sheet", e);
            }
            finally
            {
                if (_control_ws != null) Marshal.ReleaseComObject(_control_ws);
            }
        }
    }
}
