SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 2/26/2014
-- Description:	Delete WF Consolidated Rich Text Layout and Columns because Viewpoint forgot to provide refresh capability
-- =============================================
CREATE PROCEDURE [dbo].[mckWFEmailDelete] 
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(60) = '',
	@ReturnMessage VARCHAR(255) OUTPUT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @rcode INT = 0

	DELETE FROM dbo.WDJBTableColumns 
		WHERE dbo.WDJBTableColumns.JobName = @JobName
	DELETE FROM dbo.WDJBTableLayout
		WHERE dbo.WDJBTableLayout.JobName = @JobName
	SELECT @ReturnMessage = 'Successfully deleted columns and layout for "'+@JobName+'"', @rcode=0
	RETURN @rcode

END
GO
