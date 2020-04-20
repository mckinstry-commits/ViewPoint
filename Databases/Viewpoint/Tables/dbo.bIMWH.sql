CREATE TABLE [dbo].[bIMWH]
(
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TextFile] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[ImportBy] [dbo].[bVPUserName] NULL,
[NumOfRecords] [int] NULL,
[ImportDate] [smalldatetime] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biIMWH] ON [dbo].[bIMWH] ([ImportId], [ImportTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bIMWH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
