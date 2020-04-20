SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
    
    
    
    Modified by CR 2/27/03 - added OpenYN field
    Modified by E.T. 09/30/2004 - removed ARTH info so everything is coming from ARTL
    Modified by CR 4/19/06 - added the Retainage field to the view
    Reports: AR Customer Accounts by Contract
    
    */
    
     
     CREATE         view [dbo].[brvAROpenTrans] as 
     select ARTL.ARCo, ARTL.ApplyMth, ARTL.ApplyTrans, MaxMth=max(ARTL.Mth), Amount=sum(ARTL.Amount),Ret=sum(ARTL.Retainage),
     OpenYN=Case when Sum(ARTL.Amount) <> 0 and Sum(ARTL.Retainage)<> 0 then 'Y' else 'N' end
  
      From ARTL
     Group By ARTL.ARCo, ARTL.ApplyMth, ARTL.ApplyTrans
 
   
 
 


GO
GRANT SELECT ON  [dbo].[brvAROpenTrans] TO [public]
GRANT INSERT ON  [dbo].[brvAROpenTrans] TO [public]
GRANT DELETE ON  [dbo].[brvAROpenTrans] TO [public]
GRANT UPDATE ON  [dbo].[brvAROpenTrans] TO [public]
GO
