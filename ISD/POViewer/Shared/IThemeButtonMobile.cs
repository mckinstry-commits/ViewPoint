
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IThemeButtonMobile {

#region Interface Properties
        
        System.Web.UI.WebControls.LinkButton Button {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  