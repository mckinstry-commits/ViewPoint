using System;

namespace McKinstry.ViewpointImport.Common
{
    public class Db
    {
        private static string integrationConnectionString;
        public static string IntegrationConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(integrationConnectionString))
                {
                    integrationConnectionString = CommonSettings.MckIntegrationConnectionString;
                }
                return integrationConnectionString;
            }
        }

        private static string viewpointConnectionString;
        public static string ViewpointConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(viewpointConnectionString))
                {
                    viewpointConnectionString = CommonSettings.ViewpointConnectionString;
                }
                return viewpointConnectionString;
            }
        }

        public static string TrimString(string str, int length)
        {
            if (string.IsNullOrEmpty(str))
            {
                return str;
            }
            if (str.Length > length)
            {
                return str.Substring(0, length);
            }
            return str;
        }
    }
}
