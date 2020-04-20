SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  procedure [dbo].[vspPRAUETPEmployeeInitializeAmounts]
/******************************************************
* CREATED BY:	CHS 03/25/2011
* MODIFIED By:	MV	04/04/2011 - PR AU ETP Epic
*
* Usage: Calculates ETP amounts from bPREA on an employee.
*		 Inserts Employee information and amounts into vPRAUEmployeeETPAmounts.
*		 Called from PRAUEmployerETPProcess form.	
*
* Input params:
*
*	@PRCo - PR Company
*	@Taxyear - Tax Year
*	@Employee
*	@DateOfPayment 
*	@TransitionalPayment
*	@PartialPayment
*	@DeathBenefit
*	@DeathBenefitType
*
* Output params:
*	@Msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@PRCo bCompany,@TaxYear char(4), @Employee bEmployee, @DateOfPayment bDate,
@TransitionalPayment bYN, @PartialPayment bYN, @DeathBenefit bYN, @DeathBenefitType VARCHAR(1),
@Msg varchar(100) output)
   	
AS
SET NOCOUNT ON
DECLARE @rcode INT, @PRDate bDate,@TotTaxWithheld bDollar,
	@TaxableComponent bDollar, @TaxFreeComponent bDollar
	
SELECT @rcode=0, @TotTaxWithheld=0,@TaxableComponent=0,@TaxFreeComponent =0

IF @PRCo IS NULL
BEGIN
	SELECT @Msg='Missing PRCo!', @rcode=1
	RETURN
END

IF @TaxYear IS NULL
BEGIN
	SELECT @Msg='Missing Tax Year!', @rcode=1
	RETURN
END

IF @Employee IS NULL
BEGIN
	SELECT @Msg='Missing Employee!', @rcode=1
	RETURN
END

IF @DateOfPayment IS NULL
BEGIN
	SELECT @Msg='Missing Date of Payment!', @rcode=1
	RETURN
END

-- Set @PRDate relative to payment date
SELECT @PRDate = CONVERT(VARCHAR(2),DATEPART(mm, @DateOfPayment))
	+ '/1/' 
	+ CONVERT(VARCHAR(4), DATEPART(yyyy,@DateOfPayment))

-- Check for the existence of this employee by taxyear in EFTAmounts table
IF EXISTS(
			SELECT * 
			FROM dbo.PRAUEmployeeETPAmounts
			WHERE PRCo=@PRCo AND TaxYear=@TaxYear AND Employee=@Employee
		 )
-- update existing record
BEGIN
	-- Check for existence of bPREA record 
	IF EXISTS 
		(
			SELECT * 
			FROM dbo.PREA e
			JOIN dbo.PRDL d ON e.PRCo=d.PRCo AND e.EDLType=d.DLType AND e.EDLCode=d.DLCode
			WHERE e.PRCo=@PRCo AND e.Mth=@PRDate AND e.Employee=@Employee AND d.DLType='D' AND d.ATOCategory in ('TE','ETP')
		)
	BEGIN
		-- get amounts to update
		SELECT @TotTaxWithheld = SUM(Amount),@TaxableComponent = SUM(EligibleAmt), @TaxFreeComponent = SUM(SubjectAmt - EligibleAmt)
		FROM dbo.PREA e JOIN dbo.PRDL d ON e.PRCo=d.PRCo AND e.EDLType=d.DLType AND e.EDLCode=d.DLCode
		WHERE e.PRCo=@PRCo AND e.Mth=@PRDate AND e.Employee=@Employee AND d.DLType='D' AND d.ATOCategory in ('TE','ETP')
		-- update existing record with new amounts
			UPDATE dbo.PRAUEmployeeETPAmounts
			SET	DateOfPayment = @DateOfPayment,
				TotalTaxWithheld = TotalTaxWithheld + ISNULL(@TotTaxWithheld,0),
				TaxableComponent = TaxableComponent + ISNULL(@TaxableComponent,0),
				TaxFreeComponent = TaxFreeComponent + ISNULL(@TaxFreeComponent,0),
				TransitionalPaymentYN = @TransitionalPayment,
				PartialPaymentYN = @PartialPayment,
				DeathBenefitYN = @DeathBenefit,
				DeathBenefitType = @DeathBenefitType
			WHERE PRCo=@PRCo AND TaxYear=@TaxYear AND Employee=@Employee
			-- Return message
			IF @@ROWCOUNT = 1
			BEGIN
				SELECT @Msg = 'ETP Amounts were re-generated for Employee ' + CONVERT(VARCHAR(10),@Employee) + '.'
			END 
	END
	ELSE
		BEGIN
		SELECT @Msg = 'No ETP Amounts re-generated for Employee # ' + CONVERT(VARCHAR(10),@Employee)
		+ ' with payment date ' + CONVERT(VARCHAR (10),@DateOfPayment,3)
		END
	        
END
ELSE
-- Create a new record
BEGIN
	-- Check for existence of bPREA record 
	IF EXISTS 
		(
			SELECT * 
			FROM dbo.PREA e
			JOIN dbo.PRDL d ON e.PRCo=d.PRCo AND e.EDLType=d.DLType AND e.EDLCode=d.DLCode
			WHERE e.PRCo=@PRCo AND e.Mth=@PRDate AND e.Employee=@Employee AND d.DLType='D' AND d.ATOCategory in ('TE','ETP')
		)
	BEGIN
		-- get amounts to update
		SELECT @TotTaxWithheld = SUM(Amount),@TaxableComponent = SUM(EligibleAmt), @TaxFreeComponent = SUM(SubjectAmt - EligibleAmt)
		FROM dbo.PREA e JOIN dbo.PRDL d ON e.PRCo=d.PRCo AND e.EDLType=d.DLType AND e.EDLCode=d.DLCode
		WHERE e.PRCo=@PRCo AND e.Mth=@PRDate AND e.Employee=@Employee AND d.DLType='D' AND d.ATOCategory in ('TE','ETP')
		-- Insert new rec
			INSERT INTO dbo.PRAUEmployeeETPAmounts
				(
					PRCo,                          
					TaxYear,                       
					Employee,                      
					Seq,                     
					GivenName,              
					GivenName2,             
					Surname,                
					Address,                       
					City,                          
					State,                         
					Postcode,                      
					DateofBirth,                   
					DateOfPayment,                 
					TaxFileNumber,                 
					TotalTaxWithheld,              
					TaxableComponent,              
					TaxFreeComponent,              
					TransitionalPaymentYN,         
					PartialPaymentYN,              
					DeathBenefitYN,                
					DeathBenefitType,              
					Amended,                       
					AmendedATO,                    
					CompleteYN                    
				)
			SELECT @PRCo,
					@TaxYear,
					@Employee,
					1,
					SUBSTRING(h.FirstName,1,15),
					h.MidName,
					h.LastName,
					h.Address,
					h.City,
					h.State,
					h.Zip,
					h.BirthDate,
					@DateOfPayment,
					h.SSN,
					ISNULL(@TotTaxWithheld, 0),
					ISNULL(@TaxableComponent,0),
					ISNULL(@TaxFreeComponent,0),
					ISNULL(@TransitionalPayment,'N'),
					ISNULL(@PartialPayment,'N'),
					ISNULL(@DeathBenefit,'N'),
					@DeathBenefitType,
					'N','N','N'
			FROM dbo.PREH h 
			WHERE h.PRCo=@PRCo AND h.Employee=@Employee	
			-- Return message
			IF @@ROWCOUNT = 1
			BEGIN
				SELECT @Msg = 'ETP Amounts were generated for Employee ' + CONVERT(VARCHAR(10),@Employee) + '.'
			END
	END
	ELSE
		BEGIN
			SELECT @Msg = 'No ETP Amounts were generated for Employee # ' + CONVERT(VARCHAR(10),@Employee)
			+ ' with payment date ' + CONVERT(VARCHAR (10),@DateOfPayment,3)
		END
END
			

RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUETPEmployeeInitializeAmounts] TO [public]
GO
