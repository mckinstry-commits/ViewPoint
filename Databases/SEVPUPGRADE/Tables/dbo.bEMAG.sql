CREATE TABLE [dbo].[bEMAG]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAG] ON [dbo].[bEMAG] ([EMCo], [AllocCode], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
