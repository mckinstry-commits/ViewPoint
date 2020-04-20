SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVACompanyCopyTableCopy]
  /***********************************************************
   * CREATED BY: MV 06/11/07
   * MODIFIED By :	CC 3/18/2009 Issue#127519 - Update to use SQL 2005 views and use metadata for company/group column and whether to copy table
   *				AL 10/27/2009 Issue #135916 - Expanded ColumnName to 30 characters
   *				CC 10/19/2010 Issue #140575 - Move trigger enable to the exit procedure to ensure call even in error
   *				CG 12/03/2010 Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
   * USAGE:
   * called from frmVACompanyCopyforServer to copy tables
   * 
   * INPUT PARAMETERS
   *   @tablename - table to be copied   
   *   @SourceCo - the company value of the table being copied from  
   *   @SourceCombo - server/database of the source table
   *   @DestCo - the company value of the table being copied to
   *   @zeroINMTyn - if table is bINMT and flag is Y set value to 0 
   *
   * OUTPUT PARAMETERS
   *    @msg If Error, error message otherwise table copy info
   *
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@tablename varchar(128),@SourceCo int, @SourceCombo varchar(100),@DestCo int, @zeroINMTyn bYN, @msg varchar(1000)=null output)
  WITH EXECUTE AS 'viewpointcs' 
  AS
  
  set nocount on
    
declare @rcode int,@coltype varchar(20), @colname varchar(128),@SqlCopyString varchar(max),
	@insertstring varchar(max),@selectstring varchar(max), @whereclause varchar(max),@opencursor int,@notexists varchar(max),
	@commastring varchar(100),@colid integer, @inkey integer,@xprec int,@keycnt int,
	@rowscopied bigint,@beforecount bigint,@aftercount int,@countwhere varchar(max),@errnumber int,@errmsg varchar(500),
	@grouptype varchar(20),@isnullable integer,@nullstringnumdate varchar(20),@sqlstring varchar(max),@IsFirstColumn bYN
	,@CompanyColumn varchar(128)
	
--table variable to hold column info for table being copied
declare @table TABLE(ColumnName varchar(128),TypeName varchar(25),ColId int,InKey int,IsNullable int,xprec int)
-- table variable to hold the record counts before and after the table copy
declare @tablecount TABLE(TableCount int)
select @rcode = 0, @IsFirstColumn = 'Y', @insertstring = '',@selectstring='',@whereclause='',@notexists=''
 BEGIN TRY
   ------ list of columns in table should be replaced by views --------
select @sqlstring = 
'select  c.name AS ColumnName, isnull(t.name,'''') AS TypeName, c.column_id AS ColId, 
        Count(k.index_id) AS InKey,c.is_nullable AS IsNullAble,c.precision
        from sys.columns c 
        join sys.types t on c.user_type_id=t.user_type_id
        join sys.objects o on o.object_id=c.object_id
        left join sys.indexes i on i.object_id=c.object_id and (i.type_desc = ''CLUSTERED'' or i.is_primary_key = 1)
        left join sys.index_columns k on i.object_id=k.object_id and i.index_id=k.index_id and k.is_included_column = 0 AND c.column_id = k.column_id
		and k.is_included_column = 0
		where o.name = ''' + rtrim(@tablename) + ''' 
		group by o.name, c.name, t.name, c.column_id, c.is_nullable,c.precision
        order by	case 
						when c.name=''Qualifier'' then 0 
						when o.name=''bPMTD'' and c.name=''PMCo'' then 0 
						else c.column_id
					end'
					
 -- return result into table variable
 insert into @table exec (@sqlstring)
 -- check if there are rows
 if @@rowcount = 0
	begin
	select @msg = rtrim(@tablename) + ' is not on file.',@rcode=5 --exit to get next table, return conditional error
	goto vspexit
	end 
END TRY
BEGIN CATCH
    SELECT 
        @errnumber = ERROR_NUMBER(),
        @errmsg = ERROR_MESSAGE();
		--select @msg = 'Error Number: ' + convert(varchar(5),@errnumber) + ' Error Message: ' + @errmsg ,@rcode=1
		select @msg = @sqlstring, @rcode=1
		goto vspexit
END CATCH

select @CompanyColumn = CoColumn from DDTables where TableName = rtrim(@tablename) and CopyTable = 'Y'

-- open cursor on @table
 declare vcTable cursor for
    select ColumnName,TypeName,ColId,InKey,IsNullable,xprec
    from @table
    /* open cursor */ 
    open vcTable
    select @opencursor = 1

	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @tablename, @identityColumn output

    vcTable_loop:
    	fetch next from vcTable into @colname,@coltype,@colid,@inkey,@isnullable,@xprec
		if @@fetch_status = -1 goto vcTable_end
		--skip identity columns
				
		if @colname = @identityColumn goto vcTable_loop
		---determine if this is a valid table with a company 
		--- changed DD tables to vDD and removed DDDI as it is no longer used - danf
		if @tablename in ('vDDDS','vDDDU','bPMTD')
		begin
			if @colname = 'Qualifier' or @colname = 'PMCo'
				begin
				select @colid = 1,@coltype = 'bCompany'
				end
			if @colname ='Datatype' or @colname = 'CostType'
				begin
				select @colid = 2
				end
		end
		--for first column only
		if @IsFirstColumn = 'Y'
			begin
			--- valid company? 
			if @colid = 1 and @tablename in ('bHQCX', 'bJCCT', 'bJCPM', 'bJCPC') select @coltype = 'bGroup' --1st col is group but not bGroup type
			if not exists(select 1 from DDTables where TableName = rtrim(@tablename) and CopyTable = 'Y')
			begin
				select @msg = 'Skipping ' + rtrim(@tablename) + ', it is not flagged to copy.',@rcode=5 --exit to get next table, return conditional error
				goto vspexit	
			end
			--begin formatting the insert statements
			select @insertstring = 'INSERT INTO ' + rtrim(@tablename) + '(' + @colname 
			select @selectstring = 'SELECT '
			select @commastring = ''
			end
		else
			begin
			select @insertstring = @insertstring + @commastring + @colname 
			-- put in a line break
			if @keycnt >= 10 and @keycnt%10 = 0 
				begin
				select @insertstring = @insertstring + char(10)
				end
			end

		if @isnullable <> 0
		begin
		-- @nullstringnumdate is used to determine if statement should be isnull(col,'') or isnull(col,0) or isnull(col,'1/1/1970')
		select @nullstringnumdate = ''
		if @xprec = 0 select @nullstringnumdate = '=''''' --not a numeric field
		if @coltype in ('smalldatetime','datetime','bDate','bMonth')
			begin
			select @nullstringnumdate = '''01/01/1970'''
			end
		else
			begin
			select @nullstringnumdate = '''0'''
			end
		end

		--Group Fields - since the bGroup was not used consistently, need to figure out group by col name
		select @grouptype = ''

		if @coltype = 'bGroup' select @coltype = 'tinyint' 
		-- check for inconsistencies in db not using correct datatype ------
		if @coltype in('tinyint','smallint','int')
		begin
		select @grouptype=''
		if UPPER(@colname) in ('PHASEGROUP','PHASEGRP','OLDPHASEGROUP','OLDPHASEGRP','JCPHASEGROUP') select @grouptype='PhaseGroup', @coltype='bGroup'
		if UPPER(@colname) in ('APVENDORGROUP','VENDORGRP','VENDORGROUP','OLDVENDORGRP','OLDVENDORGROUP') select @grouptype='VendorGroup', @coltype='bGroup'
		if UPPER(@colname) in ('EMGROUP','OLDEMGROUP','REVUSEDONEQUIPGROUP','OLDREVUSEDONEQUIPGROUP','USEDONEQUIPGROUP','USEDONEQUIPGROUP') select @grouptype='EMGroup', @coltype='bGroup'
		if UPPER(@colname) in ('MATERIALGROUP','MATLGROUP','OLDMATLGROUP','MIMATERIALGROUP') select @grouptype='MatlGroup', @coltype='bGroup'
		if UPPER(@colname) in ('CUSTGROUP','OLDCUSTGROUP') select @grouptype='CustGroup', @coltype='bGroup'
		if UPPER(@colname) in ('TAXGROUP','OLDTAXGROUP') select @grouptype='TaxGroup', @coltype='bGroup'
		if UPPER(@colname) in ('SHOPGROUP','OLDSHOPGROUP') select @grouptype='ShopGroup', @coltype='bGroup'
		end
		
		if @colname = @CompanyColumn--@colid=1 is always the first column
	
			begin
				--set the whereclause and wherecount 
				if @grouptype <> '' 
					begin
					select @whereclause = 'WHERE ' + @colname + ' = (select ' + @grouptype + ' from ' + @SourceCombo +
					 'HQCO where HQCo=' + convert(varchar(3),@SourceCo) + ')'
					select @countwhere = 'WHERE ' + @colname + ' = (select ' + @grouptype + ' from  HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
					select @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +
					 @colname + '=' + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
					end
				else 
					begin
					select @whereclause = 'WHERE ' + @colname + ' = ' + convert(varchar(3),@SourceCo)
					select @countwhere = 'WHERE ' + @colname + ' = ' + convert(varchar(3),@DestCo)
					select @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +
					 @colname + '=' + convert(varchar(3),@DestCo)+ ')'
					end
			end
		-- set select string  
		if @coltype in ('bCompany','bGroup')
			begin
			if @grouptype = ''
				begin
				select @selectstring = @selectstring + @commastring + convert(varchar(3),@DestCo) 
				end
			else
				begin
				select @selectstring = @selectstring + @commastring + ' case when ' + @colname + ' is null then null else '
				select @selectstring = @selectstring + '(select ' + @grouptype + ' from HQCO where HQCo= ' + convert(varchar(3),@DestCo) + ') end'
				end
			end
		else
			if rtrim(@tablename) = 'bINMT' and @zeroINMTyn='Y' and @colname in ('OnHand','RecvdNInvcd','OnOrder') 
				begin
				select @selectstring = @selectstring + @commastring + '0'
				end
			else
				begin
				select @selectstring = @selectstring + @commastring + @colname
				end

		-- put in a line break
		if @keycnt >= 10 and @keycnt%10 = 0 
			begin
			select @selectstring = @selectstring + char(10) 
			end

		-- set notexists string
		if @colname = @CompanyColumn -- Is the first Column in the table
			begin
			if @grouptype <> '' -- Is a Group Type Column
				begin
				select @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +
				 @colname + '=' + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')' 
				end
			else  -- Is not a Group Type Column
				begin
				select @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +
				 @colname + '=' + convert(varchar(3),@DestCo)
				end
			end
		else
			if @inkey > 0 and @colname not in('SortName','UniqueAttchID',@identityColumn) --Is not the 1st column but is a key column
			begin
				if @coltype <> 'bCompany'
				begin
					if @isnullable <> 0  -- Can be null
						begin
						select @notexists = @notexists + ' and isnull(b.' + @colname + ',' + @nullstringnumdate + ')='
						end
					else	-- Cannot be null
						begin
						select @notexists = @notexists + ' and b.' + @colname + '='
						end
					if @grouptype <> '' -- Is a Group Type Column
						begin
						if @isnullable <> 0 --Can be null
							begin
							select @notexists = @notexists + '(select '+ 'isnull(' + @tablename + '.' + @colname + ',' + @nullstringnumdate + ')' +
								 ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
							end
						else -- Cannot be null
							begin
							select @notexists = @notexists + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
							end
						end
					else -- Is not a Group Type Column
						begin
						if @isnullable <> 0  -- Can be null
							begin
							select @notexists = @notexists + 'isnull(' + @tablename + '.' + @colname + ',' + @nullstringnumdate + ')'
							end
						else -- Cannot be null
							begin
							select @notexists = @notexists + @tablename + '.' + @colname
							end
						end
				end
			end
			
		if @IsFirstColumn = 'Y' 
			begin
			select @IsFirstColumn = 'N'
			select @commastring = ','
			end

		--get next column
		select @keycnt = @keycnt + 1
		goto vcTable_loop

	vcTable_end:
		close vcTable
        deallocate vcTable
        select @opencursor = 0
		
		-- Put the SQL statement together
		select @SqlCopyString = @insertstring + ')' + char(10) + @selectstring + char(10) + ' FROM ' + @SourceCombo +
		 @tablename + ' ' + char(10) + @whereclause + ' ' + char(10) + @notexists + ')'
		
		--count records before copy
		select @sqlstring = 'select count(1) from ' + @tablename + ' b ' + @countwhere
		BEGIN TRY
			delete from @tablecount
			insert into @tablecount exec (@sqlstring)
			select @beforecount = TableCount from @tablecount
		END TRY
		BEGIN CATCH
			SELECT 
				@errnumber = ERROR_NUMBER(),
				@errmsg = ERROR_MESSAGE();
				select @msg = 'Err doing count before copy, Err Msg: ' + @errmsg,@rcode=1
				goto vspexit
		END CATCH

		--disable triggers
		if @tablename <> 'bPRGS'
			begin
			select @sqlstring = 'If exists (select 1 from sysobjects join sysobjects s on s.id=sysobjects.parent_obj '
			select @sqlstring = @sqlstring + 'where s.name=''' + @tablename + '''and sysobjects.xtype=''TR'')'
			select @sqlstring = @sqlstring + ' Alter Table ' + @tablename + ' disable trigger all '
			BEGIN TRY
				exec (@sqlstring)
			END TRY
			BEGIN CATCH
				SELECT 
					@errnumber = ERROR_NUMBER(),
					@errmsg = ERROR_MESSAGE();
					select @msg = 'Err disabling triggers for ' + @tablename + ' Err Msg: ' + @errmsg
			END CATCH
			end

		--run the copy statement
		BEGIN TRY
			exec (@SqlCopyString)
			select @rowscopied = @@rowcount
		END TRY
		BEGIN CATCH
			SELECT 
				@errnumber = ERROR_NUMBER(),
				@errmsg = ERROR_MESSAGE();
			select @msg = 'Err doing table copy for ' + @tablename +  ' Err Msg: ' + @errmsg,@rcode=1
				goto vspexit
		END CATCH

		--count records after copy
		select @sqlstring = 'select count(1) from ' + @tablename + ' b ' + @countwhere
		BEGIN TRY
			delete from @tablecount
			insert into @tablecount exec (@sqlstring)
			select @aftercount = TableCount from @tablecount
		END TRY
		BEGIN CATCH
			SELECT 
				@errnumber = ERROR_NUMBER(),
				@errmsg = ERROR_MESSAGE();
				select @msg = 'Err doing count after copy, Err Msg: ' + @errmsg,@rcode=1
				goto vspexit
		END CATCH
			

	
		--return status message on table copy
		select @msg = @tablename + ' rows copied: ' + Rtrim(convert(varchar(20),isnull(@rowscopied,0))) + 
			' Before copy: ' + Rtrim(convert(varchar(20),isnull(@beforecount,0))) +
			' After copy: ' + Rtrim(convert(varchar(20),isnull(@aftercount,0)))


  vspexit:
  		--turn triggers back on
		IF @tablename <> 'bPRGS'
		BEGIN
			select @sqlstring = 'If exists (select 1 from sysobjects join sysobjects s on s.id=sysobjects.parent_obj '
			select @sqlstring = @sqlstring + 'where s.name=''' + @tablename + ''' and sysobjects.xtype=''TR'')'
			select @sqlstring = @sqlstring + ' Alter Table ' + @tablename + ' enable trigger all '
			BEGIN TRY
				exec (@sqlstring)
			END TRY
			BEGIN CATCH
				SELECT 
					@errnumber = ERROR_NUMBER(),
					@errmsg = ERROR_MESSAGE();
					select @msg = 'Err enabling triggers for ' + @tablename + ' Err Msg: ' + @errmsg
			END CATCH
		END
			
  	if @opencursor = 1
		begin
		close vcTable
		deallocate vcTable
		end
    return @rcode
    
    
    
    
    
/****** Object:  StoredProcedure [dbo].[vspVAProcessScheduledChange]    Script Date: 12/02/2010 08:31:40 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyTableCopy] TO [public]
GO
