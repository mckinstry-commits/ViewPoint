CREATE TABLE [dbo].[bHRRI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[RatingGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRRI] ON [dbo].[bHRRI] ([HRCo], [RatingGroup], [Code]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
