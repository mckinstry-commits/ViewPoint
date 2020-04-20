SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE dbo.vpspRolesUpdate
(
	@Name varchar(50),
	@Description varchar(255),
	@Active bit,
	@Static bit,
	@Original_RoleID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@Original_Active bit,
	@Original_Static bit,
	@RoleID int
)
AS
	SET NOCOUNT OFF;
UPDATE pRoles SET Name = @Name, Description = @Description, Active = @Active, Static = @Static 
	WHERE (RoleID = @Original_RoleID) AND (Description = @Original_Description) AND (Name = @Original_Name) AND (Active = @Original_Active) AND (Static = @Original_Static);
	

execute vpspRolesGet @RoleID






GO
GRANT EXECUTE ON  [dbo].[vpspRolesUpdate] TO [VCSPortal]
GO
