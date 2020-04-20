SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspUDAlterTable]
     /************************************************
     	Created 03/09/01 RM
      Modified: 
      	RM 02/06/03 -  Issue#19874 - Added code for UseNotes in UD Tables
    	RM 03/31/03 - Issue#??  - Changed @dropstring from varchar(50) to varchar(255) to allow longer tablenames.
    	RM 04/29/03 - Issue#16329 - Code to allow decimals based on the input mask
   		RM 08/12/03 - Issue#22122 - Make notes column nullable.
    	RM 10/21/03 - Issue#22787 - Make InputType=5 behave as InputType=0 when creating table
   		RM 10/30/03 - Issue#22809 - Invalid msg when @inputmask is null and @prec = 0,1 or 2
   		DANF 03/11/04 Issue#20536 - Update Data Type Security Entries
   		RM 05/02/05 - Issue#26710 - Include Co in index when company based
   					    InputType - Text, InputLength - 0 was erroring.  Default 1000 when 0.
   		DANF 09/01/05 - Expand column name to 50 characters
		TIMP 07/18/07 - Added WITH EXECUTE AS 'viewpointcs'
		TIMP 08/09/07 - Changed to vspUDAlterTable
		TIMP 08/10/07 - Update Data Type Security Entries to use vDDFIc tables
						removed bUDCA table insert/delete
		TIMP 12/11/07 - Issue#125965 - #12 in issue - Made bYN DEFAULT 'N' NOT NULL
						TIMP 12/14/07 - Issue #122074 - Added or @decpos is null to make sure Decimal Position is not Null
        RM   01/03/08 - Issue#126618 - Exclude KeyID from drop code
		RM   01/04/08 - Issue#126645 - change @datatype and @olddatatype from varchar(15) to varchar(20)
		RM   01/17/08 - Issue#126783 - Several changes to contraint handling for bYN
        George Clingerman 03/06/2008 - Issue #121238 Change stored procedure to not allow 
									   the table to be altered if it would become a key only table.
									 - Moved the tablename check to below the cursor creation and the
                                     - transactioncount initialization so errors do not occur on exit
		CC	 05/01/08 - Issue #128017 - Check if bYN column is null, if it is, update null values to 'N' and then make column not null
		RM   02/06/09 - Issue #131327 - Added bigint precision
		CC	 05/26/09 - Issue #129627 - Added call to [vspUDUpdateAuditTriggers] to update auditing on UD table
		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
		JA - 11/9/2012 - TK-14366 - change usenotes to usenotestab (allows formatted notes tab on UD forms)
		
     	Usage: Used to alter a UD Table
     
     
     ************************************************/
     (@tablename varchar(30),@errmsg varchar(255) output)
     WITH EXECUTE AS 'viewpointcs'
     AS

	 declare @rcode int,@alterstring varchar(500),@keystring varchar(500),@dropstring varchar(255),@btablename varchar(21),@appost varchar(30),@char39 char(1)
     
     declare @numerictype varchar(30),@leftofdecimal int,@rightofdecimal int,@decpos int,@errstart varchar(100),@oldprec int, @oldscale int
     
     select @rcode = 0, @btablename = 'b' + @tablename,@char39 = char(39),@appost = char(39) +  ' + ' + char(39) + 'char(39)' + char(39) + ' + ' + char(39)
     
     declare @columnname varchar(50),@keyseq int,@datatype varchar(20),@inputtype int,@inputmask varchar(15),
     	@inputlength int,@prec int,@systemdatatype varchar(50),@syscolumnname varchar(50),@usenotestab int
     declare @begintrancount int, @InUse bYN, @formname varchar(30), @olddatatype varchar(20), @companybased bYN
   

     select @usenotestab=UseNotesTab,@formname=FormName, @companybased=CompanyBasedYN from bUDTH where TableName=@tablename
     
     declare @alteropen int, @keyopen int, @dropopen int 
   
     declare altercursor  cursor for
     select ColumnName,KeySeq,DataType,InputType,InputMask,InputLength,Prec from bUDTC
     where TableName = @tablename and ColumnName not in ('Notes','UniqueAttchID')
     order by DDFISeq
     
     declare keycursor cursor for
     select ColumnName from bUDTC
     where TableName = @tablename and KeySeq is not null
     order by KeySeq
     
     declare dropcursor cursor for
     select name from syscolumns
     where id = object_id(@btablename)
     and name not in ('Notes','UniqueAttchID','KeyID')
     
     --Initialize the transaction count, if this number does not equal the transcount
  --when bspexit is hit, then a rollback occurs
     select @begintrancount = @@trancount    

     --Check to see if a tablename has been passed into the stored procedure. The table name is
     --used in the above queries, but this check cannot be done until after the cursor objects
     --have been created and the begintrancount variable has been filled since these objects
     --are used in the bspexit
     if @tablename is null
     begin
     	select @rcode = 1, @errmsg = 'Table Name Missing!'
     	goto bspexit
     end     

	 --Check to see if the table is being altered so that it would create a key-only table
	 if not exists(select * from bUDTC where TableName = @tablename and KeySeq is  null)
	 begin
		select @rcode = 1, @errmsg = 'Cannot update table to be a key-only table.'
		goto bspexit
	 end
     
     begin tran
     if exists(select * from sys.indexes where name = 'bi' + @tablename and object_id = object_id(@btablename))
     begin
     	select @dropstring = 'drop index ' + @btablename + '.bi' + @tablename

     	exec(@dropstring)
     end

     open altercursor
     select @alteropen = 1
   
     fetch next from altercursor into
     @columnname,@keyseq,@datatype,@inputtype,@inputmask,@inputlength,@prec
     
     while @@fetch_status = 0
     begin
     
     select @columnname = replace(@columnname,@char39,@appost)
     
     	select @systemdatatype = null
     
     	
     if @datatype is not null
     	exec @rcode =  vspDDDTGetDatatypeInfo @datatype, @inputtype output, @inputmask output,@inputlength output, @prec output, @systemdatatype output, @errmsg output
     
       select @InUse = isnull(InUse,'N') from dbo.DDSL with (nolock)
     	where TableName=@btablename and Datatype=@systemdatatype and InstanceColumn=@columnname
     
     	if isnull(@systemdatatype,'')= ''
     	begin
     
   		select @errstart='Column: ' + @columnname + char(13) + char(11)
   
   		if @inputtype = 1
   		begin
   			--strip out the positioning characters and other characters
   			select @inputmask=replace(replace(@inputmask,'R',''),'L','')
   			select @inputmask=replace(@inputmask,',','')
   
   			if @prec=3--numeric
   			begin
   				select @decpos = charindex('.',@inputmask,1)
   				if @decpos = 0 or @decpos is null
   				begin
   					select @errmsg='Cannot have Numeric precision unless mask has a decimal.',@rcode=1
   					goto bspexit
   				end
   				select @leftofdecimal=@decpos-1
   				select @rightofdecimal=len(@inputmask)-@leftofdecimal-1
   	
   				select @oldprec=prec, @oldscale=scale from syscolumns where name=@columnname and id=object_id(@tablename)
   				
   				if @oldprec is not null and @oldscale is not null
   				begin
   					if @leftofdecimal < @oldprec - @oldscale
   					begin
   						select @errmsg = 'Invalid Mask.  Number of characters to the left of the decimal must be at least ' + convert(varchar(10),@oldprec - @oldscale) + '.' + ' ' + @columnname,@rcode=1
   						
   						goto bspexit
   					end
   				end --@oldprec/@oldscale not null
   
   				select @numerictype='numeric(' + convert(varchar(5),@leftofdecimal + @rightofdecimal) + ',' + convert(varchar(5),@rightofdecimal) + ')'
   			end --prec=3
   			else
   			begin
   				select @decpos = isnull(charindex('.',@inputmask,1),0)
   				if @decpos <> 0
   				begin
   					select @errmsg= 'Mask may not include a decimal unless the precision is numeric.',@rcode=1
   					goto bspexit
   				end --decpos<>0
   			end --@prec=3
   		end --@inputtype=1
   
     		select @alterstring =   '[' + @columnname + '] ' + convert(varchar(30),case 
   																				when @inputtype in (0,5) then 'varchar(' +  convert(varchar(10),case isnull(@inputlength,30) when 0 then 1000 else isnull(@inputlength,30) end)   + ')'
   																				when @inputtype =1 then (case @prec 
   																								when 0 then 'tinyint' 
   																								when 1 then 'smallint' 
   																								when 2 then 'int' 
   																								when 3 then @numerictype 
   																								when 4 then 'bigint' end)end)
    										 + (case isnull(@keyseq,'') when '' then ' null' else ' not null' end)
     	end
     	else
     	begin
     		if @systemdatatype = 'bYN'
				begin
					select @alterstring =  '[' +  @columnname + '] ' + @systemdatatype + ' not null'
				end
			else
	      		select @alterstring =  '[' +  @columnname + '] ' + @systemdatatype + case isnull(@keyseq,'') when '' then ' null' else ' not null' end
		end
     
     	if exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME = @columnname and TABLE_NAME = @btablename)
     	begin
				
				EXEC	@rcode = [dbo].[vspUDDropColumnConstraints]
						@btablename,
						@columnname ,
						@errmsg = @errmsg OUTPUT

				if(@rcode <> 0)
					goto bspexit
				IF ISNULL(@systemdatatype,'') <> 'bYN'
					SELECT @alterstring = ' Alter table ' + @btablename + ' alter column ' + @alterstring			
				ELSE
					IF (SELECT IS_NULLABLE FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @columnname AND TABLE_NAME = @btablename) = 'YES'
						SELECT @alterstring = 'UPDATE ' + QUOTENAME(@btablename) + ' SET ' + @columnname + ' = ''N'' WHERE ' + @columnname + ' IS NULL;  ' +  ' Alter table ' + QUOTENAME(@btablename) + ' alter column ' + @alterstring + '; Alter table ' + QUOTENAME(@btablename) + ' ADD CONSTRAINT [DF_' + @tablename +  '_' + @columnname + '] DEFAULT (''N'') FOR [' + @columnname + ']; '		
					ELSE
						SELECT @alterstring = ' Alter table ' + QUOTENAME(@btablename) + ' alter column ' + @alterstring + '; Alter table ' + QUOTENAME(@btablename) + ' ADD CONSTRAINT [DF_' + @tablename +  '_' + @columnname + '] DEFAULT (''N'') FOR [' + @columnname + ']; '

								
		end
     	else
     	begin
     		select @alterstring = 'Alter table ' + @btablename + ' add ' + @alterstring

			if @systemdatatype = 'bYN'
				select @alterstring = @alterstring + ' CONSTRAINT [DF_' + @tablename +  '_' + @columnname + '] DEFAULT (''N'')'
     	end
  
   	select @olddatatype=Datatype
   	from vDDFIc with (nolock)
   	where @tablename=ViewName and ColumnName=@columnname
     
   	If isnull(@olddatatype,'')<> ''
   		begin
   		-- Delete old DDSL entry
   		    exec @rcode = dbo.vspDDSLUserColumn @btablename, @olddatatype, @columnname, null, 'Deletion', @errmsg output
   		      if @rcode <> 0
   		      begin
   		      select @errmsg='Error Deleting User Data Column ' + @columnname + ' from the Security Links Table. ', @rcode = 1
   		      end
   		end
     	exec(@alterstring)
     
   	if isnull(@datatype,'')<> ''
   		begin
   			  exec @rcode = dbo.vspDDSLUserColumn @btablename, @datatype, @columnname, @formname, 'Addition', @errmsg output
  			      if @rcode <> 0
   			      begin
   			      select @errmsg='Error Adding User Data Column ' + @columnname + ' to the Security Links Table. ', @rcode = 1
   			      end
   		
   			  -- reset in use by flag as column may have been deleted and them readded	
   			  If @InUse = 'Y'
   				begin
   			    	Update  dbo.DDSL 
   					 Set InUse = @InUse
   		  			where TableName=@btablename and Datatype=@datatype and InstanceColumn=@columnname
   				end
   		end
   
     	fetch next from altercursor into
     	@columnname,@keyseq,@datatype,@inputtype,@inputmask,@inputlength,@prec
     end
     
     close altercursor
     select @alteropen = 0
     
     open dropcursor
     select @dropopen = 1
   
     fetch next from dropcursor into @syscolumnname
     while @@Fetch_Status = 0
     begin
     
     	if not exists(select * from bUDTC where ColumnName = @syscolumnname and TableName = @tablename)
     	begin
     		if @syscolumnname <> 'Co'
     		begin
   
   			-- Use old data type from vDDFIc
   			select @datatype=Datatype
   			from dbo.vDDFIc with (nolock)
   			where ViewName = @tablename and ColumnName = @syscolumnname
   
   			if isnull(@datatype,'') <> ''
   				begin
   					-- Delete old DDSL entry
   				    exec @rcode = dbo.vspDDSLUserColumn @btablename, @datatype, @syscolumnname, null, 'Deletion', @errmsg output
   				      if @rcode <> 0
   				      begin
   				      select @errmsg='Error Deleting User Data Column ' + @columnname + ' from the Security Links Table. ', @rcode = 1
   				      end
   				end
				
				EXEC	@rcode = [dbo].[vspUDDropColumnConstraints]
						@btablename,
						@syscolumnname ,
						@errmsg = @errmsg OUTPUT

				if(@rcode <> 0)
					goto bspexit
 
     			select @alterstring = ' alter table [' + @btablename + '] drop column [' + @syscolumnname + ']'
			
				exec(@alterstring)
     		end
     	end
     fetch next from dropcursor into @syscolumnname
     end
     
     close dropcursor
     select @dropopen = 0
     
     --Add formatted notes tab if needed.
     if not exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='Notes' and TABLE_NAME=@btablename) and @usenotestab=2
     	begin
     		select @alterstring = 'alter table [' + @btablename + '] add Notes VARCHAR(MAX) null'
			exec(@alterstring)
     	end	
     	         
     --Add standard notes tab if needed.
     if not exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='Notes' and TABLE_NAME=@btablename) and @usenotestab=1
     	begin
     		select @alterstring = 'alter table [' + @btablename + '] add Notes VARCHAR(MAX) null'
			exec(@alterstring)
     	end	
     	
     --Drop Notes if needed.
     if  exists(select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='Notes' and TABLE_NAME=@btablename) and @usenotestab=0
     	begin
     		select @alterstring = 'alter table [' + @btablename + '] drop column Notes '
			exec(@alterstring)
     	end	
     
    --If Table is CompanyBased then we need to have Co in the keystring so that
    --the index gets built correctly
     if @companybased='Y'
   	select @keystring = 'Co'
     
     open keycursor
     select keyopen = 1
   
     fetch next from keycursor into @columnname
     while @@fetch_status = 0
     begin
     	if @keystring is not null
     	select @keystring = @keystring + ', '
     
     	select @keystring = isnull(@keystring,'') + '[' + @columnname + ']'
     
     	fetch next from keycursor into @columnname
     end
     
     close keycursor
     select keyopen = 0
     
     --Build the index string
     if @keystring is not null
     select @keystring = 'Create unique clustered index bi' + @tablename + ' on ' + @btablename + '(' + @keystring + ')'
     exec(@keystring)
     
     --Create/Alter view
     exec @rcode = vspVAViewGen @tablename,@btablename, @errmsg output
     if @rcode = 1
     begin
     	select @errmsg = @errmsg + ' - error creating view'
     	goto bspexit
     end
     
     commit tran
     
     bspexit:
     
     if @alteropen=1
   		close altercursor
     if @keyopen=1
   		close keycursor
     if @dropopen=1
   		close dropcursor
   
   	deallocate altercursor
   	deallocate keycursor
   	deallocate dropcursor
   
	DECLARE @AuditTable		bYN
	
	SELECT @AuditTable = AuditTable
	FROM UDTH
	WHERE TableName = @tablename
	
	EXEC dbo.vspUDUpdateAuditTriggers @tablename, @AuditTable
   
   	if @@trancount <> @begintrancount
   		if @rcode=1
   			rollback tran
   		else
   			commit tran
   
     return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspUDAlterTable] TO [public]
GO
