CREATE TABLE [dbo].[bHQDXPREH]
(
[ErrorID] [int] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[TriggerName] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ErrorDate] [dbo].[bDate] NULL,
[ErrorMessage] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bHQDXPREH] ON [dbo].[bHQDXPREH] ([ErrorID]) ON [PRIMARY]
GO
