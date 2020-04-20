CREATE TABLE [dbo].[bHQRP]
(
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQRP] ON [dbo].[bHQRP] ([Reviewer], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQRP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
