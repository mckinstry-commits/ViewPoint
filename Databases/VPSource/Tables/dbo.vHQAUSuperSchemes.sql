CREATE TABLE [dbo].[vHQAUSuperSchemes]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SchemeID] [smallint] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtHQAUSuperSchemesd] 
   ON  [dbo].[vHQAUSuperSchemes] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	4/20/12		TK-14426
* Modified:		
*
*	Delete trigger for HQ Australia Superannuation Scheme Setup
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vHQAUSuperSchemes', 
	' SchemeID: ' + CAST(d.SchemeID AS VARCHAR(10)),
	NULL, 
	'D', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM DELETED d
	
RETURN



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtHQAUSuperSchemesi] 
	ON [dbo].[vHQAUSuperSchemes] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	4/20/12		TK-14426
* Modified:		
*
*	Insert trigger for HQ Australia Superannuation Scheme Setup
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vHQAUSuperSchemes', 
	' SchemeID: ' + CAST(i.SchemeID AS VARCHAR(10)),
	NULL, 
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i 
  
RETURN



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtHQAUSuperSchemesu] 
   ON  [dbo].[vHQAUSuperSchemes] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	4/20/12		TK-14426
* Modified: 
*
*	Update trigger for HQ Australia Superannuation Scheme Setup
*	HQCo Constraint is handled by Foreign Key
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

IF UPDATE(SchemeID)
BEGIN
	RAISERROR('SchemeID cannot be updated, it is a sequential key value - cannot update HQ Scheme ID! ', 11, -1)
    ROLLBACK TRANSACTION
END

/* add HQ Master Audit entry */
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vHQAUSuperSchemes', 
		' SchemeID: ' + CAST(i.SchemeID AS VARCHAR(10)),
		NULL, 
		'C',
		'Name',
		d.Name,
		i.Name,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
          JOIN deleted d ON i.SchemeID = d.SchemeID
          WHERE ISNULL(i.Name,'') <> ISNULL(d.Name,'')

RETURN


GO
ALTER TABLE [dbo].[vHQAUSuperSchemes] ADD CONSTRAINT [PK_vHQAUSuperSchemes_SchemeID] PRIMARY KEY CLUSTERED  ([SchemeID]) ON [PRIMARY]
GO
