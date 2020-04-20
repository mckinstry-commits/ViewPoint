SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Aaron Lang, vspVAAddUsersToGroup>
-- Create date: <6/1/07>
-- Description:	Inserts a list of users into a group
--				
-- =============================================
CREATE PROCEDURE [dbo].[vspVAAddUsersToGroup]

(@NameArray VARCHAR(max), @Group int) 

	-- Add the parameters for the stored procedure here
AS
Begin

insert DDSU (SecurityGroup, VPUserName)
Select @Group, Names  from vfTableFromArray(@NameArray) 
Where Names not in (SElect VPUserName from DDSU where SecurityGroup = @Group)


end
GO
GRANT EXECUTE ON  [dbo].[vspVAAddUsersToGroup] TO [public]
GO
