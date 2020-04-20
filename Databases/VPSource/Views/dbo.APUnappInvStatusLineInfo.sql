SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Created by:	 MV 12/18/07 - #29702 Unapproved Enhancement
	Modified by:
	Purpose:	 Display APUI Line info in APUnappInvStatus Grid */
  
   
   CREATE       view [dbo].[APUnappInvStatusLineInfo] as
select 		
 	distinct TOP 20000 APUL.APCo,APUL.UIMth, APUL.UISeq, APUL.Line,APUL.ReviewerGroup,APUR.ApprovalSeq,
	'VendorName'= APVM.Name,'InvoiceAmt'=APUI.InvTotal,
	'LineInfo' = case APUL.LineType 
		when 1 then
			'Job - ' + JCJM.Description + '/'
			+ JCPM.Description + '/' 
			+ JCCT.Description 
		when 2 then
			'Inv - ' + INLM.Description + '/'
			+ APUL.Material
		when 3 then
			'Exp - ' + isnull(APUL.Material, 'no material')
		when 4 then
			'Equip - ' + rtrim(EMEM.Description) + '/'
			+ EMCT.Description + '/'
			+ EMCC.Description
		when 5 then
			'WO - ' + isnull(APUL.WO,'/no WO') 
			+ ' /WO Item ' + isnull(convert(varchar(3),APUL.WOItem), 'no WO Item') + '/'
			+ isnull(APULforWO.EQDesc, 'no equip info') + '/'
			+ isnull(APULforWO.EQComp, 'no component info')
		when 6 then
			'PO - ' + rtrim(isnull(APUL.PO,'/no PO'))
			+ ' /PO Item ' + isnull(convert(varchar(3),APUL.POItem), 'no PO Item') + '/' 
			+ case APUL.ItemType
				when 1 then
					'Job - ' + JCJM.Description + '/'
					+ JCPM.Description + '/' 
					+ JCCT.Description
				when 2 then 
					'Inv - ' + INLM.Description + '/'
					+ APUL.Material
				when 3 then
					'Exp - ' + rtrim(APUL.Material)
				when 4 then
					'Equip - ' + rtrim(EMEM.Description) + '/'
					+ EMCT.Description + '/'
					+ EMCC.Description
				when 5 then
					'WO - ' + isnull(APUL.WO,'/no WO') 
					+ ' /WO Item ' + isnull(convert(varchar(3),APUL.WOItem), 'no WO Item') + '/'
					+ isnull(APULforWO.EQDesc, 'no equip info') + '/'
					+ isnull(APULforWO.EQComp, 'no component info')
				end
		when 7 then
			'SL - ' + isnull(APUL.SL,'/no SL') 
			+ ' /SL Item ' + isnull(convert(varchar(3),APUL.SLItem), 'no SL Item') + '/'
			+ 'Job - ' + JCJM.Description + '/'
			+ JCPM.Description + '/' 
			+ JCCT.Description 
		end
	from APUL join APUR on APUL.APCo=APUR.APCo and APUL.UIMth=APUR.UIMth and APUL.UISeq=APUR.UISeq
	and APUL.Line=APUR.Line and APUL.ReviewerGroup=APUR.ReviewerGroup
	join APUI on APUI.APCo=APUL.APCo and APUI.UIMth=APUL.UIMth and APUI.UISeq=APUL.UISeq
	join APVM on APUI.VendorGroup=APVM.VendorGroup and APVM.Vendor=APUI.Vendor
	left join JCJM on JCJM.JCCo = APUL.JCCo and JCJM.Job=APUL.Job
	left Join JCPM on JCPM.PhaseGroup=APUL.PhaseGroup and JCPM.Phase=APUL.Phase
	left Join JCCT on JCCT.PhaseGroup=APUL.PhaseGroup and JCCT.CostType=APUL.JCCType
	left Join INLM on INLM.INCo=APUL.INCo and INLM.Loc=APUL.Loc
	left Join EMEM on EMEM.EMCo=APUL.EMCo and EMEM.Equipment=APUL.Equip
	left Join EMCT on EMCT.EMGroup=APUL.EMGroup and EMCT.CostType=APUL.EMCType
	left Join EMCC on EMCC.EMGroup=APUL.EMGroup and EMCC.CostCode=APUL.CostCode
	left Join APULforWO on APULforWO.APCo=APUL.APCo and APULforWO.UIMth=APUL.UIMth and
		APULforWO.UISeq=APUL.UISeq and APULforWO.Line=APUL.Line and APULforWO.EMCo=APUL.EMCo and
		APULforWO.Equipment=APUL.Equip
	Where APUR.Line <> -1 
	Order by APUL.ReviewerGroup,APUR.ApprovalSeq

GO
GRANT SELECT ON  [dbo].[APUnappInvStatusLineInfo] TO [public]
GRANT INSERT ON  [dbo].[APUnappInvStatusLineInfo] TO [public]
GRANT DELETE ON  [dbo].[APUnappInvStatusLineInfo] TO [public]
GRANT UPDATE ON  [dbo].[APUnappInvStatusLineInfo] TO [public]
GO
