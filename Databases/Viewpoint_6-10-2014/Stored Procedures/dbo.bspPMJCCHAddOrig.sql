SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMJCCHAddOrig    Script Date: 2/12/97 3:25:01 PM ******/
CREATE  proc [dbo].[bspPMJCCHAddOrig]
	/***********************************************************
	* CREATED BY: LM   11/11/98
	* MODIFIED By: SR 07/09/02 17738 pass @phasegroup to bspJCVCOSTTYPE
	*			AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
	*				
	*
	*
	* USAGE:
	* tries to update JCCH if it doesn't exist then adds JCCH.
	* Check for valid phase/costtype according to
	* standard Job/Phase/CostType validation.
	* Used only by Subcontract detail because it could be trying to add original est.
	*
	* INPUT PARAMETERS
	*    co             Job Cost Company
	*    job            Valid job
	*    phasegroup     phase group
	*    phase          phase to validate
	*    costtype       cost type to validate
	*    contract item  optional contract item
	*    um	      optional unit of measue
	*    estunits       original estimated units
	*    estcost        original estimated cost
	*    activeyn       optional activeyn (defaults to 'Y')
	*    override       optional if set to 'Y' will override 'lock phases' flag from JCJM
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
 @costtype bJCCType = null, @item bContractItem = null, @um bUM = null, @estunits bUnits = 0,
 @estcost bDollar = 0, @activeyn bYN = 'Y', @override bYN = 'P', @sendyn bYN = 'Y',
 @msg varchar(255) = null output)
as
set nocount on
	--#142350 - renaming @PhaseGroup 
	DECLARE @rcode int,
			@PhaseGrp tinyint,
			@JCCHexists char(1),
			@pphase bPhase,
			@desc varchar(255),
			@costtypestring varchar(5),
			@umjcpc bUM,
			@billflagjcpc char(1),
			@itemunitflagjcpc bYN,
			@phaseunitflagjcpc bYN,
			@billflag char(1),
			@itemunitflag bYN,
			@phaseunitflag bYN,
			@buyoutyn bYN,
			@retcode int,
			@errmsg varchar(255)

select @rcode = 0, @retcode = 0, @billflag='C', @itemunitflag='N', @phaseunitflag='N', @buyoutyn='N'

if isnull(@item,'') = '' select @item = null

select @costtypestring=convert(varchar(5), @costtype)

exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup,@phase,@costtypestring,@override,
   			@PhaseGrp output, @pphase output, @desc output,
   			@billflagjcpc output, @umjcpc output, @itemunitflagjcpc output,
   			@phaseunitflagjcpc  output, @JCCHexists output, @msg=@msg output
---- could not validate cost type
if @rcode <> 0
   	begin
   	select @desc=@msg
   	goto bspexit
   	end

if @JCCHexists='Y' goto bspexit

---- check AND add the phase
exec @retcode = dbo.bspJCADDPHASE @jcco,@job,@PhaseGrp,@phase,'Y',@item, @errmsg output

if isnull(@billflagjcpc,'') <> ''
	begin
	select @billflag=@billflagjcpc
	end

if isnull(@itemunitflagjcpc,'') <> ''
	begin
	select @itemunitflag=@itemunitflagjcpc
	end

if isnull(@phaseunitflagjcpc,'') <> ''
	begin
	select @phaseunitflag=@phaseunitflagjcpc
	end

---- insert JCCH record
insert into bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
   		PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN,OrigUnits, OrigCost, SourceStatus)
select @jcco, @job, @PhaseGrp, @phase, @costtype, @um, @billflag, @itemunitflag,
   		@phaseunitflag,@buyoutyn,'N',@activeyn, @estunits, @estcost, @sendyn
if @@rowcount <> 1
	begin
   	select @desc='Cost header could not be added!', @rcode=1
   	goto bspexit
	end





bspexit:
	select @msg = isnull(@msg,'') + ' ' + @desc
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMJCCHAddOrig] TO [public]
GO
