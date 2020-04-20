SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE       View [dbo].[brvPOCurCost]
   
   as
   
   select POCo,PO,CurCost=sum(CurCost),InvCost=sum(InvCost) From POIT 
   where Job is not NULL
   Group By POCo,PO
   
   
   
   
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvPOCurCost] TO [public]
GRANT INSERT ON  [dbo].[brvPOCurCost] TO [public]
GRANT DELETE ON  [dbo].[brvPOCurCost] TO [public]
GRANT UPDATE ON  [dbo].[brvPOCurCost] TO [public]
GO
