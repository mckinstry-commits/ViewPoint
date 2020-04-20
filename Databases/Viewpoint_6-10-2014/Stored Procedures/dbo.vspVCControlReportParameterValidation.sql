SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Validates that the report parameter is indeed a part of a report.
-- =============================================
CREATE PROCEDURE [dbo].[vspVCControlReportParameterValidation]
	(@reportID AS INT,
	@portalControlID AS INT,
	@reportParameter AS VARCHAR(30),
	@userIsViewpointcs AS BIT,
	@currentDefaultValue AS VARCHAR(60) OUTPUT,
	@currentDefaultValueDescription AS VARCHAR(60) OUTPUT,
	@currentAccess AS VARCHAR(256) OUTPUT,
	@status AS VARCHAR(256) OUTPUT,
	@msg AS VARCHAR(256) OUTPUT)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @msg = Description,
		@currentDefaultValue = ISNULL(pvReportParameterControlShared.PortalParameterDefault ,ISNULL(RPRPShared.PortalParameterDefault, ParameterDefault)),
		@currentAccess = CASE ISNULL(pvReportParameterControlShared.PortalAccess, RPRPShared.PortalAccess) WHEN 0 THEN 'Always Hide' WHEN 1 THEN 'Always Show' WHEN 2 THEN 'Show When Empty' END,
		@status = pvReportParameterControlShared.Status
	FROM RPRPShared
		LEFT JOIN pvReportParameterControlShared ON RPRPShared.ReportID = pvReportParameterControlShared.ReportID
			AND RPRPShared.ParameterName = pvReportParameterControlShared.ParameterName
			AND pvReportParameterControlShared.PortalControlID = @portalControlID
	WHERE RPRPShared.ReportID = @reportID AND RPRPShared.ParameterName = @reportParameter
	
	IF @@ROWCOUNT = 0
	BEGIN
		SET @msg = CAST(@reportParameter AS VARCHAR) + ' is not a valid report parameter for report: ' + CAST(@reportID AS VARCHAR)
		RETURN 1
	END

	-- We get the status if the record is saved. Otherwise the status is null at this point
	-- so we predict what the status will be.
	IF @status IS NULL
	BEGIN
		IF @userIsViewpointcs = 1
		BEGIN
			SET @status = 'Standard'
		END
		ELSE
		BEGIN
			SET @status = 'Custom'
		END
	END

	--If we have a matching description in the user/site parameters we display that
	SELECT @currentDefaultValueDescription = Description
	FROM pvPortalParameters
	WHERE KeyField = @currentDefaultValue
	
	--If we have a matching cache parameter we use it as the description
	SELECT @currentDefaultValueDescription = LabelText
	FROM pvPortalControlDetailsFields
	WHERE PortalControlID = @portalControlID AND '#' + ColumnName + '#' = @currentDefaultValue
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVCControlReportParameterValidation] TO [public]
GO
