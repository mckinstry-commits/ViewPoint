SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCOSHAInsert]
	(@VendorGroup bGroup, @Vendor bVendor, @Year SMALLINT, @TotalStaffHours INT, @TotalTradeHours INT, @LostDaysCases INT, @LostDaysRate bRate, @InjuryRate bRate, @Fatalities SMALLINT, @RMT bRate, @VehicleAccidents INT, @VehicleAccidentCost bDollar, @TotalLiabilityLoss bDollar, @OSHAViolations INT, @WillfullViolations INT)
AS
SET NOCOUNT ON;

BEGIN
	-- Validation
	DECLARE @rcode INT
	EXEC @rcode = vpspPCValidateYearField @Year
	
	IF @rcode != 0
	BEGIN
		goto vpspExit
	END
	
	-- Validation successful
	INSERT INTO PCOSHA
		(VendorGroup, Vendor, [Year], TotalStaffHours, TotalTradeHours, LostDaysCases, LostDaysRate, InjuryRate, Fatalities, RMT, VehicleAccidents, VehicleAccidentCost, TotalLiabilityLoss, OSHAViolations, WillfullViolations)
	VALUES
		(@VendorGroup, @Vendor, @Year, @TotalStaffHours, @TotalTradeHours, @LostDaysCases, @LostDaysRate, @InjuryRate, @Fatalities, @RMT, @VehicleAccidents, @VehicleAccidentCost, @TotalLiabilityLoss, @OSHAViolations, @WillfullViolations)

vpspExit:
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCOSHAInsert] TO [VCSPortal]
GO
