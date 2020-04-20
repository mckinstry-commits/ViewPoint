CREATE TABLE [dbo].[bHRST]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[StatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UpdateHistYN] [dbo].[bYN] NOT NULL,
[HistoryCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bHRST] WITH NOCHECK ADD CONSTRAINT [CK_bHRST_UpdateHistYN] CHECK (([UpdateHistYN]='Y' OR [UpdateHistYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biHRST] ON [dbo].[bHRST] ([HRCo], [StatusCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRST] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
