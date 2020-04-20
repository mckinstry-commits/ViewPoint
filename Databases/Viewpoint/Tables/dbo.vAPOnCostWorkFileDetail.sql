CREATE TABLE [dbo].[vAPOnCostWorkFileDetail]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[APTrans] [dbo].[bTrans] NOT NULL,
[APLine] [smallint] NOT NULL,
[UserID] [dbo].[bVPUserName] NOT NULL,
[Amount] [dbo].[bDollar] NULL,
[OnCostAction] [tinyint] NULL,
[Error] [dbo].[bItemDesc] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vAPOnCostWorkFileDetail_ALL] ON [dbo].[vAPOnCostWorkFileDetail] ([APCo], [Mth], [APTrans], [APLine]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtAPOnCostWorkFileDetaild] 
	ON [dbo].[vAPOnCostWorkFileDetail] 
	FOR DELETE AS
/*-----------------------------------------------------------------
* Created:		CHS	03/01/2012		B-08291
* Modified:
*
*	Insert trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(d.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(d.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(d.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(d.APLine AS VARCHAR(10))
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

CREATE TRIGGER [dbo].[vtAPOnCostWorkFileDetaili] 
	ON [dbo].[vAPOnCostWorkFileDetail] 
	FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		CHS	03/01/2012		B-08291
* Modified:
*
*	Insert trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

DECLARE @errmsg varchar(255)

SET NOCOUNT ON

/* validate existence of a header record */
IF NOT EXISTS(SELECT TOP 1 1 FROM inserted i JOIN dbo.vAPOnCostWorkFileHeader h (NOLOCK) ON h.APCo = i.APCo and h.Mth = i.Mth and h.APTrans = i.APTrans and h.UserID = i.UserID)
	BEGIN
	SELECT @errmsg = 'Missing header record'
	GOTO error
	END

/* add HQ Master Audit entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(i.APLine AS VARCHAR(10))
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

error:
   	SELECT @errmsg = @errmsg + ' - cannot insert AP On-Cost Line!'
   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtAPOnCostWorkFileDetailu] 
	ON [dbo].[vAPOnCostWorkFileDetail] 
	FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		CHS	03/01/2012		B-08291
* Modified:		
*
*	Update trigger for PR Australian PAYG Employees
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON


/* add UserID entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(i.APLine AS VARCHAR(10))
		, 			
	i.APCo,
	'C', 
	'UserID', 
	d.UserID, 
	i.UserID, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.Mth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine
WHERE ISNULL(i.UserID,'') <> ISNULL(d.UserID,'') 	


/* add Amount entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(i.APLine AS VARCHAR(10))
		, 			
	i.APCo,
	'C', 
	'Amount', 
	d.Amount, 
	i.Amount, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.Mth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine
WHERE ISNULL(i.Amount,0.00) <> ISNULL(d.Amount,0.00) 	


/* add OnCostAction entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(i.APLine AS VARCHAR(10))
		, 			
	i.APCo,
	'C', 
	'OnCostAction', 
	d.OnCostAction, 
	i.OnCostAction, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.Mth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine
WHERE ISNULL(i.OnCostAction,'') <> ISNULL(d.OnCostAction,'') 	


/* add Error entry */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
SELECT 
	'vAPOnCostWorkFileDetail', 
	'APCo: ' + CAST(i.APCo AS VARCHAR(10)) 
		+ ',  Mth: ' + CAST(i.Mth AS VARCHAR(20))	
		+ ',  APTrans: ' + ISNULL(CAST(i.APTrans AS VARCHAR(10)), '')
		+ ',  APLine: ' + CAST(i.APLine AS VARCHAR(10))
		, 			
	i.APCo,
	'C', 
	'Error', 
	d.Error, 
	i.Error, 
	GETDATE(), 
	SUSER_SNAME() 
FROM inserted i
	JOIN deleted d ON i.APCo = d.APCo AND i.Mth = d.Mth AND i.APTrans = d.APTrans AND i.APLine = d.APLine
WHERE ISNULL(i.Error,'') <> ISNULL(d.Error,'') 	

RETURN

GO
ALTER TABLE [dbo].[vAPOnCostWorkFileDetail] ADD CONSTRAINT [PK_vAPOncostWorkFileDetail] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
