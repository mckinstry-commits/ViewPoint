SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRCheckReplaceInfoGet]
/*************************************
* Created: GG 05/11/07
* Modified:
* 
* Returns existing payment information for a specific PR Co#, PR Group,
* Pay Period, Employee, and Pay Sequence#.  Used by PR Check Replacement 
*
* Input:
*	@prco			PR Company
*	@prgroup		PR Group
*	@prenddate		Pay Period Ending Date
*	@employee		Employee #
*	@payseq			Payment Sequence#
*
* Output:
*	@hrs			Total Hours
*	@earns			Total Earnings
*	@dedns			Total Deductions
*	@netpay			Net Pay
*	@paymethod		Payment Method	C = Check, E = EFT
*	@chktype		Check Type		null = none, C = computer, M = manual
*	@cmco			CM Company #
*	@cmacct			CM Account
*	@cmacctdesc		CM Account description
*	@cmref			CM Reference
*	@cmrefseq		CM Reference Seq#
*	@eftseq			EFT Seq#
*	@paiddate		Paid Date
*	@paidmth		Paid Month
*	@msg				Error message				
*
* Return code:
*	0 = success, 1 = error 
**************************************/
(@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
	@hrs bHrs output, @earns bDollar output, @dedns bDollar output, @netpay bDollar output,
	@paymethod char(1) output, @chktype char(1) output, @cmco bCompany output, @cmacct bCMAcct output,
	@cmacctdesc bDesc output, @cmref bCMRef output, @cmrefseq tinyint output, @eftseq smallint output,
	@paiddate bDate output, @paidmth bMonth output, @msg varchar(255) output)
 
as 
set nocount on
declare @rcode int
select @rcode = 0
 
-- get existing payment information
select @cmco = s.CMCo, @cmacct = s.CMAcct, @cmacctdesc = a.Description, @paymethod = s.PayMethod, @cmref = s.CMRef,
	@cmrefseq = s.CMRefSeq, @eftseq = s.EFTSeq, @chktype = s.ChkType, @paiddate = s.PaidDate, @paidmth = s.PaidMth,
	@hrs = s.Hours, @earns = s.Earnings, @dedns = s.Dedns, @netpay = s.Earnings - s.Dedns
from dbo.PRSQ s (nolock)	--  use views for security
left join dbo.CMAC a on a.CMCo = s.CMCo and a.CMAcct = s.CMAcct
where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate and s.Employee = @employee and s.PaySeq = @payseq
if @@rowcount = 0
	begin
	select @msg = 'Pay Period Sequence Control entry not found for this Employee and Pay Period.', @rcode = 1
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCheckReplaceInfoGet] TO [public]
GO
