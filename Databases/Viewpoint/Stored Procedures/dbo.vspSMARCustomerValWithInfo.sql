SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspSMARCustomerValWithInfo]
/***********************************************************
* CREATED BY: Chris G 6/29/2012
* MODIFIED By:
*
* USAGE:
* 	Validates a AR Customer for SM:
*	If successful, returns billing info for the customer.  Wraps the bspARCustomerValWithInfo so that we
*	can select the info that SM forms need.
*
*****************************************************/
(@Company bCompany,
	@CustGroup bGroup = null,
	@Customer bSortName = null,
	@fullBillAddress varchar(255) = null output,	
	@billAddress varchar(60) = null output,
	@billAddress2 varchar(60) = null output,
	@billCity varchar(30) = null output,
	@billState varchar(4) = null output,
	@billZip bZip = null output,	
	@billCountry char(2) = null output,	
	@payterms bPayTerms = null output,
	@msg varchar(255) = null output)
     
AS
	SET NOCOUNT ON;
	
	DECLARE @rcode int
	
	EXEC @rcode = bspARCustomerValWithInfo @Company, @CustGroup, @Customer
					,null, null, null, null, null, null, null, null, null, null
					,@payterms output
					,null, null, null, null, null, null, null, null
					,@msg output							
					
	IF @rcode = 0
	BEGIN
		SELECT
			 @fullBillAddress = dbo.vfSMAddressFormat(ARCM.BillAddress, ARCM.BillAddress2, ARCM.BillCity, ARCM.BillState, ARCM.BillZip, ARCM.Country)
			,@billAddress = BillAddress
			,@billCity = BillCity
			,@billZip = BillZip
			,@billAddress2 = BillAddress2
			,@billCountry = BillCountry
			,@billState = BillState
		FROM ARCM
		WHERE CustGroup = @CustGroup
		  AND Customer = @Customer
	END
	
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSMARCustomerValWithInfo] TO [public]
GO
