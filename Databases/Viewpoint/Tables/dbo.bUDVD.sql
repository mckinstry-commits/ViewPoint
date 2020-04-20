CREATE TABLE [dbo].[bUDVD]
(
[Seq] [int] NOT NULL,
[TypePC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bUDVD_TypePC] DEFAULT ('P'),
[Parameter] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ValProc] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[TableName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[AndOr] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[Operator] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Value] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biUDVD] ON [dbo].[bUDVD] ([Seq], [ValProc], [TableName]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDVD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
