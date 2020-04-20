SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMProjPhasesCTGet  Script Date: 02/18/2004 AM ******/
   CREATE   proc [dbo].[bspPMProjPhasesCTGet]
    /********************************************************
    * CREATED BY:	GF 02/18/2004
    * MODIFIED BY:
    *
    * USAGE: Called from PMProjectPhases form to get the ShowCostTypes(1-10) and cost type
    *		description from JCCT.
    *
    *
    * INPUT PARAMETERS:
    * @pmco		PM Company
    *
    * OUTPUT PARAMETERS:
    * @showcosttype1	Cost Type 1 grid column
    * @showcosttype2	Cost Type 2 grid column
    * @showcosttype3	Cost Type 3 grid column
    * @showcosttype4	Cost Type 4 grid column
    * @showcosttype5	Cost Type 5 grid column
    * @showcosttype6	Cost Type 6 grid column
    * @showcosttype7	Cost Type 7 grid column
    * @showcosttype8	Cost Type 8 grid column
    * @showcosttype9	Cost Type 9 grid column
    * @showcosttype10	Cost Type 10 grid column
    * @ctdesc1			Cost Type 1 grid column description
    * @ctdesc2			Cost Type 2 grid column description
    * @ctdesc3			Cost Type 3 grid column description
    * @ctdesc4			Cost Type 4 grid column description
    * @ctdesc5			Cost Type 5 grid column description
    * @ctdesc6			Cost Type 6 grid column description
    * @ctdesc7			Cost Type 7 grid column description
    * @ctdesc8			Cost Type 8 grid column description
    * @ctdesc9			Cost Type 9 grid column description
    * @ctdesc10		Cost Type 10 grid column description
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    **********************************************************/
   (@pmco bCompany, @showcosttype1 bJCCType output, @showcosttype2 bJCCType output, @showcosttype3 bJCCType output,
    @showcosttype4 bJCCType output, @showcosttype5 bJCCType output, @showcosttype6 bJCCType output,
    @showcosttype7 bJCCType output, @showcosttype8 bJCCType output, @showcosttype9 bJCCType output,
    @showcosttype10 bJCCType output, @ctdesc1 bDesc output, @ctdesc2 bDesc output, @ctdesc3 bDesc output,
    @ctdesc4 bDesc output, @ctdesc5 bDesc output, @ctdesc6 bDesc output, @ctdesc7 bDesc output, @ctdesc8 bDesc output,
    @ctdesc9 bDesc output, @ctdesc10 bDesc output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @phasegroup bGroup
   
   select @rcode = 0
   
   -- validate PM Company
   select  @showcosttype1=ShowCostType1, @showcosttype2=ShowCostType2, @showcosttype3=ShowCostType3,
   		@showcosttype4=ShowCostType4, @showcosttype5=ShowCostType5, @showcosttype6=ShowCostType6,
   		@showcosttype7=ShowCostType7, @showcosttype8=ShowCostType8, @showcosttype9=ShowCostType9,
   		@showcosttype10=ShowCostType10
   from PMCO with (nolock) where PMCo=@pmco
   if @@rowcount = 0
    	begin
    	select @msg = 'Invalid PM Company', @rcode = 1
    	goto bspexit
    	end
   
   -- get phase group from HQCO for PMCo
   select @phasegroup=PhaseGroup from HQCO with (nolock) where HQCo=@pmco
   if @@rowcount = 0
   	begin
    	select @msg = 'PM Company: ' + isnull(convert(varchar(3),@pmco),' ') + ' does not exist in HQCO.', @rcode = 1
    	goto bspexit
    	end
   
   
   -- get cost type descriptions from JCCT
   select @ctdesc1 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype1
   if @@rowcount = 0 set @showcosttype1 = null
   select @ctdesc2 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype2
   if @@rowcount = 0 set @showcosttype2 = null
   select @ctdesc3 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype3
   if @@rowcount = 0 set @showcosttype3 = null
   select @ctdesc4 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype4
   if @@rowcount = 0 set @showcosttype4 = null
   select @ctdesc5 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype5
   if @@rowcount = 0 set @showcosttype5 = null
   select @ctdesc6 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype6
   if @@rowcount = 0 set @showcosttype6 = null
   select @ctdesc7 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype7
   if @@rowcount = 0 set @showcosttype7 = null
   select @ctdesc8 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype8
   if @@rowcount = 0 set @showcosttype8 = null
   select @ctdesc9 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype9
   if @@rowcount = 0 set @showcosttype9 = null
   select @ctdesc10 = Description from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@showcosttype10
   if @@rowcount = 0 set @showcosttype10 = null
   
   
   
   bspexit:
   	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjPhasesCTGet] TO [public]
GO
