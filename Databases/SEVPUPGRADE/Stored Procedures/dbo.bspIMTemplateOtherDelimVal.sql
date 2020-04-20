SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMTemplateOtherDelimVal]
   /************************************************************************
   * CREATED:    MH 11/22/00    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate the 'Other' delimiter entered in IMTemplate.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@testchar varchar(100), @msg varchar(100) = '' output)
   
   
   
   as
   set nocount on
   
       declare @rcode int, @charval int
   
       select @rcode = 0
   
       if @testchar is null
           begin
               select @msg = 'Other delimiter not specified.', @rcode = 1
               goto bspexit
           end
   
       if len(@testchar) < 2
           begin
               select @charval = (select ascii(@testchar))
   
               if @charval = 124
                   begin
                       select @msg = 'Other delimiter entered was a pipe.', @rcode = 1
                       goto bspexit
                   end
   
               if @charval = 32
                   begin
                       select @msg = 'Other delimiter entered was a space.', @rcode = 1
                       goto bspexit
                   end
   
               if @charval = 44
                   begin
                       select @msg = 'Other delimiter entered was a comma.', @rcode = 1
                       goto bspexit
                   end
   
               if @charval = 59
                   begin
                       select @msg = 'Other delimiter entered was a semicolon.', @rcode = 1
                       goto bspexit
                   end
   
               if @charval = 9
                   begin
                       select @msg = 'Other delimiter entered was a tab.', @rcode = 1
                       goto bspexit
                   end
           end
   
   bspexit:
   
       if @rcode = 1
           begin
               if @testchar is not null
                   select @msg = isnull(@msg,'Other') + char(13) + 'Please select a predefined delimiter.'
           end
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateOtherDelimVal] TO [public]
GO
