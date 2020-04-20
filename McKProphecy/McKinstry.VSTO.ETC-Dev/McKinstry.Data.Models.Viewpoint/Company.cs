using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.Serialization;

namespace McKinstry.Data.Models.Viewpoint
{
    /// <summary>
    /// Companies Class
    /// </summary>
    [DataContract]
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
    [DataContract]
    public partial class Company
    {
        [DataMember]
        public int CompanyId { get; set; }

        [DataMember]
        public string CompanyName { get; set; }
    }

}
