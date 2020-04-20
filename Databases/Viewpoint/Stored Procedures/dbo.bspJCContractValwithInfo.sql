SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCContractValwithInfo    Script Date: 8/28/99 9:35:02 AM ******/
CREATE   proc [dbo].[bspJCContractValwithInfo]
/***********************************************************
    * CREATED BY: CJW
    * MODIFIED By : CJW 05/19/97
    *				TV - 23061 added isnulls
*					GF 12/12/2007 - issue #25569 separate post closed job flags in JCCO enhancement
*
    * USAGE:
    * validates JC contract - returns STATUS, DAYS UNTIL DISCOUNT, DAYS UNTIL DUE, and Customer
    * an error is returned if any of the following occurs
    * no contract passed, no contract found in JCCM.
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
(@jcco bCompany = 0, @contract bContract = null, @transtype char(1) = NULL, @contractstatus tinyint output,
 @PayTerms bPayTerms output,  @Customer bCustomer output, @taxinterface bYN output,
 @msg varchar(60) output)
as
set nocount on

declare @rcode int, @postclosedjobs varchar(1), @postsoftclosedjobs varchar(1)

select @rcode = 0, @contractstatus=1

if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end

select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs=PostSoftClosedJobs
from bJCCO where JCCo=@jcco
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


select @taxinterface = j.TaxInterface, @msg = j.Description,
   	@contractstatus=j.ContractStatus, @PayTerms = j.PayTerms,
   	@Customer = j.Customer
from bJCCM j
where j.JCCo = @jcco and j.Contract = @contract
if @@rowcount = 0
   	begin
   	select @msg = 'Contract not on file!', @rcode = 1
   	goto bspexit
   	end

if @contractstatus = 2 and @postsoftclosedjobs = 'N' and @transtype <> 'W'
	begin
	select @msg = 'Contract Soft-Closed!', @rcode = 1
	goto bspexit
	end

if @contractstatus = 3 and @postclosedjobs = 'N' and @transtype <> 'W'
	begin
   	select @msg= 'Contract Hard-Closed!', @rcode=1
	goto bspexit
	end


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCContractValwithInfo] TO [public]
GO
