SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/30/13
-- Description:	Date Time stamp for Job Request
-- =============================================
CREATE PROCEDURE [dbo].[mckspJRStamp] 
	-- Add the parameters for the stored procedure here
	@Company int = 0, 
	@JRNum int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT @Company, @JRNum
	
	UPDATE dbo.budJobRequest
		SET QueueDate = CURRENT_TIMESTAMP
		WHERE @Company = Co AND @JRNum = RequestNum
END
GO
GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [MCKINSTRY\ViewpointUsers]
GO
