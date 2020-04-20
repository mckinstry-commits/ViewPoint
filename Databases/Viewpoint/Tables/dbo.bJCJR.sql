CREATE TABLE [dbo].[bJCJR]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Seq] [int] NOT NULL CONSTRAINT [DF_bJCJR_Seq] DEFAULT ((1)),
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[Memo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ReviewerType] [smallint] NOT NULL CONSTRAINT [DF_bJCJR_ReviewerType] DEFAULT ((1)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJCJR] ON [dbo].[bJCJR] ([JCCo], [Job], [Reviewer], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCJR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
