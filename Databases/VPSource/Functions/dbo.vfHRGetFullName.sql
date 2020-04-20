SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY	: Dan Sochacki 01/24/2008
* MODIFIED BY	
*
* USAGE:
* 	Returns Full Name of Resource with a Company
*
* INPUT PARAMETERS:
*	HRCo	- Company
*	HRRef	- Resource
*
* OUTPUT PARAMETERS:
*	FullName
*	
*
*****************************************************/
--CREATE FUNCTION [dbo].[vfHRGetFullName]
CREATE FUNCTION [dbo].[vfHRGetFullName]
(@HRCo bCompany = NULL, @HRRef bHRRef = NULL)

RETURNS bVPUserName

AS
BEGIN

	DECLARE		@FullName	VARCHAR(100)

	-----------------------
	-- MAKE CALL TO VIEW --
	-----------------------
	SELECT @FullName = FullName 
      FROM HRRMName
     WHERE HRCo = @HRCo
       AND HRRef = @HRRef


ExitFunction:
  	RETURN @FullName

END

GO
GRANT EXECUTE ON  [dbo].[vfHRGetFullName] TO [public]
GO
