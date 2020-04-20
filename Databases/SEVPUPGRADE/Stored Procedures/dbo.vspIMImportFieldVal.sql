SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspIMImportFieldVal]
 /************************************************************************
 * CREATED:    MH 4/4/00    
 * MODIFIED:   DANF 10/19/06 recode for 6.x
 *
 * Purpose of Stored Procedure
 *    Valadate an import field to be used in an import cross reference
 *    exists in IMTD for that particular Import Template.  If the import
 *    field exists, return the column description.
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
 
     (@template varchar(30) = null, @identifier int = null, @msg varchar(80) = '' output)
 
 as
 set nocount on
 
     declare @rcode int
  
     select @rcode = 0
 
     if @template is null
     begin
         select @msg = 'Missing Template', @rcode = 1            
         goto bspexit
     end
 
     if @identifier is null
     begin
         select @msg = 'Missing Import Field Identifier', @rcode = 1
         goto bspexit
     end
 
     --Validate Identifier
     select @msg = ColDesc from IMTD where ImportTemplate = @template and Identifier = @identifier
 
     if @@rowcount > 0
     --Identifier existed.  May or may not have a description associated.
     begin
         if @msg is null
         begin
             select @msg = 'No description listed.'
         end
     end
     else
     begin
         --Identifier did not exist for this template
         select @msg = 'Identifier does not exist.', @rcode = 1
         goto bspexit
     end
 
 
 bspexit:
 
     if @rcode = 1
     begin
         select @msg = isnull(@msg,'Field Val') + char(13) + char(13) + '[vspIMImportFieldVal]'
     end
 
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspIMImportFieldVal] TO [public]
GO
