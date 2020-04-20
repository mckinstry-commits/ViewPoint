SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMImportXML]
     /************************************************************************
     * CREATED:    RT 11/12/03
     * MODIFIED:   CC 11-09-10 Issue #138004 - added QUOTENAME function arround import table name
     *
     * Purpose of Stored Procedure
     *
     *    Move data from a temporary table holding records to be imported
     *    into the work edit table - IMWE
     *
     * Notes about Stored Procedure
     *
     *    returns 0 if successful
     *    returns 1 and error msg if failed
     *
     *************************************************************************/
     
   	(@importid varchar(20), @importtemplate varchar(10), 
   	@importtbl varchar(30), @rectype varchar(30), @msg varchar(80) = '' output) AS
   
   	set nocount on
     
   	declare @template varchar(10), @identifier int, @recordtype varchar(30), @xmltag  varchar(50),
   	@form varchar(30), @imweins varchar(255), @rcode int
     
   	if @importid is null
   	begin
   		select @msg = 'Missing ImportId', @rcode = 1
   		goto bspexit
   	end
     
   	if @importtemplate is null
   	begin
   		select @msg = 'Missing Import Template', @rcode = 1
   		goto bspexit
   	end
   
   	select @form = Form from IMTR where ImportTemplate = @importtemplate and RecordType = @rectype
   	select @rcode = 0
   
   	-- cursor to hold info from IMTD
   	declare procimptbl_curs cursor local fast_forward for
   	select ImportTemplate, Identifier, RecordType, XMLTag
   	from IMTD where ImportTemplate = @importtemplate and RecordType = @rectype and 
   	(XMLTag is not null or Required <> 0 or XRefName is not null or DefaultValue is not null or UserDefault is not null)
   
   	open procimptbl_curs
   
   	fetch next from procimptbl_curs into @template, @identifier, @recordtype, @xmltag
   
   	-- while cursor is not empty
   	while @@fetch_status = 0
   	begin
   		if @xmltag is not null
   		begin
   			select @imweins = 'select ' + char(39) + @importid + char(39) + ',' + char(39) + @template + char(39) + ',' + char(39) +
   				@form + char(39) + ',' + char(39) + @recordtype + char(39) + ','
   				+ convert(varchar(4),@identifier) + ',' + 'KeyCol,[' + @xmltag + '] from ' + QUOTENAME(@importtbl)
   
   			--select @imweins 'IMWE insert statement when @xmltag is not null'
   			insert IMWE (ImportId, ImportTemplate, Form, RecordType, Identifier, RecordSeq, ImportedVal)
   			exec (@imweins)
   		end
   		else
   		begin
   			select @imweins = 'select ' + char(39) + @importid + char(39) + ',' + char(39) + @template + char(39) + ',' + char(39) +
   				@form + char(39) + ',' + char(39) + @recordtype + char(39) + ','
   				+ convert(varchar(4),@identifier) + ',' + 'KeyCol' + ' from ' + QUOTENAME(@importtbl)
   
   			--select @imweins 'IMWE insert statement when @xmltag is null'
   			insert IMWE (ImportId, ImportTemplate, Form, RecordType, Identifier, RecordSeq)
   			exec (@imweins)
   		end
   
   		fetch next from procimptbl_curs into @template, @identifier, @recordtype, @xmltag
   
   		select @msg = convert(varchar(20), (select Max(RecordSeq) from IMWE where ImportTemplate = @template and ImportId = @importid))
   
   	end
     
   bspexit:
     
   	close procimptbl_curs
   	deallocate procimptbl_curs
     
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMImportXML] TO [public]
GO
