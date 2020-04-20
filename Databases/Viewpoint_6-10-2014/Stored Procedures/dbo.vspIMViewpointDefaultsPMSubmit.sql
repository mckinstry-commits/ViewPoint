SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/21/10
-- Description:	Used by Imports to create values for needed or missing
--		data based upon Bidtek default rules. This will call 
--		coresponding bsp based on record type.
-- =============================================
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsPMSubmit]
	(@Company bCompany, @ImportId VARCHAR(20), @ImportTemplate VARCHAR(20), @Form VARCHAR(20), @rectype VARCHAR(30), @msg VARCHAR(120) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode INT

	SELECT @rcode = 0, @msg = ''

	SELECT @Form = Form FROM IMTR WHERE RecordType = @rectype AND ImportTemplate = @ImportTemplate
	    
	IF @Form = 'PMSubmittal'
	BEGIN
		EXEC @rcode = dbo.bspIMViewpointDefaultsPMSM @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg OUTPUT
	END
	IF @Form = 'PMSubmittalItems'
	BEGIN
		EXEC @rcode = dbo.vspIMViewpointDefaultsPMSI @Company, @ImportId, @ImportTemplate, @Form, @rectype, @msg OUTPUT
	END

	SELECT @msg = @msg + 'PM Submittal' + CHAR(13) + CHAR(10) + '[vspIMViewpointDefaultsPMSubmittal]'

	RETURN @rcode

END


GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPMSubmit] TO [public]
GO
