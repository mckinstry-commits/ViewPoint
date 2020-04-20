SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURUpdateAPUL]
/***************************************************
* Created:	MV 10/31/06 APUnappInvRev 6X recode
* Modified	MV 08/01/08 - #129254 - update job/equip/loc only if value changed
*			CHS	09/06/2011	- TK-08190 
*			JG 01/25/2012 - TK-12012 - Added SMJCCostType and SMPhaseGroup
*
*    Purpose: Update APUL from APUnappInvRev
*
*    Input:
*       @apco
*       @uimth
*       @uiseq
*       @line
*       @jcco, @job,@phase,@jcctype,@emco,@equip,@costcode
*       @emct,@inco,@loc,@glco,@glacct
*		@SMCo, @SMCostType, @SMScope, @SMWorkOrder
*		@SMJCCostType, @SMPhaseGroup
*
*    output:
*        @msg    
****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @line int,@jcco int = null,
	@job bJob = null, @phase bPhase = null,@jcctype bJCCType = null, @emco int =null,
	@equip bEquip = null,@costcode bCostCode = null,@emct bEMCType = null, @inco int = null,
	@loc bLoc = null, @glco int = null, @glacct bGLAcct = null,@linedesc varchar(30),
	@SMCo bCompany, @SMCostType int, @SMScope int, @SMWorkOrder smallint,
	@SMJCCostType dbo.bJCCType, @SMPhaseGroup dbo.bGroup,
	@msg varchar(255) output)
   
   as
   
	declare @APULjob bJob,@APULequip bEquip,@APULloc bLoc

	select @APULjob=Job,@APULequip=Equip,@APULloc=Loc from bAPUL 
	where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line=@line

	--update job,equip or loc only if they have changed otherwise it will cause bAPUL update trigger to clear all reviewers.
	if (isnull(@APULjob,'') <> isnull(@job,'')) 
		or (isnull(@APULequip,'') <> isnull(@equip,''))
		or (isnull(@APULloc,'') <> isnull(@loc,''))
		begin
		Update bAPUL set JCCo=@jcco,Job=@job,Phase=@phase, JCCType=@jcctype,EMCo = @emco, Equip = @equip,
			CostCode = @costcode,EMCType=@emct,INCo=@inco,Loc=@loc,GLCo=@glco,GLAcct=@glacct,Description=@linedesc,
			SMCo= @SMCo, SMCostType = @SMCostType, Scope = @SMScope, SMWorkOrder = @SMWorkOrder,
			SMJCCostType = @SMJCCostType, SMPhaseGroup = @SMPhaseGroup
		   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line=@line 
		end 
	else 
		begin
		Update bAPUL set JCCo=@jcco,Phase=@phase, JCCType=@jcctype,EMCo = @emco,
			CostCode = @costcode,EMCType=@emct,INCo=@inco,GLCo=@glco,GLAcct=@glacct,Description=@linedesc,
			SMCo= @SMCo, SMCostType = @SMCostType, Scope = @SMScope, SMWorkOrder = @SMWorkOrder,
			SMJCCostType = @SMJCCostType, SMPhaseGroup = @SMPhaseGroup
		   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line=@line 
		end

   
         
   Return
GO
GRANT EXECUTE ON  [dbo].[vspAPURUpdateAPUL] TO [public]
GO
