
using Microsoft.VisualBasic;
  
namespace POViewer.UI
{

  

    public interface IMenu_Item_Highlighted {

#region Interface Properties
        
        System.Web.UI.WebControls.LinkButton Button {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  