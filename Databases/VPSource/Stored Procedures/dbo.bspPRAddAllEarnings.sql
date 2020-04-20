
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAddAllEarnings    Script Date: 8/28/99 9:35:28 AM ******/
   CREATE    procedure [dbo].[bspPRAddAllEarnings]
/***********************************************************
* CREATED BY:	GG 02/05/98
* MODIFIED By:	EN 10/7/02		- issue 18877 change double quotes to single
*				CHS 10/15/2010	- #140541 - change bPRDB.EarnCode to EDLCode
*				CHS 10/19/2010	- #140541 - added DL codes to insert
*				MV	06/11/2013	- TFS-49396 - added 'FromCode' to initialize earn/pre-tax codes from a specific DLCode/LiabCode
*
* USAGE:
* Called by PR Dedn/Liab maintenance form to initlaize all
* earnings codes as subject to the current deduction/liability.
*
* INPUT PARAMETERS
*   PRCo    	PR Company
*   DLCode	Deduction/liability code to initialize
* OUTPUT PARAMETERS
*   @msg      error message IF falure
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
   
(@prco bCompany = null, @CopyToCode bEDLCode = null, @CopyFromCode bEDLCode = null,  @msg varchar(60) output)
AS

SET NOCOUNT ON

DECLARE @rcode int
SELECT @rcode = 0

IF @prco is null
BEGIN
	SELECT @msg = 'Missing PR Company!', @rcode = 1
	GOTO bspexit
END

IF @CopyToCode is null
BEGIN
	SELECT @msg = 'Missing Dedn/Liab Code!', @rcode = 1
	GOTO bspexit
END


IF @CopyFromCode IS NULL
BEGIN
	--Copy all earn codes in PRED to the new Dedn code.
	INSERT bPRDB	(
						PRCo, DLCode, EDLType, EDLCode, SubjectOnly
					)
	SELECT DISTINCT PRCo = @prco, DLCode = @CopyToCode, 'E', EarnCode, SubjectOnly = 'N' 
	FROM dbo.bPREC
	WHERE PRCo=@prco 
			AND EarnCode NOT IN	(
									SELECT EDLCode 
									FROM dbo.bPRDB 
									WHERE PRCo = @prco and DLCode = @CopyToCode and EDLType = 'E'
								)
   	
	IF EXISTS	(
					SELECT TOP 1 1 
					FROM dbo.bPRDL 
					WHERE PRCo=@prco AND DLCode=@CopyToCode AND CalcCategory in ('F', 'S', 'L') AND Method IN ('G', 'R')
				)
	BEGIN
		INSERT bPRDB	(
							PRCo, DLCode, EDLType, EDLCode, SubjectOnly
						)
		SELECT DISTINCT PRCo = @prco,DLCode = @CopyToCode, DLType, DLCode, SubjectOnly = 'N'
		FROM dbo.bPRDL
		WHERE PRCo=@prco AND PreTax='Y' AND DLCode <> @CopyToCode 
			AND DLCode NOT IN	(
									SELECT EDLCode 
									FROM dbo.bPRDB 
									WHERE PRCo = @prco and DLCode = @CopyToCode AND EDLType = 'D'
								)

	END
END
ELSE
-- copy basis earn codes assigned to a specific DLCode from PRDB
BEGIN
	INSERT bPRDB	(
						PRCo, DLCode, EDLType, EDLCode, SubjectOnly
					)
	SELECT DISTINCT PRCo = @prco, DLCode = @CopyToCode, 'E', b.EDLCode, SubjectOnly = 'N' 
	FROM dbo.bPRDB b
	WHERE PRCo=@prco AND b.DLCode = @CopyFromCode AND b.EDLType = 'E' 
			AND b.EDLCode NOT IN	(
									SELECT EDLCode 
									FROM dbo.bPRDB 
									WHERE PRCo = @prco and DLCode = @CopyToCode and EDLType = 'E'
								)

	IF EXISTS	(
					SELECT TOP 1 1 
					FROM dbo.bPRDL 
					WHERE PRCo=@prco AND DLCode=@CopyToCode AND CalcCategory in ('F', 'S', 'L') AND Method IN ('G', 'R')
				)
	BEGIN
		INSERT bPRDB	(
							PRCo, DLCode, EDLType, EDLCode, SubjectOnly
						)
		SELECT DISTINCT PRCo = @prco,DLCode = @CopyToCode, 'D', b.EDLCode, SubjectOnly = 'N'
		FROM dbo.bPRDB b
		JOIN dbo.bPRDL d ON b.PRCo = d.PRCo AND b.EDLCode=d.DLCode AND b.EDLType = d.DLType 
		WHERE b.PRCo=@prco AND b.DLCode = @CopyFromCode AND b.EDLType = 'D' AND d.PreTax = 'Y' 
			AND b.EDLCode NOT IN	(
									SELECT EDLCode 
									FROM dbo.bPRDB 
									WHERE PRCo = @prco and DLCode = @CopyToCode and EDLType = 'D'
								)

	END
   	
END



   
   
bspexit:

RETURN @rcode

GO

GRANT EXECUTE ON  [dbo].[bspPRAddAllEarnings] TO [public]
GO
