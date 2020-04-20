namespace ViewpointXRef.UI
{

    // Code-behind class for the Forbidden page.
    // Place your customizations in Section 1. Do not modify Section 2.
    public partial class ForbiddenMobile : BaseApplicationPage
    {

#region "Section 1: Place your customizations here."

        public ForbiddenMobile()
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
      
#endregion

    }
}