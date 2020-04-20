using Office = Microsoft.Office.Core;

namespace Mck_TL_UI
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
            this.Application.CommandBars["Task Pane"].Width = 150;// HelperUI.GetDynamicPaneWidth();

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }

            _myActionPane.summary_ws = Globals.sht_Summary.InnerObject;

            _myActionPane.summary_ws.get_Range("D21").Formula = "EBS Timesheet Load v." + _myActionPane.ProductVersion;

            _myActionPane.dbSource    = _myActionPane.summary_ws.Names.Item("dbSource").RefersToRange;
            _myActionPane.productName = _myActionPane.summary_ws.Names.Item("productTitle").RefersToRange;
            _myActionPane.productName.Formula = "EBS Timesheet Load v." + _myActionPane.ProductVersion;

            //Excel.Shape xlTextBox = summary_ws.Shapes.Item("picLogo");
            //xlTextBox.Visible = Office.MsoTriState.msoFalse;
        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
            if (_myActionPane.summary_ws != null) System.Runtime.InteropServices.Marshal.ReleaseComObject(_myActionPane.summary_ws); _myActionPane.summary_ws = null;
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
        }

        #endregion

    }
}
