using System.DirectoryServices;

namespace McK.Data.Viewpoint
{
    // https://stackoverflow.com/questions/14813452/connect-to-active-directory-via-ldap
    public static class AD
    {
        /// <summary>
        /// Retrive user information from Active Directory Services
        /// </summary>
        /// <param name="accountName"></param>
        /// <returns></returns>
        public static dynamic GetUserInfo(string accountName)
        {
            DirectoryEntry dirEntry = new DirectoryEntry("LDAP://mckinstry.com");

            DirectorySearcher searcher = new DirectorySearcher(dirEntry)
            {
                PageSize = int.MaxValue,
                Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=" + accountName + "))"
            };
            
            //searcher.PropertiesToLoad.Add("SAMAccountName");
            searcher.PropertiesToLoad.Add("DisplayName");
            searcher.PropertiesToLoad.Add("Mail");
            searcher.PropertiesToLoad.Add("TelephoneNumber");

            var result = searcher.FindOne();
           
            return result;
        }
    }
}
