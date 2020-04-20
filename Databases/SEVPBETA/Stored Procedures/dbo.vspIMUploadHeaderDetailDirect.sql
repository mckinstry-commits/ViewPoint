SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspIMUploadHeaderDetailDirect]    
/**************************************************
*
*		Created By:   CC 06/30/2009
*		Modified By:  ECV 05/23/2011 Modified @errmsg to include previous value of @errmsg to preserve
*                                    original value for display. ROLLBACK was causing an error that replaced
*                                    the original error.
*                     JE 11/13/2012 TK-18465 Modified to not auto generate Workorder number form SM Work Orders
*							        because there will be additional imports where the WorkOrder number will be
*                                   needed and if the # is generated then there is no way to link up
*                     JE 11/13/2012 TK-18465 Added '' aroun dattimes, before only small datetime was quoted
*	
*
*		USAGE:
*			Upload data from IMWE to appropriate tables.  Designed 
*			for Header/Detail maintenance tables.  
*
*		INPUT PARAMETERS:
*			ImportId, Template
*
*		RETURN PARAMETERS:
*			Error Message, return code
*
*
*
*************************************************/     
@importid	VARCHAR(20)		= NULL, 
@template	VARCHAR(30)		= NULL, 
@errmsg		VARCHAR(500)	= NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON
    BEGIN TRY
		-----Initial validation------
		IF @importid IS NULL
		BEGIN
			SET @errmsg = 'No importid specified.';
			RETURN 1;
		END

		IF @template IS NULL
		BEGIN
			SET @errmsg = 'No template specified.';
			RETURN 1;
		END		
		
		DECLARE @NumberOfRecordTypes int;
		SELECT @NumberOfRecordTypes = COUNT(*) FROM IMTR WHERE ImportTemplate = @template
		IF @NumberOfRecordTypes <> 2
			BEGIN
				SET @errmsg = 'Incorrect number of record types, 2 expected (header, detail); found ' + CAST(ISNULL(@NumberOfRecordTypes, 0) AS VARCHAR(10))+ '.';
				RETURN 1;
			END
		-----------------------------
		-----Get Header/Detail forms & record types, validate that they are not batch forms------
		DECLARE   @IsHeaderBatchForm	bYN
				, @HeaderRecordType		VARCHAR(30)
				, @HeaderForm			VARCHAR(30)
				, @HeaderView			VARCHAR(30)
				, @IsDetailBatchForm	bYN
				, @DetailRecordType		VARCHAR(30)
				, @DetailForm			VARCHAR(30)
				, @DetailView			VARCHAR(30)
				, @rcode				INT
				, @quote				CHAR(1)
				, @DeleteStatement		VARCHAR(MAX)
				, @IMWMInsert			VARCHAR(MAX)
				, @HeaderInsert			VARCHAR(MAX)
				, @DetailInsert			VARCHAR(MAX)
				, @ErrorNumber			INT
				, @InsertStatement		NVARCHAR(MAX)
				, @InsertCursorStatus	INT
				, @InsertForm			VARCHAR(30)
				;
		
		DECLARE @InsertStatements TABLE
		(
			  StatementNumber	INT IDENTITY(-2147483648, 1)
			, InsertStatement	NVARCHAR(MAX)
			, Form				VARCHAR(30)
		);
		
		SELECT	  @quote = ''''
				, @rcode = 0
				;

		SELECT @HeaderRecordType = MIN(RecordType)
		FROM dbo.IMTR
		WHERE dbo.IMTR.ImportTemplate = @template;

		SELECT	  @IsHeaderBatchForm = IMForm.BatchYN
				, @HeaderForm = IMForm.Form
				, @HeaderView = DDForm.ViewName
		FROM IMTR AS IMRecordTypes
		INNER JOIN DDFH AS DDForm	ON IMRecordTypes.Form = DDForm.Form
		INNER JOIN DDUF AS IMForm	ON DDForm.Form = IMForm.Form
		WHERE	IMRecordTypes.ImportTemplate = @template
				AND IMRecordTypes.RecordType = @HeaderRecordType
				;

		SELECT	  @IsDetailBatchForm = IMForm.BatchYN
				, @DetailForm = IMForm.Form
				, @DetailRecordType = IMRecordTypes.RecordType
				, @DetailView = DDForm.ViewName
		FROM IMTR AS IMRecordTypes
		INNER JOIN DDFH AS DDForm	ON IMRecordTypes.Form = DDForm.Form
		INNER JOIN DDUF AS IMForm	ON DDForm.Form = IMForm.Form
		WHERE	IMRecordTypes.ImportTemplate = @template
				AND IMRecordTypes.RecordType > @HeaderRecordType
				;
		
		IF @HeaderForm IS NULL 
			BEGIN
				SET @errmsg = 'Header form not found.'
				RETURN 1;
			END

		IF @DetailForm IS NULL 
			BEGIN
				SET @errmsg = 'Detail form not found.'
				RETURN 1;
			END
		
		IF @HeaderView IS NULL 
			BEGIN
				SET @errmsg = 'Header view not found.'
				RETURN 1;
			END

		IF @DetailView IS NULL 
			BEGIN
				SET @errmsg = 'Detail view not found.'
				RETURN 1;
			END
		
		IF @IsHeaderBatchForm = 'Y' OR @IsDetailBatchForm = 'Y'
			BEGIN
				SET @errmsg = 'Procedure "vspIMUploadHeaderDetailDirect" cannot upload batch forms, use "bspIMUploadHeaderDetail".';
				RETURN 1;
			END

		-----------------------------
		----Get Company identifier---
		DECLARE   @HeaderCoIdentifier	INT
				;
		
		SELECT @HeaderCoIdentifier = MIN(Identifier)
		FROM IMWE 
		WHERE	ImportTemplate = @template 
				AND RecordType = @HeaderRecordType 
				AND ImportId = @importid;

		IF 	@HeaderCoIdentifier IS NULL
			BEGIN
				SET @errmsg = 'Company Identifier not found.'
				RETURN 1;
			END

		-----------------------------
		
		-----------------------------
		----Find auto seq. columns---
			--assuming only 1 auto sequence key per form
			--assuming header auto seq. column must be in detail key
			
			DECLARE	  @HeaderAutoSeqIdentifier	INT
					, @HeaderAutoSeqColumn		VARCHAR(30)
					, @NewHeaderAutoSeq			BIGINT
					, @DetailAutoSeqIdentifier	INT
					, @DetailAutoSeqColumn		VARCHAR(30)
					, @NewDetailAutoSeq			BIGINT
					;
			
			--find header auto seq. key
			SELECT	  @HeaderAutoSeqIdentifier = DDUD.Identifier
					, @HeaderAutoSeqColumn = DDUD.ColumnName
			FROM dbo.DDUD
			INNER JOIN dbo.DDFI ON	dbo.DDFI.Form = dbo.DDUD.Form 
									AND dbo.DDFI.Seq = dbo.DDUD.Seq 
									AND dbo.DDFI.ColumnName = dbo.DDUD.ColumnName
			WHERE	dbo.DDUD.Form = @HeaderForm
					AND dbo.DDFI.AutoSeqType <> 0
					AND dbo.DDFI.AutoSeqType <> ''
					AND dbo.DDFI.InputType = 1
					;
					
			--find detail auto seq. key
			SELECT	  @DetailAutoSeqIdentifier = dbo.DDUD.Identifier
					, @DetailAutoSeqColumn = dbo.DDUD.ColumnName
			FROM dbo.DDUD
			INNER JOIN dbo.DDFI ON	dbo.DDFI.Form = dbo.DDUD.Form 
									AND dbo.DDFI.Seq = dbo.DDUD.Seq 
									AND dbo.DDFI.ColumnName = dbo.DDUD.ColumnName
			WHERE	dbo.DDUD.Form = @DetailForm
					AND dbo.DDFI.AutoSeqType <> 0
					AND dbo.DDFI.AutoSeqType <> ''
					AND dbo.DDFI.InputType = 1
					;
					
		/**************************************************************************************/			
		/* TK-18465 SM Work Orders will always need a Work Order Number dont generate numbers */
			IF 	@HeaderForm = 'SMWorkOrder'	
				BEGIN;
					SELECT @HeaderAutoSeqIdentifier =NULL;
					SELECT @HeaderAutoSeqColumn =NULL	;		
					SELECT @DetailAutoSeqIdentifier =NULL;
					SELECT @DetailAutoSeqColumn =NULL	;
				END;	
												
		-----------------------------

		-----------------------------
		-------Find header keys------
		DECLARE @HeaderKeyColumns TABLE
				(
					  KeyColumn		VARCHAR(128)
					, Used			BIT
				);
		DECLARE	  @HeaderWhereClause	VARCHAR(MAX)
				, @WhereClauseAnd		VARCHAR(5)
				;
		
		IF @HeaderAutoSeqColumn IS NOT NULL AND @HeaderAutoSeqIdentifier IS NOT NULL
			BEGIN
				INSERT INTO @HeaderKeyColumns (KeyColumn, Used)
				SELECT DDUD.ColumnName, 0
				FROM dbo.DDUD
				WHERE	dbo.DDUD.Form = @HeaderForm
						AND dbo.DDUD.Identifier <> @HeaderAutoSeqIdentifier
						AND dbo.DDUD.UpdateKeyYN = 'Y'
						;
				
				INSERT INTO @HeaderKeyColumns (KeyColumn, Used)
				SELECT MIN(Identifier), 0
				FROM IMWE 
				WHERE	ImportTemplate = @template 
						AND RecordType = @HeaderRecordType 
						AND ImportId = @importid;	
				
				SELECT	  @HeaderWhereClause = ' WHERE '
						, @WhereClauseAnd = ' AND '
						;
			END			
				
		-------Find detail keys------
		DECLARE @DetailKeyColumns TABLE
				(
					  KeyColumn		VARCHAR(128)
					, Used			BIT
				);
		DECLARE	  @DetailWhereClause	VARCHAR(MAX)
				;
		
		IF @DetailAutoSeqColumn IS NOT NULL AND @DetailAutoSeqIdentifier IS NOT NULL
			BEGIN
				INSERT INTO @DetailKeyColumns (KeyColumn, Used)
				SELECT DDUD.ColumnName, 0
				FROM dbo.DDUD
				WHERE	dbo.DDUD.UpdateKeyYN = 'Y'
						AND dbo.DDUD.Form = @DetailForm
						AND dbo.DDUD.Identifier <> @DetailAutoSeqIdentifier;
				
				INSERT INTO @DetailKeyColumns (KeyColumn, Used)
				SELECT MIN(Identifier), 0
				FROM IMWE 
				WHERE	ImportTemplate = @template 
						AND RecordType = @DetailRecordType 
						AND ImportId = @importid;	
				
				SELECT	  @DetailWhereClause = ' WHERE '
						, @WhereClauseAnd = ' AND '
						;
			END
					
		-----------------------------
		
		DECLARE		  @HeaderRecKeyIdentifier		INT
					, @DetailRecKeyIdentifier		INT
					, @HeaderCursorStatus			INT
					, @DetailCursorStatus			INT
					, @HeaderErrorStatus			INT
					, @DetailErrorStatus			INT
					, @HeaderRecSequence			INT
					, @DetailRecSequence			INT
					, @HeaderRecKeyValue			INT
					, @CurrentHeaderIdentifier		INT
					, @CurrentDetailIdentifier		INT
					, @ImportColumn					VARCHAR(128)
					, @ImportValue					VARCHAR(MAX)
					, @Co							dbo.bCompany
					, @ColumnType					VARCHAR(128)
					, @DetailColumnType				VARCHAR(128)
					, @ValueList					VARCHAR(MAX)
					, @ColumnList					VARCHAR(MAX)
					, @DetailColumnList				VARCHAR(MAX)
					, @DetailValueList				VARCHAR(MAX)
					;
		
		SELECT @HeaderRecKeyIdentifier = TemplateDetail.Identifier
		FROM IMTD AS TemplateDetail
		INNER JOIN DDUD AS DefaultDetail ON TemplateDetail.Identifier = DefaultDetail.Identifier
		WHERE	TemplateDetail.ImportTemplate=@template AND 
				DefaultDetail.ColumnName = 'RecKey' AND
				TemplateDetail.RecordType = @HeaderRecordType AND 
				DefaultDetail.Form = @HeaderForm;

		SELECT @DetailRecKeyIdentifier = TemplateDetail.Identifier
		FROM IMTD AS TemplateDetail
		INNER JOIN DDUD AS DefaultDetail ON TemplateDetail.Identifier = DefaultDetail.Identifier
		WHERE	TemplateDetail.ImportTemplate=@template AND 
				DefaultDetail.ColumnName = 'RecKey' AND
				TemplateDetail.RecordType = @DetailRecordType AND 
				DefaultDetail.Form = @DetailForm;
				
		DECLARE HeaderCursor CURSOR LOCAL FAST_FORWARD FOR
		SELECT DISTINCT IMWE.RecordSeq 
		FROM IMWE 
		LEFT OUTER JOIN DDUD ON IMWE.Form = DDUD.Form AND DDUD.TableName = @HeaderView AND DDUD.Identifier = IMWE.Identifier 
		INNER JOIN		IMTD ON IMWE.ImportTemplate = IMTD.ImportTemplate AND IMWE.Identifier = IMTD.Identifier AND IMWE.RecordType = IMTD.RecordType 
		WHERE	IMWE.ImportId = @importid AND
				IMWE.ImportTemplate = @template AND
				IMWE.RecordType = @HeaderRecordType 
		ORDER BY IMWE.RecordSeq;

		OPEN HeaderCursor
		FETCH NEXT FROM HeaderCursor INTO @HeaderRecSequence
		SELECT @HeaderCursorStatus = @@FETCH_STATUS

		WHILE @HeaderCursorStatus = 0
		BEGIN -- Outer/header while
			SELECT	  @HeaderErrorStatus = 0
					, @DetailErrorStatus = 0
					;
			SELECT @IMWMInsert = NULL;
			--Build Header insert statement
			--Get Header reckey value (value that joins header to detail records)
			SELECT @HeaderRecKeyValue = UploadVal 
			FROM IMWE 
			WHERE	ImportTemplate = @template 
					AND RecordType = @HeaderRecordType
     				AND	Identifier = @HeaderRecKeyIdentifier 
     				AND RecordSeq = @HeaderRecSequence 
     				AND ImportId = @importid
						
			--Get the first identifier for this RecordSequence
			SELECT @CurrentHeaderIdentifier = MIN(Identifier) 
			FROM IMWE 
			WHERE IMWE.ImportId = @importid 
			AND IMWE.ImportTemplate = @template 
			AND IMWE.RecordType = @HeaderRecordType 
			AND IMWE.RecordSeq = @HeaderRecSequence
			
			WHILE @CurrentHeaderIdentifier IS NOT NULL
     		BEGIN --inner header rec while     			
     			SELECT	  @ImportColumn = NULL
     					, @ImportValue = NULL
     					;
     			SELECT @ImportColumn = ColumnName
     			FROM dbo.DDUD 
     			INNER JOIN dbo.IMWEDetail ON	DDUD.Form = dbo.IMWEDetail.Form 
     											AND dbo.DDUD.Identifier = dbo.IMWEDetail.Identifier
     			WHERE	dbo.DDUD.TableName = @HeaderView
     					AND dbo.IMWEDetail.ImportId = @importid
     					AND dbo.IMWEDetail.ImportTemplate = @template
     					AND dbo.IMWEDetail.RecordType = @HeaderRecordType
     					AND dbo.IMWEDetail.Identifier = @CurrentHeaderIdentifier
     					AND dbo.IMWEDetail.RecordSeq = @HeaderRecSequence
     					;
     			
     			SELECT @ImportValue = UploadVal
     			FROM dbo.IMWEDetail
     			WHERE	ImportId = @importid
     					AND RecordType = @HeaderRecordType
     					AND Identifier = @CurrentHeaderIdentifier
     					AND RecordSeq = @HeaderRecSequence
     					;
     					     			
     			IF @CurrentHeaderIdentifier = @HeaderCoIdentifier
     				SELECT @Co = @ImportValue;

				IF @CurrentHeaderIdentifier = @HeaderAutoSeqIdentifier
					BEGIN
						SELECT @ImportValue = ' ISNULL(MAX(' + @ImportColumn + '),0) + 1 ';
			 			SELECT	  @ValueList = ISNULL(@ValueList + ',' + @ImportValue, ' SELECT ' + @ImportValue)
								, @ColumnList = ISNULL(@ColumnList + ',' + @ImportColumn, 'INSERT INTO ' + @HeaderView + ' (' + @ImportColumn)
								;
						GOTO GetNextHeaderIdentifier;
					END
     			
     			IF ISNULL(@Co,'') = ''
					BEGIN
						--Write back to IMWE
						UPDATE IMWE
						SET UploadVal = '*MISSING REQUIRED VALUE*'
						WHERE	ImportId = @importid 
								AND ImportTemplate = @template 
								AND Identifier = @HeaderCoIdentifier 
								AND RecordSeq = @HeaderRecSequence;
    	
    					SELECT @errmsg = 'Company is null';

						INSERT INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, [Message])
    					VALUES (@importid, @template, @HeaderForm, @HeaderRecSequence, @HeaderCoIdentifier, NULL, @errmsg);
				
    					--dump this record seq.  go onto next one	
						SELECT @rcode = 1, @HeaderErrorStatus = 1;
    				    GOTO GetNextHeaderRecSeq;
					END
					
     			--if column does not allow nulls and value is null then write to IMWM and skip record
     			IF @ImportValue = '' OR @ImportValue IS NULL
     				BEGIN				 				 
     					IF (SELECT COLUMNPROPERTY(OBJECT_ID(@HeaderRecordType),@ImportColumn,'AllowsNull')) = 0 
     						--update upload value...message that Table.Column cannot be null
     						--stop developing this record, go to next record sequence
     						--write message to IMWM
     						BEGIN 
     							SELECT	  @rcode = 1
     									, @errmsg = 'Null value encountered.'
     									, @HeaderErrorStatus = 1
     									;
		     					
     							SELECT @errmsg = 'Identifier ' + convert(varchar(10), @CurrentHeaderIdentifier) + '.  Column : ' + @ImportColumn + ' does not allow null values!' 
		     					
     							INSERT INTO IMWM (ImportId, ImportTemplate, Form, RecordSeq, [Message], Identifier)
     							VALUES (@importid, @template, @HeaderForm, @HeaderRecSequence, @errmsg, @CurrentHeaderIdentifier);
		     
     							GOTO GetNextHeaderRecSeq;
     						END
     					ELSE
 							--set and empty string to null
 							SELECT @ImportValue = NULL;
     				END
     			     			
     			IF @ImportColumn IS NOT NULL
     				BEGIN
     					SELECT @ColumnType = ISNULL(ColType,'varchar') 
     					FROM DDUD 
     					WHERE	Form = @HeaderForm 
     							AND Identifier = @CurrentHeaderIdentifier;

 						IF @ImportValue IS NOT NULL
 							BEGIN
 								--escape single quotes in import values
								IF CHARINDEX(@quote,@ImportValue) > 0
 									--replace single quotes with single back-quotes
 									SELECT @ImportValue = REPLACE(@ImportValue, @quote, '`');
		     					
 								--wrap varchar, text, char, nvarchar, ntext, nchar values with single quotes
 								IF @ColumnType IN ('varchar', 'text', 'char', 'nvarchar', 'ntext', 'nchar')
 									IF ISNULL(@ImportValue, '') <> ''
 										SELECT @ImportValue = @quote + @ImportValue + @quote;
 									ELSE
 										SELECT @ImportValue = 'NULL';     						
		     					
 								--ltrim and quote smalldatetime values
								/* TK-18465 added datetime to column types */
 								IF @ColumnType IN ('smalldatetime','datetime')
 									IF ISNULL(@ImportValue, '') <> ''
 										SELECT @ImportValue = @quote + LTRIM(@ImportValue) + @quote;
 									ELSE
 										SELECT @ImportValue = 'NULL';
		     					
 								--strip commas from 'bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real' & verify value is numeric
 								IF @ColumnType IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
 									BEGIN
 										IF ISNULL(@ImportValue,'') = '' 
 											SELECT @ImportValue = 'NULL';
			 								
										SET @ImportValue = replace(@ImportValue, ',', '')
 										IF ISNUMERIC(@ImportValue) <> 1 AND @ImportValue IS NOT NULL AND @ImportValue <> 'NULL'
 											BEGIN
 												SELECT	  @rcode = 1
 														, @errmsg = 'Non numeric value encountered.'
 														, @HeaderErrorStatus = 1
 														, @errmsg = 'Identifier ' + convert(varchar(10), @CurrentHeaderIdentifier) + '.  Column : ' + @ImportColumn + ' does not allow non-numeric values!' 
 														;
				     	
 												UPDATE IMWE
 				  								SET UploadVal = '*VALUE NOT NUMERIC*'
 		          								WHERE	ImportId = @importid 
 		          										AND ImportTemplate = @template 
 														AND Identifier = @CurrentHeaderIdentifier 
 														AND RecordSeq = @HeaderRecSequence 
 														AND Form = @HeaderForm;
				     	
 												INSERT INTO IMWM (ImportId, ImportTemplate, Form, RecordSeq, [Message], Identifier)
 												VALUES (@importid, @template, @HeaderForm, @HeaderRecSequence, @errmsg, @CurrentHeaderIdentifier);
				     				
 												GOTO GetNextHeaderRecSeq;
 											END --Error condition for numerics
 								END -- numeric types
		 						
 								SELECT	  @ValueList = ISNULL(@ValueList + ',' + @ImportValue, ' SELECT ' + @ImportValue)
 										, @ColumnList = ISNULL(@ColumnList + ',' + @ImportColumn, 'INSERT INTO ' + @HeaderView + ' (' + @ImportColumn)
 										;		
 							END -- Import value is not null
					END -- Import column is not null
					
				IF	@HeaderWhereClause IS NOT NULL 
					AND EXISTS (SELECT TOP 1 1 
								FROM @HeaderKeyColumns 
								WHERE	KeyColumn = @ImportColumn
										AND Used = 0)
					BEGIN
						SELECT @HeaderWhereClause = @HeaderWhereClause +  @ImportColumn + ' = ' + @ImportValue + @WhereClauseAnd;
						
						UPDATE @HeaderKeyColumns 
						SET Used = 1 
						WHERE KeyColumn = @ImportColumn;
					END
					
					
				GetNextHeaderIdentifier:
					SELECT @CurrentHeaderIdentifier = MIN(Identifier)
					FROM dbo.IMWEDetail
					WHERE	dbo.IMWEDetail.ImportTemplate = @template
							AND dbo.IMWEDetail.RecordType = @HeaderRecordType
							AND dbo.IMWEDetail.RecordSeq = @HeaderRecSequence
							AND dbo.IMWEDetail.Identifier > @CurrentHeaderIdentifier
							;
				END --header seq while
				IF @HeaderAutoSeqColumn IS NOT NULL
				  -- Fix for issue 139663 APUI max seq comes either APUI or APUR which ever is greater
				  if @HeaderView = 'APUI'
				  begin
				    declare @newHeaderView varchar(500)
				    select @newHeaderView = '
                    (
                      select APCo,UIMth,max(UISeq) as UISeq from APUI where APCo='+convert(varchar(3),@Co)+' group by APCo,UIMth
                      union all
                      select APCo,UIMth,max(UISeq) as UISeq from APUR where APCo='+convert(varchar(3),@Co)+' group by APCo,UIMth
                    ) a
                    '
  					SELECT @HeaderInsert =  'DECLARE @NewValue TABLE ( NewAutoSequenceValue BIGINT ); ' 
						+ @ColumnList + ') OUTPUT inserted.' + @HeaderAutoSeqColumn + ' INTO @NewValue ' 
						+ @ValueList + ' FROM ' + @newHeaderView + LEFT(@HeaderWhereClause, LEN(@HeaderWhereClause) - LEN (@WhereClauseAnd)) + ' ;'
						+ ' SELECT @NewHeaderAutoSeq = NewAutoSequenceValue FROM @NewValue; ';
				  end
				  else
					SELECT @HeaderInsert =  'DECLARE @NewValue TABLE ( NewAutoSequenceValue BIGINT ); ' 
											+ @ColumnList + ') OUTPUT inserted.' + @HeaderAutoSeqColumn + ' INTO @NewValue ' 
											+ @ValueList + ' FROM ' + case @HeaderView when 'APUI' then 'APUR' else @HeaderView end + LEFT(@HeaderWhereClause, LEN(@HeaderWhereClause) - LEN (@WhereClauseAnd)) + ' ;'
											+ ' SELECT @NewHeaderAutoSeq = NewAutoSequenceValue FROM @NewValue; ';
				ELSE
					SELECT @HeaderInsert = @ColumnList + ') ' + @ValueList + ' ;';
     			
     			--insert insert statement into holding table
     			INSERT INTO @InsertStatements (InsertStatement, Form) VALUES (@HeaderInsert, @HeaderForm);
				
	     		--Clear out last values
 				SELECT	  @ColumnList	= NULL
 						, @ValueList	= NULL
 						, @ColumnType	= NULL
 						, @HeaderInsert	= NULL 						
     					;     			
				--detail processing
				DECLARE DetailCursor CURSOR LOCAL FAST_FORWARD FOR
				SELECT DISTINCT IMWE.RecordSeq 
				FROM IMWE 
				LEFT OUTER JOIN DDUD ON IMWE.Form = DDUD.Form AND DDUD.TableName = @DetailView AND DDUD.Identifier = IMWE.Identifier 
				INNER JOIN		IMTD ON IMWE.ImportTemplate = IMTD.ImportTemplate AND IMWE.Identifier = IMTD.Identifier AND IMWE.RecordType = IMTD.RecordType 
				WHERE	IMWE.ImportId = @importid 
						AND IMWE.ImportTemplate = @template 
						AND IMWE.RecordType = @DetailRecordType 
						AND IMWE.Identifier = @DetailRecKeyIdentifier
						AND dbo.IMWE.UploadVal = @HeaderRecKeyValue
				ORDER BY IMWE.RecordSeq;
				
				OPEN DetailCursor;
				FETCH NEXT FROM DetailCursor INTO @DetailRecSequence;
				SELECT @DetailCursorStatus = @@FETCH_STATUS;
								
				WHILE @DetailCursorStatus = 0
					BEGIN
						--Get the first identifier for this RecordSequence
						SELECT @CurrentDetailIdentifier = MIN(Identifier) 
						FROM IMWE 
						WHERE IMWE.ImportId = @importid 
						AND IMWE.ImportTemplate = @template 
						AND IMWE.RecordType = @DetailRecordType 
						AND IMWE.RecordSeq = @DetailRecSequence
						
						WHILE @CurrentDetailIdentifier IS NOT NULL
							BEGIN
								SELECT	  @ImportColumn = NULL
     									, @ImportValue = NULL
     									;
     							SELECT @ImportColumn = ColumnName
     							FROM dbo.DDUD 
     							INNER JOIN dbo.IMWEDetail ON	DDUD.Form = dbo.IMWEDetail.Form 
     															AND dbo.DDUD.Identifier = dbo.IMWEDetail.Identifier
     							WHERE	dbo.DDUD.TableName = @DetailView
     									AND dbo.IMWEDetail.ImportId = @importid
     									AND dbo.IMWEDetail.ImportTemplate = @template
     									AND dbo.IMWEDetail.RecordType = @DetailRecordType
     									AND dbo.IMWEDetail.Identifier = @CurrentDetailIdentifier
     									AND dbo.IMWEDetail.RecordSeq = @DetailRecSequence
     									;
     			
								SELECT @ImportValue = UploadVal
								FROM dbo.IMWEDetail
								WHERE	ImportId = @importid
										AND RecordType = @DetailRecordType
										AND Identifier = @CurrentDetailIdentifier
										AND RecordSeq = @DetailRecSequence
										;

								IF @ImportColumn IS NOT NULL
									BEGIN
									    SELECT @DetailColumnType = ISNULL(ColType,'varchar')
     									FROM DDUD 
     									WHERE	Form = @DetailForm 
     											AND Identifier = @CurrentDetailIdentifier;
								
								--Check for auto seq value, if yes, replace and get next
								IF @CurrentDetailIdentifier = @DetailAutoSeqIdentifier
									BEGIN									
										SELECT @ImportValue = ' ISNULL(MAX(' + @ImportColumn + '),0) + 1 ';
			 							SELECT	  @DetailValueList = ISNULL(@DetailValueList + ',' + @ImportValue, ' SELECT ' + @ImportValue)
												, @DetailColumnList = ISNULL(@DetailColumnList + ',' + @ImportColumn, 'INSERT INTO ' + @DetailView + ' (' + @ImportColumn)
												;
										GOTO GetNextDetailIdentifier;
									END
								--Check for *header* auto seq key, replace and get next
								IF @ImportColumn = @HeaderAutoSeqColumn
									BEGIN
										SELECT @ImportValue = '@NewHeaderAutoSeq';
										SELECT	  @DetailValueList = ISNULL(@DetailValueList + ',' + @ImportValue, ' SELECT ' + @ImportValue)
 												, @DetailColumnList = ISNULL(@DetailColumnList + ',' + @ImportColumn, 'INSERT INTO ' + @DetailView + ' (' + @ImportColumn)
										GOTO GetNextDetailIdentifier;
									END

									--if column does not allow nulls and value is null then write to IMWM and skip header & detail records
									IF @ImportValue = '' OR @ImportValue IS NULL
     									BEGIN				 				 
     										IF (SELECT COLUMNPROPERTY(OBJECT_ID(@DetailRecordType),@ImportColumn,'AllowsNull')) = 0 
     											--update upload value...message that Table.Column cannot be null
     											--stop developing this record, go to next record sequence
     											--write message to IMWM
     											BEGIN 
     												SELECT	  @rcode = 1
     														, @DetailErrorStatus = 1
     														, @errmsg = 'Identifier ' + convert(varchar(10), @CurrentDetailIdentifier) + '.  Column : ' + @ImportColumn + ' does not allow null values!'
     														;
							     					
     												SET @IMWMInsert = 'INSERT INTO IMWM (ImportId, ImportTemplate, Form, RecordSeq, [Message], Identifier) VALUES (' 
     																+ @quote + @importid + @quote + ', ' + @quote + @template + @quote + ', '  + @quote + @DetailForm + @quote 
     																+ ', ' + @quote + CAST(@HeaderRecSequence AS VARCHAR(10)) + @quote + ', '  + @quote + @errmsg + @quote 
     																+ ', '  + @quote + CAST(@CurrentDetailIdentifier AS VARCHAR(10))+ @quote + ');';
							     
     												GOTO GetNextHeaderRecSeq;
     											END
     										ELSE
 												--set and empty string to null
 												SELECT @ImportValue = NULL;
     									END

										IF CHARINDEX(@quote,@ImportValue) > 0
 											--replace single quotes with single back-quotes
 											SELECT @ImportValue = REPLACE(@ImportValue, @quote, '`');
 										
										--wrap varchar, text, char, nvarchar, ntext, nchar values with single quotes
										IF @DetailColumnType IN ('varchar', 'text', 'char', 'nvarchar', 'ntext', 'nchar')
 											IF ISNULL(@ImportValue, '') <> ''
 												SELECT @ImportValue = @quote + @ImportValue + @quote;
 											ELSE
 												SELECT @ImportValue = 'NULL';     						
		     					
 										--ltrim and quote smalldatetime values
 										IF @DetailColumnType = 'smalldatetime'
 											IF ISNULL(@ImportValue, '') <> ''
 												SELECT @ImportValue = @quote + LTRIM(@ImportValue) + @quote;
 											ELSE
 												SELECT @ImportValue = 'NULL';
										
 										--strip commas from 'bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real' & verify value is numeric
 										IF @DetailColumnType IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
 											BEGIN
 												IF ISNULL(@ImportValue,'') = '' 
 													SELECT @ImportValue = 'NULL';
					 								
												SET @ImportValue = replace(@ImportValue, ',', '')
 												IF ISNUMERIC(@ImportValue) <> 1 AND @ImportValue IS NOT NULL AND @ImportValue <> 'NULL'
 													BEGIN
 														SELECT	  @rcode = 1
 																, @DetailErrorStatus = 1
 																, @errmsg = 'Identifier ' + CONVERT(VARCHAR(10), @CurrentDetailIdentifier) + '.  Column : ' + @ImportColumn + ' does not allow non-numeric values!' 
 																;						     								     	
     												SET @IMWMInsert = 'INSERT INTO IMWM (ImportId, ImportTemplate, Form, RecordSeq, [Message], Identifier) VALUES (' 
     																+ @quote + @importid + @quote + ', ' + @quote + @template + @quote + ', '  + @quote + @DetailForm + @quote 
     																+ ', ' + @quote + CAST(@HeaderRecSequence AS VARCHAR(10))+ @quote + ', '  + @quote + @errmsg + @quote 
     																+ ', '  + @quote + CAST(@CurrentDetailIdentifier AS VARCHAR(10))+ @quote + ');';
						     				
 														GOTO GetNextHeaderRecSeq;
 													END --Error condition for numerics
 										END -- numeric types
											
										SELECT	  @DetailValueList = ISNULL(@DetailValueList + ',' + @ImportValue, ' SELECT ' + @ImportValue)
 												, @DetailColumnList = ISNULL(@DetailColumnList + ',' + @ImportColumn, 'INSERT INTO ' + @DetailView + ' (' + @ImportColumn)

									END --@ImportColumn IS NOT NULL
								GetNextDetailIdentifier:
								IF	@DetailWhereClause IS NOT NULL 
								AND EXISTS (SELECT TOP 1 1 
											FROM @DetailKeyColumns 
											WHERE	KeyColumn = @ImportColumn
													AND Used = 0)
								BEGIN
									SELECT @DetailWhereClause = @DetailWhereClause +  @ImportColumn + ' = ' + @ImportValue + @WhereClauseAnd;
									
									UPDATE @DetailKeyColumns 
									SET Used = 1 
									WHERE KeyColumn = @ImportColumn;
								END
								
								SELECT @CurrentDetailIdentifier = MIN(Identifier) 
								FROM IMWE 
								WHERE IMWE.ImportId = @importid 
								AND IMWE.ImportTemplate = @template 
								AND IMWE.RecordType = @DetailRecordType 
								AND IMWE.RecordSeq = @DetailRecSequence
								AND IMWE.Identifier > @CurrentDetailIdentifier;
							
							END	-- detail identifier while

					GetNextDetailRecSeq:
						IF @DetailErrorStatus = 0
							BEGIN
								IF @DetailAutoSeqColumn IS NOT NULL
									SELECT @DetailInsert =  @DetailColumnList + ') ' + @DetailValueList + ' FROM ' + @DetailView + LEFT(@DetailWhereClause, LEN(@DetailWhereClause) - LEN (@WhereClauseAnd)) + ' ;';
															
								ELSE
									SELECT @DetailInsert = @DetailColumnList + ') ' + @DetailValueList + ' ;';
								
     							--insert into holding table
								INSERT INTO @InsertStatements (InsertStatement, Form ) VALUES (@DetailInsert, @DetailForm);															
																
								IF @DetailWhereClause IS NOT NULL
									BEGIN
										--Reset detail where clause for auto seq.
										SELECT @DetailWhereClause = ' WHERE ';
										
										--Reset detail key columns for auto seq.
										UPDATE @DetailKeyColumns
										SET Used = 0;
									END
																
								--Clear out last values
 								SELECT	  @DetailColumnList	= NULL
 										, @DetailValueList	= NULL
 										, @DetailColumnType	= NULL
 										, @HeaderInsert		= NULL 						
     									;     									
							END
						ELSE
							GOTO GetNextHeaderRecSeq;

						FETCH NEXT FROM DetailCursor INTO @DetailRecSequence;
						SELECT @DetailCursorStatus = @@FETCH_STATUS;
					END--Loop for detail processing
				
			--process batched insert statements
			DECLARE InsertProcessing CURSOR LOCAL FAST_FORWARD FOR
			SELECT InsertStatement, Form
			FROM @InsertStatements
			ORDER BY StatementNumber;

			OPEN InsertProcessing;
			
			SET @NewHeaderAutoSeq = NULL;
			
			BEGIN TRANSACTION;
			
			FETCH NEXT FROM InsertProcessing INTO @InsertStatement, @InsertForm;
			SELECT @InsertCursorStatus = @@FETCH_STATUS;
			WHILE @InsertCursorStatus = 0
			BEGIN
						
				--Execute insert statement
				BEGIN TRY					
					IF @InsertForm = @HeaderForm
						EXECUTE sp_executesql @InsertStatement , N'@NewHeaderAutoSeq BIGINT OUTPUT', @NewHeaderAutoSeq = @NewHeaderAutoSeq OUTPUT;
					ELSE						
						EXECUTE sp_executesql @InsertStatement , N'@NewHeaderAutoSeq BIGINT', @NewHeaderAutoSeq = @NewHeaderAutoSeq;
				END TRY
				
				BEGIN CATCH
					DECLARE	  @ErrorMessage VARCHAR(MAX)
							;
							 
					SELECT	  @ErrorNumber = ERROR_NUMBER()
							, @ErrorMessage = ERROR_MESSAGE()
							;
					-- if transaction is uncommitable, rollback
					--IF (XACT_STATE()) <> 0
						WHILE @@TRANCOUNT >0
							ROLLBACK TRANSACTION;

					IF @IMWMInsert IS NOT NULL
						EXEC(@IMWMInsert);

					--insert the SQL statement into IMWM with error 9999
					INSERT INTO IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, [Message], SQLStatement)
					VALUES (@importid, @template, @InsertForm, @HeaderRecSequence, 9999, '', @InsertStatement);

					UPDATE dbo.IMWM
					SET	  Error = @ErrorNumber
						, [Message] = @ErrorMessage
					WHERE	ImportId = @importid
							AND ImportTemplate = @template
							AND Form = @InsertForm
							AND RecordSeq = @HeaderRecSequence;
					
					IF @@rowcount <> 1		  
						INSERT INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, [Message])
						VALUES(@importid, @template, @InsertForm, @HeaderRecSequence, @ErrorNumber, @ErrorMessage);
					
					IF @InsertForm = @HeaderForm
						SET @HeaderErrorStatus = 1;
					ELSE
						SET @DetailErrorStatus = 1;
					
					 SELECT	  @rcode = 1
     						, @errmsg = 'Data errors.  Check IM Work Edit and IMWM: '+@ErrorMessage
     						;     
				END CATCH
				
				IF @ErrorNumber <> 0
				BEGIN
					SELECT @HeaderErrorStatus = 1;
					GOTO GetNextHeaderRecSeq;
				END
			
			FETCH NEXT FROM InsertProcessing INTO @InsertStatement, @InsertForm;
     		SELECT @InsertCursorStatus = @@FETCH_STATUS;
     		
			END --insert processing loop
						
			GetNextHeaderRecSeq:
			
			SELECT	  @DetailValueList = NULL
					, @DetailColumnList = NULL
					, @ValueList = NULL
					, @ColumnList = NULL
					;
			
			IF CURSOR_STATUS('local','DetailCursor') > 0
				BEGIN
					CLOSE DetailCursor;
					DEALLOCATE DetailCursor;
				END
			
			IF CURSOR_STATUS('local','InsertProcessing') > 0
				BEGIN
					CLOSE InsertProcessing;
					DEALLOCATE InsertProcessing;
				END
					
			--Clear insert batch table
			DELETE @InsertStatements;
			
			--reset header key info
			UPDATE @HeaderKeyColumns
			SET Used = 0;
			
			IF @HeaderWhereClause IS NOT NULL
				SELECT @HeaderWhereClause = ' WHERE ';
			
			--if header and detail inserted successfully then delete header record from IM Work Edit
     		IF @HeaderErrorStatus = 0 AND @DetailErrorStatus = 0
     			BEGIN		 		 
     				IF @@TRANCOUNT >= 1     		
						WHILE @@TRANCOUNT > 0
							COMMIT TRANSACTION;
					--clear Error 9999 from IMWM for the importid for successful inserts
					DELETE FROM IMWM WHERE ImportId = @importid AND Error = 9999;

					--Delete Record from IMWE
					DELETE FROM IMWE WHERE ImportId = @importid AND RecordSeq = @HeaderRecSequence AND RecordType = @HeaderRecordType;
					DELETE FROM IMWENotes WHERE ImportId = @importid AND RecordSeq = @HeaderRecSequence AND RecordType = @HeaderRecordType;

					DELETE FROM IMWE WHERE ImportId = @importid AND RecordSeq = @HeaderRecSequence AND RecordType = @DetailRecordType;
					DELETE FROM IMWENotes WHERE ImportId = @importid AND RecordSeq = @HeaderRecSequence AND RecordType = @DetailRecordType;
     			END
     		ELSE
     			BEGIN
     				IF @@TRANCOUNT >= 1     		
     					WHILE @@TRANCOUNT > 1
     						ROLLBACK TRANSACTION;
					
					IF @IMWMInsert IS NOT NULL						
						EXEC(@IMWMInsert);
							     		     		     
     				SELECT	  @rcode = 1
     						, @errmsg = 'Data errors.  Check IM Work Edit and IMWM: '+ISNULL(@errmsg,'')
     						;     
     			END
	     
     		SELECT	  @ColumnList = NULL
     				, @ValueList =  NULL
     				, @HeaderErrorStatus = 0
     				;
     
     		SELECT @IMWMInsert = NULL;
	     
     		FETCH NEXT FROM HeaderCursor INTO @HeaderRecSequence
     		SELECT @HeaderCursorStatus = @@FETCH_STATUS
     		
		END ----Loop for header/outer while
     END TRY
     BEGIN CATCH			
		IF @@TRANCOUNT >= 1     		
			WHILE @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			
		SELECT @errmsg = 'SQL errors.  Check IM Work Edit and IMWM.';
		
		INSERT INTO IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, [Message])
		VALUES(@importid, @template, '', @HeaderRecSequence, ERROR_NUMBER(), ERROR_MESSAGE());  
		
		RETURN 1;
     END CATCH
     
     IF CURSOR_STATUS('local','HeaderCursor') > 0
		BEGIN
			CLOSE HeaderCursor;
			DEALLOCATE HeaderCursor;
		END     

     IF CURSOR_STATUS('local','InsertProcessing') > 0
		BEGIN
			CLOSE InsertProcessing;
			DEALLOCATE InsertProcessing;
		END

     IF CURSOR_STATUS('local','DetailCursor') > 0
		BEGIN
			CLOSE DetailCursor;
			DEALLOCATE DetailCursor;
		END     		
		
	RETURN @rcode;
END


GO
GRANT EXECUTE ON  [dbo].[vspIMUploadHeaderDetailDirect] TO [public]
GO
