SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE procedure [dbo].[vspAPT5018PaymentDateVal]
/************************************************************
* CREATED BY:	GF 06/03/2013 TFS-47326 AP T5018 Payments (CA)
* MODIFIED By:		
*								
*								
*
* USAGE:
* Validate Reporting Period End Date entered in APT5018Payments.
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
* @ContactName				Contact Name
* @ContactAreaCode			Contact Area Code
* @ContactPhone				Contact Phone
* @ContactExtension			Contact Extenion
* @ContactEmail				Contact Email
* @SubmissionReferenceId	Submission Reference Id
* @TransmitterNo			Transmitter number
* @@OneYearBetweenDates		Flag to indicate one year between reporting periods
* @LastReportingDate		Last Reporing Period date if one exists
* @EOM						Last Day of Month for the @PeriodEndDate
* @errmsg					if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
(@APCo bCompany = NULL, 
 @PeriodEndDate bDate = NULL,
 @ContactName VARCHAR(22) = NULL OUTPUT,
 @ContactAreaCode VARCHAR(3) = NULL OUTPUT,
 @ContactPhone VARCHAR(8) = NULL OUTPUT,
 @ContactExtension VARCHAR(5) = NULL OUTPUT,
 @ContactEmail VARCHAR(60) = NULL OUTPUT,
 @SubmissionReferenceId VARCHAR(8) = NULL OUTPUT,
 @TransmitterNo VARCHAR(8) = NULL OUTPUT,
 @OneYearBetweenDates CHAR(1) = 'Y' OUTPUT,
 @LastReportingDate bDate = NULL OUTPUT,
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
	---- first check if @EOM exists in table
	IF EXISTS(SELECT 1 FROM dbo.APT5018Payment WHERE APCo = @APCo AND PeriodEndDate = @EOM)
		BEGIN
		SET @Msg = 'Record exists for the end of month for the reporting period. ' + dbo.vfToString(CONVERT(VARCHAR(11), @PeriodEndDate, @ReportDateFormat))
		RETURN 1
		END
		 
	SET @Msg = 'Invalid reporting period end date. Must be last day of month: ' + dbo.vfToString(CONVERT(VARCHAR(11), @EOM, @ReportDateFormat))
	RETURN 0
	END  


---- if prior contractor pay record exists get values for defaults
SELECT TOP 1 @LastReportingDate = PAY.PeriodEndDate
			,@ContactName = PAY.ContactName
			,@ContactAreaCode = PAY.ContactAreaCode
			,@ContactPhone  = ContactPhone
			,@ContactExtension = ContactExtension
			,@ContactEmail = ContactEmail
			,@SubmissionReferenceId = SubmissionReferenceId
			,@TransmitterNo = TransmitterNo
FROM dbo.APT5018Payment PAY
WHERE PAY.APCo = @APCo
	AND PAY.PeriodEndDate < @PeriodEndDate
ORDER BY PAY.APCo DESC, PAY.PeriodEndDate DESC
IF @@ROWCOUNT = 0
	BEGIN
	---- no previous T5018 payments
	SET @LastReportingDate = NULL
	END  


---- validate that there is a year between dates. form validation warning
SET @OneYearBetweenDates = 'Y'
IF @LastReportingDate IS NOT NULL
	BEGIN
	SET @DaysDiff = DATEDIFF(DAY, @LastReportingDate, @PeriodEndDate)
	IF @DaysDiff > 366
		BEGIN
		SET @Msg = 'Invalid Period End Date. May not be more than a year between reporting periods.'  
		RETURN -1
		END	
	IF @DaysDiff < 365
		BEGIN
		SET @OneYearBetweenDates = 'N'
		END
	END

---- get month range for period end date
--exec @rcode = dbo.vspAPT5018PaymentGetMonthRange @APCo, @PeriodEndDate, @StartMonth OUTPUT, @EndMonth OUTPUT, @Msg OUTPUT
--IF @rcode <> 0
--	BEGIN
--	RETURN 1
--	END





RETURN 0




GO
GRANT EXECUTE ON  [dbo].[vspAPT5018PaymentDateVal] TO [public]
GO
