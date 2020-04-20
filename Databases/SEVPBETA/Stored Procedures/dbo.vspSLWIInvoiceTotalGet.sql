SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspSLWIInvoiceTotalGet]
	/********************************************************
	* CREATED BY: 	DC 03/16/09 #129889 - AUS SL - Track Claimed  and Certified amounts
	* MODIFIED BY:	GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
	*              
	*
	* USAGE:
	* 	Retrieves the total for all invoices in APUI for a subcontract item.
	*
	* INPUT PARAMETERS:
	*	@slco		SL Company
	*	@sl			Subcontract
	*	@slitem		Subcontract Item
	*	@slkeyid	SL Key ID (SLWH!KeyID)
	*
	* OUTPUT PARAMETERS:
	*	@total		sum(APUL! GrossAmt)
	*	@msg			Error message
	*
	* RETURN VALUE:
	* 	0 	    Success
	*	1 & message Failure
	*
	**********************************************************/
      	(@slco bCompany, @sl VARCHAR(30), @slitem bItem, @slkeyid bigint,      	
      	@total bDollar = null output, @msg varchar(60) output)
      as
  
      set nocount on
   	DECLARE @rcode int
    SELECT @rcode = 0
    SELECT @total = 0
	
	IF @slco is null
		BEGIN
			SELECT @msg = 'missing SL Company', @rcode =1
			GOTO vspexit
		END  
	IF @sl is null
		BEGIN
			SELECT @msg = 'missing Subcontract', @rcode =1
			GOTO vspexit
		END  
	IF @slitem is null
		BEGIN
			SELECT @msg = 'missing Subcontract Item', @rcode =1
			GOTO vspexit
		END  
	IF @slkeyid is null
		BEGIN
			SELECT @msg = 'missing SL Worksheet Key ID', @rcode =1
			GOTO vspexit
		END  	

	SELECT @total = sum(GrossAmt)
	FROM APUL
	WHERE APCo = @slco and SL = @sl and SLItem = @slitem and SLKeyID = @slkeyid      	
 
    
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLWIInvoiceTotalGet] TO [public]
GO
