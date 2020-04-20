using System;
using log4net;
using System.Collections.Generic;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewoint.CompanyMove
{
    /// <summary>
    /// Command interface
    /// </summary>
    internal interface ICommand
    {
        string Name { get; }
        string Description { get; }
        void RunWith(ILog log);
    }
}
