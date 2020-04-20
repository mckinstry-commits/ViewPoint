CREATE TABLE [dbo].[vSMBillingSessionFilter]
(
[SMBillingSessionFilterID] [bigint] NOT NULL IDENTITY(1, 1),
[UserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SMCo] [tinyint] NOT NULL,
[DateTimeCreated] [datetime] NOT NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Division] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Customer] [int] NULL,
[BillTo] [int] NULL,
[ServiceSite] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[DateEnteredMin] [smalldatetime] NULL,
[DateEnteredMax] [smalldatetime] NULL,
[DateProvidedMin] [smalldatetime] NULL,
[DateProvidedMax] [smalldatetime] NULL,
[LineType] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMBillingSessionFilter] ADD CONSTRAINT [PK_vSMBillingSessionFilter] PRIMARY KEY CLUSTERED  ([SMBillingSessionFilterID]) ON [PRIMARY]
GO
