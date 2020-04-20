SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:  2012-05-24 Chris Crewdson
* MODIFIED: 
*
* Purpose:  Determines if a given user has access to the forms that 
*           define them as a SSRS System Admin or SSRS System User
* 
*************************************************************************/
CREATE PROCEDURE [dbo].[vspDDSSRSAdminUserCheck]
(
    @user dbo.bVPUserName,
    @sysadmin char(1) OUTPUT,
    @sysuser char(1) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @sysadmin = 'N';
    SELECT @sysuser = 'N';

    DECLARE @SysAdminFormNames TABLE (Form VARCHAR(30));
    DECLARE @SysUserFormNames TABLE (Form VARCHAR(30));
    
    INSERT @SysAdminFormNames
    EXEC dbo.vspSSRSGetSysAdminFormNames
    
    INSERT @SysUserFormNames
    EXEC dbo.vspSSRSGetSysUserFormNames

    -- Does the user have access to any forms that are in the SysAdminFormNames list?
    IF EXISTS(
        --Direct access to the forms
        SELECT 1
        FROM dbo.vDDFS fs WITH (NOLOCK)
        JOIN @SysAdminFormNames fn ON fn.Form = fs.Form
        WHERE fs.VPUserName = @user
              AND fs.Access IN (0, 1)
        UNION ALL 
        --Access to the forms via a group
        SELECT 1
        FROM dbo.vDDFS fs WITH ( NOLOCK )
        JOIN @SysAdminFormNames fn ON fn.Form = fs.Form
        JOIN dbo.vDDSU su WITH ( NOLOCK ) ON fs.SecurityGroup = su.SecurityGroup
        WHERE   su.VPUserName = @user
                AND fs.Access IN (0, 1)
                AND NOT EXISTS(
                    --And not denied at user level
                    SELECT 1
                    FROM dbo.vDDFS fs WITH (NOLOCK)
                    JOIN @SysAdminFormNames fn ON fn.Form = fs.Form
                    WHERE fs.VPUserName = @user
                          AND fs.Access = 2
                )
    )
    BEGIN
        SELECT @sysadmin = 'Y'
    END

    -- Does the user have access to any forms that are in the SysUserFormNames list?
    IF EXISTS(
        --Direct access to the forms
        SELECT 1
        FROM dbo.vDDFS fs WITH (NOLOCK)
        JOIN @SysUserFormNames fn ON fn.Form = fs.Form
        WHERE fs.VPUserName = @user
              AND fs.Access IN (0, 1)
        UNION ALL
        --Access to the forms via a group
        SELECT 1
        FROM dbo.vDDFS fs WITH ( NOLOCK )
        JOIN @SysUserFormNames fn ON fn.Form = fs.Form
        JOIN dbo.vDDSU su WITH ( NOLOCK ) ON fs.SecurityGroup = su.SecurityGroup
        WHERE   su.VPUserName = @user
                AND fs.Access IN (0, 1)
                AND NOT EXISTS(
                    --And not denied at user level
                    SELECT 1
                    FROM dbo.vDDFS fs WITH (NOLOCK)
                    JOIN @SysUserFormNames fn ON fn.Form = fs.Form
                    WHERE fs.VPUserName = @user
                          AND fs.Access = 2
                )
    )
    BEGIN
        SELECT @sysuser = 'Y'
    END

END

GO
GRANT EXECUTE ON  [dbo].[vspDDSSRSAdminUserCheck] TO [public]
GO
