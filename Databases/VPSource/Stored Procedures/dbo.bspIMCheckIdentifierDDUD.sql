SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMCheckIdentifierDDUD]
   /************************************************************************
   * CREATED:    MH  6/27/00    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Check DDUD for existance of an identifier for a form.  Used by 
   *    IMTemplateDetail to determine if a record in the grid may be 
   *    deleted.     
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
           (@form varchar(30), @identifier int, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       if @form is null
           begin 
               select @msg = 'Missing Form Name!', @rcode = 1
               goto bspexit
           end
   
       if @identifier is null
           begin
               select @msg = 'Missing Identifier!', @rcode = 1
               goto bspexit
           end
       
       if exists(select * from DDUD where Form = @form and Identifier = @identifier)
           select @rcode = 1, @msg = 'Identifier exists in DDUD.  Cannot delete.'
               
   
   bspexit:
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMCheckIdentifierDDUD] TO [public]
GO
