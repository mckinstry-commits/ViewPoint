CREATE TABLE [dbo].[bHQDX]
(
[Co] [dbo].[bCompany] NOT NULL,
[Package] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[TriggerName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Enable] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQDX_Enable] DEFAULT ('N'),
[StdXMLFormat] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQDX_StdXMLFormat] DEFAULT ('N'),
[UserStoredProc] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ExportDirectory] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bHQDX] WITH NOCHECK ADD CONSTRAINT [CK_bHQDX_Enable] CHECK (([Enable]='Y' OR [Enable]='N'))
GO
ALTER TABLE [dbo].[bHQDX] WITH NOCHECK ADD CONSTRAINT [CK_bHQDX_StdXMLFormat] CHECK (([StdXMLFormat]='Y' OR [StdXMLFormat]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biHQDX] ON [dbo].[bHQDX] ([Co], [Package], [TriggerName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQDX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
