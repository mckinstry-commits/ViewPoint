SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspARJCContractValwithInfo]

(@jcco bCompany = 0, @contract bContract = null, @transtype char(1) = NULL, @contractstatus tinyint output,
	@PayTerms bPayTerms output,  @Customer bCustomer output, @taxinterface bYN output,
	@RecType tinyint output, @miscdistcode varchar(10) output, @msg varchar(60) output)
as
set nocount on
   
/***********************************************************
* CREATED BY: TJL  06/07/02 - Issue #17268, Do not allow Invoice Entry when Contract not open
* MODIFIED By :	TJL  02/03/05 - Issue #26986, Return Contract RecType value
*		TJL 07/16/07 - Issue #27721, 6x Recode ARMiscDist.  Return Contract MiscDistCode dflt.
*			GF 12/17/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*
*
* USAGE:
* validates JC contract - returns STATUS, DAYS UNTIL DISCOUNT, DAYS UNTIL DUE, and Customer
* 
* 
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against
*   Contract  Contract to validate
*
* OUTPUT PARAMETERS
*   @status   Status of the contract
*   @DaysTillDisc	days until discount in HQPT
*   @DaysTillDue	days until due in HQPT
*
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)

select @rcode = 0, @contractstatus=1

if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
from bJCCO with (nolock) where JCCo=@jcco
if @@rowcount = 0
	begin
	select @msg = 'JC Company invalid!', @rcode = 1
	goto bspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto bspexit
	end

select @taxinterface = TaxInterface, @msg = Description,
@contractstatus = ContractStatus, @PayTerms = PayTerms,
@Customer = Customer, @RecType = RecType, @miscdistcode = MiscDistCode
from bJCCM with (nolock)
where JCCo = @jcco and Contract = @contract
if @@rowcount = 0
	begin
	select @msg = 'Contract not on file!', @rcode = 1
	goto bspexit
	end

if @contractstatus = 0
	begin
	select @msg = 'Cannot invoice pending contracts.', @rcode = 1
	goto bspexit
	end

if @contractstatus = 2 and @postsoftclosedjobs = 'N' and @transtype <> 'W'
	begin
	select @msg = 'Contract is soft-closed!', @rcode=1
	goto bspexit
	end

if @contractstatus = 3 and @postclosedjobs = 'N' and @transtype <> 'W'
	begin
	select @msg = 'Contract is hard-closed!', @rcode=1
	goto bspexit
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARJCContractValwithInfo] TO [public]
GO
