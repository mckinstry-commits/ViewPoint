using System;
using log4net;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    /// <summary>
    /// Command interface
    /// </summary>
    internal interface ICommand
    {
        string Name { get; }
        string Description { get; }
        void RunWith(ILog log, string fileName, RLBImportBatch batch, APImportFile file);
    }
}
