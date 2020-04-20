using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;

namespace McKinstry.Data.Models.Viewpoint
{
    [DataContract]
    public class Contracts : List<Contract>
    {
        public Contracts()
        {
            new List<Contract>();
        }
    }

    [DataContract]
    public class Contract 
    {
        public Contract()
        {
            this.Items = new List<ContractItem>();           
        }

        [DataMember]
        public int CompanyId { get; set; }

        [DataMember]
        public string ContractId { get; set; }

        [DataMember]
        public string ContractName { get; set; }

        [DataMember]
        public List<ContractItem> Items { get; set; } 


    }
}
