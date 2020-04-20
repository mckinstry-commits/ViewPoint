SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/15/11
-- Description:	Validates that the EM company is valid and that the GL month used for posting is valid
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedEMCompanyVal]
	@EMCo bCompany, @PostMonth bMonth, @EMGroup bGroup = NULL OUTPUT, @IsPostMonthClosed bYN  = NULL OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @GLCo bCompany, @rcode int, @errmsg varchar(255)
	
	EXEC @rcode = dbo.bspEMCompanyValWithInfo @emco = @EMCo, @emgroup = @EMGroup OUTPUT, @emcoglco = @GLCo OUTPUT, @msg = @msg OUTPUT, @gloverride = NULL, @wocostcodechgyn = NULL
	
	IF @rcode <> 0 RETURN @rcode
	
	-- Check whether or not the batch month is closed
	SET @IsPostMonthClosed = 'N'
	EXEC @rcode = dbo.bspGLClosedMthSubVal @glco = @GLCo, @mth = @PostMonth, @msg = @errmsg OUTPUT
	IF (@rcode = 0) -- 0 return value means it is closed
	BEGIN
		SELECT @IsPostMonthClosed = 'Y', @msg = @errmsg
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
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedEMCompanyVal] TO [public]
GO
