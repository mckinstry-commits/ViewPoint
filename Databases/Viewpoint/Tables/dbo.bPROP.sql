CREATE TABLE [dbo].[bPROP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[OccupCat] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ReportSeq] [smallint] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPROP] ON [dbo].[bPROP] ([PRCo], [OccupCat]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPROP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
