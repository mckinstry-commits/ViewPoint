CREATE TABLE [dbo].[bPRGI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[GarnGroup] [dbo].[bGroup] NOT NULL,
[EDType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRGI] ON [dbo].[bPRGI] ([PRCo], [GarnGroup], [EDType], [EDCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
