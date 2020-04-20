SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMUploadDirect]
       
         /**************************************************
         *
         * Created By:  RT 07/01/03 Issue 13558 - Direct Table Imports (update/insert).
         * Modified By: RT 10/27/03 Issue 22777 - Save SQL strings in IMWM as error 9999 in case of
         *						Trigger or table constraint error.
         *		  		RT 01/13/04 Issue 23432 - Allow importing into bNotes fields.
         *		  		RT 02/17/04 Issue 13558 Fix - Check for existing records even if update=N.
     	*		  		RT 04/01/04 Issue 23929 - Take out code that excludes PRGroup and PREndDate columns.
    	    *				RT 04/22/04 Issue 24402 - Fix null column check to use isnull.
    	    *				RT 08/25/04 Issue 25350 - Make sure to store identifier in IMWM when entries made.
    	    *				RT 10/01/04 Issue 25668 - Do not check non-nullable non-key fields for upload-only.
  	    *				RT 11/01/04 Issue 24532 - Use 62 byte variable for uploadval.
 		*				RT 01/18/05 Issue 19580 - Fix for null tablename for last column in template.
 		*				RT 07/18/05 Issue 29144 - Increase UpdVal to 62 characters to allow for single quotes.
		 *				DANF 10/12/06 Issue 122528 - Do not auto increment Seq number for the PRAE Table.
		 *				CC 2/26/08 Issue 127127 - Remove commas from numeric values
		 *				CC 03/25/08 Issue 122980 - Handled notes/large fields
		 *				DANF 04/17/08 - Issue 123291 - Correct update and insert SQL statements when imported column is null.
		 *				CC 05/05/08 - Issue 128132 - Pass empty string for non-nullable columns where upload val is null and for nullable columns where upload val is empty string													 
         *
         * Note:  This is a re-write of bspIMUpload.
         * USAGE:
         *
         * Upload data from IMWE to appropriate tables, update if existing, else insert.
         *
         * INPUT PARAMETERS
         *    ImportId, Template
         *
         * RETURN PARAMETERS
         *    Error Message and
         *	   0 for success, or
         *    1 for failure
         *
         *************************************************/
         (@importid varchar(20) = null, @template varchar(30) = null, 
             @errmsg varchar(255) = null output)
        
         AS
        
         set nocount on
         /* Store current state for ANSI_WARNINGS to restore at end. */
         /* This allows column values to be truncated if too long. */
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
                 @columnlist varchar(max), @complete int, @counter int, @records int, 
                 @deletestmt varchar(max), @formtype int, @coltype varchar(20), 
                 @sql varchar(max), @month_col varchar(10), @mth bMonth,
                 @rcode int, @errcode int, @errdesc varchar(255), @form varchar(30),
         		  @batchlockmth varchar(30), @coident int, @co bCompany, @rectype varchar(10),
       		  @rc int, @insertyn varchar(1), @updateyn varchar(1), @insupdtype smallint, @UpdCol varchar(30),
       		  @UpdVal varchar(max), @UpdTable varchar(30),
       		  @UploadCursorUsed int, @RecSeqCursorUsed int, @CheckExistingStmt varchar(max),
       		  @updatestmt varchar(max), @whereclause varchar(max), @ExistRecs int
       --@tblUpdateKeys 
         CREATE TABLE #tblUpdateKeys (
       		UpdCol varchar(30) not null,
       		UpdVal varchar(MAX) null)
		CREATE INDEX UpdateKeys ON #tblUpdateKeys (UpdCol)


         CREATE TABLE #tblUpdateValues (
       		UpdCol varchar(30) not null,
       		UpdVal varchar(MAX) null)
   		 CREATE INDEX UpdateValues ON #tblUpdateKeys (UpdCol)       

       declare @openrecseqcursor int, @openuploadcursor int
       declare @quote int, @imbccount int
       
       --the ascii code for a single quote
       select @quote = 39
       
       select @rcode = 0, @openrecseqcursor = 0, @openuploadcursor = 0, 
       	@UploadCursorUsed = 0, @RecSeqCursorUsed = 0
       
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
       select @form = Form from IMTR with (nolock) where ImportTemplate = @template
        
       select @rectype = MIN(RecordType) from IMTR with (nolock) where ImportTemplate = @template
       
       select @insupdtype = DirectType from IMTH with (nolock) where ImportTemplate = @template
       if @insupdtype is null	--if type is null, user selected this upload procedure but did not check the box for insert/update upload.
       begin
       	select @insertyn = 'Y', @updateyn = 'N'		--set default action in case type is null (should not be null)
       	update IMTH set DirectType = 0 where ImportTemplate = @template
       end
       else
       begin
       	if @insupdtype = 0			--insert and update
       		select @insertyn = 'Y', @updateyn = 'Y'
       	else if @insupdtype = 1		--insert only
       		select @insertyn = 'Y', @updateyn = 'N'
       	else if @insupdtype = 2		--update only
       		select @insertyn = 'N', @updateyn = 'Y'
       end
       
      -- if @updateyn = 'Y'
      -- begin
       	--Populate the columns for update value and update key tables.
       	insert into #tblUpdateKeys(UpdCol, UpdVal)
       		select ColumnName, null from DDUD a join IMTD b on a.Identifier = b.Identifier
       		join IMTH c on b.ImportTemplate = c.ImportTemplate and c.Form = a.Form
       		where b.ImportTemplate = @template and b.UpdateKeyYN = 'Y'
       
       	insert into #tblUpdateValues(UpdCol, UpdVal)
       		select ColumnName, null from DDUD a join IMTD b on a.Identifier = b.Identifier
       		join IMTH c on b.ImportTemplate = c.ImportTemplate and c.Form = a.Form
       		where b.ImportTemplate = @template and b.UpdateValueYN = 'Y'
       
      -- end
       declare RecSeq_curs cursor local fast_forward for
       Select distinct RecordSeq 
       from IMWE with (nolock)
       where ImportId = @importid and ImportTemplate = @template and Form = @form
       Order by RecordSeq
       
       select @RecSeqCursorUsed = 1
       
       open RecSeq_curs
       
       select @openrecseqcursor = 1
       
       fetch next from RecSeq_curs into @recseq
       
       while @recseq is not null
       BEGIN	--LOOP A
       
         declare Upload_curs cursor local fast_forward for
		 select d.TableName, d.ColumnName, e.UploadVal, e.Identifier, e.ImportId
         from IMWE e with (nolock)
         inner join DDUD d with (nolock) on d.Identifier = e.Identifier and d.Form = e.Form
         where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and e.RecordSeq = @recseq
			UNION ALL
		 select d.TableName, d.ColumnName, e.UploadVal, e.Identifier, e.ImportId
         from IMWENotes e with (nolock)
         inner join DDUD d with (nolock) on d.Identifier = e.Identifier and d.Form = e.Form
         where e.ImportId = @importid and e.ImportTemplate = @template and e.Form = @form and e.RecordSeq = @recseq
		 Order by e.Identifier;
       
         select @UploadCursorUsed = 1
       
         open Upload_curs
       
         select @openuploadcursor = 1
     
         fetch next from Upload_curs into @tablename, @column, @uploadval, @ident, @importid
        
         while @ident is not null
         BEGIN 	--LOOP B
		set @coltype = ''
		select @coltype = ColType from DDUD with (nolock) where Form = @form and Identifier = @ident

       	if upper(@column) = 'SEQ' AND @tablename not in ('PRAE','PMSubmittal') select @uploadval = @recseq 
       
           if @uploadval <> '' and @uploadval is not null
        	Begin
       		--Catch fields with embedded single quotes...
       		if CHARINDEX(char(@quote),@uploadval) > 0
       		begin
       			--replace single quotes with single back-quotes
       			SELECT @uploadval = REPLACE(@uploadval, char(@quote), '`')
       		end
        
             --Varchar, Char, and Smalldatetime data types need to be encapsulated in '''
             if @coltype = 'varchar' or @coltype = 'text'
       			select @uploadval = char(@quote) + @uploadval + char(@quote)
        
             if @coltype = 'char' select @uploadval = char(@quote) + @uploadval + char(@quote)
       
       	  --Check numeric types for validity
       	  if @coltype IN ('bigint','int','smallint','tinyint','decimal','numeric','money','smallmoney','float','real')
       	  begin
			set @uploadval = replace(@uploadval, ',', '') --added for issue #127127 CC
       		if isnumeric(@uploadval) <> 1 --if not numeric
       		begin
       			select @rcode = 1, @errmsg = 'Non-numeric value found in numeric field (' + convert(varchar(10),@ident) + ').'
       	        update IMWE
       		  	set UploadVal = '*VALUE NOT NUMERIC*'
                 	where ImportId = @importid and ImportTemplate = @template and Identifier = @ident and RecordSeq = @recseq
       
       	        Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Message)
       	        values (@importid, @template, @form, @recseq, @ident, @errmsg)
       
       			goto NextReqSeq
       		end
       	  end
       
       	  if @coltype = 'smalldatetime' 
       	  Begin
       		if @column = 'Mth'
       		begin
       		  select @month_col = @column
       		  select @mth = ltrim(@uploadval)	
       		end
       		select @uploadval = char(@quote) + ltrim(@uploadval) + char(@quote)
       	  end
         									   
       		--build column list
       		if @columnlist is not null 
       			select @columnlist = @columnlist + ',' + @column 
       		else 
       			select @columnlist = @column
       
       		--build values list
       		if @valuelist is not null 
       			select @valuelist = @valuelist + ',' + @uploadval 
       		else 
       			select @valuelist = @uploadval
       	
       		--update keys and values for updates
      -- 		if @updateyn = 'Y'
      -- 		begin
       			update #tblUpdateKeys set UpdVal = @uploadval
       			where UpdCol = @column
       
       			update #tblUpdateValues set UpdVal = @uploadval
       			where UpdCol = @column
      -- 		end
       
       	End
       	Else 
       	Begin  
  	   		--check for nullability
   	   		select @allownull = COLUMNPROPERTY( OBJECT_ID(@tablename),@column,'AllowsNull')

    		--#25668, do not fail on non-nullable, non-key, non-updated fields if update only.
    		if @insertyn = 'Y' or (@updateyn = 'Y' and (exists(select * from #tblUpdateKeys where UpdCol = @column) 
    								or exists(select * from #tblUpdateValues where UpdCol = @column)))
    		begin
    	    
    	   		--if nulls not allowed - isnull added for #24402
    	   	   	if @allownull = 0 and isnull(@uploadval,'') = '' 
    	   	      begin  
    	   			  select @rcode = 1, @errmsg = 'Missing required value (' + convert(varchar(10),@ident) + ').'
    	   	          --Write back to IMWE
    	   		      update IMWE
    	   			  set UploadVal = '*MISSING REQUIRED VALUE*'
    	   	          where ImportId = @importid and ImportTemplate = @template and Identifier = @ident and RecordSeq = @recseq
    	
    					Update IMWM
    					Set Message = @errmsg
    					where ImportId = @importid and ImportTemplate = @template and Form = @form and RecordSeq = @recseq
    					
    					if @@rowcount <> 1
    					begin
    					 Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Identifier, Error, Message)
    					 values (@importid, @template, @form, @recseq, @ident, @errcode, @errmsg)
    				  	end
    	   	
    	   	          --dump this record seq.  go onto next one	
    	   			  goto NextReqSeq
    	   	      end
    		end 
			--if column allows nulls and upload val is empty or column doesn't allow nulls and upload val is null, and it's a text column, make the upload val empty
			if ((@allownull = 1 and @uploadval = '') or (@allownull = 0 and @uploadval is null) )and (@coltype = 'varchar' or @coltype = 'text' or @coltype = 'char') 
				select @uploadval = char(@quote) + char(@quote)
			
    		update #tblUpdateKeys set UpdVal = @uploadval
    		where UpdCol = @column
    
    		update #tblUpdateValues set UpdVal = @uploadval
    		where UpdCol = @column
    
       	  End
       
 			--Issue #19580
 			if @UpdTable is null and @tablename is not null
       			select @UpdTable = @tablename

             fetch next from Upload_curs into @tablename, @column, @uploadval, @ident, @importid
       	  if @@fetch_status <> 0 select @ident = null
           END		--LOOP B
       
         --@ident is now null (we've gone through all identifiers for this row...do insert or update
       --Determine whether record exists and is to be updated, or does not exist and must be inserted.
       --use update keys to check need for update
         DECLARE UpdateKeys CURSOR FAST_FORWARD FOR
       	select UpdCol, UpdVal from #tblUpdateKeys
       
         OPEN UpdateKeys
         FETCH NEXT FROM UpdateKeys INTO @UpdCol, @UpdVal
         if @@fetch_status = 0
         begin
       	while @@fetch_status = 0
       	begin
       		if @CheckExistingStmt is null 
       			select @CheckExistingStmt = 'select 1 from ' + @UpdTable + ' with (nolock) where ' + @UpdCol + ' = ' + @UpdVal
       		else
       			select @CheckExistingStmt = @CheckExistingStmt + ' and ' + @UpdCol + ' = ' + @UpdVal
      
       		FETCH NEXT FROM UpdateKeys INTO @UpdCol, @UpdVal
       	end
         end
         CLOSE UpdateKeys
         deallocate UpdateKeys
         exec(@CheckExistingStmt)
         select @ExistRecs = @@rowcount
         select @errcode = 0
      
         if @ExistRecs > 0 and @updateyn = 'Y'
         begin

       	--create update statement
       	--update flagged fields in IMTD
           DECLARE UpdateValues CURSOR FAST_FORWARD FOR
       		select UpdCol, UpdVal from #tblUpdateValues
       
       	OPEN UpdateValues
   
       	FETCH NEXT FROM UpdateValues INTO @UpdCol, @UpdVal
       	if @@fetch_status = 0
       	begin
  	
       		while @@fetch_status = 0
       		begin
       			if @updatestmt is null
       				select @updatestmt = 'Update ' + @UpdTable + ' set ' + @UpdCol + ' = ' + isnull(@UpdVal,'null')
       			else
       				select @updatestmt = @updatestmt + ', ' + @UpdCol + ' = ' + isnull(@UpdVal,'null')
       
       			fetch next from UpdateValues into @UpdCol, @UpdVal
       		end
       
       		DECLARE UpdateKeys CURSOR FAST_FORWARD FOR
       			select UpdCol, UpdVal from #tblUpdateKeys
       
       		OPEN UpdateKeys
       		FETCH NEXT FROM UpdateKeys INTO @UpdCol, @UpdVal
       		if @@fetch_status = 0
       		begin
       			while @@fetch_status = 0
       			begin
       				if @whereclause is null
       					select @whereclause = 'Where ' + @UpdCol + ' = ' + @UpdVal
       				else
       					select @whereclause = @whereclause + ' and ' + @UpdCol + ' = ' + @UpdVal
       				
       				fetch next from UpdateKeys into @UpdCol, @UpdVal	
       			end
       		end
       		CLOSE UpdateKeys
       		DEALLOCATE UpdateKeys
       		select @updatestmt = @updatestmt + ' ' + @whereclause
       		--save statement in case of error
       		delete from IMWM where ImportId = @importid and Error = 9999
       		insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
       		values (@importid, @template, @form, @recseq, 9999, @updatestmt)

				select @errcode = 0
		    
			  begin try
       			--Execute Update Statement
       			exec(@updatestmt)
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
       	end
       	CLOSE UpdateValues
       	deallocate UpdateValues
         end
         else if @insertyn = 'Y' and @ExistRecs = 0
         begin
         	select @insertstmt = 'Insert ' + @UpdTable + ' (' + @columnlist + ') values (' +  @valuelist + ')'
       	--save statement in case of error
       	delete from IMWM where ImportId = @importid and Error = 9999
       	insert into IMWM(ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
       	values (@importid, @template, @form, @recseq, 9999, @insertstmt)

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
         end
       
			   --Delete Record from IMWE
		  if @errcode = 0
		  begin
			delete IMWE where ImportId = @importid and ImportTemplate = @template and RecordSeq = @recseq
			delete IMWENotes where ImportId = @importid and ImportTemplate = @template and RecordSeq = @recseq
		  end
 /* 
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
       
         NextReqSeq:
         select @columnlist = null, @valuelist = null, @insertstmt = null
         select @updatestmt = null, @whereclause = null, @CheckExistingStmt = null
       
         close Upload_curs
         deallocate Upload_curs
         select @openuploadcursor = 0, @UploadCursorUsed = 0
       
         select @recseq = null
         fetch next from RecSeq_curs into @recseq
         if @@fetch_status <> 0 select @recseq = null
       
       END		--LOOP A
       
       close RecSeq_curs
       deallocate RecSeq_curs
       select @openrecseqcursor = 0, @RecSeqCursorUsed = 0
       
       --remove any remaining statements (so only fatal errors leave 9999 messages)
       delete from IMWM where ImportId = @importid and Error = 9999
       
       bspexit:
       
       if @openuploadcursor = 1
       	close Upload_curs
       if @UploadCursorUsed = 1
       	deallocate Upload_curs
       
       if @openrecseqcursor = 1
       	close RecSeq_curs 
       if @RecSeqCursorUsed = 1
       	deallocate RecSeq_curs
       
       if @ANSIWARN = 1
       	SET ANSI_WARNINGS ON
       
       return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspIMUploadDirect] TO [public]
GO
