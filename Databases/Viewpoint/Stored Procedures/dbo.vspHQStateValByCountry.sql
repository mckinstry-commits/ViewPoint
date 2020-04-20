SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspHQStateValByCountry]	
/******************************************************
* CREATED BY:	MV	03/29/11	 
* MODIFIED By:  	
*
* Usage: Validates State by country.  If Country is not
*		passed use default Country from HQ Company.
*	
*
* Input params:
*	@hqco		Company #
*	@country	Country 
*	@state		State
*
* Output params:
*	@msg		State name or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

(@HQCo bCompany = NULL, @Country CHAR(2) = NULL, @State VARCHAR(4) = NULL, @Msg VARCHAR(100) OUTPUT)

AS 
SET NOCOUNT ON
DECLARE @rcode INT

SELECT @rcode = 0

-- get default Country assigned by company, if not passed (optional) 
IF @Country IS NULL
	SELECT @Country = DefaultCountry
	FROM dbo.bHQCO (NOLOCK)
	WHERE HQCo = @HQCo

-- must have Country, passed or pulled from bHQCO
IF @Country IS NULL
	BEGIN
	SELECT @Msg = 'Default Country, must be setup in HQ Company!', @rcode = 1
	GOTO vspexit
	END
	

-- validate State
IF @State IS NOT NULL
	BEGIN
	SELECT @Msg = Name
	FROM dbo.bHQST (NOLOCK)
	WHERE State = @State and Country = @Country
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @Msg = @State + ' is an invalid state!', @rcode = 1
		GOTO vspexit
		END
	END
	 
vspexit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQStateValByCountry] TO [public]
GO
