SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEOtherPaymentsNumGen]
/************************************************************************
* CREATED:	KK 02/29/2013   
* MODIFIED:
*
* USAGE: Canadian ROE generates a Number on Category validation, in PR Employee ROE History, Other Payments tab
*				-	When Category is "V-Vacation", Num can only = 1, as only one record of this Category is allowed in the XML file
*				-	When Category is "SH-StatutoryHoliday", Num can only = 1,2 or 3, as only 3 records of this Category are allowed
*				-	When Category is "SP-SpecialPayments", Num can only = 1, as only one record of this Category is allowed
*				-	When Category is "OM-OtherMonies", Num can only = 1,2 or 3, as only 3 records of this Category are allowed 
*    
* INPUT:	Company		Current company
*			Employee	Employee of this record
*			ROEDate		ROE Date of this record
*			Category	2 character combobox selection
*
* OUTPUT:	@num	A valid number for the row
*			@msg	An error message if failed
*
* RETURNS:	0	successfull 
*			1	failed
*
*************************************************************************/
(@PRCo bCompany = NULL,
 @Employee bEmployee = NULL,
 @ROEDate bDate = NULL,
 @Category varchar(2),
 @num int OUTPUT,
 @msg varchar(255) = '' OUTPUT)

AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @count int
	SELECT @count = 0

	IF @PRCo IS NULL
	BEGIN
		SELECT @msg = 'Company is required'
		RETURN 1
	END
	
	IF @Employee IS NULL
	BEGIN
		SELECT @msg = 'Employee is required'
		RETURN 1
	END
	
	IF @ROEDate IS NULL
	BEGIN
		SELECT @msg = 'ROE Date is required'
		RETURN 1
	END
	
	-- Count the number of records in this "set" to see if it has reached the max for this Category
	SELECT @count = COUNT(*)  
	FROM vPRROEEmployeeSSPayments 
	WHERE PRCo = @PRCo
		AND Employee = @Employee
		AND ROEDate = @ROEDate 
		AND Category = @Category
  
	-- If we reached the max, return an error and do not add record
	IF @Category = 'V' 
	BEGIN IF @count < 1 
		  BEGIN SELECT @num = @count + 1 RETURN 0 END
		  ELSE 
		  BEGIN SELECT @msg = 'Only 1 Vacation record may exist' RETURN 1 END
	END
	
	ELSE IF @Category = 'SH'
	BEGIN IF @count < 3
		  BEGIN SELECT @num = @count + 1 RETURN 0 END
		  ELSE 
		  BEGIN SELECT @msg = 'Only 3 Statutory Holiday records may exist' RETURN 1 END
	END

	ELSE IF @Category = 'SP'
	BEGIN IF @count < 1
		  BEGIN SELECT @num = @count + 1 RETURN 0 END
		  ELSE 
		  BEGIN SELECT @msg = 'Only 1 Special Payment records may exist' RETURN 1 END
	END

	ELSE IF @Category = 'OM' 
	BEGIN IF @count < 3 
		  BEGIN SELECT @num = @count + 1 RETURN 0 END
		  ELSE 
		  BEGIN SELECT @msg = 'Only 3 Other Monies record may exist' RETURN 1 END
	END
	
	
	-- Have not reached the max, return the next valid "number" for this record
	
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEOtherPaymentsNumGen] TO [public]
GO
