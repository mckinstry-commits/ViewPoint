SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 03/014/13
-- Description:	Validate WO Quote and optionally activate..
--
-- Modified:	04/17/13 DKS - Moved approval code to vspSMGenerateQuoteWorkOrder
--			    07/03/13 ScottAlvey - Added @SMCo to IfExist checks - also added a check
--					to make sure the scope's flatprice split summed up to the scope price
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderQuoteApproveValidate]
	@SMCo bCompany, 
	@WOQuote varchar(15),
	@Approve bYN, 
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @CustGroup bGroup, 
			@Customer bCustomer, 
			@CustomerActive bYN,
			@ServiceSite varchar(20),
			@ServiceCenter varchar(10),
			@Status varchar(16),
			@rcode int,
			@TempMsg varchar(255)

	SELECT @Status =
	CASE 
		WHEN (SMWorkOrderQuote.DateCanceled IS NULL AND SMWorkOrderQuote.DateApproved IS NOT NULL) 
		THEN 'Activated' 
		WHEN (SMWorkOrderQuote.DateCanceled IS NOT NULL AND SMWorkOrderQuote.DateApproved IS NULL) 
		THEN 'Canceled' 
		ELSE 'Open' 
	END
	FROM SMWorkOrderQuote
	WHERE SMCo = @SMCo AND 
		  WorkOrderQuote = @WOQuote
	
	SELECT  @CustGroup = SMWorkOrderQuote.CustGroup,
		@Customer = SMWorkOrderQuote.Customer,
		@ServiceSite = SMWorkOrderQuote.ServiceSite,
		@ServiceCenter = SMWorkOrderQuote.ServiceCenter,
		@CustomerActive = SMCustomer.Active
	FROM dbo.SMWorkOrderQuote
	LEFT JOIN SMCustomer
		ON SMWorkOrderQuote.SMCo = SMCustomer.SMCo
		AND SMWorkOrderQuote.CustGroup = SMCustomer.CustGroup
		AND SMWorkOrderQuote.Customer = SMCustomer.Customer
	WHERE SMWorkOrderQuote.SMCo = @SMCo 
		AND WorkOrderQuote = @WOQuote

	EXEC @rcode = vspSMCustomerVal @SMCo = @SMCo, @CustomerGroup = @CustGroup, @Customer = @Customer, @MustExist = 'Y'
	IF @rcode <> 0
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Invalid Customer.'
		SET @msg = @msg + dbo.vfLineBreak()
	END
	ELSE
	BEGIN
		EXEC @rcode = vspSMServiceSiteVal @SMCo = @SMCo, @ServiceSite = @ServiceSite, @SiteCustomer = @Customer
		IF @rcode <> 0
		BEGIN
			SET @msg = ISNULL(@msg, '') + 'Invalid Service Site.'
			SET @msg = @msg + dbo.vfLineBreak()
		END
	END

	EXEC @rcode = vspSMServiceCenterVal @SMCo = @SMCo, @ServiceCenter = @ServiceCenter, @MustBeActive = 0, @HasWorkCompleted = 'N', @msg = @TempMsg
	IF @rcode <> 0
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Invalid Service Center.'
		SET @msg = @msg + dbo.vfLineBreak()
	END

	IF NOT EXISTS (SELECT 1
	FROM dbo.SMWorkOrderQuoteScope
	WHERE SMWorkOrderQuoteScope.SMCo = @SMCo 
	AND SMWorkOrderQuoteScope.WorkOrderQuote = @WOQuote)
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'No scope present.'
		SET @msg = @msg + dbo.vfLineBreak() 
	END

	IF EXISTS (SELECT 1
	FROM dbo.SMWorkOrderQuoteScope
	WHERE SMWorkOrderQuoteScope.SMCo = @SMCo 
	AND SMWorkOrderQuoteScope.WorkOrderQuote = @WOQuote
	AND SMWorkOrderQuoteScope.PriceMethod = 'T'
	AND SMWorkOrderQuoteScope.RateTemplate IS NULL)
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Scope price method set to Time & Material without specifying rate template.'
		SET @msg = @msg + dbo.vfLineBreak() 
	END

	IF EXISTS (SELECT 1
	FROM dbo.SMWorkOrderQuoteScope
	WHERE SMWorkOrderQuoteScope.SMCo = @SMCo 
	AND SMWorkOrderQuoteScope.WorkOrderQuote = @WOQuote
	AND SMWorkOrderQuoteScope.PriceMethod = 'F'
	AND SMWorkOrderQuoteScope.Price IS NULL)
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Scope price method set to Flat Price without specifying a price.'
		SET @msg = @msg + dbo.vfLineBreak()
	END

	IF EXISTS (SELECT 1
	FROM dbo.SMWorkOrderQuoteScope s
	OUTER APPLY
		(SELECT sum(Amount) as Amount
		 FROM SMFlatPriceRevenueSplit f
		 JOIN SMEntity e ON f.SMCo = e.SMCo AND f.EntitySeq = e.EntitySeq
		 WHERE e.SMCo = s.SMCo 
		 AND e.WorkOrderQuote = s.WorkOrderQuote
		 AND e.WorkOrderQuoteScope = s.WorkOrderQuoteScope
		) t --FPSplitTotal
	WHERE s.SMCo = @SMCo 
	AND s.WorkOrderQuote = @WOQuote
	AND s.PriceMethod = 'F'
	AND t.Amount <> s.Price	)
	BEGIN
		SET @msg = ISNULL(@msg, '') + 'Scope price does not equal the sum of the Scope''s Flat Price Split amount'
		SET @msg = @msg + dbo.vfLineBreak()
	END

	IF @Approve = 'Y' AND @msg IS NULL
	BEGIN
		IF @Status <> 'Open'
		BEGIN
			SET @msg = ISNULL(@msg, '') + 'Quote is not open, activation failed.'
			SET @msg = @msg + dbo.vfLineBreak()
			RETURN 1
		END
	END

	IF @msg IS NOT NULL
		RETURN 1

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderQuoteApproveValidate] TO [public]
GO
