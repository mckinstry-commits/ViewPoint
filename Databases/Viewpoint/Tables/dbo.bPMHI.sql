CREATE TABLE [dbo].[bPMHI]
(
[KeyId] [bigint] NOT NULL IDENTITY(1, 1),
[SourceTableName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[SourceKeyId] [bigint] NOT NULL,
[CreatedDateTime] [smalldatetime] NOT NULL CONSTRAINT [DF_bPMHI_CreatedDateTime] DEFAULT (getdate()),
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[SentToFirm] [dbo].[bFirm] NULL,
[SentToContact] [dbo].[bEmployee] NULL,
[EMail] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Fax] [dbo].[bPhone] NULL,
[FaxAddress] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[CCAddresses] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[bCCAddresses] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Printed] [dbo].[bYN] NULL CONSTRAINT [DF_bPMHI_Printed] DEFAULT ('N'),
[Emailed] [dbo].[bYN] NULL CONSTRAINT [DF_bPMHI_Emailed] DEFAULT ('N'),
[Faxed] [dbo].[bYN] NULL CONSTRAINT [DF_bPMHI_Faxed] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMHI] ADD 
CONSTRAINT [PK_bPMHI] PRIMARY KEY CLUSTERED  ([KeyId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
