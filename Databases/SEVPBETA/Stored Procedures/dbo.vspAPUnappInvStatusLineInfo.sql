SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPUnappInvStatusLineInfo]
  /***********************************************************
   * CREATED BY: MV 01/09/08
   * MODIFIED By : 
   *              
   *
   * USAGE:
   * called from APUnappInvStatus to get APUL line info to display
   * 
   * INPUT PARAMETERS
   *   APCo, UIMth, UISeq, Line  

   * OUTPUT PARAMETERS
   *    @msg If Error

   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  (@apco bCompany = null , @uimth bMonth= null, @uiseq int = null, @line int = null)
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
   	
  select 'InvTotal' = APUI.InvTotal,
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
			'WO - ' + isnull(APUL.WO,'/no WO') + '/' 
			+ isnull(APULforWO.EQDesc, 'no equip info') + '/'
			+ isnull(APULforWO.EQComp, 'no component info')
		when 6 then
			'PO - ' + rtrim(isnull(APUL.PO,'/no PO'))+ '/' 
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
					'WO - ' + isnull(APUL.WO,'/no WO') + '/' 
					+ isnull(APULforWO.EQDesc, 'no equip info') + '/'
					+ isnull(APULforWO.EQComp, 'no component info')
				end
		when 7 then
			'SL - ' + isnull(APUL.SL,'/no SL') + '/' 
			+ 'Job - ' + JCJM.Description + '/'
			+ JCPM.Description + '/' 
			+ JCCT.Description 
		end
	from APUI WITH (NOLOCK)
	join APUL WITH (NOLOCK) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
	join APVM WITH (NOLOCK) on APUI.VendorGroup=APVM.VendorGroup and APUI.Vendor=APVM.Vendor 
	left join JCJM WITH (NOLOCK) on JCJM.JCCo = APUL.JCCo and JCJM.Job=APUL.Job
	left Join JCPM WITH (NOLOCK) on JCPM.PhaseGroup=APUL.PhaseGroup and JCPM.Phase=APUL.Phase
	left Join JCCT WITH (NOLOCK) on JCCT.PhaseGroup=APUL.PhaseGroup and JCCT.CostType=APUL.JCCType
	left Join INLM WITH (NOLOCK) on INLM.INCo=APUL.INCo and INLM.Loc=APUL.Loc
	left Join EMEM WITH (NOLOCK) on EMEM.EMCo=APUL.EMCo and EMEM.Equipment=APUL.Equip
	left Join EMCT WITH (NOLOCK) on EMCT.EMGroup=APUL.EMGroup and EMCT.CostType=APUL.EMCType
	left Join EMCC WITH (NOLOCK) on EMCC.EMGroup=APUL.EMGroup and EMCC.CostCode=APUL.CostCode
	left Join APULforWO on APULforWO.APCo=APUL.APCo and APULforWO.UIMth=APUL.UIMth and
		APULforWO.UISeq=APUL.UISeq and APULforWO.Line=APUL.Line and APULforWO.EMCo=APUL.EMCo and
		APULforWO.Equipment=APUL.Equip
	Where APUI.APCo=@apco and APUI.UIMth=@uimth and APUI.UISeq=@uiseq and APUL.Line=@line
	if @@rowcount = 0
		begin
		select @rcode = 1
		end
	
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappInvStatusLineInfo] TO [public]
GO
