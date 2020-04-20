
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspIMUploadHeaderDetailPay]
     
     /**************************************************
      *
      *  Created By:	MV 08/19/09
      *  Modified By:	MV 11/23/09 - #130949 @ExpMthID, @APTransID,@InvDateID 
	  *					MV 12/08/09 - #130949 @INMWinsert
	  *					GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
	  *					MV 02/14/11 - #142713
	  *					MV 03/21/13 - TFS 44601 - If Textura retg payment, bypass non-retg coding
	  *					MV 04/17/13 - TFS 47145 - Get Textura retg Flag before processing APTBs
      *
      *USAGE:
      *
      * Upload data from IMWE to APPB,APTB tables.  Designed 
      * for Textura AP Payment imports. Creates third payment 
	  * table records - APDB.  Handles retainage imported payments
	  * separately.  Looks for released retainage and creates APTBs 
	  * and APDBs.   
      *
      *INPUT PARAMETERS
      *    Company, ImportId, Template, Errmsg
      *
      *RETURN PARAMETERS
      *    Error Message
      *
      *None
      *
      *************************************************/
     
     
       (@importid varchar(20) = null, @template varchar(30) = null, @errmsg varchar(500) = null output)
     
     AS
	 SET NOCOUNT ON
     
     /* Store current state for ANSI_WARNINGS to restore at end. */
     DECLARE @ANSIWARN int
     SELECT @ANSIWARN = 0
     IF @@OPTIONS & 8 > 0
     	SELECT @ANSIWARN = 1
     SET ANSI_WARNINGS OFF
     
     
     --Locals
     DECLARE @ident int, @detailident int, @headrecseq int, @detailrecseq int, 
     @columnlist varchar(max), @valuelist varchar(max), @rcode int, 
     @detailcollist varchar(max), @detailvallist varchar(max),
     @detailinsert varchar(max), @headerinsert varchar(max),@headerkeyident int, 
     @detailkeyident int, @headerkeycol int, @detailkeycol int, @quote int, 
     @importcolumn varchar(30), @importvalue varchar(max), @coltype varchar(20),
     @headform varchar(30), @detailform varchar(30), @headerr int, @detailerr int,
     @deletestmt varchar(8000), @errcode int, @errdesc varchar(255), @ErrorMessage varchar(2048),
     @firstform varchar(30), @secondform varchar(30), @rectypecount int, @batchyn char(1), 
     @headtable varchar(10), @detailtable varchar(10), @headrectype varchar(10), 
     @detailrectype varchar(10), @batchid bBatchID, @batchmth varchar(25), @batchseq int,
     @batchlock varchar(max), @batchunlock varchar(max), @maxbatchid int, @sql varchar(max),
     @updateIMBC varchar(max), @imbccount int, @rc int, @retainageident int, @retainageYN bYN,
     @IMWMinsert varchar(max), @intrans int, @quoteloc int, @hcstatus int, @dcstatus int,
     @DetailCursorOpen int, @HeaderCursorOpen int,@TexturaYN bYN,@apdbrcode int,

	--APDB variables
	@ExpMth			bDate,			@APTrans		bTrans,		@APRef			varchar(15),
	@AmtToPay		bDollar,		@RetainageFlag	bYN,		@InvDate		bDate,
	@SL				VARCHAR(30),	@HeaderCMCo		bCompany,	@HeaderCMAcct	bCMAcct,
	@HeaderCMRef	bCMRef,		

	-- ID --
	@CoID		int, @MthID				int, @ExpMthID			int, @APTransID		int,   
	@InvDateID	int, @RetainageFlagID	int, @AmtToPayID		int, @APRefID		int,
	@SLID		int, @HeaderCMCoID		int, @HeaderCMAcctID	int, @HeaderCMRefID	int
     

     DECLARE @coident int, @co bCompany, @form varchar(30), @batchassign_errmsg varchar(8000)
     
     --the ascii code for a single quote
     SELECT @quote = 39
     
     --initialize the error code
     SELECT @rcode = 0, @ident = -1, @headrecseq = -1, @headerr = 0, @DetailCursorOpen = 0, @HeaderCursorOpen = 0, @apdbrcode = 0
     
     SELECT @rectypecount = count(ImportTemplate) FROM IMTR with (nolock) WHERE ImportTemplate = @template
     
     --we should only have 2 record types but we don't know which one is header or which one is detail
     IF @rectypecount = 2
     BEGIN
     	SELECT @headrectype = min(RecordType) FROM IMTR with (nolock) WHERE ImportTemplate = @template
     	SELECT @firstform = Form FROM IMTR with (nolock) WHERE ImportTemplate = @template and RecordType = @headrectype 
     	SELECT @detailrectype = RecordType FROM IMTR with (nolock) WHERE ImportTemplate = @template and RecordType > @headrectype
     	SELECT @secondform = Form FROM IMTR with (nolock) WHERE ImportTemplate = @template and RecordType = @detailrectype
     END
    -- set Textura flag 
	IF @template = 'AP Pay Txt'
	BEGIN
		SELECT @TexturaYN = 'Y'
	END
	ELSE
		BEGIN
		SELECT @TexturaYN = 'N'
		END

     SELECT @headform = Form, @batchyn = BatchYN FROM DDUF with (nolock) WHERE Form = @firstform 
     IF @batchyn = 'N'
     BEGIN
     	SELECT @headform = Form, @batchyn = BatchYN 
		FROM dbo.DDUF with (nolock) 
		WHERE Form = @secondform 
   		SELECT @headrectype = RecordType 
		FROM dbo.IMTR with (nolock) 
		WHERE ImportTemplate = @template and Form = @headform
   
     	IF @batchyn = 'N'
     	--we got an error here.  Bump out of procedure.
     	BEGIN
     		SELECT @errmsg = 'Unable to get upload form information', @rcode = 1
     		INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     		VALUES (@importid, @template, @firstform, @headrecseq, @errmsg)
     		GOTO bspexit
     	END
     	ELSE
			BEGIN
     			SELECT @detailform = Form 
				FROM dbo.DDUF 
				WHERE Form = @firstform 
   			-- correct the record types.
   				SELECT @detailrectype = RecordType FROM IMTR with (nolock) WHERE ImportTemplate = @template and Form = @detailform
   			END
		END
     ELSE
     	SELECT @detailform = Form 
		FROM dbo.DDUF with (nolock) 
		WHERE Form = @secondform 
     
		SELECT @headtable = ViewName 
		FROM dbo.vDDFH with (nolock) 
		WHERE Form = @headform
     
     IF @headtable = ''
     BEGIN
     	SELECT @errmsg = 'Unable to get Header table information', @rcode = 1
     	INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     	VALUES (@importid, @template, @firstform, @headrecseq, @errmsg)
     	GOTO bspexit
     END
     
     SELECT @detailtable = ViewName 
	 FROM dbo.vDDFH 
	 WHERE Form = @detailform
     
     IF @detailtable = ''
     BEGIN
     	SELECT @errmsg = 'Unable to get Detail table information', @rcode = 1
     	INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     	VALUES (@importid, @template, @firstform, @headrecseq, @errmsg)
     	GOTO bspexit
     END
     
     --Get the identifier for the company.  This should be the first identifier.
     SELECT @coident = min(Identifier)
     FROM IMWE with (nolock)
     WHERE ImportTemplate = @template and RecordType = @headrectype 
     and ImportId = @importid	
     --new company stuff
     
     --call bspIMBatchAssign to spin through IMWE and assign the batches.
     EXEC @rc = bspIMBatchAssign @importid, @template, @headrectype, @headform, @coident, @batchassign_errmsg output
     IF @rc <> 0
     BEGIN
     	SELECT @errmsg = 'Unable to assign batch.  ' + @batchassign_errmsg
     	SELECT @rcode = 1
     	goto bspexit
     END
     
     --Get the key column identifier
   	SELECT @headerkeyident = a.Identifier
   	FROM dbo.IMTD a with (nolock) 
	JOIN dbo.DDUD b with (nolock) on a.Identifier = b.Identifier
   	WHERE a.ImportTemplate=@template AND b.ColumnName = 'RecKey'
   		and a.RecordType = @headrectype and b.Form = @headform
   
     DECLARE HeaderCursor CURSOR FOR
     SELECT DISTINCT IMWE.RecordSeq FROM 
     IMWE with (nolock) left outer join DDUD with (nolock) on 
     	IMWE.Form = DDUD.Form and 
     	DDUD.TableName = @headtable and 
     	DDUD.Identifier = IMWE.Identifier 
     INNER JOIN IMTD with (nolock) on 
     	IMWE.ImportTemplate = IMTD.ImportTemplate and 
     	IMWE.Identifier = IMTD.Identifier and 
     	IMWE.RecordType = IMTD.RecordType 
     WHERE IMWE.ImportId = @importid and 
     	IMWE.ImportTemplate = @template and 
     	IMWE.RecordType = @headrectype 
     order by IMWE.RecordSeq
     
     OPEN HeaderCursor
     SELECT @HeaderCursorOpen = 1
     FETCH NEXT FROM HeaderCursor INTO @headrecseq
     SELECT @hcstatus = @@FETCH_STATUS
     
     	WHILE @hcstatus = 0
     	BEGIN  --outer while
     		SELECT @headerr = 0, @detailerr = 0
     		SELECT @IMWMinsert = null
     		--Develop header record
     		--Get the key value
     		SELECT @headerkeycol = UploadVal 
			FROM dbo.IMWE with (nolock) 
			WHERE ImportTemplate = @template and RecordType = @headrectype
     			and	Identifier = @headerkeyident and RecordSeq = @headrecseq and ImportId = @importid

			--Validate the CMRef 
			--get identifiers 
			SET @HeaderCMCoID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMCo', @headrectype, 'Y')
			SET @HeaderCMAcctID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMAcct', @headrectype, 'Y')
			SET @HeaderCMRefID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMRef', @headrectype, 'N')
			
			--CMCo
			SELECT @HeaderCMCo =  IMWE.UploadVal 
			FROM dbo.IMWE
			WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMCoID
			--CMAcct
			SELECT @HeaderCMAcct =  IMWE.UploadVal 
			FROM dbo.IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMAcctID
			--CMRef
			SELECT @HeaderCMRef =  IMWE.UploadVal FROM dbo.IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMRefID

			
			-- Payment Batch
		   IF exists(SELECT 1 FROM dbo.APPB with (nolock) WHERE PayMethod = 'C' and ChkType = 'I' and CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct
				and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
			BEGIN 
				SELECT @rcode = 1, @headerr = 1
				SELECT @errmsg = 'Entries in a Payment Batch have already been assigned Check#: ' +  isnull(@HeaderCMRef,'') + '!'
				INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				GOTO GetNextHeaderReqSeq
			END
			-- Payment History
		   IF EXISTS (SELECT 1 FROM dbo.APPH WHERE PayMethod='C' and ChkType = 'I' and CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct
			   and case isNumeric(CMRef) when 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
			BEGIN
			  SELECT @rcode = 1, @headerr = 1
				SELECT @errmsg = 'Entries in Payment History have already been assigned Check#: ' +  isnull(@HeaderCMRef,'') + '!'
				INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				GOTO GetNextHeaderReqSeq
			END
		   --  CM Detail  
		   IF EXISTS (SELECT 1 FROM dbo.CMDT with (nolock) WHERE CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct and CMTransType = 1	
					and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
    		BEGIN
				SELECT @rcode = 1, @headerr = 1
				SELECT @errmsg = 'Check #: ' + isnull(@HeaderCMRef,'') + ' already exists as CM Detail!'
				INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				GOTO GetNextHeaderReqSeq
    		END


     		--Get the first identifier for this RecordSequence
     		SELECT @ident = min(Identifier) 
			FROM dbo.IMWE with (nolock) 
			WHERE IMWE.ImportId = @importid and 
     			IMWE.ImportTemplate = @template and IMWE.RecordType = @headrectype and 
     			IMWE.RecordSeq = @headrecseq
     
     		WHILE @ident is not null
     		BEGIN  --inner header req while
     
     			SELECT @importcolumn = null, @importvalue = null
     			IF EXISTS(SELECT 1 
								FROM INFORMATION_SCHEMA.COLUMNS c
								JOIN DDUD d ON c.TABLE_NAME = d.TableName AND c.COLUMN_NAME = d.ColumnName
								WHERE (c.CHARACTER_MAXIMUM_LENGTH > 60 OR c.CHARACTER_MAXIMUM_LENGTH  = -1) 
							          AND d.Form = @headform AND d.Identifier = @ident AND d.TableName = @headtable)
				BEGIN
					SELECT @importvalue = (SELECT UploadVal FROM IMWENotes WITH (NOLOCK)
     										WHERE IMWENotes.ImportId = @importid AND 
     										IMWENotes.ImportTemplate = @template AND 
     										IMWENotes.RecordType = @headrectype AND 
		 									IMWENotes.Identifier = @ident AND 
	     									IMWENotes.RecordSeq = @headrecseq)
     
     				SELECT @importcolumn = (SELECT DDUD.ColumnName 
											FROM dbo.IMWENotes WITH (NOLOCK) 
     										LEFT OUTER JOIN dbo.DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
     										DDUD.TableName = @headtable AND 
     										DDUD.Identifier = IMWENotes.Identifier 
		 									WHERE IMWENotes.ImportId = @importid AND 
     										IMWENotes.ImportTemplate = @template AND 
     										IMWENotes.RecordType = @headrectype AND 
		 									IMWENotes.Identifier = @ident AND 
	     									IMWENotes.RecordSeq = @headrecseq)
				END
				ELSE
				  BEGIN
     				SELECT @importvalue = (SELECT IMWE.UploadVal FROM IMWE with (nolock)
     										WHERE IMWE.ImportId = @importid and 
     										IMWE.ImportTemplate = @template and 
     										IMWE.RecordType = @headrectype and 
		 									IMWE.Identifier = @ident and 
	     									IMWE.RecordSeq = @headrecseq)
     
     				SELECT @importcolumn = (SELECT DDUD.ColumnName FROM IMWE with (nolock) 
     										LEFT OUTER JOIN dbo.DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     										DDUD.TableName = @headtable and 
     										DDUD.Identifier = IMWE.Identifier 
     										WHERE IMWE.ImportId = @importid and 
     										IMWE.ImportTemplate = @template and 
     										IMWE.RecordType = @headrectype and 
		 									IMWE.Identifier = @ident and 
	     									IMWE.RecordSeq = @headrecseq)
				  END
     			--Get the destination Company
     			IF @ident = @coident SELECT @co = @importvalue
     
				IF ISNULL(@co,'') = ''
				BEGIN
					--Write back to IMWE
					update IMWE
					SET UploadVal = '*MISSING REQUIRED VALUE*'
					WHERE ImportId = @importid and ImportTemplate = @template and Identifier = @coident and RecordSeq = @headrecseq
    	
    				SELECT @errmsg = 'Batch Company is null'

					INSERT IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, Message)
    				VALUES (@importid, @template, @firstform, @headrecseq, @ident, @errcode, @errmsg)
				
    				--dump this record seq.  go onto next one	
					SELECT @rcode = 1, @headerr = 1
    				GOTO GetNextHeaderReqSeq
				END
     			--get the batch info stuff
     			IF @importcolumn = 'Mth'
     				SELECT @batchmth = @importvalue
     			IF @importcolumn = 'BatchId'
     				SELECT @batchid = @importvalue
				--new batch seq code
     			IF upper(@importcolumn) = 'BATCHSEQ'  
     			BEGIN
     				exec @rc = bspIMGetLastBatchSeq @co, @batchmth, @batchid, @headtable, @maxbatchid output, @errmsg output
     				IF @rc = 0
     				BEGIN
     					SELECT @importvalue = convert(varchar(100), @maxbatchid + 1)
     					SELECT @batchseq = @importvalue
     				END
     				ELSE
     				BEGIN
     					SELECT @rcode = 1, @headerr = 1
     					SELECT @errmsg = 'Unable get last Batch Seq.  ' + @errmsg
     					INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     					GOTO bspexit
     				END
     			END
     
     			--determine if column is required....
     			IF @importvalue = '' or @importvalue is null
     			BEGIN	
     				if (SELECT COLUMNPROPERTY( OBJECT_ID(@headrectype),@importcolumn,'AllowsNull')) = 0 
     				--update upload value...message that Table.Column cannot be null
     				--stop developing this record, go to next record sequence
     				--write message to IMWM
     				BEGIN 
     					SELECT @rcode = 1, @headerr = 1
       					SELECT @errmsg = 'Identifier ' + convert(varchar(10), @ident) + '.  Column : ' + @importcolumn + ' does not allow null values!' 
     					INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     
     					GOTO GetNextHeaderReqSeq
     				END
     			ELSE
     				--set and emtry string to null
     				SELECT @importvalue = null
     			END
     
     
     			IF @importcolumn is not null
     			BEGIN
     				SELECT @coltype = ColType 
     				FROM dbo.DDUD with (nolock) 
     				WHERE Form = @headform and Identifier = @ident
     
     				IF @importvalue IS NOT NULL
     				BEGIN
     					--Catch fields with embedded single quotes...
     					IF CHARINDEX(char(@quote),@importvalue) > 0
     					BEGIN
     						--replace single quotes with single back-quotes
     						SELECT @importvalue = REPLACE(@importvalue, char(@quote), '`')
     					END
     					
     					IF @coltype = 'varchar' or @coltype = 'text'
     					IF isnull(@importvalue,'') <> '' 
     					BEGIN
     						SELECT @importvalue = char(@quote) + @importvalue + char(@quote)
     					END
     					ELSE
     					BEGIN
     						SELECT @importvalue = 'char(null)'
     					END
     
     				IF @coltype = 'char' 
     				IF isnull(@importvalue,'') <> '' 
     				BEGIN
     					SELECT @importvalue = char(@quote) + @importvalue + char(@quote)
     				END
     				ELSE
     				BEGIN
     					SELECT @importvalue = 'char(null)'
     				END
     
     				IF @coltype = 'smalldatetime' 
     					IF isnull(@importvalue,'') <> '' 
     					BEGIN
     						SELECT @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     					END
     					ELSE
     					BEGIN
     						SELECT @importvalue = 'char(null)'
     					END
     
     				IF @coltype = 'tinyint' or @coltype = 'int' or @coltype = 'numeric' 
     				BEGIN
     					IF isnull(@importvalue,'') = '' SELECT @importvalue = 'char(null)'
     				END
     
     				IF @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
     				BEGIN
					  SET @importvalue = replace(@importvalue, ',', '') 
     				  IF isnumeric(@importvalue) <> 1 and @importvalue is not null and @importvalue <> 'char(null)'
     				  BEGIN
     					SELECT @rcode = 1, @headerr = 1
     					SELECT @errmsg = 'Identifier ' + convert(varchar(10), @ident) + '.  Column : ' + @importcolumn + ' does not allow non-numeric values!' 
     	
     			        UPDATE IMWE
     				  	SET UploadVal = '*VALUE NOT NUMERIC*'
     		          	WHERE ImportId = @importid and ImportTemplate = @template 
     						and Identifier = @ident and RecordSeq = @headrecseq and Form = @firstform
     	
     					INSERT IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					VALUES (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     				
     					GOTO GetNextHeaderReqSeq
     				  END
     				END
     
     				IF @valuelist is not null
     					SELECT @valuelist = @valuelist + ',' + @importvalue
     				ELSE
     					SELECT @valuelist = 'values (' + @importvalue
     	
     				IF @columnlist is null
     					SELECT @columnlist = 'Insert into ' + @headtable + ' (' + @importcolumn
     				ELSE
     					SELECT @columnlist = @columnlist + ',' + @importcolumn
     
     			  END
     			END	
     
     			--get the next identifier
				SELECT @ident = MIN(Identifier) 
								FROM (SELECT MIN(Identifier) AS Identifier 
										FROM IMWE WITH (NOLOCK) 
										WHERE IMWE.ImportId = @importid AND 
     									IMWE.ImportTemplate = @template AND IMWE.RecordType = @headrectype AND 
     									IMWE.RecordSeq = @headrecseq AND IMWE.Identifier > @ident
				UNION ALL
				SELECT MIN(Identifier) AS Identifier 
				FROM dbo.IMWENotes WITH (NOLOCK) 
				WHERE IMWENotes.ImportId = @importid AND 
     			IMWENotes.ImportTemplate = @template AND IMWENotes.RecordType = @headrectype AND 
     			IMWENotes.RecordSeq = @headrecseq AND IMWENotes.Identifier > @ident) AS IMWEUnion 
     		END
     
     
     		SELECT @headerinsert = @columnlist + ') ' + @valuelist + ')'
     
     		--lock the batch
     		SELECT @batchlock = 'update HQBC set InUseBy = ' + char(@quote) + SUSER_SNAME() + 
     			char(@quote) + ' where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + 
     			char(@quote) + convert(varchar(30), @batchmth) + char(@quote) + ' and BatchId = ' + 
     			CONVERT(varchar(6),@batchid) 
     
     		BEGIN TRANSACTION 
     		SELECT @intrans = 1
     
     		EXEC(@batchlock)
   
   			DELETE 
			FROM IMWM 
			WHERE ImportId = @importid and Error = 9999
   			INSERT into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, SQLStatement)
   			VALUES (@importid, @template, @headform, @headrecseq, 9999, '', @headerinsert)
     
			SELECT @errcode = 0
    
			BEGIN TRY
     		--execute the insert APPB statement
     		EXEC(@headerinsert)

			END TRY
     
		  BEGIN CATCH
			SELECT @errcode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE(), @rcode = 1
			-- Test whether the transaction is uncommittable.
			IF (XACT_STATE()) <> 0
				BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
				END

			UPDATE IMWM
			SET Error = @errcode, Message = @ErrorMessage
			WHERE ImportId = @importid and ImportTemplate = @template and Form = @headform and RecordSeq = @headrecseq
	    
			IF @@rowcount <> 1
			  BEGIN
			  INSERT IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
			  VALUES (@importid, @template, @headform, @headrecseq, @errcode, @ErrorMessage)
    		  END
		  END CATCH

     		IF @errcode = 0
     		BEGIN
     			--unlock the batch
     			SELECT @batchunlock = 'update HQBC set InUseBy = null where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + 
     			char(@quote) + convert(varchar(30), @batchmth) + char(@quote) + ' and BatchId = ' + 
     			convert(varchar(6),@batchid) 
     
     			EXEC(@batchunlock)
     
     			IF @@error <> 0
     			BEGIN
     				--insert was sucessful but could not unlock the batch, 
     				--abort the whole transaction. may want to consider bumping out
     				--of the whole procedure.
     				SELECT @headerr = 1
     				SELECT @errcode = @@error
     				GOTO GetNextHeaderReqSeq
     			END
     		END
     		ELSE
     		BEGIN
     			--insert failed, abort transaction
     			SELECT @headerr = 1
     			GOTO GetNextHeaderReqSeq
     		END
     
     		SELECT @headerinsert = null
     		
     
     		--Clear out the columnlist and valuelist
     		SELECT @columnlist = null, @valuelist = null, @coltype = null
     	
     
    --Now work on the line item detail records
    --Get the identifier for the key column
DetailInsert:
   		SELECT @detailkeyident = a.Identifier
   		FROM IMTD a jOIN DDUD b on a.Identifier = b.Identifier
   		WHERE a.ImportTemplate=@template AND b.ColumnName = 'RecKey'
   		and a.RecordType = @detailrectype and b.Form = @detailform

			-- get identifiers 
			SET @ExpMthID			= dbo.bfIMTemplateDefaults(@template, @detailform, 'ExpMth', @detailrectype, 'Y')
			IF @ExpMthID = 0 SET @ExpMthID = dbo.bfIMTemplateDefaults(@template, @detailform, 'ExpMth', @detailrectype, 'N')
			SET @APTransID			= dbo.bfIMTemplateDefaults(@template, @detailform, 'APTrans', @detailrectype, 'Y')
			IF @APTransID = 0 SET @APTransID = dbo.bfIMTemplateDefaults(@template, @detailform, 'APTrans', @detailrectype, 'N')
			SET @InvDateID			= dbo.bfIMTemplateDefaults(@template, @detailform, 'InvDate', @detailrectype, 'Y')
			IF  @InvDateID = 0 SET @InvDateID = dbo.bfIMTemplateDefaults(@template, @detailform, 'InvDate', @detailrectype, 'N')
			SET @RetainageFlagID	= dbo.bfIMTemplateDefaults(@template, @detailform, 'RetainageFlag', @detailrectype, 'Y')
			IF  @RetainageFlagID = 0 SET @RetainageFlagID = dbo.bfIMTemplateDefaults(@template, @detailform, 'RetainageFlag', @detailrectype, 'N')
			SET @APRefID			= dbo.bfIMTemplateDefaults(@template, @detailform, 'APRef', @detailrectype, 'N')
			IF  @APRefID = 0 SET @APRefID = dbo.bfIMTemplateDefaults(@template, @detailform, 'APRef', @detailrectype, 'Y')
			SET @AmtToPayID			= dbo.bfIMTemplateDefaults(@template, @detailform, 'AmountToPay', @detailrectype, 'N')
			IF  @AmtToPayID = 0 SET @AmtToPayID = dbo.bfIMTemplateDefaults(@template, @detailform, 'AmountToPay', @detailrectype, 'Y')
			SET @SLID				= dbo.bfIMTemplateDefaults(@template, @detailform, 'Subcontract', @detailrectype, 'N')
			IF  @SLID = 0 SET @SLID = dbo.bfIMTemplateDefaults(@template, @detailform, 'Subcontract', @detailrectype, 'Y')
		

     		--Get Set of detail records associated with the header record's key value
     		DECLARE DetailCursor CURSOR FOR
     		SELECT distinct IMWE.RecordSeq 
     		FROM IMWE with (nolock) left outer join DDUD with (nolock) on 	
     			IMWE.Form = DDUD.Form and 
     			DDUD.TableName = @detailtable and 
     			DDUD.Identifier = IMWE.Identifier 
     		iNNER JOIN IMTD with (nolock) on 
     			IMWE.ImportTemplate = IMTD.ImportTemplate and 
     			IMWE.Identifier = IMTD.Identifier and 
     			IMWE.RecordType = IMTD.RecordType  
     		WHERE IMWE.ImportId = @importid and 
     		IMWE.ImportTemplate = @template and 
     		IMWE.RecordType = @detailrectype and 
     		IMWE.Identifier = @detailkeyident and
     		IMWE.UploadVal = @headerkeycol
     		ORDER BY IMWE.RecordSeq
     
     
     		OPEN DetailCursor
    		SELECT @DetailCursorOpen = 1
     		FETCH NEXT FROM DetailCursor INTO @detailrecseq
     		SELECT @dcstatus = @@FETCH_STATUS
     
     		WHILE @dcstatus = 0
     		BEGIN
     			SELECT @detailkeycol = UploadVal 
     			FROM IMWE with (nolock) 
     			WHERE ImportTemplate = @template and 
     			RecordType = @detailrectype and 
     			RecordSeq = @detailrecseq and 
     			Identifier = @detailkeyident and 
     			ImportId = @importid


--				Get rest of key values 
				-- ExpMth
				SELECT @ExpMth =  IMWE.UploadVal 
				FROM dbo.IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @ExpMthID
				-- APTrans
				SELECT @APTrans =  IMWE.UploadVal 
				FROM dbo.IMWE 
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @APTransID
				--APRef
				SELECT @APRef =  IMWE.UploadVal 
				FROM dbo.IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @APRefID

				-- if this is a Textura import get retainage flag
				IF @TexturaYN = 'Y'
				BEGIN
				-- RetainageFlag
				SELECT @RetainageFlag =  IMWE.UploadVal 
				FROM dbo.IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @RetainageFlagID
				END

				-- if bAPTB already exists go to APDB insert
				IF EXISTS
						(
							SELECT * 
							FROM dbo.APTB (nolock) 
							WHERE Co=@co and Mth=@batchmth and BatchId=@batchid and
								BatchSeq=@batchseq and ExpMth=@ExpMth and APTrans=@APTrans and APRef=@APRef
						) 
				GOTO APDBInsert

				-- If this is a Textura Retainage only payment go directly to APDB insert.  APDB Insert process will
				-- create both the bAPTB and bAPDB for Textura retainage only payments.
				IF @TexturaYN = 'Y' AND ISNULL(@RetainageFlag,'N') = 'R' GOTO APDBInsert
	
				-- If payment is not a Textura retainage payment, handle as normal invoice payment
     			--Get the first identifier for this RecordSequence
     			SELECT @detailident = MIN(Identifier) 
     			FROM dbo.IMWE with (nolock) 
     			WHERE IMWE.ImportId = @importid and 
     			IMWE.ImportTemplate = @template and 
     			IMWE.RecordType = @detailrectype and 
     			IMWE.RecordSeq = @detailrecseq 
     
     			IF @detailkeycol = @headerkeycol
     			BEGIN
     			WHILE @detailident is not null
     			BEGIN
     				SELECT @importcolumn = null, @importvalue = null, @coltype = null
					IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
							   JOIN DDUD d ON c.TABLE_NAME = d.TableName AND c.COLUMN_NAME = d.ColumnName
							   WHERE (c.CHARACTER_MAXIMUM_LENGTH > 60 OR c.CHARACTER_MAXIMUM_LENGTH  = -1) 
							          AND d.Form = @detailform AND d.Identifier = @detailident AND d.TableName = @detailtable)
					BEGIN
	     				SELECT @importcolumn = (SELECT dbo.DDUD.ColumnName FROM IMWENotes WITH (NOLOCK) 
		 										LEFT OUTER JOIN dbo.DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
     												DDUD.TableName = @detailtable AND 
     												DDUD.Identifier = IMWENotes.Identifier 
		 										WHERE IMWENotes.ImportId = @importid AND 
     												IMWENotes.ImportTemplate = @template AND 
     												IMWENotes.RecordType = @detailrectype AND 
     												IMWENotes.Identifier = @detailident AND 
     												IMWENotes.RecordSeq = @detailrecseq)
     
	     				SELECT @importvalue = (SELECT IMWENotes.UploadVal 
												FROM dbo.IMWENotes WITH (NOLOCK)   
		 										LEFT OUTER JOIN dbo.DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
     												DDUD.TableName = @detailtable AND 
     												DDUD.Identifier = IMWENotes.Identifier 
		 										WHERE IMWENotes.ImportId = @importid AND 
     												IMWENotes.ImportTemplate = @template AND 
     												IMWENotes.RecordType = @detailrectype AND 
     												IMWENotes.Identifier = @detailident AND 
     												IMWENotes.RecordSeq = @detailrecseq)
					END
					ELSE
					  BEGIN
	     				SELECT @importcolumn = (SELECT DDUD.ColumnName 
												FROM dbo.IMWE with (nolock) 
		 										LEFT OUTER JOIN dbo.DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     												DDUD.TableName = @detailtable and 
     												DDUD.Identifier = IMWE.Identifier 
		 										WHERE IMWE.ImportId = @importid and 
     												IMWE.ImportTemplate = @template and 
     												IMWE.RecordType = @detailrectype and 
     												IMWE.Identifier = @detailident and 
     												IMWE.RecordSeq = @detailrecseq)
     
	     				SELECT @importvalue = (SELECT IMWE.UploadVal FROM IMWE with (nolock)  
		 										LEFT OUTER JOIN dbo.DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     												DDUD.TableName = @detailtable and 
     												DDUD.Identifier = IMWE.Identifier 
		 										WHERE IMWE.ImportId = @importid and 
     												IMWE.ImportTemplate = @template and 
     												IMWE.RecordType = @detailrectype and 
     												IMWE.Identifier = @detailident and 
     												IMWE.RecordSeq = @detailrecseq)
					  END
     				IF @importcolumn is not null
     				BEGIN
     					IF @importcolumn = 'BatchId'
     						SELECT @importvalue = @batchid
     
     					IF @importcolumn = 'Mth'
     						SELECT @importvalue = @batchmth
     
     					IF @importcolumn = 'BatchSeq'
     						SELECT @importvalue = @batchseq
     
     					IF @importvalue = '' or @importvalue is null
     					BEGIN	
     						IF (SELECT COLUMNPROPERTY( OBJECT_ID(@detailrectype),@importcolumn,'AllowsNull')) = 0 
     						--update upload value...message that Table.Column cannot be null
     						--stop developing this record, go to next record sequence
     						BEGIN 
     							SELECT @rcode = 1, @detailerr = 1
     							SELECT @errmsg =  'Column : ' + @importcolumn + ' does not allow null values! See Identifier ' 
     												+ convert(varchar(10), @detailident)
     
     							--Build error message to input after transaction rollback, otherwise gets rolled back!
     							SELECT @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) ' +
     								'values (' + char(@quote) + @importid + char(@quote) + ',' + char(@quote) + @template + char(@quote) + ',' + 
     								char(@quote) + @secondform + char(@quote) + ',' + convert(varchar(10),@detailrecseq) + ',' + 
     								convert(varchar(10),@detailerr) + ',' + char(@quote) + @errmsg + char(@quote) + ',' + convert(varchar(10), @detailident) + ')'
								
     							GOTO GetNextHeaderReqSeq	--Exit on first detail error, because we can't store more than one insert statement for IMWM.
     						END
     						ELSE
     							SELECT @importvalue = null
     					END
     					--Catch fields with embedded single quotes...
     					IF CHARINDEX(char(@quote),@importvalue) > 0
     					BEGIN
     						--replace single quotes with single back-quotes
     						SELECT @importvalue = REPLACE(@importvalue, char(@quote), '`')
     					END
     
     					--Varchar, Char, and Smalldatetime data types need to be encapsulated in '''
     					SELECT @coltype = ColType 
     					FROM dbo.DDUD 
						WHERE Form = @detailform and Identifier = @detailident
     
     					IF @coltype = 'varchar' OR @coltype = 'text'
     					BEGIN
     						IF isnull(@importvalue,'') <> '' 
     						BEGIN
     							SELECT @importvalue = char(@quote) + @importvalue + char(@quote)
     						END
     						ELSE
     					BEGIN
     							SELECT @importvalue = 'char(null)'
     						END
     					END
     
     					--if @coltype = 'char' SELECT @importvalue = char(@quote) + @importvalue + char(@quote)
     					IF @coltype = 'char' 
     					BEGIN
     						IF isnull(@importvalue,'') <> '' 
     						BEGIN
     							SELECT @importvalue = char(@quote) + @importvalue + char(@quote)
     						END
     					ELSE
     					BEGIN
     						SELECT @importvalue = 'char(null)'
     					END
     				END
     
     				--if @coltype = 'smalldatetime' SELECT @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     				IF @coltype = 'smalldatetime' 
     				BEGIN
     					IF isnull(@importvalue,'') <> '' 
     					BEGIN
							SELECT @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     					END
     					ELSE
     					BEGIN
     						SELECT @importvalue = 'char(null)'
     					END
     				END
     
     				IF @coltype = 'tinyint' or @coltype = 'int' or @coltype = 'numeric' 
     				BEGIN
     					IF isnull(@importvalue,'') = '' SELECT @importvalue = 'char(null)'
     				END
     
     				IF @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
     				BEGIN
					  SET @importvalue = replace(@importvalue, ',', '') --CC issue #127127
     				  IF isnumeric(@importvalue) <> 1 and @importvalue IS NOT NULL AND @importvalue <> 'char(null)'
     				  BEGIN
     					SELECT @rcode = 1, @detailerr = 1
     					SELECT @errmsg =  'Column : ' + @importcolumn + ' does not allow non-numeric values! See Identifier ' 
     										+ convert(varchar(10), @detailident)
     					
     					--Build error message to input after transaction rollback, otherwise gets rolled back!
     					SELECT @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) ' +
     						'values (' + char(@quote) + @importid + char(@quote) + ',' + char(@quote) + @template + char(@quote) + ',' + 
     						char(@quote) + @secondform + char(@quote) + ',' + convert(varchar(10),@detailrecseq) + ',' + 
     						convert(varchar(10),@detailerr) + ',' + char(@quote) + @errmsg + char(@quote) + ',' + convert(varchar(10), @detailident) + ')'
				
     					GOTO GetNextHeaderReqSeq	--Save time by exiting now, but remaining details may have errors.
     
     				  END
     				END
     
     				IF @importvalue IS NOT NULL
     				BEGIN
     					IF @detailvallist IS NOT NULL
     						SELECT @detailvallist = @detailvallist + ',' + @importvalue
     					ELSE
     						SELECT @detailvallist = 'values (' + @importvalue 
     
     					IF @detailcollist is not null
     						SELECT @detailcollist = @detailcollist + ',' + @importcolumn
     					ELSE
     						SELECT @detailcollist = 'insert into ' + @detailtable + ' (' + @importcolumn 
     			  	END
     			END
     
     			--Get the next identifier for this RecordSequence
				SELECT @detailident = MIN(Identifier) 
				FROM (SELECT MIN(Identifier) AS Identifier 
						FROM dbo.IMWE WITH (NOLOCK) 
						WHERE IMWE.ImportId = @importid AND 
     					IMWE.ImportTemplate = @template AND IMWE.RecordType = @detailrectype AND 
     					IMWE.RecordSeq = @detailrecseq AND IMWE.Identifier > @detailident
							UNION ALL
						SELECT MIN(Identifier) AS Identifier 
						FROM dbo.IMWENotes WITH (NOLOCK) 
						WHERE IMWENotes.ImportId = @importid AND 
     						IMWENotes.ImportTemplate = @template AND IMWENotes.RecordType = @detailrectype AND 
     						IMWENotes.RecordSeq = @detailrecseq AND IMWENotes.Identifier > @detailident) AS IMWEUnion 
     		END	--develop detail 
     
     		SELECT @detailinsert = @detailcollist + ') ' + @detailvallist + ')'
     
   			DELETE FROM IMWM WHERE ImportId = @importid and Error = 9999
   			INSERT into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, SQLStatement)
   			VALUES (@importid, @template, @headform, @detailrecseq, 9999, '', @detailinsert)
   
			SELECT @errcode = 0

			BEGIN TRY
     		EXEC(@detailinsert)

			END TRY 
		   
			BEGIN CATCH
			SELECT @errcode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE(), @rcode = 1

			-- Test whether the transaction is uncommittable.
			IF XACT_STATE() <>0
				BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
				END

				Update IMWM
				SET Error = @errcode, Message = @ErrorMessage
				WHERE ImportId = @importid and ImportTemplate = @template and Form = @detailform and RecordSeq = @detailrecseq
		    
				IF @@rowcount <> 1
				  BEGIN
				  INSERT IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
				  VALUES (@importid, @template, @detailform, @detailrecseq, @errcode, @ErrorMessage)
				  END
			END CATCH
     
     		IF @errcode <> 0
     		BEGIN
     			SELECT @detailerr = 1
     			GOTO GetNextHeaderReqSeq
     		END
     
     		SELECT @detailcollist = null
     		SELECT @detailvallist = null
     		SELECT @detailinsert = null
     
     	END
	
	APDBInsert:
		-- prepare to insert bAPDB records 
		-- get rest of IMWE values to pass

		-- InvDate
		SELECT @InvDate =  IMWE.UploadVal 
		FROM dbo.IMWE 
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @InvDateID

		-- AmtToPay
		SELECT @AmtToPay =  IMWE.UploadVal  
		FROM dbo.IMWE
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @AmtToPayID

		-- if this is a Textura import get SL
		IF @TexturaYN = 'Y'
		BEGIN
			SELECT @SL =  IMWE.UploadVal 
			FROM dbo.IMWE
			WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
				AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
				AND IMWE.Identifier = @SLID
		END
  
		SELECT @errcode = 0

		-- execute sp to insert APDB records for invoices or create APTB/APDB for released retainage
		BEGIN TRY
     		EXEC @apdbrcode = vspIMUploadAPDB @co, @batchmth, @batchid,@batchseq,
			@ExpMth,@APTrans,@APRef,@InvDate, @RetainageFlag,@AmtToPay,@SL,@TexturaYN, @errmsg output
			IF @apdbrcode=1
			BEGIN
			-- RAISERROR with severity 11-19 will cause execution to jump to the CATCH block
			RAISERROR (@errmsg, -- Message text.
			   16, -- Severity.
			   1 -- State.
			   );
			END
			
		END TRY 
		   
		BEGIN CATCH
			SELECT @errcode = ERROR_NUMBER(), @rcode = 1
			-- Test whether the transaction is uncommittable.
			IF XACT_STATE() <>0 
			BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
			END
			-- write to error log
			SELECT @ErrorMessage = ERROR_MESSAGE()
			INSERT dbo.IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
			VALUES (@importid, @template, @detailform, @detailrecseq, 0, @ErrorMessage)

			IF @errcode <> 0
     		BEGIN
     			SELECT @detailerr = 1, @apdbrcode = 0
     			GOTO GetNextHeaderReqSeq
     		END

		END CATCH
     
     GetNextDetailReqSeq:
     
     	IF @detailerr = 0
     	BEGIN 
     		--only delete if detailkey and headerkey match
     		IF @detailkeycol = @headerkeycol
     		BEGIN
     			SELECT @deletestmt = 'Delete IMWE where ImportId = ' + char(@quote) + @importid + char(@quote) + 
     			' and RecordSeq = ' + convert(varchar(5),@detailrecseq) + ' and RecordType = ' + char(@quote) + 
     			@detailrectype + char(@quote)  
     
     			EXEC(@deletestmt)
     			SELECT @deletestmt = null
				
				SELECT @deletestmt = 'DELETE IMWENotes WHERE ImportId = ' + CHAR(@quote) + @importid + CHAR(@quote) + 
     			' AND RecordSeq = ' + CONVERT(VARCHAR(5),@detailrecseq) + ' AND RecordType = ' + CHAR(@quote) + 
     			@detailrectype + CHAR(@quote)  
     
     			EXEC(@deletestmt)
     			SELECT @deletestmt = NULL	
     		END
     	END
     	ELSE
     	BEGIN
     		SELECT @errdesc = description FROM master.dbo.sysmessages WHERE error = @errcode
     	END
     
     	SELECT @detailcollist = null, @detailvallist = null
     
     	FETCH NEXT FROM DetailCursor INTO @detailrecseq
     	SELECT @dcstatus = @@FETCH_STATUS
     
     END
     
     --get next header record
     GetNextHeaderReqSeq:
    	IF @DetailCursorOpen = 1
    	BEGIN
    	 	CLOSE DetailCursor
    		SELECT @DetailCursorOpen = 0
     		DEALLOCATE DetailCursor
     	END
    
     	SELECT @detailcollist = null
     	SELECT @detailvallist = null
     	SELECT @detailinsert = null
     	
     	IF @headerr = 0 and @detailerr = 0
     	BEGIN 
     
     		IF @intrans = 1
     		BEGIN
     			COMMIT TRANSACTION
     			SELECT @intrans = 0	
     		END
     		--Delete Record FROM IMWE
     		SELECT @deletestmt = 'Delete IMWE where ImportId = ' + char(@quote) + @importid + char(@quote) + 
     		' and RecordSeq = ' + convert(varchar(5),@headrecseq) + ' and RecordType = ' + char(@quote) +
     		@headrectype + char(@quote)
     
     		EXEC(@deletestmt)
     		SELECT @deletestmt = null
     
     		SELECT @deletestmt = 'DELETE IMWENotes WHERE ImportId = ' + CHAR(@quote) + @importid + CHAR(@quote) + 
     		' AND RecordSeq = ' + CONVERT(VARCHAR(5),@detailrecseq) + ' AND RecordType = ' + CHAR(@quote) + 
     		@detailrectype + CHAR(@quote)  
     
     		EXEC(@deletestmt)
     		SELECT @deletestmt = NULL	
     		--Update IMBC 
     		IF @batchid is not null
     		BEGIN
     			SELECT @imbccount = (SELECT count(ImportId) FROM IMBC WHERE ImportId = @importid and Co = @co and Mth = @batchmth and BatchId = @batchid)
     
     			IF @imbccount = 0
     			BEGIN
     				INSERT IMBC (ImportId, Co, Mth, BatchId, RecordCount) 
					VALUES (@importid, @co, @batchmth, @batchid, 1)
     			END
     
     			IF @imbccount = 1
     			BEGIN
     				UPDATE IMBC set RecordCount = RecordCount + 1 WHERE ImportId = @importid and Co = @co and Mth = @batchmth and BatchId = @batchid
     			END
     
     			SELECT @imbccount = null
     
     		END
     	END
     	ELSE
     	BEGIN
     		IF @intrans = 1
     		BEGIN
     			ROLLBACK TRANSACTION
     			SELECT @intrans = 0
     		END
    
			IF @IMWMinsert IS NOT NULL
			EXEC(@IMWMinsert)
			
     		SELECT @rcode = 1
     		SELECT @errmsg = 'Data errors.  Check IM Work Edit and IMWM.'
     
     	END
     
     	SELECT @columnlist = null, @valuelist = null, @headerr = 0
     
     	SELECT @IMWMinsert = null
     
     	FETCH NEXT FROM HeaderCursor INTO @headrecseq
     	SELECT @hcstatus = @@FETCH_STATUS
     
     END --END outer while
     
     
     bspexit:
     
     IF @HeaderCursorOpen = 1 
     BEGIN
    	 CLOSE HeaderCursor
    	 SELECT @HeaderCursorOpen = 0
    	 deallocate HeaderCursor
     END
     
     IF @ANSIWARN = 1
     SET ANSI_WARNINGS ON
     
     
     RETURN @rcode




GO

GRANT EXECUTE ON  [dbo].[vspIMUploadHeaderDetailPay] TO [public]
GO
