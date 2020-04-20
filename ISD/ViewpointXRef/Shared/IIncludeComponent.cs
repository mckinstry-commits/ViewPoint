
using Microsoft.VisualBasic;
  
namespace ViewpointXRef.UI
{

  

    public interface IIncludeComponent {

#region Interface Properties
        
      bool Visible {get; set;}
      string ID {get; set;}
         
      void SaveData();
        

#endregion

    }

  
}
  