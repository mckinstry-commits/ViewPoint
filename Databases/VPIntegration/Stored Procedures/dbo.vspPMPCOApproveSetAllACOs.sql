SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveSetAllACOs]
/************************************
*Created by:	GP 4/5/2011 - TK-04872
*Modified by:
*
*Purpose:	Sets all ACOs for a specified
*			group of PCOs in PCO Approval.
*			Also marks all items ready to
*			approve after ACO is assigned.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Username bVPUserName,
@ACO bACO, @ACODesc bItemDesc, @ReportSeqNum int, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @DeleteApprovalID smallint
select @rcode = 0

--VALIDATION
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @ApprovalID is null
begin
	select @msg = 'Missing Approval ID.', @rcode = 1
	goto vspexit
end

if @Username is null
begin
	select @msg = 'Missing Username.', @rcode = 1
	goto vspexit
end

if @ACO is null
begin
	select @msg = 'Missing ACO.', @rcode = 1
	goto vspexit
end

--SET ACOs
update dbo.PMPCOApprove
set ACO = @ACO, ACODesc = @ACODesc, ReportSeqNum = @ReportSeqNum
where PMCo = @PMCo and ApprovalID = @ApprovalID and Username = @Username

--Mark items ready to approve by default
exec @rcode = dbo.vspPMPCOApproveSelectAll @PMCo, @ApprovalID, @ACO, @msg output
if @rcode <> 0	goto vspexit



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveSetAllACOs] TO [public]
GO
