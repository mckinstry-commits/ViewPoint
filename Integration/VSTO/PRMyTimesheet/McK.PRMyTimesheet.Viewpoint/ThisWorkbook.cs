using System.Runtime.InteropServices;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.PRMyTimesheet.Viewpoint
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane _myActionPane = new ActionPane();


        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            this.Application.CommandBars["Task Pane"].Width = 140;// HelperUI.GetDynamicPaneWidth();

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }

            _myActionPane.Summary_ws = Globals.sht_Summary.InnerObject;

            _myActionPane.Summary_ws.Names.Item("productTitleTop").RefersToRange.Formula = "PR My Timesheet v." + _myActionPane.ProductVersion;

            _myActionPane._dbSource    = _myActionPane.Summary_ws.Names.Item("dbSource").RefersToRange;
            _myActionPane._productName = _myActionPane.Summary_ws.Names.Item("productTitle").RefersToRange;
            _myActionPane._productName.Formula = "PR My Timesheet v." + _myActionPane.ProductVersion;

            _myActionPane.tabColorDefault = Globals.sht_Summary.Tab.Color; // save to show on landing page
            _myActionPane._logo           = Globals.sht_Summary.Shapes.Item("picLogo");
            _myActionPane.ShowLandingPage();
            _myActionPane.Summary_ws.Names.Item("productTitleTop").RefersToRange.Font.Color = _myActionPane._productName.Font.Color;
            _myActionPane.Summary_ws.Names.Item("dbSourceTop").RefersToRange.Font.Color = _myActionPane._productName.Font.Color;

            Globals.ThisWorkbook.Application.ActiveWindow.ScrollRow = 1;
        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
            if (_myActionPane.Summary_ws != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane.Summary_ws);
        }

        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisWorkbook_Startup);
            this.Shutdown += new System.EventHandler(ThisWorkbook_Shutdown);
            this.BeforeClose += new Excel.WorkbookEvents_BeforeCloseEventHandler(ThisWorkbook_BeforeClose);
        }

        #endregion

        private void ThisWorkbook_BeforeClose(ref bool Cancel)
        {
            try
            {
                string wkbSaveAsName = "McK PRMyTimesheets " + string.Format("{0:M-dd-yyyy}", System.DateTime.Today) + " " + System.DateTime.Now.ToString("h:mm:ss tt").Replace(":", " ") + ".xlsx";

                Cancel = IOexcel.SavePrompt(Globals.ThisWorkbook.Worksheets.Parent, wkbSaveAsName);

                if (_myActionPane.Summary_ws != null) Marshal.ReleaseComObject(_myActionPane.Summary_ws);
                if (_myActionPane._approved_ws != null) Marshal.ReleaseComObject(_myActionPane._approved_ws);
                if (_myActionPane._productName != null) Marshal.ReleaseComObject(_myActionPane._productName);
                if (_myActionPane._dbSource != null) Marshal.ReleaseComObject(_myActionPane._dbSource);
                if (_myActionPane._logo != null) Marshal.ReleaseComObject(_myActionPane._logo);

            }
            catch (System.Exception) { }
        }
    }
}
