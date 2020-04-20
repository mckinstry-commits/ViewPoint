
using Microsoft.VisualBasic;
  
namespace VPLookup.UI
{

  

    public interface IIncludeComponentMobile {

#region Interface Properties
        
      bool Visible {get; set;}
      string ID {get; set;}
         
      void SaveData();
        

#endregion

    }

  
}
  