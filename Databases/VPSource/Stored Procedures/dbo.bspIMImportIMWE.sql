SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMImportIMWE]
     /************************************************************************
     * CREATED:     MH 12/15/99
     * MODIFIED:    MH 5/17/00  Modified where clause that populates cursor.  See notes below.
     *              MH 07/22/02 Added New Column UserDefault to cursor.
     * 			    MH 4/15/03 - Issue 19626.  Need to populate RecColumn if null 
     *				DANF 08/18/2003 - Issue 22191 Reset Record Column value for Fixed length imports.
     *				RT 10/2/03 - Issue 22620, moved code for issues 19626,22191 to bsp IMTemplateImport.
     *				RT 06/22/04 - issue 24373, set ANSI_WARNINGS OFF to prevent import failure for truncation.
     * 				DANF 10/26/2004 - Issue 25901 Added with ( nolock )  and local fast_forward cursor
     *			    DANF 02/28/2008 - Issue 127053 String or binary data will be truncated error fix. 
	 *				CC 03/12/2008 - Issue 127389 Increased @importtbl to varchar(128), increase @imweins to varchar(max)
	 *				CC 03/14/2008 - Issue #122980 Added handling for fields larger than 60 characters
     *
     * Purpose of Stored Procedure
     *
     *    Move data from a temporary table holding records to be imported
     *    into the work edit table - IMWE
     *
     * Notes about Stored Procedure
     *
     *
     * returns 0 if successfull
     * returns 1 and error msg if failed
     *
     *************************************************************************/
     
   	(@importid varchar(20), @importtemplate varchar(10), 
   	@importtbl varchar(128), @rectype varchar(30), @msg varchar(80) = '' output)
     
   	as
   	set nocount on
    	SET ANSI_WARNINGS OFF
   
   	declare @template varchar(10), @identifier int, @recordtype varchar(30), @reccolumn  int,
   	@form varchar(30), @complete int, @imweins nvarchar(max),  @ident int, @begpos int, @rcode int
     
     
   	if @importid is null
   	begin
   		select @msg = 'Missing ImportId', @rcode = 1
   		goto bspexit
   	end
     
   	if @importtemplate is null
   	begin
   		select @msg = 'Missing Import Template'
   		goto bspexit
   	end
   
	Update IMTH
	Set LastImport = getdate()
	where ImportTemplate = @importtemplate
     
   	select @form = Form from IMTR with (nolock) where ImportTemplate = @importtemplate and RecordType = @rectype
   	select @rcode = 0
   
     
   	-- cursor to hold info form IMTD
   	declare procimptbl_curs cursor local fast_forward
   	for
   
   		select ImportTemplate, Identifier, RecordType, RecColumn
   		from IMTD where ImportTemplate = @importtemplate and RecordType = @rectype and (RecColumn is not null or Required <> 0 or XRefName is not null or DefaultValue is not null or UserDefault is not null)
   
   		open procimptbl_curs
     
   		fetch next from procimptbl_curs into @template, @identifier, @recordtype, @reccolumn
     
   		select @complete = 0
     
   		-- while cursor is not empty
   		while @complete = 0
   		begin
     
   		if @@fetch_status = 0
   		begin
			IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS c
							   JOIN DDUD d ON c.TABLE_NAME = d.TableName AND c.COLUMN_NAME = d.ColumnName
							   WHERE (c.CHARACTER_MAXIMUM_LENGTH > 60 OR c.CHARACTER_MAXIMUM_LENGTH  = -1) 
							          AND d.Form =@form AND d.Identifier = @identifier)
			BEGIN
				SELECT @imweins = 'SET ANSI_WARNINGS OFF; INSERT IMWENotes (ImportId, ImportTemplate, Form, RecordType, Identifier, ' + 
								  CASE WHEN @reccolumn IS NOT NULL THEN 'RecordSeq, ImportedVal)'
									   ELSE 'RecordSeq)'
								  END 
								  + ' SELECT ' + char(39) + @importid + char(39) + ',' + char(39) + @template + char(39) + ',' + char(39)
     							  + @form + char(39) + ',' + char(39) + @recordtype + char(39) + ','
     							  + convert(varchar(4),@identifier) + ',' + 
								  CASE WHEN @reccolumn IS NOT NULL THEN 'KeyCol,' + 'Col' + convert(varchar(4), @reccolumn) 
									   ELSE 'KeyCol' 
								  END
								  + ' FROM ' + QUOTENAME(@importtbl)
				EXEC sp_executesql @imweins  				
			END

			ELSE

			BEGIN
				SELECT @imweins = 'SET ANSI_WARNINGS OFF; INSERT IMWE (ImportId, ImportTemplate, Form, RecordType, Identifier, ' + 
								  CASE WHEN @reccolumn IS NOT NULL THEN 'RecordSeq, ImportedVal)'
									   ELSE 'RecordSeq)'
								  END 
								  + ' SELECT ' + char(39) + @importid + char(39) + ',' + char(39) + @template + char(39) + ',' + char(39)
     							  + @form + char(39) + ',' + char(39) + @recordtype + char(39) + ','
     							  + convert(varchar(4),@identifier) + ',' + 
								  CASE WHEN @reccolumn IS NOT NULL THEN 'KeyCol,' + 'Col' + convert(varchar(4), @reccolumn) 
									   ELSE 'KeyCol' 
								  END
								  + ' FROM ' + QUOTENAME(@importtbl)
				EXEC sp_executesql @imweins  				
			END
   			  
   			fetch next from procimptbl_curs into @template, @identifier, @recordtype, @reccolumn
     
   		end
   		else
   		begin
   			select @complete = 1
   		end
     
   		select @msg = convert(varchar(20), (select Max(RecordSeq) from IMWE where ImportTemplate = @template and ImportId = @importid))
     
     
   	end
     
   bspexit:
     
     
   close procimptbl_curs
   deallocate procimptbl_curs
     
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMImportIMWE] TO [public]
GO
