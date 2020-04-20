SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMCostTypeCategoryVal]

-- =============================================

-- Author:		Dan Koslicki

-- Create date: 04/02/13

-- Description:	Validation for SM Cost Type Category.

-- Modifications: EricV 05/31/13 Allow cost type with any category when cost type category is Other.


-- =============================================

	@SMCo AS bCompany, 
	@SMCostType AS smallint, 
	@SMCostTypeCategory AS char(1),
	@TaxableCostType AS bYN OUTPUT, 
	@msg AS varchar(255) OUTPUT

AS

BEGIN

	-- Confirm SMCo is populated
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END

	-- Confirm SMCost Type is populated
	IF @SMCostType IS NULL
	BEGIN
		SET @msg = 'Missing SM Cost Type!'
		RETURN 1
	END

	-- Call vspSMCostTypeVal to perform additional validation
	DECLARE @rcode int 

	EXEC @rcode = vspSMCostTypeVal 
				@SMCo = @SMCo, 
				@SMCostType = @SMCostType, 				
				@MustExist = 'Y', 
				@Taxable = @TaxableCostType OUTPUT,
				@msg = @msg OUTPUT

	IF @rcode <> 0 
	BEGIN 
		RETURN @rcode
	END 
	
	IF @SMCostTypeCategory = 'O' 
	BEGIN 
		RETURN @rcode
	END

	-- Check to see that the selected Cost Type Category is in the selected Cost Type (SMCostType.Category)
	IF NOT EXISTS (	SELECT	1   
					FROM	SMCostType 
					WHERE	SMCo = @SMCo
						AND SMCostType = @SMCostType
						AND SMCostTypeCategory = @SMCostTypeCategory)
	BEGIN 
		SET @msg = 'Selected Cost Type not valid for the related Cost Type Category!'
		RETURN 1
	END 

	
	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspSMCostTypeCategoryVal] TO [public]
GO
