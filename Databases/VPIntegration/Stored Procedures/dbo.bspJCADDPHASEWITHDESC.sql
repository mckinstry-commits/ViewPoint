SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCADDPHASEWITHDESC    Script Date: 8/28/99 9:34:59 AM ******/
CREATE  proc [dbo].[bspJCADDPHASEWITHDESC]
/***********************************************************
* CREATED BY:	GF 11/18/98
* MODIFIED By:	SR 07/08/02		- issue 17738 - pass PhaseGroup into call to bspJCVPHASE
*				GF 06/09/2003	- issue #21464 - added contract item format.
*				GF 12/05/2003	- issue #23186 - was not using newly formatted item when added
*				TV				- 23061 added isnulls
*				CHS	02/12/2009	- issue #12015 - add insurance code
*
* USAGE: Special to insert a job/phase from the PM change orders.
* The difference between this procedure and the standard is a override
* description is being passed in. Check for valid phase according to
* standard Job/Phase validation. Currently only used within bspPMJCCHAddUpdate.
*
* INPUT PARAMETERS
*    co        	Job Cost Company
*    job        	Valid job
*    PhaseGroup	Valid phase group
*    phase		phase to validate
*    override  	optional if set to 'Y' will override 'lock phases' flag from JCJM
*    item      	optional ContractItem (if null then uses first contract item found)
*    description	optional phase Description (if null then uses description from JCPM)
*
* OUTPUT PARAMETERS
*    msg        	error message.
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @job bJob = null, @PhaseGroup tinyint, @phase bPhase = null,
@override bYN = 'N', @item bContractItem = null, @description bDesc = null, 
@inscode bInsCode = null, @msg varchar(255) output)

   as
   set nocount on


   declare @rcode int, @active bYN, @rowcount int, @pphase bPhase,
   		@desc varchar(255), @projminpct real, @contract bContract, @JCJPexists char(1), @dept bDept,
   		@pitem bContractItem, @pdesc bDesc, @contractitem char(16), @itemformat varchar(10), 
   		@itemmask varchar(10), @ditem varchar(16), @itemlength varchar(10), @inputmask varchar(30)
   
   set @rcode = 0
       
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
   exec @rcode=dbo.bspJCVPHASE @jcco, @job, @phase, @PhaseGroup, @override,
              @pphase output, @pdesc output, @PhaseGroup, @contract output, @pitem output,
   		   @dept output, @projminpct output,@JCJPexists output, @msg output
   
   -- check if invalid phase
   if @rcode <> 0
   	begin
       select @desc = 'Invalid phase.', @rcode = 1
       goto bspexit
       end
       
   -- if job/phase already exists then exit
   if @JCJPexists='Y'  -- no need to add the phase
   	begin
   	select @rcode =0
   	goto bspexit
   	end
   
   -- if no phase is passed use the standard description
   if isnull(@description,'') = '' select @description = @pdesc
   if isnull(@description,'') = '' select @description = ''
	
   -- if no contract item is passed get the first contract item 
   if @item is null select @item = @pitem
   if @item is null
   	begin
   	select @item=Min(Item) from bJCCI with (nolock)
   	where JCCo=@jcco and Contract=@contract
   	end
   
   -- if no contract items exist, lets try to add it
   if @item is null
   	begin
   	select @item=@contractitem
   	insert into bJCCI (JCCo, Contract, Item, Description,
   			Department, TaxCode, UM, RetainPCT, OrigContractAmt,
   			OrigContractUnits, OrigUnitPrice, BillType)
   	select @jcco, @contract,@item, @desc, bJCCM.Department,
   			bJCCM.TaxCode,'LS',bJCCM.RetainagePCT,0,0,0,bJCCM.DefaultBillType
   	from bJCCM with (nolock) where JCCo=@jcco and Contract=@contract
   	end
   
   -- check contract item
   if not exists ( select top 1 1 from bJCCI with (nolock) where JCCo=@jcco and Contract=@contract and Item=@item)
   	begin
       select @desc = 'Cannot add Contract Item', @rcode = 1
       goto bspexit
       end
   
   -- now insert Job Phase
   insert into bJCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, InsCode)
   select  @jcco, @job, @PhaseGroup, @phase, @description, @contract, @item, @projminpct, 'Y', @inscode
   if @@rowcount <> 1
   	begin
       select @desc = 'Cannot add Job Phase', @rcode = 1
       goto bspexit
       end
   
   
   
   bspexit:
   	select @msg=isnull(@msg,'') + ' ' + isnull(@desc,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCADDPHASEWITHDESC] TO [public]
GO
