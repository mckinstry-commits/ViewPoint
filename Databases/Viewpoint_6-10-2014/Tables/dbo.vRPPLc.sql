CREATE TABLE [dbo].[vRPPLc]
(
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[LoadSeq] [tinyint] NULL,
[Active] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vRPPLc] WITH NOCHECK ADD CONSTRAINT [CK_vRPPLc_Active] CHECK (([Active]='Y' OR [Active]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [viRPPLc] ON [dbo].[vRPPLc] ([ReportID], [ParameterName], [Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
