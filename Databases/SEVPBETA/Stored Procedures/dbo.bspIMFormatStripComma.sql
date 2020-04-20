SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMFormatStripComma]
   /************************************************************************
   * CREATED:  MH 8/17/00    
   * MODIFIED: CC 3/19/2008 - Issue #122980 add support for notes/large fields   
   *
   * Purpose of Stored Procedure
   *
   *  Strip the commas from a string.  For example, a string
   *  '1,000,000.00' will be converted to '1000000.00'.      
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@invalue varchar(max), @outvalue varchar(max) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @count int
   
       select @rcode = 0
   
       select @outvalue = @invalue
   
       select @count = (select charindex(',', @outvalue))
   
       while @count > 0
           begin
   
               select @outvalue = (select left(@outvalue, (charindex(',', @outvalue) - 1))) + (select substring(@outvalue, (select charindex(',', @outvalue) + 1), (select Len(@outvalue) - 2)))
   
               select @count = (select charindex(',', @outvalue))
   
           end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMFormatStripComma] TO [public]
GO
