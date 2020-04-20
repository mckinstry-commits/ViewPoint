using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;

namespace McKinstry.Data.Models.Viewpoint
{
    [DataContract]
    public class ContractItems : List<ContractItem>
    {
        public ContractItems()
        {
            new List<ContractItem>();
        }
    }

    [DataContract]
    public class ContractItem
    {
        [DataMember]
        public int CompanyId { get; set; }

        [DataMember]
        public string ContractId { get; set; }

        [DataMember]
        public string ContractItemId { get; set; }

        [DataMember]
        public string ContractItemName { get; set; }

    }

}
