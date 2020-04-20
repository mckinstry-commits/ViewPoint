CREATE TABLE [dbo].[boldxrefGLJournals]
(
[CMSCode] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[GLJrnl] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Source] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
