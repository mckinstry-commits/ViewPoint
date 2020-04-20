SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE view [dbo].[CMDBGrid] as select Co, Mth, BatchId, BatchSeq, BatchTransType, CMTrans, CMAcct, CMTransType, GLAcct, CMRef,
        CMRefSeq, ActDate,
      'Amount'=Case
         when CMTransType=1 then Amount*-1
         else
            Amount
         end
      
      from CMDB
      
   
  
 



GO
GRANT SELECT ON  [dbo].[CMDBGrid] TO [public]
GRANT INSERT ON  [dbo].[CMDBGrid] TO [public]
GRANT DELETE ON  [dbo].[CMDBGrid] TO [public]
GRANT UPDATE ON  [dbo].[CMDBGrid] TO [public]
GRANT SELECT ON  [dbo].[CMDBGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CMDBGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CMDBGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CMDBGrid] TO [Viewpoint]
GO
