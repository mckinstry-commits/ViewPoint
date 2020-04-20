CREATE TABLE [dbo].[bHRGI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[BenefitGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BenefitCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ElectiveYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRGI] ON [dbo].[bHRGI] ([HRCo], [BenefitGroup], [BenefitCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRGI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRGI].[ElectiveYN]'
GO
