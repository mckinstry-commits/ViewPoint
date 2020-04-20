SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		David Solheim
-- Create date: 3/1/13
-- Description:	Get the next SM WO Quote integer number.
-- Modified:	05/10/13 EricV Change to use the stored value as the minimum quote Id, but don't store that last used.
-- =============================================

CREATE PROCEDURE [dbo].[vspSMWOQuoteGetNextNumber]
	@SMCo AS bCompany,
	@NextWOQuote bigint OUTPUT, 
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
	
	SELECT @NextWOQuote = ISNULL(NextWOQuoteID, 1)
	FROM SMCO 
	WHERE SMCo = @SMCo

	WHILE EXISTS (
		SELECT WorkOrderQuote
		FROM SMWorkOrderQuote
		WHERE SMCo = @SMCo AND WorkOrderQuote = CONVERT(varchar, @NextWOQuote)
		)
	BEGIN
		SET @NextWOQuote = @NextWOQuote + 1
	END

    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWOQuoteGetNextNumber] TO [public]
GO
