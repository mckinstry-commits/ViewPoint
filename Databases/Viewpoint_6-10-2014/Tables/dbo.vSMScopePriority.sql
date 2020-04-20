CREATE TABLE [dbo].[vSMScopePriority]
(
[SMScopePriorityID] [int] NOT NULL IDENTITY(1, 1),
[PriorityName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PriorityRank] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMScopePriority] ADD CONSTRAINT [PK_vSMScopePriority] PRIMARY KEY CLUSTERED  ([SMScopePriorityID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMScopePriority] ADD CONSTRAINT [IX_vSMScopePriority] UNIQUE NONCLUSTERED  ([PriorityName]) ON [PRIMARY]
GO
