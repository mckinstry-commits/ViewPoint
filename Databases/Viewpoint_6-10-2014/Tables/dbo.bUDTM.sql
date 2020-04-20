CREATE TABLE [dbo].[bUDTM]
(
[TableName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bUDTM] WITH NOCHECK ADD CONSTRAINT [CK_bUDTM_Active] CHECK (([Active]='Y' OR [Active]='N' OR [Active] IS NULL))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDTM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biUDTM] ON [dbo].[bUDTM] ([TableName], [Mod]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
