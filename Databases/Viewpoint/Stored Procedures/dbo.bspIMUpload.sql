SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspIMUpload]
    
      /**************************************************
      *
      *Created By:  MH 05/03/2002
      *Modified By: mh 5/9/02 Issue 17289 
      *             danf 10/16/02 Added rectype to bspIMBatchAssign
      *             bc  12/16/02 - #19669   
      *             bc  03/36/03 - cleaned up white space for readability
      *				RBT 05/13/03 - #21242 SET ANSI_WARNINGS OFF to avoid truncation error msgs
      *				RBT 05/16/03 - #17507 Fixed exec calls to use 'OUTPUT' keyword 
      *					for return error messages.
      *				RBT 05/20/03 - #19675 Catch non-numeric data being passed for numeric fields,
      *					and change call to bspIMGetLastBatchSeq to return value into @rc instead
      *					of @rcode so VB knows about errors.  Changed err msgs to be more descriptive.
      *				RBT 06/05/03 - #20197 Replace single quotes with single backquotes.
      *				DC 9/25/03  - #21652 - Increased the Seq number for 2nd upload of the day
      *				RBT 10/27/03 - #22777 Save SQL string as error 9999 in IMWM in case of fatal error.
      *				RBT 01/12/04 - #23432 Import to Notes field.
      *				RBT 01/14/04 - #23449 Correct batch record count.
      *				RBT 08/25/04 - #25350 Make sure to store identifier in IMWM when entries made.
      *				RBT 11/01/04 - #24532 Use 62 byte variable for uploadval.
      *				DANF 12/19/06 - 6.X Added Try Catch around insert statement
      *				CC	02/26/08 - #127127 strip comma from numeric values
	  *				CC  03/20/08 - #127467 add check for null batch company add error, and skip record
	  *				CC  03/20/08 - #122980 add support for notes/large fields
	  *				CC	08/14/08 - #129393 added condition to get company for CMCE imports
	  *				CC	09/22/08 - #129868 Corrected getting max sequence for existing CMCE records.
	  *				mh  03/17/10 - #130799 Clear out CMCE before importing records.  This will allow 
	  *								customers to re-import and re-upload a file without having to use
	  *								the purge process.
	  *				
      * Note:  This is a re-write of bspIMUpload from 10/4/99
      * USAGE:
      *
      * Upload data from IMWE to appropriate tables
      *
      *INPUT PARAMETERS
      *    ImportId, Template
      *
      *RETURN PARAMETERS
      *    Error Message
      *
      *None
      *
      *************************************************/
      (@importid varchar(20) = null, @template varchar(30) = null, 
          @errmsg varchar(255) = null output)
     
      AS
     
      set nocount on
      /* Store current state for ANSI_WARNINGS to restore at end. */
    	declare @ANSIWARN int
    	SELECT @ANSIWARN = 0
    	IF @@OPTIONS & 8 > 0
    		SELECT @ANSIWARN = 1
    	SET ANSI_WARNINGS OFF
    
      --Local Variables that will hold contents of cursor
      declare @recseq int, @tablename varchar(20), @column varchar(30), @uploadval varchar(max),
              @ident int, @seq int
     
      --Local Variables - misc
      declare @curr_rec_seq int, @allownull int, @error int, @insertstmt varchar(max), @valuelist varchar(max),
              @columnlist varchar(8000), @complete int, @counter int, @records int, 
              @deletestmt varchar(8000), @formtype int, @coltype varchar(20), @batchassign_errmsg varchar(255),
              @batch_col varchar(10), @month_col varchar(10), @batchid bBatchID, @mth bMonth,
              @batchlock varchar(8000), @batchunlock varchar(8000), @sql varchar(500),
              @updateIMBC varchar(8000), @rcode int, @errcode int, @errdesc varchar(255), @form varchar(30),
      		  @batchlockmth varchar(30), @coident int, @co bCompany, @rectype varchar(30),
    		  @cmco bCompany, @uploaddate bDate, @bankacct varchar(30), @minseq int, @rc int,
    		  @CMCESeq int,  --DC 21652
    	      @tblname varchar(30)  --DC 21652
     
    --@mth varchar(30)
    declare @openrecseqcursor int, @openuploadcursor int
    declare @test bMonth, @maxbatchid int, @quote int, @imbccount int
    
    --the ascii code for a single quote
    select @quote = 39
    
    select @rcode = 0, @openrecseqcursor = 0, @openuploadcursor = 0
    
    
    if @importid is null
    begin
    	select @errmsg = 'Missing Import Id', @rcode = 1
    	goto bspexit
    end
    
    if @template is null
    begin
    	select @errmsg = 'Missing Import Template', @rcode = 1
    	goto bspexit
    end
    
    --get the form
    select @form = Form from IMTR where ImportTemplate = @template
     
    select @rectype =  MIN(RecordType) from IMTR where ImportTemplate = @template
    
    --Check if form needs batch
    select @formtype = FormType from DDFH where Form = @form
    
    --Get the identifier for the company.  This should be the first identifier.
    select @coident = min(Identifier)
    from IMWE 
    where ImportTemplate = @template
     
    if @formtype = 2  --batch form is type 2.
      begin
      --this form needs a batch.
      if @form <> 'PRTimeCards'
        begin
    	    exec @rcode = bspIMBatchAssign @importid, @template, @rectype, @form, @coident, @batchassign_errmsg output
    		if @rcode = 1
    		begin
    			select @errmsg = @batchassign_errmsg
    			goto bspexit
    		end
        end
      else
    	begin
        exec @rcode = bspIMBatchAssignPR @form, @importid, @batchassign_errmsg output
       	if @rcode = 1 --there was an error creating the batches
          begin
    	  select @errmsg = @batchassign_errmsg
          goto bspexit
          end
    	end
      end
    
    
    /***** DC 21652 *START************************************
    Gets the next seq number to use*********************/
    
      select top 1 @tblname = d.TableName from IMWE e with (nolock)
      inner join DDUD d on d.Identifier = e.Identifier and d.Form = e.Form
      where e.ImportId = @importid and e.ImportTemplate = @template
      IF @tblname = 'CMCE'
    	BEGIN
    		--Begin 130799
			-- select @CMCESeq = Max(Seq) from CMCE with (nolock) where CMCo = (select top 1 e.UploadVal from IMWE e with (nolock)
			--		inner join DDUD d on d.Identifier = e.Identifier and d.Form = e.Form
			--where ColumnName = 'CMCo' and e.ImportId = @importid) and UploadDate = CAST(CONVERT(VARCHAR(20),GETDATE(), 101) AS DATETIME)
			
			select @minseq = Min(RecordSeq) from IMWE where ImportId = @importid and ImportTemplate = @template and Form = @form

			select @cmco = e.UploadVal 
			from IMWE e with (nolock) join DDUD d with (nolock) on e.Form = d.Form and e.Identifier = d.Identifier  
			where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and 
			e.RecordSeq = @minseq and d.ColumnName = 'CMCo'
			
			select @uploaddate = cast(e.UploadVal as smalldatetime)
			from IMWE e with (nolock) join DDUD d with (nolock) on e.Identifier = d.Identifier and e.Form = d.Form
			where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and 
			e.RecordSeq = @minseq and d.ColumnName = 'UploadDate'
			
			select @bankacct = e.UploadVal 
			from IMWE e with (nolock) join DDUD d with (nolock) on e.Identifier = d.Identifier and e.Form = d.Form
			where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and 
			e.RecordSeq = @minseq and d.ColumnName = 'BankAcct'

			delete CMCE  
			from CMCE where CMCo = @cmco and UploadDate = @uploaddate and BankAcct = @bankacct
  		
    		select @CMCESeq = 0
    		--End 130799
    	END
     
    /****** DC END ********************************************/
    
    declare RecSeq_curs cursor
    for
    Select distinct RecordSeq 
    from IMWE
    where ImportId = @importid and ImportTemplate = @template and Form = @form
    Order by RecordSeq
    
    open RecSeq_curs
    
    select @openrecseqcursor = 1
    DECLARE @IsNote bYN

    fetch next from RecSeq_curs into @recseq
    
    while @recseq is not null
      begin
      declare Upload_curs cursor
      for
	  	WITH IMWE_CTE (TableName, ColumnName, UploadVal, Identifier, ImportId, IsNote) AS 
		(
		select d.TableName, d.ColumnName, e.UploadVal, e.Identifier, e.ImportId, 'N'
		from IMWE e
		inner join DDUD d on d.Identifier = e.Identifier and d.Form = e.Form
		where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and e.RecordSeq = @recseq 
	  UNION ALL
		select d.TableName, d.ColumnName, e.UploadVal, e.Identifier, e.ImportId, 'Y'
		from IMWENotes e
		inner join DDUD d on d.Identifier = e.Identifier and d.Form = e.Form
		where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and e.RecordSeq = @recseq 
		)    
		SELECT TableName, ColumnName, UploadVal, Identifier, ImportId, IsNote FROM IMWE_CTE ORDER BY Identifier
	  
      open Upload_curs
    
      select @openuploadcursor = 1
     
      fetch next from Upload_curs into @tablename, @column, @uploadval, @ident, @importid, @IsNote
     
      while @ident is not null
      BEGIN 
    
        --Get the destination Company
        if @ident = @coident and (@formtype = 2 OR @tablename = 'CMCE') select @co = @uploadval
    
    	
    --DC 21652----START------------------------
    	--if upper(@column) = 'SEQ' select @uploadval = @recseq 
    
    	if upper(@column) = 'SEQ' AND @tablename = 'CMCE' 
    	BEGIN	
    	  select @CMCESeq = ISNULL(@CMCESeq,0) + 1
    	  select @uploadval = @CMCESeq 
    	END
    	ELSE
    	BEGIN
    	  if upper(@column) = 'SEQ' select @uploadval = @recseq 
    	END
    --DC 21652----END-------------------------
    
        --Need to capture BatchId and Mth.  Used to lock the batch prior to executing insert statement
        --and unlock that batch after the insert statement.
        if @column = 'BatchId' select @batch_col = @column, @batchid = convert(int,@uploadval)
			BEGIN
				IF @co IS NULL
				begin  
    	          --Write back to IMWE
    		      update IMWE
    			  set UploadVal = '*MISSING REQUIRED VALUE*'
    	          where ImportId = @importid and ImportTemplate = @template and Identifier = @coident and RecordSeq = @recseq

    			  SELECT @errmsg = 'Batch Company is null'

    			  Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, Message)
    			  values (@importid, @template, @form, @recseq, @ident, @errcode, @errmsg)
    
    	          --dump this record seq.  go onto next one	
    			  --close Upload_curs
    			  --deallocate Upload_curs
    			  goto NextReqSeq
				end
		    	if upper(@column) = 'BATCHSEQ' and @formtype = 2 
					begin
						/* Only retrieve the last batch sequence when uploading into a processing form.  #19669 */
    					--Note if IMPR.PREndDate is null, the following bsp will not work
						exec @rc = bspIMGetLastBatchSeq @co, @mth, @batchid, @tablename, @maxbatchid output, @errmsg output
						if @rc = 0
							begin
		 						select @uploadval = convert(varchar(100), @maxbatchid + 1)
							end
     					else
     						begin
    							select @rcode = 1
     							select @errmsg = 'Unable get last Batch Seq.  ' + @errmsg
     							goto bspexit
		 					end
					end		
    		END
        if @uploadval <> '' and @uploadval is not null
     	Begin
    		--Issue #20197 - Catch fields with embedded single quotes...
    		if CHARINDEX(char(@quote),@uploadval) > 0
    		begin
    			--replace single quotes with single back-quotes
    			SELECT @uploadval = REPLACE(@uploadval, char(@quote), '`')
    		end
    
          select @coltype = ColType from DDUD where Form = @form and Identifier = @ident
     
          --Varchar, Char, and Smalldatetime data types need to be encapsulated in '''
          if @coltype = 'varchar' or @coltype = 'text'
    	  	select @uploadval = char(@quote) + @uploadval + char(@quote)
     
          if @coltype = 'char' select @uploadval = char(@quote) + @uploadval + char(@quote)
    
    	  --Issue #19675 - Check numeric types for validity
    	  if @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
    
    	  begin
			set @uploadval = replace(@uploadval, ',', '') --CC issue #127127
    		if isnumeric(@uploadval) <> 1 --if not numeric
    		begin
    			select @rcode = 1, @errmsg = 'Non-numeric value found in numeric field (' + convert(varchar(10),@ident) + ').'
    	        update IMWE
    		  	set UploadVal = '*VALUE NOT NUMERIC*'
              	where ImportId = @importid and ImportTemplate = @template and Identifier = @ident and RecordSeq = @recseq
    
    	        Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Message, Identifier)
    	        values (@importid, @template, @form, @recseq, @errmsg, @ident)
    
    			goto NextReqSeq
    		end
    	  end
    
          -- mh 6/5/02
          --if @coltype = 'smalldatetime' select @uploadval = char(@quote) + ltrim(@uploadval) + char(@quote)
    	  if @coltype = 'smalldatetime' 
    		Begin
    			if @column = 'Mth'
    			begin
    			  select @month_col = @column
    			  select @mth = ltrim(@uploadval)	
    			end
    			select @uploadval = char(@quote) + ltrim(@uploadval) + char(@quote)
    		end
    									   
       		--5/30/00 skip column if PRGroup or PREndDate
    		if @column <> 'PRGroup' and @column <> 'PREndDate'
              begin
              --build values list
              if @valuelist is not null select @valuelist = @valuelist + ',' + @uploadval else select @valuelist = @uploadval
     
              --build column list
              if @columnlist is not null select @columnlist = @columnlist + ',' + @column else select @columnlist = @column
              end
    	  End
    	  Else 
    	  Begin  
    		--check for nullability
    		select @allownull = COLUMNPROPERTY( OBJECT_ID(@tablename),@column,'AllowsNull')
     
    		--if nulls not allowed
    	   	if @allownull = 0 and @uploadval = ''
    	      begin  
    	          --Write back to IMWE
    		      update IMWE
    			  set UploadVal = '*MISSING REQUIRED VALUE*'
    	          where ImportId = @importid and ImportTemplate = @template and Identifier = @ident and RecordSeq = @recseq
    	
    			  Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, Message)
    			  values (@importid, @template, @form, @recseq, @ident, @errcode, @errmsg)
    
    	          --dump this record seq.  go onto next one	
    			  --close Upload_curs
    			  --deallocate Upload_curs
    			  goto NextReqSeq
    	      end
    	  End
    
    		
          fetch next from Upload_curs into @tablename, @column, @uploadval, @ident, @importid, @IsNote
    	  if @@fetch_status <> 0 select @ident = null
        END
    
      --@ident is now null...do insert
      select @insertstmt = 'Insert ' + @tablename + ' (' + @columnlist + ') values (' +  @valuelist + ')'
    
      --Lock batch
      if @batch_col = 'BatchId' and @month_col = 'Mth'
        begin
    	select @batchlockmth = char(39) + convert(varchar(30), @mth) + char(39)
    	select @batchlock = 'update HQBC set InUseBy = ' + char(@quote) + SUSER_SNAME(SUSER_SID ()) + char(@quote) + ' where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + @batchlockmth + ' and BatchId = ' + convert(varchar(6),@batchid)
        exec(@batchlock)
        end 
     
      --#22777, save SQL string in IMWM
    	delete from IMWM where ImportId = @importid and Error = 9999
    	insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message, SQLStatement)
    	values (@importid, @template, @form, @recseq, 9999, NULL, @insertstmt)

		select @errcode = 0
    
	  begin try

      --Execute Insert Statement
      exec(@insertstmt)
	
	  end try 
   
	  begin catch
        select @errcode = ERROR_NUMBER(), @rcode = 1

        Update IMWM
        Set Error = ERROR_NUMBER(), Message = ERROR_MESSAGE()
        where ImportId = @importid and ImportTemplate = @template and Form = @form and RecordSeq = @recseq
    
        if @@rowcount <> 1
          begin
          Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
          values (@importid, @template, @form, @recseq, ERROR_NUMBER(), ERROR_MESSAGE())
    	  end
	  end catch

      --Delete Record from IMWE & IMWENotes
      if @errcode = 0
      begin
    	delete IMWE where ImportId = @importid and ImportTemplate = @template and RecordSeq = @recseq
		DELETE FROM IMWENotes WHERE ImportId = @importid AND ImportTemplate = @template AND RecordSeq = @recseq
      end

/* Relplace with  try catch
      select @errcode = @@error
    
      --Delete Record from IMWE
      if @errcode = 0
      begin
    	delete IMWE where ImportId = @importid and ImportTemplate = @template and RecordSeq = @recseq
      end
      else
      begin
    	select @rcode = 1
        select @errdesc = description from master.dbo.sysmessages where error = @errcode
        
        Update IMWM
        Set Message = @errdesc
        where ImportId = @importid and ImportTemplate = @template and Form = @form and RecordSeq = @recseq
    
        if @@rowcount <> 1
          begin
          Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
          values (@importid, @template, @form, @recseq, @errcode, @errdesc)
    	  end
      end
*/
      --Unlock batch
      if @batch_col = 'BatchId' and @month_col = 'Mth'
        begin
    	select @batchlockmth = char(39) + convert(varchar(30), @mth) + char(39)
    	select @batchunlock = 'update HQBC set InUseBy = null where Co = ' + convert(varchar(3),@co) + ' and Mth = ' + @batchlockmth + ' and BatchId = ' + convert(varchar(6),@batchid)
        exec(@batchunlock)
        end
     
      --Update IMBC 
      if @batchid is not null and @errcode = 0	--Issue 23449, do not count errors.
      begin
     	select @imbccount = (select count(ImportId) from IMBC where ImportId = @importid and Co = @co and Mth = @mth and BatchId = @batchid)
    
        if @imbccount = 0
        begin
          Insert IMBC (ImportId, Co, Mth, BatchId, RecordCount) values (@importid, @co, @mth, @batchid, 1)
        end
    
        if @imbccount = 1
        begin
          Update IMBC set RecordCount = RecordCount + 1 where ImportId = @importid and Co = @co and Mth = @mth and BatchId = @batchid	
        end
    
        select @imbccount = null
      end
    
      NextReqSeq:
      -- Issue #19675 - moved this line below NextReqSeq so they'll get reset in case we have 
      -- an error and jump here using 'goto'.
      select @columnlist = null, @valuelist = null, @insertstmt = null
    
      close Upload_curs
      deallocate Upload_curs
      select @openuploadcursor = 0
    
      select @recseq = null
      fetch next from RecSeq_curs into @recseq
      if @@fetch_status <> 0 select @recseq = null
    
    end
    
    close RecSeq_curs
    deallocate RecSeq_curs
    select @openrecseqcursor = 0
    
    bspexit:
    
    if @openuploadcursor = 1
    begin
    	close Upload_curs
    	deallocate Upload_curs
    end	
    
    if @openrecseqcursor = 1
    begin
    	close RecSeq_curs 
    	deallocate RecSeq_curs
    end
    
    if @ANSIWARN = 1
    	SET ANSI_WARNINGS ON
    
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMUpload] TO [public]
GO
