SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspPRAUEmployerFBTEDLCodeVal]
	/******************************************************
	* CREATED BY:	MV 01/06/11
	* MODIFIED By: 
	*
	* Usage:	Validates EDL Code against FBT Type and EDL Type.  
	*			Called from PRAUEmployerFBTItems.
	*
	* Input params:
	*
	*	@prco - PR Company
	*	@taxyear - Tax Year
	*	@FBTType - FBT Type
	*	@type - EDL Type
	*	@code - EDL Code	
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@PRCo bCompany,@FBTType varchar(4), @EDLType char(1),
   	  @EDLCode bEDLCode, @Msg varchar(100) output)
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT

	SELECT @rcode = 0

	if @PRCo is null
	BEGIN
		SELECT @Msg = 'Missing PR Company.', @rcode = 1	
		GOTO  vspexit
	END

	IF @FBTType IS NULL
	BEGIN	
		SELECT @Msg = 'Missing FBT Type.', @rcode = 1
		GOTO  vspexit
	END

	IF @EDLType IS NULL
	BEGIN	
		SELECT @Msg = 'Missing EDL Type.', @rcode = 1
		GOTO  vspexit
	END
	
	IF @EDLCode IS NULL
	BEGIN
		SELECT @Msg = 'Missing EDL Code.', @rcode = 1
		GOTO  vspexit
	END

	IF @EDLType = 'E'
	BEGIN
		IF NOT EXISTS
			(
				SELECT 1 
				FROM dbo.PREC 
				WHERE PRCo = @PRCo AND EarnCode = @EDLCode 
			)
		BEGIN
			SELECT @Msg = 'Invalid Earnings code for EDL Type.', @rcode = 1
			GOTO  vspexit 
		END
		ELSE
		BEGIN
			IF NOT EXISTS
			(
				SELECT 1 
				FROM dbo.PREC 
				WHERE PRCo = @PRCo AND EarnCode = @EDLCode AND ATOCategory=@FBTType
			)
			BEGIN
				SELECT @Msg = 'No ATO category set up for this Earnings Code .', @rcode = 1
				GOTO  vspexit 
			END
			ELSE
			BEGIN
				SELECT @Msg = [Description]
				FROM dbo.PREC
				WHERE PRCo = @PRCo AND EarnCode = @EDLCode AND ATOCategory=@FBTType	
			END
		END
	END
	
	
	IF @EDLType <> 'E'
	BEGIN
		IF NOT EXISTS
			(
				SELECT 1 
				FROM dbo.PRDL
				WHERE PRCo = @PRCo AND DLCode = @EDLCode AND DLType = @EDLType
			)
		BEGIN
			SELECT @Msg = 'Invalid Dedn/Liab code for EDL Type.', @rcode = 1
			GOTO  vspexit 
		END
		ELSE
		BEGIN
			IF NOT EXISTS
			(
				SELECT 1 
				FROM dbo.PRDL
				WHERE PRCo = @PRCo AND DLCode = @EDLCode AND DLType = @EDLType AND ATOCategory=@FBTType
			)
			BEGIN
				SELECT @Msg = 'No ATO category set up for this Dedn/Liab Code.', @rcode = 1
				GOTO  vspexit 
			END
			ELSE
			BEGIN
				SELECT @Msg = [Description]
			FROM dbo.PRDL 
			WHERE PRCo = @PRCo and DLCode = @EDLCode AND DLType = @EDLType AND ATOCategory=@FBTType
			END
		END	
	END
	 
	vspexit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUEmployerFBTEDLCodeVal] TO [public]
GO
