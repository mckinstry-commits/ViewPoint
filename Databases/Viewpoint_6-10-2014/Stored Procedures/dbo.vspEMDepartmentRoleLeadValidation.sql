SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspEMDepartmentRoleLeadValidation]
/***********************************************************
* CREATED BY:	NH	03/22/2012
* MODIFIED BY:  ScottP  04/05/2012  TFS-38524
*					Pass in VPUserName to use in query. Should not give error message if found record is the one for the user
*				
* USAGE:
* Used to validate that each HQ Role in
* a given department only has one lead.
*
* INPUT PARAMETERS
*   Role
*	EMCo
*	Department
*	Lead
*
* OUTPUT PARAMETERS
*   @msg	Description of error if found.
*
* RETURN VALUE
*   0		success
*   1		Failure
***********************************************************/ 

(@Role varchar(20), @EMCo bCompany, @Department bDept, @VPUserName bVPUserName, @Lead bYN, @msg varchar(255) output)
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

if @EMCo is null
begin
	select @msg = 'Missing Company.', @rcode = 1
	goto vspexit
end

if @Department is null
begin
	select @msg = 'Missing Department.', @rcode = 1
	goto vspexit
end


--Check if valid HQ Role already has a lead assigned
if exists(select 1
		  from dbo.vEMDepartmentRole
		  where [Role] = @Role
		  and EMCo = @EMCo
		  and Department = @Department
		  and VPUserName <> @VPUserName
		  and Lead = 'Y'
		  and Active = 'Y') and @Lead = 'Y'
begin
	select @rcode = 1, @msg = 'This Role already has an active lead.'
	goto vspexit
end

	
vspexit:
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspEMDepartmentRoleLeadValidation] TO [public]
GO
