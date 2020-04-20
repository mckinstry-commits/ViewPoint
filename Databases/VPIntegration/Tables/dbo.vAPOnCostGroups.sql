CREATE TABLE [dbo].[vAPOnCostGroups]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[GroupID] [tinyint] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPOnCostGroupsd] 
   ON  [dbo].[vAPOnCostGroups] 
   FOR DELETE AS 
/*-----------------------------------------------------------------
* Created:		MV	01/05/12 B-07008 - AP OnCost
* Modified:		CHS 02/10/12 TK-12400
*
*	Delete trigger for AP OnCost Groups
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON


/* HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostGroups', 
	'APCo: ' + CAST(d.APCo AS VARCHAR(10)) 
			 + ',  GroupID: ' + CAST(d.GroupID AS VARCHAR(10)),

	d.APCo, 
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


CREATE TRIGGER [dbo].[vtAPOnCostGroupsi] 
	ON [dbo].[vAPOnCostGroups] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	01/05/12 B-07008 - AP OnCost
* Modified:		MV	02/07/12		Drop OnCostID
*
*	Insert trigger for AP OnCost Groups
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
	'vAPOnCostGroups', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
			 + ',  GroupID: ' + CAST(i.GroupID AS VARCHAR(10)),
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
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtAPOnCostGroupsu] 
   ON  [dbo].[vAPOnCostGroups] 
   FOR UPDATE AS 
/*-----------------------------------------------------------------
* Created:		MV	01/05/12 B-07008 - AP OnCost
* Modified:		MV	02/07/12		Drop OnCostID
*
*	update trigger for AP OnCost Groups
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON


/* add HQ Master Audit entry */
INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	SELECT 
		'vAPOnCostGroups', 
		'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
			 + ',  GroupID: ' + CAST(i.GroupID AS VARCHAR(10)),
		i.APCo, 
		'C',
		'Description',
		d.Description,
		i.Description,
		GETDATE(), 
		SUSER_SNAME() 
	FROM inserted i
          JOIN deleted d ON i.APCo = d.APCo AND i.GroupID = d.GroupID
          WHERE ISNULL(i.Description,'') <> ISNULL(d.Description,'')

RETURN


GO
ALTER TABLE [dbo].[vAPOnCostGroups] ADD CONSTRAINT [PK_vAPOnCostGroups] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vAPOnCostGroups_ALL] ON [dbo].[vAPOnCostGroups] ([APCo], [GroupID]) ON [PRIMARY]
GO
