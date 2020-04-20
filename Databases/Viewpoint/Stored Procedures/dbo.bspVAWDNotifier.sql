SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspVAWDNotifier]
		/***********************************************************************
		*  Created by: 	JM 08/23/02
		*
		*  Altered by: 	TV 10/29/02 - Cleanup
		*              	TV 01/17/03 issue 20408. Changed Convert(varchar(3),@InputValue) to Convert(varchar(50),@InputValue)
		*              	TV 05/17/03 20408. Checks param being passed in to see if it is numeric.
		*              	TV 10/15/03 22710. Correct insert statment
   		*				TV - 23061 added isnulls	
   		*				RT 04/27/04 - issue 24326, retrieve servername and fromaddress and pass to bspXP_SendMail.
   		*				MV 08/07/07 - #119594 - increased size of emailto,cc,bcc fields in bWDJB to 512
		*				CC 11/12/07 - #121258 - added trim to remove instance name and '\' if SMTP server not set
		*				CC 11/12/07 - #120619 - moved location of identity column definition for the select clause, remarked out the code to set @startpos
		*				CC 03/03/08 - #120840 - SProc re-write: additional error handling, loop removals, set based parameter replacements,
		*										use Viewpoint vMailQueue instead of bspXP_SendMail, unique temp table names, 
		*										allow for 1 email per result set, allow for grouping of emails to send 1 email per group of results
		*				CC 05/30/08 - #128451 - Wrapped line and footer with ISNULL for cases where no data is present.
		*				CC 06/09/08 - #127893 - Corrected issue with JobLine trimming the string correctly.
		*				CC 06/16/08 - #128689 - Corrected unclosed quote in the grouped where clause.
		*				CC 06/30/08 - #128847 - Added check for null job parameters and return an error if they exist.
		*				CC 09/30/08 - #130032 - Change WDJB update to use FirstRun and LastRun as datetime columns
		*				CC 11/03/08 - #130757 - Changed number of characters to trim because of SQL 2005 RTM error with LEN
		*				CC 01/26/09 - #131796 - Added check to verify grouping variables were populated, if not go straight to building the line query
		*				CC 01/28/09 - #129920 - Added ability to send event type notifications
		*				CC 07/01/09 - #132804 - Corrected single quote and beginning/end constant handling in consolidated emails (line query section)
		*				JV 09/01/09 - #135323 - Fixed the number of charcters to trim by using RTRIM. Related to issue #130757
		*				JV 11/24/09 - #132804 - Wrapped job email line with isnull
		*				RM 01/27/10 - #136686 - Changed the way the Seq column is added and updated.
		*				HH 10/02/12 - #TK-18072 - Fixed Parameter Value for replacement in Email Body(header)
		*				HH 10/18/12 - #TK-18459 - added support for VAInquiries
		*				DK 10/24/12 - #TK-18072 - Add support for Test Email option
		*				HH 11/12/12 - #TK-18867 - added support for RTF/HTML formatted emails
		*				HH 02/28/13 - #TK-148109- added To, CC, BCC, Subject to consolidation group validation list
		*				HH 03/01/13 - #TK-148108- removed quote handling on WDJP.InputValue
		*				HH 03/06/13 - #TK-148109- renamed Seq column 
		*			
		* Usage: Fires notifier email if select statement for Job finds qualifying data. 
		*
		***********************************************************************/
		@JobName VARCHAR(150), 
		@ExecuteBySQLJob TINYINT = 1,			-- 0 - Not run as a SQL Job (ie via Test Email or Send Email buttons); 1 - Run as SQL Job
		@SendToTestEmail VARCHAR(3000) = NULL
		WITH EXECUTE AS 'viewpointcs'
		
		AS  


		SET NOCOUNT ON
		DECLARE @ErrorMessage VARCHAR(MAX)
	BEGIN TRY    	        
		--get from address for email notification  
		DECLARE @FromAddress VARCHAR(255)
   		SELECT @FromAddress = ISNULL([Value], 'Notifier')
   		FROM WDSettings
   		WHERE Setting = 'FromAddress'
   	
		-- Get QueryName
		DECLARE @QueryName				VARCHAR(150) 
				,@QueryType				INT
				,@IsConsolidated		bYN 
				,@JobEmailTo			VARCHAR(3000)
				,@JobEmailCC			VARCHAR(3000) 
				,@JobEmailBCC			VARCHAR(3000) 
				,@JobEmailSubject		VARCHAR(3000) 
				,@JobEmailBody			VARCHAR(MAX)
				,@JobEmailBodyHtml		VARCHAR(MAX)
				,@JobEmailLine			VARCHAR(MAX)
				,@JobEmailFooter		VARCHAR(MAX)
				,@IsHTML				bYN


		SELECT	@QueryName				= QueryName
				,@QueryType				= QueryType
				,@IsConsolidated		= IsConsolidated
       			,@JobEmailTo			= CASE WHEN ISNULL(@SendToTestEmail,'') <> '' THEN @SendToTestEmail 
       											ELSE ISNULL(EmailTo,'')
       									  END 
				,@JobEmailCC			= CASE WHEN ISNULL(@SendToTestEmail,'') <> '' THEN ''
												ELSE ISNULL(EmailCC,'')
										  END
				,@JobEmailBCC			= CASE WHEN ISNULL(@SendToTestEmail,'') <> '' THEN ''
												ELSE ISNULL(BCC,'')
										  END 
				,@JobEmailSubject		= ISNULL(EmailSubject,'')
				,@JobEmailBody			= ISNULL(EmailBody,'')
				,@JobEmailBodyHtml		= ISNULL(EmailBodyHtml,'')
				,@JobEmailLine			= EmailLine
				,@JobEmailFooter		= EmailFooter
				,@IsHTML				= CASE	
												WHEN EmailFormat = 1 THEN 'Y'
												ELSE 'N'
											END
   		FROM [bWDJB]
		WHERE [JobName] = @JobName;

		IF (ISNULL(@QueryName,'') = '')
			RAISERROR('Invalid Query Name specified on the job', 16, 1);
		
		IF (@QueryType not in (0,1))
			RAISERROR('Invalid Query Type specified on the job', 16, 1);			

		IF (ISNULL(@JobEmailTo,'') = '' AND ISNULL(@SendToTestEmail,'') = '')
			RAISERROR('Missing recipient. Please enter email address in ''To'' field.' , 16, 1);

		-- Parsing parts for RTF/HTML formatted emails
		IF @IsHTML = 'Y'
		BEGIN
			DECLARE @TableHtml varchar(max)
			DECLARE @TableStart int
			DECLARE @TableEnd int

			DECLARE @HeaderHtml varchar(max)
			DECLARE @HeaderStart int
			DECLARE @HeaderEnd int

			DECLARE @DetailHtml varchar(max)
			DECLARE @DetailStart int
			DECLARE @DetailEnd int
			
			DECLARE @FrontPart varchar(max)
			DECLARE @FrontStart int
			DECLARE @FrontEnd int

			DECLARE @BackPart varchar(max)
			DECLARE @BackStart int
			DECLARE @BackEnd int

			SELECT @TableStart = PATINDEX ( '%<table%' , @JobEmailBodyHtml )
			SELECT @TableEnd = PATINDEX ( '%</table>%' , @JobEmailBodyHtml ) + len('</table>')
			SELECT @TableHtml = SUBSTRING ( @JobEmailBodyHtml ,@TableStart , @TableEnd - @TableStart )

			IF (SELECT HeaderIsVisible FROM WDJBTableLayout WHERE JobName = @JobName ) = 'Y'
			BEGIN
				SELECT @HeaderStart = PATINDEX ( '%<tr%' , @TableHtml )
				SELECT @HeaderEnd = PATINDEX ( '%</tr>%' , @TableHtml ) + len('</tr>')
				SELECT @HeaderHtml = SUBSTRING ( @TableHtml ,@HeaderStart , @HeaderEnd - @HeaderStart )

				SELECT @DetailHtml = SUBSTRING ( @TableHtml ,@HeaderEnd, len(@TableHtml) )
				SELECT @DetailStart = PATINDEX ( '%<tr%' , @DetailHtml )
				SELECT @DetailEnd = PATINDEX ( '%</tr>%' , @DetailHtml ) + len('</tr>')
				SELECT @DetailHtml = SUBSTRING ( @DetailHtml ,@DetailStart , @DetailEnd - @DetailStart )
			END
			ELSE
			BEGIN
				SELECT @DetailHtml = @TableHtml
				SELECT @DetailStart = PATINDEX ( '%<tr%' , @TableHtml )
				SELECT @DetailEnd = PATINDEX ( '%</tr>%' , @TableHtml ) + len('</tr>')
				SELECT @DetailHtml = SUBSTRING ( @DetailHtml ,@DetailStart , @DetailEnd - @DetailStart )
			END
			
		
			IF (SELECT HeaderIsVisible FROM WDJBTableLayout WHERE JobName = @JobName ) = 'Y'
			-- with header row
			BEGIN
				SELECT @FrontStart = 0
				SELECT @FrontEnd = PATINDEX ( '%</tr>%' , @JobEmailBodyHtml ) + len('</tr>')
				SELECT @FrontPart = SUBSTRING(@JobEmailBodyHtml, @FrontStart, @FrontEnd)
			END
			ELSE 
			-- without header row
			BEGIN
				SELECT @FrontStart = 0
				SELECT @FrontEnd = PATINDEX ( '%<tr>%' , @JobEmailBodyHtml )
				SELECT @FrontPart = SUBSTRING(@JobEmailBodyHtml, @FrontStart, @FrontEnd)
			END

			SELECT @BackStart = PATINDEX('%</table>%', @JobEmailBodyHtml)
			SELECT @BackEnd = len(@JobEmailBodyHtml)
			SELECT @BackPart = SUBSTRING(@JobEmailBodyHtml, @BackStart, @BackEnd)

			IF @IsConsolidated = 'Y'
			BEGIN
				SET @JobEmailBody = @FrontPart
				SET @JobEmailLine = @DetailHtml
				SET @JobEmailFooter	= @BackPart
			END
			ELSE
			BEGIN
				SET @JobEmailBody = @JobEmailBodyHtml
			END

		END
		-- End Parsing parts for RTF/HTML formatted emails

		-- Get Query text 
		DECLARE		@SelectClause			NVARCHAR(MAX)
					,@FromWhereClause		NVARCHAR(MAX)
					,@IsQueryEventBased		bYN

		-- WF Notifier Queries		
		IF @QueryType = 0
		BEGIN	
			SELECT	@SelectClause = ISNULL(SelectClause,'') 
					,@FromWhereClause = ISNULL(FromWhereClause,'')
					,@IsQueryEventBased = IsEventQuery
			FROM [bWDQY]
			WHERE [QueryName] = @QueryName;
		

			IF ISNULL(@IsQueryEventBased,'N') = 'Y'
				IF NOT EXISTS (SELECT TOP 1 1 FROM WDQF WHERE QueryName = @QueryName AND IsKeyField = 'Y')
					SET @IsQueryEventBased = 'N'

			IF @SelectClause = ''
			BEGIN
				SET @ErrorMessage = 'Blank ''Select Clause'' found in the query '''  + @QueryName + '''.';
				RAISERROR(@ErrorMessage, 16, 1);
			END

			IF @FromWhereClause = ''
			BEGIN
				SET @ErrorMessage = 'Blank ''FromWhere clause'' found in the query '''  + @QueryName + '''.';
				RAISERROR(@ErrorMessage, 16, 1);
			END
	       
			IF EXISTS (SELECT TOP 1 1 FROM WDJP WHERE JobName = @JobName AND InputValue IS NULL)
			BEGIN
				SET @ErrorMessage = 'Missing values in parameters for job '''  + @JobName + '''.  Please assign values to job parameters.';
				RAISERROR(@ErrorMessage, 16, 1);
			END

			-- Embed Identity column in Select Clause if not event based
			--IF @IsQueryEventBased = 'N'
			--SELECT @SelectClause = @SelectClause + ' ,IDENTITY (int, 1, 1) AS Seq '

			-- Replace params in @FromWhereClause with Input Values from WDJP 
			-- need to order by [Param] Desc (longest string) since sql replace is NOT whole word
			--SELECT @FromWhereClause = REPLACE(@FromWhereClause, [Param], QUOTENAME(REPLACE(InputValue,'''',''),'''')) FROM WDJP WHERE JobName = @JobName ORDER BY [Param] Desc
			SELECT @FromWhereClause = REPLACE(@FromWhereClause, [Param], InputValue) FROM WDJP WHERE JobName = @JobName ORDER BY [Param] Desc
		END	
		-- VA Inquiries
		ELSE
		BEGIN 
			SELECT	@SelectClause = ISNULL(Query,'') 
					,@FromWhereClause = ''
					,@IsQueryEventBased = (SELECT MAX(IsNotifierKeyField) FROM VPGridColumns WHERE QueryName = @QueryName)
			FROM VPGridQueries
			WHERE [QueryName] = @QueryName;
		
			IF ISNULL(@IsQueryEventBased,'N') = 'Y'
				IF NOT EXISTS (SELECT TOP 1 1 FROM VPGridColumns WHERE QueryName = @QueryName AND IsNotifierKeyField = 'Y')
					SET @IsQueryEventBased = 'N'

			IF @SelectClause = ''
			BEGIN
				SET @ErrorMessage = 'Blank ''Select Clause'' found in the query '''  + @QueryName + '''.';
				RAISERROR(@ErrorMessage, 16, 1);
			END

			IF EXISTS (SELECT TOP 1 1 FROM WDJP WHERE JobName = @JobName AND InputValue IS NULL)
			BEGIN
				SET @ErrorMessage = 'Missing values in parameters for job '''  + @JobName + '''.  Please assign values to job parameters.';
				RAISERROR(@ErrorMessage, 16, 1);
			END

			-- Embed Identity column in Select Clause if not event based
			--IF @IsQueryEventBased = 'N'
			--SELECT @SelectClause = @SelectClause + ' ,IDENTITY (int, 1, 1) AS Seq '

			DECLARE @VAInquiryQueryType INT;
			SELECT @VAInquiryQueryType = QueryType 
			FROM VPGridQueries 
			WHERE QueryName = @QueryName;
			
			-- create and stuff select statement for VA Inquiry type 'view'
			IF @VAInquiryQueryType = 1
			BEGIN
				SELECT @SelectClause =
					'SELECT' + STUFF
					(
						(
							SELECT ', ' + '['+ColumnName+']'
							FROM VPGridColumns C
							WHERE C.QueryName = Q.QueryName
							ORDER BY DefaultOrder
							FOR XML PATH('')
						), 1, 1, ''
					) 
					+ ' FROM '
					+ Q.Query 
					+ ISNULL(' WHERE ' + STUFF
					(
						(
							SELECT ' ' + ISNULL('['+P.ColumnName+']','') + ' ' + ISNULL(P.Comparison,'') + ' ' + ISNULL(P.ParameterName,'') + ' ' + ISNULL(P.Operator,'')
							FROM VPGridQueryParameters P
							WHERE P.QueryName = Q.QueryName
							ORDER BY P.Seq
							FOR XML PATH(''), ROOT('Query'), TYPE 
						).value('/Query[1]','VARCHAR(MAX)'), 1, 1, ''
					), '')
				FROM	VPGridQueries Q
				WHERE	QueryName = @QueryName;

				--Remove last and/or
				IF EXISTS(SELECT 1 FROM VPGridQueryParameters WHERE QueryName = @QueryName )
					SET @SelectClause = CASE WHEN (RIGHT(@SelectClause,3) IN ('AND', ' OR'))THEN LEFT(@SelectClause, LEN(@SelectClause)-3) END;

			END 
		
			-- Replace params in @SelectClause with Input Values from WDJP
			-- need to order by [Param] Desc (longest string) since sql replace is NOT whole word
			--SELECT @SelectClause = REPLACE(@SelectClause, [Param], QUOTENAME(REPLACE(InputValue,'''',''),'''')) FROM WDJP WHERE JobName = @JobName ORDER BY [Param] Desc
			SELECT @SelectClause = REPLACE(@SelectClause, [Param], InputValue) FROM WDJP WHERE JobName = @JobName ORDER BY [Param] Desc
		END


		-- create temp. @tempDataTableName table ---------------------
		DECLARE @tempDataTableName VARCHAR(40), @sql NVARCHAR(MAX);
		SET @tempDataTableName = 'tmp-' + CONVERT(VARCHAR(36),NEWID());

		IF @QueryType = 0
		BEGIN
			SET @sql = @SelectClause + ' INTO [' + @tempDataTableName + '] ' + @FromWhereClause;
			EXEC sp_executesql @sql;
		END
		ELSE IF @QueryType = 1
		BEGIN
			DECLARE @CreateTmpTable varchar(max)
			SET @CreateTmpTable = 
					'CREATE TABLE '+ '['+@tempDataTableName+']' +' (' + STUFF
					(
						(
							SELECT ', ' + '['+ColumnName+']' + ' VARCHAR(MAX)'
							FROM VPGridColumns C
							WHERE QueryName = @QueryName
							ORDER BY DefaultOrder
							FOR XML PATH('')
						), 1, 1, ''
					) + ' ) ' 
	
			SET @sql = @CreateTmpTable + ' INSERT INTO ' + '['+@tempDataTableName+']' +' EXEC sp_executesql N' + ''''+REPLACE(@SelectClause, '''', '''''')+''''
			EXEC sp_executesql @sql;
		END

		--------
		IF (@@error <> 0)
			RAISERROR('Cannot create temporary data table. Please check your query and its parameters.', 16, 1);


		-- If query is event based add hash column to table, purge old results
		IF @IsQueryEventBased = 'Y'
		BEGIN
			--Get hash columns
			DECLARE @HashKeyColumns		VARCHAR(MAX);
			SET @HashKeyColumns = 'CAST(HASHBYTES(N''MD5'', CONVERT(NVARCHAR(MAX), ';
			
			-- WF Notifier Query
			IF @QueryType = 0
			BEGIN 
				SELECT @HashKeyColumns = @HashKeyColumns + 'ISNULL(' + EMailField + ', '''')) + CONVERT(NVARCHAR(MAX), '
				FROM bWDQF
				WHERE	QueryName = @QueryName
						AND IsKeyField = 'Y';
			END
			-- VA Inquiry
			ELSE IF @QueryType = 1
			BEGIN 
				SELECT @HashKeyColumns = @HashKeyColumns + 'ISNULL(' + '[' + ColumnName + ']' + ', '''')) + CONVERT(NVARCHAR(MAX), '
				FROM VPGridColumns
				WHERE	QueryName = @QueryName
						AND IsNotifierKeyField = 'Y';
			END
			
			SELECT @HashKeyColumns = LEFT(@HashKeyColumns, LEN(@HashKeyColumns) - 25) + ') AS UNIQUEIDENTIFIER)';
					
			--Add hash column to temp table
			SET @sql = 'ALTER TABLE [' + @tempDataTableName + '] ADD KeyHash UNIQUEIDENTIFIER NULL;'					
			EXEC sp_executesql @sql
			
			--Populate hash column
			SET @sql = 'UPDATE [' + @tempDataTableName + '] SET KeyHash = ' + @HashKeyColumns + ';'			
			EXEC sp_executesql @sql
			
			--Purge old results
			SET @sql = 'DELETE vWFSentNotifications
			FROM vWFSentNotifications s
			LEFT OUTER JOIN [' + @tempDataTableName + '] t ON s.KeyHash = t.KeyHash
			WHERE t.KeyHash IS NULL AND s.JobName = ''' + @JobName + ''''						
			EXEC sp_executesql @sql
			
			--Delete any previously sent items from the temp table
			SET @sql = 'DELETE [' + @tempDataTableName + '] 
			FROM [' + @tempDataTableName + '] t
			INNER JOIN vWFSentNotifications s ON t.KeyHash = s.KeyHash
			WHERE s.JobName = ''' + @JobName + ''''						
			EXEC sp_executesql @sql
			
		END

		--Add sequence column to temp table
		SET @sql = 'ALTER TABLE [' + @tempDataTableName + '] ADD SeqForTmpTable int null;'
		EXEC sp_executesql @sql

		--Add sequence column to temp table
		SET @sql = 'WITH t AS (select SeqForTmpTable, ROW_NUMBER() OVER(Order By SeqForTmpTable) RowNum FROM [' + @tempDataTableName + ']) UPDATE t SET SeqForTmpTable=RowNum;'
		EXEC sp_executesql @sql
	

		--extract number of records in @tempDataTableName
		DECLARE @NumRows int
		SET @sql = 'SELECT @NumRows = ISNULL(MAX(SeqForTmpTable),0) FROM [' + @tempDataTableName + ']'
		EXEC sp_executesql @sql, N'@NumRows int OUTPUT', @NumRows = @NumRows OUTPUT;
		IF (@@error <> 0)
			RAISERROR('Cannot retrieve number of rows from temporary data table. Please check your query and its parameters.', 16, 1);

		-- Leave if no data in result set
		IF @NumRows = 0 
			GOTO Notifier_Exit
				
		--declare and initialize variables for pivot table     
		DECLARE @ColumnList					NVARCHAR(MAX), 
				@EmailFields				NVARCHAR(MAX), 
				@CTE						NVARCHAR(MAX)

		SELECT @ColumnList = '', @EmailFields = '', @CTE = ''

		-- WF Notifier Query
		IF @QueryType = 0
		BEGIN
			--build column and field list
			SELECT @ColumnList = @ColumnList + 'ISNULL(CAST(' + TableColumn + ' AS VARCHAR(MAX)),'''') AS ' + EMailField + ', ',
			@EmailFields = @EmailFields + EMailField + ', '
			FROM bWDQF WHERE QueryName = @QueryName
		END
		-- VA Inquiry
		ELSE IF @QueryType =1
		BEGIN
			--build column and field list
			SELECT @ColumnList = @ColumnList + 'ISNULL(CAST(' + '['+ColumnName+']' + ' AS VARCHAR(MAX)),'''') AS ' + '['+ColumnName+']' + ', ',
			@EmailFields = @EmailFields + '['+ColumnName+']' + ', '
			FROM VPGridColumns WHERE QueryName = @QueryName
		END
		
		-- #135323 - changed #130757 hack to using RTRIM to remove spaces instead of calculating with the spaces.

		--trim trailing comma
		SET @ColumnList = LEFT(@ColumnList, LEN(RTRIM(@ColumnList)) - 1)
		SET @EmailFields = LEFT(@EmailFields, LEN(RTRIM(@EmailFields)) - 1)

		--Create holding pivot table
		CREATE TABLE #ReplaceVal (col VARCHAR(MAX), val VARCHAR(MAX))

		--build pivot statment
		SET @CTE = 'WITH CTE AS ( SELECT ' + @ColumnList + ' FROM [' + @tempDataTableName + '] WHERE SeqForTmpTable = @RowNum  ) INSERT INTO #ReplaceVal SELECT col, val FROM CTE UNPIVOT(val FOR col IN(' + @EmailFields + ')) AS U'
		
		SET @sql = 'SELECT @CurrentRecord = KeyHash FROM [' + @tempDataTableName + '] WHERE SeqForTmpTable = @RowNum'
								
        IF @IsConsolidated = 'N'
		BEGIN
			--email variables	
			DECLARE @EmailTo VARCHAR(3000), @EmailCC VARCHAR(3000), @EmailBCC VARCHAR(3000), @EmailSubject VARCHAR(3000), @EmailBody VARCHAR(MAX)
		
			--counter variable
			DECLARE	 @RowNum int
					,@CurrentRecord UNIQUEIDENTIFIER
					
					
			SET @RowNum = 1
			WHILE @RowNum <= @NumRows
       		BEGIN
       			--Get email template for this iteration
				SELECT	@EmailTo = @JobEmailTo, 
						@EmailCC = @JobEmailCC, 
						@EmailBCC = @JobEmailBCC,
						@EmailSubject = @JobEmailSubject,
						@EmailBody = @JobEmailBody
							
       			-- Make sure #ReplaceVal is empty (truncate for minimal logging)
       			TRUNCATE TABLE #ReplaceVal
	
				--use sp_executesql to execute pivot for the current row
				EXEC sp_executesql @CTE, N'@RowNum int', @RowNum

            	-- Replace [field name] with its value in all email parameters: To, CC, BCC, Subject, Body
				SELECT @EmailTo = REPLACE(@EmailTo, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @EmailCC = REPLACE(@EmailCC, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @EmailBCC = REPLACE(@EmailBCC, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @EmailSubject = REPLACE(@EmailSubject, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @EmailBody = REPLACE(@EmailBody,  '[' + col + ']', val) FROM #ReplaceVal;
       
    	   		-- Send email 
        	   IF ISNULL(@EmailTo, '') <> ''
        			BEGIN
						IF @IsQueryEventBased = 'N'
							EXEC [dbo].[vspMailQueueInsert] @To = @EmailTo, @CC = @EmailCC, @BCC = @EmailBCC, @From = @FromAddress, @Subject = @EmailSubject, @Body = @EmailBody, @Source = N'Notifier', @IsHTML = @IsHTML						
						ELSE --Query is Event based
							BEGIN
								EXEC sp_executesql @sql, N'@RowNum int, @CurrentRecord UNIQUEIDENTIFIER OUTPUT', @RowNum = @RowNum, @CurrentRecord = @CurrentRecord OUTPUT;

								EXEC [dbo].[vspMailQueueInsert] @To = @EmailTo, @CC = @EmailCC, @BCC = @EmailBCC, @From = @FromAddress, @Subject = @EmailSubject, @Body = @EmailBody, @Source = N'Notifier', @IsHTML = @IsHTML						
								
								INSERT INTO vWFSentNotifications (KeyHash, JobName) 
									VALUES (@CurrentRecord, @JobName)
							END
					END
				-- Set RowNum
	       		SELECT @RowNum = @RowNum + 1
    	   	END 
		END -- End IsConsolidated = 'N'
		ELSE
		BEGIN
			DECLARE @GroupColumnList NVARCHAR(MAX), @GroupEmailFields NVARCHAR(MAX), 
					@tempGroupTableName NVARCHAR(40), @NumGroupRows int, @GroupWhere NVARCHAR(MAX),
					@WithBrackets NVARCHAR(MAX), @WithoutBrackets NVARCHAR(MAX);
			IF EXISTS(SELECT * FROM WFNFGrouping WHERE JobName = @JobName)
			BEGIN
			-----------------------------------Build Groups---------------------------------------------------
			--build grouping query
				--check if To, CC, BCC, Subject are in column list and if so check if they have [ in them
					--if [ exists in a given element add it to the column list
				SELECT @GroupColumnList = '', @GroupEmailFields = '', @WithBrackets = '', @WithoutBrackets = '', @GroupWhere = ''
				IF EXISTS (SELECT * FROM WFNFGrouping WHERE GroupBy = 'To' AND JobName = @JobName)
		   			WHILE CHARINDEX('[', @JobEmailTo) <> 0
					BEGIN

						SELECT @WithBrackets = SUBSTRING(@JobEmailTo, CHARINDEX('[', @JobEmailTo), CHARINDEX(']', @JobEmailTo) - CHARINDEX('[', @JobEmailTo)+1),
							   @WithoutBrackets = SUBSTRING(@JobEmailTo, CHARINDEX('[', @JobEmailTo)+1, CHARINDEX(']', @JobEmailTo)-(CHARINDEX('[', @JobEmailTo)+1))

						SELECT @GroupColumnList = @GroupColumnList + 'ISNULL(CAST(' + @WithBrackets + ' AS VARCHAR(MAX)),'''') AS ' + @WithBrackets + ', ',
							   @GroupEmailFields = @GroupEmailFields + @WithBrackets + ', ',
							   @GroupWhere = @GroupWhere + @WithoutBrackets + ' = ''' + @WithBrackets + ''' AND '

						SELECT @JobEmailTo = REPLACE(@JobEmailTo, @WithBrackets, '')
					END

				IF EXISTS (SELECT * FROM WFNFGrouping WHERE GroupBy = 'CC' AND JobName = @JobName)
			   		WHILE CHARINDEX('[', @JobEmailCC) <> 0
					BEGIN

						SELECT @WithBrackets = SUBSTRING(@JobEmailCC, CHARINDEX('[', @JobEmailCC), CHARINDEX(']', @JobEmailCC) - CHARINDEX('[', @JobEmailCC)+1),
							   @WithoutBrackets = SUBSTRING(@JobEmailCC, CHARINDEX('[', @JobEmailCC)+1, CHARINDEX(']', @JobEmailCC)-(CHARINDEX('[', @JobEmailCC)+1))

						SELECT @GroupColumnList = @GroupColumnList + 'ISNULL(CAST(' + @WithBrackets + ' AS VARCHAR(MAX)),'''') AS ' + @WithBrackets + ', ',
							   @GroupEmailFields = @GroupEmailFields + @WithBrackets + ', ',
							   @GroupWhere = @GroupWhere + @WithoutBrackets + ' = ''' + @WithBrackets + ''' AND '

						SELECT @JobEmailCC = REPLACE(@JobEmailCC, @WithBrackets, '')
					END

				IF EXISTS (SELECT * FROM WFNFGrouping WHERE GroupBy = 'BCC' AND JobName = @JobName)
			   		WHILE CHARINDEX('[', @JobEmailBCC) <> 0
					BEGIN

						SELECT @WithBrackets = SUBSTRING(@JobEmailBCC, CHARINDEX('[', @JobEmailBCC), CHARINDEX(']', @JobEmailBCC) - CHARINDEX('[', @JobEmailBCC)+1),
							   @WithoutBrackets = SUBSTRING(@JobEmailBCC, CHARINDEX('[', @JobEmailBCC)+1, CHARINDEX(']', @JobEmailBCC)-(CHARINDEX('[', @JobEmailBCC)+1))

						SELECT @GroupColumnList = @GroupColumnList + 'ISNULL(CAST(' + @WithBrackets + ' AS VARCHAR(MAX)),'''') AS ' + @WithBrackets + ', ',
							   @GroupEmailFields = @GroupEmailFields + @WithBrackets + ', ',
							   @GroupWhere = @GroupWhere + @WithoutBrackets + ' = ''' + @WithBrackets + ''' AND '

						SELECT @JobEmailBCC = REPLACE(@JobEmailBCC, @WithBrackets, '')
					END

				IF EXISTS (SELECT * FROM WFNFGrouping WHERE GroupBy = 'Subject' AND JobName = @JobName)
			   		WHILE CHARINDEX('[', @JobEmailSubject) <> 0
					BEGIN
						SELECT @WithBrackets = SUBSTRING(@JobEmailSubject, CHARINDEX('[', @JobEmailSubject), CHARINDEX(']', @JobEmailSubject) - CHARINDEX('[', @JobEmailSubject)+1),
							   @WithoutBrackets = SUBSTRING(@JobEmailSubject, CHARINDEX('[', @JobEmailSubject)+1, CHARINDEX(']', @JobEmailSubject)-(CHARINDEX('[', @JobEmailSubject)+1))

						SELECT @GroupColumnList = @GroupColumnList + 'ISNULL(CAST(' + @WithBrackets + ' AS VARCHAR(MAX)),'''') AS ' + @WithBrackets + ', ',
							   @GroupEmailFields = @GroupEmailFields + @WithBrackets + ', ',
							   @GroupWhere = @GroupWhere + @WithoutBrackets + ' = ''' + @WithBrackets + ''' AND '

						SELECT @JobEmailSubject = REPLACE(@JobEmailSubject, @WithBrackets, '')
					END	
		
				--check if consolidation grouping is valid
				DECLARE @InvalidGrouping VARCHAR(MAX)
				SELECT @InvalidGrouping = 'Invalid Consolidation Grouping. Please remove: '
				-- WF Query
				IF(@QueryType = 0)
				BEGIN
					SELECT @InvalidGrouping = COALESCE(@InvalidGrouping+ CHAR(13) + CHAR(10) ,'') + GroupBy 
					FROM WFNFGrouping 
					WHERE JobName = @JobName AND GroupBy NOT IN(	SELECT EMailField 
																	FROM WDQF 
																	WHERE QueryName = @QueryName)
					
					IF	EXISTS(SELECT 1 FROM WFNFGrouping WHERE JobName = @JobName
															AND GroupBy NOT IN(	SELECT EMailField 
																				FROM WDQF 
																				WHERE QueryName = @QueryName 
																				UNION ALL 
																				SELECT 'To'
																				UNION ALL
																				SELECT 'CC'
																				UNION ALL
																				SELECT 'BCC'
																				UNION ALL
																				SELECT 'Subject' ))
						RAISERROR(@InvalidGrouping, 16, 1)
				END
				-- VA Inquiry
				ELSE
				BEGIN
					SELECT @InvalidGrouping = COALESCE(@InvalidGrouping+ CHAR(13) + CHAR(10) ,'') + GroupBy 
					FROM WFNFGrouping 
					WHERE JobName = @JobName AND GroupBy NOT IN(	SELECT QuoteName(ColumnName) 
																	FROM VPGridColumns 
																	WHERE QueryName = @QueryName)
									
					IF	EXISTS(SELECT 1 FROM WFNFGrouping WHERE JobName = @JobName
															AND GroupBy NOT IN(	SELECT QuoteName(ColumnName) 
																				FROM VPGridColumns 
																				WHERE QueryName = @QueryName
																				UNION ALL 
																				SELECT 'To'
																				UNION ALL
																				SELECT 'CC'
																				UNION ALL
																				SELECT 'BCC'
																				UNION ALL
																				SELECT 'Subject' ))
						RAISERROR(@InvalidGrouping, 16, 1)
				END

				--build rest of the column list
				SELECT @GroupColumnList = @GroupColumnList + 'ISNULL(CAST(' + GroupBy + ' AS VARCHAR(MAX)),'''') AS ' + GroupBy + ', ',
					   @GroupEmailFields = @GroupEmailFields + GroupBy + ', ',
					   @GroupWhere = @GroupWhere + SUBSTRING(GroupBy, CHARINDEX('[', GroupBy)+1, CHARINDEX(']', GroupBy)-(CHARINDEX('[', GroupBy)+1)) + ' = ''' + SUBSTRING(GroupBy, CHARINDEX('[', GroupBy), CHARINDEX(']', GroupBy)) + ''' AND '
				FROM WFNFGrouping WHERE GroupBy NOT IN ('To', 'CC', 'BCC', 'Subject') AND JobName = @JobName
										AND (SELECT ISNULL(EmailSubject,'') FROM WDJB WHERE JobName = @JobName) not like '%'+GroupBy+'%'

				--(131796) If the column list, email fields, or where clause were not populated
				--exit the rest of this block
				IF LEN(@GroupColumnList) < 6 OR LEN(@GroupEmailFields) < 1 OR LEN(@GroupWhere) < 1
					GOTO Build_Line_Query

				--trim trailing comma
				SET @GroupColumnList = LEFT(@GroupColumnList, LEN(RTRIM(@GroupColumnList)) - 1)
				SET @GroupEmailFields = LEFT(@GroupEmailFields, LEN(RTRIM(@GroupEmailFields)) - 1)
				
				--trim trailing AND from the where replacement
				SET @GroupWhere = LEFT(@GroupWhere, LEN(@GroupWhere) - 4)
				
				--generate new group temp table name
				SET @tempGroupTableName = 'tmp-' + CONVERT(VARCHAR(36),NEWID());
			
				--final query looks like: select distinct (column list) into [newtemptable] from [temptable]
				SET @sql = 'SELECT DISTINCT ' + @GroupColumnList + ' INTO ' + QUOTENAME(@tempGroupTableName) + ' FROM ' + QUOTENAME(@tempDataTableName);


				EXEC (@sql);
				IF (@@error <> 0)
					RAISERROR('Cannot create temporary group table. Please check your query and its parameters.', 16, 1);

				SET @sql = 'ALTER TABLE [' + @tempGroupTableName + '] ADD [SeqForTmpTable] int NOT NULL IDENTITY(1,1)';
				EXEC (@sql);

				--extract number of records in @tempGroupTableName
				SET @sql = 'SELECT @NumGroupRows = ISNULL(MAX(SeqForTmpTable),0) FROM ' + QUOTENAME(@tempGroupTableName) 
				EXEC sp_executesql @sql, N'@NumGroupRows int OUTPUT', @NumGroupRows = @NumGroupRows OUTPUT;
				IF (@@error <> 0)
					RAISERROR('Cannot retrieve row number from temporary group table. Please check your query and its parameters.', 16, 1);

				-- Leave if no data in result set (nothing to group by)
				IF @NumGroupRows = 0 
					RAISERROR('No records in temp group table, nothing to group by. Please check your query and its parameters.', 16, 1);
			END

			--------------------------------------------------------------------------------------------------------------------------					
Build_Line_Query:
			----------------------------build line query-----------------------------------
			DECLARE @LineQuery NVARCHAR(MAX)
			IF @JobEmailLine IS NOT NULL AND RTRIM(LTRIM(@JobEmailLine)) <> ''
			BEGIN
			SELECT @JobEmailLine = REPLACE(@JobEmailLine, '''', '''''');

					IF CHARINDEX('[', @JobEmailLine) <> 0 AND CHARINDEX(']', @JobEmailLine) <> 0
					BEGIN
						DECLARE	  @FirstPartOfJobLine	VARCHAR(MAX)
								, @LastPartOfJobLine	VARCHAR(MAX);

								  --for the first part, take everything up to the first '[', not including the '['
						SELECT	  @FirstPartOfJobLine = SUBSTRING(@JobEmailLine, 1, CHARINDEX('[', @JobEmailLine) - 1)
								  --for the last part, take everything from the last ']' to the end, not including the ']'
								, @LastPartOfJobLine = REVERSE(LEFT(REVERSE(@JobEmailLine), CHARINDEX(']',REVERSE(@JobEmailLine))-1))
								;

						--update the line to have everything from the first '[' to the end
						SET @JobEmailLine = SUBSTRING(@JobEmailLine, CHARINDEX('[', @JobEmailLine), LEN(@JobEmailLine));

						--update the line to have everything from the last ']' to the begining
						SET @JobEmailLine = REVERSE(SUBSTRING(REVERSE(@JobEmailLine), CHARINDEX(']',REVERSE(@JobEmailLine)), LEN(@JobEmailLine)));

						-- WF Notifier Query
						IF @QueryType = 0
						BEGIN
							SELECT @JobEmailLine = REPLACE(@JobEmailLine, EMailField,''' + ISNULL(CAST(' + TableColumn + ' AS VARCHAR(MAX)),'''') + ''')
							FROM bWDQF WHERE QueryName = @QueryName;
						END
						-- VA Inquiry
						ELSE IF @QueryType = 1
						BEGIN
							SELECT @JobEmailLine = REPLACE(@JobEmailLine, '['+ColumnName+']',''' + ISNULL(CAST(' + '['+ColumnName+']' + ' AS VARCHAR(MAX)),'''') + ''')
							FROM VPGridColumns WHERE QueryName = @QueryName;
						END

						--add + to left hand side
						SET @JobEmailLine = '+ ''' + @JobEmailLine;
							 
						--handle left hand side to prepare it for combination with the first part of the line
						IF LEFT(LTRIM(@JobEmailLine), 2) = ''''
							SET @JobEmailLine = SUBSTRING(@JobEmailLine, 3, LEN(@JobEmailLine));

						--handle right hand side to prepare it for combination with the last part of the line
						IF RIGHT(@JobEmailLine, 3) =  '+ '''
							SET @JobEmailLine = SUBSTRING(@JobEmailLine, 1, LEN(@JobEmailLine)-3);
						ELSE --add closing quote to the right side
							SET @JobEmailLine = @JobEmailLine + '''';

						--combine the first part, the replaced values, and last part of the line for insertion into @LineQuery
						SET @JobEmailLine = ' + ''' + @FirstPartOfJobLine + ''' ' + @JobEmailLine + ' + ''' + @LastPartOfJobLine + ''' ';

						SELECT @LineQuery = 'DECLARE @BodyLine VARCHAR(MAX)
											 SELECT @BodyLine = ''''
											 SELECT @BodyLine = @BodyLine ' + @JobEmailLine + ' + CHAR(13) + CHAR(10) FROM ' + QUOTENAME(@tempDataTableName) +
											'; INSERT INTO #tmpMessages ([BodyLine]) VALUES (@BodyLine);';
					END
					ELSE
						SELECT @LineQuery = 'INSERT INTO #tmpMessages ([BodyLine]) VALUES (''' + @JobEmailLine + ''');';
										
			END
			ELSE
				SELECT @LineQuery = 'INSERT INTO #tmpMessages ([BodyLine]) VALUES ('''');';

			-------------------------------------------------------------------------------

			--build message holding table
			CREATE TABLE #tmpMessages(
									  KeyID int IDENTITY(1,1),
									  [To] VARCHAR(3000) NULL,
									  CC VARCHAR(3000) NULL,
									  BCC VARCHAR(3000) NULL,
									  [From] VARCHAR(3000) NULL,
									  [Subject] VARCHAR(3000) NULL,
									  BodyHeader VARCHAR(MAX) NULL,
									  BodyLine VARCHAR(MAX) NULL,
									  BodyFooter VARCHAR(MAX) NULL,
									  Source VARCHAR(30) NULL
									  )

			DECLARE @Newline VARCHAR(2)
			SET @Newline = CHAR(13) + CHAR(10)

			--see if grouping table was created
			IF @tempGroupTableName IS NULL
			BEGIN 
				--temp table not created, no groupings, send 1 email
       			-- Make sure #ReplaceVal is empty (truncate for minimal logging)
       			TRUNCATE TABLE #ReplaceVal

				--execute pivot for the first row
				SET @RowNum = 1
				EXEC sp_executesql @CTE, N'@RowNum int', @RowNum

            	-- Replace [field name] with its value in all email parameters: To, CC, BCC, Subject, Body(header), Footer
				-- Use the Job variables because they will not be re-used in this procedure
				SELECT @JobEmailTo = REPLACE(@JobEmailTo, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @JobEmailCC = REPLACE(@JobEmailCC, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @JobEmailBCC = REPLACE(@JobEmailBCC, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @JobEmailSubject = REPLACE(@JobEmailSubject, '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @JobEmailBody = REPLACE(@JobEmailBody,  '[' + col + ']', val) FROM #ReplaceVal;
				SELECT @JobEmailFooter = REPLACE(@JobEmailFooter,  '[' + col + ']', val) FROM #ReplaceVal;

				--insert message body into holding table
				EXEC(@LineQuery);
				DECLARE @NewRecord int
				SELECT @NewRecord = MAX(KeyID) FROM #tmpMessages

				UPDATE #tmpMessages SET [To] = @JobEmailTo, CC = @JobEmailCC, BCC = @JobEmailBCC, 
										[From] = @FromAddress, [Subject] = @JobEmailSubject, BodyHeader = @JobEmailBody, 
										BodyFooter = @JobEmailFooter, Source = 'Notifier'
								    WHERE KeyID = @NewRecord
			END --END @tempGroupTableName IS NULL
			ELSE 
			BEGIN
			--Groupings exist, send multiple messages
			----------------Setup for grouping -----------------------------
			--reset RowNum
			SET @RowNum = 1

			--extract number of records in grouping table
			SET @sql = 'SELECT @NumRows = ISNULL(MAX(SeqForTmpTable),0) FROM ' + QUOTENAME(@tempGroupTableName)
			EXEC sp_executesql @sql, N'@NumRows int OUTPUT', @NumRows = @NumRows OUTPUT;

			IF (@@error <> 0)
				RAISERROR('Cannot retrieve row number from temporary group table. Please check your query and its parameters.', 16, 1);

			DECLARE @WherePredicate NVARCHAR(MAX), @GroupingCTE NVARCHAR(MAX), @NewRec int, @EmailFooter NVARCHAR(MAX)
			--Create holding pivot table for the grouping criteria
			CREATE TABLE #Groups (col VARCHAR(MAX), val VARCHAR(MAX));
			
			--create pivot for the grouping
			SET @GroupingCTE = 'WITH CTE AS ( SELECT ' + @GroupColumnList + ' FROM ' + QUOTENAME(@tempGroupTableName) + ' WHERE SeqForTmpTable = @RowNum  ) INSERT INTO #Groups SELECT col, val FROM CTE UNPIVOT(val FOR col IN(' + @GroupEmailFields + ')) AS U'			

			--repopulate template variables because of destructive replace during group building
			SELECT	@JobEmailTo =	CASE 
										WHEN ISNULL(@SendToTestEmail,'') <> '' THEN @SendToTestEmail 
										ELSE ISNULL(EmailTo,'')
									END, 
					@JobEmailCC =	CASE 
										WHEN ISNULL(@SendToTestEmail,'') <> '' THEN ''
										ELSE ISNULL(EmailCC,'')
									END,
					@JobEmailBCC =	CASE 
										WHEN ISNULL(@SendToTestEmail,'') <> '' THEN ''
										ELSE ISNULL(BCC,'')
									END, 
					@JobEmailSubject = ISNULL(EmailSubject,'')
   			FROM [bWDJB]
			WHERE [JobName] = @JobName;
			----------------------------------------------------------------

			--loop through groupings
			WHILE @RowNum <= @NumRows
       			BEGIN
					-- clear temp tables
       				TRUNCATE TABLE #ReplaceVal
       				TRUNCATE TABLE #Groups					

       				--Get email template for this iteration
					SELECT	@EmailTo = @JobEmailTo, 
							@EmailCC = @JobEmailCC, 
							@EmailBCC = @JobEmailBCC,
							@EmailSubject = @JobEmailSubject,
							@EmailBody = @JobEmailBody,
							@EmailFooter = @JobEmailFooter,
							@WherePredicate = @GroupWhere

					--execute grouping pivot
					EXEC sp_executesql @GroupingCTE, N'@RowNum int', @RowNum

					--build where clause
					SELECT @WherePredicate = REPLACE(@WherePredicate, QUOTENAME(col), REPLACE(val,'''','''''')) FROM #Groups;
					
					SET @LineQuery = 'DECLARE @BodyLine VARCHAR(MAX)
								 SELECT @BodyLine = ''''
								 SELECT @BodyLine = @BodyLine ' + ISNULL(@JobEmailLine, '') + ' + CHAR(13) + CHAR(10) FROM ' + QUOTENAME(@tempDataTableName) +
								' WHERE '+ @WherePredicate +'; '+'
								INSERT INTO #tmpMessages ([BodyLine]) VALUES (@BodyLine);'
					
					--insert message body into holding table
					EXEC sp_executesql @LineQuery;

					SELECT @NewRec = MAX(KeyID) FROM #tmpMessages					

					--build replacement value pivot statment
					SET @CTE = 'WITH CTE AS (SELECT TOP 1 ' + @ColumnList + ' FROM ' + QUOTENAME(@tempDataTableName) + ' WHERE ' + @WherePredicate + ') INSERT INTO #ReplaceVal SELECT col, val FROM CTE UNPIVOT(val FOR col IN(' + @EmailFields + ')) AS U'			

					EXEC sp_executesql @CTE

					--insert parameter values
					INSERT INTO #ReplaceVal SELECT [Param], InputValue FROM WDJP WHERE JobName = @JobName;

            		-- Replace [field name] with its value in all email parameters: To, CC, BCC, Subject, Body(header), Footer
					SELECT @EmailTo = REPLACE(@EmailTo, '[' + col + ']', val) FROM #ReplaceVal;
					SELECT @EmailCC = REPLACE(@EmailCC, '[' + col + ']', val) FROM #ReplaceVal;
					SELECT @EmailBCC = REPLACE(@EmailBCC, '[' + col + ']', val) FROM #ReplaceVal;
					SELECT @EmailSubject = REPLACE(@EmailSubject, '[' + col + ']', val) FROM #ReplaceVal;
					SELECT @EmailBody = REPLACE(@EmailBody,  '[' + col + ']', val) FROM #ReplaceVal;
					SELECT @EmailFooter = REPLACE(@EmailFooter,  '[' + col + ']', val) FROM #ReplaceVal;
					
					-- Replace @Parameters with its value in Body(header)
					SELECT @EmailBody = REPLACE(@EmailBody,  col, val) FROM #ReplaceVal WHERE col LIKE '@%';

					--pre-queue email in #tmpMessages	
					UPDATE #tmpMessages SET [To] = @EmailTo, CC = @EmailCC, BCC = @EmailBCC, 
											[From] = @FromAddress, [Subject] = @EmailSubject, BodyHeader = @EmailBody, 
											BodyFooter = @EmailFooter, Source = 'Notifier'
									    WHERE KeyID = @NewRec
	
					SET @RowNum = @RowNum + 1
				END--End while loop
				
				-- Remove messages that do not contain information
				DELETE FROM #tmpMessages where LTRIM(RTRIM(ISNULL(BodyLine,''))) = ''
			END

  	   		-- Send email 
  	   		INSERT INTO vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source, IsHTML)
			SELECT [To], CC, BCC, [From], [Subject], ISNULL(BodyHeader,'') + @Newline + ISNULL(BodyLine,'') + @Newline + ISNULL(BodyFooter,''), Source, @IsHTML
			FROM #tmpMessages WHERE [To] IS NOT NULL

			IF @IsQueryEventBased = 'Y'
			BEGIN			
				SELECT @sql = 'INSERT INTO vWFSentNotifications (JobName, KeyHash)
								SELECT ''' + @JobName + ''', KeyHash 
								FROM ' + QUOTENAME(@tempDataTableName)						
								
				EXEC sp_executesql @sql
			END
			
			DROP TABLE #tmpMessages

		END -- End IsConsolidated ='N' Else block

		SET @ErrorMessage = NULL;
END TRY
BEGIN CATCH

		IF (OBJECT_ID('tempdb..#ReplaceVal') IS NOT NULL)
			DROP TABLE #ReplaceVal;

		IF (OBJECT_ID('tempdb..#tmpMessages') IS NOT NULL)
			DROP TABLE #tmpMessages;

		IF (OBJECT_ID('tempdb..#Groups') IS NOT NULL)
			DROP TABLE #Groups;

		IF (OBJECT_ID(@tempDataTableName) IS NOT NULL)
			BEGIN
				SET @sql = 'DROP TABLE ' + QUOTENAME(@tempDataTableName) ;
				EXEC (@sql);
			END

		IF (OBJECT_ID(@tempGroupTableName) IS NOT NULL)
			BEGIN
				SET @sql = 'DROP TABLE ' + QUOTENAME(@tempGroupTableName);
				EXEC (@sql);
			END

		IF @ExecuteBySQLJob = 1
		BEGIN
			SET @ErrorMessage = 
				'Job: ' + ISNULL(@JobName, 'n/a') + CHAR(13) + CHAR(10) +
				'Query: ' + ISNULL(@QueryName,'n/a') + CHAR(13) + CHAR(10) +
				'Error: ' + ISNULL(ERROR_MESSAGE(), 'n/a') + CHAR(13) + CHAR(10) +
				'Line: ' + ISNULL(CONVERT(varchar(5),ERROR_LINE()), 'n/a') + CHAR(13) + CHAR(10) + 
				'Query String:' + ISNULL('<<' + @sql + '>>', 'none') ;
		END
		ELSE
		BEGIN
			SET @ErrorMessage = ERROR_MESSAGE() + CHAR(13) + CHAR(10)
		END
		
		RAISERROR(@ErrorMessage, 16, 1); 

END CATCH

Notifier_Exit:
	IF @ExecuteBySQLJob = 1
	BEGIN
		-- no need to update the Last Run details when testing. 
		-- Because the actual run of this proc is done via Remote Helper, it should be run as viewpointcs, if not skip it. 
		DECLARE @JobLastRun VARCHAR(10)
		--Get last job run
		SELECT @JobLastRun = CONVERT(varchar(10), CASE WHEN NULLIF([last_run_date],0) IS NULL THEN GETDATE() ELSE CONVERT(datetime,CONVERT(VARCHAR(10),[last_run_date])) END, 101)
		FROM msdb.dbo.sysjobsteps
		
		WHERE [step_name] = @JobName;

		--Update WDJB with First/Last Run information
		UPDATE [bWDJB] SET 
			[FirstRun] = CASE WHEN [FirstRun] IS NULL THEN @JobLastRun ELSE [FirstRun] END,
			[LastRun] = @JobLastRun
		WHERE
			[JobName] = @JobName;
	END 
	
		IF (OBJECT_ID('tempdb..#ReplaceVal') IS NOT NULL)
			DROP TABLE #ReplaceVal;

		IF (OBJECT_ID('tempdb..#tmpMessages') IS NOT NULL)
			DROP TABLE #tmpMessages;

		IF (OBJECT_ID('tempdb..#Groups') IS NOT NULL)
			DROP TABLE #Groups;

		IF (OBJECT_ID(@tempDataTableName) IS NOT NULL)
			BEGIN
				SET @sql = 'DROP TABLE ' + QUOTENAME(@tempDataTableName);
				EXEC (@sql);
			END

		IF (OBJECT_ID(@tempGroupTableName) IS NOT NULL)
			BEGIN
				SET @sql = 'DROP TABLE ' + QUOTENAME(@tempGroupTableName);
				EXEC (@sql);
			END
GO
GRANT EXECUTE ON  [dbo].[bspVAWDNotifier] TO [public]
GO
