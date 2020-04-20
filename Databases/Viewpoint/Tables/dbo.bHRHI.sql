CREATE TABLE [dbo].[bHRHI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Hospital] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [dbo].[bDesc] NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Phone] [dbo].[bPhone] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRHI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
CREATE UNIQUE CLUSTERED INDEX [biHRHI] ON [dbo].[bHRHI] ([HRCo], [Hospital]) ON [PRIMARY]
GO
