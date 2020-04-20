SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMApplyDefaultIMWE    Script Date: 11/6/2002 9:28:13 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspIMApplyDefaultIMWE    Script Date: 2/21/2002 3:08:48 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspIMApplyDefaultIMWE    Script Date: 1/16/2002 3:27:49 PM ******/
   
   /****** Object:  Stored Procedure dbo.bspIMApplyDefaultIMWE    Script Date: 1/11/2002 7:25:35 AM ******/
   CREATE     procedure [dbo].[bspIMApplyDefaultIMWE]
   /************************************************************************
   * CREATED:    MH
   * MODIFIED:   CC 3/19/2008 - Issue #122980 - Add support for notes/large fields
   *
   * Purpose of Stored Procedure
   *
   *    Apply defaults from IMTD to IMWE for a given ImportId
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@importid varchar(20), @importtemplate varchar(10), @rectype varchar(30), @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare  @complete int, @rcode int
   
       declare @identifier int, @defaultvalue varchar(20)
   
   	declare @userdefault varchar(20), @overrideyn bYN
   
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
   
   declare proc_default_curs cursor
   for
   /*
       select Identifier, DefaultValue 
   	from IMTD 
   	where ImportTemplate = @importtemplate and DefaultValue is not null
   */
   /*
   	select Identifier, UserDefault, OverrideYN
   	from IMTD
   	where ImportTemplate = @importtemplate and UserDefault is not null
   */
   	select Identifier, UserDefault, OverrideYN
   	from IMTD
   	where ImportTemplate = @importtemplate and UserDefault is not null and RecordType = @rectype
   
       open proc_default_curs
   
   --    fetch next from proc_default_curs into @identifier, @defaultvalue
   	fetch next from proc_default_curs into @identifier, @userdefault, @overrideyn
   
   select @complete = 0
   

   
   while @complete = 0
   begin
   
       if @@fetch_status = 0
           begin
   
   --this will overwrite an existing value.  
   /*
           update IMWE set UploadVal = @defaultvalue
               where ImportId = @importid and ImportTemplate = @importtemplate and
                   Identifier = @identifier
   */
   
   /*
           update IMWE set UploadVal = @defaultvalue
   			where ImportId = @importid and ImportTemplate = @importtemplate and
   			Identifier = @identifier and ImportedVal is null
   */
   
   
   		if @overrideyn = 'Y'
   			BEGIN
   /*
   			update IMWE set UploadVal = @userdefault
   			where ImportId = @importid and ImportTemplate = @importtemplate and
   			Identifier = @identifier 
   */
   
	   			update IMWE set UploadVal = @userdefault
   				where ImportId = @importid and ImportTemplate = @importtemplate and
   				Identifier = @identifier and RecordType = @rectype

	   			update IMWENotes set UploadVal = @userdefault
   				where ImportId = @importid and ImportTemplate = @importtemplate and
   				Identifier = @identifier and RecordType = @rectype
			END
   		ELSE
			BEGIN
   /*
   			update IMWE set UploadVal = @userdefault
   			where ImportId = @importid and ImportTemplate = @importtemplate and
   			Identifier = @identifier and (ImportedVal is null or ImportedVal = '')
   */
   				update IMWE set UploadVal = @userdefault
	   			where ImportId = @importid and ImportTemplate = @importtemplate and
   				Identifier = @identifier and RecordType = @rectype and (ImportedVal is null or ImportedVal = '')
   
				update IMWENotes set UploadVal = @userdefault
	   			where ImportId = @importid and ImportTemplate = @importtemplate and
   				Identifier = @identifier and RecordType = @rectype and (ImportedVal is null or ImportedVal = '')
			END
   --        fetch next from proc_default_curs into @identifier, @defaultvalue
   		fetch next from proc_default_curs into @identifier, @userdefault, @overrideyn
           end
   
       else
           select @complete = 1
   
   end
   
   select @rcode = 0
   
   bspexit:
   
       close proc_default_curs
       deallocate proc_default_curs
   
        return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMApplyDefaultIMWE] TO [public]
GO
