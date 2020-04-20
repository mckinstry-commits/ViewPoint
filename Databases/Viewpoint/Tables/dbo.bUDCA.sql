CREATE TABLE [dbo].[bUDCA]
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
[ControlType] [char] (1) COLLATE Latin1_General_BIN NULL,
[OptionButtons] [int] NULL,
[StatusText] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Tab] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DDFISeq] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biUDCA] ON [dbo].[bUDCA] ([TableName], [ColumnName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
