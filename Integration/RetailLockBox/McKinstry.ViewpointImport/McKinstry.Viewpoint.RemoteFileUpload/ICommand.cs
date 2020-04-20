﻿using System;
using log4net;

namespace McKinstry.Viewpoint.RemoteFileUpload
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