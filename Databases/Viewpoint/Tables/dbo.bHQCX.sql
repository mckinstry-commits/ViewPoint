CREATE TABLE [dbo].[bHQCX]
(
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CompCode] [dbo].[bCompCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQCX] ON [dbo].[bHQCX] ([CompGroup], [CompCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQCX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
