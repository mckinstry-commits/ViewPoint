﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Xml.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
using Microsoft.Office.Tools.Excel;
using Microsoft.VisualStudio.Tools.Applications.Runtime;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Core;

namespace McK.ARStatement.Viewpoint
{
    public partial class BaseResults
    {
        private void BaseResults_Startup(object sender, System.EventArgs e)
        {
        }

        private void BaseResults_Shutdown(object sender, System.EventArgs e)
        {
        }


        #region VSTO Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InternalStartup()
        {
            this.Startup += new System.EventHandler(BaseResults_Startup);
            this.Shutdown += new System.EventHandler(BaseResults_Shutdown);
        }

        #endregion

    }
}
