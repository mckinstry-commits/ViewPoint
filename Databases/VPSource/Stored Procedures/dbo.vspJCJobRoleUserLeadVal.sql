SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  proc [dbo].[vspJCJobRoleUserLeadVal]
/***********************************************************
* CREATED BY:	GF 03/23/2012 TK-13526
* MODIFIED BY:
*				
* USAGE:
* Used in JC Job Master Roles and PM Project Roles to validate
* that only one user is the lead for a job role.
*
* INPUT PARAMETERS
* @JCCo			JC/PM Company
* @Job			JC/PM Job
* @Role			Role to check lead
* @VPUserName	User to check lead
* @Lead			Flag to indicate if lead
*
*
* OUTPUT PARAMETERS
* @msg			Error message for role/user and lead
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@JCCo bCompany = 0, @Job bJob = NULL, @Role varchar(20) = NULL,
 @VPUserName bVPUserName = NULL, @Lead CHAR(1) = 'N',
 @Msg varchar(255) output)
as
set nocount on

DECLARE @rcode INT

SET @rcode = 0

---- check key fields
IF @JCCo IS NULL
	OR @Job IS NULL
	OR @Role IS NULL
	OR @VPUserName IS NULL
	BEGIN
	GOTO vspexit
	END
	
---- if not lead no check needed
IF ISNULL(@Lead, 'N') = 'N' GOTO vspexit

---- check if there is another lead already for this job and role
IF EXISTS(SELECT 1 FROM dbo.JCJobRoles WHERE JCCo = @JCCo
			AND Job = @Job
			AND [Role] = @Role
			AND Lead = 'Y'
			AND VPUserName <> @VPUserName)
	BEGIN
	SELECT @Msg = 'The Job Role: ' + dbo.vfToString(@Role) + ' has a different user specified as lead. Only one lead is allowed for a job role.'
	SET @rcode = 1
	GOTO vspexit
	END




	
vspexit:
	RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[vspJCJobRoleUserLeadVal] TO [public]
GO
