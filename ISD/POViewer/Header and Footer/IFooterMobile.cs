
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IFooterMobile {

#region Interface Properties
        
        System.Web.UI.WebControls.Literal CopyrightMobile {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  