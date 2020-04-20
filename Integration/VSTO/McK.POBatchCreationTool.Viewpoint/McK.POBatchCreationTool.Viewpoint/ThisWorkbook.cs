using Office = Microsoft.Office.Core;

namespace McK.POBatchCreationTool.Viewpoint
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane1 _myActionPane = new ActionPane1();

        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            Application.CommandBars["Task Pane"].Width = 228;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)Application.Top + 100;
            }

        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
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
