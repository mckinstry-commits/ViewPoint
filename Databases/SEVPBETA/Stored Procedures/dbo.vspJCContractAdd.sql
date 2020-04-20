SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCContractAdd    Script Date: 05/16/2005 9:35:01 AM ******/
CREATE     proc [dbo].[vspJCContractAdd]
/***********************************************************
 * Created By:	SE 11/18/96
 * Modified By:	SE 11/18/96
 *				SE  5/01/97   - Added code for TaxGroup
 *				SE  7/22/97   - added additional checks for contract
 *				SE  9/28/97   - If Contract already exists no worries
 *				JE  4/8/98    - added Retg % to be passed in
 *				JE  5/2/98    - added Contract Status to be passed in
 *				JE  8/21/98   - added code for payment terms
 *				GF 07/19/2000 - use start month passed in as a parameter
 *				DANF 03/13/01 - Added security group to allow access to contracts.
 *				DC 4/10/03 - issue 20818.  Added code to pull CustGroup from HQCO based on ARCo from JCCO
 *				DC 01/30/2004 - 18385 - Check Job History when new Job or Contract is added.
 *				DANF 03/19/04 - 20980 expanded Security Group.
 *				TV - 23061 added isnulls
 *				GF - Modified for 6.x
 *				DANF - Added TM Template
 *				danf 10/29/2007 - Issue 125947 Fixed Contract Item insert to update Start Month.
 *				CHS	01/22/2009	- issue #26087
 *
 * USAGE:
 * creates minimal JCCM entries and default item 1 in JCCI.
 * Used by AutoAdd from Job Master and PM Project Master
 * an error is returned if anything goes wrong.
 *
 *
 * INPUT PARAMETERS
 *   JCCo        JC Co to get JCPC recs from
 *   Contract    Contract to add
 *   Description Description of Contract
 *   Department  Department for new contract
 *   ArGroup     AR Group for customer.
 *   Customer    Customer for contract
 *   Retainage   Retainage percent
 *   StartMth    Contract Start Month
 *   ContractStatus Status
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@jcco bCompany = 0, @contract bContract = null, @description bItemDesc,
 @department bDept, @argroup tinyint = null, @customer bCustomer = null, @retg bPct = null,
 @startmth bMonth, @contractstatus tinyint, @tmtemplate varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validphasechars int, @lockphases bYN, @PhaseGroup tinyint,
		@taxgroup bGroup, @PayTerms bPayTerms, @defaultsecurity smallint,
		@secure bYN, @item bContractItem, @dfltitem bContractItem, @itemlength varchar(10),
		@itemmask varchar(30), @defaultbilltype bBillType

select @rcode = 0, @secure='N'

if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

if isnull(@contract,'') = ''
   	begin
   	select @msg = 'Missing contract!', @rcode = 1
   	goto bspexit
   	end

if isnull(@department,'') = ''
   	begin
   	select @msg = 'Missing department!', @rcode = 1
   	goto bspexit
   	end

-- -- -- if contract already exists in JCCM - done exit SP
if exists(select * from bJCCM with (nolock) where JCCo=@jcco and Contract=@contract)
	begin
	select @msg = 'Contract exists!', @rcode = 0
	goto bspexit
	end

-- -- -- get input mask for bContractItem
select @itemmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bContractItem'
if isnull(@itemmask,'') = '' select @itemmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '16'
if @itemmask in ('R','L')
	begin
   	select @itemmask = @itemlength + @itemmask + 'N'
   	end

-- -- -- format ContractItem '1'
set @dfltitem = '1'
exec @retcode = dbo.bspHQFormatMultiPart @dfltitem, @itemmask, @item output

-- -- -- if @argroup is null use customer group from HQCO
if @argroup is null
	begin
   	select @argroup=h.CustGroup
   	from dbo.bHQCO h with (nolock) JOIN dbo.bJCCO j with (nolock) ON h.HQCo = j.ARCo
   	where j.JCCo = @jcco
	end

-- -- -- get tax group from HQCO
select @taxgroup=TaxGroup from dbo.bHQCO with (nolock) where HQCo=@jcco

-- -- -- DC 18385
-- -- -- Check Contract history to see if this contract number has been used
exec @rcode = dbo.bspJCJMJobVal @jcco, @contract, 'C', @msg output
if @rcode = 1 goto bspexit

-- -- -- get payterms from ARCM
select @PayTerms=PayTerms from dbo.bARCM with(nolock) where CustGroup=@argroup and Customer=@customer

-- -- -- get DefaultBillType
select @defaultbilltype=isnull(DefaultBillType, 'P') from bJCCO with (nolock) where JCCo=@jcco

-- -- -- if Security is turned off or not found set default security group to null
select @secure = Secure, @defaultsecurity = DfltSecurityGroup
from dbo.DDDTShared with (nolock) where Datatype = 'bContract'
if @@rowcount <> 1 or isnull(@secure,'N') = 'N' select @secure='N', @defaultsecurity=null


-- -- -- insert contract using a transaction
begin transaction
insert into bJCCM (JCCo, Contract, Description, Department, DefaultBillType, TaxGroup, TaxCode,
		OriginalDays, ContractStatus, CurrentDays, CustGroup, Customer, TaxInterface, RetainagePCT,
		PayTerms, StartMonth, SecurityGroup, JBTemplate)
select @jcco, @contract, @description, @department, @defaultbilltype, @taxgroup, null,
		0, @contractstatus, 0, @argroup, @customer, 'N', isnull(@retg,0),
		@PayTerms, @startmth, @defaultsecurity, @tmtemplate
if @@rowcount <> 1
	begin
	select @msg= 'Error inserting contract!  Insert cancled.', @rcode=1
	rollback transaction
	goto bspexit
	end

-- -- -- insert a default item 1
insert into dbo.bJCCI (JCCo, Contract, Item, Description, BillDescription, Department, TaxGroup, UM, BillType, RetainPCT, StartMonth)
select @jcco, @contract, @item, @description, @description, @department, @taxgroup, 'LS', @defaultbilltype, isnull(@retg,0), @startmth
if @@rowcount <> 1
	begin
	select @msg= 'Error during contract add, trying to insert contract item: ' + isnull(@item,'') + '!  Insert cancelled.'
	rollback transaction
	goto bspexit
	end



select @rcode = 0
commit transaction





bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCContractAdd] TO [public]
GO
