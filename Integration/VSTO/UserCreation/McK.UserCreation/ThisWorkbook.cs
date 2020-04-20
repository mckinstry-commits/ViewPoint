using Office = Microsoft.Office.Core;

namespace McKUserCreation
{
    public partial class ThisWorkbook
    {
        // Global Variable for Custom Action Pane
        internal ActionPane1 _myActionPane = new ActionPane1();


        private void ThisWorkbook_Startup(object sender, System.EventArgs e)
        {
            // Add Custom Action Pane to Excel application context   
            this.ActionsPane.Controls.Add(_myActionPane);

            // Set default configuration for custom action pane
            this.Application.CommandBars["Task Pane"].Position = Office.MsoBarPosition.msoBarLeft;
            this.Application.CommandBars["Task Pane"].Width = 250;

            if (this.Application.CommandBars["Task Pane"].Position == Microsoft.Office.Core.MsoBarPosition.msoBarFloating)
            {
                this.Application.CommandBars["Task Pane"].Top = (int)this.Application.Top + 100;
            }
        }

        private void ThisWorkbook_Shutdown(object sender, System.EventArgs e)
        {
        }

        // reset edited cell to data entry color
        private void ThisWorkbook_SheetChange(object Sh, Microsoft.Office.Interop.Excel.Range Target)
        {
            if (_myActionPane._rng == null) return;

            if (Target.Rows.CountLarge == 1 && _myActionPane.@switch == 0x1)
            {
                if (Target.Application.Intersect(_myActionPane._rng, Target) != null)
                {
                    Target.Interior.Color = HelperUI.DataEntryColor;
                    _myActionPane.@switch = 0x0;
                }
            }
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
            this.SheetChange += ThisWorkbook_SheetChange;
        }

        #endregion

    }
}
