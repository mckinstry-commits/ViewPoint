SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJCADDPHASE]
   /***********************************************************
    * CREATED BY:  JE 11/25/96
    * MODIFIED By: EN 1/7/99
    *	         	JE 12/14/00  - added taxgroup to the JCCI insert
    *				SR 07/09/02 - issue 17738 - pass @PhaseGroup to bspJCVPHASE
    *				GF 06/09/2003 - issue #21464 - added contract item format.
    *				GF 12/05/2003 - issue #23186 - was not using newly formatted item when added
    *			 	TV - 23061 added isnulls
    *				GF 04/20/2009 - issue #132326 JCCI start month not null
    *				GF 03/02/2010 - issue #138332 bill description equal item description when JCCI insert
    *
    *
    * USAGE:
    * inserts a JobPhase.
    * Check for valid phase according to standard Job/Phase validation.
    * no job passed, no phase passed.
    *
    *
    * INPUT PARAMETERS
    *    co         Job Cost Company
    *    job        Valid job
    *    PhaseGroup, phase      phase to validate
    *    override   optional if set to 'Y' will override 'lock phases' flag from JCJM
    *    item       optional ContractItem (if null then uses first contract item found)
    *
    * OUTPUT PARAMETERS
    *    msg        Phase description, or error message.
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   @jcco bCompany = 0, @job bJob = null, @PhaseGroup tinyint,  @phase bPhase = null, @override bYN = 'N',
   @item bContractItem = null, @msg varchar(255) output
   as
   set nocount on
   
   declare @rcode int, @active bYN, @rowcount int,@pphase bPhase,
   	    @desc varchar(255),@projminpct real, @contract bContract, @JCJPexists char(1), 
   		@dept bDept, @pitem bContractItem, @contractitem char(16), @itemformat varchar(10), 
   		@itemmask varchar(10), @ditem varchar(16), @itemlength varchar(10), @inputmask varchar(30)
   
   select @rcode = 0, @msg = ''
   
   --TEST CODE
	   --select @desc = 'Test - In Add Phase', @rcode = 1
	   --goto bspexit
   
   -- get input mask for bContractItem
   select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
   from DDDTShared with (nolock) where Datatype = 'bContractItem'
   if isnull(@inputmask,'') = '' select @inputmask = 'R'
   if isnull(@itemlength,'') = '' select @itemlength = '16'
   if @inputmask in ('R','L')
   	begin
   	select @inputmask = @itemlength + @inputmask + 'N'
   	end
   
   select @ditem = '1'
   exec bspHQFormatMultiPart @ditem, @inputmask, @contractitem output
   
   -- validate phase 
   exec @rcode=dbo.bspJCVPHASE @jcco, @job, @phase, @PhaseGroup, @override, @pphase output, @desc output, 
   							@PhaseGroup output, @contract output, @pitem output, @dept output, 
   							@projminpct output, @JCJPexists output, @msg output
   -- check if invalid phase
   if @rcode <> 0
   	begin
       select @desc = 'Invalid phase.', @rcode = 1
       goto bspexit
       end
   
   -- if job/phase already exists then exit
   if @JCJPexists='Y' -- no need to add the phase
   	begin
       select @rcode =0
   	goto bspexit
   	end
   
   --if no contract item is passed get the first contract item
   if @item is null select @item = @pitem
   if @item is null
   	begin
   	select @item=Min(Item)
       from bJCCI with (nolock)
   	where JCCo=@jcco and Contract=@contract
   	end
   
   -- if no contract items exist, lets try to add it
   if @item is null
   	begin
   	select @item=@contractitem
   	---- #138332 set bill description to item description
   	insert into bJCCI (JCCo, Contract, Item, Description,
   			           Department, TaxGroup, TaxCode, UM, RetainPCT, OrigContractAmt,
   			           OrigContractUnits, OrigUnitPrice, BillType, StartMonth, BillDescription)
   	select @jcco, @contract,@item, @desc, bJCCM.Department, bJCCM.TaxGroup,
   		   bJCCM.TaxCode,'LS',bJCCM.RetainagePCT,0,0,0,bJCCM.DefaultBillType,
   		   bJCCM.StartMonth, @desc
   	from bJCCM with (nolock)
       where JCCo=@jcco and Contract=@contract
   	end
   
   -- check contract item
   if not exists ( select top 1 1 from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@item)
   	begin
       select @desc = 'Cannot add Contract Item', @rcode = 1
       goto bspexit
       end
   
   -- now insert Job Phase
   if not exists (select top 1 1  from bJCJP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@PhaseGroup and Phase=@phase)
   	begin
   	insert into bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
   	select  @jcco, @job, @PhaseGroup, @phase, @desc, @contract, @item, @projminpct, 'Y'
   	if @@rowcount <> 1
   		begin
   	    select @desc = 'Cannot add Job Phase', @rcode = 1
   	    goto bspexit
   	    end
   	end
   
   
   
   bspexit:
   	select @msg=isnull(@msg,'') + ' ' + isnull(@desc,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCADDPHASE] TO [public]
GO
