SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 03/20/09
	Modified by: MV 06/25/09 - #134502 commented out top 50000  
	Purpose:	APUnapprovedReview header - provide one APUR rec in the header  */
  
   
CREATE       view [dbo].[APURHdr] as
Select distinct --top 50000 
	APUR.APCo as [APCo],
	APUR.Reviewer as [Reviewer],
	APUR.UIMth as [UIMth],
	APUR.UISeq as [UISeq],
	APUR.UniqueAttchID as [UniqueAttchID],
	APUR.Line as [Line],
	APUR.KeyID as [KeyID]
from dbo.APUR (nolock)
join (SELECT  APCo,Reviewer, MAX(KeyID) As KeyID from dbo.APUR (nolock)  where Line <> -1 
	GROUP BY  APCo,UIMth,Reviewer,UISeq) APURDistinct on APUR.KeyID=APURDistinct.KeyID 
	and APURDistinct.APCo=APUR.APCo and APURDistinct.Reviewer=APUR.Reviewer
where APUR.Line <> -1




GO
GRANT SELECT ON  [dbo].[APURHdr] TO [public]
GRANT INSERT ON  [dbo].[APURHdr] TO [public]
GRANT DELETE ON  [dbo].[APURHdr] TO [public]
GRANT UPDATE ON  [dbo].[APURHdr] TO [public]
GRANT SELECT ON  [dbo].[APURHdr] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APURHdr] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APURHdr] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APURHdr] TO [Viewpoint]
GO
