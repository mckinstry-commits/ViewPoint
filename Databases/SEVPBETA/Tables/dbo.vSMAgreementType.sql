CREATE TABLE [dbo].[vSMAgreementType]
(
[AgreementTypeID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[AgreementType] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementType] ADD CONSTRAINT [PK_vSMAgreementType] PRIMARY KEY CLUSTERED  ([AgreementTypeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementType] ADD CONSTRAINT [IX_vSMAgreementType] UNIQUE NONCLUSTERED  ([SMCo], [AgreementType]) ON [PRIMARY]
GO
