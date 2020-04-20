CREATE TABLE [dbo].[vDateFormat]
(
[DFId] [int] NOT NULL IDENTITY(1, 1),
[DateFormat] [varchar] (500) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDateFormat] ADD CONSTRAINT [PK_vDateFormat] PRIMARY KEY CLUSTERED  ([DFId]) ON [PRIMARY]
GO
