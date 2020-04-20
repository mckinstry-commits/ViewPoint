SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[vspINLocationRoleLeadValidation]
/***********************************************************
* CREATED BY:	NH	03/22/2012
* MODIFIED BY:
*				
* USAGE:
* Used to validate that each HQ Role in
* a given location only has one lead.
*
* INPUT PARAMETERS
*   Role
*	INCo
*	Loc
*	Lead
*
* OUTPUT PARAMETERS
*   @msg	Description of error if found.
*
* RETURN VALUE
*   0		success
*   1		Failure
***********************************************************/ 

(@Role varchar(20), @INCo bCompany, @Loc bLoc, @Lead bYN, @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0


--Validate
if @Role is null
begin
	select @msg = 'Missing Role.', @rcode = 1
	goto vspexit
end

if @INCo is null
begin
	select @msg = 'Missing Company.', @rcode = 1
	goto vspexit
end

if @Loc is null
begin
	select @msg = 'Missing Location.', @rcode = 1
	goto vspexit
end


--Check if valid HQ Role already has a lead assigned
if exists(select 1
		  from dbo.vINLocationRole
		  where [Role] = @Role
		  and INCo = @INCo
		  and Loc = @Loc
		  and Lead = 'Y'
		  and Active = 'Y') and @Lead = 'Y'
begin
	select @rcode = 1, @msg = 'This Role already has an active lead.'
	goto vspexit
end
	
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspINLocationRoleLeadValidation] TO [public]
GO
