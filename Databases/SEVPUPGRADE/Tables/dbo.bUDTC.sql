CREATE TABLE [dbo].[bUDTC]
(
[TableName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[KeySeq] [tinyint] NULL,
[DataType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL,
[InputMask] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[InputLength] [int] NULL,
[Prec] [tinyint] NULL,
[FormSeq] [int] NULL,
[ControlType] [tinyint] NOT NULL,
[OptionButtons] [int] NULL,
[StatusText] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Tab] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DDFISeq] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AutoSeqType] [tinyint] NULL,
[ComboType] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDTC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biUDTC] ON [dbo].[bUDTC] ([TableName], [ColumnName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
