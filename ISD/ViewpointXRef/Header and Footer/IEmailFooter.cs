﻿
using Microsoft.VisualBasic;
  
namespace ViewpointXRef.UI
{

  

    public interface IEmailFooter {

#region Interface Properties
        
        System.Web.UI.WebControls.Literal Copyright {get;}
                
      bool Visible {get; set;}
      string ID {get; set;}
         

#endregion

    }

  
}
  