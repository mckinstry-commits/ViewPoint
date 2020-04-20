using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using Office = Microsoft.Office.Core;
using Word = Microsoft.Office.Interop.Word;

using System.Reflection;
using VP = McKinstry.ViewPoint.Subcontract.VPService;
namespace McKinstry.ViewPoint.Subcontract
{
    public partial class SubcontractTaskPanel : UserControl
    {
        Word.Document docCurrent = null;

        public bool isChangeOrder { get; set; }

        public SubcontractTaskPanel()
        {
            InitializeComponent();
        }
        private void bGenerate_Click(object sender, EventArgs e)
        {
            try
            {
                if (isChangeOrder)
                    
                    if (tbSL.Text.Trim() != "" && tbCO.Text.Trim() !="")
                    {
                        CreateDocument.CreateSubContractChangeOrder(Globals.ThisAddIn.Application, tbSL.Text.Trim(), tbCO.Text.Trim());
                    }
                    else
                    {
                        MessageBox.Show("Please enter a valid SL# and Change Order#");
                        return;
                    }
                else
                {
                    //Get data
                    if (tbSL.Text.Trim() != "")
                    {
                        CreateDocument.CreateSubContract(Globals.ThisAddIn.Application, tbSL.Text.Trim());
                    }
                    else
                    {
                        MessageBox.Show("Please enter a valid SL#");
                        return;
                    }
                }
            }
          
            catch (Exception ex){
                MessageBox.Show(ex.Message);
            }
            finally { }

        }

        private void SubcontractTaskPanel_Load(object sender, EventArgs e)
        {
            var databind = (from t in CreateDocument.Companies()
                            select new {  Text = t.HQCo1.ToString() + "-" + t.Name, Value = t.HQCo1}
                            ).ToList();
            cbCompany.DataSource = databind;
            
            // Is it Change order template
            if (isChangeOrder)
                ShowCO();
            else
                HideCO();
        }

        private void ShowCO()
        {
            
            lCO.Visible = true;
            tbCO.Visible = true;
        }

        private void HideCO()
        {
            lCO.Visible = false;
            tbCO.Visible = false;
        }
    }
}
