SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPRWHTaxYearVal    Script Date: 8/28/99 9:35:43 AM ******/
CREATE procedure [dbo].[vspPRAUBASTaxYearVal]
/************************************************************
* CREATED BY: 	 CHS	03/11/2011
* MODIFIED By :		MV	03/14/2011
*								
*								
*
* USAGE:
* Validate Tax Year entered for PRAUBASProcess.
* return default values from ATO Process
*
* INPUT PARAMETERS
*   @PRCo       PR Co
*   @TaxYear    Year to validate
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
************************************************************/
@PRCo bCompany, @TaxYear VARCHAR(4),
@Sequence int OUTPUT,
@GivenName varchar(15)OUTPUT,
@Surname varchar(30) OUTPUT,
@Phone varchar(20) OUTPUT,
@Signature varchar(30) OUTPUT,
@msg VARCHAR(255) OUTPUT

   AS
   SET NOCOUNT ON
   
   DECLARE @rcode INT
   
   SELECT @rcode = 0
   
IF LEN(ISNULL(@TaxYear, '')) NOT IN (0,4)
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF ISNUMERIC(@TaxYear) = 0
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF SUBSTRING(@TaxYear, 1, 1) not in ('1','2','3','4','5','6','7','8','9')
  	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
IF SUBSTRING(@TaxYear, 2, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END

IF SUBSTRING(@TaxYear, 3, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END

IF SUBSTRING(@TaxYear, 4, 1) not in ('1','2','3','4','5','6','7','8','9','0')
	BEGIN
	SELECT @msg = 'Invalid Tax Year entered!', @rcode = 1
	RETURN @rcode
	END
	
SELECT @GivenName = ContactGivenName,
@Surname = ContactSurname,
@Phone = ContactPhone,
@Signature = SignatureOfAuthPerson
FROM dbo.PRAUEmployerMaster
WHERE PRCo=@PRCo and TaxYear=@TaxYear 
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Tax Year is not set up in ATO Processing!', @rcode = 1
	RETURN @rcode
END
   
SELECT @Sequence = Max(Seq) 
FROM PRAUEmployerBAS 
WHERE @PRCo = PRCo AND @TaxYear = TaxYear

   
   bspexit:
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASTaxYearVal] TO [public]
GO
