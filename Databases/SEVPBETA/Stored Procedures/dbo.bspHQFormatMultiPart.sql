SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQFormatMultiPart    Script Date: 10/18/2001 11:38:10 AM ******/
   /****** Object:  Stored Procedure dbo.bspHQFormatMultiPart    Script Date: 8/28/99 9:32:47 AM ******/
   CREATE proc [dbo].[bspHQFormatMultiPart]
   
   /***********************************************************
    * CREATED BY: SE   11/10/96
    * MODIFIED By : SE 11/10/96
    *				RM 02/13/04 = #23061, Add isnulls to all concatenated strings, where necessary
    *
    * USAGE:
    * Pass this function a stirng and a format like '2R-3LN' and it
    * return a string formatted to the format specification.
    *
    *
    * INPUT PARAMETERS
    *    instring   string to format
    *    informat   format mask to format string to
    *
    * OUTPUT PARAMETERS
    *    outstring  instring formatted
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure or nothing to format
    *****************************************************/
   (@instring varchar(50) = null, @informat varchar(30)= null, @outstring varchar(50) output)
   as
   set nocount on
   
   declare @count int, @just char(1), @separator char(1), @nwformat varchar(50),
   		@leftover varchar(50), @frmtstring varchar(50), @cut int
   
   declare @format varchar(50), @rcode tinyint, @formatlength int, @rest varchar(50), @empty varchar(50)
   
   --select @outstring = '', @rcode = 1
   select @rcode = 1
   
   while (DATALENGTH(@informat) > 1)
     begin
        /*if length is 2 assume null separator at end*/
       if DATALENGTH(@informat) = 2
        select @informat=@informat + 'N'
   
   
     select @formatlength = DATALENGTH(@informat)
   
       if @formatlength < 3
          begin
   
           select @rcode = 1
           goto bspexit
          end
   
      /*now get the number of chars in the format*/
      /* 99 is the highest possible value for format chars */
   
      if isnumeric(substring(@informat,1,2)) = 1
   
         begin
          /*get the length of the part the justification and the separator*/
   
          select @count = convert(int, (substring(@informat,1,2)))
          select @just = substring(@informat,3,1)
          select @separator = substring(@informat,4,1)
   
   
          select @nwformat = substring(@informat,5,@formatlength-4)
         end
      else
        begin
         if isnumeric(substring(@informat,1,1)) = 1
            begin
             /*get the length of the part the justification and the separator*/
             select @count = convert(int, (substring(@informat,1,1)))
             select @just = substring(@informat,2,1)
             select @separator = substring(@informat,3,1)
             select @nwformat = substring(@informat,4,@formatlength-3)
   
            end
         else
   
            begin
   
             select @outstring = '', @rcode = 1
             goto bspexit
            end
        end
   
   
       if @separator <> 'N'
          begin
           select @cut = charindex(@separator,@instring)
           if @cut = 0
             begin
   
              select @cut = DATALENGTH(@instring) + 1
             end
   
           if (@cut-1) > @count
              begin
               select @frmtstring = substring(@instring,1, @count)
   
               select @leftover = RIGHT(@instring,DATALENGTH(@instring) - DATALENGTH(@frmtstring))
              end
           else
              begin
               select @frmtstring = substring(@instring, 1, @cut-1)
   
               select @leftover = RIGHT(@instring,DATALENGTH(@instring) - DATALENGTH(@frmtstring))
              end
          end
       else
           begin
            select @frmtstring = substring(@instring, 1,@count)
   
            select @leftover = RIGHT(@instring,DATALENGTH(@instring) - DATALENGTH(@frmtstring))
           end
       
   
          select @frmtstring = isnull(@frmtstring,'')
   
       if DATALENGTH(@frmtstring) < @count or DATALENGTH(@frmtstring) is null
            begin
             if @just = 'L'
                begin
                 select @frmtstring = @frmtstring + SPACE(@count-DATALENGTH(@frmtstring))
                end
   
   
             if @just = 'R'
                begin
                 select @frmtstring = SPACE(@count-DATALENGTH(@frmtstring)) + @frmtstring
                end
   
         /*    if @just = 'F'
                begin
                 /*don't do anything*/
                end */
          end
   
        if @separator <> 'N'
           select @frmtstring = @frmtstring + isnull(@separator,'')
   
        if @separator <> 'N'
           begin
            if substring(@leftover,1,1) = @separator
              select @leftover = RIGHT(@leftover,DATALENGTH(@leftover)-1)
           end
   
   
        if DATALENGTH(@nwformat) > 0
           begin
           --if @outstring=''
   		if @outstring is null
                 select @outstring=@frmtstring
              else
                 select @outstring = @outstring + @frmtstring
              select @instring = @leftover, @informat = @nwformat, @rcode = 0
           end
        else
           begin
   --           if @outstring=''
   			if @outstring is null
                 select @outstring=@frmtstring
              else
                 select @outstring = @outstring + @frmtstring
              select @instring = @leftover, @informat = @nwformat, @rcode = 0
           end
   end
   
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQFormatMultiPart] TO [public]
GO
