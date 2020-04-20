SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE procedure [dbo].[vspAPT5018PaymentGetMonthRange]
/************************************************************
* CREATED BY:	GF 06/07/2013 TFS-47329 AP T5018 Payments (CA)
* MODIFIED By:		
*								
*								
*
* USAGE:
* Procedure will return the start month and end month for a T5018 period ending date.
* The month range can then be used to get vendor payments from AP Payment Detail (APTD)
* Will be used by other AP T5018 processes where the vendor payments for a reporting
* period are needed.
*
* 1. Must be a valid T5018 Payment Reporting Period End Date.
*
* INPUT PARAMETERS
* @APCo				AP Co
* @PeriodEndDate    Period End Date to validate
*
* OUTPUT PARAMETERS
* @StartMonth				T5018 Reporting Period Start Month
* @EndMonth					T5018 Reporting Period End Month
* @errmsg					if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@APCo bCompany = NULL, 
 @PeriodEndDate bDate = NULL,
 @StartMonth bDate = NULL OUTPUT,
 @EndMonth bDate = NULL OUTPUT,
 @Msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @DaysDiff INT, @ReportDateFormat INT, @EOM SMALLDATETIME,
		@LastReportingDate SMALLDATETIME	

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
	SET @Msg = 'Invalid reporting period end date. Must be last day of month: ' + dbo.vfToString(CONVERT(VARCHAR(11), @PeriodEndDate, @ReportDateFormat))
	RETURN 1
	END  

---- period end date must exist in APT5018 payments
IF NOT EXISTS(SELECT 1 FROM dbo.APT5018Payment WHERE APCo = @APCo AND PeriodEndDate = @PeriodEndDate)
	BEGIN
	SET @Msg = 'Reporting period end date does not exist in APT5018 payments. ' + dbo.vfToString(CONVERT(VARCHAR(11), @PeriodEndDate, @ReportDateFormat))
	RETURN 1
	END


---- get end month for reporting period end date
SET @EndMonth = dbo.vfToString(@PeriodEndDate)


---- check for prior T5018 payment record
SELECT TOP 1 @LastReportingDate = PAY.PeriodEndDate
FROM dbo.APT5018Payment PAY
WHERE PAY.APCo = @APCo
	AND PAY.PeriodEndDate < @PeriodEndDate
ORDER BY PAY.APCo DESC, PAY.PeriodEndDate DESC
IF @@ROWCOUNT = 0
	BEGIN
	---- no previous T5018 payments
	SET @LastReportingDate = NULL
	END  

---- if the difference is more than a year we only want one year
IF @LastReportingDate IS NOT NULL AND DATEDIFF(YY, @LastReportingDate, @PeriodEndDate) > 1 SET @LastReportingDate = NULL

---- when no prior entry exists then assume one full year for reporting period
IF @LastReportingDate IS NULL
	BEGIN
	SET @LastReportingDate = DATEADD(YEAR, -1, @PeriodEndDate)
	SET @LastReportingDate = DATEADD(MONTH, 1, @LastReportingDate)
	SET @LastReportingDate = dbo.vfLastDayOfMonth(@LastReportingDate)
	END
   
    
---- set the start month from last reporting date - add 1 month to start
SET @StartMonth = DATEADD(MM, 1, dbo.vfFirstDayOfMonth(@LastReportingDate))
 

---- validate months are valid dates
---- is the start month a valid date?
if ISDATE(@StartMonth) = 0
	BEGIN
	SET @Msg = 'Invalid Start Month.'
	RETURN 1
	END

---- is the end month a valid date?
if ISDATE(@EndMonth) = 0
	BEGIN
	SET @Msg = 'Invalid End Month.'
	RETURN 1
	END




RETURN 0





GO
GRANT EXECUTE ON  [dbo].[vspAPT5018PaymentGetMonthRange] TO [public]
GO
