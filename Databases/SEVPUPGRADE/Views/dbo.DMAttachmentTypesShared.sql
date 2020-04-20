SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	Modified by: JonathanP 04/13/09 - 129918: This view will now also return the MonthsToRetain column
*/


/* Custom types*/
CREATE VIEW [dbo].[DMAttachmentTypesShared]
AS
SELECT     ISNULL(c.AttachmentTypeID, s.AttachmentTypeID) AS AttachmentTypeID, 
		   ISNULL(c.Name, d.CultureText) AS Name, 
		   CASE WHEN c.Name IS NULL THEN s.Description ELSE c.Description END AS Description, 
				
           CASE WHEN c.AttachmentTypeID IS NULL AND s.AttachmentTypeID < 50000 THEN 'Standard' 
                WHEN s.AttachmentTypeID = c.AttachmentTypeID THEN 'Override' 
                WHEN c.AttachmentTypeID > 50000 THEN 'Custom' 
                ELSE '' END AS Status,
                
           ISNULL(c.MonthsToRetain, NULL) as MonthsToRetain, 
           ISNULL(c.Secured, 'Y') as Secured               
                
FROM       dbo.DMAttachmentTypes AS s 
		   INNER JOIN dbo.vDDTM AS d ON s.TextID = d.TextID 
		   FULL OUTER JOIN dbo.vDMAttachmentTypesCustom AS c ON s.AttachmentTypeID = c.AttachmentTypeID
		   
WHERE     (s.Active <> 'N') OR (c.AttachmentTypeID IS NOT NULL)




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdDMAttachmentTypesShared] on [dbo].[DMAttachmentTypesShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: JonathanP 04/11/08
-- Modified:
--			JonathanP 11/06/08 - 128444 Changed error message from select @errorMessage = 'Attachment types in use can not be deleted.' to select @errorMessage = 'Attachment types in use can not be deleted. Please remove these types from any attachments that use them.'
--
-- Processes deletions to DMAttachmentTypesShared, a view combining standard
-- and custom attachment types, into their respective tables.
--
-- Deleting any attachment type removes its overridden or custom entry from vDMAttachmentTypesCustom.
-- Standard attachment types can not be deleted.
--
-- =============================================
declare @errorMessage varchar(255), @numberOfRows int
   
select @numberOfRows = @@rowcount
if @numberOfRows = 0 return
set nocount on

-- Check if any attachments are using any of the attachment types that will be deleted.
SELECT d.AttachmentTypeID 
	FROM deleted d 
	JOIN HQAT a ON d.AttachmentTypeID = a.AttachmentTypeID	
	WHERE d.AttachmentTypeID IS NOT NULL 
	
if @@rowcount > 0
begin	

	-- Some of the attachment types to be deleted exist in HQAT. This will throw an error since
	-- we do not want to delete any attachment types that are in use. The only exception to this is if
	-- ALL the types that are being deleted are overriden types. We check for this case here by looking
	-- at the types in the custom table that are overrides.
	SELECT c.AttachmentTypeID 
		FROM deleted d 
		JOIN vDMAttachmentTypesCustom c 
			ON d.AttachmentTypeID = c.AttachmentTypeID
		WHERE c.AttachmentTypeID < 50000

	-- @@ROWCOUNT in this case is the number of types that are overriden. @numberOfRows is the number 
	-- of types to delete. This check makes sure that every type that is being deleted is an overriden type.
	IF @@ROWCOUNT <> @numberOfRows 
	BEGIN
		select @errorMessage = 'Attachment types in use can not be deleted. Please remove these types from any attachments that use them.'
		goto triggerError
	END	
end

-- Delete custom types.
delete vDMAttachmentTypesCustom
from deleted d
join vDMAttachmentTypesCustom c on c.AttachmentTypeID = d.AttachmentTypeID

-- Even if logged in as viewpointcs, we should not delete standard types. Check if there are 
-- standard types being deleted.
select @numberOfRows = count(*) from deleted d where d.Status = 'Standard'

if @numberOfRows > 0
begin
	select @errorMessage = 'Standard Types can not be deleted.'
	goto triggerError
end

return

triggerError:
	RAISERROR(@errorMessage, 11, -1);
	rollback transaction

	





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtiDMAttachmentTypesShared] on [dbo].[DMAttachmentTypesShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: JonathanP 04/11/08
-- Modified: JonathanP 04/13/09 - See 129918: The MonthsToRetain column is now inserted.
--
--
-- Processes insertions to DMAttachmentTypesShared, a view combining standard
-- and custom attachment types from into their respective tables. This trigger will
-- add custom attachment types. To add standard attachment types, use the
-- DMAttachmentTypes view. 
--
-- =============================================
declare @errorMessage varchar(255), @numberOfRows int

DECLARE @newAttachmentTypeID int
						
-- Get the next AttachmentTypeID number.
SELECT @newAttachmentTypeID = ISNULL(MAX(AttachmentTypeID), 50000) + 1 
	FROM vDMAttachmentTypesCustom 
	WHERE AttachmentTypeID > 50000	
	
-- Insert the record into the custom attachment types table.
INSERT INTO vDMAttachmentTypesCustom (AttachmentTypeID, Name, [Description], MonthsToRetain, Secured)
	SELECT @newAttachmentTypeID, i.Name, i.[Description], i.MonthsToRetain, i.Secured
		FROM inserted i

return

	






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtuDMAttachmentTypesShared] on [dbo].[DMAttachmentTypesShared] INSTEAD OF UPDATE AS
-- =============================================
-- Created: JonathanP 04/11/08
-- Modified: JonathanP 04/13/09 - 129918: Updated to return new MonthToRetain column.
--
-- Processes updates to DMAttachmentTypesShared, a view combining standard
-- and custom attachment types from their respective tables. This trigger will
-- update custom attachment types. To update a standard attachment type, use the
-- DMAttachmentTypes view. 
--
-- =============================================
declare @errorMessage varchar(255), @numberOfRows int

		
	-- Check if the given attachment type ID does not exist yet in the custom table. If it doesn't,
	-- we'll add it. Otherwise, update the existing record.
	IF not exists(SELECT TOP 1 1 FROM vDMAttachmentTypesCustom c join inserted i on c.AttachmentTypeID = i.AttachmentTypeID)
	BEGIN			
		-- Insert the custom type into the custom attachment types table (it may now override a standard type).
		INSERT INTO vDMAttachmentTypesCustom (AttachmentTypeID, Name, [Description], MonthsToRetain, Secured)
			SELECT i.AttachmentTypeID, i.Name, i.[Description], i.MonthsToRetain, i.Secured
				FROM inserted i			
	END
	
	-- The given attachment type is already overriden in the custom table so update that record.
	ELSE
	BEGIN
		-- Update the custom type.
		UPDATE vDMAttachmentTypesCustom
			SET Name = i.Name, [Description] = i.[Description], MonthsToRetain = i.MonthsToRetain, Secured = i.Secured
			FROM vDMAttachmentTypesCustom c 
			JOIN inserted i on c.AttachmentTypeID = i.AttachmentTypeID			
	END										

	
return

	







GO
GRANT SELECT ON  [dbo].[DMAttachmentTypesShared] TO [public]
GRANT INSERT ON  [dbo].[DMAttachmentTypesShared] TO [public]
GRANT DELETE ON  [dbo].[DMAttachmentTypesShared] TO [public]
GRANT UPDATE ON  [dbo].[DMAttachmentTypesShared] TO [public]
GO
