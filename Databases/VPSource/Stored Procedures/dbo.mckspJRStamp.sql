
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
	(@Company int, 
	@JRNum INT
	,@msg VARCHAR(255)=null output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Timestamp AS bDate
	declare @rcode int
	SELECT @rcode = 0--, @msg = @msg

	SET @Timestamp = CURRENT_TIMESTAMP
    -- Insert statements for procedure here
	--SELECT @Company, @JRNum
	IF EXISTS(SELECT * FROM dbo.udJobRequest WHERE @Company = Co AND @JRNum = RequestNum AND QueueDate IS NULL)
	BEGIN
		UPDATE dbo.budJobRequest
			SET QueueDate = @Timestamp
			WHERE @Company = Co AND @JRNum = RequestNum

		SELECT @msg = 'Your request was been submitted at '+ CONVERT(VARCHAR(255),@Timestamp), @rcode = 5;
	--GOTO spexit
	END
	ELSE
	BEGIN
		SELECT @msg = 'This request has already been submitted', @rcode = 11;
	--	--GOTO spexit		
	END
	
	spexit:
	BEGIN
		RAISERROR (@msg,@rcode,1)

		--SELECT 1/0
		return @rcode
END
	end
GO

GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [MCKINSTRY\ViewPointTestUsers]
GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [MCKINSTRY\ViewpointUsers]
GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [PML1]
GRANT EXECUTE ON  [dbo].[mckspJRStamp] TO [PML2]
GO
