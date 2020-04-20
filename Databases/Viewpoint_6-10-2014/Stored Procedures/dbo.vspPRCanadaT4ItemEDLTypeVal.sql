SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRCanadaT4ItemEDLTypeVal]
/******************************************************
* CREATED BY:	EN 10/17/2013
* MODIFIED By: 
*
* Usage:	
* Validates EDL Type for Canada T4 Employer Box Item.
*	  -	Confirm that all Box 14 entries in bPRCAEmployerItems are all
*		either for EDL Type 'E' or EDL Type 'D'.  If not, return an error. 
*
* Input params:
*	@prco		PR Company
*	@taxyear	Tax Year
*	@boxnumber	T4 Box Number
*	@type		EDL Type (E or D)
*	
*
* Output params:
*	@msg		Code description or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/
(@prco bCompany, 
 @taxyear char(4), 
 @boxnumber smallint,  
 @type char(1), 
 @ErrorMsg  varchar(255) OUTPUT
)

AS 

BEGIN TRY

	SET NOCOUNT ON

	DECLARE @Return_Value tinyint

	SELECT @Return_Value = 0

	-------------------------------
	-- VALIDATE INPUT PARAMETERS --
	-------------------------------
	IF @prco IS NULL
	BEGIN
		SELECT @ErrorMsg = 'Missing PR Company.', @Return_Value = 1	
		GOTO vspExit
	END

	IF @taxyear IS NULL
	BEGIN
		SELECT @ErrorMsg = 'Missing Tax Year.', @Return_Value = 1
		GOTO vspExit
	END

	IF @boxnumber IS NULL
	BEGIN	
		SELECT @ErrorMsg = 'Missing Box Number.', @Return_Value = 1
		GOTO vspExit
	END

	IF @type IS NULL
	BEGIN
		SELECT @ErrorMsg = 'Missing EDL Type.', @Return_Value = 1
		GOTO vspExit
	END

	---------------------------------------------------------------------
	-- CHECK BOX 14 SETUP IN bPRCAEmployerItems                        --
	-- ALL BOX 14 ENTRIES MUST BE UNIFORMLY EITHER EDL TYPE 'E' OR 'D' --
	---------------------------------------------------------------------
	IF @boxnumber = 14
	BEGIN
		--------------------------------------------------------------------------------
		-- BOX 14 SHOULD ONLY ALLOW EARNINGS AND DEDUCTION CODES, NOT LIABILITY CODES --
		--------------------------------------------------------------------------------
		IF @type NOT IN ('E', 'D')
		BEGIN
			SELECT @ErrorMsg = 'Box 14 setup only allows earnings codes and deduction codes.', @Return_Value = 1
			GOTO vspExit
		END

		DECLARE @ValidType char(1),
				@ValidTypeName varchar(9)

		SET @ValidType = (CASE WHEN @type = 'E' THEN 'D' ELSE 'E' END)
		SET @ValidTypeName = (CASE WHEN @ValidType = 'E' THEN 'Earnings' ELSE 'Deduction' END)

		IF EXISTS  (SELECT	1
					FROM	dbo.bPRCAEmployerItems
					WHERE	PRCo = @prco
							AND TaxYear = @taxyear
							AND T4BoxNumber = @boxnumber
							AND EDLType = @ValidType
				   )
		BEGIN
			SELECT @ErrorMsg = 'Your current Box 14 setup requires that only ' + @ValidTypeName + ' codes be selected for Box Number 14.', 
								@Return_Value = 1
			GOTO vspExit
		END
	END
	
END TRY

--------------------
-- ERROR HANDLING --
--------------------
BEGIN CATCH
	SET @Return_Value = 1
	SET @ErrorMsg = ERROR_PROCEDURE() + ': ' + ERROR_MESSAGE()	
END CATCH

------------------
-- EXIT ROUTINE --
------------------
vspExit:
	RETURN @Return_Value
GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4ItemEDLTypeVal] TO [public]
GO
