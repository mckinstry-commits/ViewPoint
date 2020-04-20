SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPTChekVal]
/***************************************************************************
* CREATED BY:	KK 04/30/12
* MODIFIED By : 
*
*
* USAGE:	Validates TChek inputs to make sure it the values entered are numeric and have no special characters
*			An error is returned if any of the following occurs, else Dexcription
*
* DDFI Validation Procedure for:
*			TCCo (seq 316)   ValLevel-2	AP Company
*			TCAcct (seq 317) ValLevel-2 AP Company
*
*
* INPUT PARAMETERS
*   One of the following sent in as the second parameter:
*
*	TCCo		TChek company to validate against
*   TCAcct		TChek account to validate against
*
*
* OUTPUT PARAMETERS
*   @msg		error message if error occurs
*
* RETURN VALUE
*   0			success
*   1			Failure
******************************************************************************/ 
   
(@tchekval varchar(10) = NULL,
 @msg varchar(255) OUTPUT)

AS 
SET NOCOUNT ON

SELECT @tchekval = LTRIM(RTRIM(@tchekval))


--Check that the user entered a numeric value, with no invalid special characters 
IF @tchekval IS NOT NULL 
   AND(   ISNUMERIC(@tchekval) = 0 
	   OR CHARINDEX('-',@tchekval) > 0
	   OR CHARINDEX('.',@tchekval) > 0)
BEGIN 
	SELECT @msg = '''' + @tchekval + ''' ' + 'is an invalid value. Input must be numeric.'
	RETURN 1
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPTChekVal] TO [public]
GO
