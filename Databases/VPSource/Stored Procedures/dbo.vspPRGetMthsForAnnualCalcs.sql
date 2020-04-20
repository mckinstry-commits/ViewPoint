SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPRGetMthsForAnnualCalcs]
/***********************************************************
* Created:	GG 02/05/10
* Modified: 
*
* Finds the year's beginning and ending months for Payroll annual limit and
* year-to-date calculations.  Used in Payroll Processing and Check/EFT YTD accums.
*
* INPUT PARAMETERS
*	@yearendmth		Number from 1 to 12 indicating the month in which the year ends.
*					US and CAN should be 12, AUS should be 6.
*	@mth			Month used to calculate, typically paid month
*
* OUTPUT PARAMETERS
*	@beginmth		Beginning month for year-to-date accums and annual limit calcs
*	@endmth			Ending month for year-to-date accums and annual limit calcs
*   @msg			Error message
*
* RETURN VALUE
*   @rcode			0 = success, 1 = failure
*  
*****************************************************/

(@yearendmth TINYINT = 12, @mth bMonth = null, @beginmth bMonth output, @endmth bMonth output, @msg varchar(255) output)
as

set nocount on

declare @rcode INT, @mthvalue TINYINT, @yearvalue INT

select @rcode = 0

-- validate input params
IF @yearendmth <1 OR @yearendmth > 12 
	BEGIN
	SELECT @msg = 'Year ending month must be between 1 and 12.', @rcode = 1
	GOTO vspexit
	END
IF @mth IS null
	BEGIN
	SELECT @msg = 'Missing value for @mth, unable to continue.', @rcode = 1
	GOTO vspexit
	END

-- determine month and year values from input month	
SELECT @mthvalue = DATEPART(MONTH,@mth), @yearvalue = DATEPART(YEAR,@mth)

-- increment year if month value comes after year ending month
IF @mthvalue > @yearendmth  select @yearvalue = @yearvalue +  1 

-- compute beginning and ending months for the year
SELECT @endmth = CONVERT(VARCHAR,@yearendmth) + '/1/' + CONVERT(VARCHAR,@yearvalue)
SELECT @beginmth = DATEADD(MONTH,-11,@endmth)	-- beginning month is 11 months earlier


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRGetMthsForAnnualCalcs] TO [public]
GO
