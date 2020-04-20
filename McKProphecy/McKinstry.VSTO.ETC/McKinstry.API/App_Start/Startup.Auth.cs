using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IdentityModel.Claims;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Cookies;
using Microsoft.Owin.Security.OpenIdConnect;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using Owin;
using McKinstry.API.Models;

namespace McKinstry.API
{
    public partial class Startup
    {
        private static string clientId = ConfigurationManager.AppSettings["ida:ClientId"];
        private static string appKey = ConfigurationManager.AppSettings["ida:ClientSecret"];
        private static string aadInstance = ConfigurationManager.AppSettings["ida:AADInstance"];
        private static string tenantId = ConfigurationManager.AppSettings["ida:TenantId"];
        private static string postLogoutRedirectUri = ConfigurationManager.AppSettings["ida:PostLogoutRedirectUri"];

        public static readonly string Authority = aadInstance + tenantId;

        // This is the resource ID of the AAD Graph API.  We'll need this to request a token to call the Graph API.
        string graphResourceId = "https://graph.windows.net";

        //public void ConfigureAuth(IAppBuilder app)
        //{
        //    ApplicationDbContext db = new ApplicationDbContext();

        //    app.SetDefaultSignInAsAuthenticationType(CookieAuthenticationDefaults.AuthenticationType);

        //    app.UseCookieAuthentication(new CookieAuthenticationOptions());

        //    app.UseOpenIdConnectAuthentication(
        //        new OpenIdConnectAuthenticationOptions
        //        {
        //            ClientId = clientId,
        //            Authority = Authority,
        //            PostLogoutRedirectUri = postLogoutRedirectUri,

        //            //Notifications = new OpenIdConnectAuthenticationNotifications()
        //            //{
        //            //    AuthenticationFailed = (context) =>
        //            //    {
        //            //        if (context.Exception.Message.StartsWith("OICE_20004") || context.Exception.Message.Contains("IDX10311"))
        //            //        {
        //            //            context.SkipToNextMiddleware();
        //            //            return Task.FromResult(0);
        //            //        }
        //            //        return Task.FromResult(0);
        //            //    }
        //            //}

        //            Notifications = new OpenIdConnectAuthenticationNotifications()
        //            {

        //                // If there is a code in the OpenID Connect response, redeem it for an access token and refresh token, and store those away.
        //               AuthorizationCodeReceived = (context) => 
        //               {
        //                   var code = context.Code;
        //                   ClientCredential credential = new ClientCredential(clientId, appKey);
        //                   string signedInUserID = context.AuthenticationTicket.Identity.FindFirst(ClaimTypes.NameIdentifier).Value;
        //                   AuthenticationContext authContext = new AuthenticationContext(Authority, new ADALTokenCache(signedInUserID));
        //                   AuthenticationResult result = authContext.AcquireTokenByAuthorizationCode(
        //                   code, new Uri(HttpContext.Current.Request.Url.GetLeftPart(UriPartial.Path)), credential, graphResourceId);

        //                   return Task.FromResult(0);
        //               },
        //                // 2016.03.09 - LWO - Added to work around Owin bug on Cookie Handling
        //                // Ref: https://github.com/IdentityServer/IdentityServer3/issues/542 
        //                AuthenticationFailed = (context) =>
        //               {
        //                   if (context.Exception.Message.StartsWith("OICE_20004") || context.Exception.Message.Contains("IDX10311"))
        //                   {
        //                       context.SkipToNextMiddleware();
        //                       return Task.FromResult(0);
        //                   }
        //                   return Task.FromResult(0);
        //               }
        //            }
        //        });
        //}
    }
}
