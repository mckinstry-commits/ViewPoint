SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************  
* Create date: 9/24/09
* Created: Jacob Van Houten 09/24/2009
* Modified: AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*  
*  
* Validation for selecting a report id when setting up reports to be run from Connects
*  
*********************************/

CREATE PROCEDURE [dbo].[vspVCReportIDValidation]
	(@reportID AS INT,
	@status AS VARCHAR(256) OUTPUT,
	@msg AS VARCHAR(150) OUTPUT)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT	@status = [Status], 
			@msg = Title
		--use inline table function for performance issue
	FROM dbo.vfRPRTShared(@reportID)
	
	IF @@ROWCOUNT = 0
	BEGIN
		SET @msg = CAST(@reportID AS VARCHAR) + ' is not a valid report id.'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVCReportIDValidation] TO [public]
GO
