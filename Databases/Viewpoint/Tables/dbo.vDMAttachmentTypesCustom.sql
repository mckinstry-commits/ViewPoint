CREATE TABLE [dbo].[vDMAttachmentTypesCustom]
(
[AttachmentTypeID] [int] NOT NULL,
[Name] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[MonthsToRetain] [int] NULL CONSTRAINT [DF_vDMAttachmentTypesCustom_MonthsToRetain] DEFAULT (NULL),
[Secured] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDMAttachmentTypesCustom_Secured] DEFAULT ('Y')
) ON [PRIMARY]
ALTER TABLE [dbo].[vDMAttachmentTypesCustom] ADD 
CONSTRAINT [PK_vDMAttachmentTypesCustom] PRIMARY KEY CLUSTERED  ([AttachmentTypeID]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDMAttachmentTypesCustom] ON [dbo].[vDMAttachmentTypesCustom] ([Name]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDMAttachmentTypesCustomd] on [dbo].[vDMAttachmentTypesCustom] for Delete 
/*-----------------------------------------------------------------
 * Created: AL - 3/2/09 
 *
 * Modified: John Dabritz 12/11/09, 131937 and 135609 
 *           There are now references to attachment types that may be deleted:
 *             1) System wide Per form DefaultAttachmentTypeID (in vDDFHc)
 *             2) Per User Per form DefaultAttachmentTypeID (in vDDFU)
 *             3) Scan batch AttachmentsTypeID (in bVSBH)
 *           NOTE: Attachment Types that are in current use on existing attachments 
 *                 cannot be deleted.
 *           These custom types can be deleted IF they are not used on any attachments yet.
 *           What happens when one of these custom attachment types is deleted?
 *           Desired Behavior: 
 *             1) If there is a corresponding standard Attachment Type, revert to it
 *                NOTE: this action requires no work here because 
 *                vDDFHc.ID = vDDFU.ID and the view built from the join will do the
 *                desired behavior automatically.
 *             2) If there is no corresponding standard Attachment Type, set 
 *                attachment type to null. Here we must go out and update the 
 *                reference to AttachmentTypeID to null in all records with the deleted
 *                AttachmentTypeID in tables vDDFHc, vDDFU, and vVSBH
 *                NOTE: Custom attachment types that do not override a standard
 *                type are those with ids >= 50000 (see vspDMAttachmentTypesDelete)
 *
 */----------------------------------------------------------------
as

 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDMAttachmentTypesCustom', 'D', 'AttachmentTypeID: ' + rtrim(AttachmentTypeID), null, null,
	null, getdate(), SUSER_SNAME() from deleted
	
	-- John Dabritz, 131937 and 135609
	-- IF deleted.AttachmentTypeID >= 50000, then there is no corresponding standard type
	-- and all references to it must be set to null (in vDDFHc, vDDFU, bVSBH, bHQAT).
	
-- check vDDFHC.DefaultAttachmentTypeID	column
UPDATE vDDFHc
SET vDDFHc.DefaultAttachmentTypeID = null 
FROM vDDFHc 
INNER JOIN deleted ON vDDFHc.DefaultAttachmentTypeID = deleted.AttachmentTypeID
WHERE deleted.AttachmentTypeID >= 50000

-- check vDDFU.DefaultAttachmentTypeID	column
UPDATE vDDFU
SET vDDFU.DefaultAttachmentTypeID = null 
FROM vDDFU 
INNER JOIN deleted ON vDDFU.DefaultAttachmentTypeID = deleted.AttachmentTypeID
WHERE deleted.AttachmentTypeID >= 50000

-- check bVSBH.tAttachmentTypeID	column
UPDATE bVSBH
SET bVSBH.AttachmentTypeID = null 
FROM bVSBH 
INNER JOIN deleted ON bVSBH.AttachmentTypeID = deleted.AttachmentTypeID
WHERE deleted.AttachmentTypeID >= 50000

return
 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create trigger [dbo].[vtDMAttachmentTypesCustomi] on [dbo].[vDMAttachmentTypesCustom] for Insert
/*-----------------------------------------------------------------
 * Created: AL - 3/2/09 
 *
 *	
 *
 */----------------------------------------------------------------
as



 	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDMAttachmentTypesCustom', 'I', 'AttachmentTypeID: ' + rtrim(AttachmentTypeID), null, null,
	null, getdate(), SUSER_SNAME() from inserted
return
 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create trigger [dbo].[vtDMAttachmentTypesCustomu] on [dbo].[vDMAttachmentTypesCustom] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: AL 3/02/09
 *
 *
 */----------------------------------------------------------------
as



if update(Description)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDMAttachmentTypesCustom', 'U', 'AttachmentTypeID: ' + rtrim(i.AttachmentTypeID), 'Description',
		d.Description, i.Description, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.AttachmentTypeID = d.AttachmentTypeID
  	where isnull(i.Description,'') <> isnull(d.Description,'')
  	

return
 

GO
