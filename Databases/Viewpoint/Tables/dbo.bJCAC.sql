CREATE TABLE [dbo].[bJCAC]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[AutoReversal] [dbo].[bYN] NOT NULL,
[SelectJobs] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[SelectDepts] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocBasis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AmtRateFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AllocAmount] [dbo].[bDollar] NULL,
[AmtColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AllocRate] [dbo].[bRate] NULL,
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
CREATE UNIQUE CLUSTERED INDEX [biJCAC] ON [dbo].[bJCAC] ([JCCo], [AllocCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCAC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCAC].[AutoReversal]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bJCAC].[AutoReversal]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCAC].[AllocAmount]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCAC].[AllocRate]'
GO
