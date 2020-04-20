using System.Collections.Generic;

namespace McKinstry.Data.Models.Viewpoint
{
    public class ContractItems : List<ContractItem>
    {
        public ContractItems()
        {
            new List<ContractItem>();
        }
    }

    public class ContractItem
    {
        public int CompanyId { get; set; }

        public string ContractId { get; set; }

        public string ContractItemId { get; set; }

        public string ContractItemName { get; set; }
    }

}
