SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		David Solheim
-- Create date: 5/15/13
-- Description:	Validation for SM WO Quote Required Labor Rate
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWOQuoteReqLaborRateVal]
	@SMCo AS bCompany, 
	@PRCo AS bCompany = NULL,
	@Technician AS varchar(15), 
	@Craft bCraft,
	@Class bClass,
	@CostRate AS bUnitCost OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF (@SMCo IS NULL)
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	SET @CostRate = 
	(
		SELECT tbl.CostRate FROM 
		(
			SELECT TOP 1 * FROM
			(
				SELECT 1 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician = @Technician AND Craft = @Craft AND Class = @Class

				UNION ALL

				SELECT 2 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician = @Technician AND Craft = @Craft AND Class IS NULL

				UNION ALL

				SELECT 3 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician = @Technician AND Craft IS NULL AND Class IS NULL

				UNION ALL

				SELECT 4 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician IS NULL AND Craft = @Craft AND Class = @Class

				UNION ALL

				SELECT 5 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician IS NULL AND Craft = @Craft AND Class IS NULL

				UNION ALL

				SELECT 6 RateRank, CostRate
				FROM SMLaborCostEstimate
				WHERE SMCo = @SMCo AND PRCo = @PRCo AND Technician IS NULL AND Craft IS NULL AND Class IS NULL

				UNION ALL

				SELECT 7 RateRank, 0 CostRate
			)getRates
			ORDER BY getRates.RateRank
		)tbl
	)
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMWOQuoteReqLaborRateVal] TO [public]
GO
