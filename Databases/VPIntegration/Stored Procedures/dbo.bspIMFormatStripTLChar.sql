SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMFormatStripTLChar]
    /************************************************************************
    * CREATED:    MH 06/14/01
    * MODIFIED:   RT 08/29/05, issue #29629, replace 'len' function with 'datalength' to count trailing spaces.
	*			  CC 03/19/2008 - Issue #122980 - Add support for notes/large fields
    *
    * Purpose of Stored Procedure
    *
    *    Remove a character from in input value depending on a side indicated.
    *
    *
    * Notes about Stored Procedure
    *
    *
    * returns 0 if successfull
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
    
    	(@invalue varchar(max), @stripchar char(1), @side varchar(1), @outvalue varchar(max) output, @msg varchar(80) = '' output)
    as
    set nocount on
    
        declare @rcode int, @valuelen int, @complete int, @pos int, @testval varchar(max)
    
        select @rcode = 0, @complete = 0, @outvalue = ''
    
        --Strip leading char
        if @side = 'L'
            begin
                select @outvalue = @invalue
                while @complete = 0
                    begin
                        if (select left(@outvalue, 1)) = @stripchar
                            begin
                                select @pos = (datalength(@outvalue) - 1)
                                select @outvalue = right(@outvalue, @pos)
                            end
                        else
                        select @complete = 1
                    end
    
            end
    
        --Strip trailing char
        if @side = 'T'
            begin
                select @outvalue = @invalue
                while @complete = 0
                    begin
                        if (select right(@outvalue, 1)) = @stripchar
                            begin
                                select @pos = (datalength(@outvalue) - 1)
                                select @outvalue = left(@outvalue, @pos)
                            end
                        else
                        select @complete = 1
                    end
            end
    
        --strip the character from both sides
        if @side = 'B'
            begin
                --strip the leading characters
                select @outvalue = @invalue
                while @complete = 0
                    begin
                        if (select left(@outvalue, 1)) = @stripchar
                            begin
                                select @pos = (datalength(@outvalue) - 1)
                                select @outvalue = right(@outvalue, @pos)
                            end
                        else
                        select @complete = 1
                    end
    
    	    --then strip the trailing characters
                    select @complete = 0	--reset the complete flag, still working with @outvalue
                    while @complete = 0
                        begin
                            if (select right(@outvalue, 1)) = @stripchar
                                begin
                                    select @pos = (datalength(@outvalue) - 1)
                                    select @outvalue = left(@outvalue, @pos)
                                end
                            else
                            select @complete = 1
                        end
            end
    
        --Strip all instances of specified char
        if @side = 'A'
            begin
                select @valuelen = datalength(@invalue)
                while @valuelen > 0
                    begin
                        select @testval = substring(@invalue, 1, 1)
                        if @testval <> @stripchar
                            begin
    							if @outvalue is null
    								select @outvalue = @testval
    							else
    	                            select @outvalue = @outvalue + @testval
                            end
    
                        select @invalue = substring(@invalue, 2, (datalength(@invalue)-1))
                        select @valuelen = datalength(@invalue)
                    end
  
            end
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMFormatStripTLChar] TO [public]
GO
