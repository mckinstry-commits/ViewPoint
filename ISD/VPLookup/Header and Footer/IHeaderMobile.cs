
using Microsoft.VisualBasic;
  
namespace VPLookup.UI
{

  

    public interface IHeaderMobile {

#region Interface Properties
        System.Web.UI.WebControls.DropDownList LanguageSelector {get;}
                
        System.Web.UI.WebControls.LinkButton SignIn {get;}
                System.Web.UI.WebControls.DropDownList ThemeSelector {get;}
                
        System.Web.UI.WebControls.Label UserStatusLbl {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  