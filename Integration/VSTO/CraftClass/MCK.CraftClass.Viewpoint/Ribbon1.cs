using Microsoft.Office.Tools.Ribbon;
using System.Windows.Forms;
using Excel = Microsoft.Office.Interop.Excel;
using OfficeCore = Microsoft.Office.Core;
using Office = Microsoft.Office.Tools;
using System.Collections.Generic;
using System;
using System.Runtime.InteropServices;

namespace MCK.CraftClass.Viewpoint
{
    public partial class Ribbon1
    {
        internal Excel.Workbook MyActiveWorkbook { get; set; }

        internal Excel.Worksheet MyDataSheet => (Excel.Worksheet)MyActiveWorkbook?.Sheets["Data"];


        // Associate pane to active window if needed
        private bool IsValidTemplate
        {
            get
            {
                if (Globals.ThisAddIn.Application.ActiveProtectedViewWindow != null)
                {
                    MessageBox.Show(null, "The Worksheet is in Protected View.\n\n" + "" +
                                          "Click 'Enable Editing' to use this tool.", "Oops", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return false;
                }

                return IsValidCraftClassTemplate();
            }
        }

        private void Ribbon1_Load(object sender, RibbonUIEventArgs e){}

        /// <summary>
        /// Perform Craft class updates in Viewpoint
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnUpdate_Click(object sender, RibbonControlEventArgs e)
        {
            if (IsValidTemplate)
            {
                if (MessageBox.Show("Are you sure you want to update Craft Class rates in Viewpoint?", "Question", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    AttachPaneToActiveTemplate();
                    btnShowPane_Click(sender, e);
                    Globals.ThisAddIn.TaskPaner1.UpdateCraftClasses();
                }
            }   
        }

        /// <summary>
        /// Excel vs Viewpoint variances report
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnCheckVariances_Click(object sender, RibbonControlEventArgs e)
        {
            if (IsValidTemplate)
            {
                AttachPaneToActiveTemplate();
                btnShowPane_Click(sender, e);
                Globals.ThisAddIn.TaskPaner1.CheckViewpointVariances();
            }
        }

        /// <summary>
        /// List of Crafts to Update report
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnCraftsToUpdate_Click(object sender, RibbonControlEventArgs e)
        {

            if (IsValidTemplate)
            {
                AttachPaneToActiveTemplate();
                btnShowPane_Click(sender, e);
                Globals.ThisAddIn.TaskPaner1.CraftsToUpdateReport();
            }
        }

        /// <summary>
        /// Show/Hide the Action Pane
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnShowPane_Click(object sender, RibbonControlEventArgs e)
        {

            try
            {
                if (((RibbonButton)sender).Id == "btnShowPane")
                {
                    // toggle visibility
                    foreach (var pane in Globals.ThisAddIn.CustomTaskPanes)
                    {
                        if (btnShowPane.Label == "Show Pane")
                        {
                            pane.Visible = true;
                        }
                        else
                        {
                            pane.Visible = false;
                        }
                    }

                    // toggle button
                    if (btnShowPane.Label == "Show Pane")
                    {
                        btnShowPane.Label = "Hide Pane";
                    }
                    else
                    {
                        btnShowPane.Label = "Show Pane";
                    }
                }
                else
                {
                    foreach (var pane in Globals.ThisAddIn.CustomTaskPanes)
                    {
                        pane.Visible = true;
                        btnShowPane.Label = "Hide Pane";
                    }
                }
            }
            catch (Exception ex)
            {
                Globals.ThisAddIn.TaskPaner1.errOut(ex);
            }
        }

        /// <summary>
        /// Checks for valid Craft Class template 
        /// </summary>
        /// <returns>if null, template is not valid</returns>
        private bool IsValidCraftClassTemplate()
        {
            Excel.Worksheet ws = null;
            bool isValidCraftClassTemplate = false;

            try
            {
                // these names must exist for template to be valid
                List<string> namedRanges = new List<string>() { "Info_and_Notes", "Pay_Rates", "Addon_Earnings", "Dedns_Liabs" };

                ws = HelperUI.GetSheet("Data"); // (Excel.Worksheet)Globals.ThisAddIn.Application.ActiveSheet;

                if (ws != null) {

                    ws.Activate();

                    // check required named ranges exist
                    string named;
                    foreach (dynamic c in ws.Names)
                    {
                        named = c.Name.ToString().Split('!')[1];

                        if (namedRanges.Exists(name => name == named))
                        {
                            namedRanges.Remove(named);
                        }
                        isValidCraftClassTemplate = namedRanges.Count == 0;
                        if (isValidCraftClassTemplate) break;
                    }
                }

                if (!isValidCraftClassTemplate)
                {
                    MessageBox.Show(null,"The active worksheet is not a valid Craft Class template.\n\n" +
                                                       "Missing named ranges:\n" +
                                                       "---------------------\n" +
                                                       string.Join("\n", namedRanges),"Oops", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                Globals.ThisAddIn.TaskPaner1.errOut(ex);
            }

            return isValidCraftClassTemplate;
        }

        /// <summary>
        /// Attach Action Pane to the Active Template but only after IsValidTemplate()
        /// </summary>
        private void AttachPaneToActiveTemplate()
        {
            try
            {
                bool paneIsAttachedToTemplate = false;

                Excel.Window activeWindow = Globals.ThisAddIn.Application.ActiveWindow;

                if (activeWindow != null) // Protected View file would be null
                {
                    MyActiveWorkbook = activeWindow.Parent;

                    // is pane attached to active template ?
                    foreach (var pane in Globals.ThisAddIn.CustomTaskPanes)
                    {
                        Excel.Window w = (Excel.Window)pane.Window;
                        if (w.Hwnd == activeWindow.Hwnd && pane.Title == "Craft Class Maintenance")
                        {
                            paneIsAttachedToTemplate = true;
                            break;
                        }
                    }

                    if (!paneIsAttachedToTemplate)
                    {
                        // attach it
                        Globals.ThisAddIn.TaskPaner1.AutoSize = false;
                        Globals.ThisAddIn.TaskPaner1.AutoSizeMode = AutoSizeMode.GrowOnly;
                        Globals.ThisAddIn.TaskPaner1.AutoScaleMode = AutoScaleMode.Inherit;
                        Office.CustomTaskPane pane = Globals.ThisAddIn.CustomTaskPanes.Add(Globals.ThisAddIn.TaskPaner1, "Craft Class Maintenance", activeWindow);
                        pane.DockPosition = OfficeCore.MsoCTPDockPosition.msoCTPDockPositionLeft;
                        pane.Width = 107;
                    }
                }
            }
            catch (Exception ex)
            {
                Globals.ThisAddIn.TaskPaner1.errOut(ex);
            }
        }

    }
}
