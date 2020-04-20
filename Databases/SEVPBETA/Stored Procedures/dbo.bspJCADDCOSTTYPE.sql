SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCADDCOSTTYPE    Script Date: 8/28/99 9:34:58 AM ******/
    /****** Object:  Stored Procedure dbo.bspJCADDCOSTTYPE    Script Date: 2/12/97 3:25:01 PM ******/
    CREATE       proc [dbo].[bspJCADDCOSTTYPE]
    (@jcco bCompany = 0, @job bJob = null,  @phasegroup bGroup = null, @phase bPhase = null,
     @costtype bJCCType = null, @um bUM = null, @billflag char(1) = null,
     @itemunitflag bYN = null,  @phaseunitflag bYN = null,  @buyoutyn bYN = 'N',
     @activeyn bYN = 'Y', @override Char(1) = 'N', @msg varchar(255)=null output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:	JE 12/10/96
     * MODIFIED By:	JE 12/10/96
     *				SR 07/06/02 - 17738 added @phasegroup to bspJCVCOSTTYPE
     *              DANF 09/05/02 - 17738 added phase group as input paramater
     *				TV - 23061 added isnulls
     *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
     *
     * USAGE:
     * adds JC Phase/CostType.  Check for valid phase/costtype according to
     * standard Job/Phase/CostType validation.
     *
     *
     * INPUT PARAMETERS
     *    co             Job Cost Company
     *    job            Valid job
     *    phasegroup     Phase Group
     *    phase          phase to validate
     *    costtype       cost type to validate
     *    um	     optional unit of measue
     *    billflag       optional bill flag
     *    itemunitflag   optional item unit flag
     *    phaseunitflag  optional phase unit flag
     *    buyoutyn       optional buyoutyn (defaults to 'N')
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
   --#142350 renaming @PhaseGroup  
    DECLARE @rcode int,
			@PhaseGrp tinyint,
			@JCCHexists char(1),
			@pphase bPhase,
			@desc varchar(255),
			@costtypestring varchar(5),
			@sourcestatus char(1),
			@vum bUM
    
    select @rcode = 0, @sourcestatus='J', @costtypestring=convert(varchar(5),@costtype)
    
    
    exec @rcode = dbo.bspJCVCOSTTYPE @jcco, @job, @phasegroup, @phase, @costtypestring, @override,
    			@PhaseGrp output, @pphase output, @desc output, @billflag output, @vum output, 
    			@itemunitflag output, @phaseunitflag  output, @JCCHexists output, @msg=@msg output
    -- could not validate cost type
    if @rcode <> 0
    	begin
    	select @desc=@msg
    	goto bspexit
    	end
    
    if @um is null
    	begin
    	select @um=@vum
    	end
    
    if @JCCHexists='Y'
    	begin
    	goto bspexit
    	end
    
    if @override = 'P'
    	begin
    	select @billflag = isnull(@billflag,'C'), @itemunitflag = isnull(@itemunitflag,'N'),
    	       @phaseunitflag = isnull(@phaseunitflag,'N')
    	select @sourcestatus=SendFlag from bPMSL with (nolock) 
    	where PMCo=@jcco and Project=@job and PhaseGroup=@PhaseGrp and Phase=@phase and CostType=@costtype
    	if @@rowcount <> 1 select @sourcestatus = 'Y'
    	end


    -- insert cost header record
    insert into bJCCH (JCCo,Job,PhaseGroup,Phase,CostType,UM,BillFlag,ItemUnitFlag,
    		PhaseUnitFlag,BuyOutYN,Plugged,ActiveYN, SourceStatus)
    select @jcco, @job, @PhaseGrp, @phase, @costtype, isnull(@um,'LS'), @billflag, @itemunitflag,
    		@phaseunitflag,@buyoutyn,'N',@activeyn, @sourcestatus
    if @@rowcount <> 1
    	begin
    	select @desc='Cost header could not be added!', @rcode=1
    	goto bspexit
    	end
    
    
    
   bspexit:
    	select @msg=@desc
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCADDCOSTTYPE] TO [public]
GO
