SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE    view [dbo].[brvPRAttachments]
   as
   select a.PRCo, a.JCCo, a.CostTrans,a.LiabilityType, b.PRGroup, b.PREndDate, 
   Date= (Case when PRCO.JCIPostingDate = 'N' then a.ActualDate else b.PostDate end ), a.Employee, b.UniqueAttchID
   
   from JCCD a 
   
   Left join PRTH b on b.PRCo=a.PRCo and b.Employee=a.Employee --and 
   --b.PREndDate=a.ActualDate
   Inner Join PRCO on b.PRCo=PRCO.PRCo
   
   where b.UniqueAttchID is not null 
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPRAttachments] TO [public]
GRANT INSERT ON  [dbo].[brvPRAttachments] TO [public]
GRANT DELETE ON  [dbo].[brvPRAttachments] TO [public]
GRANT UPDATE ON  [dbo].[brvPRAttachments] TO [public]
GO
