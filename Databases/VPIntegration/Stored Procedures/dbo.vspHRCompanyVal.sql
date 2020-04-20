SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************
 * Created: Dan Sochacki - 11/08/2007
 *
 * Purpose: Validates HR Company number
 *
 * Inputs:
 *	@HRCo		Company # 
 *
 * Ouput:
 *	@msg		Company name or error message
 * 
 * Return code:
 *	0 = success, 1 = failure
 *
 ******************************************/
--CREATE  PROC [dbo].[vspHRCompanyVal]
CREATE  PROC [dbo].[vspHRCompanyVal]
	(@HRCo bCompany = 0, @msg VARCHAR(60) OUTPUT)

AS
SET NOCOUNT ON

	DECLARE @rcode int

	SELECT @rcode = 0

	IF @HRCo = 0
		BEGIN
			SELECT @msg = 'Missing HR Company#!', @rcode = 1
			GOTO vspexit
		END

	-----------------
	-- GET COMPANY --
	-----------------
	SELECT @msg = HRCo 
      FROM bHRCO WITH (NOLOCK) 
     WHERE HRCo = @HRCo 

	-------------------
	-- FIND COMPANY? --
	-------------------
	IF @@rowcount = 0
		SELECT @msg = 'Not a valid HR Company!', @rcode = 1

vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRCompanyVal] TO [public]
GO
