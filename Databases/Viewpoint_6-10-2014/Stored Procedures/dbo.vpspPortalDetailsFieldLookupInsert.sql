SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDetailsFieldLookupInsert
(
	@DetailsFieldID int,
	@LookupID int,
	@Filter varchar(50),
	@KeyColumnUpdatesDetailsFieldID int,
	@AssociatedDetailsFieldID int,
	@LookupColumnIDToUpdateAssociated int,
	@HasResetDefaultButton bit,
	@ConfirmMessageID int
)
AS
	SET NOCOUNT OFF;
INSERT INTO pPortalDetailsFieldLookup(DetailsFieldID, LookupID, Filter, KeyColumnUpdatesDetailsFieldID, AssociatedDetailsFieldID, LookupColumnIDToUpdateAssociated, HasResetDefaultButton, ConfirmMessageID) VALUES (@DetailsFieldID, @LookupID, @Filter, @KeyColumnUpdatesDetailsFieldID, @AssociatedDetailsFieldID, @LookupColumnIDToUpdateAssociated, @HasResetDefaultButton, @ConfirmMessageID);
	SELECT DetailsFieldID, LookupID, Filter, KeyColumnUpdatesDetailsFieldID, AssociatedDetailsFieldID, LookupColumnIDToUpdateAssociated, HasResetDefaultButton, ConfirmMessageID FROM pPortalDetailsFieldLookup WHERE (DetailsFieldID = @DetailsFieldID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsFieldLookupInsert] TO [VCSPortal]
GO
