USE [DBAdmin]
GO
/****** Object:  StoredProcedure [dbo].[sp_PromoteUDLookups]    Script Date: 12/22/2014 9:54:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/12/2014
-- Description:	Promotion for Lookups
-- Used for Viewpoint ud lookups which can be used on Reports and/or Fields
-- To copy the field overrides for any associated field use @ApplyToFields = 1
--	- Currently this option checks for existing field overrides and deletes and re-adds.  
--  - When a field is missing entirely, this portion of the script errors out and exits.
-- To copy the Report parameter lookups for any associated parameters use @ApplyToParams = 1
-- =============================================
ALTER PROCEDURE [dbo].[sp_PromoteUDLookups] 
	-- Add the parameters for the stored procedure here
	@LookupName VARCHAR(30) = 0, 
	@ApplyToFields int = 0, 
	@ApplyToRptParams INT = 0
	, @ReturnMessage VARCHAR(255) OUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	DECLARE @rcode INT = 0
	
	--DECLARE VARIABLES FOR UNIT TESTS
	--DECLARE @LookupName VARCHAR(30) = 'udARCM_Project', @ApplyToFields int = 0
	
	--VALIDATION
	IF NOT EXISTS(
		SELECT TOP 1 1 
		FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.vDDLHc
		WHERE Lookup = @LookupName
		)
		BEGIN
			SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Lookup not found at source.'
			GOTO spexit
		END
	--CHECK FOR EXISTING AT DESTINATION, DELETE AND OVERWRITE IF YES
	IF EXISTS (
		SELECT TOP 1 1
		FROM Viewpoint.dbo.vDDLHc WITH (NOLOCK)
		WHERE Lookup = @LookupName
		)
		BEGIN
			PRINT 'Deleting existing lookup header.'
			DELETE 
			FROM Viewpoint.dbo.vDDLHc 
			WHERE Lookup = @LookupName

			PRINT 'Deleting existing lookup details.'
			DELETE FROM Viewpoint.dbo.vDDLDc 
			WHERE Lookup = @LookupName
			SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Success: Deleted existing lookup. '
		END

	SELECT @LookupName, @ApplyToFields
	
	BEGIN TRY
		PRINT 'Inserting lookup header.'
		INSERT INTO Viewpoint.dbo.vDDLHc
				( Lookup ,
				  Title ,
				  FromClause ,
				  WhereClause ,
				  JoinClause ,
				  OrderByColumn ,
				  Memo ,
				  GroupByClause ,
				  Version
				)
		SELECT  Lookup ,
				Title ,
				FromClause ,
				WhereClause ,
				JoinClause ,
				OrderByColumn ,
				Memo ,
				GroupByClause ,
				Version 
				--,Source 
		FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDLHShared
		WHERE Lookup = @LookupName

		PRINT 'Success.'
		SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Success: Inserted lookup header. '

		PRINT  'Inserting lookup details.'
		INSERT INTO Viewpoint.dbo.vDDLDc
		        ( Lookup ,
		          Seq ,
		          ColumnName ,
		          ColumnHeading ,
		          Hidden ,
		          Datatype ,
		          InputType ,
		          InputLength ,
		          InputMask ,
		          Prec
		        )
		SELECT  Lookup ,
		        Seq ,
		        ColumnName ,
		        ColumnHeading ,
		        Hidden ,
		        Datatype ,
		        InputType ,
		        InputLength ,
		        InputMask ,
		        Prec 
		FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDLDShared
		WHERE Lookup = @LookupName
		PRINT 'Success'
		SELECT @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Success: Inserted lookup details. '
	END TRY
	BEGIN CATCH
		SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage,'')+ERROR_MESSAGE()
		GOTO spexit
	END CATCH

	IF @ApplyToFields = 1
	BEGIN
		PRINT 'Apply to field overrides'

		--CHECK FOR EXISTANCE OF DESTINATION FIELDS
		IF EXISTS(
			SELECT TOP 1 1 
			FROM [MCKTESTSQL04\VIEWPOINT].[Viewpoint].[dbo].[DDFIShared] srcI
				LEFT JOIN Viewpoint.dbo.DDFIShared dstI ON srcI.Form = dstI.Form AND srcI.Seq = dstI.Seq
				JOIN [MCKTESTSQL04\VIEWPOINT].[Viewpoint].[dbo].[DDFLShared] srcL ON srcI.Form = srcL.Form AND srcI.Seq = srcL.Seq
			WHERE dstI.Seq IS NULL
				AND srcL.Lookup = @LookupName
			)
			BEGIN
				PRINT 'Missing field: cannot apply lookup. '
				--CURRENT STATE: ERROR AND EXIT WHEN FIELDS ARE MISSING
				--WILL NEED TO RETURN TO THIS WHEN WE HAVE OUR udFIELDS AND Field Overrides promotion scripts completed.
				SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage,'') + 'Failed to apply to field overrides.  Not all fields exist at destination.'
				GOTO spexit
			END
			ELSE
			BEGIN
				BEGIN TRY
					--CHECK FOR EXISTING LOOKUP ASSIGNMENTS TO DELETE
					IF EXISTS(
						SELECT TOP 1 1 FROM Viewpoint.dbo.DDFLc
						WHERE Lookup = @LookupName
						)
						BEGIN
							PRINT 'Deleting existing lookup assignments.'
							DELETE FROM Viewpoint.dbo.DDFLc
							WHERE Lookup = @LookupName
							PRINT 'Success'
						END

					INSERT INTO Viewpoint.dbo.DDFLc
							( Form ,
							  Seq ,
							  Lookup ,
							  LookupParams ,
							  Active ,
							  LoadSeq
							)
					SELECT  Form ,
							Seq ,
							Lookup ,
							LookupParams ,
							Active ,
							LoadSeq
					FROM [MCKTESTSQL04\VIEWPOINT].[Viewpoint].[dbo].DDFLc
					WHERE Lookup = @LookupName
				END TRY
				BEGIN CATCH
					SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage,'') + ERROR_MESSAGE()
					GOTO spexit
				END CATCH

			END
		

		--DECLARE VARIABLES FOR UNIT TESTS
		--DECLARE @LookupName VARCHAR(30) = 'udARCM_Project', @ApplyToFields int = 0
		--SELECT *
		--FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDFLShared
		--WHERE Lookup = @LookupName 

		--SELECT * 
		--FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDLDShared
		--WHERE Lookup = @LookupName 

	END
	
	IF @ApplyToRptParams = 1
	BEGIN
		PRINT 'Apply to report parameters'
		--CHECK FOR EXISTING REPORT.  IF NONE, EXIT
		IF NOT EXISTS(
				SELECT TOP 1 1 
				FROM Viewpoint.dbo.RPRTShared t
					JOIN Viewpoint.dbo.RPPLShared l ON l.ReportID = t.ReportID
				WHERE l.Lookup = @LookupName
			)
			BEGIN
				PRINT 'No report(s) found at destination.  Cannot update parameter lookups.  Run the Report migration tool first.'
				SELECT @rcode = 1, @ReturnMessage = ISNULL(@ReturnMessage, '') + 'No report(s) found at destination.  Cannot update parameter lookups.  Run the Report migration tool first.'
				GOTO spexit
			END


		--CHECK FOR EXISTING REPORT PARAMETERS USING THE LOOKUP. THEN DELETE
		IF EXISTS(
			--DECLARE @LookupName VARCHAR(30) = 'udARCM_Project', @ApplyToFields int = 0
			SELECT TOP 1 lh.*
			FROM Viewpoint.dbo.RPPLShared lh
			WHERE lh.Lookup = @LookupName
			)
			BEGIN
				PRINT 'DELETE: Report parameter lookup assignments'
				DELETE FROM Viewpoint.dbo.RPPLShared
				WHERE Lookup = @LookupName
			END

		INSERT INTO Viewpoint.dbo.RPPLShared
		        ( ReportID ,
		          ParameterName ,
		          Lookup ,
		          LookupParams ,
		          LoadSeq ,
		          Active ,
		          Custom ,
		          Status
		        )
		SELECT dstH.ReportID ,
		          srcL.ParameterName ,
		          srcL.Lookup ,
		          srcL.LookupParams ,
		          srcL.LoadSeq ,
		          srcL.Active ,
		          srcL.Custom ,
		          srcL.Status	
		FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.RPPLShared srcL
			JOIN [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.RPRTShared srcH ON srcH.ReportID = srcL.ReportID
			JOIN Viewpoint.dbo.RPRTShared dstH ON srcH.Title = srcH.Title
		WHERE Lookup = @LookupName
	END

	
	/*

	--DECLARE VARIABLES FOR UNIT TESTS
	--DECLARE @LookupName VARCHAR(30) = 'udARCM_Project', @ApplyToFields int = 0
	SELECT *
	FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDFLShared
	WHERE Lookup = @LookupName 

	SELECT * 
	FROM [MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.DDLDShared
	WHERE Lookup = @LookupName 
	*/
	
	spexit:
	RETURN @rcode
END
