SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 11/09/06
	Modified by: MV 03/26/09 - #132650 return RejReason
	Purpose:	 to display Approved or Reject in APUnappInvRev */
  
   
   CREATE       view [dbo].[APURRevAppRej] as
select            
      distinct APUI.APCo,APUI.UIMth, APUI.UISeq,r.Reviewer,
      'Approved' = (select case when (sum(case r.ApprvdYN when 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end),
      'Rejected' = (select case when (sum(case r.Rejected when 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end),
      'RejReason' = (select case when (count(distinct isnull(r.RejReason,''))= 1) then max(r.RejReason) else '' end)
      from APUI join APUR r on APUI.APCo=r.APCo and APUI.UIMth=r.UIMth and APUI.UISeq=r.UISeq
      where r.Line <> -1 
      Group By APUI.APCo,APUI.UIMth, APUI.UISeq,r.Reviewer


--select 		
-- 	distinct APUI.APCo,APUI.UIMth, APUI.UISeq,r.Reviewer,'Approved' = (select case when (sum(case r.ApprvdYN when 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end),
--	'Rejected' = (select case when (sum(case r.Rejected when 'Y' then 0 else 1 end)= 0) then 'Y' else 'N' end)
--	from APUI join APUR r on APUI.APCo=r.APCo and APUI.UIMth=r.UIMth and APUI.UISeq=r.UISeq
--	where r.Line <> -1 
--	Group By APUI.APCo,APUI.UIMth, APUI.UISeq,r.Reviewer

GO
GRANT SELECT ON  [dbo].[APURRevAppRej] TO [public]
GRANT INSERT ON  [dbo].[APURRevAppRej] TO [public]
GRANT DELETE ON  [dbo].[APURRevAppRej] TO [public]
GRANT UPDATE ON  [dbo].[APURRevAppRej] TO [public]
GRANT SELECT ON  [dbo].[APURRevAppRej] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APURRevAppRej] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APURRevAppRej] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APURRevAppRej] TO [Viewpoint]
GO
