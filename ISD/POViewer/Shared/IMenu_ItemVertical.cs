
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IMenu_ItemVertical {

#region Interface Properties
        
        System.Web.UI.WebControls.LinkButton Button {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  