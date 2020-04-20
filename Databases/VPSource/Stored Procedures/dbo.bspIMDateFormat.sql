SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMDateFormat]
    /************************************************************************
    * CREATED:    MH 12/29/99
    * MODIFIED:   MH 1/7/02 Issue 15734.  Not formating correctly.  Recoded. 
    *			   RT 09/02/03 Issue #22317 - Handle date format without slashes.
    *
    * Purpose of Stored Procedure
    *
    *    Reformat a date (MM/YY[YY], MM/DD/YY[YY], or MMDDYY[YY]) into our smalldatetype 
    *		month format (MM/01/YY)
    *
    * Notes about Stored Procedure
    *
    *
    * returns 0 if successfull
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   
        (@importid varchar(20), @template varchar(30), @rectype varchar(30), @msg varchar(80) = '' output)
   
    as
    set nocount on
   
        declare @ident int, @complete int, @formated_mth varchar(10), @slash int, @rcode int
   
        declare @mth varchar(10)
   
   	--Issue 15734 mh 1/7/02
   	declare @slashpos int
   	declare @leftside varchar(20), @rightside varchar(20), @remain varchar(20)
   
   	select @ident = (select top 1 Identifier 
   						from IMTD 
   						where ImportTemplate = @template and ColDesc = 'Month' and RecordType = @rectype)
   
    	declare date_curs cursor
   	for
   	select distinct ltrim(UploadVal) 
   	from IMWE 
   	where ImportId = @importid and Identifier = @ident and UploadVal <> '' and RecordType = @rectype
   
   	open date_curs
   
    	fetch next from date_curs into @mth
   	select @complete = 0
   
   	while @complete = 0
   	begin
   
   		if @@fetch_status = 0
   			begin
   
   				select @slashpos = 0
   
   				select @slashpos = charindex('/', @mth)
   
   				if @slashpos > 0	--format most likely MM/DD/YY[YY]
   				begin
   --					select @slashpos = charindex('/', @mth)
   					select @leftside = substring(@mth, 1, @slashpos - 1)
   					select @remain = substring(@mth, @slashpos + 1, len(@mth) - @slashpos)
   					select @slashpos = charindex('/', @remain)
   					if @slashpos > 0	--handle MM/YY format
   						select @rightside = rtrim(substring(@remain, @slashpos + 1, len(@remain) - @slashpos))
   					else
   						select @rightside = right(@remain,2)
   					select @formated_mth = @leftside + '/01/' + @rightside
   				end		
   				else		--format most likely MMDDYY[YY]
   				begin
   					select @leftside = left(@mth,2)
   					select @rightside = right(@mth,2)
   					select @formated_mth = @leftside + '/01/' + @rightside
   				end
   
                   update IMWE set UploadVal = @formated_mth
                   where ImportId = @importid and Identifier = @ident and ltrim(UploadVal) = @mth and
   				RecordType = @rectype
   --end Issue 1/7/02
   
                   fetch next from date_curs into @mth
       	    end
   		else
       	    select @complete = 1
   
    	end
   
    	select @rcode = 0
   
    bspexit:
   
        close date_curs
        deallocate date_curs
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMDateFormat] TO [public]
GO
