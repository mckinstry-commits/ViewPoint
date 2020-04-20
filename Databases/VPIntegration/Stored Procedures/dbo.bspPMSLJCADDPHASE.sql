SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspPMSLJCADDPHASE]
/***********************************************************
* Created By:  GF 09/26/2001
* Modified By: SR 07/09/02 - issue 17738 pass @phasegroup to bspJCVPHASE
*				GF 04/20/2009 - issue #132326 JCCI start month cannot be null
*				GF 03/02/2010 - issue #138332 bill description equal item description when JCCI insert
*
*
* USAGE:
* inserts a Job Phase called from PMSL subcontract only. Called from btPMSLi trigger.
* Uses SLCT1Option from PMCo when:
* 1 - phase must exists in JCJP, does not care about locked phases.
* 2,3 - will add phase to JCJP.
*
*
* INPUT PARAMETERS
* @jcco         Job Cost Company
* @job          Valid job
* @phasegroup   Valid phase group
* @phase        Phase code to be validated
* @override     optional if set to 'Y' will override 'lock phases' flag from JCJM
* @item         optional ContractItem (if null then uses first contract item found)
*
* OUTPUT PARAMETERS
*    msg        Phase description, or error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
@jcco bCompany = 0, @job bJob = null, @phasegroup tinyint, @phase bPhase = null,
@override bYN = 'N', @item bContractItem = null, @msg varchar(255) output
as
set nocount on

declare @rcode int, @active bYN, @inputmask varchar(20),@rowcount int, @pphase bPhase,
	@desc varchar(255), @projminpct real, @contract bContract, @jcjpexists char(1),
	@dept bDept, @pitem bContractItem, @slct1option tinyint
   
   select @rcode = 0
   
   -- get option flag from PM company
   select @slct1option=isnull(SLCT1Option,2)
   from bPMCO with (nolock) where PMCo=@jcco
   if @@rowcount <> 1
       begin
       select @desc = 'Invalid Company.', @rcode = 1
       goto bspexit
       end
   
   -- validate phase
   exec @rcode=dbo.bspJCVPHASE @jcco, @job, @phase, @phasegroup, @override, @pphase output, @desc output, @phasegroup output,
                               @contract output, @pitem output, @dept output, @projminpct output,
                               @jcjpexists output, @msg output
   if @rcode <> 0
   	begin
       select @desc = 'Invalid phase.', @rcode = 1
       goto bspexit
       end
   
   -- if job/phase already exists then exit
   if @jcjpexists = 'Y'
   	begin
       select @rcode = 0
   	goto bspexit
   	end
   
   -- if Job/Phase does not exists and option is 1-no, do not add
   if @slct1option = 1 and @jcjpexists <> 'Y'
       begin
       select @desc = 'Invalid phase, PM company option is (1-no) and phase not set up in JCJP.', @rcode = 1
       goto bspexit
       end
   
   -- if no contract item is passed get the first contract item
   if @item is null select @item = @pitem
   if @item is null
   	begin
   	select @item=Min(Item)
       from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract
   	end
   
   -- if no contract items exist, lets try to add it
   if @item is null
   	begin
   	select @item= '               1'
   	---- #138332 - set bill description to item description
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
   if not exists (select top 1 1 from bJCJP with (nolock) where JCCo=@jcco and Job=@job and PhaseGroup=@phasegroup and Phase=@phase)
   begin
       insert into bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN)
       select  @jcco, @job, @phasegroup, @phase, @desc, @contract, @item, @projminpct, 'Y'
       if @@rowcount<>1
   	   begin
           select @desc = 'Cannot add Job Phase', @rcode = 1
           goto bspexit
           end
   end
   
   
   
   
   
   bspexit:
       select @msg = isnull(@msg,'') + ' ' + isnull(@desc,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLJCADDPHASE] TO [public]
GO
