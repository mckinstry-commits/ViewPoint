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
     
     
       (@importid varchar(20) = null, @template varchar(30) = null, 
           @errmsg varchar(500) = null output)
     
     as
     set nocount on
     
     /* Store current state for ANSI_WARNINGS to restore at end. */
     declare @ANSIWARN int
     SELECT @ANSIWARN = 0
     IF @@OPTIONS & 8 > 0
     	SELECT @ANSIWARN = 1
     SET ANSI_WARNINGS OFF
     
     
     --Locals
     declare @ident int, @detailident int, @headrecseq int, @detailrecseq int, 
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
     

     declare @coident int, @co bCompany, @form varchar(30), @batchassign_errmsg varchar(8000)
     
     --the ascii code for a single quote
     select @quote = 39
     
     --initialize the error code
     select @rcode = 0, @ident = -1, @headrecseq = -1, @headerr = 0, @DetailCursorOpen = 0, @HeaderCursorOpen = 0, @apdbrcode = 0
     
     select @rectypecount = count(ImportTemplate) from IMTR with (nolock) where ImportTemplate = @template
     
     --we should only have 2 record types but we don't know which one is header or which one is detail
     if @rectypecount = 2
     begin
     	select @headrectype = min(RecordType) from IMTR with (nolock) where ImportTemplate = @template
     	select @firstform = Form from IMTR with (nolock) where ImportTemplate = @template and RecordType = @headrectype 
     	select @detailrectype = RecordType from IMTR with (nolock) where ImportTemplate = @template and RecordType > @headrectype
     	select @secondform = Form from IMTR with (nolock) where ImportTemplate = @template and RecordType = @detailrectype
     end
    -- set Textura flag 
	if @template = 'AP Pay Txt'
		begin
		select @TexturaYN = 'Y'
		end
	else
		begin
		select @TexturaYN = 'N'
		end

     select @headform = Form, @batchyn = BatchYN from DDUF with (nolock) where Form = @firstform 
     if @batchyn = 'N'
     begin
     	select @headform = Form, @batchyn = BatchYN from DDUF with (nolock) where Form = @secondform 
   		select @headrectype = RecordType from IMTR with (nolock) where ImportTemplate = @template and Form = @headform
   
     	if @batchyn = 'N'
     	--we got an error here.  Bump out of procedure.
     	begin
     		select @errmsg = 'Unable to get upload form information', @rcode = 1
     		insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     		values (@importid, @template, @firstform, @headrecseq, @errmsg)
     		goto bspexit
     	end
     	else
		begin
     		select @detailform = Form from DDUF where Form = @firstform 
   		-- correct the record types.
   			select @detailrectype = RecordType from IMTR with (nolock) where ImportTemplate = @template and Form = @detailform
   		end
		end
     else
     	select @detailform = Form from DDUF with (nolock) where Form = @secondform 
     
		select @headtable = ViewName from dbo.vDDFH with (nolock) where Form = @headform
     
     if @headtable = ''
     begin
     	select @errmsg = 'Unable to get Header table information', @rcode = 1
     	insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     	values (@importid, @template, @firstform, @headrecseq, @errmsg)
     	goto bspexit
     end
     
     select @detailtable = ViewName from dbo.vDDFH where Form = @detailform
     
     if @detailtable = ''
     begin
     	select @errmsg = 'Unable to get Detail table information', @rcode = 1
     	insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message)
     	values (@importid, @template, @firstform, @headrecseq, @errmsg)
     	goto bspexit
     end
     
     --new company stuff
     --Get the identifier for the company.  This should be the first identifier.
     select @coident = min(Identifier)
     from IMWE with (nolock)
     where ImportTemplate = @template and RecordType = @headrectype 
     and ImportId = @importid	
     --new company stuff
     
     --call bspIMBatchAssign to spin through IMWE and assign the batches.
     exec @rc = bspIMBatchAssign @importid, @template, @headrectype, @headform, @coident, @batchassign_errmsg output
     if @rc <> 0
     begin
     	select @errmsg = 'Unable to assign batch.  ' + @batchassign_errmsg
     	select @rcode = 1
     	goto bspexit
     end
     
     --Get the key column identifier
   	select @headerkeyident = a.Identifier
   	From IMTD a with (nolock) join DDUD b with (nolock) on a.Identifier = b.Identifier
   	Where a.ImportTemplate=@template AND b.ColumnName = 'RecKey'
   	and a.RecordType = @headrectype and b.Form = @headform
   
     DECLARE HeaderCursor CURSOR FOR
     SELECT DISTINCT IMWE.RecordSeq FROM 
     IMWE with (nolock) left outer join DDUD with (nolock) on 
     	IMWE.Form = DDUD.Form and 
     	DDUD.TableName = @headtable and 
     	DDUD.Identifier = IMWE.Identifier 
     inner join IMTD with (nolock) on 
     	IMWE.ImportTemplate = IMTD.ImportTemplate and 
     	IMWE.Identifier = IMTD.Identifier and 
     	IMWE.RecordType = IMTD.RecordType 
     where IMWE.ImportId = @importid and 
     	IMWE.ImportTemplate = @template and 
     	IMWE.RecordType = @headrectype 
     order by IMWE.RecordSeq
     
     OPEN HeaderCursor
     SELECT @HeaderCursorOpen = 1
     FETCH NEXT FROM HeaderCursor INTO @headrecseq
     SELECT @hcstatus = @@FETCH_STATUS
     
     	while @hcstatus = 0
     	begin  --outer while
     		select @headerr = 0, @detailerr = 0
     		select @IMWMinsert = null
     		--Develop header record
     		--Get the key value
     		select @headerkeycol = UploadVal from IMWE with (nolock) where ImportTemplate = @template and RecordType = @headrectype
     			and	Identifier = @headerkeyident and RecordSeq = @headrecseq and ImportId = @importid

			--Validate the CMRef 
			--get identifiers 
			SET @HeaderCMCoID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMCo', @headrectype, 'Y')
			SET @HeaderCMAcctID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMAcct', @headrectype, 'Y')
			SET @HeaderCMRefID = dbo.bfIMTemplateDefaults(@template, @headform, 'CMRef', @headrectype, 'N')
			
			--CMCo
			SELECT @HeaderCMCo =  IMWE.UploadVal FROM IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMCoID
			--CMAcct
			SELECT @HeaderCMAcct =  IMWE.UploadVal FROM IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMAcctID
			--CMRef
			SELECT @HeaderCMRef =  IMWE.UploadVal FROM IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @headrectype AND IMWE.RecordSeq = @headrecseq
					AND IMWE.Identifier = @HeaderCMRefID

			
			-- Payment Batch
		   if exists(select 1 from dbo.APPB with (nolock) where PayMethod = 'C' and ChkType = 'I' and CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct
				and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
			begin 
				select @rcode = 1, @headerr = 1
				select @errmsg = 'Entries in a Payment Batch have already been assigned Check#: ' +  isnull(@HeaderCMRef,'') + '!'
				insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				goto GetNextHeaderReqSeq
			end
			-- Payment History
		   if exists(select 1 from dbo.APPH where PayMethod='C' and ChkType = 'I' and CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct
			   and case isNumeric(CMRef) when 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
			begin
			  select @rcode = 1, @headerr = 1
				select @errmsg = 'Entries in Payment History have already been assigned Check#: ' +  isnull(@HeaderCMRef,'') + '!'
				insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				goto GetNextHeaderReqSeq
			end
		   --  CM Detail  
		   if exists(select 1 from dbo.CMDT with (nolock) where CMCo = @HeaderCMCo and CMAcct = @HeaderCMAcct and CMTransType = 1	
					and case isNumeric(CMRef) WHEN 1 THEN convert(float,CMRef) ELSE 0 END = @HeaderCMRef)
    		begin
				select @rcode = 1, @headerr = 1
				select @errmsg = 'Check #: ' + isnull(@HeaderCMRef,'') + ' already exists as CM Detail!'
				insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
				values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
				goto GetNextHeaderReqSeq
    		end


     		--Get the first identifier for this RecordSequence
     		select @ident = min(Identifier) from IMWE with (nolock) where IMWE.ImportId = @importid and 
     			IMWE.ImportTemplate = @template and IMWE.RecordType = @headrectype and 
     			IMWE.RecordSeq = @headrecseq
     
     		while @ident is not null
     		begin  --inner header req while
     
     			select @importcolumn = null, @importvalue = null
     			IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
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
     
     				SELECT @importcolumn = (SELECT DDUD.ColumnName FROM IMWENotes WITH (NOLOCK) 
     				LEFT OUTER JOIN DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
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
     				select @importvalue = (select IMWE.UploadVal from IMWE with (nolock)
     				where IMWE.ImportId = @importid and 
     				IMWE.ImportTemplate = @template and 
     				IMWE.RecordType = @headrectype and 
		 			IMWE.Identifier = @ident and 
	     			IMWE.RecordSeq = @headrecseq)
     
     				select @importcolumn = (select DDUD.ColumnName from IMWE with (nolock) 
     				left outer join DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     				DDUD.TableName = @headtable and 
     				DDUD.Identifier = IMWE.Identifier 
     				where IMWE.ImportId = @importid and 
     				IMWE.ImportTemplate = @template and 
     				IMWE.RecordType = @headrectype and 
		 			IMWE.Identifier = @ident and 
	     			IMWE.RecordSeq = @headrecseq)
				  END
     			--Get the destination Company
     			if @ident = @coident select @co = @importvalue
     
				IF ISNULL(@co,'') = ''
					BEGIN
						--Write back to IMWE
						update IMWE
						set UploadVal = '*MISSING REQUIRED VALUE*'
						where ImportId = @importid and ImportTemplate = @template and Identifier = @coident and RecordSeq = @headrecseq
    	
    					SELECT @errmsg = 'Batch Company is null'

						Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, Message)
    					values (@importid, @template, @firstform, @headrecseq, @ident, @errcode, @errmsg)
				
    					--dump this record seq.  go onto next one	
						select @rcode = 1, @headerr = 1
    				    goto GetNextHeaderReqSeq
					END
     			--get the batch info stuff
     			if @importcolumn = 'Mth'
     				select @batchmth = @importvalue
     			if @importcolumn = 'BatchId'
     				select @batchid = @importvalue
				--new batch seq code
     			if upper(@importcolumn) = 'BATCHSEQ'  
     			begin
     				exec @rc = bspIMGetLastBatchSeq @co, @batchmth, @batchid, @headtable, @maxbatchid output, @errmsg output
     				if @rc = 0
     				begin
     					select @importvalue = convert(varchar(100), @maxbatchid + 1)
     					select @batchseq = @importvalue
     				end
     				else
     				begin
     					select @rcode = 1, @headerr = 1
     					select @errmsg = 'Unable get last Batch Seq.  ' + @errmsg
     					insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     					goto bspexit
     				end
     			end
     
     			--determine if column is required....
     			if @importvalue = '' or @importvalue is null
     			begin	
     				if (select COLUMNPROPERTY( OBJECT_ID(@headrectype),@importcolumn,'AllowsNull')) = 0 
     				--update upload value...message that Table.Column cannot be null
     				--stop developing this record, go to next record sequence
     				--write message to IMWM
     				begin 
     					select @rcode = 1, @headerr = 1
       					select @errmsg = 'Identifier ' + convert(varchar(10), @ident) + '.  Column : ' + @importcolumn + ' does not allow null values!' 
     					insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     
     					goto GetNextHeaderReqSeq
     				end
     			else
     				--set and emtry string to null
     					select @importvalue = null
     			end
     
     
     			if @importcolumn is not null
     			begin
     				select @coltype = ColType 
     				from DDUD with (nolock) 
     				where Form = @headform and 
     				Identifier = @ident
     
     				if @importvalue is not null
     				begin
     					--Catch fields with embedded single quotes...
     					if CHARINDEX(char(@quote),@importvalue) > 0
     					begin
     						--replace single quotes with single back-quotes
     						SELECT @importvalue = REPLACE(@importvalue, char(@quote), '`')
     					end
     					
     					if @coltype = 'varchar' or @coltype = 'text'
     					if isnull(@importvalue,'') <> '' 
     					begin
     						select @importvalue = char(@quote) + @importvalue + char(@quote)
     					end
     					else
     					begin
     						select @importvalue = 'char(null)'
     					end
     
     				if @coltype = 'char' 
     				if isnull(@importvalue,'') <> '' 
     				begin
     					select @importvalue = char(@quote) + @importvalue + char(@quote)
     				end
     				else
     				begin
     					select @importvalue = 'char(null)'
     				end
     
     				if @coltype = 'smalldatetime' 
     					if isnull(@importvalue,'') <> '' 
     					begin
     						select @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     					end
     					else
     					begin
     						select @importvalue = 'char(null)'
     					end
     
     				if @coltype = 'tinyint' or @coltype = 'int' or @coltype = 'numeric' 
     				begin
     					if isnull(@importvalue,'') = '' select @importvalue = 'char(null)'
     				end
     
     				if @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
     				begin
					  set @importvalue = replace(@importvalue, ',', '') 
     				  if isnumeric(@importvalue) <> 1 and @importvalue is not null and @importvalue <> 'char(null)'
     				  begin
     					select @rcode = 1, @headerr = 1
     					select @errmsg = 'Identifier ' + convert(varchar(10), @ident) + '.  Column : ' + @importcolumn + ' does not allow non-numeric values!' 
     	
     			        update IMWE
     				  	set UploadVal = '*VALUE NOT NUMERIC*'
     		          	where ImportId = @importid and ImportTemplate = @template 
     						and Identifier = @ident and RecordSeq = @headrecseq and Form = @firstform
     	
     					insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
     					values (@importid, @template, @firstform, @headrecseq, @errmsg, @ident)
     				
     					goto GetNextHeaderReqSeq
     				  end
     				end
     
     				if @valuelist is not null
     					select @valuelist = @valuelist + ',' + @importvalue
     				else
     					select @valuelist = 'values (' + @importvalue
     	
     				if @columnlist is null
     					select @columnlist = 'Insert into ' + @headtable + ' (' + @importcolumn
     				else
     					select @columnlist = @columnlist + ',' + @importcolumn
     
     			  end
     			end	
     
     			--get the next identifier
				SELECT @ident = MIN(Identifier) FROM (SELECT MIN(Identifier) AS Identifier FROM IMWE WITH (NOLOCK) WHERE IMWE.ImportId = @importid AND 
     			IMWE.ImportTemplate = @template AND IMWE.RecordType = @headrectype AND 
     			IMWE.RecordSeq = @headrecseq AND IMWE.Identifier > @ident
					UNION ALL
				SELECT MIN(Identifier) AS Identifier FROM IMWENotes WITH (NOLOCK) WHERE IMWENotes.ImportId = @importid AND 
     			IMWENotes.ImportTemplate = @template AND IMWENotes.RecordType = @headrectype AND 
     			IMWENotes.RecordSeq = @headrecseq AND IMWENotes.Identifier > @ident) AS IMWEUnion 
     		end
     
     
     		select @headerinsert = @columnlist + ') ' + @valuelist + ')'
     
     		--lock the batch
     		select @batchlock = 'update HQBC set InUseBy = ' + char(@quote) + SUSER_SNAME() + 
     			char(@quote) + ' where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + 
     			char(@quote) + convert(varchar(30), @batchmth) + char(@quote) + ' and BatchId = ' + 
     			convert(varchar(6),@batchid) 
     
     		BEGIN TRANSACTION 
     		select @intrans = 1
     
     		exec(@batchlock)
   
   			delete from IMWM where ImportId = @importid and Error = 9999
   			insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, SQLStatement)
   			values (@importid, @template, @headform, @headrecseq, 9999, '', @headerinsert)
     
			select @errcode = 0
    
			begin try
     		--execute the insert APPB statement
     		exec(@headerinsert)

			end try
     
		  begin catch
			select @errcode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE(), @rcode = 1
			-- Test whether the transaction is uncommittable.
			IF (XACT_STATE()) <> 0
				BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
				END

			Update IMWM
			Set Error = @errcode, Message = @ErrorMessage
			where ImportId = @importid and ImportTemplate = @template and Form = @headform and RecordSeq = @headrecseq
	    
			if @@rowcount <> 1
			  begin
			  Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
			  values (@importid, @template, @headform, @headrecseq, @errcode, @ErrorMessage)
    		  end
		  end catch

     		if @errcode = 0
     		begin
     			--unlock the batch
     			select @batchunlock = 'update HQBC set InUseBy = null where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + 
     			char(@quote) + convert(varchar(30), @batchmth) + char(@quote) + ' and BatchId = ' + 
     			convert(varchar(6),@batchid) 
     
     			exec(@batchunlock)
     
     			if @@error <> 0
     			begin
     				--insert was sucessful but could not unlock the batch, 
     				--abort the whole transaction. may want to consider bumping out
     				--of the whole procedure.
     				select @headerr = 1
     				select @errcode = @@error
     				goto GetNextHeaderReqSeq
     			end
     		end
     		else
     		begin
     			--insert failed, abort transaction
     			select @headerr = 1
     			goto GetNextHeaderReqSeq
     		end
     
     		select @headerinsert = null
     		
     
     		--Clear out the columnlist and valuelist
     		select @columnlist = null, @valuelist = null, @coltype = null
     	
     
     		--Now work on the line item detail records
     		--Get the identifier for the key column
DetailInsert:
   		select @detailkeyident = a.Identifier
   		From IMTD a join DDUD b on a.Identifier = b.Identifier
   		Where a.ImportTemplate=@template AND b.ColumnName = 'RecKey'
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
     		select distinct IMWE.RecordSeq 
     		from IMWE with (nolock) left outer join DDUD with (nolock) on 	
     			IMWE.Form = DDUD.Form and 
     			DDUD.TableName = @detailtable and 
     			DDUD.Identifier = IMWE.Identifier 
     		inner join IMTD with (nolock) on 
     			IMWE.ImportTemplate = IMTD.ImportTemplate and 
     			IMWE.Identifier = IMTD.Identifier and 
     			IMWE.RecordType = IMTD.RecordType  
     		where IMWE.ImportId = @importid and 
     		IMWE.ImportTemplate = @template and 
     		IMWE.RecordType = @detailrectype and 
     		IMWE.Identifier = @detailkeyident and
     		IMWE.UploadVal = @headerkeycol
     		ORDER BY IMWE.RecordSeq
     
     
     		OPEN DetailCursor
    		SELECT @DetailCursorOpen = 1
     		FETCH NEXT FROM DetailCursor INTO @detailrecseq
     		SELECT @dcstatus = @@FETCH_STATUS
     
     		while @dcstatus = 0
     		begin
     			select @detailkeycol = UploadVal 
     			from IMWE with (nolock) 
     			where ImportTemplate = @template and 
     			RecordType = @detailrectype and 
     			RecordSeq = @detailrecseq and 
     			Identifier = @detailkeyident and 
     			ImportId = @importid


--				Get rest of key values 
				-- ExpMth
				SELECT @ExpMth =  IMWE.UploadVal FROM IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @ExpMthID
				-- APTrans
				SELECT @APTrans =  IMWE.UploadVal FROM IMWE 
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @APTransID
				--APRef
				SELECT @APRef =  IMWE.UploadVal FROM IMWE
				WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
					AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
					AND IMWE.Identifier = @APRefID


				-- if bAPTB already exists go to APDB insert
				if exists(select * from dbo.APTB (nolock) where Co=@co and Mth=@batchmth and BatchId=@batchid and
					BatchSeq=@batchseq and ExpMth=@ExpMth and APTrans=@APTrans and APRef=@APRef) goto APDBInsert

				
     			--Get the first identifier for this RecordSequence
     			select @detailident = min(Identifier) 
     			from IMWE with (nolock) 
     			where IMWE.ImportId = @importid and 
     			IMWE.ImportTemplate = @template and 
     			IMWE.RecordType = @detailrectype and 
     			IMWE.RecordSeq = @detailrecseq 
     
     			if @detailkeycol = @headerkeycol
     			begin
     			while @detailident is not null
     			begin
     				select @importcolumn = null, @importvalue = null, @coltype = null
					IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
							   JOIN DDUD d ON c.TABLE_NAME = d.TableName AND c.COLUMN_NAME = d.ColumnName
							   WHERE (c.CHARACTER_MAXIMUM_LENGTH > 60 OR c.CHARACTER_MAXIMUM_LENGTH  = -1) 
							          AND d.Form = @detailform AND d.Identifier = @detailident AND d.TableName = @detailtable)
					BEGIN
	     				SELECT @importcolumn = (SELECT DDUD.ColumnName FROM IMWENotes WITH (NOLOCK) 
		 				left outer join DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
     					DDUD.TableName = @detailtable AND 
     					DDUD.Identifier = IMWENotes.Identifier 
		 				where IMWENotes.ImportId = @importid AND 
     					IMWENotes.ImportTemplate = @template AND 
     					IMWENotes.RecordType = @detailrectype AND 
     					IMWENotes.Identifier = @detailident AND 
     					IMWENotes.RecordSeq = @detailrecseq)
     
	     				SELECT @importvalue = (SELECT IMWENotes.UploadVal FROM IMWENotes WITH (NOLOCK)   
		 				left outer join DDUD WITH (NOLOCK) ON IMWENotes.Form = DDUD.Form AND 
     					DDUD.TableName = @detailtable AND 
     					DDUD.Identifier = IMWENotes.Identifier 
		 				where IMWENotes.ImportId = @importid AND 
     					IMWENotes.ImportTemplate = @template AND 
     					IMWENotes.RecordType = @detailrectype AND 
     					IMWENotes.Identifier = @detailident AND 
     					IMWENotes.RecordSeq = @detailrecseq)
					END
					ELSE
					  BEGIN
	     				select @importcolumn = (select DDUD.ColumnName from IMWE with (nolock) 
		 				left outer join DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     					DDUD.TableName = @detailtable and 
     					DDUD.Identifier = IMWE.Identifier 
		 				where IMWE.ImportId = @importid and 
     					IMWE.ImportTemplate = @template and 
     					IMWE.RecordType = @detailrectype and 
     					IMWE.Identifier = @detailident and 
     					IMWE.RecordSeq = @detailrecseq)
     
	     				select @importvalue = (select IMWE.UploadVal from IMWE with (nolock)  
		 				left outer join DDUD with (nolock) on IMWE.Form = DDUD.Form and 
     					DDUD.TableName = @detailtable and 
     					DDUD.Identifier = IMWE.Identifier 
		 				where IMWE.ImportId = @importid and 
     					IMWE.ImportTemplate = @template and 
     					IMWE.RecordType = @detailrectype and 
     					IMWE.Identifier = @detailident and 
     					IMWE.RecordSeq = @detailrecseq)
					  END
     				if @importcolumn is not null
     				begin
     					if @importcolumn = 'BatchId'
     						select @importvalue = @batchid
     
     					if @importcolumn = 'Mth'
     						select @importvalue = @batchmth
     
     					if @importcolumn = 'BatchSeq'
     						select @importvalue = @batchseq
     
     					if @importvalue = '' or @importvalue is null
     					begin	
     						if (select COLUMNPROPERTY( OBJECT_ID(@detailrectype),@importcolumn,'AllowsNull')) = 0 
     						--update upload value...message that Table.Column cannot be null
     						--stop developing this record, go to next record sequence
     						begin 
     							select @rcode = 1, @detailerr = 1
     							select @errmsg =  'Column : ' + @importcolumn + ' does not allow null values! See Identifier ' 
     												+ convert(varchar(10), @detailident)
     
     							--Build error message to input after transaction rollback, otherwise gets rolled back!
     							select @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) ' +
     								'values (' + char(@quote) + @importid + char(@quote) + ',' + char(@quote) + @template + char(@quote) + ',' + 
     								char(@quote) + @secondform + char(@quote) + ',' + convert(varchar(10),@detailrecseq) + ',' + 
     								convert(varchar(10),@detailerr) + ',' + char(@quote) + @errmsg + char(@quote) + ',' + convert(varchar(10), @detailident) + ')'
								
     							goto GetNextHeaderReqSeq	--Exit on first detail error, because we can't store more than one insert statement for IMWM.
     						end
     						else
     							select @importvalue = null
     					end
     					--Catch fields with embedded single quotes...
     					if CHARINDEX(char(@quote),@importvalue) > 0
     					begin
     						--replace single quotes with single back-quotes
     						SELECT @importvalue = REPLACE(@importvalue, char(@quote), '`')
     					end
     
     					--Varchar, Char, and Smalldatetime data types need to be encapsulated in '''
     					select @coltype = ColType 
     					from DDUD where Form = @detailform and 
     					Identifier = @detailident
     
     					if @coltype = 'varchar' or @coltype = 'text'
     					begin
     						if isnull(@importvalue,'') <> '' 
     						begin
     							select @importvalue = char(@quote) + @importvalue + char(@quote)
     						end
     						else
     					begin
     							select @importvalue = 'char(null)'
     						end
     					end
     
     					--if @coltype = 'char' select @importvalue = char(@quote) + @importvalue + char(@quote)
     					if @coltype = 'char' 
     					begin
     						if isnull(@importvalue,'') <> '' 
     						begin
     							select @importvalue = char(@quote) + @importvalue + char(@quote)
     						end
     					else
     					begin
     						select @importvalue = 'char(null)'
     					end
     				end
     
     				--if @coltype = 'smalldatetime' select @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     				if @coltype = 'smalldatetime' 
     				begin
     					if isnull(@importvalue,'') <> '' 
     					begin
							select @importvalue = char(@quote) + ltrim(@importvalue) + char(@quote)
     					end
     					else
     					begin
     						select @importvalue = 'char(null)'
     					end
     				end
     
     				if @coltype = 'tinyint' or @coltype = 'int' or @coltype = 'numeric' 
     				begin
     					if isnull(@importvalue,'') = '' select @importvalue = 'char(null)'
     				end
     
     				if @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
     				begin
					  set @importvalue = replace(@importvalue, ',', '') --CC issue #127127
     				  if isnumeric(@importvalue) <> 1 and @importvalue is not null and @importvalue <> 'char(null)'
     				  begin
     					select @rcode = 1, @detailerr = 1
     					select @errmsg =  'Column : ' + @importcolumn + ' does not allow non-numeric values! See Identifier ' 
     										+ convert(varchar(10), @detailident)
     					
     					--Build error message to input after transaction rollback, otherwise gets rolled back!
     					select @IMWMinsert = 'insert IMWM (ImportId, ImportTemplate, Form, RecordSeq, Error, Message, Identifier) ' +
     						'values (' + char(@quote) + @importid + char(@quote) + ',' + char(@quote) + @template + char(@quote) + ',' + 
     						char(@quote) + @secondform + char(@quote) + ',' + convert(varchar(10),@detailrecseq) + ',' + 
     						convert(varchar(10),@detailerr) + ',' + char(@quote) + @errmsg + char(@quote) + ',' + convert(varchar(10), @detailident) + ')'
				
     					goto GetNextHeaderReqSeq	--Save time by exiting now, but remaining details may have errors.
     
     				  end
     				end
     
     				if @importvalue is not null
     				begin
     					if @detailvallist is not null
     						select @detailvallist = @detailvallist + ',' + @importvalue
     					else
     						select @detailvallist = 'values (' + @importvalue 
     
     					if @detailcollist is not null
     						select @detailcollist = @detailcollist + ',' + @importcolumn
     					else
     						select @detailcollist = 'insert into ' + @detailtable + ' (' + @importcolumn 
     			  	end
     			end
     
     			--Get the next identifier for this RecordSequence
				SELECT @detailident = MIN(Identifier) FROM (SELECT MIN(Identifier) AS Identifier FROM IMWE WITH (NOLOCK) WHERE IMWE.ImportId = @importid AND 
     			IMWE.ImportTemplate = @template AND IMWE.RecordType = @detailrectype AND 
     			IMWE.RecordSeq = @detailrecseq AND IMWE.Identifier > @detailident
					UNION ALL
				SELECT MIN(Identifier) AS Identifier FROM IMWENotes WITH (NOLOCK) WHERE IMWENotes.ImportId = @importid AND 
     			IMWENotes.ImportTemplate = @template AND IMWENotes.RecordType = @detailrectype AND 
     			IMWENotes.RecordSeq = @detailrecseq AND IMWENotes.Identifier > @detailident) AS IMWEUnion 
     		end	--develop detail 
     
     		select @detailinsert = @detailcollist + ') ' + @detailvallist + ')'
     
   		delete from IMWM where ImportId = @importid and Error = 9999
   		insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, SQLStatement)
   		values (@importid, @template, @headform, @detailrecseq, 9999, '', @detailinsert)
   
			select @errcode = 0

			begin try
     		exec(@detailinsert)

			end try 
		   
			begin catch
			select @errcode = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE(), @rcode = 1

			-- Test whether the transaction is uncommittable.
			IF XACT_STATE() <>0
				BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
				END

				Update IMWM
				Set Error = @errcode, Message = @ErrorMessage
				where ImportId = @importid and ImportTemplate = @template and Form = @detailform and RecordSeq = @detailrecseq
		    
				if @@rowcount <> 1
				  begin
				  Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
				  values (@importid, @template, @detailform, @detailrecseq, @errcode, @ErrorMessage)
				  end
			end catch
     
     		if @errcode <> 0
     		begin
     			select @detailerr = 1
     			goto GetNextHeaderReqSeq
     		end
     
     		select @detailcollist = null
     		select @detailvallist = null
     		select @detailinsert = null
     
     	end
	
	APDBInsert:
		-- prepare to insert bAPDB records
		-- get rest of IMWE values to pass

		-- InvDate
		SELECT @InvDate =  IMWE.UploadVal FROM IMWE 
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @InvDateID

		-- AmtToPay
		SELECT @AmtToPay =  IMWE.UploadVal  FROM IMWE
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @AmtToPayID

		-- if this is a Textura import get retainage flag and SL
		if @TexturaYN = 'Y'
		begin
		-- RetainageFlag
		SELECT @RetainageFlag =  IMWE.UploadVal FROM IMWE
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @RetainageFlagID
		-- SL
		SELECT @SL =  IMWE.UploadVal FROM IMWE
		WHERE IMWE.ImportTemplate = @template AND IMWE.ImportId = @importid 
			AND IMWE.RecordType = @detailrectype AND IMWE.RecordSeq = @detailrecseq
			AND IMWE.Identifier = @SLID
		end
  
		select @errcode = 0

		-- execute sp to insert APDB records for invoices or create APTB/APDB for released retainage
		begin try
     		exec @apdbrcode = vspIMUploadAPDB @co, @batchmth, @batchid,@batchseq,
			@ExpMth,@APTrans,@APRef,@InvDate, @RetainageFlag,@AmtToPay,@SL,@TexturaYN, @errmsg output
			if @apdbrcode=1
			
			begin
			-- RAISERROR with severity 11-19 will cause execution to jump to the CATCH block
			RAISERROR (@errmsg, -- Message text.
			   16, -- Severity.
			   1 -- State.
			   );
			end
			
		end try 
		   
		begin catch
			select @errcode = ERROR_NUMBER(), @rcode = 1
			-- Test whether the transaction is uncommittable.
			IF XACT_STATE() <>0 
				BEGIN
					ROLLBACK TRANSACTION;
					SET @intrans = 0
				END
			-- write to error log
			select @ErrorMessage = ERROR_MESSAGE()
			Insert dbo.IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
			values (@importid, @template, @detailform, @detailrecseq, 0, @ErrorMessage)

			if @errcode <> 0
     		begin
     			select @detailerr = 1, @apdbrcode = 0
     			goto GetNextHeaderReqSeq
     		end

		end catch
     
     GetNextDetailReqSeq:
     
     	if @detailerr = 0
     	begin 
     		--only delete if detailkey and headerkey match
     		if @detailkeycol = @headerkeycol
     		begin
     			select @deletestmt = 'Delete IMWE where ImportId = ' + char(@quote) + @importid + char(@quote) + 
     			' and RecordSeq = ' + convert(varchar(5),@detailrecseq) + ' and RecordType = ' + char(@quote) + 
     			@detailrectype + char(@quote)  
     
     			exec(@deletestmt)
     			select @deletestmt = null
				
				SELECT @deletestmt = 'DELETE IMWENotes WHERE ImportId = ' + CHAR(@quote) + @importid + CHAR(@quote) + 
     			' AND RecordSeq = ' + CONVERT(VARCHAR(5),@detailrecseq) + ' AND RecordType = ' + CHAR(@quote) + 
     			@detailrectype + CHAR(@quote)  
     
     			EXEC(@deletestmt)
     			SELECT @deletestmt = NULL	
     		end
     	end
     	else
     	begin
     		select @errdesc = description from master.dbo.sysmessages where error = @errcode
     	end
     
     	select @detailcollist = null, @detailvallist = null
     
     	FETCH NEXT FROM DetailCursor INTO @detailrecseq
     	SELECT @dcstatus = @@FETCH_STATUS
     
     end
     
     --get next header record
     GetNextHeaderReqSeq:
    	IF @DetailCursorOpen = 1
    	BEGIN
    	 	CLOSE DetailCursor
    		SELECT @DetailCursorOpen = 0
     		DEALLOCATE DetailCursor
     	END
    
     	select @detailcollist = null
     	select @detailvallist = null
     	select @detailinsert = null
     	
     	if @headerr = 0 and @detailerr = 0
     	begin 
     
     		if @intrans = 1
     		begin
     			COMMIT TRANSACTION
     			select @intrans = 0	
     		end
     		--Delete Record from IMWE
     		select @deletestmt = 'Delete IMWE where ImportId = ' + char(@quote) + @importid + char(@quote) + 
     		' and RecordSeq = ' + convert(varchar(5),@headrecseq) + ' and RecordType = ' + char(@quote) +
     		@headrectype + char(@quote)
     
     		exec(@deletestmt)
     		select @deletestmt = null
     
     		SELECT @deletestmt = 'DELETE IMWENotes WHERE ImportId = ' + CHAR(@quote) + @importid + CHAR(@quote) + 
     		' AND RecordSeq = ' + CONVERT(VARCHAR(5),@detailrecseq) + ' AND RecordType = ' + CHAR(@quote) + 
     		@detailrectype + CHAR(@quote)  
     
     		EXEC(@deletestmt)
     		SELECT @deletestmt = NULL	
     		--Update IMBC 
     		if @batchid is not null
     		begin
     			select @imbccount = (select count(ImportId) from IMBC where ImportId = @importid and Co = @co and Mth = @batchmth and BatchId = @batchid)
     
     			if @imbccount = 0
     			begin
     				Insert IMBC (ImportId, Co, Mth, BatchId, RecordCount) values (@importid, @co, @batchmth, @batchid, 1)
     			end
     
     			if @imbccount = 1
     			begin
     				Update IMBC set RecordCount = RecordCount + 1 where ImportId = @importid and Co = @co and Mth = @batchmth and BatchId = @batchid
     			end
     
     			select @imbccount = null
     
     		end
     	end
     	else
     	begin
     		if @intrans = 1
     		begin
     			ROLLBACK TRANSACTION
     			select @intrans = 0
     		end
    
			IF @IMWMinsert IS NOT NULL
			EXEC(@IMWMinsert)
			
     		select @rcode = 1
     		select @errmsg = 'Data errors.  Check IM Work Edit and IMWM.'
     
     	end
     
     	select @columnlist = null, @valuelist = null, @headerr = 0
     
     	select @IMWMinsert = null
     
     	FETCH NEXT FROM HeaderCursor INTO @headrecseq
     	SELECT @hcstatus = @@FETCH_STATUS
     
     end --end outer while
     
     
     bspexit:
     
     IF @HeaderCursorOpen = 1 
     BEGIN
    	 close HeaderCursor
    	 SELECT @HeaderCursorOpen = 0
    	 deallocate HeaderCursor
     END
     
     IF @ANSIWARN = 1
     	SET ANSI_WARNINGS ON
     
     
          return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspIMUploadHeaderDetailPay] TO [public]
GO
