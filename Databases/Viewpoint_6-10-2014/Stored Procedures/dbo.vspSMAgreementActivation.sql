SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 03/05/11
-- Description:	
-- Modification: Matthew Bradford 3/7/13 Task 42328
-- =============================================
CREATE PROCEDURE [dbo].[vspSMAgreementActivation]
	@SMCo bCompany, 
	@Agreement varchar(15), 
	@Revision int, 
	@DeleteNewWorkOrders bYN = 'N', 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rcode int, @PreviousRevision int, @EffectiveDate smalldatetime, @DateTerminated smalldatetime,
		@RevisionType tinyint, @errmsg varchar(max), @TotalAmountPrevious bDollar, @TotalAmountAmend bDollar

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @Agreement IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement!'
		RETURN 1
	END
	
	IF @Revision  IS NULL
	BEGIN
		SET @msg = 'Missing SM Agreement Revision!'
		RETURN 1
	END
	
	EXEC @rcode = vspSMAgreementActivationValidate @SMCo = @SMCo, @Agreement = @Agreement, @Revision = @Revision, @msg = @errmsg OUTPUT
	IF @rcode <> 0
	BEGIN
		SET @msg = @errmsg
		RETURN @rcode
	END
	ELSE 
	BEGIN
		-- Check to see if this is an activation of an amendment.
		BEGIN TRY
			BEGIN TRAN
			-- Get the effective date of the new revision.
			SELECT @EffectiveDate = EffectiveDate, @PreviousRevision = PreviousRevision, @RevisionType=RevisionType FROM vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @Revision
			IF (@RevisionType = 2)
			BEGIN								
				-- Terminate the previous revision on the day before the effective date of the amendment.
				SET @DateTerminated = DATEADD(D, -1, @EffectiveDate)
			
				EXEC @rcode = vspSMAgreementTerminate @SMCo=@SMCo, @Agreement=@Agreement, @Revision=@PreviousRevision, @DateTerminated=@DateTerminated, @CancelQuote= 'N', @DeleteNewWorkOrders=@DeleteNewWorkOrders, @AmendmentRevision=@Revision, @msg=@msg OUTPUT
				IF (@rcode<>0)
				BEGIN
					ROLLBACK TRAN
					RETURN 1
				END
				
				/* Activate the renewal */
				UPDATE SMAgreement
				SET DateActivated = dbo.vfDateOnly()
				WHERE SMCo = @SMCo AND
					  Agreement = @Agreement AND
					  Revision = @Revision AND
					  DateActivated IS NULL
				
				IF @@rowcount <> 1
				BEGIN
					SET @msg = 'SM Agreement failed to activate!'
					ROLLBACK TRAN
					RETURN 1
				END

				-- Adjust the price of the previous revision, and any periodic prices on services to match what was billed.
				SELECT @TotalAmountPrevious = ISNULL(SUM(BillingAmount), 0)
				FROM dbo.vSMAgreementBillingSchedule
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND Service IS NULL AND BillingType = 'S'

				-- Now remove any scheduled billing dates that have not been invoiced on the previous revision.
				DELETE dbo.vSMAgreementBillingSchedule
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND SMInvoiceID IS NULL AND BillingType = 'S'				
							
				--Delete of amounts remaining on deferrals here.
				--Check for null on the invoiceId here.
				--****************************************************
				--****************************************************
				DELETE vSMAgreementRevenueDeferral
				FROM vSMAgreementRevenueDeferral
				CROSS APPLY
					(
						SELECT SUM(Amount) AS RunningTotal
						FROM vSMAgreementRevenueDeferral SMRevenueDeferral
						WHERE vSMAgreementRevenueDeferral.SMCo = SMRevenueDeferral.SMCo AND 
						vSMAgreementRevenueDeferral.Agreement = SMRevenueDeferral.Agreement AND 
						vSMAgreementRevenueDeferral.Revision = SMRevenueDeferral.Revision AND 
						dbo.vfIsEqual(vSMAgreementRevenueDeferral.[Service], SMRevenueDeferral.[Service]) = 1 AND
						(
							vSMAgreementRevenueDeferral.[Date] > SMRevenueDeferral.[Date] OR 
							(
								vSMAgreementRevenueDeferral.[Date] = SMRevenueDeferral.[Date] AND 
								vSMAgreementRevenueDeferral.Deferral >= SMRevenueDeferral.Deferral
							)
						)
					) DeriveRunningTotal
				 CROSS APPLY
					(
						--For the agreement/service get the sum amount that has not been invoiced. 
						--This is the amount that the deferrals copied to the agreement/service need to sum to.
						SELECT SUM(BillingAmount) BillingAmountSum
						FROM dbo.vSMAgreementBillingSchedule
						WHERE 
						vSMAgreementRevenueDeferral.SMCo = vSMAgreementBillingSchedule.SMCo AND 
						vSMAgreementRevenueDeferral.Agreement = vSMAgreementBillingSchedule.Agreement AND 
						vSMAgreementRevenueDeferral.Revision = vSMAgreementBillingSchedule.Revision AND 
						dbo.vfIsEqual(vSMAgreementRevenueDeferral.[Service], vSMAgreementBillingSchedule.[Service]) =1 AND
						vSMAgreementBillingSchedule.BillingType = 'S' 		
					) DeriveBillingAmountSum
				WHERE 
					vSMAgreementRevenueDeferral.SMCo = @SMCo AND 
					vSMAgreementRevenueDeferral.Agreement = @Agreement AND 
					vSMAgreementRevenueDeferral.Revision = @PreviousRevision AND 
					DeriveRunningTotal.RunningTotal - ISNULL(DeriveBillingAmountSum.BillingAmountSum,0) >= vSMAgreementRevenueDeferral.Amount 
	
				--Update amounts of deferrals

				UPDATE vSMAgreementRevenueDeferral SET Amount =
				 (ISNULL(DeriveBillingAmountSum.BillingAmountSum,0)-DeriveRunningTotal.RunningTotal+vSMAgreementRevenueDeferral.Amount)				
				FROM vSMAgreementRevenueDeferral				
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
							vSMAgreementRevenueDeferral.[Date] > SMRevenueDeferral.[Date] OR 
							(
								vSMAgreementRevenueDeferral.[Date] = SMRevenueDeferral.[Date] AND 
								vSMAgreementRevenueDeferral.Deferral >= SMRevenueDeferral.Deferral
							)
						)
					) DeriveRunningTotal
				 CROSS APPLY
					(
					--For the agreement/service get the sum amount that has not been invoiced. 
					--This is the amount that the deferrals copied to the agreement/service need to sum to.
					SELECT SUM(BillingAmount) BillingAmountSum
					FROM dbo.vSMAgreementBillingSchedule
					WHERE 
					vSMAgreementRevenueDeferral.SMCo = vSMAgreementBillingSchedule.SMCo AND 
					vSMAgreementRevenueDeferral.Agreement = vSMAgreementBillingSchedule.Agreement AND 
					vSMAgreementRevenueDeferral.Revision = vSMAgreementBillingSchedule.Revision AND 
					dbo.vfIsEqual(vSMAgreementRevenueDeferral.[Service], vSMAgreementBillingSchedule.[Service]) = 1	 AND
					vSMAgreementBillingSchedule.BillingType = 'S'
				) DeriveBillingAmountSum
				WHERE vSMAgreementRevenueDeferral.SMCo = @SMCo AND vSMAgreementRevenueDeferral.Agreement = @Agreement AND vSMAgreementRevenueDeferral.Revision = @PreviousRevision AND DeriveRunningTotal.RunningTotal > ISNULL(DeriveBillingAmountSum.BillingAmountSum,0)
			
				--****************************************************

				SELECT @TotalAmountAmend = ISNULL(SUM(BillingAmount), 0)
				FROM dbo.vSMAgreementBillingSchedule
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND Service IS NULL AND BillingType = 'S'

				UPDATE dbo.vSMAgreementService
				SET PricingPrice = CASE WHEN @TotalAmountPrevious = 0 THEN 0 ELSE PricingPrice * @TotalAmountAmend / @TotalAmountPrevious END
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND PricingMethod = 'P' AND BilledSeparately = 'N'

				SELECT @TotalAmountAmend = @TotalAmountAmend - ISNULL(SUM(PricingPrice), 0)
				FROM dbo.vSMAgreementService
				WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND PricingMethod = 'P' AND BilledSeparately = 'N'

				--If the agreement didn't have a price or was set to 0 then tack the left over amount to the first service
				--Otherwise set the agreement to the left over amount
				IF EXISTS(SELECT 1 FROM dbo.vSMAgreement WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND (AgreementPrice IS NULL OR AgreementPrice = 0))
				BEGIN
					UPDATE TOP (1) dbo.vSMAgreementService 
					SET PricingPrice = PricingPrice + @TotalAmountAmend
					WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision AND PricingMethod = 'P' AND BilledSeparately = 'N'
				END
				ELSE
				BEGIN
					UPDATE dbo.vSMAgreement
					SET AgreementPrice = @TotalAmountAmend
					WHERE SMCo = @SMCo AND Agreement = @Agreement AND Revision = @PreviousRevision
				END

				/* Update the service price for services that are billed separately based on billings that have already been invoiced. Non-invoiced billings will have been deleted. */
				UPDATE vSMAgreementService SET PricingPrice = ISNULL((SELECT SUM(BillingAmount) BillingTotal FROM vSMAgreementBillingSchedule WHERE SMCo=vSMAgreementService.SMCo AND Agreement=vSMAgreementService.Agreement AND Revision=vSMAgreementService.Revision AND Service=vSMAgreementService.Service AND BillingType='S'),0)
				FROM vSMAgreementService 
				WHERE vSMAgreementService.SMCo=@SMCo AND vSMAgreementService.Agreement=@Agreement AND vSMAgreementService.Revision=@PreviousRevision AND vSMAgreementService.PricingMethod='P' AND vSMAgreementService.BilledSeparately='Y'	
				
				IF (@rcode <> 0)
				BEGIN
					SET @msg = 'Previous revision failed to terminate: ' + @errmsg
					ROLLBACK TRAN
					RETURN 1
				END
			END
			ELSE
			BEGIN
				/* Activate the renewal */
				UPDATE SMAgreement
				SET DateActivated = dbo.vfDateOnly()
				WHERE SMCo = @SMCo AND
					  Agreement = @Agreement AND
					  Revision = @Revision AND
					  DateActivated IS NULL
				
				IF @@rowcount <> 1
				BEGIN
					SET @msg = 'SM Agreement failed to activate!'
					ROLLBACK TRAN
					RETURN 1
				END
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			--If the error is due to a transaction count mismatch in vspSMAgreementDeleteNewWorkOrders
			--then it is more helpful to keep the error message from vspSMAgreementDeleteNewWorkOrders.
			IF ERROR_NUMBER() <> 266 SET @msg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 ROLLBACK TRAN
			RETURN 1
		END CATCH
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMAgreementActivation] TO [public]
GO
