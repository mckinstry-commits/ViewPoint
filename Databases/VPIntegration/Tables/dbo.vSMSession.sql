CREATE TABLE [dbo].[vSMSession]
(
[SMSessionID] [int] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[UserName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[Prebilling] [bit] NOT NULL CONSTRAINT [DF_vSMSession_Prebilling] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMSession] ADD CONSTRAINT [PK_vSMSession] PRIMARY KEY CLUSTERED  ([SMSessionID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMSession] ADD CONSTRAINT [IX_vSMSession_SMSessionID_SMCo] UNIQUE NONCLUSTERED  ([SMSessionID], [SMCo]) ON [PRIMARY]
GO
