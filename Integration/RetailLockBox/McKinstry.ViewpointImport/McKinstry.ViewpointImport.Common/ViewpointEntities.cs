using System;

namespace McKinstry.ViewpointImport.Common
{
    public partial class ViewpointEntities
    {
        // Add new constructor to pass custom connection string to DbContext
        public ViewpointEntities(string connectionString) : base(connectionString) {}
    }
}
