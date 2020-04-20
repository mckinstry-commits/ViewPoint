SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPMRecordRelateRelGetUnRel]
/************************************************************************
* CREATED:	Dan Sochacki 08/25/2010   
* MODIFIED: TL 07/03/2013 Bug 54378 , Task; 54729 -Prevent  linking when missing from rec key id
*
* Main routine to handle Relating, Unrelating, Getting available records
*
* Inputs
*	@DataTable	- XML Dataset
*
* Outputs
*	@rcode		- 0 = successfull - 1 = error
*	@errmsg		- Error Message
*
*************************************************************************/
(@XMLData XML, @SearchStr NVARCHAR(100) = NULL, @TypeOfSearch NCHAR(1) = 'G', 
 @FromFormName NVARCHAR(128) = NULL, @msg varchar(255) output)

----with execute as 'viewpointcs'
	
AS
SET NOCOUNT ON

    DECLARE @cnt				int,
			@Category			varchar(30),
			@Co					tinyint,
			@Project			varchar(30),
			@FormName			varchar(30),
			@KeyID				bigint,
			@LinkedKeyID		bigint,
			@FormKeyID			bigint,
			@Detail				varchar(2),
			@DocType			varchar(30),
			@DocID				varchar(30),
			@Date				varchar(30),
			@Description		varchar(100),
			@Action				varchar(100),
			@TableName			varchar(100),
			@ReportDateFormat	tinyint,
			@ReportStyle		int,
			@Hack				int,
			@TempMsg			varchar(255),
			@RowCnt				int,
			@MaxRows			int,
			@TempRCode			int,
			@rcode				INT,
			@Module				NVARCHAR(30)





