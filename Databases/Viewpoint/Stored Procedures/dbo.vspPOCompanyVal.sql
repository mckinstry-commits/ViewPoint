SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/* =============================================
-- Author:		Jeremiah Barkley
-- Create date: 11/23/10
-- Description:	PO Company Validation. Created for use in SM.
=============================================*/
CREATE PROCEDURE [dbo].[vspPOCompanyVal]
	@POCo AS bCompany,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT @msg = HQCO.Name FROM dbo.POCO 
	INNER JOIN dbo.HQCO ON HQCO.HQCo = POCO.POCo
	WHERE POCo = @POCo

	IF (@@ROWCOUNT = 0)
	BEGIN
		SET @msg = 'Invalid PO Company.'
		RETURN 1
	END
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspPOCompanyVal] TO [public]
GO
