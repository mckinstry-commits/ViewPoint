SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 03/05/11
-- Description:	Validate agreement before activation.
--
-- Modified:	Dan K 02/25/13 - TFS-40937 - add validation for Revenue Deferral
--				Dan K 03/07/13 - TFS-40937 - adjusted validation logic to use functions for simplification
--				Matthew B 5/1/13 - TFS 43397 - Added validation for sum of split prices matching pricing price from services
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementActivationValidate]
	@SMCo bCompany, @Agreement varchar(15), @Revision int, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT SMAgreement.[Description], SMAgreement.[Status], SMAgreement.CustGroup, SMAgreement.Customer, ARCM.Name AS CustomerName, SMAgreement.EffectiveDate, SMAgreement.ExpirationDate, SMAgreement.DateActivated, SMAgreement.AgreementType, SMAgreement.RevisionType, SMAgreement.PreviousRevision
	FROM dbo.SMAgreement
		INNER JOIN dbo.ARCM ON SMAgreement.CustGroup = ARCM.CustGroup AND SMAgreement.Customer = ARCM.Customer
	WHERE SMCo = @SMCo AND 
		  Agreement = @Agreement AND 
		  Revision = @Revision
	
	DECLARE @OriginalEffectiveDate bDate, 
			@EffectiveDate bDate, 
			@NonExpiring bYN, 
			@PreviousExpirationDate bDate, 
			@ExpirationDate bDate, 
			@AgreementPrice bDollar, 
			@RevisionType tinyint, 
			@PreviousRevision int, 
			@CustGroup bGroup, 
			@Customer bCustomer, 
			@AgreementType varchar(15), 
			@AgreementTypeActive bYN, 
			@RateTemplateActive bYN, 
			@CustomerActive bYN,
			@RevenueRecognition char(1)
	
	SELECT  @EffectiveDate = SMAgreementExtended.EffectiveDate, 
		@NonExpiring = SMAgreementExtended.NonExpiring, 
		@ExpirationDate = SMAgreementExtended.ExpirationDate, 
		@AgreementPrice = SMAgreementExtended.AgreementPrice, 
		@RevisionType = SMAgreementExtended.RevisionType, 
		@PreviousRevision = SMAgreementExtended.PreviousRevision,
		@CustGroup = SMAgreementExtended.CustGroup,
		@Customer = SMAgreementExtended.Customer,
		@OriginalEffectiveDate = SMAgreementOriginal.EffectiveDate,
		@PreviousExpirationDate = SMAgreementPrevious.ExpirationDate,
		@AgreementType = SMAgreementExtended.AgreementType,
		@AgreementTypeActive = SMAgreementType.Active,
		@CustomerActive = SMCustomer.Active,
		@RateTemplateActive = SMRateTemplate.Active, 
		@RevenueRecognition = SMAgreementExtended.RevenueRecognition
	FROM dbo.SMAgreementExtended
	LEFT JOIN SMAgreement SMAgreementOriginal 
		ON SMAgreementExtended.SMCo = SMAgreementOriginal.SMCo 
		AND SMAgreementExtended.Agreement = SMAgreementOriginal.Agreement 
		AND SMAgreementExtended.OriginalRevision = SMAgreementOriginal.Revision
	LEFT JOIN SMAgreement SMAgreementPrevious 
		ON SMAgreementExtended.SMCo = SMAgreementPrevious.SMCo 
		AND SMAgreementExtended.Agreement = SMAgreementPrevious.Agreement 
		AND SMAgreementExtended.PreviousRevision = SMAgreementPrevious.Revision
	LEFT JOIN SMAgreementType 
		ON SMAgreementExtended.SMCo = SMAgreementType.SMCo 
		AND SMAgreementExtended.AgreementType = SMAgreementType.AgreementType
	LEFT JOIN SMCustomer
		ON SMAgreementExtended.SMCo = SMCustomer.SMCo
		AND SMAgreementExtended.CustGroup = SMCustomer.CustGroup
		AND SMAgreementExtended.Customer = SMCustomer.Customer
	LEFT JOIN SMRateTemplate
		ON SMAgreementExtended.SMCo = SMRateTemplate.SMCo 
		AND SMAgreementExtended.RateTemplate = SMRateTemplate.RateTemplate
	WHERE SMAgreementExtended.SMCo = @SMCo 
		AND SMAgreementExtended.Agreement = @Agreement 
		AND SMAgreementExtended.Revision = @Revision 
		
	IF @EffectiveDate IS NULL
	BEGIN
		SET @msg = 'Effective date must be supplied.'
		RETURN 1
	END
	
	IF @RevisionType=2 AND @EffectiveDate > @PreviousExpirationDate
	BEGIN
		SET @msg = 'Effective date must be within term of revision being amended.'
		RETURN 1
	END
	
	IF @AgreementType IS NULL
	BEGIN
		SET @msg = 'Agreement type must be supplied.'
		RETURN 1
	END
	
	IF @AgreementTypeActive = 'N'
	BEGIN
		SET @msg = 'Agreement type is not active.'
		RETURN 1
	END
	
	IF @CustomerActive = 'N'
	BEGIN
		SET @msg = 'Customer is not active.'
		RETURN 1
	END
	
	IF @RateTemplateActive = 'N'
	BEGIN
		SET @msg = 'Rate template is not active.'
		RETURN 1
	END

	IF @NonExpiring = 'N'
	BEGIN
		IF @ExpirationDate IS NULL
		BEGIN
			SET @msg = 'Expiration date must be supplied for expiring agreements.'
			RETURN 1
		END
		
		IF @ExpirationDate <= @EffectiveDate
		BEGIN
			SET @msg = 'Expiration date must be after the effective date.'
			RETURN 1
		END
		
		/* Amendments (Revision Type=2) can overlap the revision that they are amending. */
		IF EXISTS(SELECT 1 
			FROM dbo.SMAgreementExtended
			WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision <> @Revision AND NonExpiring = 'N' AND DateActivated IS NOT NULL 
			AND (@EffectiveDate BETWEEN EffectiveDate AND EndDate OR @ExpirationDate BETWEEN EffectiveDate AND EndDate)
			AND (NOT @RevisionType=2 OR NOT Revision=@PreviousRevision)
			)
		BEGIN
			SET @msg = 'Non-expiring active agreements cannot have overlapping terms.'
			RETURN 1
		END		
		
		IF EXISTS
		(
			SELECT 1 FROM vSMAgreementService
			CROSS APPLY
			(
				SELECT SUM(Amount) as Amount FROM vSMFlatPriceRevenueSplit
				LEFT JOIN vSMEntity 
				ON 
					vSMEntity.EntitySeq = vSMFlatPriceRevenueSplit.EntitySeq AND vSMEntity.SMCo = vSMFlatPriceRevenueSplit.SMCo
				WHERE
					vSMEntity.SMCo = vSMAgreementService.SMCo AND vSMEntity.Agreement = vSMAgreementService.Agreement AND vSMEntity.AgreementRevision = vSMAgreementService.Revision AND vSMEntity.AgreementService = vSMAgreementService.Service
			) SplitRev
			WHERE 
				SMCo = @SMCo AND Agreement=@Agreement AND Revision = @Revision AND
				vSMAgreementService.PricingPrice <> SplitRev.Amount
		) 			
		BEGIN
			SET @msg = 'Flat rate split amounts must match the price from the agreement service.'
			RETURN 1
		END				
		
		
		/* Amendments (Revision Type=2) must have an effective date that is greater than the effective date of the previous revision. */
		IF EXISTS(SELECT 1 FROM vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision
					AND @RevisionType=2 AND EffectiveDate>=@EffectiveDate)
		BEGIN
			SET @msg = 'An amendment/revision must have an effective date after the effective date of the revision being amended.'
			RETURN 1
		END
		
		IF EXISTS(SELECT 1 FROM dbo.SMAgreementBillingSchedule WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Date] IS NULL)
		BEGIN
			SET @msg = 'All agreement/work schedule billings must have a date.'
			RETURN 1
		END
		
		-- For Amendment Activation allow dates between effective date of original revision and the current expiration date.
		IF EXISTS(SELECT 1 FROM dbo.SMAgreementBillingSchedule 
			WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision 
			AND (([Date] < @EffectiveDate AND NOT @RevisionType=2) OR ([Date] < @OriginalEffectiveDate AND @RevisionType=2)))
		BEGIN
			SET @msg = 'All agreement/work schedule billing dates must be greater than or equal to the agreement effective date.'
			RETURN 1
		END
		
		IF EXISTS(SELECT 1 FROM dbo.SMAgreementBillingSchedule WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Date] > @ExpirationDate)
		BEGIN
			SET @msg = 'All agreement/work schedule billing dates must be less than or equal to the agreement expiration date.'
			RETURN 1
		END
		
		-- Sum of agreement billing schedule = agreement price + sum of periodic services not billed separately
		IF (SELECT BillingTotalRemaining FROM vfSMGetTotalRemainingAgreement(@SMCo, @Agreement, @Revision)) <> 0 
		BEGIN
			SET @msg = 'The agreement billing schedule sum must match the agreement price plus the sum of the periodic work schedule prices.'
			RETURN 1
		END
		
		-- Periodic services billed separately price = sum of billings billing amount
		IF EXISTS(SELECT 1
			FROM dbo.SMAgreementService SMAS
				CROSS APPLY vfSMGetTotalRemainingService (SMAS.SMCo, SMAS.Agreement, SMAS.Revision, SMAS.Service) RS
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND BilledSeparately = 'Y' AND RS.BillingTotalRemaining <> 0)
		BEGIN
			SET @msg = 'The periodic work schedules being billed separately must have the sum of the billing match the work schedule price.'
			RETURN 1
		END
		
		IF @RevenueRecognition = 'S'
		BEGIN
			-- All Revenue Deferral items must have a date 
			IF EXISTS(SELECT 1 FROM dbo.SMAgreementRevenueDeferral WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Date] IS NULL)
			BEGIN
				SET @msg = 'All Revenue Deferrals must have a date.'
				RETURN 1
			END

			-- For Amendment Activation allow Revenue Deferral dates between effective date of original revision and the current expiration date.
			IF EXISTS(SELECT 1 FROM dbo.SMAgreementRevenueDeferral
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision 
				AND (([Date] < @EffectiveDate AND NOT @RevisionType=2) OR ([Date] < @OriginalEffectiveDate AND @RevisionType=2)))
			BEGIN
				SET @msg = 'All Revenue Deferral dates must be greater than or equal to the agreement effective date.'
				RETURN 1
			END
			
			-- Revenue Deferral dates cannot exceed the expiration date of the Agreement
			IF EXISTS(SELECT 1 FROM dbo.SMAgreementRevenueDeferral WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Date] > @ExpirationDate)
			BEGIN
				SET @msg = 'All agreement/work schedule billing dates must be less than or equal to the agreement expiration date.'
				RETURN 1
			END
			
			-- Sum of agreement revenue deferral = agreement price + sum of periodic services not billed separately
			IF (SELECT DeferralTotalRemaining FROM vfSMGetTotalRemainingAgreement(@SMCo, @Agreement, @Revision)) <> 0 
			BEGIN
				SET @msg = 'The agreement revenue deferral sum must match the agreement price plus the sum of the periodic work schedule prices.'
				RETURN 1
			END
			
			-- Periodic services billed separately price = sum of revenue deferrals amount
			IF EXISTS(SELECT 1
				FROM dbo.SMAgreementService SMAS
				CROSS APPLY vfSMGetTotalRemainingService (SMAS.SMCo, SMAS.Agreement, SMAS.Revision, SMAS.Service) RS
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND BilledSeparately = 'Y' AND RS.DeferralTotalRemaining <> 0)
					
			BEGIN
				SET @msg = 'The periodic work schedules being billed separately must have the sum of the billings match the revenue deferrals.'
				RETURN 1
			END
		END 
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM dbo.SMAgreementService WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND PricingMethod = 'P' AND PricingFrequency IS NULL)
		BEGIN
			SET @msg = 'Because the agreement is non-expiring all work schedules with periodic pricing must supply a frequency.'
			RETURN 1
		END
	END

	-- Serivces are not required because work orders can be associated to an agreement
	
	IF EXISTS(SELECT 1 FROM dbo.SMAgreementService WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND [Description] IS NULL)
	BEGIN
		SET @msg = 'All work schedules must have a description.'
		RETURN 1
	END
	
	-- Validate that all services have a call type
	IF EXISTS(SELECT 1 FROM dbo.SMAgreementService WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision AND CallType IS NULL)
	BEGIN
		SET @msg = 'All work schedules must have a call type.'
		RETURN 1
	END
	
	IF EXISTS(
		SELECT 1 FROM dbo.SMAgreementService
			INNER JOIN dbo.SMServiceSite ON SMAgreementService.SMCo = SMServiceSite.SMCo 
			AND SMAgreementService.ServiceSite = SMServiceSite.ServiceSite
		WHERE SMAgreementService.SMCo = @SMCo 
			AND SMAgreementService.Agreement = @Agreement 
			AND SMAgreementService.Revision = @Revision 
			AND (SMServiceSite.CustGroup <> @CustGroup OR SMServiceSite.Customer <> @Customer))
	BEGIN
		SET @msg = 'A work schedule with a service site that no longer belongs to the agreement''s customer exists.'
		RETURN 1
	END
	
	-- Checks if the SMServiceSite is not active
	IF EXISTS(
		SELECT 1 FROM dbo.SMAgreementService
			INNER JOIN dbo.SMServiceSite ON SMAgreementService.SMCo = SMServiceSite.SMCo 
			AND SMAgreementService.ServiceSite = SMServiceSite.ServiceSite
		WHERE SMAgreementService.SMCo = @SMCo 
			AND SMAgreementService.Agreement = @Agreement 
			AND SMAgreementService.Revision = @Revision
			AND SMServiceSite.Active = 'N')
	BEGIN
		SET @msg = 'A service site on the work schedule is not active.'
		RETURN 1
	END
	
	-- Checks if the SMCallType is not active
	IF EXISTS(
		SELECT 1 FROM dbo.SMAgreementService
			INNER JOIN dbo.SMCallType ON SMAgreementService.SMCo = SMCallType.SMCo 
			AND SMAgreementService.CallType = SMCallType.CallType
		WHERE SMAgreementService.SMCo = @SMCo 
			AND SMAgreementService.Agreement = @Agreement 
			AND SMAgreementService.Revision = @Revision
			AND SMCallType.Active = 'N')
	BEGIN
		SET @msg = 'A call type on the work schedule is not active.'
		RETURN 1
	END
	
	-- Checks if the SMServiceCenter is not active
	IF EXISTS(
		SELECT 1 FROM dbo.SMAgreementService
			INNER JOIN dbo.SMServiceCenter ON SMAgreementService.SMCo = SMServiceCenter.SMCo 
			AND SMAgreementService.ServiceCenter = SMServiceCenter.ServiceCenter
		WHERE SMAgreementService.SMCo = @SMCo 
			AND SMAgreementService.Agreement = @Agreement 
			AND SMAgreementService.Revision = @Revision
			AND SMServiceCenter.Active = 'N')
	BEGIN
		SET @msg = 'A service center override on the work schedule is not active.'
		RETURN 1
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementActivationValidate] TO [public]
GO
