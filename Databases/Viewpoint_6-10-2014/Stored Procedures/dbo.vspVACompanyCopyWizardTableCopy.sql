SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vspVACompanyCopyWizardTableCopy]    
/***********************************************************    
 * CREATED BY: Narendra K 12/04/12    
 * MODIFICATIONS: EricV 11/06/13 TFS-66335 Enclose the column names in brackets when creating SQL commands to handle column names that are SQL reserved words
 *                                         Added @sourcetablename as an optional parameter.
 *				GarthT  12/02/13 TFS-67114 Added ContactGroup conditionals for group-field copy, specifically to work with the vHQContacts constraint.
 *
 * USAGE:    
 * Company Copy Wizard - called from frmTableSelect to copy tables    
 *     
 * INPUT PARAMETERS    
 *   @tablename - table to be copied       
 *   @SourceCo - the company value of the table being copied from      
 *   @SourceCombo - server/database of the source table    
 *   @DestCo - the company value of the table being copied to    
 *   @sourcetablename - source table to be copied. optional. defaults to @tablename
 *   @allowexistingrecords - If 1 then destination table can already contain records. Defaults to 0
 *   @zeroINMTyn - if table is bINMT and flag is Y set value to 0     
 *    
 * OUTPUT PARAMETERS    
 *    @msg - if Error, error message otherwise table copy info    
 *	  @disabledTriggers - return list of disabled triggers if any
 *    
 * RETURN VALUE    
 *   0   success    
 *   1   fail    
*****************************************************/     
   (@tablename varchar(128),@SourceCo int, @SourceCombo varchar(100),@DestCo int, @zeroINMTyn bYN, @sourcetablename varchar(128)=NULL, @allowexistingrecords bit=false, @msg varchar(1000)=null output,@disabledTriggers VARCHAR (MAX)='' output)
  AS    
      
  SET NOCOUNT ON          


DECLARE @rcode int, @coltype varchar(20), @colname varchar(128), @SqlCopyString varchar(max),    
	@insertstring varchar(max), @selectstring varchar(max), @whereclause varchar(max), @opencursor int, @notexists varchar(max),    
	@commastring varchar(100), @colid integer, @inkey integer,@xprec int,@keycnt int, @rowscopied bigint, @beforecount bigint, 
	@aftercount int, @countwhere varchar(max), @errnumber int, @errmsg varchar(500), @grouptype varchar(20), @isnullable integer,
	@nullstringnumdate varchar(20),@sqlstring varchar(max),@IsFirstColumn bYN, @CompanyColumn varchar(128)    
     
-- table variable to hold column information for table being copied    
DECLARE @table TABLE(ColumnName varchar(128),TypeName varchar(25),ColId int,InKey int,IsNullable int,xprec int)    

-- table variable to hold the record counts before and after the table copy    
DECLARE @tablecount TABLE(TableCount int)    

SELECT @rcode = 0, @IsFirstColumn = 'Y', @insertstring = '',@selectstring='',@whereclause='',@notexists=''    
IF @sourcetablename IS NULL
	SET @sourcetablename = @tablename

BEGIN TRY    
------ list of columns in table should be replaced by views --------    
SELECT @sqlstring =     
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
        order by case     
      when c.name=''Qualifier'' then 0     
      when o.name=''bPMTD'' and c.name=''PMCo'' then 0     
      else c.column_id    
     end'    
        
 -- return result into table variable    
 INSERT INTO @table EXEC (@sqlstring)    

 -- check if there are rows    
 IF @@rowcount = 0    
 BEGIN    
	SELECT @msg = rtrim(@tablename) + ' is not on file.',@rcode=5 --exit to get next table, return conditional error    
	GOTO vspexit    
 END     
END TRY    
BEGIN CATCH    

    SELECT     
        @errnumber = ERROR_NUMBER(),    
        @errmsg = ERROR_MESSAGE();    
    
    --select @msg = @sqlstring, @rcode=1    
	SELECT @msg = 'Error Number: ' + convert(varchar(5),@errnumber) + ' Error Message: ' + @errmsg ,@rcode=1    
	
	GOTO vspexit    
