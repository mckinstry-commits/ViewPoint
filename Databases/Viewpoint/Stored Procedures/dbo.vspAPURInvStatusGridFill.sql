SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURInvStatusGridFill]
  
/***********************************************************
* CREATED BY: MV 11/09/06
* MODIFIED By : TJL 10/07/08 - Issue #12992, Modify form code for International Dates
*		
*
* Usage:
*	Used by APUnappInvRev to fill the Invoice Status grid 
*
* Input params:
*	@co			company
*	@mth		UIMth
*	@seq		UISeq
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
(@co bCompany ,@mth bMonth,@seq int, @msg varchar(255)=null output)
as
set nocount on
declare @rcode int
select @rcode = 0
/* check required input params */
if @co is null
  	begin
  	select @msg = 'Missing Company.', @rcode = 1
  	goto bspexit
  	end
  
if @mth is null
  	begin
  	select @msg = 'Missing UIMth.', @rcode = 1
  	goto bspexit
  	end

if @seq is null
  	begin
  	select @msg = 'Missing UISeq.', @rcode = 1
  	goto bspexit
  	end

Select 'Invoice Line'= Line, 'Approval Seq' = ApprovalSeq,  'Reviewer'=Reviewer, 'Approved' = isnull(ApprvdYN,'NA'),
	'Date Assigned' = DateAssigned, 'Date Approved' = DateApproved,
	'Amount Approved' = AmountApproved, 'Rejected' = isnull(Rejected, 'NA'), 'Rejected Reason' = RejReason,
	'Status' = case Rejected when 'Y' then 'R' else case ApprvdYN when 'Y' then 'A' else 'N' end end
	from APUR Where APCo=@co  and APUR.UIMth=@mth  and APUR.UISeq=@seq 
	and Line <> -1 and APUR.APTrans is null and APUR.ExpMonth is null
	Order by Line,ApprovalSeq	--Reviewer, Line, ApprovalSeq

bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPURInvStatusGridFill] TO [public]
GO
