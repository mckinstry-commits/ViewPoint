using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Office.Tools.Ribbon;
using System.Windows.Forms;
using Tools = Microsoft.Office.Tools;

namespace McKinstry.ViewPoint.Subcontract
{
    public partial class SubcontractRibbon
    {
        private Tools.CustomTaskPane ctp;
        private SubcontractTaskPanel stp;
        private MasterContractTaskPane mstp;

        private void SubcontractRibbon_Load(object sender, RibbonUIEventArgs e)
        {

        }

        private void bSubContracts_Click(object sender, RibbonControlEventArgs e)
        {
            stp = new SubcontractTaskPanel();
            stp.isChangeOrder = false;
            ShowSubContractTaskPanel("Subcontract Pane");
        }

        public void ShowSubContractTaskPanel(string Title)
        {
            var width = stp.Width;
            if (Globals.ThisAddIn.CustomTaskPanes.Count <= 0)
            {
                ctp = Globals.ThisAddIn.CustomTaskPanes.Add(stp, Title);
                ctp.Visible = true;
            }
            else
            {
                Globals.ThisAddIn.CustomTaskPanes.RemoveAt(0);
                ctp = Globals.ThisAddIn.CustomTaskPanes.Add(stp, Title);
                ctp.Visible = true;
            }

            ctp.Width = width+10;
            
         
        }

        public void HideTaskPanel()
        {
            //Hide the first Custom control.
            Globals.ThisAddIn.CustomTaskPanes[0].Control.Visible = false;
        }

       

        public void ShowMasterContractTaskPanel()
        {
            var width = mstp.Width;
            if(Globals.ThisAddIn.CustomTaskPanes.Count >0 )
            {
                Globals.ThisAddIn.CustomTaskPanes.RemoveAt(0);
            }
            ctp = Globals.ThisAddIn.CustomTaskPanes.Add(mstp, "Master Subcontract Pane");
            ctp.Visible = true;
            ctp.Width = width+10;
        }


        public void ShowSampleContractTaskPanel()
        {
            var width = mstp.Width;
            if (Globals.ThisAddIn.CustomTaskPanes.Count > 0)
            {
                Globals.ThisAddIn.CustomTaskPanes.RemoveAt(0);
            }
            ctp = Globals.ThisAddIn.CustomTaskPanes.Add(mstp, "Sample Subcontract Pane");
            ctp.Visible = true;
            ctp.Width = width +10;
        }

        private void bChangeOrder_Click(object sender, RibbonControlEventArgs e)
        {
            stp = new SubcontractTaskPanel();
            stp.isChangeOrder = true;
            ShowSubContractTaskPanel("Subcontract Change Order");
        }

        private void bMasterContract_Click(object sender, RibbonControlEventArgs e)
        {
            mstp = new MasterContractTaskPane();
            mstp.isSample = false;
            ShowMasterContractTaskPanel();
        }

        private void bSample_Click(object sender, RibbonControlEventArgs e)
        {
            mstp = new MasterContractTaskPane();
            mstp.isSample = true;
            Button b = (Button)mstp.Controls["bGenerateMaster"];
            b.Text = "Generate Sample";
            ShowSampleContractTaskPanel();
        }

        private void bSubOrder_Click(object sender, RibbonControlEventArgs e)
        {
            stp = new SubcontractTaskPanel();
            stp.isChangeOrder = false;
            ShowSubContractTaskPanel("Master Subcontract Order");
        }
    }
}
