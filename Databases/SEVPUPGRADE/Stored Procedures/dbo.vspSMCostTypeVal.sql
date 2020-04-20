SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMCostTypeVal]
-- =============================================
-- Author:		Lane Gresham
-- Create date: 07/21/11
-- Description:	Validation for SM Cost Type.
-- Modified:	JG 01/20/2012 - TK-11897 - Returning the JC Cost Type
-- =============================================
	@SMCo AS bCompany, 
	@SMCostType AS smallint, 
	@LineType AS tinyint=NULL, 
	@MustExist AS bYN, 
	@Job dbo.bJob = NULL,
	@LaborCode VARCHAR(15) = NULL,
	@PayType VARCHAR(10) = NULL,
	@Equipment dbo.bEquip = NULL,
	@MatlGroup dbo.bGroup = NULL,
	@Material bMatl = NULL,
	@Taxable bYN = NULL OUTPUT, 
	@JCCostType AS dbo.bJCCType = NULL OUTPUT,
	@msg AS varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @SMCostType IS NULL
	BEGIN
		SET @msg = 'Missing SM Cost Type!'
		RETURN 1
	END
	
	DECLARE @SMCostTypeCategory char(1)
	
	SELECT @msg = [Description], @SMCostTypeCategory = SMCostTypeCategory, @Taxable = TaxableYN
    FROM dbo.SMCostType
    WHERE SMCo = @SMCo AND SMCostType = @SMCostType
    
    IF @@rowcount <> 1
    BEGIN
		IF @MustExist = 'Y'
		BEGIN
			SET @msg = 'Cost Type has not been setup in SM Cost Type.'
			RETURN 1
		END
		
		RETURN 0
    END
	
	IF @LineType <> 3 AND @SMCostTypeCategory <> CASE @LineType WHEN 1 THEN 'E' WHEN 2 THEN 'L' WHEN 4 THEN 'M' WHEN 5 THEN 'M' ELSE '' END
	BEGIN 
		SET @msg = 'SM Cost Type Category doesn''t match the Work Completed line type.'
		RETURN 1
	END

	--TK-11897
    DECLARE @rcode TINYINT
    SET @rcode = 0

	EXEC	@rcode = vspSMJCCostTypeDefaultVal 
			@SMCo = @SMCo
			, @Job = @Job
			, @LaborCode = @LaborCode
			, @PayType = @PayType
			, @SMCostType = @SMCostType
			, @Equipment = @Equipment
			, @MatlGroup = @MatlGroup
			, @Material = @Material
			, @JCCostType = @JCCostType OUTPUT
			, @msg = @msg OUTPUT
    
    RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspSMCostTypeVal] TO [public]
GO
