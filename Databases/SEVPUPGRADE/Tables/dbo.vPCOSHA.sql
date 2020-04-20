CREATE TABLE [dbo].[vPCOSHA]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Year] [smallint] NOT NULL,
[TotalStaffHours] [int] NULL,
[TotalTradeHours] [int] NULL,
[LostDaysCases] [int] NULL,
[LostDaysRate] [dbo].[bRate] NULL,
[InjuryRate] [dbo].[bRate] NULL,
[Fatalities] [smallint] NULL,
[RMT] [dbo].[bRate] NULL,
[VehicleAccidents] [int] NULL,
[VehicleAccidentCost] [dbo].[bDollar] NULL,
[TotalLiabilityLoss] [dbo].[bDollar] NULL,
[OSHAViolations] [int] NULL,
[WillfullViolations] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCOSHA] ADD CONSTRAINT [PK_vPCOSHA] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Year]) ON [PRIMARY]
GO
