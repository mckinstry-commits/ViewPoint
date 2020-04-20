SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 1/12/12
-- Description:	Get the next SM Agreement integer number.
-- Modified:	
-- =============================================

CREATE PROCEDURE [dbo].[vspSMAgreementGetNextNumber]
	@SMCo AS bCompany, 
	@NextAgreement bigint OUTPUT, 
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
	SET @NextAgreement = 1
	
	SELECT @NextAgreement = ISNULL(MAX(CONVERT(bigint, Agreement)), 0) + 1
	FROM SMAgreement 
	WHERE SMCo = @SMCo AND dbo.bfIsInteger(Agreement) = 1
    
    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementGetNextNumber] TO [public]
GO
