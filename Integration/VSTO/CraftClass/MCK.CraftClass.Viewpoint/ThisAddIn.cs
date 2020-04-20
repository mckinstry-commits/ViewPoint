using OfficeCore = Microsoft.Office.Core;
using Office = Microsoft.Office.Tools;
using Excel = Microsoft.Office.Interop.Excel;
using System.Runtime.InteropServices;

namespace MCK.CraftClass.Viewpoint
{
    public partial class ThisAddIn
    {
        //private Office.CustomTaskPane customTaskPane;

        //// Expose it to the Ribbon
        //public Office.CustomTaskPane CustomTaskPane => customTaskPane;

        private TaskPaner _taskPane;
        public TaskPaner TaskPaner1 => _taskPane;

        private void ThisAddIn_Startup(object sender, System.EventArgs e) => _taskPane = new TaskPaner();


        /// <summary>
        /// Remove the pane associated with the closing workbook if exists in CustomTaskPanes
        /// </summary>
        /// <param name="wkb"></param>
        /// <param name="Cancel"></param>
        private void Application_WorkbookBeforeClose(Excel.Workbook wkb, ref bool Cancel)
        {
            Office.CustomTaskPane _pane = null;
            Excel.Window activeWindow = Globals.ThisAddIn.Application.ActiveWindow;

            try
            {
                if (activeWindow != null)
                {
                    foreach (var pane in Globals.ThisAddIn.CustomTaskPanes)
                    {
                        if (((Excel.Window)pane.Window).Hwnd == activeWindow.Hwnd && pane.Title == "Craft Class Maintenance")
                        {
                            _pane = pane;
                            break;
                        }
                    }
                    if (_pane != null) Globals.ThisAddIn.CustomTaskPanes.Remove(_pane);
                }
            }
            catch (System.Exception) { }
            finally
            {
                if (activeWindow != null) Marshal.ReleaseComObject(activeWindow);
            }
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            if (Globals.ThisAddIn.TaskPaner1.ws != null) Marshal.ReleaseComObject(Globals.ThisAddIn.TaskPaner1.ws);
        }

        #region VSTO generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(ThisAddIn_Startup);
            this.Shutdown += new System.EventHandler(ThisAddIn_Shutdown);
            Application.WorkbookBeforeClose += Application_WorkbookBeforeClose;
        }
        
        #endregion
    }
}
