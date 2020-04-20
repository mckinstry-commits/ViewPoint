SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROESpecialPaymentDateVal]
/************************************************************************
* CREATED:	MV 04/09/2013   
* MODIFIED:
*
* USAGE: Canadian ROE Validation for PR Employee ROE History, Other Payments tab
*			-   When Category is "SH - Special Holiday"	
*			-	When Category is "SP-SpecialPayments"
*    
* INPUT: PRCo				
		 Employee 
*		 Special Payment Code	
*		 Special Payment Date
*
* OUTPUT: message if failed
*
* RETURNS:	0 if successfull 
*			1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany,
 @Employee bEmployee,
 @Category varchar(2),
 @SpecialHolidayDate bDate,
 @SpecialPaymentCode varchar(3),
 @SpecialPaymentDate bDate,
 @msg varchar(255) = '' OUTPUT)

AS
BEGIN
	SET NOCOUNT ON
	DECLARE @RecentRehireDate bDate,
			@RecentSeparationDate bDate

	SELECT @RecentRehireDate = RecentRehireDate, @RecentSeparationDate = RecentSeparationDate
	FROM dbo.PREH
	WHERE PRCo = @PRCo AND Employee=@Employee

	-- Special Holiday Date must be after the employee's recent separation date
	IF ISNULL(@Category,'') = 'SH'
	BEGIN
		IF @SpecialHolidayDate <= @RecentSeparationDate
		BEGIN
			SELECT @msg = 'Statutory Holiday Date must be after Employee''s Recent Separation Date.'
			RETURN 1
		END
	END
	ELSE 
		-- Special Payment Start Date must be on or before Employee's recent rehire date.
		-- If Special payment code is other than 'WLI' than Special Payment Start Date must
		-- also be on or before employee's recent separation date.
		IF ISNULL(@Category,'') = 'SP' 
		BEGIN
			IF @SpecialPaymentDate >= @RecentRehireDate
			BEGIN
				IF ISNULL(@SpecialPaymentCode,'') <> 'WLI' AND @SpecialPaymentDate > @RecentSeparationDate
				BEGIN
					SELECT @msg = 'Special Payment Start Date must be on or before Employee''s Recent Separation Date.'
					RETURN 1
				END
			END
			ELSE
			BEGIN
				SELECT @msg = 'Special Payment Start Date must be on or after Employee''s Recent Rehire Date'
				RETURN 1
			END
		END   
		
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspPRROESpecialPaymentDateVal] TO [public]
GO
