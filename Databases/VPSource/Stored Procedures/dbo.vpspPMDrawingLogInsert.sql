SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMDrawingLogInsert]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:		GF 09/05/2010 - issue #141031 use functin vfDateOnly
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a drawing log.
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@DrawingType bDocType,
	@Drawing bDocument,
	@DateIssued bDate,
	@Status bStatus,
	@Notes VARCHAR(MAX),
	@UniqueAttchID UNIQUEIDENTIFIER,
	@Description bDesc
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @msg VARCHAR(255), @DocCat VARCHAR(255)
	SELECT @DocCat = 'DRAWING'

	--Date Issued Validation
	----#141031
	IF (@DateIssued IS NULL) SET @DateIssued = dbo.vfDateOnly()

	--Drawing Number Validation
	IF (ISNULL(@Drawing, '') = '' OR @Drawing = '+')
	BEGIN
		DECLARE @nextDrawing INT
		SELECT @msg = NULL, @nextDrawing = (SELECT ISNULL(MAX(Drawing), 0) + 1 
										FROM [PMDG] WITH (NOLOCK) 
										WHERE [PMCo] = @PMCo 
											AND [Project] = @Project 
											AND [DrawingType] = @DrawingType 
											AND ISNUMERIC(Drawing) = 1 
											AND Drawing NOT LIKE '%.%' 
											AND SUBSTRING(LTRIM(Drawing), 1, 1) <> '0')

		EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextDrawing, @msg OUTPUT
		SET @Drawing = @msg
	END
	ELSE
	BEGIN
		SET  @msg = null
		EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @Drawing, @msg OUTPUT
		SET @Drawing = @msg
	
		--Drawing Type/Drawing pair validation
		IF EXISTS(SELECT 1 FROM PMDG WHERE [PMCo] = @PMCo and [Project] = @Project and [DrawingType] = @DrawingType and [Drawing] = @Drawing)
		BEGIN
			SET @msg = 'Drawing Type/Drawing # combination has already been used. Please use another Drawing number.'
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END

	--Status Validation
	IF @Status IS NULL SET @Status = (SELECT [BeginStatus] FROM [PMCO] WHERE [PMCo] = @PMCo)

	IF ([dbo].vpfPMValidateStatusCode(@Status, @DocCat)) = 0
	BEGIN
		SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '') + ' is not valid for Document Category: ' + ISNULL(@DocCat, '') + '.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END

	--Insert the Drawing log
	INSERT INTO PMDG 
		( PMCo
		, Project
		, DrawingType
		, Drawing
		, DateIssued
		, Status
		, Notes
		, UniqueAttchID
		, Description
		) 
	VALUES 
		( @PMCo
		, @Project
		, @DrawingType
		, @Drawing
		, @DateIssued
		, @Status
		, @Notes
		, @UniqueAttchID
		, @Description
		)

	DECLARE @KeyID INT
	SET @KeyID = SCOPE_IDENTITY()
	EXECUTE vpspPMDrawingLogGet @PMCo, @Project, @KeyID
	
vspExit:

END
GO
GRANT EXECUTE ON  [dbo].[vpspPMDrawingLogInsert] TO [VCSPortal]
GO
