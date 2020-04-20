SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMDivisionVal]
	/******************************************************
	* CREATED BY:  MarkH 
	* MODIFIED By: 
	*
	* Usage:  Validation procedure for SMDivisions.
	*	
	*
	* Input params:
	*	
	*	@SMCo - SM Company
	*	@ServiceCenter - SM Service Center
	*	@Division - SM Division
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, @ServiceCenter AS varchar(10), @Division AS varchar(10), @MustBeActive AS bit, @msg AS varchar(255) OUTPUT
AS 
BEGIN

	SET NOCOUNT ON

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END

	IF @ServiceCenter IS NULL
	BEGIN
		SET @msg = 'Missing Service Center.'
		RETURN 1
	END
	
	IF @Division IS NULL
	BEGIN
		SET @msg = 'Missing Division.'
		RETURN 1
	END
	
	DECLARE @IsActive bYN
	
	SELECT @msg = [Description], @IsActive = Active
	FROM dbo.SMDivision
	WHERE SMCo = @SMCo AND ServiceCenter = @ServiceCenter AND Division = @Division
	
	IF @@rowcount = 0
    BEGIN
		SET @msg = 'Service Center/Division has not been setup.'
		RETURN 1
    END
    
    IF @IsActive <> 'Y'
    BEGIN
		SET @msg = ISNULL(@msg,'') + ' - Inactive division.'
		IF @MustBeActive = 1
		BEGIN
			RETURN 1
		END
    END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMDivisionVal] TO [public]
GO
