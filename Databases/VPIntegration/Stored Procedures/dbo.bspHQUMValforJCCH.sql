SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspHQUMValforJCCH]
   /*************************************
   * Created By: TV 06/01/2002
   * Modified By: DANF 09/06/02 - 17738 Correct Phase Group lookup
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   *
   * validates HQ Unit of Measure vs HQUM.UM FOR JCCH
   *
   * Pass:
   *	HQ UM, JCCo, PhaseGroup, Phase, Cost Type
   *
   * Success returns:
   *	0 and Description from bHQUM
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@JCCo bCompany, @Job bJob, @CostType bJCCType, @Phase bPhase, @um bUM = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int,@validcnt int, @PhaseGroup bGroup, @sourcestatus char(1), @oldum bUM
   
   select @rcode = 0
   
   if @um is null
   	begin
   	select @msg = 'Missing Unit of Measure', @rcode = 1
   	goto bspexit
   	end
   
   -- get phase group from JCJP
   select @PhaseGroup=PhaseGroup from bHQCO with (nolock) where HQCo=@JCCo
   
   -- get source status from JCCH
   select @sourcestatus=SourceStatus, @oldum=UM
   from bJCCH with (nolock) where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   
   if isnull(@oldum,'') <> isnull(@um,'')
   	begin
   	-- only restrict UM change for change orders where status in 'J' or 'I'
   	if @sourcestatus in ('J','I')
   		begin
   		-- do not allow changes to UM if Change Order detail exists in JCOD
   		select @validcnt=count(*) from bJCOD with (nolock)
   		where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   		if @validcnt <> 0
   			begin
   			select @msg = 'Cannot change UM, change order detail exists in JCOD!', @rcode = 1
   			goto bspexit
   			end
   	
   		-- do not allow changes to UM if change order detail exists in PMOL
   		select @validcnt=count(*) from bPMOL with (nolock)
   		where PMCo=@JCCo and Project=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType and SendYN='Y'
   		if @validcnt <> 0
   			begin
   			select @msg = 'Cannot change UM, change order detail exists in PMOL!', @rcode = 1
   			goto bspexit
   			end
   		end
   	
   	-- do not allow changes if TotalCmtdCost <> 0 or RemainCmtdCost <> 0 for any month in JCCP
   	select @validcnt=count(*) from bJCCP with (nolock)
   	where JCCo=@JCCo and Job=@Job and PhaseGroup=@PhaseGroup and Phase=@Phase and CostType=@CostType
   	and (TotalCmtdCost <> 0 or RemainCmtdCost <> 0)
   	if @validcnt <> 0
   		begin
   		select @msg = 'Cannot change UM, committed dollars exist in JCCP!',  @rcode = 1
   		goto bspexit
   		end
   	end
   
   
   -- get um description
   select @msg = Description from bHQUM with (nolock) where UM = @um
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Unit of Measure', @rcode = 1
   	end
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(10) + '[bspHQUMValforJCCH]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUMValforJCCH] TO [public]
GO
