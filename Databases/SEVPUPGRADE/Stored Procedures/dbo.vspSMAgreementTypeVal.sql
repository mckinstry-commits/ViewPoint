SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMAgreementTypeVal]
-- =============================================
-- Author:		David Solheim
-- Create date: 3/21/12
-- Description:	Validation for SM Agreement Type
-- Modified:	
-- =============================================
	@SMCo AS bCompany, 
	@AgreementType AS varchar(15), 
	@Description AS varchar(255) OUTPUT,
	@msg AS varchar(255) OUTPUT
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
	
	IF (@AgreementType IS NULL)
	BEGIN
		SET @msg = 'Missing SM Agreement Type!'
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @Description = [Description], @IsActive = Active
	FROM dbo.SMAgreementType
	WHERE SMCo = @SMCo AND AgreementType = @AgreementType
    
    IF (@@ROWCOUNT = 0)
    BEGIN
		SET @msg = 'Agreement Type has not been setup in SM Agreement Type.'
		RETURN 1
    END
    
    IF (@IsActive <> 'Y')
    BEGIN
		SET @msg = 'Inactive agreement type.'
		RETURN 1
    END
    
    RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementTypeVal] TO [public]
GO
