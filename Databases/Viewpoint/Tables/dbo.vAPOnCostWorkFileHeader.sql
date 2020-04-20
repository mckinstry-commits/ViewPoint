CREATE TABLE [dbo].[vAPOnCostWorkFileHeader]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[UserID] [dbo].[bVPUserName] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vAPOnCostWorkFileHeader_ALL] ON [dbo].[vAPOnCostWorkFileHeader] ([APCo], [Mth], [APTrans], [UserID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtAPOnCostWorkFileHeaderd] 
	ON [dbo].[vAPOnCostWorkFileHeader] 
	FOR DELETE AS
/*-----------------------------------------------------------------
* Created:		MV	03/01/2012		B-08291
* Modified:
*
*	Insert trigger for AP OnCost WOrkfile Header
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileHeader', 
	'APCo: ' + CAST(d.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(d.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(d.APTrans AS VARCHAR(10)), '')
		+ ',  UserID: ' + ISNULL(d.UserID, '') 
		, 			
	d.APCo,
	'A', 
	NULL, 
	NULL, 
	NULL, 
	GETDATE(), 
	SUSER_SNAME() 
FROM deleted d

  
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtAPOnCostWorkFileHeaderi] 
	ON [dbo].[vAPOnCostWorkFileHeader] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		MV	03/01/2012		B-08291
* Modified:
*
*	Insert trigger for AP OnCost Workfile Header
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

DECLARE @ErrMsg varchar(255)

-- validate record doesn't already exist in another workfile
IF EXISTS
	(
		SELECT * 
		FROM dbo.vAPOnCostWorkFileHeader h
		JOIN Inserted i ON i.APCo=h.APCo AND i.Mth=h.Mth AND i.APTrans=h.APTrans
		WHERE h.UserID <> i.UserID
	)
BEGIN
	SELECT @ErrMsg = 'Record exists in another workfile - cannot insert Transaction Header!'
    RAISERROR(@ErrMsg, 11, -1);
    ROLLBACK TRANSACTION
    RETURN
END


/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileHeader', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  UserID: ' + ISNULL(i.UserID, '') 
		, 			
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
ALTER TABLE [dbo].[vAPOnCostWorkFileHeader] ADD CONSTRAINT [PK_vAPOncostWorkFileHeader] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
