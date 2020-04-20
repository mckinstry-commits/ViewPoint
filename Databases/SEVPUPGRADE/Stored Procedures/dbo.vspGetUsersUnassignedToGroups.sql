SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<AL, vspGetUsersUnassignedToGroups>
-- Create date: <3/31/2008>
-- Description:	<Gets users that are not assigned to the group passed in>
-- =============================================
CREATE PROCEDURE [dbo].[vspGetUsersUnassignedToGroups]
	-- Add the parameters for the stored procedure here
	(@securitygroup int) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Get users not assigned to the passd in group
	SELECT VPUserName FROM DDUP (nolock)
	where VPUserName not in (Select VPUserName from DDSU where SecurityGroup = @securitygroup)
END

GO
GRANT EXECUTE ON  [dbo].[vspGetUsersUnassignedToGroups] TO [public]
GO
