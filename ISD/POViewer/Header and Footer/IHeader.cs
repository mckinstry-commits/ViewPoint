
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IHeader {

#region Interface Properties
        
        System.Web.UI.WebControls.ImageButton HeaderSettings {get;}
                System.Web.UI.WebControls.DropDownList LanguageSelector {get;}
                
        System.Web.UI.WebControls.Image Logo {get;}
                
        System.Web.UI.WebControls.LinkButton SignIn {get;}
                
        System.Web.UI.WebControls.HyperLink SkipNavigationLinks {get;}
                System.Web.UI.WebControls.DropDownList ThemeSelector {get;}
                
        System.Web.UI.WebControls.Label UserStatusLbl {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  