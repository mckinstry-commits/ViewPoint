SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPMPCOApproveClearApproved]
/************************************
*Created by:	GP 4/1/2011
*Modified by:
*
*Purpose:	Called from PMPCOSApproved form
*			to clear all apprvoed items for a
*			PCO record when the ACO is changed.
*************************************/
(@PMCo bCompany, @ApprovalID smallint, @Project bProject, @PCOType bPCOType, @PCO bPCO, @msg varchar(255) output)
as
set nocount on

declare @rcode int
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

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
end

--CLEAR APPROVED ITEMS
update dbo.vPMPCOApproveItem
set Approve = 'N', ACOItem = null, ApprovalDate = null
where PMCo = @PMCo and ApprovalID = @ApprovalID and Project = @Project and PCOType = @PCOType and PCO = @PCO



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOApproveClearApproved] TO [public]
GO
