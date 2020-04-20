SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE procedure [dbo].[vspAPT5018ReportingPeriodEndDateVal]
/************************************************************
* CREATED BY:	GF 06/03/2013 TFS-47326 AP T5018 Payments (CA)
* MODIFIED By:		
*								
*								
*
* USAGE:
* Validate Reporting Period End Date entered in AP Taxable Payments Reporting Flag process form.
* Must be a valid End of Month date.
*
* 1. The date must be for the last date of month.
* 2. Warning if not exactly one year between period end dates.
*
* INPUT PARAMETERS
* @APCo				AP Co
* @PeriodEndDate    Period End Date to validate
*
* OUTPUT PARAMETERS
* @EOM						Last Day of Month for the @PeriodEndDate
* @errmsg					if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@APCo bCompany = NULL, 
 @PeriodEndDate bDate = NULL,
 @PeriodClosed CHAR(1) = 'N' OUTPUT,
 @EOM bDate = NULL OUTPUT,
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @DaysDiff INT, @ReportDateFormat INT		

SET @rcode = 0

IF @PeriodEndDate IS NULL
	BEGIN
	SET @Msg = 'Missing Reporting Period End Date!'
	RETURN 1
	END

IF @APCo IS NULL
	BEGIN
	SET @Msg = 'Missing AP Company!'
	RETURN 1
	END

---- is the date a valid date?
if ISDATE(@PeriodEndDate) = 0
	BEGIN
	SET @Msg = 'Reporting Period End Date is not a valid date.'
	RETURN 1
	END

---- get HQ date format
SELECT @ReportDateFormat = CASE WHEN ReportDateFormat = 2 THEN 103
								WHEN ReportDateFormat = 3 THEN 111 
								ELSE 101 
								END
FROM dbo.HQCO
WHERE HQCo = @APCo 
IF @@ROWCOUNT = 0 SET @ReportDateFormat = 101


---- validate that the @PeriodEndDate is a valid EOM date
SET @EOM = dbo.vfLastDayOfMonth (@PeriodEndDate)
IF @EOM IS NULL
	BEGIN
	SET @Msg = 'Invalid Reporting Period End Date.'
	RETURN 1
	END  


---- validate to EOM. Possible that the period date is not end of month
IF @EOM <> @PeriodEndDate
	BEGIN
	SET @Msg = 'Invalid reporting period end date. Must be last day of month: ' + dbo.vfToString(CONVERT(VARCHAR(11), @EOM, @ReportDateFormat))
	RETURN 1
	END  

---- get period closed flag
SELECT @PeriodClosed = PeriodClosed
FROM dbo.APT5018Payment
WHERE APCo = @APCo
	AND PeriodEndDate = @PeriodEndDate
IF @@ROWCOUNT = 0 
	BEGIN
	SET @PeriodClosed = 'N'
	SET @Msg = 'Invalid Reporting Period End Date.'
	RETURN 1
	END	


RETURN 0






GO
GRANT EXECUTE ON  [dbo].[vspAPT5018ReportingPeriodEndDateVal] TO [public]
GO
