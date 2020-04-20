CREATE TABLE [dbo].[budxrefGLAcctTypes]
(
[Company] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[oldAcctType] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[newAcctType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ixrefGLAcctType] ON [dbo].[budxrefGLAcctTypes] ([Company], [oldAcctType], [newAcctType]) ON [PRIMARY]
GO
