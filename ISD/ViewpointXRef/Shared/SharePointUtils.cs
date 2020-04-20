using BaseClasses.Configuration;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Administration;
using System;

namespace ViewpointXRef.UI
{
    
    //Class implements all functionality which requires presence of Sharepoint DLL 
    public class SharePointUtils : BaseClasses.Utils.ISharePointFunctions
    {
        
        //Retrieves roles from SharePoint for currently logged in user
        public string GetUserRoles() 
        {
            try {
                if (Microsoft.SharePoint.SPContext.Current == null) return ""; 
                string roles = null;
                System.Uri newuri = new System.Uri(Microsoft.SharePoint.SPContext.Current.Web.Url);
                SPWebApplication webApp = SPWebApplication.Lookup(newuri);
                if ((webApp != null)) {
                    foreach (SPSite site in webApp.Sites) {
                        string siteUrl = site.Url.Substring(Microsoft.SharePoint.SPContext.Current.Web.Url.Length);
                        siteUrl = siteUrl.Replace("\\", "/");
                        if (!siteUrl.StartsWith("/")) {
                            siteUrl = "/" + siteUrl;
                        }
                        string siteID = "{" + site.ID.ToString() + "}";
                        try {   
                            if ((site != null) && (site.RootWeb != null) && 
                               (site.RootWeb.CurrentUser != null) &&
                               (site.RootWeb.CurrentUser.Groups != null) &&
                               (!(site.RootWeb.CurrentUser.Groups.Count == 0)))
                            {
                                foreach (SPGroup g in site.RootWeb.CurrentUser.Groups) {
                                    if (!string.IsNullOrEmpty(roles)) roles = roles + ";"; 
                                    roles = roles + siteUrl + siteID + BaseClasses.Utils.SystemUtils.ROLE_SITE_SEPARATOR + g.Name;
                                }
                            
                            }
                         }
                        catch { }
                    }
                }
                else {
                    //can't retrieve web application. Use current collection only
                    SPSite site = Microsoft.SharePoint.SPContext.Current.Site;
                    string siteUrl = site.Url.Substring(Microsoft.SharePoint.SPContext.Current.Web.Url.Length);
                    siteUrl = siteUrl.Replace("\\", "/");
                    if (!siteUrl.StartsWith("/")) {
                        siteUrl = "/" + siteUrl;
                    }
                    string siteID = "{" + site.ID.ToString() + "}";
                    if ((site != null) && (site.RootWeb != null) && 
                               (site.RootWeb.CurrentUser != null) &&
                               (site.RootWeb.CurrentUser.Groups != null) &&
                               (!(site.RootWeb.CurrentUser.Groups.Count == 0)))
                    {
                        foreach (SPGroup g in site.RootWeb.CurrentUser.Groups) {
                            roles = roles + siteUrl + siteID + BaseClasses.Utils.SystemUtils.ROLE_SITE_SEPARATOR + g.Name + ";";
                        }                        
                    }
                }
                return roles;
            }
            catch (Exception) {
                return "";
            }
        }
        
        
        //Verifies if SharePoint context is present
        public bool IsSPContextPresent() 
        {
            try {
                if ((Microsoft.SharePoint.SPContext.Current != null)) {
                    return true;
                }
                return false;
            }
            catch (Exception) {
                return false;
            }
        }
        
        //Sets username and userLoginName to currently logged in user in Sharepoint
        public void SetUserInfo(ref string username, ref string userLoginName) 
        {
            try {
                if (Microsoft.SharePoint.SPContext.Current == null) {
                    userLoginName = "";
                    username = "";
                    return;
                }
                SPUser loggedInUser = Microsoft.SharePoint.SPContext.Current.Web.CurrentUser;
                username = loggedInUser.Name;
                userLoginName = loggedInUser.LoginName;
            }
            catch (Exception) {
                userLoginName = "";
                username = "";
            }
        }
    }
}