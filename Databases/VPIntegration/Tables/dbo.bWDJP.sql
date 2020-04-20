CREATE TABLE [dbo].[bWDJP]
(
[JobName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[Param] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[InputValue] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biWDJP] ON [dbo].[bWDJP] ([JobName], [Param]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bWDJP] ([KeyID]) ON [PRIMARY]
GO
