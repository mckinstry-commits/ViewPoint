SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- Author:      Chris Crewdson
-- Create date: 2012-05-18
-- Description: This is the list of forms that means the user given access 
--              should be set as an SSRS User
-- Modified:    
-- ==============================================================================
CREATE PROCEDURE [dbo].[vspSSRSGetUsersAndGroupsWithAccess]
-- Add the parameters for the stored procedure here
(@msg varchar(80) = '' output)

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    DECLARE @rcode int
    SELECT @rcode = 0
    
    DECLARE @formNames TABLE 
    (
        Form VARCHAR(30)
    )

    INSERT INTO @formNames (Form)
    EXECUTE vspSSRSGetSysAdminFormNames;
    
    INSERT INTO @formNames (Form)
    EXECUTE vspSSRSGetSysUserFormNames;

	SELECT DISTINCT(SecurityGroup) 
    FROM DDFS fs
    JOIN @formNames fn ON fs.Form = fn.Form
    
	SELECT DISTINCT(VPUserName) 
    FROM DDFS fs
    JOIN @formNames fn ON fs.Form = fn.Form

    return @rcode

bsperror:
    
    if @rcode <> 0 select @msg = @msg + char(13) + char(20) + '[vspSSRSGetUsersAndGroupsWithAccess]'
    return @rcode

END
GO
GRANT EXECUTE ON  [dbo].[vspSSRSGetUsersAndGroupsWithAccess] TO [public]
GO
