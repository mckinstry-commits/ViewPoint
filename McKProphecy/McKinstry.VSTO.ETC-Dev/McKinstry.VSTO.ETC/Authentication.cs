using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;
using System.Globalization;
using System.Net.Http;
using System.Net.Http.Headers;
using Microsoft.IdentityModel.Clients.ActiveDirectory;


namespace McKinstry.ETC.Template
{
    class Authentication
    {
        public static string TokenForUser;

        private static string aadInstance = "https://login.windows.net/98db3f1b-6b74-4afe-8a78-49574c36ec45";
        private static string tenant = "mckinstry871.onmicrosoft.com";
        private static string clientId = "5d27ea2e-f4e9-4e42-b704-763d04b40bbc";
        private static string apiResourceId = "http://mckapi.mckinstry.com/";

        //private static string clientId = "5d5040bb-583f-487e-837f-e8859289bf95";      
        //private static string apiResourceId = "http://mckapi.mckinstry.com/";

        private static string apiBaseAddress = "http://mckapi.mckinstry.com/";

        public static string authority = String.Format(CultureInfo.InvariantCulture, aadInstance, tenant);

        

        private static AuthenticationContext authContext = null;

        public static AuthenticationResult GetAuth(string Login, string Password)
        {

            AuthenticationResult retValue = CallWebAPI(Login, Password).Result;
            return retValue;

        }

        static async Task<AuthenticationResult> CallWebAPI(string Login, string Password)
        {
            //FROM
            //http://blogs.msdn.com/b/microsoft_azure_simplified/archive/2015/03/23/getting-started-using-azure-active-directory-aad-for-authenticating-automated-clients-C:\Users\aaudretsch\Documents\Visual Studio 2015\Projects\McKinstryAuth\McKinstry.Vista\McKinstry.Vista.Services\Content\c.aspx 
            //

            authContext = new AuthenticationContext(authority);
            //      PlatformParameters _authParms = new PlatformParameters(PromptBehavior.Always);       

            AuthenticationResult result = null;
            try
            {

                //result = await authContext.AcquireTokenAsync(apiResourceId, certCred);
                // result = await authContext.AcquireTokenAsync(apiResourceId, clientId, new n Uri("http://mckvistaservicesdevclient"), _authParms);

                //UserCredential _cred = new UserCredential("MattOD@mckinstry.com", "@ttun!x2006");
                //UserCredential _cred = new UserCredential("billo@mckinstry.com", "Loreba1ug");
                UserCredential _cred = new UserCredential(Login, Password);


                //var credential = new ClientCredential(clientId, clientSecret);
                //var bootstrapContext = (BootstrapContext)ClaimsPrincipal.Current.Identities.First().BootstrapContext;
                //string userName = ClaimsPrincipal.Current.FindFirst(ClaimTypes.Upn) != null ? ClaimsPrincipal.Current.FindFirst(ClaimTypes.Upn).Value : ClaimsPrincipal.Current.FindFirst(ClaimTypes.Email).Value;
                //string userAccessToken = bootstrapContext.Token;
                //var userAssertion = new UserAssertion(userAccessToken, USER_ASSERTION_BOILERPLATE, "MattOD@mckinstry.com");
                //authContext.AcquireTokenAsync()
                //    result = authContext.AcquireTokenAsync(apiResourceId, credential).Result;

                result = authContext.AcquireTokenAsync(apiResourceId, clientId, _cred).Result;


            }
            catch (AdalException)
            {
                //May be retry
            }
            catch (Exception) { }
            var clientHandler = new HttpClientHandler()
            {
                UseDefaultCredentials = true
            };


            var httpClient = new HttpClient(clientHandler);
            
            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", result.AccessToken);

            HttpResponseMessage response = null;
            try

            {
                response = await httpClient.GetAsync(apiBaseAddress + "api/v1/companies");
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
            if (response.IsSuccessStatusCode)
            {
                string s = await response.Content.ReadAsStringAsync();
                Console.WriteLine(s);
            }
            else
            {
                Console.WriteLine("ERROR :" + response.StatusCode);
            }
            return result;
        }
    }

}
