SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspIMTemplateCopyDestVal]
   /************************************************************************
   * CREATED:  mh 10/20/00
   * MODIFIED:
   *
   * Purpose of Stored Procedure
   *
   *   Verify that a destination template does not already exist.
   *
   *
   * Notes about Stored Procedure
   *
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@desttemplate varchar(30) = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
       if @desttemplate is null
           begin
               select @msg = 'Missing destination template', @rcode = 1
               goto bspexit
           end
   
       if (select count(*) from IMTH where ImportTemplate = @desttemplate) > 0
           begin
               select @msg = 'Cannot copy into existing template.', @rcode = 1
               goto bspexit
           end
       else
           select @msg = isnull(@desttemplate,'')
   
   
   bspexit:
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMTemplateCopyDestVal] TO [public]
GO
