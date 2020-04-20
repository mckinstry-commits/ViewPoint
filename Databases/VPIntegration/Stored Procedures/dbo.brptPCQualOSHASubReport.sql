SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mike Brewer
-- Create date: 4/27/09
-- Description:	PCQualificationReport, OHSA subreport
--Null values are used if enduser chooses Blank Form
-- =============================================
CREATE PROCEDURE [dbo].[brptPCQualOSHASubReport]
--	@Type  varchar(12) --Report or Blank Form
 @Vendor bVendor, @VendorGroup bGroup
AS
BEGIN

		Select 
		'R' as 'CRType',
		Null as 'Line',
		NULL as 'GLCo',
		VendorGroup as 'VendorGroup',
		Vendor as 'Vendor',
		[Year] as 'Year',
		TotalStaffHours as 'TotalStaffHours',
		TotalTradeHours as 'TotalTradeHours',
		LostDaysCases  as 'LostDaysCases',
		LostDaysRate  as 'LostDaysRate',
		InjuryRate as 'InjuryRate',
		Fatalities as 'Fatalities',
		RMT  as 'RMT',
		VehicleAccidents as 'VehicleAccidents',
		VehicleAccidentCost as 'VehicleAccidentCost',
		TotalLiabilityLoss as 'TotalLiabilityLoss',
		OSHAViolations  as 'OSHAViolations',
		WillfullViolations  as 'WillfullViolations',
		UniqueAttchID as 'UniqueAttchID', 
		KeyID  as 'KeyID'
		from PCOSHA
		where Vendor = @Vendor
		and VendorGroup = @VendorGroup
Union all
		select 
		'B' as 'CRType', '1' as 'Line', NULL as 'GLCo',
		Null as 'VendorGroup',Null as 'Vendor', Null as 'Year',
		Null as 'TotalStaffHours', Null as 'TotalTradeHours',Null as 'LostDaysCases',
		Null as 'LostDaysRate',Null as 'InjuryRate',Null as 'Fatalities',Null as 'RMT',
		Null as 'VehicleAccidents',Null as 'VehicleAccidentCost',Null as 'TotalLiabilityLoss',
		Null as 'OSHAViolations',Null as 'WillfullViolations',Null as 'UniqueAttchID',Null as 'KeyID'

		Union All

		select 
		'B' as 'CRType', '2' as 'Line', NULL as 'GLCo',
		Null as 'VendorGroup',Null as 'Vendor',Null as '[Year]',
		Null as 'TotalStaffHours',Null as 'TotalTradeHours',Null as 'LostDaysCases',
		Null as 'LostDaysRate',Null as 'InjuryRate',Null as 'Fatalities',Null as 'RMT',
		Null as 'VehicleAccidents',Null as 'VehicleAccidentCost',Null as 'TotalLiabilityLoss',
		Null as 'OSHAViolations',Null as 'WillfullViolations',Null as 'UniqueAttchID',Null as 'KeyID'
		Union All

		select 
		'B' as 'CRType', '3' as 'Line', NULL as 'GLCo',
		Null as 'VendorGroup',Null as 'Vendor',Null as '[Year]',
		Null as 'TotalStaffHours',Null as 'TotalTradeHours',Null as 'LostDaysCases',
		Null as 'LostDaysRate',Null as 'InjuryRate',Null as 'Fatalities',Null as 'RMT',
		Null as 'VehicleAccidents',Null as 'VehicleAccidentCost',Null as 'TotalLiabilityLoss',
		Null as 'OSHAViolations',Null as 'WillfullViolations',Null as 'UniqueAttchID',Null as 'KeyID'
		Union All

		select 
		'B' as 'CRType', '4' as 'Line', NULL as 'GLCo',
		Null as 'VendorGroup',Null as 'Vendor',Null as '[Year]',
		Null as 'TotalStaffHours',Null as 'TotalTradeHours',Null as 'LostDaysCases',
		Null as 'LostDaysRate',Null as 'InjuryRate',Null as 'Fatalities',Null as 'RMT',
		Null as 'VehicleAccidents',Null as 'VehicleAccidentCost',Null as 'TotalLiabilityLoss',
		Null as 'OSHAViolations',Null as 'WillfullViolations',Null as 'UniqueAttchID',Null as 'KeyID'
		Union All

		select 
		'B' as 'CRType', '5' as 'Line', NULL as 'GLCo',
		Null as 'VendorGroup',Null as 'Vendor',Null as '[Year]',
		Null as 'TotalStaffHours',Null as 'TotalTradeHours',Null as 'LostDaysCases',
		Null as 'LostDaysRate',Null as 'InjuryRate',Null as 'Fatalities',Null as 'RMT',
		Null as 'VehicleAccidents',Null as 'VehicleAccidentCost',Null as 'TotalLiabilityLoss',
		Null as 'OSHAViolations',Null as 'WillfullViolations',Null as 'UniqueAttchID',Null as 'KeyID'
	END

GO
GRANT EXECUTE ON  [dbo].[brptPCQualOSHASubReport] TO [public]
GO
