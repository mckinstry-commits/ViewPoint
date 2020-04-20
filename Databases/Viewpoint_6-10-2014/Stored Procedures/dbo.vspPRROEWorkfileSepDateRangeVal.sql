SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRROEWorkfileSepDateRangeVal]
/***********************************************************
* CREATED BY:  KK 03/20/2013
* MODIFIED By: 
* 
* USAGE: Used in PREmployeeROEWorkfile, Validates that the separation start date is before the end date 
*
* INPUT PARAMETERS
*   @begdate   Beginning of the "Separation date range"
*	@enddate	End of the "Separation date range"
*
* OUTPUT PARAMETERS
*   @msg      error message or Description (Full name)
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/
(@begdate bDate = NULL,
 @enddate bDate = NULL,
 @msg varchar(60) OUTPUT)

AS SET NOCOUNT ON

DECLARE	@method char(1)

-- Only return an error message if both dates have been entered and the end date is before the begin date.
IF @begdate IS NULL	
	OR @begdate = ''
	OR @enddate IS NULL 
	OR @enddate = ''
	OR @begdate <= @enddate 
	RETURN 0
ELSE
BEGIN
	SET @msg = 'End date must be the same as, or later than the Begin date.'
	RETURN 1
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRROEWorkfileSepDateRangeVal] TO [public]
GO
