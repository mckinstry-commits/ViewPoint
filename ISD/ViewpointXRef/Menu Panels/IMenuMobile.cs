
using Microsoft.VisualBasic;
  
namespace ViewpointXRef.UI
{

  

    public interface IMenuMobile {

#region Interface Properties
        System.Web.UI.WebControls.Menu MultiLevelMenu {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  