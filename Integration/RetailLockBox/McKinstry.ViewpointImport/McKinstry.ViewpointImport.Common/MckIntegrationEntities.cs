using System;

namespace McKinstry.ViewpointImport.Common
{
    public partial class MckIntegrationEntities
    {
        // Add new constructor to pass custom connection string to DbContext
        public MckIntegrationEntities(string connectionString) : base(connectionString) { }
    }
}
