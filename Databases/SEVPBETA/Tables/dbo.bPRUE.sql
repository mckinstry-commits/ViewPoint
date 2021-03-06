CREATE TABLE [dbo].[bPRUE]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[Quarter] [dbo].[bMonth] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[SSN] [char] (9) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MidName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[GrossWages] [dbo].[bDollar] NOT NULL,
[SUIWages] [dbo].[bDollar] NOT NULL,
[ExcessWages] [dbo].[bDollar] NOT NULL,
[EligWages] [dbo].[bDollar] NOT NULL,
[DisWages] [dbo].[bDollar] NOT NULL,
[TipWages] [dbo].[bDollar] NOT NULL,
[WksWorked] [tinyint] NOT NULL,
[HrsWorked] [smallint] NOT NULL,
[StateTax] [dbo].[bDollar] NOT NULL,
[Seasonal] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[HealthCode1] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[HealthCode2] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[ProbCode] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Officer] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[WagePlan] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Mth1] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Mth2] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Mth3] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EmplDate] [dbo].[bDate] NULL,
[SepDate] [dbo].[bDate] NULL,
[SUIWageType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRUE_SUIWageType] DEFAULT ('W'),
[AnnualGrossWage] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_AnnualGrossWage] DEFAULT ((0)),
[AnnualStateTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_AnnualStateTax] DEFAULT ((0)),
[ReportUnit] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Industry] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[OfficerCode] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Coverage] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Loc1Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_Loc1Amt] DEFAULT ((0)),
[Loc2Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_Loc2Amt] DEFAULT ((0)),
[Loc3Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_Loc3Amt] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[Suffix] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[DLCode1Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_DLCode1Amt] DEFAULT ((0)),
[DLCode2Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_DLCode2Amt] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[NAICS] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[StateTaxableWages] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRUE_StateTaxableWages] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRUE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
