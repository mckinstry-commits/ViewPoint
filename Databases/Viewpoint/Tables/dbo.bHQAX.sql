CREATE TABLE [dbo].[bHQAX]
(
[ParentColumn] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQAX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
