CREATE TABLE [dbo].[bPMVC]
(
[ViewName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ViewGrid] [smallint] NULL,
[TableView] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ColTitle] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ColSeq] [int] NOT NULL CONSTRAINT [DF_bPMVC_ColSeq] DEFAULT ((0)),
[Visible] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMVC_Visible] DEFAULT ('Y'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[GridCol] [smallint] NOT NULL CONSTRAINT [DF_bPMVC_GridCol] DEFAULT ((0)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMVC] ADD 
CONSTRAINT [PK_bPMVC] PRIMARY KEY CLUSTERED  ([ViewName], [Form], [ColSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMVC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMVC] WITH NOCHECK ADD
CONSTRAINT [FK_bPMVC_bPMVG] FOREIGN KEY ([ViewName], [Form]) REFERENCES [dbo].[bPMVG] ([ViewName], [Form])
GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMVC].[Visible]'
GO
