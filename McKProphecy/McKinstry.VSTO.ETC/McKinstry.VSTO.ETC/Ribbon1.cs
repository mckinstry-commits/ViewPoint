using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using System.Windows.Forms;

// TODO:  Follow these steps to enable the Ribbon (XML) item:

// 1: Copy the following code block into the ThisAddin, ThisWorkbook, or ThisDocument class.

//  protected override Microsoft.Office.Core.IRibbonExtensibility CreateRibbonExtensibilityObject()
//  {
//      return new Ribbon1();
//  }

// 2. Create callback methods in the "Ribbon Callbacks" region of this class to handle user
//    actions, such as clicking a button. Note: if you have exported this Ribbon from the Ribbon designer,
//    move your code from the event handlers to the callback methods and modify the code to work with the
//    Ribbon extensibility (RibbonX) programming model.

// 3. Assign attributes to the control tags in the Ribbon XML file to identify the appropriate callback methods in your code.  

// For more information, see the Ribbon XML documentation in the Visual Studio Tools for Office Help.


namespace McKinstry.ETC.Template
{
    [ComVisible(true)]
    public class Ribbon1 : Office.IRibbonExtensibility
    {
        public Office.IRibbonUI ribbon;

        public Ribbon1() {}

        #region IRibbonExtensibility Members

        public string GetCustomUI(string ribbonID)
        {
            return GetResourceText("McKinstry.ETC.Template.Ribbon1.xml");
        }

        #endregion

        #region Ribbon Callbacks
        //Create callback methods here. For more information about adding callback methods, visit http://go.microsoft.com/fwlink/?LinkID=271226

        public void Ribbon_Load(Office.IRibbonUI ribbonUI) => this.ribbon = ribbonUI; 
        
        public void SortNoAlerts(Office.IRibbonControl control, ref bool cancelDefault)
        {
            Excel.Worksheet ws = null;
            try
            {
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                if (ws.Name != "Control")
                {
                    ws.Unprotect(ETCOverviewActionPane.pwd);
                    cancelDefault = false;
                }
                else
                {
                    cancelDefault = true;
                }
                Globals.ThisWorkbook.isSorting = true;
            }
            catch (Exception) { }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        public void SortDialogNoAlerts(Office.IRibbonControl control, ref bool cancelDefault)
        {
            Excel.Worksheet ws = null;
            try
            {
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                if (ws.Name != "Control")
                {
                    ws.Unprotect(ETCOverviewActionPane.pwd);
                    Globals.ThisWorkbook._myActionPane.tmrWaitSortWinClose.Enabled = true;
                    cancelDefault = false;
                }
                else
                {
                    cancelDefault = true;
                }
                Globals.ThisWorkbook.isSorting = true;
            }
            catch (Exception) {
                Globals.ThisWorkbook._myActionPane.tmrWaitSortWinClose.Enabled = false;
            }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
        }

        /// <summary>
        /// Disable alerts when inserting rows from protect cells
        /// </summary>
        /// <param name="control"></param>
        /// <param name="cancelDefault"></param>
        public void InsertRowAlertsOff(Office.IRibbonControl control, ref bool cancelDefault)
        {
            Excel.Worksheet ws = null;
            try
            {
                ws = (Excel.Worksheet)Globals.ThisWorkbook.ActiveSheet;
                if (ws.Name.StartsWith(ETCOverviewActionPane.laborSheet) || ws.Name.StartsWith(ETCOverviewActionPane.nonLaborSheet))
                {
                    ws.Unprotect(ETCOverviewActionPane.pwd);
                    ws.Application.ActiveWindow.RangeSelection.EntireRow.Select();
                    ws.Application.ActiveWindow.RangeSelection.EntireRow.Insert(Excel.XlInsertShiftDirection.xlShiftDown);
                }
            }
            catch (Exception) { }
            finally
            {
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
            }
            cancelDefault = true;
        }
        #endregion

        #region Helpers

        private static string GetResourceText(string resourceName)
        {
            Assembly asm = Assembly.GetExecutingAssembly();
            string[] resourceNames = asm.GetManifestResourceNames();
            for (int i = 0; i < resourceNames.Length; ++i)
            {
                if (string.Compare(resourceName, resourceNames[i], StringComparison.OrdinalIgnoreCase) == 0)
                {
                    using (StreamReader resourceReader = new StreamReader(asm.GetManifestResourceStream(resourceNames[i])))
                    {
                        if (resourceReader != null)
                        {
                            return resourceReader.ReadToEnd();
                        }
                    }
                }
            }
            return null;
        }

        #endregion
    }
}
