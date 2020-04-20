CREATE TABLE [dbo].[vPRAllowanceRules]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AllowanceRuleName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[AllowanceRulesetName] [varchar] (16) COLLATE Latin1_General_BIN NOT NULL,
[AllowanceRuleDesc] [dbo].[bDesc] NULL,
[DayOfWeekSunday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekSunday] DEFAULT ('N'),
[DayOfWeekMonday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekMonday] DEFAULT ('N'),
[DayOfWeekTuesday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekTuesday] DEFAULT ('N'),
[DayOfWeekWednesday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekWednesday] DEFAULT ('N'),
[DayOfWeekThursday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekThursday] DEFAULT ('N'),
[DayOfWeekFriday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekFriday] DEFAULT ('N'),
[DayOfWeekSaturday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_DayOfWeekSaturday] DEFAULT ('N'),
[Holiday] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPRAllowanceRules_Holiday] DEFAULT ('N'),
[Threshold] [dbo].[bHrs] NOT NULL,
[CalcMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RateAmount] [dbo].[bUnitCost] NOT NULL,
[Factor] [numeric] (3, 2) NULL,
[MaxAmountPeriod] [tinyint] NULL,
[MaxAmount] [dbo].[bDollar] NULL,
[Notes] [dbo].[bNotes] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceRulesd] ON [dbo].[vPRAllowanceRules] FOR DELETE AS

/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		
*
*	This trigger validates deletions to vPRAllowanceRules
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
/************** Record deletion in HQMA *******************/
SET NOCOUNT ON
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRAllowanceRules',	
						'AllowanceRuleName:' + CONVERT(varchar(16),d.AllowanceRuleName),
						d.PRCo,			
						'D', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM	deleted d
RETURN

 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceRulesi] ON [dbo].[vPRAllowanceRules] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		DAN SO 12/10/2012 - B-11859 - check for duplicate Rules
*				DAN SO 12/26/2012 - B-12063 - TK-20377 - IF the RulesetName AND RuleName AND Threshold we all equal, but not hte Company, 
*									it would throw a NOT uniqie error
*
*	This trigger validates insertions to vPRAllowanceRules
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

DECLARE @errmsg VARCHAR(255)

IF @@ROWCOUNT = 0 RETURN

-------------------------------
-- CHECK FOR DUPLICATE RULES --
-------------------------------
-- WEEKLY --
IF EXISTS(
	SELECT i.Threshold
	  FROM vPRAllowanceRuleSet h
	  JOIN inserted i ON h.AllowanceRulesetName = i.AllowanceRulesetName
	  JOIN vPRAllowanceRules d1 ON i.AllowanceRulesetName = d1.AllowanceRulesetName
	 WHERE i.PRCo = d1.PRCo  -- B-12063 - TK-20377 --
	   AND h.ThresholdPeriod = 4
	   AND i.KeyID <> d1.KeyID
	   AND i.Threshold = d1.Threshold)
	BEGIN
		SET @errmsg = 'Weekly record is NOT Unique'
		GOTO Error
	END

-- DAILY --
IF EXISTS(
	SELECT r1.AllowanceRulesetName, r1.KeyID, r2.KeyID
	  FROM vPRAllowanceRules r1
	  JOIN INSERTED r2 ON r1.AllowanceRulesetName = r2.AllowanceRulesetName
	 WHERE r1.PRCo = r2.PRCo  -- B-12063 - TK-20377 --
	   AND r1.Threshold = r2.Threshold
	   AND r1.KeyID <> r2.KeyID
	   AND ((r1.DayOfWeekSunday = 'Y'		AND r2.DayOfWeekSunday = 'Y')
			OR (r1.DayOfWeekMonday = 'Y'	AND r2.DayOfWeekMonday = 'Y')
			OR (r1.DayOfWeekTuesday = 'Y'	AND r2.DayOfWeekTuesday = 'Y')
			OR (r1.DayOfWeekWednesday = 'Y' AND r2.DayOfWeekWednesday = 'Y')
			OR (r1.DayOfWeekThursday = 'Y'	AND r2.DayOfWeekThursday = 'Y')
			OR (r1.DayOfWeekFriday = 'Y'	AND r2.DayOfWeekFriday = 'Y')
			OR (r1.DayOfWeekSaturday = 'Y'	AND r2.DayOfWeekSaturday = 'Y')
			OR (r1.Holiday = 'Y'			AND r2.Holiday = 'Y')))
	BEGIN
		SET @errmsg = 'Daily record is NOT Unique'
		GOTO Error
	END

/************** Record insertions in HQMA *******************/
SET NOCOUNT ON
INSERT INTO dbo.bHQMA  (TableName,		
						KeyString, 
						Co,				
						RecType, 
						FieldName,		
						OldValue, 
						NewValue,		
						DateTime, 
						UserName)
				SELECT  'vPRAllowanceRules',	
						'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName),
						i.PRCo,			
						'A', 
						NULL,			
						NULL, 
						NULL,			
						GETDATE(), 
						SUSER_SNAME()
				FROM	inserted i

	
