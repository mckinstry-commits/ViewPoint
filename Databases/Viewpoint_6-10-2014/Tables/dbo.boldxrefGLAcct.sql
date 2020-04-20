CREATE TABLE [dbo].[boldxrefGLAcct]
(
[Company] [smallint] NOT NULL,
[oldGLAcct] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[newGLAcct] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
