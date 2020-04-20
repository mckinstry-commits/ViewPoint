
using Microsoft.VisualBasic;
  
namespace ViewpointXRef.UI
{

  

    public interface IHeader {

#region Interface Properties
        
        System.Web.UI.WebControls.Image Divider0 {get;}
                
        System.Web.UI.WebControls.Image Divider1 {get;}
                
        System.Web.UI.WebControls.Image Divider2 {get;}
                System.Web.UI.WebControls.DropDownList LanguageSelector {get;}
                
        System.Web.UI.WebControls.Image LeftImage {get;}
                
        System.Web.UI.WebControls.Literal PageTitle {get;}
                
        System.Web.UI.WebControls.Image RightImage {get;}
                
        System.Web.UI.WebControls.LinkButton SignIn {get;}
                
        System.Web.UI.WebControls.Image SignInBarPrintButton {get;}
                
        System.Web.UI.WebControls.ImageButton SIOImage {get;}
                
        System.Web.UI.WebControls.HyperLink SkipNavigationLinks {get;}
                System.Web.UI.WebControls.DropDownList ThemeSelector {get;}
                
        System.Web.UI.WebControls.Label UserStatusLbl {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  