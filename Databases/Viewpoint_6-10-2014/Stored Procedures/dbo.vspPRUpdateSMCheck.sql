SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRUpdateSMCheck    Script Date: 8 ******/
CREATE procedure [dbo].[vspPRUpdateSMCheck]
/***********************************************************
* CREATED BY: ECV 08/12/12
* MODIFIED By : 
*
*
* USAGE:
* Called from the Pay Period Update form after Validation has completed.  If SM records DO NOT exist
* for the Pay Period, then the SM Report remains disabled.
*
*
* INPUT PARAMETERS
*   @prco   		PR Company
*   @prgroup  		PR Group to validate
*   @prenddate		Pay Period Ending Date
*
* OUTPUT PARAMETERS
*   @errmsg      error message if error occurs
*
* RETURN VALUE
*   0		success - PRER records do exist for this Pay Period
*   1		error - Cannot determine
*	7		Conditional Success - No errors but PRER records do NOT exist for this Pay Period
*	
*****************************************************/
(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @errmsg varchar(255) = null output)
AS

SET NOCOUNT ON

DECLARE @rcode INT

SELECT @rcode = 0

IF @prco IS NULL
	BEGIN
	SELECT @errmsg = 'Missing PR Company.'
	RETURN 1
	END
IF @prgroup IS NULL
	BEGIN
	SELECT @errmsg = 'Missing PR Group.'
	RETURN 1
	END
IF @prenddate IS NULL
	BEGIN
	SELECT @errmsg = 'Missing PR Pay Period Ending Date.'
	RETURN 1
	END

/* Check for SM records for this Pay Period */
IF NOT EXISTS(SELECT TOP 1 1 FROM bPRTH WITH (NOLOCK) WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND SMCo IS NOT NULL AND SMWorkOrder IS NOT NULL)
	BEGIN
	RETURN 7
	END
	
RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRUpdateSMCheck] TO [public]
GO
