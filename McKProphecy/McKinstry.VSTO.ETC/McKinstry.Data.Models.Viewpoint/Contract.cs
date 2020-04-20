using System.Collections.Generic;

namespace McKinstry.Data.Models.Viewpoint
{
    public class Contracts : List<Contract>
    {
        public Contracts()
        {
            new List<Contract>();
        }
    }

    public class Contract
    {
        public Contract() { this.Projects = new List<string>(); }

        public Contract(byte co, string contractId, string trimContract, List<string> projects)
        {
            JCCo = co;
            ContractId = contractId;
            TrimContractId = trimContract;
            Projects = projects;
        }

        public byte JCCo { get; set; }

        public string ContractId { get; set; }

        public string TrimContractId { get; set; }

        public string ContractName { get; set; }

        public List<string> Projects { get; set; }

    }
}
