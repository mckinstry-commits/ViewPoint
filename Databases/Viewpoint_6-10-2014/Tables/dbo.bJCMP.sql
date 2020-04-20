CREATE TABLE [dbo].[bJCMP]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[ProjectMgr] [int] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Phone] [dbo].[bPhone] NULL,
[FAX] [dbo].[bPhone] NULL,
[MobilePhone] [dbo].[bPhone] NULL,
[Pager] [dbo].[bPhone] NULL,
[Internet] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udEmployee] [dbo].[bEmployee] NULL,
[udPRCo] [dbo].[bCompany] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCMP] ON [dbo].[bJCMP] ([JCCo], [ProjectMgr]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCMP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
