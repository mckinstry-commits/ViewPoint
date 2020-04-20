CREATE TABLE [dbo].[vPMPCOApprove]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[ApprovalID] [smallint] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[PCOType] [dbo].[bPCOType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[ACO] [dbo].[bACO] NULL,
[ACODesc] [dbo].[bItemDesc] NULL,
[ApprovalDate] [dbo].[bDate] NULL,
[CompletionDate] [dbo].[bDate] NULL,
[AdditionalDays] [int] NULL,
[ReportSeqNum] [int] NULL,
[Username] [dbo].[bVPUserName] NULL,
[Contract] [dbo].[bContract] NULL,
[COR] [smallint] NULL,
[CCOOption] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CCONew] [smallint] NULL,
[CCONewDesc] [dbo].[bItemDesc] NULL,
[CCO] [smallint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMPCOApprove] ADD CONSTRAINT [PK_vPMPCOApprove] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMPCOApprove_PCO] ON [dbo].[vPMPCOApprove] ([PMCo], [ApprovalID], [Project], [PCOType], [PCO]) ON [PRIMARY]
GO
