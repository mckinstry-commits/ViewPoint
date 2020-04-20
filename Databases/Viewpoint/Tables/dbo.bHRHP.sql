CREATE TABLE [dbo].[bHRHP]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UpdateOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ErrMsg] [varchar] (60) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRHP] ON [dbo].[bHRHP] ([HRCo], [HRRef], [PRCo], [Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
