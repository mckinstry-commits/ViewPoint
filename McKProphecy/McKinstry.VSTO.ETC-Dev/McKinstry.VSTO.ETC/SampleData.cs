using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using McKinstry.Data.Models.Viewpoint;


namespace McKinstry.ETC.Template
{
    public class testContract : Contract
    {
        public testContract ()
        {
            this.CompanyId = 1;
            this.ContractId = "";
            this.ContractName = "Test Contract";

            this.Items.Add(new testContractItem(this.CompanyId, this.ContractId, "1", "Test Contract Item 1"));
            this.Items.Add(new testContractItem(this.CompanyId, this.ContractId, "2", "Test Contract Item 2"));
            this.Items.Add(new testContractItem(this.CompanyId, this.ContractId, "3", "Test Contract Item 3"));
            this.Items.Add(new testContractItem(this.CompanyId, this.ContractId, "4", "Test Contract Item 4"));


        }

    }

    public class testContractItem : ContractItem
    {
        public testContractItem (int CompanyId, string ContractId, string ContractItemId, string ContractItemName)
        {
            this.CompanyId = CompanyId;
            this.ContractId = ContractId;
            this.ContractItemId = ContractItemId;
            this.ContractItemName = ContractItemName;

        }
    }
}
