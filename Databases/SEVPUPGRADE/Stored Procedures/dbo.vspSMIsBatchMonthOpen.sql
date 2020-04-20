SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/28/11
-- Description:	Will return whether a batch month is open or not provided a GL company and a batch source.
--				Will also return the closest open month.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMIsBatchMonthOpen]
	@GLCo bCompany, @Source bSource, @BatchMonth bMonth, @IsMonthOpen bit = NULL OUTPUT, @ClosestOpenMonth bMonth = NULL OUTPUT, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @IsMonthOpen = IsMonthOpen, @ClosestOpenMonth = ClosestOpenMonth
	FROM dbo.vfGLClosedMonths(@Source, @BatchMonth)
	WHERE GLCo = @GLCo
	IF @@rowcount <> 1
	BEGIN
		SET @msg = 'The GL company ' + dbo.vfToString(@GLCo) + ' doesn''t appear to be setup.'
		RETURN 1
	END
	
	DECLARE @rcode int
	
	--Double check that the month we figured out is actually open
	EXEC @rcode = dbo.bspHQBatchMonthVal @glco = @GLCo, @mth = @ClosestOpenMonth, @source = @Source, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMIsBatchMonthOpen] TO [public]
GO
