SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		David Solheim
-- Create date: 11/28/12
-- Description:	Validates that the GL month used for posting is valid
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedMiscGLMonthVal]
	@GLCo bCompany, @PostMonth bMonth, @JCCo bCompany = NULL, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int, @errmsg varchar(255)
	
	-- Check whether or not the batch month is closed
	EXEC @rcode = dbo.bspGLClosedMthSubVal @glco = @GLCo, @mth = @PostMonth, @msg = @errmsg OUTPUT
	IF (@rcode = 0) -- 0 return value means it is closed
	BEGIN
		SELECT @msg = @errmsg
		RETURN 1
	END
	
	-- Check whether or not the batch month is closed for Job related GLCo
	IF @JCCo IS NOT NULL
	BEGIN
		EXEC @rcode = dbo.bspGLClosedMthSubVal @glco = @JCCo, @mth = @PostMonth, @msg = @errmsg OUTPUT
		IF (@rcode = 0) -- 0 return value means it is closed
		BEGIN
			SELECT @msg = @errmsg
			RETURN 1
		END
	END
	
	EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @GLCo, @mth = @PostMonth, @msg = @errmsg OUTPUT
	
	IF @rcode <> 0 
	BEGIN
		SET @msg = @errmsg
		RETURN @rcode
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedMiscGLMonthVal] TO [public]
GO
