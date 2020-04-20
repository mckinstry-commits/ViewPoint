CREATE TABLE [dbo].[vPMIssueHistory]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[IssueKeyID] [bigint] NOT NULL,
[RelatedTableName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[RelatedKeyID] [bigint] NOT NULL,
[Co] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Issue] [int] NOT NULL,
[ActionDate] [smalldatetime] NOT NULL CONSTRAINT [DF_vPMIssueHistory_ActionDate] DEFAULT (getdate()),
[Login] [dbo].[bVPUserName] NOT NULL CONSTRAINT [DF_vPMIssueHistory_Login] DEFAULT (suser_sname()),
[ActionType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[RelatedDeleteAction] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMIssueHistory] WITH NOCHECK ADD CONSTRAINT [CK_vPMIssueHistory_ActionType] CHECK (([ActionType]='D' OR [ActionType]='C' OR [ActionType]='A'))
GO
ALTER TABLE [dbo].[vPMIssueHistory] ADD CONSTRAINT [PK_vPMIssueHistory] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMIssueHistory] WITH NOCHECK ADD CONSTRAINT [FK_vPMIssueHistory_bPMIM_IssueKeyID] FOREIGN KEY ([IssueKeyID]) REFERENCES [dbo].[bPMIM] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMIssueHistory] NOCHECK CONSTRAINT [FK_vPMIssueHistory_bPMIM_IssueKeyID]
GO
