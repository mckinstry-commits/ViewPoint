SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE dbo.vpspLinkTypesGet
(@LinkTypeID int = Null)
AS
	SET NOCOUNT ON;
SELECT LinkTypeID, Name, Description FROM pLinkTypes with (nolock)
	where LinkTypeID = IsNull(@LinkTypeID, LinkTypeID)



GO
GRANT EXECUTE ON  [dbo].[vpspLinkTypesGet] TO [VCSPortal]
GO
