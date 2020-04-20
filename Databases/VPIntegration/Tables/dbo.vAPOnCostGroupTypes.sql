CREATE TABLE [dbo].[vAPOnCostGroupTypes]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[GroupID] [tinyint] NOT NULL,
[OnCostID] [tinyint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPOnCostGroupTypesd] 
	ON [dbo].[vAPOnCostGroupTypes] 
	FOR DELETE AS
/*-----------------------------------------------------------------
* Created:		MV	02/07/12	TK-12400
* Modified:		
*
*	Insert trigger for APOnCostGroupTypes
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName,
KeyString,
Co,
RecType,
FieldName,
OldValue,
NewValue,
DateTime,
UserName)
SELECT 
	'vAPOnCostGroupTypes', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
			 + ',  GroupID: ' + CAST(i.GroupID AS VARCHAR(10))
 			 + ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)),
	i.APCo, 
	'D', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME()
FROM deleted i 
  
RETURN




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPOnCostGroupTypesi] 
	ON [dbo].[vAPOnCostGroupTypes] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	02/07/12	TK-12400
* Modified:		
*
*	Insert trigger for APOnCostGroupTypes
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName,
KeyString,
Co,
RecType,
FieldName,
OldValue,
NewValue,
DateTime,
UserName)
SELECT 
	'vAPOnCostGroupTypes', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
			 + ',  GroupID: ' + CAST(i.GroupID AS VARCHAR(10))
 			 + ',  OnCostID: ' + CAST(i.OnCostID AS VARCHAR(10)),
	i.APCo, 
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME()
FROM inserted i 
  
RETURN




GO
ALTER TABLE [dbo].[vAPOnCostGroupTypes] ADD CONSTRAINT [PK_vAPOnCostGroupTypes] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
