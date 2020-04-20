SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham	
-- Create date: 02-18-11
-- Description:	Validates a Custom ReportID # 
-- =============================================
CREATE PROCEDURE [dbo].[vspRPCustomReportVal]
	@ReportID int, @msg varchar(60) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode int
	
	IF @ReportID < 10000 
	BEGIN
		SET @msg = 'Not a Custom Report. Please enter a valid Report ID.'
		RETURN 1
	END 
	
    EXEC @rcode = dbo.vspRPReportVal @reportid = @ReportID, @msg = @msg OUTPUT
    
    RETURN @rcode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspRPCustomReportVal] TO [public]
GO
