SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  procedure [dbo].[vspPRAUETPElectronicFiling]
/******************************************************
* CREATED BY:	MV	04/06/2011 - PR AU ETP Epic
* MODIFIED By:	EN  04/06/2011  corrections
*
* Usage: Gets ETP records to return to the calling procedure
*		 to generate ETP electronic filing records
*
* Input params:
*
*	@PRCo - PR Company
*	@Taxyear - Tax Year
*	@AmendedYN - AmendedATO
*
* Output params:
*	@Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@PRCo bCompany, @TaxYear char(4),@AmendedYN bYN)
   	
AS
SET NOCOUNT ON
DECLARE @rcode INT
	
SELECT @rcode=0

--IF @PRCo IS NULL
--BEGIN
--	SELECT @Msg='Missing PRCo!', @rcode=1
--	RETURN
--END
--
--IF @TaxYear IS NULL
--BEGIN
--	SELECT @Msg='Missing Tax Year!', @rcode=1
--	RETURN
--END

IF @AmendedYN IS NULL
BEGIN
	SELECT @AmendedYN = 'N'
END

SELECT TaxFileNumber as 'PayeeTaxFileNbr',
		Surname as 'PayeeSurname',
		GivenName as 'PayeeGivenName',
		GivenName2 as 'PayeeGivenName2',
		e.Address as 'PayeeAddress',                      
		e.City as 'PayeeCity',   
		e.State as 'PayeeState',                         
		e.Postcode as 'PayeePostCode',
		h.Country as 'PayeeCountry',
		e.DateofBirth as 'PayeeDateofBirth',                   
		DateOfPayment,
		TotalTaxWithheld,              
		TaxableComponent,             
		TaxFreeComponent, 
		DeathBenefitYN,                
		DeathBenefitType,     		            
		TransitionalPaymentYN,         
		PartialPaymentYN,
		(CASE WHEN @AmendedYN = 'Y' THEN 'A' ELSE 'O' END) AS [AmendmentIndicator]
FROM dbo.PRAUEmployeeETPAmounts e
JOIN dbo.PREH h ON h.PRCo=e.PRCo AND h.Employee=e.Employee
WHERE e.PRCo=@PRCo AND e.TaxYear=@TaxYear AND AmendedATO = @AmendedYN
	

RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUETPElectronicFiling] TO [public]
GO
