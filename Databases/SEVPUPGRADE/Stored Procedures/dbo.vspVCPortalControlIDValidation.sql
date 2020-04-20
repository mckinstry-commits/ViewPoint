SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Validation for retrieving a portal control id
-- =============================================
CREATE PROCEDURE [dbo].[vspVCPortalControlIDValidation]
	(@reportID AS INT, @portalControlID AS INT, @userIsViewpointcs AS BIT, @status AS VARCHAR(256) OUTPUT, @msg AS VARCHAR(150) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @status = pvReportControlsShared.Status, @msg = Name
	FROM pPortalControls
		LEFT JOIN pvReportControlsShared ON pPortalControls.PortalControlID = pvReportControlsShared.PortalControlID
			AND pvReportControlsShared.ReportID = @reportID
	WHERE pPortalControls.PortalControlID = @portalControlID
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @msg = CAST(@portalControlID AS VARCHAR) + ' is not a valid control id.'
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
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVCPortalControlIDValidation] TO [public]
GO