RETURN
 
Error:
   
	SET @errmsg = @errmsg + ' - cannot insert Rule'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAllowanceRulesu] ON [dbo].[vPRAllowanceRules] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:		KK  11/06/2012 - B-11658
* Modified:		DAN SO 12/03/2012 - B-11891 - add Holiday column - removed ThresholdPeriod column
*				DAN SO 12/10/2012 - B-11859 - check for duplicate Rules
*				DAN SO 12/26/2012 - B-12063 - TK-20377 - IF the RulesetName AND RuleName AND Threshold we all equal, but not hte Company, 
*									it would throw a NOT uniqie error
*
*	This trigger validates updates to vPRAllowanceRules
*
*	Adds HQ Master Audit entry.
*/-----------------------------------------------------------------

IF @@ROWCOUNT = 0 RETURN
DECLARE @errmsg varchar(255)


/************** Record updates in HQMA *******************/
SET NOCOUNT ON

-------------------------------
-- CHECK FOR DUPLICATE RULES --
-------------------------------
-- WEEKLY --
IF EXISTS(
	SELECT i.Threshold
	  FROM vPRAllowanceRuleSet h
	  JOIN inserted i ON h.AllowanceRulesetName = i.AllowanceRulesetName
	  JOIN vPRAllowanceRules d1 ON i.AllowanceRulesetName = d1.AllowanceRulesetName
	 WHERE i.PRCo = d1.PRCo  -- B-12063 - TK-20377 --
	   AND h.ThresholdPeriod = 4
	   AND i.KeyID <> d1.KeyID
	   AND i.Threshold = d1.Threshold)
	BEGIN
		SET @errmsg = 'Weekly record is NOT Unique'
		GOTO Error
	END
			
-- DAILY --
IF EXISTS(
	SELECT r1.AllowanceRulesetName, r1.KeyID, r2.KeyID, r1.PRCo, r2.PRCo
	  FROM vPRAllowanceRules r1
	  JOIN INSERTED r2 ON r1.AllowanceRulesetName = r2.AllowanceRulesetName
	 WHERE r1.PRCo = r2.PRCo  -- B-12063 - TK-20377 --
	   AND r1.Threshold = r2.Threshold
	   AND r1.KeyID <> r2.KeyID
	   AND ((r1.DayOfWeekSunday = 'Y'	AND r2.DayOfWeekSunday = 'Y')
			OR (r1.DayOfWeekMonday = 'Y'	AND r2.DayOfWeekMonday = 'Y')
			OR (r1.DayOfWeekTuesday = 'Y'	AND r2.DayOfWeekTuesday = 'Y')
			OR (r1.DayOfWeekWednesday = 'Y' AND r2.DayOfWeekWednesday = 'Y')
			OR (r1.DayOfWeekThursday = 'Y'	AND r2.DayOfWeekThursday = 'Y')
			OR (r1.DayOfWeekFriday = 'Y'	AND r2.DayOfWeekFriday = 'Y')
			OR (r1.DayOfWeekSaturday = 'Y'	AND r2.DayOfWeekSaturday = 'Y')
			OR (r1.Holiday = 'Y'			AND r2.Holiday = 'Y')))
	BEGIN
		SET @errmsg = 'Daily record is NOT Unique!'
		GOTO Error
	END


/************* Validate fields before updating ************/    
--Company and AllowanceRuleName are Key fields and cannot update
IF UPDATE (PRCo)
BEGIN
	SELECT @errmsg = 'PR Company cannot be updated, it is a key value - cannot update PR Allowance Rule!'
	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
   	RETURN
END

IF UPDATE(AllowanceRuleName)
BEGIN
	SELECT @errmsg = 'AllowanceRuleName cannot be updated, it is a key value - cannot update PR Allowance Rule!'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION
	RETURN
END

--IF EXISTS (SELECT * FROM inserted i JOIN dbo.bPRCO a WITH(NOLOCK) ON a.PRCo = i.PRCo WHERE a.AuditAllowances = 'Y')
IF UPDATE (AllowanceRulesetName)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'AllowanceRulesetDesc',			
				CONVERT(varchar(16),d.AllowanceRulesetName), 
				CONVERT(varchar(16),i.AllowanceRulesetName),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.AllowanceRulesetName <> d.AllowanceRulesetName
END 

IF UPDATE (AllowanceRuleDesc)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'AllowanceRulesetDesc',			
				CONVERT(varchar(30),d.AllowanceRuleDesc), 
				CONVERT(varchar(30),i.AllowanceRuleDesc),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.AllowanceRuleDesc <> d.AllowanceRuleDesc
