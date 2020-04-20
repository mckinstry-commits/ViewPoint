CREATE TABLE [dbo].[bHQDXARCM]
(
[ErrorID] [int] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[TriggerName] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ErrorDate] [dbo].[bDate] NULL,
[ErrorMessage] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQDXARCM] ON [dbo].[bHQDXARCM] ([ErrorID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
