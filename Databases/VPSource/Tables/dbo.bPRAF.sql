CREATE TABLE [dbo].[bPRAF]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Frequency] [dbo].[bFreq] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRAF] ON [dbo].[bPRAF] ([PRCo], [PRGroup], [PREndDate], [Frequency]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRAF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]





GO