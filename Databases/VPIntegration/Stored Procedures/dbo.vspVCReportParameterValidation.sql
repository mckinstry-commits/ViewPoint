SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 10/2/09
-- Description:	Updates Status in Report Setup Parameters tab
-- =============================================
CREATE PROCEDURE [dbo].[vspVCReportParameterValidation]
	(@reportID AS INT,
	@parameterName AS VARCHAR(30),
	@status AS VARCHAR(256) OUTPUT,
	@currentDefaultValue AS VARCHAR(60) OUTPUT,
	@msg AS VARCHAR(256) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @status = Status, @currentDefaultValue = ISNULL(PortalParameterDefault, ParameterDefault), @msg = Description
	FROM RPRPShared
	WHERE ReportID = @reportID AND ParameterName = @parameterName
	
	IF @@ROWCOUNT = 0
	BEGIN
		SET @msg = @parameterName + ' is not a valid parameter name.'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVCReportParameterValidation] TO [public]
GO
