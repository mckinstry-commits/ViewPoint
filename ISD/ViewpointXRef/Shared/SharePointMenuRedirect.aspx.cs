using System;
namespace ViewpointXRef.UI
{
    
    // Code-behind class for the Forbidden page. This page is needed to provide correct redirects of SharePoint application
    // outside Microsoft SharePoint environment
    public partial class SharePointMenuRedirect : BaseApplicationPage
    {
        
        public SharePointMenuRedirect()
        {
            this.IsUpdatesSessionNavigationHistory = false;
            this.Load += new EventHandler(Page_Load);
        }
        
        protected void Page_Load(object sender, System.EventArgs e)
        {
            if ((this.Page.Request != null) && (this.Page.Request.QueryString != null)) {
                //First check if HttpRequest has aspxerrorpath url parameter
                string url = this.Page.Request.QueryString["aspxerrorpath"];
                if (string.IsNullOrEmpty(url)) return;
                string slash = "/";
                if (url.IndexOf(slash) < 0 && url.IndexOf("\\") >= 0) slash = "\\"; 
                
                //If this is SharePoint application running in non-sharepoint environment, than it will have /_layouts/ in the path.
                int index = url.ToLowerInvariant().IndexOf(slash + "_layouts" + slash);
                if ((url != null) && url.ToLowerInvariant().EndsWith("aspx") && index >= 0) {
                    index = index + "_layouts".Length + 1;
                    //Get page url for non-sharepoint environment.
                    url = this.GetPageUrl(url, slash, index);
                    if (!string.IsNullOrEmpty(url)) this.Page.Response.Redirect(url); 
                }
                else if ((url != null) && index >= 0 && this.IsImage(url)) {
                    index = index + "_layouts".Length + 1;
                    //Get image url for non-sharepoint environment
                    url = this.GetPageUrl(url, slash, index);
                    //Me.GetImageUrl(url, slash)
                    if (!string.IsNullOrEmpty(url) && System.IO.File.Exists(Server.MapPath(url))) {

                        url = this.ProcessURLForPagination(url);
                        byte[] content = System.IO.File.ReadAllBytes(Server.MapPath(url));
                        if ((content != null) && content.Length > 0) {
                            //Feed content of the image file back to page
                            BaseClasses.Utils.NetUtils.WriteResponseBinaryAttachment(this.Page.Response, url, content, 0, false);
                        }
                    }
                }
            }
        }

        private string ProcessURLForPagination(string url)
        {
	        string imageFileName = System.IO.Path.GetFileName(url);
	        if (string.IsNullOrEmpty(imageFileName))
		        return url;
	        switch (imageFileName.ToLower(System.Globalization.CultureInfo.InvariantCulture)) {
		        case "buttonbarbackground.gif":
		        case "buttonbarincrement.gif":
		        case "buttonbarincrementover.gif":
			        return url.Replace(imageFileName, "_" + imageFileName);
		        default:
			        return url;
	        }
        }
        
        //Check if url provided is pointing to the image with know extension
        private bool IsImage(string link)
        {
            string llink = link.ToLower(System.Globalization.CultureInfo.InvariantCulture);
            if (llink.EndsWith("gif") || llink.EndsWith("jpg") || llink.EndsWith("png") || llink.EndsWith("tiff")) {
                return true;
            }
            return false;
        }
        
        //Get page url for non-sharepoint environment
        private string GetPageUrl(string url, string slash, int index)
        {
            try {
                if (url.ToLower(System.Globalization.CultureInfo.InvariantCulture).IndexOf(slash + "ViewpointXRef".ToLower(System.Globalization.CultureInfo.InvariantCulture), index) >= 0)
                {
                    index = url.ToLower(System.Globalization.CultureInfo.InvariantCulture).IndexOf(slash + "ViewpointXRef".ToLower(System.Globalization.CultureInfo.InvariantCulture), index) + (slash + "ViewpointXRef").Length;
                }
                url = "~" + url.Substring(index);
                return url;
            }
            catch (Exception) {
                return "";
            }
        }
        
    }
}