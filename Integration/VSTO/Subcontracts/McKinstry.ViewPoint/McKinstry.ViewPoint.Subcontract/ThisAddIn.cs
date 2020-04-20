using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using System.Text;
using System.Xml.Linq;
using Word = Microsoft.Office.Interop.Word;
using Office = Microsoft.Office.Core;
using Microsoft.Office.Tools.Word;
using Tools = Microsoft.Office.Tools;

namespace McKinstry.ViewPoint.Subcontract
{
    public partial class ThisAddIn
    {
        private Tools.CustomTaskPane ctp;
        private SubcontractTaskPanel stp;
        private void ThisAddIn_Startup(object sender, System.EventArgs e)
        {
            //ShowTaskPanel();
        }

        private void ThisAddIn_Shutdown(object sender, System.EventArgs e)
        {
            HideTaskPanel();
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
        }

     

        public void ShowTaskPanel()
        {
            stp = new SubcontractTaskPanel();
            ctp = this.CustomTaskPanes.Add(stp,"Subcontract Task Pane");
            ctp.Visible = true;
        }

        public void HideTaskPanel()
        {
            //ctp.Visible = false;
        }

        
        #endregion
    }
}
