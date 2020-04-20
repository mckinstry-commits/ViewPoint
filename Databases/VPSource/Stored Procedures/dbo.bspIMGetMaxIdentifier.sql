SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMGetMaxIdentifier]
   /************************************************************************
   * CREATED:    MH 6/27/00    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Get the max identifier from IMTD    
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
       (@template varchar(10) = null, @recordtype varchar(30) = null, @identifier int output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       if @template is null
           begin
               select @msg = 'Missing Import Template', @rcode = 1
               goto bspexit
           end
       
       if @recordtype is null
           begin
               select @msg = 'Missing Record Type', @rcode = 1
               goto bspexit
           end
   
       select @identifier = isnull((select max(Identifier) from IMTD where ImportTemplate = @template and RecordType = @recordtype), 0)
         
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMGetMaxIdentifier] TO [public]
GO
