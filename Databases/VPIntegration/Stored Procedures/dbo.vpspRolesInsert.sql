SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE      PROCEDURE [dbo].[vpspRolesInsert]
(
	@Name varchar(50),
	@Description varchar(255),
	@Active bit, 
	@Static bit
)
AS
	SET NOCOUNT OFF;
INSERT INTO pRoles(Name, Description, Active, Static) VALUES (@Name, @Description, @Active, @Static);
	
DECLARE @RoleID int 
SET @RoleID = SCOPE_IDENTITY() 
execute vpspRolesGet @RoleID









GO
GRANT EXECUTE ON  [dbo].[vpspRolesInsert] TO [VCSPortal]
GO
