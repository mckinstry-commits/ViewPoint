CREATE TABLE [dbo].[bHRRP]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[ReviewDate] [dbo].[bDate] NOT NULL,
[Seq] [int] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Rating] [int] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRRP] ON [dbo].[bHRRP] ([HRCo], [HRRef], [ReviewDate], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
