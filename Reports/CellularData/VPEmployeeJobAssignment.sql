USE [CellularBill]
GO

/****** Object:  Table [dbo].[EmployeeJobAssignment]    Script Date: 12/17/2014 4:52:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[VPEmployeeJobAssignment](
	[EmployeeId] [int] NOT NULL,
	[JobNumber] [varchar](50) NOT NULL,
	[JobName] [varchar](50) NULL,
	[PRDepartmentNumber] [char](20) NOT NULL,
	[PRDepartmentName] [varchar](50) NULL,
	[GLDepartmentNumber] [char](20) NULL,
	[GLDepartmentName] [varchar](50) NULL,
	[JobHours] [decimal](9, 2) NOT NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[EffectiveYear]  AS (datepart(year,[EffectiveDate])),
	[EffectiveMonth]  AS (datepart(month,[EffectiveDate]))
 CONSTRAINT [PK_EmployeeJobAssignmentVP] PRIMARY KEY CLUSTERED 
(
	[EmployeeId] ASC,
	[JobNumber] ASC,
	[PRDepartmentNumber] ASC,
	[EffectiveDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO