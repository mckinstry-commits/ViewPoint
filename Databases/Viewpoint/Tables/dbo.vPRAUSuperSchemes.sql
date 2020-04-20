CREATE TABLE [dbo].[vPRAUSuperSchemes]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
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


CREATE TRIGGER [dbo].[vtPRAUSuperSchemesd] 
   ON  [dbo].[vPRAUSuperSchemes] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		LS	1/27/2011	#139033
* Modified:		
*
*	Delete trigger for PR Australia Superannuation Scheme Setup
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUSuperSchemes', 
	'PRCo: ' + CAST(d.PRCo AS VARCHAR(10)) 
			 + ',  SchemeID: ' + CAST(d.SchemeID AS VARCHAR(10)),
	d.PRCo, 
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


CREATE TRIGGER [dbo].[vtPRAUSuperSchemesi] 
	ON [dbo].[vPRAUSuperSchemes] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		LS	1/27/2011	#139033
* Modified:		
*
*	Insert trigger for PR Australia Superannuation Scheme Setup
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vPRAUSuperSchemes', 
	'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
			 + ',  SchemeID: ' + CAST(i.SchemeID AS VARCHAR(10)),
	i.PRCo, 
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

CREATE TRIGGER [dbo].[vtPRAUSuperSchemesu] 
   ON  [dbo].[vPRAUSuperSchemes] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		LS	1/27/2011	#139033
* Modified: 
*
*	Update trigger for PR Australia Superannuation Scheme Setup
*	PRCo Constraint is handled by Foreign Key
*
*	Performs auditing via HQ Master Audit.
*/----------------------------------------------------------------

SET NOCOUNT ON

IF UPDATE(SchemeID)
BEGIN
	RAISERROR('SchemeID cannot be updated, it is a sequential key value - cannot update PR Scheme ID! ', 11, -1)
    ROLLBACK TRANSACTION
END

/* add HQ Master Audit entry */
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vPRAUSuperSchemes', 
		'PRCo: ' + CAST(i.PRCo AS VARCHAR(10)) 
				 + ',  SchemeID: ' + CAST(i.SchemeID AS VARCHAR(10)),
		i.PRCo, 
		'C',
		'Name',
		d.Name,
		i.Name,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
          JOIN deleted d ON i.PRCo = d.PRCo AND i.SchemeID = d.SchemeID
          WHERE ISNULL(i.Name,'') <> ISNULL(d.Name,'')

RETURN


GO
ALTER TABLE [dbo].[vPRAUSuperSchemes] ADD CONSTRAINT [PK_vPRAUSuperSchemes_PRCo_SchemeID] PRIMARY KEY CLUSTERED  ([PRCo], [SchemeID]) ON [PRIMARY]
GO