---- check search string parameter
IF ISNULL(@SearchStr,'') = ''
	BEGIN
	SET @SearchStr = NULL
	END



		
	---------------------------
	-- SETUP XML INFORMATION --
	---------------------------
	-- CREATE XMLTable TABLE --
	DECLARE @XMLTable TABLE 
			(RowID			int		IDENTITY,
			 Category		varchar(30),
			 Co				tinyint,
			 Project		varchar(30),
			 FormName		varchar(60),		
			 KeyID			bigint, 
			 LinkedKeyID	bigint,
			 FormKeyID		bigint,
			 Detail			varchar(2),
			 DocType		varchar(30),
			 DocID			varchar(30),
			 Date			varchar(20),
			 Description	varchar(100),
			 Action			varchar(20))
		 
	-- POPULATE DATA TABLE --
	INSERT INTO @XMLTable
		SELECT	NDS.Tab.value('Category[1]'		,'varchar(30)')		AS Category,
				NDS.Tab.value('Co[1]'			,'tinyint')			AS Co,
				NDS.Tab.value('Project[1]'		,'varchar(30)')		AS Project,
				NDS.Tab.value('FormName[1]'		,'varchar(60)')		AS FormName,
				NDS.Tab.value('KeyID[1]'		,'bigint')			AS KeyID,
				NDS.Tab.value('LinkedKeyID[1]'	,'bigint')			AS LinkedKeyID, 
				NDS.Tab.value('FormKeyID[1]'	,'bigint')			AS FormKeyID,  
				NDS.Tab.value('Detail[1]'		,'varchar(1)')		AS Detail,
				NDS.Tab.value('DocType[1]'		,'varchar(30)')		AS DocType,
				NDS.Tab.value('DocID[1]'		,'varchar(30)')		AS DocID,		
				NDS.Tab.value('Date[1]'			,'varchar(20)')		AS [Date],
				NDS.Tab.value('Description[1]'	,'varchar(100)')	AS [Description],
				NDS.Tab.value('Action[1]'		,'varchar(20)')		AS [Action]
		  FROM	@XMLData.nodes('/NewDataSet/Table1')				AS NDS(Tab)


	------------------
	-- PRIME VALUES --
	------------------
	SET @rcode = 0	
	SET @TempRCode = 0
	SET @RowCnt = 1
	SET @ReportStyle = 101
	SELECT @MaxRows = COUNT(*) FROM @XMLTable
	SELECT @Hack = COUNT(*) FROM @XMLTable WHERE [Action] = 'GETAVAILABLE'
	

	------------------------------------
	-- GET LOCALIZED DATE TYPE FORMAT --
	------------------------------------
	----SELECT	@ReportStyle = 
	----			CASE ReportDateFormat
	----				WHEN 1 THEN 101	-- mm/dd/yyyy
	----				WHEN 2 THEN 103	-- dd/mm/yyyy
	----				WHEN 3 THEN 111 -- yyyy/mm/dd
	----				ELSE 101
	----			END
	----  FROM	dbo.bHQCO h WITH (NOLOCK)
 ----LEFT JOIN	@XMLTable x ON h.HQCo = x.Co
 ----    WHERE	x.RowID = @RowCnt


	---------------------------
	-- LOOP THROUGH @XMLData --
	---------------------------
	WHILE @RowCnt <= @MaxRows
		BEGIN

			-----------------------------
			-- GET REQUEST INFORMATION --
			-----------------------------
			SELECT	@Category = Category, @Co = Co, @Project = Project, @FormName = FormName, 
					@KeyID = KeyID, @LinkedKeyID = LinkedKeyID, @FormKeyID = FormKeyID, 
					@Detail = Detail, @DocType = DocType, @DocID = DocID, 
					@Date = [Date], @Description = [Description], 
					@Action = [Action]
			  FROM  @XMLTable
		     WHERE	RowID = @RowCnt

			--Prevent linking for blank Form KeyID record. 
			--Form Default KeyID for blank records or new records is -1.
			IF @FormKeyID IS NULL OR @FormKeyID = -1
				BEGIN
					SET @msg = 'Missing From Form Record ID!'
					SET @rcode = 1
					GOTO vspExit
				END

			----------------------------
			-- GET CORRECT TABLE NAME --
			----------------------------
			SET @TableName = NULL
			IF ISNULL(@FormName,'') <> ''
				BEGIN
				----EXEC @TempRCode = vspPMRecordRelateGetBaseTable @FormName, @TableName output, @TempMsg OUTPUT
				EXEC @TempRCode = dbo.vspPMRecordRelationGetFormTable @FormName, @TableName OUTPUT, @TempMsg OUTPUT
				IF @TempRCode <> 0
					BEGIN
						SET @rcode = @TempRCode
						SET @msg = @TempMsg
						GOTO vspExit
					END
				END
						 			
			------------------------------------
			-- INSERT/DELETE RECORD RELATIONS --
			------------------------------------
			IF @Hack = 0
				BEGIN
					IF @Action = 'RELATE'
						BEGIN
						EXEC @TempRCode = dbo.vspPMRecordRelationRelate @KeyID, @FromFormName, @FormKeyID, @FormName, @TempMsg output	
						END
						
					IF @Action = 'UNRELATE'
						BEGIN
						EXEC @TempRCode = dbo.vspPMRecordRelationUnrelate @KeyID, @FromFormName, @LinkedKeyID, @FormName, @TempMsg output	
						END
	
				END
					
			IF @Action = 'GETAVAILABLE'
				BEGIN
					---- drop global temp table for search results if exists
					If Object_Id('tempdb..##SearchResults') IS NOT NULL
						begin
						DROP TABLE ##SearchResults
						END
					
					---- Create table for search results
					CREATE TABLE ##SearchResults
						(
						TableName NVARCHAR(128),
						ColumnName NVARCHAR(128),
						ColumnValue NVARCHAR(400),
						KeyID NVARCHAR(10)
						)
						
					---- create global temp table for search results and execute procedure to populate table
					IF @SearchStr IS NOT NULL
						BEGIN
						---- execute procedure to populate ##SearchResults
						EXEC dbo.vspPMRecordRelateKeyWordSearch @SearchStr, @TypeOfSearch
						
						---- if no valid search results insert dummy
						IF (SELECT COUNT(*) FROM ##SearchResults) = 0
							BEGIN
							INSERT INTO ##SearchResults ( TableName , ColumnName , ColumnValue , KeyID )
							VALUES  ( 'dbo.Dummy' , 'Dummy', 'Dummy', '999')
							END
						END
					
					-- EMPTY STRING DOES NOT WORK --
					IF ISNULL(@Project,'') = '' SET @Project = NULL
		
					EXEC @TempRCode = dbo.vspPMRecordRelationGetAvailable @Co, @Project, @FromFormName, @KeyID, @TableName, @TempMsg output		
					
				END

			---------------------------------------
			-- CHECK FOR ERROR IN ABOVE ROUTINES --
			---------------------------------------
			IF @TempRCode <> 0
				BEGIN
					SET @rcode = @TempRCode
					SET @msg = @TempMsg
					GOTO vspExit
				END
			
			----------------------
			-- UPDATE ROW COUNT --
			----------------------
			SET @RowCnt = @RowCnt + 1
		END


vspExit:
	 ----drop global temp table for search results if exists
	If Object_Id('tempdb..##SearchResults') is Not NULL
		begin
		DROP TABLE ##SearchResults
		END
		
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelateRelGetUnRel] TO [public]
GO
