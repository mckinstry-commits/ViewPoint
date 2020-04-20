using System.Collections.Generic;
using System.Runtime.Serialization;

namespace McKinstry.Data.Models.Viewpoint
{
    /// <summary>
    /// Companies Class
    /// </summary>
    public class Companies : List<Company>
    {
        public Companies()
        {
            new List<Company>();
        }
    }

    /// <summary>
    /// Company Class
    /// </summary>
    public partial class Company
    {
        [DataMember]
        public int CompanyId { get; set; }

        [DataMember]
        public string CompanyName { get; set; }
    }

}
