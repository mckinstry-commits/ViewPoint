CREATE TABLE [dbo].[bJCAC]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[AutoReversal] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCAC_AutoReversal] DEFAULT ('N'),
[SelectJobs] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SelectDepts] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocBasis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AmtRateFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocAmount] [dbo].[bDollar] NULL CONSTRAINT [DF_bJCAC_AllocAmount] DEFAULT ((0)),
[AmtColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AllocRate] [dbo].[bRate] NULL CONSTRAINT [DF_bJCAC_AllocRate] DEFAULT ((0)),
[RateColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MthDateFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LastPosted] [smalldatetime] NULL,
[LastMonth] [smalldatetime] NULL,
[LastBeginDate] [smalldatetime] NULL,
[LastEndDate] [smalldatetime] NULL,
[PhaseGroup] [tinyint] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[DebitAcct] [dbo].[bGLAcct] NULL,
[CreditAcct] [dbo].[bGLAcct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PrevPosted] [dbo].[bDate] NULL,
[PrevMonth] [dbo].[bMonth] NULL,
[PrevBeginDate] [dbo].[bDate] NULL,
[PrevEndDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bJCAC] WITH NOCHECK ADD CONSTRAINT [CK_bJCAC_AutoReversal] CHECK (([AutoReversal]='Y' OR [AutoReversal]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCAC] ON [dbo].[bJCAC] ([JCCo], [AllocCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCAC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO