CREATE TABLE [dbo].[bJBBG]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[BillGroup] [dbo].[bBillingGroup] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBBG] ON [dbo].[bJBBG] ([JBCo], [Contract], [BillGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBBG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
