SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspParseString]
   /************************************************************************
   * CREATED:  MH 2/21/00  
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Parse a delimited string and return position of delimiter, characters from position
   *    1 to delimiter, and the remaining delimited string minus the first delimiter.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
           --Parameter list goes here
       (@instringlist varchar(8000), @char char(1), @delimpos int output, @retstring varchar(8000) output, 
       @retstringlist varchar(8000) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
           --Local variable declarations list goes here
   
   declare @strlen int, @rcode int
   
   
       if @instringlist is null
           begin
               select @msg = 'Missing string list.  Nothing to parse.', @rcode = 1
               goto bspexit
           end
   
       if @char is null
           begin
               select @msg = 'Missing delimiter.', @rcode = 1
               goto bspexit
           end
   
       
       select @delimpos = (select patindex('%' + @char + '%' , @instringlist))
   
       if @delimpos > 0
           begin
               select @strlen = (select len(@instringlist))
   
               select @retstring = left(@instringlist, (@delimpos - 1))
   
               select @retstringlist = substring(@instringlist,(@delimpos + 1), (@strlen) - (@delimpos))
           end    
   
       else
           begin
               select @retstring = @instringlist
           end
   
       select @rcode = 0
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspParseString] TO [public]
GO
