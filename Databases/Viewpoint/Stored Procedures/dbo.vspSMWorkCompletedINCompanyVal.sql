SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 4/7/2011
-- Description:	Validates that the IN company is valid and that the GL month used for posting is valid
--
--	Parameter Notes:
--			@IsPostMonthClosed:		Returns 0 if the month is open or 1 if the month is closed.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedINCompanyVal]
	@INCo bCompany, 
	@PostMonth bMonth,
	@MaterialGroup bGroup OUTPUT,
	@IsPostMonthClosed bYN OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GLCo bCompany, @rcode int, @errmsg varchar(255)
	
	-- IN Co validation
	EXEC @rcode = dbo.vspINCompanyVal @INCo, @GLCo OUTPUT, @MaterialGroup OUTPUT, NULL, @msg OUTPUT
	IF (@rcode <> 0)
	BEGIN
		-- Invalid IN Co
		RETURN 1
	END
	
	-- Check whether or not the batch month is closed
	SET @IsPostMonthClosed = 'N'
	EXEC @rcode = dbo.bspGLClosedMthSubVal @GLCo, @PostMonth, @errmsg OUTPUT
	IF (@rcode = 0) -- 0 return value means it is closed
	BEGIN
		SELECT @IsPostMonthClosed = 'Y', @msg = @errmsg
	END
	
	-- Validate the batch month
	EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @GLCo, @mth = @PostMonth, @msg = @errmsg OUTPUT
	IF @rcode <> 0 
	BEGIN
		SET @msg = @errmsg
		RETURN @rcode
	END
	
	RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedINCompanyVal] TO [public]
GO
