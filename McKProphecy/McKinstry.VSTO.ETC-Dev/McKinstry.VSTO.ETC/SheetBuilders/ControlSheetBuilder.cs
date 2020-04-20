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

        public static void BuildUserProfile(Excel.Workbook workbook, DataTable userProfile)
        {
            Excel.Worksheet _control_ws = null;
            string _control_sheet_name = "Control";

            try
            {
                _control_ws = HelperUI.GetSheet(_control_sheet_name);

                if (_control_ws == null) _control_ws = HelperUI.AddSheet(_control_sheet_name, workbook.ActiveSheet);
                _control_ws.Names.Item("ViewpointLogin").RefersToRange.Value = userProfile.Rows[0].Field<string>("VPUserName");
            }
            catch (Exception e)
            {
                throw new Exception("BuildUserProfile: Error Writing UserProfile to Control Sheet", e);
            }
            finally
            {
                if (_control_ws != null) Marshal.ReleaseComObject(_control_ws);
            }
        }
    }
}
