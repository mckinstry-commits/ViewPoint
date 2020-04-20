SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBJCCDInfo    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBJCCDInfo]
/***********************************************************
* CREATED BY	: kb 7/31/00
* MODIFIED BY	: bc 08/25/00
*		kb 5/22/01 - issue 13496
* 		kb 8/13/1 - issue #13963
*     	kb 3/11/2 - issue #16560
*    	kb 3/18/2 - issue #16560
*		TJL 02/26/03 - Issue #19765, Category returning as NULL for Material from HQMT. Fix bspJBTandMGetCategory
*		TJL 04/12/04 - Issue #24240, Reduce this to Validation only.  Rate, Amount determined by other procedures
*		TJL 04/14/06 - Issue #28232, 6x Rewrite.  Removed returned JCCD values from here and placed in bspJBJCCDDisplay
*
*					  
*
* USED IN:
*	JB JCDetail - All Form, Seq #201 DDFI validation only.
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
   
(@co bCompany, @billmth bMonth, @billnum int, @jcmonth bMonth, @jctrans bTrans,
	@msg varchar(255) output)
as

set nocount on
   
declare @rcode int, @jbcontract bContract, @jccontract bContract, @jcjpitem bContractItem, @phasegroup bGroup,
	@billtype char(1), @jbbillgroup bBillingGroup, @jcbillgroup bBillingGroup, @template varchar(10), 
	@restrictbillgroup bYN,	@jccdbillstatus tinyint, @jccdbillmonth bMonth, @jccdbillnum int,
	@job bJob, @phase bPhase
   
select @rcode = 0
   
select @jbcontract = Contract, @jbbillgroup = BillGroup, @template = Template,
	@restrictbillgroup = RestrictBillGroupYN
from JBIN with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum

select @jccdbillstatus = JBBillStatus, @jccdbillmonth = JBBillMonth, @jccdbillnum = JBBillNumber,
   	 @job = Job, @phasegroup = PhaseGroup, @phase = Phase 
from JCCD with (nolock)
where JCCo = @co and Mth = @jcmonth and CostTrans = @jctrans
if @@rowcount = 0
	begin
   	select @msg = 'Invalid JC Transaction', @rcode = 1
   	goto bspexit
   	end

if @jccdbillstatus in (1,2)		--and (@jccdbillmonth <> @billmth or
								--@jccdbillnum <> @billnum)
   	begin
	select @msg = 'JC transaction is already associated with an existing bill: - BillMonth  '
         + isnull(convert(varchar(8),@jccdbillmonth,1),'') + ', BillNumber #'
         + isnull(convert(varchar(20),@jccdbillnum),''), @rcode = 1
	goto bspexit
	end
   
   --this probably won't occur but vision had it just in case
select @jccontract = Contract, @jcjpitem = Item
from JCJP with (nolock)
where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase
if @@rowcount = 0
   	begin
   	select @msg = 'Job/Phase missing', @rcode = 1
   	goto bspexit
   	end
   
if @jbcontract <> @jccontract
   	begin
    select @msg = 'Cost posted to different contract', @rcode = 1
   	goto bspexit
   	end
   
select @billtype = BillType, @jcbillgroup = BillGroup
from JCCI with (nolock)
where JCCo = @co and Contract = @jccontract and Item = @jcjpitem
if @@rowcount = 0
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' not found', @rcode = 1
   	goto bspexit
   	end
   
if @billtype not in ('T','B')
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' not flagged as T & M', @rcode = 1
   	goto bspexit
   	end
   
if @jcbillgroup is not null and isnull(@jbbillgroup,'') <> @jcbillgroup and
   	@restrictbillgroup = 'Y'
   	begin
   	select @msg = 'Contract item ' + isnull(convert(varchar(16),@jcjpitem),'') + ' billing group does not match invoice', @rcode = 1
   	goto bspexit
   	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBJCCDInfo] TO [public]
GO
