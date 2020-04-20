SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/30/13
-- Description:	Date Time stamp for Job Request
--/*This is no longer used.  We can drop.*/
-- =============================================
CREATE PROCEDURE [dbo].[mckspJRStamp] 
	(@Company int, 
	@JRNum INT,
	@rcode int
	,@ReturnMessage VARCHAR(255)=null output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Timestamp AS bDate
	--declare @rcode int
	SELECT @rcode = 0--, @msg = @msg

	SET @Timestamp = CURRENT_TIMESTAMP
    -- Insert statements for procedure here
	--SELECT @Company, @JRNum
	IF EXISTS(SELECT * FROM dbo.udJobRequest WHERE @Company = Co AND @JRNum = RequestNum AND QueueDate IS NULL)
	BEGIN
		UPDATE dbo.budJobRequest
			SET QueueDate = @Timestamp
			WHERE @Company = Co AND @JRNum = RequestNum

		SELECT @ReturnMessage = 'Your request was submitted at '+ CONVERT(VARCHAR(255),@Timestamp), @rcode = 0;
	--GOTO spexit
	END
	ELSE
	BEGIN
		SELECT @ReturnMessage = 'This request has already been submitted', @rcode = 1;
	--	--GOTO spexit		
	END
	
	spexit:
	BEGIN
		--RAISERROR (@ReturnMessage,@rcode,1)

		--SELECT 1/0
		return @rcode
END
	end
GO
GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [public]
GO
