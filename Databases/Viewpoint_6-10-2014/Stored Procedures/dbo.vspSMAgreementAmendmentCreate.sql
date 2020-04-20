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
* Modified:	Dan K 02/25/13 TFS-40937 Add revenue recognition flag.
*			Dan K 04/09/13 TFS-46122 Resolve rounding issue with services on the billing schedule 
*			Matt B 4/24/13 TFS-48149 Split revenue copy lines
*			Matt B 5/2/13  TFS-48972 Update to handle Division in amendments
*			Dan K 07/05/13 TFS-54778 Add Taxable status to copy of Revenue Split
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
BEGIN
	SET NOCOUNT ON

	DECLARE @TotalAmountPrevious bDollar, @TotalAmountAmend bDollar, @PreviousEffectiveDate smalldatetime, @RevenueRecognition char(1), @NewPricingPriceTotal bDollar, @rcode int

	-- Check the status of the agreement revision to be amended.
	IF NOT EXISTS(SELECT 1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND Status IN (2,3))
	BEGIN
		SET @msg = 'Agreement revision to amend is not active.'
		RETURN 1
	END

	-- Make sure there isn't a pending amendment already.
	IF EXISTS(SELECT 1 FROM SMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND PreviousRevision=@Revision AND Status=0)
	BEGIN
		SET @msg = 'An amendment for this agreement revision already exists.'
		RETURN 1
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
		SET @msg = 'Pending invoices exist for this agreement revision.'
		RETURN 1
	END

	SELECT @PreviousEffectiveDate = EffectiveDate, @RevenueRecognition = RevenueRecognition
	FROM dbo.SMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision

	BEGIN TRY
		BEGIN TRAN

		-- Get the next revision
		SELECT @NextRevision = MAX(Revision)+1
		FROM SMAgreement
		WHERE SMCo = @SMCo AND Agreement = @Agreement

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
			, DateCreated
			, RevenueRecognition)
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
			, RevenueRecognition
		FROM SMAgreement
		WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision

		-- Copy the SMAgreementBillingService records.
		INSERT INTO [dbo].[vSMAgreementService]
			([SMCo]
			,[Agreement]
			,[Revision]
			,[Service]
			,[Description]
			,[ServiceSite]
			,[Division]
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
			,[Division]
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

		--Copy the deferrals if the previous revision is 
		IF @RevenueRecognition = 'S'
		BEGIN
			INSERT dbo.vSMAgreementRevenueDeferral (SMCo, Agreement, Revision, [Service], Deferral, [Date], Amount)
			SELECT SMCo, Agreement, @NextRevision, [Service],
				ROW_NUMBER() OVER(PARTITION BY [Service] ORDER BY [Date]), [Date],
				--The amount should always be the given amount 
				CASE WHEN RunningTotal > BillingAmountSum THEN BillingAmountSum - (RunningTotal - Amount) ELSE Amount END
			FROM
			(
				SELECT vSMAgreementRevenueDeferral.*,
					ISNULL(BillingAmountSum, 0) BillingAmountSum, --It is possible there are no remaining invoices to be processed and so the BillingSum would be null then.
					DeriveRunningTotal.RunningTotal
				FROM dbo.vSMAgreementRevenueDeferral					
					CROSS APPLY
					(
						SELECT SUM(Amount) AS RunningTotal
						FROM vSMAgreementRevenueDeferral SMRevenueDeferral
						WHERE 
						vSMAgreementRevenueDeferral.SMCo = SMRevenueDeferral.SMCo AND 
						vSMAgreementRevenueDeferral.Agreement = SMRevenueDeferral.Agreement AND 
						vSMAgreementRevenueDeferral.Revision = SMRevenueDeferral.Revision AND 
						dbo.vfIsEqual(vSMAgreementRevenueDeferral.[Service], SMRevenueDeferral.[Service]) = 1 AND 
						(
							vSMAgreementRevenueDeferral.Date < SMRevenueDeferral.Date OR 
							(
								vSMAgreementRevenueDeferral.Date = SMRevenueDeferral.Date AND 
								vSMAgreementRevenueDeferral.Deferral <= SMRevenueDeferral.Deferral
							)
						)
					) DeriveRunningTotal				
					CROSS APPLY
					(
						--For the agreement/service get the sum amount that has not been invoiced. This is the amount that the deferrals copied to the agreement/service need to sum to.
						SELECT SUM(BillingAmount) BillingAmountSum
						FROM dbo.vSMAgreementBillingSchedule
						WHERE vSMAgreementRevenueDeferral.SMCo = vSMAgreementBillingSchedule.SMCo AND vSMAgreementRevenueDeferral.Agreement = vSMAgreementBillingSchedule.Agreement AND vSMAgreementRevenueDeferral.Revision = vSMAgreementBillingSchedule.Revision AND dbo.vfIsEqual(vSMAgreementRevenueDeferral.[Service], vSMAgreementBillingSchedule.[Service]) = 1
							AND vSMAgreementBillingSchedule.SMInvoiceID IS NULL AND vSMAgreementBillingSchedule.BillingType = 'S'
					) DeriveBillingAmountSum
				WHERE vSMAgreementRevenueDeferral.SMCo = @SMCo AND vSMAgreementRevenueDeferral.Agreement = @Agreement AND vSMAgreementRevenueDeferral.Revision = @Revision
			) GetRunningTotal
			--Once the running total exceeds the billing sum for a given agreement/service then those records should be excluded with the exception of the last record which will need to have it amount modified
			WHERE RunningTotal - Amount < BillingAmountSum
		END

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
		
		-- Copy revenue split records									
		INSERT INTO dbo.vSMEntity
			(
			[Type]
			,SMCo
			,EntitySeq
			,Agreement
			,AgreementRevision
			,AgreementService
			)
		SELECT
			[Type]
			,SMCo
			,ROW_NUMBER() OVER (ORDER BY EntitySeq) + ISNULL((SELECT MAX(EntitySeq) FROM vSMEntity WHERE SMCo = @SMCo),0)
			,Agreement
			,@NextRevision
			,AgreementService
		FROM
			vSMEntity
		WHERE
			SMCo = @SMCo AND Agreement=@Agreement AND AgreementRevision=@Revision	
		
			
		INSERT INTO dbo.vSMFlatPriceRevenueSplit
		(
			 SMCo
			,EntitySeq
			,Seq
			,CostTypeCategory
			,CostType
			,Amount
			,PricePercent
			,Notes
			,Taxable
		)
		SELECT
			 vSMFlatPriceRevenueSplit.SMCo
			,NewRevEntity.EntitySeq
			,vSMFlatPriceRevenueSplit.Seq
			,vSMFlatPriceRevenueSplit.CostTypeCategory
			,vSMFlatPriceRevenueSplit.CostType
			,vSMFlatPriceRevenueSplit.Amount
			,vSMFlatPriceRevenueSplit.PricePercent
			,vSMFlatPriceRevenueSplit.Notes
			,vSMFlatPriceRevenueSplit.Taxable
		FROM
			vSMAgreementService INNER JOIN vSMEntity
			ON
				vSMAgreementService.SMCo = vSMEntity.SMCo AND vSMAgreementService.Agreement= vSMEntity.Agreement AND vSMAgreementService.Revision = vSMEntity.AgreementRevision AND vSMAgreementService.Service = vSMEntity.AgreementService
			INNER JOIN
				vSMFlatPriceRevenueSplit
			ON
				vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo AND vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq
			INNER JOIN
				vSMEntity NewRevEntity
			ON
				vSMAgreementService.SMCo = NewRevEntity.SMCo AND vSMAgreementService.Agreement= NewRevEntity.Agreement AND @NextRevision = NewRevEntity.AgreementRevision AND vSMAgreementService.Service = NewRevEntity.AgreementService
		WHERE
			vSMAgreementService.SMCo = @SMCo AND
			vSMAgreementService.Agreement = @Agreement AND
			vSMAgreementService.Revision = @Revision 			
	
		/* Recalculate agreement prices based on billings that have been copied. */
	
		SELECT @TotalAmountPrevious=ISNULL(SUM(BillingAmount),0) FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@Revision AND Service IS NULL AND BillingType='S'
		SELECT @TotalAmountAmend=ISNULL(SUM(BillingAmount),0) FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND Service IS NULL AND BillingType='S'

		UPDATE vSMAgreement SET AgreementPrice = CASE WHEN @TotalAmountPrevious=0 THEN 0 ELSE @TotalAmountAmend*(AgreementPrice/@TotalAmountPrevious) END FROM vSMAgreement WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision
		UPDATE vSMAgreementService SET PricingPrice = CASE WHEN @TotalAmountPrevious=0 THEN 0 ELSE @TotalAmountAmend*PricingPrice/@TotalAmountPrevious END FROM vSMAgreementService WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND PricingMethod='P' AND BilledSeparately='N'
	
				/* Get the current total of Pricing Price items for this new revision */ 
		SELECT	@NewPricingPriceTotal = SUM(PricingPrice) FROM	vSMAgreementService WHERE	SMCo=@SMCo 	AND Agreement=@Agreement AND Revision=@NextRevision AND PricingMethod='P' AND BilledSeparately='N'
		
		-- If there is a difference between the new Pricing Price total and the Total Amendment amount + Agreement Price, fix it
		IF @NewPricingPriceTotal <> (@TotalAmountAmend + ISNULL((SELECT AgreementPrice FROM vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @NextRevision),0))
		BEGIN  

			/* Check to see that there is an AgreementPrice before allowing an update to the Agreement Price */
			IF (ISNULL((SELECT	AgreementPrice FROM	vSMAgreement WHERE	vSMAgreement.SMCo=@SMCo AND vSMAgreement.Agreement=@Agreement AND vSMAgreement.Revision=@NextRevision),0) <> 0)
			BEGIN
				/* Update Agreement price for rounding */
				UPDATE vSMAgreement SET AgreementPrice = AgreementPrice+(@TotalAmountAmend-AgreementPrice-ISNULL(SumPricingPrice,0)) FROM vSMAgreement
					LEFT JOIN (SELECT SMCo, Agreement, Revision, SUM(PricingPrice) SumPricingPrice FROM vSMAgreementService WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND PricingMethod='P' AND BilledSeparately='N' GROUP BY SMCo, Agreement, Revision)
					AgreementServices ON AgreementServices.SMCo=vSMAgreement.SMCo AND AgreementServices.Agreement=vSMAgreement.Agreement AND AgreementServices.Revision=vSMAgreement.Revision
					WHERE vSMAgreement.SMCo=@SMCo AND vSMAgreement.Agreement=@Agreement AND vSMAgreement.Revision=@NextRevision
			END 
			ELSE 
			/* Update the Service item if the Agreement has no price */
			BEGIN 
		
				/* Update the first service for the SMCo, Agreement, Next Revision where the Pricing Price <> 0 */
				UPDATE vSMAgreementService
				SET PricingPrice = PricingPrice - (@NewPricingPriceTotal - @TotalAmountAmend)
				FROM vSMAgreementService	WHERE SMAgreementServiceID = (	SELECT	TOP(1) SMAgreementServiceID 
																			FROM	vSMAgreementService 
																			WHERE   SMCo		= @SMCo AND Agreement	= @Agreement AND Revision	= @NextRevision AND PricingMethod = 'P' AND BilledSeparately = 'N' AND PricingPrice <> 0) 
			
			END 
		
		END  
		/* Update the service price on services that have separate billings based on services billing schedule. */
		UPDATE vSMAgreementService SET PricingPrice = ISNULL(Billings.BillingTotal,0)
		FROM vSMAgreementService 
		LEFT JOIN (SELECT SMCo, Agreement, Revision, Service, SUM(BillingAmount) BillingTotal FROM vSMAgreementBillingSchedule WHERE SMCo=@SMCo AND Agreement=@Agreement AND Revision=@NextRevision AND Service IS NOT NULL AND BillingType='S' GROUP BY SMCo, Agreement, Revision, Service) Billings
		ON Billings.SMCo=vSMAgreementService.SMCo AND Billings.Agreement=vSMAgreementService.Agreement AND Billings.Revision=vSMAgreementService.Revision AND Billings.Service=vSMAgreementService.Service
		WHERE vSMAgreementService.SMCo=@SMCo AND vSMAgreementService.Agreement=@Agreement AND vSMAgreementService.Revision=@NextRevision AND vSMAgreementService.PricingMethod='P' AND vSMAgreementService.BilledSeparately='Y'	
	
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SET @msg = ERROR_MESSAGE()
		RETURN 1
	END CATCH

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementAmendmentCreate] TO [public]
GO
