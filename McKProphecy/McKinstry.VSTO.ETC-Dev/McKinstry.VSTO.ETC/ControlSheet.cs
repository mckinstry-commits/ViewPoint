using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using Microsoft.Office.Tools.Excel;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;
//using Mckinstry.VSTO;

namespace McKinstry.ETC.Template
{
    public partial class ControlSheet
    {
        private void Sheet1_Startup(object sender, System.EventArgs e)
        {
            Globals.ThisWorkbook._myActionPane._control_ws = HelperUI.GetSheet("Control", false);
            Globals.ThisWorkbook._myActionPane._control_ws.Unprotect(ETCOverviewActionPane.pwd);

            foreach (Excel.Name namedRange in this.Names) namedRange.Delete();

            this.Names.Add("ViewpointLogin", this.Cells[4, 2]);
            this.Names.Add("TimeOpening", this.Cells[5, 2]);
            this.Names.Add("TimeLastRefresh", this.Cells[6, 2]);
            this.Names.Item("TimeLastRefresh").RefersToRange.NumberFormat = HelperUI.DateFormatMDYYYYhmmAMPM;
            this.Names.Item("TimeOpening").RefersToRange.NumberFormat = HelperUI.DateFormatMDYYYYhmmAMPM;
            this.Names.Item("TimeOpening").RefersToRange.Value = HelperUI.DateTimeShortAMPM;

            this.Names.Add("RevBatchId", this.Cells[10, 1]);
            this.Names.Add("RevJectMonth", this.Cells[10, 2]);
            this.Names.Item("RevJectMonth").RefersToRange.NumberFormat = "@";

            // Contract info
            this.Names.Add("ContractNumber", this.Cells[16, 1]);
            this.Names.Add("ContractName", this.Cells[16, 2]);
            this.Names.Add("ContractLastSave", this.Cells[16, 3]);
            this.Names.Add("ContractLastPost", this.Cells[16, 4]);
            this.Names.Add("ContractUserName", this.Cells[16, 5]);

            this.Names.Item("ContractLastSave").RefersToRange.NumberFormat = HelperUI.DateFormatMDYYhmmAMPM;
            this.Names.Item("ContractLastPost").RefersToRange.NumberFormat = HelperUI.DateFormatMDYYhmmAMPM;

            this.Names.Add("CostBatchId", this.Cells[12, 1]);
            this.Names.Add("CostJectMonth", this.Cells[12, 2]);
            this.Names.Item("CostJectMonth").RefersToRange.NumberFormat = "@";

            this.Cells[3, 3].Font.Size = 26;
            
            if (Data.Viewpoint.HelperData._conn_string == "Server=VPSTAGINGAG\\VIEWPOINT;Database=Viewpoint;Trusted_Connection=True;")
            {
                this.Cells[3, 3].Value = "Viewpoint Staging";
                this.Cells[3, 3].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
                this.Cells[3, 4].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
            }
            if (Data.Viewpoint.HelperData._conn_string == "Server=MCKTESTSQL04\\VIEWPOINT;Database=Viewpoint;Trusted_Connection=True;")
            {
                this.Cells[3, 3].Value = "Viewpoint DEV";
                this.Cells[3, 3].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
                this.Cells[3, 4].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
            }
            if (Data.Viewpoint.HelperData._conn_string == "Server=VPSTAGINGAG\\VIEWPOINT;Database=ViewpointTraining;Trusted_Connection=True;")
            {
                this.Cells[3, 3].Value = "Viewpoint Training";
                this.Cells[3, 3].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
                this.Cells[3, 4].Interior.Color =HelperUI.McKColor(HelperUI.McKColors.Yellow);
            }
            if (Data.Viewpoint.HelperData._conn_string == "Server=SEA-STGSQL01\\VIEWPOINT;Database=Viewpoint;Trusted_Connection=True;")
            {
                this.Cells[3, 3].Value = "Upgrade Dev";
                this.Cells[3, 3].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
                this.Cells[3, 4].Interior.Color = HelperUI.McKColor(HelperUI.McKColors.Yellow);
            }

            Globals.ThisWorkbook._myActionPane._control_ws.Cells.Locked = true;
            HelperUI.ProtectSheet(Globals.ThisWorkbook._myActionPane._control_ws, false, false);
            Globals.ThisWorkbook._myActionPane._control_ws.Activate();
            Range["A1"].Activate();

            this.Cells[1, 3].EntireColumn.ColumnWidth = 22;
            this.Cells[1, 4].EntireColumn.ColumnWidth = 22;
        }

        private void Sheet1_Shutdown(object sender, System.EventArgs e)
        {
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.btnToggleActionPane.Click += new System.EventHandler(this.btnToggleActionPane_Click);
            this.Startup += new System.EventHandler(this.Sheet1_Startup);
            this.Shutdown += new System.EventHandler(this.Sheet1_Shutdown);
        }

        #endregion


        private void btnToggleActionPane_Click(object sender, EventArgs e)
        {
            this.Application.DisplayDocumentActionTaskPane = true;
        }

    }
}
