SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPortalDetailsFieldLookupDelete
(
	@Original_DetailsFieldID int,
	@Original_AssociatedDetailsFieldID int,
	@Original_ConfirmMessageID int,
	@Original_Filter varchar(50),
	@Original_HasResetDefaultButton bit,
	@Original_KeyColumnUpdatesDetailsFieldID int,
	@Original_LookupColumnIDToUpdateAssociated int,
	@Original_LookupID int
)
AS
	SET NOCOUNT OFF;
DELETE FROM pPortalDetailsFieldLookup WHERE (DetailsFieldID = @Original_DetailsFieldID) AND (AssociatedDetailsFieldID = @Original_AssociatedDetailsFieldID OR @Original_AssociatedDetailsFieldID IS NULL AND AssociatedDetailsFieldID IS NULL) AND (ConfirmMessageID = @Original_ConfirmMessageID OR @Original_ConfirmMessageID IS NULL AND ConfirmMessageID IS NULL) AND (Filter = @Original_Filter OR @Original_Filter IS NULL AND Filter IS NULL) AND (HasResetDefaultButton = @Original_HasResetDefaultButton OR @Original_HasResetDefaultButton IS NULL AND HasResetDefaultButton IS NULL) AND (KeyColumnUpdatesDetailsFieldID = @Original_KeyColumnUpdatesDetailsFieldID OR @Original_KeyColumnUpdatesDetailsFieldID IS NULL AND KeyColumnUpdatesDetailsFieldID IS NULL) AND (LookupColumnIDToUpdateAssociated = @Original_LookupColumnIDToUpdateAssociated OR @Original_LookupColumnIDToUpdateAssociated IS NULL AND LookupColumnIDToUpdateAssociated IS NULL) AND (LookupID = @Original_LookupID)


GO
GRANT EXECUTE ON  [dbo].[vpspPortalDetailsFieldLookupDelete] TO [VCSPortal]
GO
