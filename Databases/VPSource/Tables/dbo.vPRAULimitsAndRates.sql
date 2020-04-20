CREATE TABLE [dbo].[vPRAULimitsAndRates]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EffectiveDate] [dbo].[bDate] NOT NULL,
[ETPCap] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_ETPCap] DEFAULT ((0)),
[WholeIncomeCap] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_WholeIncomeCap] DEFAULT ((0)),
[RedundancyTaxFreeBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_RedundancyTaxFreeBasis] DEFAULT ((0)),
[RedundancyTaxFreeYears] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_RedundancyTaxFreeYears] DEFAULT ((0)),
[UnderPreservationAgePct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_UnderPreservationAgePct] DEFAULT ((0)),
[OverPreservationAgePct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_OverPreservationAgePct] DEFAULT ((0)),
[ExcessCapPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_ExcessCapPct] DEFAULT ((0)),
[AnnualLeaveLoadingPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_AnnualLeaveLoadingPct] DEFAULT ((0)),
[LeaveFlatRateLimit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_LeaveFlatRateLimit] DEFAULT ((0)),
[LeaveFlatRatePct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPRAULimitsAndRates_LeaveFlatRatePct] DEFAULT ((0)),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAULimitsAndRatesd] ON [dbo].[vPRAULimitsAndRates] FOR DELETE AS
/*-----------------------------------------------------------------
* Created:	DAN SO 02/22/2013 - TFS-40968
* Modified:	DAN SO 03/13/2013 - TFS-40968 - removed TaxYear - replaced with EffectiveDate
*
*	Delete trigger for PR Australian Limits And Rates table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
	/* add HQ Master Audit entry */
	INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
			FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(d.EffectiveDate), NULL, 'D', 
			NULL, NULL, NULL, GETDATE(), SUSER_SNAME() 
	  FROM deleted d 
	  
