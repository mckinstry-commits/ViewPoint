SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE   view [dbo].[VSBHInfo] as    
/*******************************
* Created: ??
* Modified: GG 04/10/08 - added top 100 percent and order by
*
* Used to return Scanning Batch information
*
*******************************/

select top 100 percent h.BatchId, h.Description, count(*) as DocCount,
	h.CreatedBy, h.CreatedDate,
	(select count(*) from bVSBD d2 where d2.BatchId=h.BatchId and d2.Attached='N') as Unattached,
	h.InUseBy
from bVSBH h
left outer join bVSBD d on h.BatchId = d.BatchId 
group by h.BatchId, h.Description, h.CreatedBy, h.CreatedDate, h.InUseBy
order by h.BatchId
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[VSBHInfo] TO [public]
GRANT INSERT ON  [dbo].[VSBHInfo] TO [public]
GRANT DELETE ON  [dbo].[VSBHInfo] TO [public]
GRANT UPDATE ON  [dbo].[VSBHInfo] TO [public]
GRANT SELECT ON  [dbo].[VSBHInfo] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VSBHInfo] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VSBHInfo] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VSBHInfo] TO [Viewpoint]
GO
