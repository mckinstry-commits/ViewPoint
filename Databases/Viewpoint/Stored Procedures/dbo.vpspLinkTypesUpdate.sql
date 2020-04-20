SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspLinkTypesUpdate
(
	@Name varchar(50),
	@Description varchar(255),
	@Original_LinkTypeID int,
	@Original_Description varchar(255),
	@Original_Name varchar(50),
	@LinkTypeID int
)
AS
	SET NOCOUNT OFF;
UPDATE pLinkTypes SET Name = @Name, Description = @Description WHERE (LinkTypeID = @Original_LinkTypeID) AND (Description = @Original_Description) AND (Name = @Original_Name);
	

execute vpspLinkTypesUpdate @LinkTypeID = @LinkTypeID



GO
GRANT EXECUTE ON  [dbo].[vpspLinkTypesUpdate] TO [VCSPortal]
GO
