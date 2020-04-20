SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************/
CREATE  proc [dbo].[bspJCPCValForPMTC]
/***********************************************************
 * CREATED By:	GF	07/23/2002
 * MODIFIED By: TV - 23061 added isnulls
 *				GF 04/10/2006 - changed for 6.x cost type input param now a varchar(10)
 *
 *
 *
 * USAGE: validates cost types in JCPC, if not valid for phase
 *	then tries to validate for valid part phase. Used in PMTemplateCostTypes.    
 *
 * INPUT PARAMETERS
 *  PhaseGroup
 *  Phase
 *  CostType
 *	PPhase	Valid part phase
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description from JCCT
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/ 
(@phasegroup tinyint = null, @phase bPhase=null, @costtype varchar(10) = null,
 @pphase varchar(20) = null, @costtypeout bJCCType = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @phasegroup is null
   	begin
   	select @msg = 'Missing Phase Group!', @rcode = 1
   	goto bspexit
   	end

if @phase is null
   	begin
   	select @msg = 'Missing Phase code!', @rcode = 1
   	goto bspexit
   	end

if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end


-- -- -- first validate cost type to JCCT. Either for numeric or abbreviation
if isnumeric(@costtype) = 1
	begin
	select @costtypeout=CostType, @msg=Description
	from JCCT with (nolock)
	where PhaseGroup=@phasegroup and CostType=convert(int,convert(float, @costtype))
	end
-- -- -- if not numeric or not found try to find as abbreviation
if @@rowcount = 0
	begin
	select @costtypeout=CostType, @msg=Description
	from JCCT with (nolock)
	where PhaseGroup=@phasegroup and CostType=(select min(j.CostType) 
	from bJCCT j with (nolock) where j.PhaseGroup=@phasegroup and j.Abbreviation like @costtype + '%')
   	if @@rowcount = 0
   		begin
   		select @msg = 'JC Cost Type not on file!', @rcode = 1
		if isnumeric(@costtype)=1 select @costtypeout=@costtype
   		goto bspexit
   		end
	end

-- -- -- now validate @costtypeout to JCPC for entire phase first
if not exists(select * from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtypeout)
	begin
	if isnull(@pphase,'') = ''
		begin
   		select @msg = 'Phase Cost Type not setup for Cost Type: ' + convert(varchar(3),@costtypeout) + ' !', @rcode = 1
   		goto bspexit
   		end
   	-- -- -- now try to validate to valid part phase
	if not exists(select * from JCPC with (nolock) where PhaseGroup=@phasegroup and Phase like @pphase + '%' and CostType=@costtypeout)
		begin
	   	select @msg = 'Phase Cost Type not setup for valid part phase!', @rcode =1
	   	goto bspexit
	   	end
	end





bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPCValForPMTC] TO [public]
GO
