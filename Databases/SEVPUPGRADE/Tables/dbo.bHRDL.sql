CREATE TABLE [dbo].[bHRDL]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[LicCodeType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[LicCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [biHRDL] ON [dbo].[bHRDL] ([HRCo], [HRRef], [State], [LicCodeType], [LicCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
