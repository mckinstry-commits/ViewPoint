namespace ViewpointXRef.UI
{

    // Code-behind class for the Forbidden page.
    // Place your customizations in Section 1. Do not modify Section 2.
    public partial class Forbidden : BaseApplicationPage
    {

#region "Section 1: Place your customizations here."

        public Forbidden()
        {
            this.IsUpdatesSessionNavigationHistory = false;
        }

        // LoadData reads database data and assigns it to UI controls.
        // Customize by adding code before or after the call to LoadData_Base()
        // or replace the call to LoadData_Base().
        public void LoadData()
        {
            LoadData_Base();
        }

        public void Page_PreInit(object sender, System.EventArgs e)
        {
            //override call to PreInit_Base() here to change top level master page used by this page, for example uncomment
            //next line to use Microsoft SharePoint default master page
            //if(this.Master != null) this.Master.MasterPageFile = Microsoft.SharePoint.SPContext.Current.Web.MasterUrl;	
            //You may change here assignment of application theme
            this.PreInit_Base();
        }
#endregion

#region "Section 2: Do not modify this section."

        // Handles MyBase.Load.  If you need to, you can add additional Load handlers in Section 1.
        // Read database data and put into the UI controls.
        protected virtual void Page_Load(System.Object sender, System.EventArgs e)
        {
            // Load data only when displaying the page for the first time
            if (!this.IsPostBack)
            {

                // Read the data for all controls on the page.
                // To change the behavior, override the DataBind method for the individual
                // record or table UI controls.
                this.LoadData();

                System.Web.UI.ScriptManager.RegisterStartupScript(this, this.GetType(), "PopupScript", "openPopupPage('QPageSize');", true);   

            }
        }

        // Load data from database into UI controls. 
        // Modify LoadData in Section 1 above to customize.  Or override DataBind() in
        // the individual table and record controls to customize.
        public void LoadData_Base()
        {
            this.DataBind();
        }

        protected override void UpdateSessionNavigationHistory()
        {
            //Do nothing
        }


        public void PreInit_Base()
        {

            // if url parameter specified a master apge, load it here
            if (((BaseApplicationPage)this.Page).GetDecryptedURLParameter("RedirectStyle") == "Popup") {
	            string masterPage = "../Master Pages/Popup.master";
	            this.Page.MasterPageFile = masterPage;
            }

            if (((BaseApplicationPage)this.Page).GetDecryptedURLParameter("RedirectStyle") == "NewWindow") {
	            string masterPage = "../Master Pages/Blank.master";
	            this.Page.MasterPageFile = masterPage;
            }

            if (!string.IsNullOrEmpty(this.Page.Request["MasterPage"])) {
	            string masterPage = ((BaseApplicationPage)this.Page).GetDecryptedURLParameter("MasterPage");
	            this.Page.MasterPageFile = masterPage;
            }
        }
      
#endregion

    }
}