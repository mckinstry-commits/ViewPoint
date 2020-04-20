SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/21/12
-- Description:	
-- Modified:	Dan K 02/25/13 TFS-40937 - Added the Revenue recognition flag to renewed agreements
-- Modified:	Matthew B 4/26/13 TFS-48149 - Add copy of split lines for services for renewed agreements
-- Modified:	matthew B 5/2/13 TFS 48972 - Add copy for Divisoin
-- Modified:	Dan K 07/05/13 TFS-54778 - Add Taxable status to copy of Revenue Splits
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementRenew]
	@SMCo bCompany, @Agreement varchar(15), @Revision int, @RenewalRevision int = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @OriginalRevision int, @EffectiveDate bDate, @ExpirationDate bDate, @RevenueRecognition char(1), @AgreementPrice bDollar, @NewAgreementLength int

	IF EXISTS(SELECT 1 FROM dbo.SMAgreementExtended WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND RevisionStatus NOT IN (2,3)/*2 is active, 3 is expired*/)
	BEGIN
		SELECT @msg = 'The revision being renewed must be active or expired.'
		RETURN 1
	END

	IF EXISTS(SELECT 1 FROM dbo.SMAgreementExtended WHERE SMCo = @SMCo AND Agreement = @Agreement AND PreviousRevision = @Revision AND RevisionStatus <> 1/*Cancelled status*/)
	BEGIN
		SELECT @msg = 'Only one amendment/renewal can be created per agreement revision.'
		RETURN 1
	END

	DECLARE @AllRevisionsAgreementService TABLE (SMAgreementServiceID bigint, SMCo bCompany NOT NULL, Agreement varchar(15) NOT NULL, Revision int NOT NULL, [Service] int NOT NULL, PricingPrice bDollar NULL)
	
	;WITH AgreementService
	AS
	(
		SELECT vSMAgreementService.*, CASE WHEN vSMAgreement.RevisionType = 2 /* Type is for amendments*/ THEN vSMAgreement.PreviousRevision END PreviousRevision
		FROM dbo.vSMAgreement
			INNER JOIN dbo.vSMAgreementService ON vSMAgreement.SMCo = vSMAgreementService.SMCo AND vSMAgreement.Agreement = vSMAgreementService.Agreement AND vSMAgreement.Revision = vSMAgreementService.Revision
	),
	AllRevisionsAgreementService
	AS
	(
		SELECT *
		FROM AgreementService
		WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
		UNION ALL
		SELECT AgreementService.*
		FROM AgreementService
			INNER JOIN AllRevisionsAgreementService ON AgreementService.SMCo = AllRevisionsAgreementService.SMCo AND AgreementService.Agreement = AllRevisionsAgreementService.Agreement AND AgreementService.Revision = AllRevisionsAgreementService.PreviousRevision
				AND AgreementService.[Service] = AllRevisionsAgreementService.[Service] AND AllRevisionsAgreementService.WasCopied = 1
	)
	INSERT @AllRevisionsAgreementService
	SELECT SMAgreementServiceID, SMCo, Agreement, Revision, [Service], PricingPrice
	FROM AllRevisionsAgreementService

	SELECT @OriginalRevision = SMAgreementExtended.OriginalRevision,
		--The calculations below depend on the variables being set in this order so don't change it.
		--The agreement length is figured in months and 1 month is added on since something like 1/1/12 - 12/31/12 should really be 12 months.
		@NewAgreementLength = DATEDIFF(month, vSMAgreement.EffectiveDate, SMAgreementExtended.ExpirationDate) + 1,
		@EffectiveDate = DATEADD(day, 1, SMAgreementExtended.ExpirationDate),
		--By adding a day and then subtracting after shifting it by the agreement length when the expiration date is the last day of the
		--month then the renewal's expiration day will also be on the last day of the month.
		@ExpirationDate = DATEADD(day, -1, DATEADD(month, @NewAgreementLength, DATEADD(day, 1, SMAgreementExtended.ExpirationDate))),
		@RevenueRecognition = SMAgreementExtended.RevenueRecognition
	FROM dbo.SMAgreementExtended
		INNER JOIN dbo.vSMAgreement ON SMAgreementExtended.SMCo = vSMAgreement.SMCo AND SMAgreementExtended.Agreement = vSMAgreement.Agreement AND SMAgreementExtended.OriginalRevision = vSMAgreement.Revision
	WHERE SMAgreementExtended.SMCo = @SMCo AND SMAgreementExtended.Agreement = @Agreement AND SMAgreementExtended.Revision = @Revision

	--Grab the sums of all revisions tied to the original
	SET @AgreementPrice = (SELECT SUM(AgreementPrice) FROM SMAgreementExtended WHERE SMCo = @SMCo AND Agreement = @Agreement AND OriginalRevision = @OriginalRevision AND RevisionStatus IN (2,3,4)) --Make sure to exclude the quote revisions that were created and never activated.

	SELECT @RenewalRevision = MAX(Revision) + 1 FROM dbo.vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement

	--Create the new quote
	INSERT dbo.vSMAgreement (SMCo, Agreement, Revision, RevisionType, [Description], CustGroup, Customer, EffectiveDate, NonExpiring, ExpirationDate, AutoRenew, RateTemplate, AgreementPrice, ReportID, AgreementType, CustomerPO, AlternateAgreement, PreviousRevision, DateCreated, RevenueRecognition)
	SELECT SMCo, Agreement, @RenewalRevision, 3 RevisionType /*3 represents renewals*/, [Description], CustGroup, Customer, @EffectiveDate, NonExpiring, @ExpirationDate, AutoRenew, RateTemplate, @AgreementPrice, ReportID, AgreementType, CustomerPO, AlternateAgreement, Revision, dbo.vfDateOnly(), RevenueRecognition
	FROM dbo.vSMAgreement
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision

	--Copy services from the previous revision. We only care about the services from the last revision since this is the most
	--up to date list of services that was agreed upon.
	INSERT dbo.vSMAgreementService (SMCo, Agreement, Revision, [Service], [Description], ServiceSite, Division, CallType, ServiceCenter, TaxSource, PricingMethod, PricingFrequency, PricingPrice, BilledSeparately, PricingRateTemplate, ScheOptContactBeforeScheduling, ScheOptDueType, ScheOptDays, RecurringPatternType, DailyType, DailyEveryDays, WeeklyEveryWeeks, WeeklyEverySun, WeeklyEveryMon, WeeklyEveryTue, WeeklyEveryWed, WeeklyEveryThu, WeeklyEveryFri, WeeklyEverySat, MonthlyType, MonthlyDay, MonthlyDayEveryMonths, MonthlyEveryOrdinal, MonthlyEveryDay, MonthlyEveryMonths, MonthlySelectOrdinal, MonthlySelectDay, MonthlyJan, MonthlyFeb, MonthlyMar, MonthlyApr, MonthlyMay, MonthlyJun, MonthlyJul, MonthlyAug, MonthlySep, MonthlyOct, MonthlyNov, MonthlyDec, YearlyType, YearlyEveryYear, YearlyEveryDateMonth, YearlyEveryDateMonthDay, YearlyEveryDayOrdinal, YearlyEveryDayDay, YearlyEveryDayMonth)
	SELECT SMCo, Agreement, @RenewalRevision, [Service], [Description], ServiceSite, Division, CallType, ServiceCenter, TaxSource, PricingMethod, PricingFrequency, PricingPrice, BilledSeparately, PricingRateTemplate, ScheOptContactBeforeScheduling, ScheOptDueType, ScheOptDays, RecurringPatternType, DailyType, DailyEveryDays, WeeklyEveryWeeks, WeeklyEverySun, WeeklyEveryMon, WeeklyEveryTue, WeeklyEveryWed, WeeklyEveryThu, WeeklyEveryFri, WeeklyEverySat, MonthlyType, MonthlyDay, MonthlyDayEveryMonths, MonthlyEveryOrdinal, MonthlyEveryDay, MonthlyEveryMonths, MonthlySelectOrdinal, MonthlySelectDay, MonthlyJan, MonthlyFeb, MonthlyMar, MonthlyApr, MonthlyMay, MonthlyJun, MonthlyJul, MonthlyAug, MonthlySep, MonthlyOct, MonthlyNov, MonthlyDec, YearlyType, YearlyEveryYear, YearlyEveryDateMonth, YearlyEveryDateMonthDay, YearlyEveryDayOrdinal, YearlyEveryDayDay, YearlyEveryDayMonth
	FROM dbo.vSMAgreementService
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	
	--Copy Service Task from the previous revision. We only care about the services from the last revision since this is the most
	--up to date list of services that was agreed upon.
	INSERT dbo.vSMAgreementServiceTask (SMCo, Agreement, Revision, [Service], [Task], [SMStandardTask], [Name], [Description], [ServiceItem])
	SELECT SMCo, Agreement, @RenewalRevision, [Service], [Task], [SMStandardTask], [Name], [Description], [ServiceItem]
	FROM dbo.vSMAgreementServiceTask
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
	
	--Update periodic services with the sum of prices from the services that have been copied.
	UPDATE vSMAgreementService
	SET PricingPrice = PricingPriceSum
	FROM dbo.vSMAgreementService
		CROSS APPLY (SELECT SUM(PricingPrice) PricingPriceSum FROM @AllRevisionsAgreementService WHERE [Service] = vSMAgreementService.[Service]) ServicePriceSum
	WHERE vSMAgreementService.SMCo = @SMCo AND vSMAgreementService.Agreement = @Agreement AND vSMAgreementService.Revision = @RenewalRevision AND vSMAgreementService.PricingMethod = 'P'
	
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
		,@RenewalRevision
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
		,Taxable
		,Notes
	)
	SELECT
		 vSMFlatPriceRevenueSplit.SMCo
		,NewRevEntity.EntitySeq
		,vSMFlatPriceRevenueSplit.Seq
		,vSMFlatPriceRevenueSplit.CostTypeCategory
		,vSMFlatPriceRevenueSplit.CostType
		,vSMFlatPriceRevenueSplit.Amount
		,vSMFlatPriceRevenueSplit.PricePercent
		,vSMFlatPriceRevenueSplit.Taxable
		,vSMFlatPriceRevenueSplit.Notes
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
			vSMAgreementService.SMCo = NewRevEntity.SMCo AND vSMAgreementService.Agreement= NewRevEntity.Agreement AND @RenewalRevision = NewRevEntity.AgreementRevision AND vSMAgreementService.Service = NewRevEntity.AgreementService
	WHERE
		vSMAgreementService.SMCo = @SMCo AND
		vSMAgreementService.Agreement = @Agreement AND
		vSMAgreementService.Revision = @Revision 	

	--Copy all the billings from all agreements tied to the original. The service billing will be copied next.
	;WITH PreviousRevisionBillings
	AS
	(
		SELECT vSMAgreementBillingSchedule.*, SUM(vSMAgreementBillingSchedule.BillingAmount) OVER(PARTITION BY vSMAgreementBillingSchedule.Revision) BillingAmountSum, MIN(vSMAgreementBillingSchedule.Billing) OVER(PARTITION BY vSMAgreementBillingSchedule.Revision) RevisionFirstBilling, DeriveRemovedServicesPrice.RemovedServicesPrice
		FROM dbo.SMAgreementExtended
			CROSS APPLY (SELECT SUM(PricingPrice) RemovedServicesPrice FROM dbo.vSMAgreementService WHERE SMCo = SMAgreementExtended.SMCo AND Agreement = SMAgreementExtended.Agreement AND Revision = SMAgreementExtended.Revision AND PricingMethod = 'P' AND BilledSeparately = 'N' AND SMAgreementServiceID NOT IN (SELECT SMAgreementServiceID FROM @AllRevisionsAgreementService)) DeriveRemovedServicesPrice
			INNER JOIN dbo.vSMAgreementBillingSchedule ON SMAgreementExtended.SMCo = vSMAgreementBillingSchedule.SMCo AND SMAgreementExtended.Agreement = vSMAgreementBillingSchedule.Agreement AND SMAgreementExtended.Revision = vSMAgreementBillingSchedule.Revision AND vSMAgreementBillingSchedule.BillingType='S'
		WHERE SMAgreementExtended.SMCo = @SMCo AND SMAgreementExtended.Agreement = @Agreement AND SMAgreementExtended.OriginalRevision = @OriginalRevision AND SMAgreementExtended.RevisionStatus IN (2,3,4) --Make sure to exclude the quote revisions that were created and never activated.
			AND vSMAgreementBillingSchedule.[Service] IS NULL
	),
	--For all the services that aren't billed seperately and didn't carry over to the renewal reduce the services price in the billing schedule by distributing its amount.
	DistributeRemovedServiceBillingAmountCTE
	AS
	(
		SELECT *, CAST(ISNULL(CASE WHEN BillingAmountSum = 0 THEN 0 ELSE BillingAmount / BillingAmountSum * RemovedServicesPrice END, 0) AS numeric(12, 2)) DistributedRemovedServicesBillingAmount
		FROM PreviousRevisionBillings
	),
	CalculateNewBillingAmountCTE
	AS
	(
		--Handle rounding by figuring out the difference between the distributed billing amount and the sum of the services removed
		SELECT *, BillingAmount - DistributedRemovedServicesBillingAmount - ISNULL(CASE WHEN Billing = RevisionFirstBilling THEN RemovedServicesPrice - (SELECT SUM(DistributedRemovedServicesBillingAmount) FROM DistributeRemovedServiceBillingAmountCTE DistributeRemovedServiceBillingAmountSum WHERE Revision = DistributeRemovedServiceBillingAmountCTE.Revision) END, 0) NewBillingAmount
		FROM DistributeRemovedServiceBillingAmountCTE
	),
	--Derive the new tax basis by taxing the service's getting a rate from the old billing amount and the new billing amount and then multiplying the rate by the taxbasis.
	CalculateNewTaxBasisCTE
	AS
	(
		SELECT *, CASE WHEN BillingAmount = 0 THEN 0 ELSE NewBillingAmount / BillingAmount * TaxBasis END NewTaxBasis
		FROM CalculateNewBillingAmountCTE
	)
	INSERT dbo.vSMAgreementBillingSchedule (SMCo, Agreement, Revision, Billing, [Date], BillingAmount, TaxGroup, TaxType, TaxCode, TaxBasis, BillingType)
	SELECT @SMCo, @Agreement, @RenewalRevision, ROW_NUMBER() OVER(ORDER BY [Date]), DATEADD(month, @NewAgreementLength, [Date]), NewBillingAmount, TaxGroup, TaxType, TaxCode, NewTaxBasis, BillingType
	FROM CalculateNewTaxBasisCTE

	--Copy all service billings from services on the revision being renewed and all services that have been copied
	--forward to the revision being renewed.
	INSERT dbo.vSMAgreementBillingSchedule (SMCo, Agreement, Revision, [Service], Billing, [Date], BillingAmount, TaxGroup, TaxType, TaxCode, TaxBasis, TaxAmount, BillingType)
	SELECT @SMCo, @Agreement, @RenewalRevision, vSMAgreementBillingSchedule.[Service], ROW_NUMBER() OVER(PARTITION BY vSMAgreementBillingSchedule.[Service] ORDER BY vSMAgreementBillingSchedule.[Date]), DATEADD(month, @NewAgreementLength, vSMAgreementBillingSchedule.[Date]), vSMAgreementBillingSchedule.BillingAmount,
		vSMAgreementBillingSchedule.TaxGroup, vSMAgreementBillingSchedule.TaxType, vSMAgreementBillingSchedule.TaxCode, vSMAgreementBillingSchedule.TaxBasis, vSMAgreementBillingSchedule.TaxAmount, vSMAgreementBillingSchedule.BillingType
	FROM @AllRevisionsAgreementService AllRevisionsAgreementService
		INNER JOIN dbo.vSMAgreementBillingSchedule ON AllRevisionsAgreementService.SMCo = vSMAgreementBillingSchedule.SMCo AND AllRevisionsAgreementService.Agreement = vSMAgreementBillingSchedule.Agreement AND AllRevisionsAgreementService.Revision = vSMAgreementBillingSchedule.Revision AND AllRevisionsAgreementService.[Service] = vSMAgreementBillingSchedule.[Service] AND vSMAgreementBillingSchedule.BillingType = 'S'

	--Update the tax amount from the tax basis
	DECLARE @UpdateTaxAmountCursor cursor, @SMAgreementBillingScheduleID bigint, @TaxGroup bGroup, @TaxType tinyint, @TaxCode bTaxCode, @TaxRate bRate, @rcode int
	
	SET @UpdateTaxAmountCursor = CURSOR LOCAL FAST_FORWARD FOR
	SELECT SMAgreementBillingScheduleID, TaxGroup, TaxType, TaxCode
	FROM dbo.vSMAgreementBillingSchedule
	WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @RenewalRevision AND TaxCode IS NOT NULL AND BillingType = 'S'
	
	OPEN @UpdateTaxAmountCursor

	UpdateTaxAmount_FetchNext:
	BEGIN
		FETCH NEXT FROM @UpdateTaxAmountCursor
		INTO @SMAgreementBillingScheduleID, @TaxGroup, @TaxType, @TaxCode

		IF @@FETCH_STATUS = 0
		BEGIN
			EXEC @rcode = dbo.vspHQTaxCodeVal @taxgroup = @TaxGroup, @taxcode = @TaxCode, @taxtype = @TaxType, @taxrate = @TaxRate OUTPUT, @msg = @msg OUTPUT
			IF @rcode <> 0
 			BEGIN
 				EXEC dbo.vspCleanupCursor @Cursor = @UpdateTaxAmountCursor
 				RETURN 1
 			END
			
			UPDATE dbo.vSMAgreementBillingSchedule 
			SET	TaxAmount = ISNULL(TaxBasis * @TaxRate, 0)
			WHERE SMAgreementBillingScheduleID = @SMAgreementBillingScheduleID
		
			GOTO UpdateTaxAmount_FetchNext
		END
	END
	
	EXEC dbo.vspCleanupCursor @Cursor = @UpdateTaxAmountCursor

	IF @RevenueRecognition = 'S'
	BEGIN
		--Copy all the deferrals from all agreements tied to the original. The service deferrals will be copied next.
		;WITH PreviousRevisionDeferrals
		AS
		(
			SELECT vSMAgreementRevenueDeferral.*,
				SUM(vSMAgreementRevenueDeferral.Amount) OVER(PARTITION BY vSMAgreementRevenueDeferral.Revision) DeferralAmountSum,
				MIN(vSMAgreementRevenueDeferral.Deferral) OVER(PARTITION BY vSMAgreementRevenueDeferral.Revision) RevisionFirstDeferral,
				DeriveRemovedServicesPrice.RemovedServicesPrice
			FROM dbo.SMAgreementExtended
				CROSS APPLY
				(
					SELECT SUM(PricingPrice) RemovedServicesPrice
					FROM dbo.vSMAgreementService
					WHERE SMCo = SMAgreementExtended.SMCo AND Agreement = SMAgreementExtended.Agreement AND Revision = SMAgreementExtended.Revision AND PricingMethod = 'P' AND BilledSeparately = 'N' AND SMAgreementServiceID NOT IN (SELECT SMAgreementServiceID FROM @AllRevisionsAgreementService)
				) DeriveRemovedServicesPrice
				INNER JOIN dbo.vSMAgreementRevenueDeferral ON SMAgreementExtended.SMCo = vSMAgreementRevenueDeferral.SMCo AND SMAgreementExtended.Agreement = vSMAgreementRevenueDeferral.Agreement AND SMAgreementExtended.Revision = vSMAgreementRevenueDeferral.Revision
			WHERE SMAgreementExtended.SMCo = @SMCo AND SMAgreementExtended.Agreement = @Agreement AND SMAgreementExtended.OriginalRevision = @OriginalRevision AND SMAgreementExtended.RevisionStatus IN (2, 3, 4) --Make sure to exclude the quote revisions that were created and never activated.
				AND vSMAgreementRevenueDeferral.[Service] IS NULL
		),
		--For all the services that aren't billed seperately and didn't carry over to the renewal reduce the services price in the deferrals by distributing its amount.
		DistributeRemovedServiceDeferralAmountCTE
		AS
		(
			SELECT *, CAST(ISNULL(CASE WHEN DeferralAmountSum = 0 THEN 0 ELSE Amount / DeferralAmountSum * RemovedServicesPrice END, 0) AS numeric(12, 2)) DistributedRemovedServicesDeferralAmount
			FROM PreviousRevisionDeferrals
		),
		CalculateNewDeferralAmountCTE
		AS
		(
			--Handle rounding by figuring out the difference between the distributed deferral amount and the sum of the services removed
			SELECT *, Amount - DistributedRemovedServicesDeferralAmount - ISNULL(CASE WHEN Deferral = RevisionFirstDeferral THEN RemovedServicesPrice - (SELECT SUM(DistributedRemovedServicesDeferralAmount) FROM DistributeRemovedServiceDeferralAmountCTE DistributeRemovedServiceDeferralAmountSum WHERE Revision = DistributeRemovedServiceDeferralAmountCTE.Revision) END, 0) NewDeferralAmount
			FROM DistributeRemovedServiceDeferralAmountCTE
		)
		INSERT dbo.vSMAgreementRevenueDeferral (SMCo, Agreement, Revision, Deferral, [Date], Amount)
		SELECT @SMCo, @Agreement, @RenewalRevision, ROW_NUMBER() OVER(ORDER BY [Date]), DATEADD(month, @NewAgreementLength, [Date]), NewDeferralAmount
		FROM CalculateNewDeferralAmountCTE

		--Copy all service deferrals from services on the revision being renewed and all services that have been copied
		--forward to the revision being renewed.
		INSERT dbo.vSMAgreementRevenueDeferral (SMCo, Agreement, Revision, [Service], Deferral, [Date], Amount)
		SELECT @SMCo, @Agreement, @RenewalRevision, vSMAgreementRevenueDeferral.[Service], ROW_NUMBER() OVER(PARTITION BY vSMAgreementRevenueDeferral.[Service] ORDER BY vSMAgreementRevenueDeferral.[Date]), DATEADD(month, @NewAgreementLength, vSMAgreementRevenueDeferral.[Date]), vSMAgreementRevenueDeferral.Amount
		FROM @AllRevisionsAgreementService AllRevisionsAgreementService
			INNER JOIN dbo.vSMAgreementRevenueDeferral ON AllRevisionsAgreementService.SMCo = vSMAgreementRevenueDeferral.SMCo AND AllRevisionsAgreementService.Agreement = vSMAgreementRevenueDeferral.Agreement AND AllRevisionsAgreementService.Revision = vSMAgreementRevenueDeferral.Revision AND AllRevisionsAgreementService.[Service] = vSMAgreementRevenueDeferral.[Service]
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementRenew] TO [public]
GO
