SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPRActiveForArrearsEmplVal    Script Date: 8/28/99 9:33:19 AM ******/
CREATE PROC [dbo].[vspPRActiveForArrearsEmplVal]

/***********************************************************
* CREATED BY: EN 8/21/2012 B-10148
* MODIFIED By: KK 10/02/2012 - B-11165/TK-18209 Loosen validation for manual entries
*
*
* Usage:
*	Used by PR Arrears/Payback History to validate Employee inputs by either Sort Name or number.
*	Validation only allows for employees, active or not, that are active for arrears.
*
* Input params:
*	@prco		PR company
*	@empl		Employee sort name or number
*
* Output params:
*	@emplout	Employee number
*	@msg		Employee Name or error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
(@prco bCompany,
 @empl varchar(15),
 @emplout bEmployee = NULL OUTPUT,
 @msg varchar(60) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@lastname varchar(30),
		@firstname varchar(30),
		@middlename varchar(15), 
		@suffix varchar(4),
		@arrearsactiveyn bYN

SELECT @rcode = 0

/* check required input params */

IF @empl IS NULL
BEGIN
	SELECT @msg = 'Missing Employee.'
	RETURN 1
END

/* If @empl is numeric then try to find Employee number */
--if isnumeric(@empl) = 1
--24734 Added call to function and check for len @empl
IF dbo.bfIsInteger(@empl) = 1
BEGIN
	IF LEN(@empl) < 7
	BEGIN
		SELECT @emplout = Employee,		@lastname = LastName,
			   @firstname = FirstName,	@middlename = MidName,		
			   @suffix = Suffix,		@arrearsactiveyn = ArrearsActiveYN
		FROM PREH
		WHERE PRCo = @prco AND 
			  Employee = CONVERT(int,CONVERT(float, @empl))
	END
ELSE
	BEGIN
		SELECT @msg = 'Invalid Employee Number, length must be 6 digits or less.'
		RETURN 1
	END
END

/* if not numeric or not found try to find as Sort Name */
IF @@ROWCOUNT = 0
BEGIN
   	SELECT @emplout = Employee,		@lastname = LastName,
		   @firstname = FirstName,	@middlename = MidName,	
		   @suffix = Suffix,		@arrearsactiveyn = ArrearsActiveYN
	FROM PREH
	WHERE PRCo = @prco AND 
		  SortName = @empl

	/* if not found,  try to find closest */
  	IF @@ROWCOUNT = 0
	BEGIN
		SET ROWCOUNT 1
		SELECT @emplout = Employee,		@lastname = LastName,
			   @firstname = FirstName,	@middlename = MidName,	
			   @suffix = Suffix,		@arrearsactiveyn = ArrearsActiveYN
		FROM PREH
		WHERE PRCo = @prco AND 
			  SortName LIKE @empl + '%'
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Not a valid Employee'
			RETURN 1
		END
	END
END

--(KK) #11165
--employee must be active for arrears
--IF @arrearsactiveyn <> 'Y'
--BEGIN
--	SELECT @msg = 'Employee must be active for Arrears/Payback'
--	RETURN 1
--END

--assemble full name to return in @msg
IF @suffix IS NULL 
BEGIN
	SELECT @msg = @lastname + ', ' + ISNULL(@firstname,'') + ' ' + ISNULL(@middlename,'')
END
ELSE
BEGIN
	SELECT @msg = @lastname + ' ' + @suffix + ', ' + ISNULL(@firstname,'') + ' ' + ISNULL(@middlename,'')
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPRActiveForArrearsEmplVal] TO [public]
GO
