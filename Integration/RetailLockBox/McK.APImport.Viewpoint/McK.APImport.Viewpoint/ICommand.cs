using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using log4net;
using McK.APImport.Common;

namespace McK.APImport.Viewpoint
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
