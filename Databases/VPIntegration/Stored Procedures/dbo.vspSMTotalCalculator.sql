SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/25/10
-- Description:	Used to calculate if possible the missing value for a quantity, rate and total
-- Automatically rounds
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTotalCalculator]
	@Quantity bUnits OUTPUT,
	@Rate bUnitCost OUTPUT,
	@Total bDollar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF @Quantity IS NOT NULL
    BEGIN
		IF @Rate IS NOT NULL
		BEGIN
			SET @Total = @Quantity * @Rate
		END
		ELSE IF @Total IS NOT NULL
		BEGIN
			IF @Quantity = 0
			BEGIN
				SET @Quantity = NULL
			END
			ELSE
			BEGIN
				SET @Rate = @Total / @Quantity
			END
		END
    END
    ELSE IF @Rate IS NOT NULL AND @Total IS NOT NULL
    BEGIN
		IF @Rate = 0
		BEGIN
			SET @Rate = NULL
		END
		ELSE
		BEGIN
			SET @Quantity = @Total / @Rate
		END
    END
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMTotalCalculator] TO [public]
GO
