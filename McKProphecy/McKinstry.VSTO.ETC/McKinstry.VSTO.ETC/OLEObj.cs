using System;
using MSForms = Microsoft.Vbe.Interop.Forms;
using Excel = Microsoft.Office.Interop.Excel; // using Shared Add-in template (caters multiple Office applications)

namespace McKinstry.ETC.Template
{
    /* PURPOSE: Provides OLE Object creation
     * AUTHOR:  Leonel Gurdian
     * 
     * CREATED:       10/13/2017
     * LAST MODIFIED: 10/13/2017
     * NOTES:         More object types can be added as needed
     */
    internal static class OLEObj
    {
        public static MSForms.CommandButton CreateOLEButton(Excel.Worksheet ws, string btnName, string btnCaption, double Left, double Top, double Width, double Height,
                                                            MSForms.CommandButtonEvents_ClickEventHandler clickCallback)
        {
            MSForms.CommandButton button = null;

            try
            {
                // insert button shape
                Excel.Shape cmdButton = ws.Shapes.AddOLEObject("Forms.CommandButton.1", Type.Missing, false, false, Type.Missing, Type.Missing, Type.Missing, Left, Top, Width, Height);
                cmdButton.Name = btnName;

                // bind it and wire it up
                button = (Microsoft.Vbe.Interop.Forms.CommandButton)Microsoft.VisualBasic.CompilerServices.NewLateBinding.LateGet(ws, null, btnName, new object[0], null, null, null);
                button.FontSize = 10;
                button.FontBold = true;
                button.Caption = btnCaption;
                button.Click += new MSForms.CommandButtonEvents_ClickEventHandler(clickCallback);
            }
            catch (Exception)
            {
                throw;
            }

            return button;
        }

        #region COMBOBOX
        //public static MSForms.ComboBox CreateCombobox(Excel.Worksheet ws, string cboName, string cboCaption, double Left, double Top, double Width, double Height,
        //                                    MSForms.MdcComboEvents_ChangeEventHandler changeCallback)
        //{
        //    MSForms.ComboBox comboBox = null;

        //    try
        //    {
        //        // insert object shape
        //        Excel.Shape cbo = ws.Shapes.AddOLEObject("Forms.ComboBox.1", Type.Missing, false, false, Type.Missing, Type.Missing, Type.Missing, Left, Top, Width, Height);
        //        cbo.Name = cboName;

        //        // bind it and wire it up
        //        comboBox = (Microsoft.Vbe.Interop.Forms.ComboBox)Microsoft.VisualBasic.CompilerServices.NewLateBinding.LateGet(ws, null, cboName, new object[0], null, null, null);
        //        comboBox.FontSize = 10;
        //        comboBox.FontBold = true;
        //        comboBox.Change += new MSForms.MdcComboEvents_ChangeEventHandler(changeCallback);
        //    }
        //    catch (Exception)
        //    {
        //        throw;
        //    }

        //    return comboBox;
        //}
        #endregion

    }
}
