SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/21/10
-- Description: Used by Imports to create values for needed or missing
--				data based upon Viewpoint default rules.
-- =============================================
CREATE PROCEDURE [dbo].[vspIMViewpointDefaultsPMSI]
	(@Company bCompany, @ImportId VARCHAR(20), @ImportTemplate VARCHAR(20), @Form VARCHAR(20), @Rectype VARCHAR(30), @msg VARCHAR(120) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @FormHeader VARCHAR(20),
		@HeaderRecordType VARCHAR(10)

	SET @FormHeader = 'PMSubmittal'

	SELECT @HeaderRecordType = RecordType
	FROM IMTR WITH (NOLOCK)
	WHERE ImportTemplate = @ImportTemplate AND Form = @FormHeader;

	/* --- HERE IS WHERE WE START THE STATIC DEFAULTS */
		
	-- Set the Send values to 'Y' if the user want to overwrite the value or they want to use the default if the value is null
	UPDATE IMWE
	SET IMWE.UploadVal = 'Y'
	FROM IMWE
		INNER JOIN vfIMGetTemplateDetails(@ImportTemplate, @Rectype) TemplateDetails ON IMWE.Identifier = TemplateDetails.Identifier
	WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @Rectype AND TemplateDetails.ColumnName = 'Send'
		AND (TemplateDetails.UserOverwrite = 1 OR (TemplateDetails.UseDefault = 1 AND dbo.vpfIsNullOrEmpty(IMWE.UploadVal) = 1))
	
	/* --- HERE IS WHERE WE END THE STATIC DEFAULTS */

	/*---- HERE IS WHERE WE START THE PROCESS OF UPDATING THE RECORDS BASED ON THE HEADER VALUES */
	DECLARE @IdentifierMappings TABLE
	(
		DetailIdentifier INT,
		HeaderIdentifier INT,
		ForceOverwrite BIT,
		UserOverwrite BIT,
		UseDefault BIT
	)
	
	--Define which detail columns map to the header columns
	INSERT @IdentifierMappings
	SELECT DetailTemplateDetails.Identifier, HeaderTemplateDetails.Identifier, ForceOverwrite, DetailTemplateDetails.UserOverwrite, DetailTemplateDetails.UseDefault
	FROM (
		-- These are the column mappings that are defaulted from the header record
		SELECT 'PMCo' AS DetailColumnName, 'PMCo' AS HeaderColumnName, 1 AS ForceOverwrite
		UNION SELECT 'Project', 'Project', 1 
		UNION SELECT 'SubmittalType', 'SubmittalType', 1
		UNION SELECT 'Submittal', 'Submittal', 1
		UNION SELECT 'Rev', 'Rev', 1
		UNION SELECT 'Description', 'Description', 0
		UNION SELECT 'Status', 'Status', 0
		UNION SELECT 'DateReqd', 'DateReqd', 0
		UNION SELECT 'DateRecd', 'DateRecd', 0
		UNION SELECT 'ToArchEng', 'ToArchEng', 0
		UNION SELECT 'DueBackArch', 'DueBackArch', 0
		UNION SELECT 'DateRetd', 'DateRetd', 0
		UNION SELECT 'ActivityDate', 'ActivityDate', 0
		UNION SELECT 'CopiesReqd', 'CopiesReqd', 0
		UNION SELECT 'CopiesRecdArch', 'CopiesRecdArch', 0
		UNION SELECT 'CopiesSentArch', 'CopiesSentArch', 0
		UNION SELECT 'CopiesRecd', 'CopiesRecd', 0
		UNION SELECT 'CopiesSent', 'CopiesSent', 0
		UNION SELECT 'Issue', 'Issue', 0
		UNION SELECT 'SpecNumber', 'SpecNumber', 0
		UNION SELECT 'RecdBackArch', 'RecdBackArch', 0) CopyHeaderDefaultColums
	INNER JOIN vfIMGetTemplateDetails(@ImportTemplate, @Rectype) DetailTemplateDetails ON
		CopyHeaderDefaultColums.DetailColumnName = DetailTemplateDetails.ColumnName
	INNER JOIN vfIMGetTemplateDetails(@ImportTemplate, @HeaderRecordType) HeaderTemplateDetails ON
		CopyHeaderDefaultColums.HeaderColumnName = HeaderTemplateDetails.ColumnName
		
	--Run the update which will update the detail columns with the header column values based upon
	--the forceoverwrite values defined above and the template settings for overwritting and defaulting
	UPDATE IMWE
	SET IMWE.UploadVal = Header.UploadVal
	FROM IMWE
		INNER JOIN vfIMGetHeaderRecordSeq(@ImportTemplate, @ImportId, @Rectype, 'RecKey', @HeaderRecordType, 'RecKey') HeaderRecordSeq ON IMWE.RecordSeq = HeaderRecordSeq.DetailRecordSeq
		INNER JOIN IMWE Header ON IMWE.ImportTemplate = Header.ImportTemplate AND IMWE.ImportId = Header.ImportId AND Header.RecordSeq = HeaderRecordSeq.HeaderRecordSeq AND Header.RecordType = @HeaderRecordType
		INNER JOIN @IdentifierMappings IdentifierMappings ON IMWE.Identifier = IdentifierMappings.DetailIdentifier AND Header.Identifier = IdentifierMappings.HeaderIdentifier
	WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @Rectype
		AND (IdentifierMappings.ForceOverwrite = 1 OR IdentifierMappings.UserOverwrite = 1 OR (IdentifierMappings.UseDefault = 1 AND dbo.vpfIsNullOrEmpty(IMWE.UploadVal) = 1))
	/*---- HERE IS WHERE WE END THE PROCESS OF UPDATING THE RECORDS BASED ON THE HEADER VALUES */
END

GO
GRANT EXECUTE ON  [dbo].[vspIMViewpointDefaultsPMSI] TO [public]
GO
