using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using Excel = Microsoft.Office.Interop.Excel;

namespace McK.SMInvoice.Viewpoint
{

    public static class ShowARCustomers
    {
        public static void BySortName(char Status)
        {
            Excel.ListObject xltable = null;

            HelperUI.AlertOff();
            HelperUI.RenderOFF();
            List<dynamic> table = null;
            Globals.ThisWorkbook._myActionPane.UseWaitCursor = true;

            try
            {
                table = Data.Viewpoint.CustomersBySortName.GetCustomers(Status);

                if (table?.Count > 0)
                {
                    Globals.Customers.Visible = Excel.XlSheetVisibility.xlSheetVisible;

                    // re-create table if present
                    if (Globals.Customers.ListObjects.Count == 1)
                    {
                        Globals.Customers.ListObjects[1].Delete();
                    }

                    Globals.ThisWorkbook._myActionPane._isBuildingTable = true;

                    xltable = SheetBuilderDynamic.BuildTable(Globals.Customers.InnerObject, table, "tblARCustomers_by_SortName", offsetFromLastUsedCell: 2, bandedRows: true, headerRow: 5);

                    Globals.ThisWorkbook._myActionPane._isBuildingTable = false;

                    xltable.ListColumns["Customer"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["State"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["Zip"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xltable.ListColumns["Country"].DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    Globals.Customers.get_Range("G:H").EntireColumn.AutoFit();

                    HelperUI.MergeLabel(Globals.Customers.InnerObject, xltable.ListColumns[1].Name, xltable.ListColumns[xltable.ListColumns.Count].Name, "", 1, offsetRowUpFromTableHeader: 1, rowHeight: 15, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                    Globals.Customers.Activate();
                    //Globals.Customers.get_Range("A2").Activate();
                }
                else
                {
                    HelperUI.ShowInfo(msg: "No AR Customer records found!");
                }
            }
            catch (Exception ex)
            {
                HelperUI.ShowErr(ex);
            }
            finally
            {
                Globals.ThisWorkbook._myActionPane.UseWaitCursor = false;
                HelperUI.RenderON();
                HelperUI.AlertON();
                if (xltable != null) Marshal.ReleaseComObject(xltable);
            }
        }
    }
}
