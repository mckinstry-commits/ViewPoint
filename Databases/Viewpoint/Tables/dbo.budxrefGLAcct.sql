CREATE TABLE [dbo].[budxrefGLAcct]
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
CREATE UNIQUE CLUSTERED INDEX [ixrefGLAcct] ON [dbo].[budxrefGLAcct] ([Company], [oldGLAcct], [newGLAcct]) ON [PRIMARY]
GO