RETURN
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAULimitsAndRatesi] ON [dbo].[vPRAULimitsAndRates] FOR INSERT AS
/*-----------------------------------------------------------------
* Created:	DAN SO 02/22/2013 - TFS-40968
* Modified:	DAN SO 03/13/2013 - TFS-40968 - removed TaxYear 
*
*	Insert trigger for PR Australian Limits And Rates table
*
*   Verify TaxYear is in the correct format.
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

SET NOCOUNT ON
 
	DECLARE @errmsg VARCHAR(255)
	   	
	--------------------
	-- ADD HQMA ENTRY --
	--------------------
	INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
			FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'A', 
			NULL, NULL, NULL, GETDATE(), SUSER_SNAME() 
	  FROM INSERTED i


	RETURN
	
	--------------------
	-- ERROR HANDLING --
	--------------------
	Error:
		SET @errmsg = isnull(@errmsg,'') + ' - cannot insert into vPRAULimitsAndRates.'
		RAISERROR(@errmsg, 11, -1);
		ROLLBACK TRANSACTION

  
RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtPRAULimitsAndRatesu] ON [dbo].[vPRAULimitsAndRates] FOR UPDATE AS
/*-----------------------------------------------------------------
* Created:	DAN SO 02/22/2013 - TFS-40968
* Modified:	DAN SO 03/13/2013 - TFS-40968 - removed TaxYear - replaced with EffectiveDate
*			EN 3/26/2013 - Story 39859 / Task 42411 - adjusted HQMA code for column name change and a new column
*
*	Update trigger for PR Australian Limits And Rates table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

	SET NOCOUNT ON
 
	DECLARE @errmsg VARCHAR(255)

	---------------------
	-- CHECK KEY FIELD --
	---------------------
	IF UPDATE (EffectiveDate)
	BEGIN
		SET @errmsg = 'Effective Date is a Key field and cannot be updated - cannot update record!'
		RAISERROR(@errmsg, 11, -1);
		ROLLBACK TRANSACTION
	END

	----------
	-- HQMA --
	----------
	-- ETPCap --
	IF UPDATE (ETPCap)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'ETPCap', 
					CONVERT(varchar(128), d.ETPCap),
					CONVERT(varchar(128), i.ETPCap),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.ETPCap <> d.ETPCap
		END
	
	-- WholeIncomeCap --
	IF UPDATE (WholeIncomeCap)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'WholeIncomeCap', 
					CONVERT(varchar(128), d.WholeIncomeCap),
					CONVERT(varchar(128), i.WholeIncomeCap),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.WholeIncomeCap <> d.WholeIncomeCap
		END	
	
	-- RedundancyTaxFreeBasis --
	IF UPDATE (RedundancyTaxFreeBasis)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'RedundancyTaxFreeBasis', 
					CONVERT(varchar(128), d.RedundancyTaxFreeBasis),
					CONVERT(varchar(128), i.RedundancyTaxFreeBasis),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.RedundancyTaxFreeBasis <> d.RedundancyTaxFreeBasis
		END	
	
	-- RedundancyTaxFreeYears --
	IF UPDATE (RedundancyTaxFreeYears)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'RedundancyTaxFreeYears', 
					CONVERT(varchar(128), d.RedundancyTaxFreeYears),
					CONVERT(varchar(128), i.RedundancyTaxFreeYears),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.RedundancyTaxFreeYears <> d.RedundancyTaxFreeYears
		END	

	-- UnderPreservationAgePct --
	IF UPDATE (UnderPreservationAgePct)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'UnderPreservationAgePct', 
					CONVERT(varchar(128), d.UnderPreservationAgePct),
					CONVERT(varchar(128), i.UnderPreservationAgePct),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.UnderPreservationAgePct <> d.UnderPreservationAgePct
		END	
		
	-- OverPreservationAgePct --
	IF UPDATE (OverPreservationAgePct)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'OverPreservationAgePct', 
					CONVERT(varchar(128), d.OverPreservationAgePct),
					CONVERT(varchar(128), i.OverPreservationAgePct),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.OverPreservationAgePct <> d.OverPreservationAgePct
		END	

	-- ExcessCapPct --
	IF UPDATE (ExcessCapPct)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'ExcessCapPct', 
					CONVERT(varchar(128), d.ExcessCapPct),
					CONVERT(varchar(128), i.ExcessCapPct),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.ExcessCapPct <> d.ExcessCapPct
		END	

	-- LeaveFlatRateLimit --
	IF UPDATE (LeaveFlatRateLimit)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'LeaveFlatRateLimit', 
					CONVERT(varchar(128), d.LeaveFlatRateLimit),
					CONVERT(varchar(128), i.LeaveFlatRateLimit),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.LeaveFlatRateLimit <> d.LeaveFlatRateLimit
		END	

	-- LeaveFlatRatePct --
	IF UPDATE (LeaveFlatRatePct)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'LeaveFlatRatePct', 
					CONVERT(varchar(128), d.LeaveFlatRatePct),
					CONVERT(varchar(128), i.LeaveFlatRatePct),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.LeaveFlatRatePct <> d.LeaveFlatRatePct
		END	
		
	-- AnnualLeaveLoadingPct --
	IF UPDATE (AnnualLeaveLoadingPct)
		BEGIN
		
			INSERT  dbo.bHQMA(TableName, KeyString, Co, RecType, 
					FieldName, 
					OldValue, 
					NewValue, 
					DateTime, UserName)
			SELECT  'vPRAULimitsAndRates', 'Effective Date: ' + dbo.vfToString(i.EffectiveDate), NULL, 'C', 
					'AnnualLeaveLoadingPct', 
					CONVERT(varchar(128), d.AnnualLeaveLoadingPct),
					CONVERT(varchar(128), i.AnnualLeaveLoadingPct),
					GETDATE(), SUSER_SNAME() 
			  FROM	inserted i
			  JOIN	deleted d ON i.EffectiveDate = d.EffectiveDate 
			 WHERE	i.AnnualLeaveLoadingPct <> d.AnnualLeaveLoadingPct
		END	

RETURN
 

GO
ALTER TABLE [dbo].[vPRAULimitsAndRates] ADD CONSTRAINT [PK_vPRAULimitsAndRates] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRAULimitsAndRates] ON [dbo].[vPRAULimitsAndRates] ([EffectiveDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[vPRAULimitsAndRates] TO [public]
GRANT SELECT ON  [dbo].[vPRAULimitsAndRates] TO [public]
GRANT INSERT ON  [dbo].[vPRAULimitsAndRates] TO [public]
GRANT DELETE ON  [dbo].[vPRAULimitsAndRates] TO [public]
GRANT UPDATE ON  [dbo].[vPRAULimitsAndRates] TO [public]
GO
