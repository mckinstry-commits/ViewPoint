SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMAgreementAmendmentCreate]
	@SMCo bCompany,
	@Agreement varchar(20),
	@Revision int,
	@NextRevision int OUTPUT,
	@msg varchar(255) OUTPUT
/***********************************************************
* CREATED BY: EricV 06/11/12
* Modified:
*
* Usage:
*	Create a copy of an agreement for amendment with the next available revision.
*
* Input params:
*	@SMCo		SM company
*	@Agreement	Agreement
*	@Revision	Agreement Revision to be amended
* Output paramsL
*	@NextRevision Revision that is created.
*	@msg		Vendor Name or error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
AS
SET NOCOUNT ON

	DECLARE @rcode int, @rowsToInsert int, @TotalAmountPrevious bDollar, @TotalAmountAmend bDollar, @PreviousEffectiveDate smalldatetime

	-- Check the status of the agreement revision to be amended.
	IF NOT EXISTS(SELECT 1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND Status IN (2,3))
	BEGIN
		SELECT @rcode=1, @msg='Agreement revision to amend is not active.'
		GOTO ExitSub
	END

	-- Make sure there isn't a pending amendment already.
	IF EXISTS(SELECT 1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND PreviousRevision=@Revision AND Status=0)
	BEGIN
		SELECT @rcode=1, @msg='An amendment for this agreement revision already exists.'
		GOTO ExitSub
	END
	
	-- Check for pending invoices on previous revision
	IF EXISTS(SELECT 1 FROM SMAgreementBillingSchedule
	INNER JOIN SMInvoice ON SMInvoice.SMInvoiceID=SMAgreementBillingSchedule.SMInvoiceID
	WHERE SMAgreementBillingSchedule.SMCo=@SMCo 
		AND SMAgreementBillingSchedule.Agreement=@Agreement 
		AND SMAgreementBillingSchedule.Revision=@Revision 
		AND SMInvoice.Invoiced = 0
		)
	BEGIN
		SELECT @rcode=1, @msg='Pending invoices exist for this agreement revision.'
		GOTO ExitSub
	END
	
	-- Get the next revision
	SELECT @NextRevision = MAX(Revision)+1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement

	SELECT @PreviousEffectiveDate=EffectiveDate FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision = @Revision
BEGIN TRAN
	-- Create the new revision agreement header
	INSERT SMAgreement 
		(SMCo
		, Agreement
		, Revision
		, Description
		, CustGroup
		, Customer
		, NonExpiring
		, EffectiveDate
		, ExpirationDate
		, AutoRenew
		, RateTemplate
		, AgreementPrice
		, PricingFrequency
		, ReportID
		, AgreementType
		, CustomerPO
		, AlternateAgreement
		, PreviousRevision
		, RevisionType
		, DateCreated)
	SELECT SMCo
		, Agreement
		, @NextRevision
		, Description
		, CustGroup
		, Customer
		, NonExpiring
		, CASE WHEN EffectiveDate >= dbo.vfDateOnly() THEN DateAdd(D, 1, EffectiveDate)
				ELSE dbo.vfDateOnly() END
		, ExpirationDate
		, AutoRenew
		, RateTemplate
		, AgreementPrice
		, PricingFrequency
		, ReportID
		, AgreementType
		, CustomerPO
		, AlternateAgreement
		, Revision
		, 2
		, dbo.vfDateOnly()
	FROM SMAgreement
	WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision

	IF NOT(@@ROWCOUNT=1)
	BEGIN
		SELECT @rcode=1, @msg='Failed to create agreement amendment header.'
		GOTO ErrorOccured
	END
	
	SELECT @rowsToInsert=COUNT(1) FROM vSMAgreementService
		WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision
	
	-- Copy the SMAgreementBillingService records.
	INSERT INTO [dbo].[vSMAgreementService]
		([SMCo]
		,[Agreement]
		,[Revision]
		,[Service]
		,[Description]
		,[ServiceSite]
		,[CallType]
		,[ServiceCenter]
		,[TaxSource]
		,[PricingMethod]
		,[PricingFrequency]
		,[PricingPrice]
		,[BilledSeparately]
		,[PricingRateTemplate]
		,[ScheOptContactBeforeScheduling]
		,[ScheOptDueType]
		,[ScheOptDays]
		,[RecurringPatternType]
		,[DailyType]
		,[DailyEveryDays]
		,[WeeklyEveryWeeks]
		,[WeeklyEverySun]
		,[WeeklyEveryMon]
		,[WeeklyEveryTue]
		,[WeeklyEveryWed]
		,[WeeklyEveryThu]
		,[WeeklyEveryFri]
		,[WeeklyEverySat]
		,[MonthlyType]
		,[MonthlyDay]
		,[MonthlyDayEveryMonths]
		,[MonthlyEveryOrdinal]
		,[MonthlyEveryDay]
		,[MonthlyEveryMonths]
		,[MonthlySelectOrdinal]
		,[MonthlySelectDay]
		,[MonthlyJan]
		,[MonthlyFeb]
		,[MonthlyMar]
		,[MonthlyApr]
		,[MonthlyMay]
		,[MonthlyJun]
		,[MonthlyJul]
		,[MonthlyAug]
		,[MonthlySep]
		,[MonthlyOct]
		,[MonthlyNov]
		,[MonthlyDec]
		,[YearlyType]
		,[YearlyEveryYear]
		,[YearlyEveryDateMonth]
		,[YearlyEveryDateMonthDay]
		,[YearlyEveryDayOrdinal]
		,[YearlyEveryDayDay]
		,[YearlyEveryDayMonth]
		,[WasCopied])
	SELECT [SMCo]
		,[Agreement]
		,@NextRevision
		,[Service]
		,[Description]
		,[ServiceSite]
		,[CallType]
		,[ServiceCenter]
		,[TaxSource]
		,[PricingMethod]
		,[PricingFrequency]
		,[PricingPrice]
		,[BilledSeparately]
		,[PricingRateTemplate]
		,[ScheOptContactBeforeScheduling]
		,[ScheOptDueType]
		,[ScheOptDays]
		,[RecurringPatternType]
		,[DailyType]
		,[DailyEveryDays]
		,[WeeklyEveryWeeks]
		,[WeeklyEverySun]
		,[WeeklyEveryMon]
		,[WeeklyEveryTue]
		,[WeeklyEveryWed]
		,[WeeklyEveryThu]
		,[WeeklyEveryFri]
		,[WeeklyEverySat]
		,[MonthlyType]
		,[MonthlyDay]
		,[MonthlyDayEveryMonths]
		,[MonthlyEveryOrdinal]
		,[MonthlyEveryDay]
		,[MonthlyEveryMonths]
		,[MonthlySelectOrdinal]
		,[MonthlySelectDay]
		,[MonthlyJan]
		,[MonthlyFeb]
		,[MonthlyMar]
		,[MonthlyApr]
		,[MonthlyMay]
		,[MonthlyJun]
		,[MonthlyJul]
		,[MonthlyAug]
		,[MonthlySep]
		,[MonthlyOct]
		,[MonthlyNov]
		,[MonthlyDec]
		,[YearlyType]
		,[YearlyEveryYear]
		,[YearlyEveryDateMonth]
		,[YearlyEveryDateMonthDay]
		,[YearlyEveryDayOrdinal]
		,[YearlyEveryDayDay]
		,[YearlyEveryDayMonth]
		,1
	FROM vSMAgreementService
	WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision

	IF NOT(@@ROWCOUNT=@rowsToInsert)
	BEGIN
		SELECT @rcode=1, @msg='Failed to create agreement amendment service.'
		GOTO ErrorOccured
	END
	
	SELECT @rowsToInsert=COUNT(1) FROM vSMAgreementBillingSchedule
		WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND SMInvoiceID IS NULL
		AND BillingType='S'
		
	-- Copy the Agreement Billing Schedule
	INSERT INTO [dbo].[vSMAgreementBillingSchedule]
		([SMCo]
		,[Agreement]
		,[Revision]
		,[Service]
		,[Billing]
		,[Date]
		,[Month]
		,[Day]
		,[BillingAmount]
		,[SMInvoiceID]
		,[TaxGroup]
		,[TaxType]
		,[TaxCode]
		,[TaxBasis]
		,[TaxAmount]
		,[BillingType])
	SELECT [SMCo]
		,[Agreement]
		,@NextRevision
		,[Service]
		,Row_Number() OVER (PARTITION By Service ORDER BY Date)
		,[Date]
		,[Month]
		,[Day]
		,[BillingAmount]
		,[SMInvoiceID]
		,[TaxGroup]
		,[TaxType]
		,[TaxCode]
		,[TaxBasis]
		,[TaxAmount]
		,[BillingType]
	FROM vSMAgreementBillingSchedule
	WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND SMInvoiceID IS NULL AND BillingType='S'

	IF NOT(@@ROWCOUNT=@rowsToInsert)
	BEGIN
		SELECT @rcode=1, @msg='Failed to create agreement amendment billing schedule.'
		GOTO ErrorOccured
	END
	
	SELECT @rowsToInsert=COUNT(1) FROM vSMAgreementServiceTask
		WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision
		
	-- Copy the Agreement Service Tasks
	INSERT INTO [dbo].[vSMAgreementServiceTask]
		([SMCo]
		,[Agreement]
		,[Revision]
		,[Service]
		,[Task]
		,[SMStandardTask]
		,[Name]
		,[Description]
		,[ServiceItem])
	SELECT [SMCo]
		,[Agreement]
		,@NextRevision
		,[Service]
		,[Task]
		,[SMStandardTask]
		,[Name]
		,[Description]
		,[ServiceItem]
	FROM SMAgreementServiceTask
	WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision

	IF NOT(@@ROWCOUNT=@rowsToInsert)
	BEGIN
		SELECT @rcode=1, @msg='Failed to create agreement amendment service tasks.'
		GOTO ErrorOccured
	END
	
	/* Recalculate agreement prices based on billings that have been copied. */
	
	SELECT @TotalAmountPrevious=ISNULL(SUM(BillingAmount),0) FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND Service IS NULL AND BillingType='S'
	SELECT @TotalAmountAmend=ISNULL(SUM(BillingAmount),0) FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND Service IS NULL AND BillingType='S'

	UPDATE vSMAgreement SET AgreementPrice = CASE WHEN @TotalAmountPrevious=0 THEN 0 ELSE @TotalAmountAmend*(AgreementPrice/@TotalAmountPrevious) END FROM vSMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision
	UPDATE vSMAgreementService SET PricingPrice = CASE WHEN @TotalAmountPrevious=0 THEN 0 ELSE @TotalAmountAmend*PricingPrice/@TotalAmountPrevious END FROM vSMAgreementService WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND PricingMethod='P' AND BilledSeparately='N'
	
	/* Update Agreement price for rounding */
	UPDATE vSMAgreement SET AgreementPrice = AgreementPrice-(@TotalAmountAmend-AgreementPrice-ISNULL(SumPricingPrice,0)) FROM vSMAgreement
		LEFT JOIN (SELECT SMCo, Agreement, Revision, SUM(PricingPrice) SumPricingPrice FROM vSMAgreementService WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND PricingMethod='P' AND BilledSeparately='N' GROUP BY SMCo, Agreement, Revision)
		AgreementServices ON AgreementServices.SMCo=vSMAgreement.SMCo AND AgreementServices.Agreement=vSMAgreement.Agreement AND AgreementServices.Revision=vSMAgreement.Revision
		WHERE vSMAgreement.SMCo=@SMCo AND vSMAgreement.Agreement=@Agreement AND vSMAgreement.Revision=@NextRevision

	/* Update the service price on services that have separate billings based on services billing schedule. */
	UPDATE vSMAgreementService SET PricingPrice = ISNULL(Billings.BillingTotal,0)
	FROM vSMAgreementService 
	LEFT JOIN (SELECT SMCo, Agreement, Revision, Service, SUM(BillingAmount) BillingTotal FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND Service IS NOT NULL AND BillingType='S' GROUP BY SMCo, Agreement, Revision, Service) Billings
	ON Billings.SMCo=vSMAgreementService.SMCo AND Billings.Agreement=vSMAgreementService.Agreement AND Billings.Revision=vSMAgreementService.Revision AND Billings.Service=vSMAgreementService.Service
	WHERE vSMAgreementService.SMCo=@SMCo AND vSMAgreementService.Agreement=@Agreement AND vSMAgreementService.Revision=@NextRevision AND vSMAgreementService.PricingMethod='P' AND vSMAgreementService.BilledSeparately='Y'	
	
	COMMIT TRAN

GOTO ExitSub

ErrorOccured:
	ROLLBACK TRAN
	
ExitSub:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmendmentCreate] TO [public]
GO
