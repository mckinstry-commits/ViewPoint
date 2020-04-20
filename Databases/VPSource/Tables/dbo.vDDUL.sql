CREATE TABLE [dbo].[vDDUL]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FormPosition] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GridRowHeight] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDUL] ON [dbo].[vDDUL] ([VPUserName], [Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