END CATCH    

-- get company column
SELECT @CompanyColumn = CoColumn from DDTables where TableName = rtrim(@tablename) and CopyTable = 'Y'    


-- fix defect related to PC tables having company column as NULL : D-06307
IF @CompanyColumn IS NULL AND @tablename LIKE 'vPC%'
BEGIN
	SET @CompanyColumn = 'VendorGroup'
END

-- open cursor on @table    
DECLARE vcTable CURSOR FOR    
	SELECT ColumnName,TypeName,ColId,InKey,IsNullable,xprec    
    FROM @table    
    /* open cursor */     
    OPEN vcTable    
    SELECT @opencursor = 1    
		
	-- Get the identity column of the table    
	DECLARE @identityColumn varchar(128)    
	EXEC vspDDGetIdentityColumn @tablename, @identityColumn output    

vcTable_loop:    
	FETCH NEXT FROM vcTable INTO @colname,@coltype,@colid,@inkey,@isnullable,@xprec    
	IF @@fetch_status = -1 GOTO vcTable_end    
	 
	--skip identity columns    
    IF @colname = @identityColumn GOTO vcTable_loop    
	--- determine if this is a valid table with a company     
		--- changed DD tables to vDD and removed DDDI as it is no longer used - danf    
	IF @tablename in ('vDDDS','vDDDU','bPMTD')    
		BEGIN    
			IF @colname = 'Qualifier' or @colname = 'PMCo'    
			BEGIN    
				SELECT @colid = 1,@coltype = 'bCompany'    
			END    
			IF @colname ='Datatype' or @colname = 'CostType'    
			BEGIN    
				SELECT @colid = 2    
			END    
		END    

	--for first column only    
	IF @IsFirstColumn = 'Y'    
		BEGIN    
			--- valid company?     
			IF @colid = 1 and @tablename in ('bHQCX', 'bJCCT', 'bJCPM', 'bJCPC') SELECT @coltype = 'bGroup' --1st col is group but not bGroup type    
				IF not exists(select 1 from DDTables where TableName = rtrim(@tablename) and CopyTable = 'Y')    
				BEGIN    
					SELECT @msg = 'Skipping ' + rtrim(@tablename) + ', it is not flagged to copy.',@rcode=5 --exit to get next table, return conditional error    
					GOTO vspexit     
				END    
				--begin formatting the insert statements    
				SELECT @insertstring = 'INSERT INTO ' + rtrim(@tablename) + '(' + QUOTENAME(@colname)
			    SELECT @selectstring = 'SELECT '    
			    SELECT @commastring = ''    
			END    
			ELSE    
			BEGIN    
				SELECT @insertstring = @insertstring + @commastring + QUOTENAME(@colname)
				-- put in a line break    
				IF @keycnt >= 10 and @keycnt%10 = 0     
				BEGIN    
					SELECT @insertstring = @insertstring + char(10)    
				END    
			END    

	IF @isnullable <> 0    
			BEGIN    
				-- @nullstringnumdate is used to determine if statement should be isnull(col,'') or isnull(col,0) or isnull(col,'1/1/1970')    
				SELECT @nullstringnumdate = ''    
				IF @xprec = 0 select @nullstringnumdate = '=''''' --not a numeric field    
				IF @coltype in ('smalldatetime','datetime','bDate','bMonth')    
				BEGIN    
					SELECT @nullstringnumdate = '''01/01/1970'''    
				END    
				ELSE    
				BEGIN    
					SELECT @nullstringnumdate = '''0'''    
				END    
			END    

	--Group Fields - since the bGroup was not used consistently, need to figure out group by col name    
	SELECT @grouptype = ''    
	IF @coltype = 'bGroup' SELECT @coltype = 'tinyint'     
	-- check for inconsistencies in db not using correct datatype ------    
	IF @coltype in('tinyint','smallint','int')    
		BEGIN    
			SELECT @grouptype=''    
			   IF UPPER(@colname) in ('PHASEGROUP','PHASEGRP','OLDPHASEGROUP','OLDPHASEGRP','JCPHASEGROUP') SELECT @grouptype='PhaseGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('APVENDORGROUP','VENDORGRP','VENDORGROUP','OLDVENDORGRP','OLDVENDORGROUP') SELECT @grouptype='VendorGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('EMGROUP','OLDEMGROUP','REVUSEDONEQUIPGROUP','OLDREVUSEDONEQUIPGROUP','USEDONEQUIPGROUP','USEDONEQUIPGROUP') select @grouptype='EMGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('MATERIALGROUP','MATLGROUP','OLDMATLGROUP','MIMATERIALGROUP') SELECT @grouptype='MatlGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('CUSTGROUP','OLDCUSTGROUP') SELECT @grouptype='CustGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('TAXGROUP','OLDTAXGROUP') SELECT @grouptype='TaxGroup', @coltype='bGroup'    
			   IF UPPER(@colname) in ('SHOPGROUP','OLDSHOPGROUP') SELECT @grouptype='ShopGroup', @coltype='bGroup'
			   IF UPPER(@colname) in ('CONTACTGROUP','OLDCONTACTGROUP') SELECT @grouptype='ContactGroup', @coltype='bGroup'      
		END    
  
	IF @colname = @CompanyColumn --@colid=1 is always the first column    
		BEGIN    
			--set the whereclause and wherecount     
			IF @grouptype <> ''     
			BEGIN
				SELECT @whereclause = 'WHERE ' + QUOTENAME(@colname) + ' = (select ' + @grouptype + ' from ' + @SourceCombo +    
				'HQCO where HQCo=' + convert(varchar(3),@SourceCo) + ')'    
				SELECT @countwhere = 'WHERE ' + QUOTENAME(@colname) + ' = (select ' + @grouptype + ' from  HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'    
				SELECT @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +    
				QUOTENAME(@colname) + '=' + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
			END
			ELSE
			BEGIN
				 SELECT @whereclause = 'WHERE ' + QUOTENAME(@colname) + ' = ' + convert(varchar(3),@SourceCo)    
				 SELECT @countwhere = 'WHERE ' + QUOTENAME(@colname) + ' = ' + convert(varchar(3),@DestCo)    
				 SELECT @notexists = 'AND NOT EXISTS (SELECT TOP 1 1 FROM ' + rtrim(@tablename) + ' b WHERE b.' +    
				  QUOTENAME(@colname) + '=' + convert(varchar(3),@DestCo)+ ')'
			END
		END
		
	-- set select string      
	IF @coltype in ('bCompany','bGroup')    
		BEGIN    
			IF @grouptype = ''    
			BEGIN    
				IF(@colname <> @CompanyColumn)
				BEGIN
					SELECT @selectstring = @selectstring + @commastring + ' case when ' + QUOTENAME(@colname) + ' = ' + convert(varchar(3),@SourceCo)   + ' then ' + convert(varchar(3),@DestCo) + ' else ' + QUOTENAME(@colname) + ' end'
				END
				ELSE
				BEGIN
					 SELECT @selectstring = @selectstring + @commastring + convert(varchar(3),@DestCo)     
				END   
			END    
			ELSE    
			BEGIN    
				SELECT @selectstring = @selectstring + @commastring + ' case when ' + QUOTENAME(@colname) + ' is null then null else '    
				SELECT @selectstring = @selectstring + '(select ' + @grouptype + ' from HQCO where HQCo= ' + convert(varchar(3),@DestCo) + ') end'    
			END    
		END    
	ELSE    
		IF rtrim(@tablename) = 'bINMT' and @zeroINMTyn='Y' and @colname in ('OnHand','RecvdNInvcd','OnOrder','Booked')     
		BEGIN    
			SELECT @selectstring = @selectstring + @commastring + '0'    
		END    
		ELSE    
		BEGIN    
			SELECT @selectstring = @selectstring + @commastring + QUOTENAME(@colname)    
		END    

	-- put in a line break    
	IF @keycnt >= 10 and @keycnt%10 = 0     
				BEGIN    
					SELECT @selectstring = @selectstring + char(10)     
				END    

	-- set notexists string    
	IF @colname = @CompanyColumn -- Is the first Column in the table    
	BEGIN    
		IF @grouptype <> '' -- Is a Group Type Column    
		BEGIN    
			SELECT @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +    
				QUOTENAME(@colname) + '=' + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'     
		END    
		ELSE  -- Is not a Group Type Column    
		BEGIN    
			SELECT @notexists = 'and Not Exists (Select top 1 1 from ' + rtrim(@tablename) + ' b where b.' +    
				 QUOTENAME(@colname) + '=' + convert(varchar(3),@DestCo)
		END    
	END    
	ELSE    
	IF @inkey > 0 and @colname not in('SortName','UniqueAttchID',@identityColumn) --Is not the 1st column but is a key column    
	BEGIN    
		IF @coltype <> 'bCompany'    
			BEGIN    
				IF @isnullable <> 0  -- Can be null    
				BEGIN    
					SELECT @notexists = @notexists + ' and isnull(b.' + QUOTENAME(@colname) + ',' + @nullstringnumdate + ')='    
				END    
				ELSE -- Cannot be null    
				BEGIN    
					SELECT @notexists = @notexists + ' and b.' + QUOTENAME(@colname) + '='    
				END    

				IF @grouptype <> '' -- Is a Group Type Column    
				BEGIN    
					IF @isnullable <> 0 --Can be null    
					BEGIN    
					   SELECT @notexists = @notexists + '(select '+ 'isnull(' + @tablename + '.' + QUOTENAME(@colname) + ',' + @nullstringnumdate + ')' +    
						 ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
					END    
					ELSE -- Cannot be null    
					BEGIN    
						SELECT @notexists = @notexists + '(select ' + @grouptype + ' from HQCO where HQCo=' + convert(varchar(3),@DestCo) + ')'
					END    
				END    
				ELSE -- Is not a Group Type Column    
				BEGIN    
					IF @isnullable <> 0  -- Can be null    
					BEGIN    
						SELECT @notexists = @notexists + 'isnull(' + @tablename + '.' + QUOTENAME(@colname) + ',' + @nullstringnumdate + ')'
					END    
					ELSE -- Cannot be null    
					BEGIN    
						SELECT @notexists = @notexists + @tablename + '.' + QUOTENAME(@colname)    
					END    
				END    
			END    
	END    

	IF @IsFirstColumn = 'Y'     
	BEGIN    
		SELECT @IsFirstColumn = 'N'    
		SELECT @commastring = ','    
	END    
			    
	--get next column    
	SELECT @keycnt = @keycnt + 1    
	GOTO vcTable_loop    

vcTable_end:    
	CLOSE vcTable    
	DEALLOCATE vcTable    
				
	SELECT @opencursor = 0    

	-- Put the SQL statement together    
	SELECT @SqlCopyString = @insertstring + ')' + char(10) + @selectstring + char(10) + ' FROM ' + @SourceCombo +    
				@sourcetablename + ' ' + char(10) + @whereclause + ' ' + char(10) + CASE WHEN @allowexistingrecords=0 THEN @notexists+')' ELSE '' END

	--count records before copy    
	SELECT @sqlstring = 'select count(1) from ' + @tablename + ' b ' + @countwhere  
	BEGIN TRY    
		DELETE FROM @tablecount    
		INSERT INTO @tablecount exec (@sqlstring)    
		SELECT @beforecount = TableCount from @tablecount    
	END TRY    
	BEGIN CATCH    
		SELECT     
			@errnumber = ERROR_NUMBER(),    
			@errmsg = ERROR_MESSAGE();    
		SELECT @msg = 'Err doing count before copy, Err Msg: ' + @errmsg,@rcode=1    
		GOTO vspexit    
	END CATCH    

	--disable triggers    
	IF @tablename <> 'bPRGS'    
	BEGIN    
		SELECT @sqlstring = 'If exists (select 1 from sysobjects join sysobjects s on s.id=sysobjects.parent_obj '    
		SELECT @sqlstring = @sqlstring + 'where s.name=''' + @tablename + '''and sysobjects.xtype=''TR'')'    
		SELECT @sqlstring = @sqlstring + ' Alter Table ' + @tablename + ' disable trigger all '    
		BEGIN TRY    
			EXEC (@sqlstring)  			      
		END TRY    
		BEGIN CATCH    
			SELECT     
			 @errnumber = ERROR_NUMBER(),    
			 @errmsg = ERROR_MESSAGE();      
			       
			DECLARE @triggerList as nvarchar(256);
			-- having trigger names in error msg while disabling the trigger  
			 
			SELECT @triggerList = COALESCE (CASE WHEN @triggerList = '' THEN O.name  ELSE @triggerList + ',' + O.name  END,'')  
				FROM sys.triggers O   
				INNER JOIN sys.tables T   
				ON T.object_id = O.parent_id   
				WHERE O.type = 'TR' AND T.name IN (@tablename) AND O.is_disabled=0  
			       
			SELECT @msg = 'Err disabling triggers ' +@triggerList+ ' for ' + @tablename + ' Err Msg: ' + @errmsg    
			     
		END CATCH    
	END    
	
	--run the copy statement    
	BEGIN TRY    
		EXEC (@SqlCopyString)    
		SELECT @rowscopied = @@rowcount    
	END TRY    
	BEGIN CATCH    
		SELECT     
			@errnumber = ERROR_NUMBER(),    
			@errmsg = ERROR_MESSAGE();    
	   
		SELECT @msg = 'Err doing table copy for ' + @tablename +  ' Err Msg: ' + @errmsg,@rcode=1    
		GOTO vspexit    
	END CATCH    
			    
	--count records after copy    
	SELECT @sqlstring = 'select count(1) from ' + @tablename + ' b ' + @countwhere    
	BEGIN TRY    
		DELETE from @tablecount    
		INSERT into @tablecount exec (@sqlstring)    
		SELECT @aftercount = TableCount from @tablecount    
	END TRY    
	BEGIN CATCH    
		SELECT     
			@errnumber = ERROR_NUMBER(),    
			@errmsg = ERROR_MESSAGE();    

		SELECT @msg = 'Err doing count after copy, Err Msg: ' + @errmsg,@rcode=1    
		GOTO vspexit    
	END CATCH    

	--return status message on table copy    
	SELECT @msg = @tablename + ' rows copied: ' + Rtrim(convert(varchar(20),isnull(@rowscopied,0))) +     
			   ' Before copy: ' + Rtrim(convert(varchar(20),isnull(@beforecount,0))) +    
			   ' After copy: ' + Rtrim(convert(varchar(20),isnull(@aftercount,0)))    

vspexit:    
	--turn triggers back on    
	IF @tablename <> 'bPRGS'    
	BEGIN    
		SELECT @sqlstring = 'If exists (select 1 from sysobjects join sysobjects s on s.id=sysobjects.parent_obj '    
		SELECT @sqlstring = @sqlstring + 'where s.name=''' + @tablename + ''' and sysobjects.xtype=''TR'')'    
		SELECT @sqlstring = @sqlstring + ' Alter Table ' + @tablename + ' enable trigger all '    
		BEGIN TRY    
			EXEC (@sqlstring)    					      
		END TRY    
		BEGIN CATCH    
			SELECT     
				@errnumber = ERROR_NUMBER(),    
				@errmsg = ERROR_MESSAGE();    
	       
			-- having trigger names in error msg while enabling the trigger    
			SELECT @disabledTriggers = COALESCE (CASE WHEN @disabledTriggers = '' THEN O.name  ELSE @disabledTriggers + ',' + O.name  END,'')  
				FROM sys.triggers O   
				INNER JOIN sys.tables T   
				ON T.object_id = O.parent_id   
				WHERE O.type = 'TR' AND T.name IN (@tablename) AND O.is_disabled=1  

			SELECT @msg = 'Err enabling triggers ' +@disabledTriggers+ ' for ' + @tablename + ' Err Msg: ' + @errmsg  

		END CATCH    
	END    

	IF @opencursor = 1    
	BEGIN    
		CLOSE vcTable    
		DEALLOCATE vcTable    
	END    

	RETURN @rcode    
 
SET ANSI_NULLS ON    
GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyWizardTableCopy] TO [public]
GO
