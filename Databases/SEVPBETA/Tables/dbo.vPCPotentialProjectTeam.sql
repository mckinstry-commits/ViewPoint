CREATE TABLE [dbo].[vPCPotentialProjectTeam]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[ContactType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ContactSource] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ContactCode] [dbo].[bEmployee] NULL,
[ContactName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactFirmVendor] [int] NULL,
[ContactFirmName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[Mobile] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WebAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCPotentialProjectTeam] ADD CONSTRAINT [PK_vPCPotentialProjectTeam] PRIMARY KEY CLUSTERED  ([JCCo], [PotentialProject], [Seq]) ON [PRIMARY]
GO
