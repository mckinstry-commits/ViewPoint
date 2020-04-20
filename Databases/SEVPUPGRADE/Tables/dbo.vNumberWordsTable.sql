CREATE TABLE [dbo].[vNumberWordsTable]
(
[Number] [int] NOT NULL,
[NumberName] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vNumberWordsTable] ADD CONSTRAINT [PK_vNumberWordsTable] PRIMARY KEY CLUSTERED  ([Number]) ON [PRIMARY]
GO
