SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================            
      
Author:         
Scott Alvey      
      
Create date:         
07/11/2012       
      
Usage:  
Helps the vrvSMAgreementQuoteServiceDetails link Agreement information to serviceable
item tasks
      
Things to keep in mind:  
      
Related reports:    
     
Revision History            
Date  Author   Issue      Description  
    
==================================================================================*/   
  
CREATE view [dbo].[vrvSMServiceItemWithAgreement] as  
  
select  
 smsi.*  
 , smas.Agreement  
 , smas.Revision  
 , smas.Service  
from  
 SMServiceItems smsi  
join  
 SMAgreementService smas on  
  smsi.SMCo = smas.SMCo  
  and smsi.ServiceSite = smas.ServiceSite
GO
GRANT SELECT ON  [dbo].[vrvSMServiceItemWithAgreement] TO [public]
GRANT INSERT ON  [dbo].[vrvSMServiceItemWithAgreement] TO [public]
GRANT DELETE ON  [dbo].[vrvSMServiceItemWithAgreement] TO [public]
GRANT UPDATE ON  [dbo].[vrvSMServiceItemWithAgreement] TO [public]
GRANT SELECT ON  [dbo].[vrvSMServiceItemWithAgreement] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSMServiceItemWithAgreement] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSMServiceItemWithAgreement] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSMServiceItemWithAgreement] TO [Viewpoint]
GO
