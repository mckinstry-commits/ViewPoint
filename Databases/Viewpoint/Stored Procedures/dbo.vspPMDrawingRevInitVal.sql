SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE proc [dbo].[vspPMDrawingRevInitVal]
/***********************************************************
* CREATED By:	GP 07/08/2009 - Issue 134115
* MODIFIED By:	
*
*
* USAGE:
* Validates the PM Drawing Revision to ensure it does not currently exist.
*
*
*
*
* INPUT PARAMETERS
*	@PMCo		PM Company
*	@Project	Project
*	@Revision	Revision
*
* OUTPUT PARAMETERS
*	@msg		error message if error occurs otherwise Description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@PMCo bCompany = null, @Project bJob = null, @Revision varchar(10) = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int
select @rcode = 0

--VALIDATION--
if @PMCo is null
begin
	select @msg = 'Missing PMCo.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @Revision is null
begin
	select @msg = 'Missing Revision.', @rcode = 1
	goto vspexit
end

--Check if Revision already exists
if exists(select top 1 1 from PMDR with (nolock) where PMCo=@PMCo and Project=@Project and Rev=@Revision)
begin
	select @msg = 'Revision already exists, please enter another.', @rcode = 1
	goto vspexit
end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDrawingRevInitVal] TO [public]
GO
