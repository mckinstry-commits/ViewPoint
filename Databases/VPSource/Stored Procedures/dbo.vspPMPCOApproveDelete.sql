SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveDelete]
/************************************
*Created by:	GP 3/25/2011
*Modified by:
*
*Purpose:	Delete ApprovalID records in
*			PMPCOApprove and PMPCOApproveItem
*			for the PM Change Order Approval form
*			and vspPMPCOApproveGetPCOItems.
*************************************/
(@PMCo bCompany, @Username bVPUserName, @ApprovalID smallint, @msg varchar(255) output)
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

if @Username is null
begin
	select @msg = 'Missing Username.', @rcode = 1
	goto vspexit
end

if @ApprovalID is null
begin
	select @msg = 'Missing ApprovalID.', @rcode = 1
	goto vspexit
end

--DELETE
delete dbo.vPMPCOApproveItem 
where PMCo = @PMCo and ApprovalID = @ApprovalID

delete dbo.vPMPCOApprove 
where PMCo = @PMCo and ApprovalID = @ApprovalID


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveDelete] TO [public]
GO
