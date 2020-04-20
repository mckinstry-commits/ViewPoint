CREATE TABLE [dbo].[vDDAL]
(
[DateTime] [datetime] NOT NULL,
[HostName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UserName] [dbo].[bVPUserName] NULL,
[ErrorNumber] [int] NULL,
[Description] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[SQLRetCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UnhandledError] [bit] NOT NULL,
[Informational] [bit] NOT NULL,
[Assembly] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[Class] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[Procedure] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[AssemblyVersion] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[StackTrace] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[FriendlyMessage] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[LineNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Event] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Company] [tinyint] NULL,
[Object] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[CrystalErrorID] [int] NULL,
[ErrorProcedure] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_vDDAL] ON [dbo].[vDDAL] ([DateTime]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
