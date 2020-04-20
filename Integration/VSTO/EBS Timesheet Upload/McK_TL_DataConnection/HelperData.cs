using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace McK.Data.Viewpoint
{
    public static class HelperData
    {
        public static AppSettingsReader _config
        {
            get { return new AppSettingsReader(); }
        }

        public static string _conn_string
        {
            get { return (string)_config.GetValue("ViewpointConnection", typeof(string)); }
        }

    }
}
