SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 11/08/06
	Modified by:    MV 7/10/08 - #126--- subtract discount if NetAmtOpt = Y
					MV 07/02/09 - #134511 - add tax if not use tax
	Purpose:	 to display Reviewer Total in APUnappInvRev */
  
   
   CREATE       view [dbo].[APURRevTot] as
select 		
 	distinct APUI.APCo,APUI.UIMth, APUI.UISeq,APUR.Reviewer,'ReviewerTotal' = sum(GrossAmt + (case MiscYN when 'Y' then MiscAmt else 0 end) 
	 + case TaxType when 2 then 0 else TaxAmt end 
     - (case NetAmtOpt when 'Y' then Discount else 0 end)) 
	from APUI join APUL on APUI.APCo=APUL.APCo and APUI.UIMth=APUL.UIMth and APUI.UISeq=APUL.UISeq
	join APUR on APUR.APCo=APUL.APCo and APUR.UIMth=APUL.UIMth and APUR.UISeq=APUL.UISeq and APUR.Line=APUL.Line
    join APCO on APUI.APCo=APCO.APCo
	Group By APUI.APCo,APUI.UIMth, APUI.UISeq, APUR.Reviewer

GO
GRANT SELECT ON  [dbo].[APURRevTot] TO [public]
GRANT INSERT ON  [dbo].[APURRevTot] TO [public]
GRANT DELETE ON  [dbo].[APURRevTot] TO [public]
GRANT UPDATE ON  [dbo].[APURRevTot] TO [public]
GO
