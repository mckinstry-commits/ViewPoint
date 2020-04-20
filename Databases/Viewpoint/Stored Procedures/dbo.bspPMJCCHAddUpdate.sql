SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMJCCHAddUpdate    Script Date: 2/12/97 3:25:01 PM ******/
CREATE proc [dbo].[bspPMJCCHAddUpdate]
/***********************************************************
* CREATED BY:		JE   1/5/98
* MODIFIED By:		GF 10/21/98
*					GF 05/07/2002 - Issue #17225 - check if item = '' set to null
*					SR 07/09/02 17738 pass @phasegroup to bspJCVCOSTTYPE
*					GF 09/24/2003 - issue #22521 - use active flag when setting source status (either 'Y' or 'N')
*					GF 02/03/2009 - issue #120115 when phase add, update insurance code if exists
*					CHS	02/12/2009 - issue #120115 - added input parameter to bspJCADDPHASEWITHDESC
*					AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
*
* USAGE:
* tries to update JCCH is it doesn't exist then adds JCCH.
* Check for valid phase/costtype according to
* standard Job/Phase/CostType validation.
*
*
* INPUT PARAMETERS
*    co             Job Cost Company
*    job            Valid job
*    phasegroup     phase group
*    phase          phase to validate
*    costtype       cost type to validate
*    contract item  optional contract item
*    description    optional phase description
*    um	      optional unit of measure
*    billflag       optional bill flag
*    itemunitflag   optional item unit flag
*    phaseunitflag  optional phase unit flag
*    buyoutyn       optional buyoutyn (defaults to 'N')
*    activeyn       optional activeyn (defaults to 'Y')
*    override       optional if set to 'Y' will override 'lock phases' flag from JCJM
*	  inscode		 optional Job Phase insurance code
*
*
* OUTPUT PARAMETERS
*    msg           cost type abbreviation, or error message. *
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @phasegroup bGroup=null, @phase bPhase = null,
 @costtype bJCCType = null, @item bContractItem = null, @description bItemDesc,
 @um bUM = null, @billflag char(1) = null, @itemunitflag bYN = null, @phaseunitflag bYN = null,
 @buyoutyn bYN = 'N', @activeyn bYN = 'Y', @override bYN = 'P',
 @inscode bInsCode = null, @msg varchar(90)=null output)
as
set nocount on
--#142350 - renaming @PhaseGroup
declare @rcode int, @PhaseGrp tinyint, @JCCHexists char(1), @pphase bPhase, @desc varchar(255),
        @costtypestring varchar(5), @CurBillFlag char(1), @CurItemUnitFlag bYN, @CurPhaseUnitFlag bYN,
        @CurActiveYN bYN, @umjcpc bUM, @billflagjcpc char(1), @itemunitflagjcpc bYN,
        @phaseunitflagjcpc bYN

select @rcode = 0

if isnull(@item,'') = '' select @item = null

---- when @billflag = 'X' then Bill, Item, Phase flags from JCCH if exists
if @billflag = 'X'
	begin
	select @billflag=BillFlag, @itemunitflag=ItemUnitFlag, @phaseunitflag=PhaseUnitFlag
	from JCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup
	and Phase=@phase and CostType=@costtype
	if @@rowcount = 0
		begin
		select @billflag = 'C', @itemunitflag = 'N', @phaseunitflag = 'N'
		end
	end

---- first try to update JCCH - if not found then add it
select @CurBillFlag=BillFlag, @CurItemUnitFlag=ItemUnitFlag, @CurPhaseUnitFlag=PhaseUnitFlag, @CurActiveYN=ActiveYN
from JCCH with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
if @@rowcount = 1
	begin
	if @CurBillFlag<>@billflag or @CurItemUnitFlag<>@itemunitflag or @CurPhaseUnitFlag<>@phaseunitflag or @CurActiveYN<>@activeyn
		begin
		update JCCH set BillFlag=@billflag,ItemUnitFlag=@itemunitflag, PhaseUnitFlag=@phaseunitflag,ActiveYN=@activeyn
		where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		if @@rowcount = 0
			begin
			select @rcode=1, @desc = 'Could not update Cost Header'
    		end
		end
	goto bspexit
	end

select @costtypestring=convert(varchar(5), @costtype)

exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase, @costtypestring, @override, @PhaseGrp output,
			@pphase output, @desc output, @billflagjcpc output, @umjcpc output, @itemunitflagjcpc output,
   			@phaseunitflagjcpc  output, @JCCHexists output, @msg=@msg output
---- could not validate cost type
if @rcode <> 0
	begin
	select @desc = 'Cost Type is invalid.'
	goto bspexit
	end

if @JCCHexists = 'Y' goto bspexit

---- check AND add the phase code if needed
if not exists(select 1 from bJCJP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGrp and Phase=@phase)
	begin
	---- use different add procedure dependent of description exists
	if isnull(@description,'') = ''
		begin
		exec @rcode=dbo.bspJCADDPHASE @jcco,@job,@PhaseGrp,@phase,'Y',@item,@msg output
		end
	else
		begin
		exec @rcode=dbo.bspJCADDPHASEWITHDESC @jcco, @job, @PhaseGrp, @phase, 'Y', @item, @description, NULL, @msg output
		end
	---- update JCJP with insurance code
	if isnull(@inscode,'') <> ''
		begin
		update bJCJP set InsCode=@inscode
		where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGrp and Phase=@phase
		end
	end

---- insert JCCH record
insert into bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
				PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,SourceStatus)
select @jcco, @job, @PhaseGrp, @phase, @costtype, @um, @billflag, @itemunitflag,
				@phaseunitflag, @buyoutyn, 'N', @activeyn, @activeyn

select @rcode = 0

if @@rowcount <> 1
	begin
	select @desc = 'Cost header could not be added!', @rcode=1
	goto bspexit
	end




bspexit:
	select @msg = isnull(@desc,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMJCCHAddUpdate] TO [public]
GO
