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
CREATE UNIQUE CLUSTERED INDEX [biWDJP] ON [dbo].[bWDJP] ([JobName], [Param]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bWDJP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
