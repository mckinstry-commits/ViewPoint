SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPCOSHAUpdate]
	(@Original_KeyID BIGINT, @Year SMALLINT, @TotalStaffHours INT, @TotalTradeHours INT, @LostDaysCases INT, @LostDaysRate bRate, @InjuryRate bRate, @Fatalities SMALLINT, @RMT bRate, @VehicleAccidents INT, @VehicleAccidentCost bDollar, @TotalLiabilityLoss bDollar, @OSHAViolations INT, @WillfullViolations INT)
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
	UPDATE PCOSHA
	SET
		[Year] = @Year,
		TotalStaffHours = @TotalStaffHours,
		TotalTradeHours = @TotalTradeHours,
		LostDaysCases = @LostDaysCases,
		LostDaysRate = @LostDaysRate,
		InjuryRate = @InjuryRate,
		Fatalities = @Fatalities,
		RMT = @RMT,
		VehicleAccidents = @VehicleAccidents,
		VehicleAccidentCost = @VehicleAccidentCost,
		TotalLiabilityLoss = @TotalLiabilityLoss,
		OSHAViolations = @OSHAViolations,
		WillfullViolations = @WillfullViolations
	WHERE KeyID = @Original_KeyID
	
vpspExit:
	return @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vpspPCOSHAUpdate] TO [VCSPortal]
GO
