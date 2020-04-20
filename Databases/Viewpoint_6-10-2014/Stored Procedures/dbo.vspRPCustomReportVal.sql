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

	-- All reports require a valid location to ensure they may be run. 
	IF NOT EXISTS (	SELECT 1 FROM RPRL INNER JOIN RPRTShared ON RPRTShared.Location = RPRL.Location WHERE RPRTShared.ReportID = @ReportID) 
	BEGIN 
		SET @msg = 'Selected report does not have a valid location.' 
		RETURN 1
	END 


	IF (SELECT AppType FROM RPRTShared WHERE ReportID = @ReportID) <> 'Crystal'
	BEGIN
		SET @msg = 'Selected report type is not supported.'
		RETURN 1
	END 
	
    EXEC @rcode = dbo.vspRPReportVal @reportid = @ReportID, @msg = @msg OUTPUT
    
    RETURN @rcode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspRPCustomReportVal] TO [public]
GO
