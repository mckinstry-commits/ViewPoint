SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE dbo.vpspRolesDelete
(
	@Original_RoleID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Active bit,
	@Original_Static bit
)
AS
	SET NOCOUNT OFF;
DELETE FROM pRoles WHERE (RoleID = @Original_RoleID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Active = @Original_Active) AND (Static = @Original_Static)






GO
GRANT EXECUTE ON  [dbo].[vpspRolesDelete] TO [VCSPortal]
GO
