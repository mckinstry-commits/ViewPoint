
using Microsoft.VisualBasic;
  
namespace VPLookup.UI
{

  

    public interface IMenuMobile {

#region Interface Properties
        System.Web.UI.WebControls.Menu MultiLevelMenu {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  