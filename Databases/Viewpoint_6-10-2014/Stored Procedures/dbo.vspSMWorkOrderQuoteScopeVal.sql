SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE  procedure [dbo].[vspSMWorkOrderQuoteScopeVal]
/******************************************************
	* CREATED BY:	Scott Alvey
	* MODIFIED By:  03-01-13 LDG Changed WorkOrderQuote from int to varchar[15] and fixed column names.
	*				03-07-13 DKS Added @SMRateOverridesExist output and related select statement
	*				03-07-13 ScottAlvey Added new @Tax outputs
	*				03-11-13 LDG Added defaulting for Tax Type, and Tax Code whether thats from a Service Site, or Service Center.
	* Usage:  
	*	Validates a Work Order Quote Scope
	*	
	*
	* Input params:
	*
	*	@SMCo					- SM Company
	*	@WorkOrderQuote			- Work Order Quote
	*   @WorkOrderQuoteScope	- Work Order Scope number
	*	@MustExist				- Flag to control validation behavior
	*	
	*
	* Output params:
	*	@msg					- description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
(
   	@SMCo bCompany,
   	@WorkOrderQuote varchar(15),
   	@WorkOrderQuoteScope int,
   	@MustExist bYN = 'N',
	@TaxSource char(1) = NULL,
	@TaxCode dbo.bTaxCode = NULL OUTPUT,
	@TaxType int = NULL OUTPUT,
	@SMRateOverridesExist bYN = NULL OUTPUT,	
   	@msg varchar(100) = NULL OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @WorkOrderQuote IS NULL
	BEGIN
		SET @msg = 'Missing Work Order Quote.'
		RETURN 1
	END
	
	IF @WorkOrderQuoteScope IS NULL
	BEGIN
		SET @msg = 'Missing Work Order Quote Scope.'
		RETURN 1
	END
	
	SELECT @msg = [Description]
	FROM dbo.SMWorkOrderQuoteScope
	WHERE SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote and WorkOrderQuoteScope = @WorkOrderQuoteScope

	SELECT	@SMRateOverridesExist = dbo.vfSMRateOverridesExist(SMEntity.SMCo, SMEntity.EntitySeq)
	FROM dbo.SMWorkOrderQuoteScope
	LEFT JOIN dbo.SMEntity ON SMWorkOrderQuoteScope.SMCo = SMEntity.SMCo 
	AND SMWorkOrderQuoteScope.WorkOrderQuote = SMEntity.WorkOrderQuote 
	AND SMWorkOrderQuoteScope.WorkOrderQuoteScope = SMEntity.WorkOrderQuoteScope
	WHERE SMWorkOrderQuoteScope.SMCo = @SMCo
	AND SMWorkOrderQuoteScope.WorkOrderQuote = @WorkOrderQuote 
	AND SMWorkOrderQuoteScope.WorkOrderQuoteScope = @WorkOrderQuoteScope
	

	IF @@rowcount <> 1 AND @MustExist = 'Y'
	BEGIN
		SET @msg = 'Work Order Quote Scope does not exist in SMWorkOrderQuoteScope.'
		RETURN 1
	END

	-- Defaults Tax Type, and Tax Code from Service Site, or Service Center
	SELECT TOP 1
		@TaxCode = CASE 
			WHEN @TaxSource = 'S' AND SMWorkOrderQuote.ServiceSite IS NOT NULL THEN SMServiceSite.TaxCode 
			WHEN @TaxSource = 'C' AND SMWorkOrderQuote.ServiceCenter IS NOT NULL THEN SMServiceCenter.TaxCode
			ELSE NULL
		END,
		@TaxType = CASE WHEN HQCO.DefaultCountry IN ('AU','CA') THEN 3 ELSE 1 END
	FROM 
		dbo.SMWorkOrderQuote
	INNER JOIN dbo.SMCO ON SMWorkOrderQuote.SMCo = SMCO.SMCo
	INNER JOIN dbo.HQCO ON SMCO.ARCo = HQCO.HQCo
	LEFT JOIN dbo.SMServiceCenter ON SMServiceCenter.SMCo = SMWorkOrderQuote.SMCo 
		AND SMServiceCenter.ServiceCenter = SMWorkOrderQuote.ServiceCenter
	LEFT JOIN dbo.SMServiceSite ON SMServiceSite.SMCo = SMWorkOrderQuote.SMCo 
		AND SMServiceSite.ServiceSite = SMWorkOrderQuote.ServiceSite
	WHERE 
		SMWorkOrderQuote.SMCo = @SMCo 
		AND SMWorkOrderQuote.WorkOrderQuote = @WorkOrderQuote 	
	IF @TaxCode IS NULL 
	BEGIN
		SET @TaxType = NULL
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderQuoteScopeVal] TO [public]
GO
