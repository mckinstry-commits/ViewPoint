SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDImportLoadDDUD]
    /***********************************************************
     * CREATED BY:   DANF 04/22/07
     * MODIFIED BY:  
     *
     * USAGE:
     * Gets the info for the form from DDFI and loads into DDUD
     *
     * INPUT PARAMETERS
    
     *   Form         Form
     *
     * RETURN VALUE
     *   0 Success
     *   1 fail
     ************************************************************************/
    	(@form varchar(30) = null, @msg varchar(60) output)
    as
    set nocount on
        declare @rcode int, @openform int, @validcnt int, @seq smallint, @columnname varchar(30), @req bYN,
            @identifier int, @tablename varchar(30), @datatype varchar(30), @table varchar(30),
            @name varchar(30), @tempname varchar(30), @description bDesc
    select @rcode = 0
    select @openform = 0
    select @identifier = 0
    
    if @form is null
    	begin
    	select @msg = 'Missing Form!', @rcode = 1
    	goto bspexit
    	end
    
    --get table from DDFH

    select @table=ViewName from dbo.vDDFH with (nolock) where Form=@form
    /* check whether the form already exisits in DDUD, if exists skip inserting */
    
    select @validcnt=Count(*) from dbo.bDDUD with (nolock) where Form=@form
    select @validcnt
    if @validcnt = 0
    begin
      --first insert company if company exists in the table
        select @name=name from syscolumns where id = object_id(@table) and colorder=1
        select @tempname = right(@name, 2)
        if @tempname = 'Co'
            begin
                insert dbo.bDDUD (Form, TableName, Identifier, ColumnName, RequiredValue, BidtekDefaultValue)
     	        values (@form, @table, @identifier, @name, 'Y', 'N')
            end
    
        declare forminfo_cursor cursor local fast_forward for
    	select Datatype, Seq, ViewName, ColumnName, Req, Description from vDDFI where Form=@form
    
    	open forminfo_cursor
    	select @openform = 1

    	forminfo_cursor_loop:     --loop through all the records
    
    	fetch next from forminfo_cursor into @datatype, @seq, @tablename, @columnname, @req, @description
    	if @@fetch_status=0
    	  begin
            if @columnname is not null or @datatype='bMonth' or @datatype='bBatchID'     --insert only those rows which are bound to table
                begin
                if @columnname is null and @datatype='bMonth'
                    begin
                    select @columnname='Mth'
                    select @tablename=@table
                    end
                if @columnname is null and @datatype='bBatchID'
                    begin
                    select @columnname='BatchId'
                    select @tablename=@table
                    end
                select @identifier=@identifier+5
    	        insert dbo.bDDUD (Form, Seq, TableName, Identifier, ColumnName, RequiredValue, BidtekDefaultValue, Description, Datatype)
     	        values (@form, @seq, @tablename, @identifier, @columnname, 'Y', 'N', @description, @datatype)
                end
    
    	    goto forminfo_cursor_loop
    	  end
    end
    -- close and deallocate cursor
    	if @openform = 1
    	  begin
    	    close forminfo_cursor
    	    deallocate forminfo_cursor
      	    select @openform = 0
    	  end
    
    
    bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'') + char(13) + char(13) + '[vspDDImportLoadDDUD]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDImportLoadDDUD] TO [public]
GO
