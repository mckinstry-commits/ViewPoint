CREATE TABLE [dbo].[bJBLC]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[LaborCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBLC] ON [dbo].[bJBLC] ([JBCo], [LaborCategory]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBLC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
