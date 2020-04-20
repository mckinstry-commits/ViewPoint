SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[bfMuliPartFormat](@instring varchar(50) = null, @informat varchar(30)= null)
      returns varchar(50)
      as
      begin
  	/***********************************************************
   	* CREATED BY: DANF 02/13/02
   	* MODIFIED By :
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
  	declare @count int, @just char(1), @separator char(1), @nwformat varchar(50),
  	@leftover varchar(50), @frmtstring varchar(50), @cut int, @outstring varchar(50)
  
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
  
          	  select @outstring = null
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
      if @frmtstring is null
         select @frmtstring = ''
  
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
          select @frmtstring = @frmtstring + @separator
  
  
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
  	return(@outstring)
      end

GO
GRANT EXECUTE ON  [dbo].[bfMuliPartFormat] TO [public]
GO
