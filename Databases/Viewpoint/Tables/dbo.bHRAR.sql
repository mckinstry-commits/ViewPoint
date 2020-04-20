CREATE TABLE [dbo].[bHRAR]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [int] NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Phone] [dbo].[bPhone] NULL,
[RefNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRAR] ON [dbo].[bHRAR] ([HRCo], [HRRef], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
