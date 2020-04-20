SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/6/2014
-- Description:	Post Interface Change Prevention
-- =============================================
CREATE PROCEDURE [dbo].[mckPostIntChangeControl] 
	-- Add the parameters for the stored procedure here
	@JobStatus int = 0, 
	@ReturnMessage VARCHAR(255) OUTPUT
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode TINYINT = 0


    -- Insert statements for procedure here
	IF @JobStatus <> 0
	BEGIN
		SELECT @ReturnMessage = 'This project has already been interfaced.  Post interface changes should be done through accounting.', @rcode = 1
		RETURN @rcode
	END

	
END
GO
GRANT EXECUTE ON  [dbo].[mckPostIntChangeControl] TO [public]
GO
