CREATE TABLE [dbo].[bJBCE]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ErrorNumber] [tinyint] NOT NULL,
[ErrorDesc] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[ErrorDate] [smalldatetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBCE] ON [dbo].[bJBCE] ([JBCo], [Contract], [ErrorNumber]) ON [PRIMARY]
GO