END

IF UPDATE (DayOfWeekSunday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'AllowanceRulesetDesc',			
				CONVERT(varchar(1),d.DayOfWeekSunday), 
				CONVERT(varchar(1),i.DayOfWeekSunday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekSunday <> d.DayOfWeekSunday
END

IF UPDATE (DayOfWeekMonday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekMonday',			
				CONVERT(varchar(1),d.DayOfWeekMonday), 
				CONVERT(varchar(1),i.DayOfWeekMonday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekMonday <> d.DayOfWeekMonday
END

IF UPDATE (DayOfWeekTuesday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekTuesday',			
				CONVERT(varchar(1),d.DayOfWeekTuesday), 
				CONVERT(varchar(1),i.DayOfWeekTuesday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekTuesday <> d.DayOfWeekTuesday
END

IF UPDATE (DayOfWeekWednesday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekWednesday',			
				CONVERT(varchar(1),d.DayOfWeekWednesday), 
				CONVERT(varchar(1),i.DayOfWeekWednesday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekWednesday <> d.DayOfWeekWednesday
END

IF UPDATE (DayOfWeekThursday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekThursday',			
				CONVERT(varchar(1),d.DayOfWeekThursday), 
				CONVERT(varchar(1),i.DayOfWeekThursday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekThursday <> d.DayOfWeekThursday
END

IF UPDATE (DayOfWeekFriday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekFriday',			
				CONVERT(varchar(1),d.DayOfWeekFriday), 
				CONVERT(varchar(1),i.DayOfWeekFriday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekFriday <> d.DayOfWeekFriday
END

IF UPDATE (DayOfWeekSaturday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'DayOfWeekSaturday',			
				CONVERT(varchar(1),d.DayOfWeekSaturday), 
				CONVERT(varchar(1),i.DayOfWeekSaturday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.DayOfWeekSaturday <> d.DayOfWeekSaturday
END

IF UPDATE (Holiday)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'ThresholdPeriod',			
				CONVERT(varchar(1),d.Holiday), 
				CONVERT(varchar(1),i.Holiday),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.Holiday <> d.Holiday
END

IF UPDATE (Threshold)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'Threshold',			
				CONVERT(varchar(12),d.Threshold), 
				CONVERT(varchar(12),i.Threshold),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.Threshold <> d.Threshold
END

IF UPDATE (CalcMethod)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'CalcMethod',			
				CONVERT(varchar(1),d.CalcMethod), 
				CONVERT(varchar(1),i.CalcMethod),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.CalcMethod <> d.CalcMethod
END

IF UPDATE (RateAmount)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'RateAmount',			
				CONVERT(varchar(18),d.RateAmount), 
				CONVERT(varchar(18),i.RateAmount),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.RateAmount <> d.RateAmount
END

IF UPDATE (Factor)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'Factor',			
				CONVERT(varchar(5),d.Factor), 
				CONVERT(varchar(5),i.Factor),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.Factor <> d.Factor
END

IF UPDATE (MaxAmountPeriod)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'MaxAmountPeriod',			
				CONVERT(varchar(1),d.MaxAmountPeriod), 
				CONVERT(varchar(1),i.MaxAmountPeriod),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.MaxAmountPeriod <> d.MaxAmountPeriod
END

IF UPDATE (MaxAmount)
BEGIN
	INSERT INTO dbo.bHQMA
		SELECT  'vPRAllowanceRules',	
				'AllowanceRuleName:' + CONVERT(varchar(16),i.AllowanceRuleName) + ' PRCo:' + CONVERT(varchar(5),i.PRCo),
				i.PRCo, 
				'C', 
				'MaxAmount',			
				CONVERT(varchar(14),d.MaxAmount), 
				CONVERT(varchar(14),i.MaxAmount),			
				GETDATE(), 
				SUSER_SNAME()
		 FROM inserted i
		 JOIN deleted d 
		   ON i.AllowanceRuleName = d.AllowanceRuleName 
			  AND i.PRCo = d.PRCo 
		WHERE i.MaxAmount <> d.MaxAmount
END


RETURN

 Error:
   
	SET @errmsg = @errmsg + ' - cannot update Rule'
	RAISERROR(@errmsg, 11, -1);
	ROLLBACK TRANSACTION



GO
ALTER TABLE [dbo].[vPRAllowanceRules] ADD CONSTRAINT [PK_vPRAllowanceRules] PRIMARY KEY CLUSTERED  ([PRCo], [AllowanceRuleName], [AllowanceRulesetName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPRAllowanceRules_AllowanceRulesetName] ON [dbo].[vPRAllowanceRules] ([AllowanceRulesetName]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPRAllowanceRules_KeyID] ON [dbo].[vPRAllowanceRules] ([KeyID]) ON [PRIMARY]
GO
