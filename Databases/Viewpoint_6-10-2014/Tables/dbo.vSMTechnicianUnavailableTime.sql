CREATE TABLE [dbo].[vSMTechnicianUnavailableTime]
(
[SMTechnicianUnavailableTimeID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Technician] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[StartDate] [dbo].[bDate] NOT NULL,
[EndDate] [dbo].[bDate] NULL,
[Duration] [dbo].[bHrs] NULL,
[AllDay] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMTechnicianUnavailableTime] ADD CONSTRAINT [PK_vSMTechnicianUnavailableTime] PRIMARY KEY CLUSTERED  ([SMTechnicianUnavailableTimeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMTechnicianUnavailableTime] ADD CONSTRAINT [IX_vSMTechnicianUnavailableTime_SMCo_Technician_Seq] UNIQUE NONCLUSTERED  ([SMCo], [Technician], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMTechnicianUnavailableTime] WITH NOCHECK ADD CONSTRAINT [FK_vSMTechnicianUnavailableTime_vSMTechnician] FOREIGN KEY ([SMCo], [Technician]) REFERENCES [dbo].[vSMTechnician] ([SMCo], [Technician])
GO
ALTER TABLE [dbo].[vSMTechnicianUnavailableTime] NOCHECK CONSTRAINT [FK_vSMTechnicianUnavailableTime_vSMTechnician]
GO
