using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using Microsoft.Office.Tools.Excel;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.SMInvoice.Viewpoint
{
    public partial class Customers
    {
        private void Sheet21_Startup(object sender, System.EventArgs e)
        {
        }

        private void Sheet21_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.btnCloseCustomers.Click += new System.EventHandler(this.btnCloseCustomers_Click);
            this.SelectionChange += this.Customer_SelectionChange;
    
        }

        #endregion

        private void btnCloseCustomers_Click(object sender, EventArgs e)
        {
            this.Visible = Excel.XlSheetVisibility.xlSheetVeryHidden;
        }

        private void Customer_SelectionChange(Excel.Range Target)
        {
            if (Globals.Customers == null || Globals.ThisWorkbook._myActionPane._isBuildingTable) return;

            Excel.ListObject xltable = null;
            Excel.Range rngSelection = null;
            long customerCol = 0;

            try
            {
                if (Globals.Customers.ListObjects.Count > 0)
                {
                    xltable = Globals.Customers.ListObjects[1];

                    rngSelection = Target.Application.ActiveWindow.Selection;

                    if (Target.Application.Intersect(xltable.DataBodyRange, Target) != null)
                    {
                        if (rngSelection.CountLarge > xltable.DataBodyRange.CountLarge) return;

                        if (rngSelection.CountLarge == 1)
                        {
                            customerCol = xltable.ListColumns["Customer"].Index;
                            Globals.ThisWorkbook._myActionPane.txtBillToCustomer.Text = Globals.Customers.Cells[rngSelection.Row, customerCol].Value.ToString();
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                HelperUI.errOut(ex);
            }
            finally
            {
                if (xltable != null) Marshal.ReleaseComObject(xltable);
                if (rngSelection != null) Marshal.ReleaseComObject(rngSelection);
            }
        }
    }
}
