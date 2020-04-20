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
namespace McKinstry.ViewPoint.Subcontract
{
    public partial class MasterContractTaskPane : UserControl
    {
        Word.Document doc = null;
        string companyNumber;
        string vendorGroup;
        int Seq;
        public bool isSample { get; set; }
        public MasterContractTaskPane()
        {
            InitializeComponent();
            if (isSample)
            {
                bGenerateMaster.Text = "Generate Sample Contract";
            }
            else
                bGenerateMaster.Text = "Generate Master Contract";
        }

        private void bGenerateMaster_Click(object sender, EventArgs e)
        {
            try
            {
                if (tbVendorNumber.Text != "" )
                {
                    companyNumber = cbCompanyName.SelectedValue.ToString();
                    vendorGroup =   cbCompany.SelectedValue.ToString();

                    Seq = Convert.ToInt32(tbSequence.Text);
                    if (!isSample)
                    {
                        CreateDocument.CreateMasterContract(Globals.ThisAddIn.Application, tbVendorNumber.Text.Trim(), companyNumber,vendorGroup,Seq);
                    }
                    else
                        CreateDocument.CreateSampleSubContract(Globals.ThisAddIn.Application, tbVendorNumber.Text.Trim(), companyNumber, vendorGroup,Seq);
                }
            }
            catch (Exception ex) { MessageBox.Show(ex.Message); }
        }

        private void MasterContractTaskPane_Load(object sender, EventArgs e)
        {
            //Load VendorGroups.
            var databind = (from t in CreateDocument.Companies()
                            group t by t.VendorGroup into vg 
                            select new { Text = vg.Key , Value = vg.Key }
                        ).ToList();
            cbCompany.DataSource = databind;

            //load Company.
            var companyBind = (from t in CreateDocument.Companies()
                            select new { Text = t.Name, Value = t.HQCo1 }
                            ).ToList();
            cbCompanyName.DataSource = companyBind;
        }

        private void cbCompany_SelectedIndexChanged(object sender, EventArgs e)
        {

        }
    }
}
