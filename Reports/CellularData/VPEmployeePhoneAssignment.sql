USE [CellularBill]
GO

/****** Object:  Table [dbo].[EmployeePhoneAssignment]    Script Date: 12/18/2014 4:30:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[VPEmployeePhoneAssignment](
	[EmpId] [int] NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NULL,
	--[PRDepartmentNumber] char(20) NULL,
	[GLDepartmentNumber] char(20) NULL,
	[PhoneType] [varchar](20) NOT NULL,
	[PhoneNumber] [varchar](20) NULL,
	[PTT] [varchar](20) NULL,
	[EffectiveDate] [datetime] NOT NULL,
	[EffectiveYear]  AS (datepart(year,[EffectiveDate])),
	[EffectiveMonth]  AS (datepart(month,[EffectiveDate]))
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO