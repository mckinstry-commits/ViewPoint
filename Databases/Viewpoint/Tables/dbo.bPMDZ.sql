CREATE TABLE [dbo].[bPMDZ]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[DocCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[VendorGroup] [nchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[SentToFirm] [dbo].[bFirm] NULL,
[SentToContact] [dbo].[bEmployee] NULL,
[DocType] [dbo].[bDocType] NULL,
[Document] [dbo].[bDocument] NULL,
[Rev] [tinyint] NULL,
[PCO] [dbo].[bPCO] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[EMail] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Fax] [dbo].[bPhone] NULL,
[FaxAddress] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[PrefMethod] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[FullFileName] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[CCAddresses] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CCList] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[HeaderString] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QueryString] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ItemQueryString] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[bCCAddresses] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PMHIKeyId] [bigint] NULL,
[AttachDocument] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDZ_AttachDocument] DEFAULT ('Y'),
[OvrDocFileName] [varchar] (250) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMDZ] ADD 
CONSTRAINT [PK_bPMDZ] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [DocCategory], [UserName], [VendorGroup], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDZ] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
