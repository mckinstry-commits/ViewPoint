SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDocTypeValExistsInPMOI    Script Date: 8/28/99 9:35:10 AM ******/
   CREATE   proc [dbo].[bspPMDocTypeValExistsInPMOI]
   /*************************************
   * CREATED BY    : CJW
   * LAST MODIFIED : CJW
   * validates PM Firm Types
   *
   * Pass:
   *	PM Document Type
   *       Document Category, or Null if any ok
   * Returns:
   *      Document Category
   *      Description
   * Success returns:
   *	0 and Description from DocumentType
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   (@pmco bCompany, @project bProject, @doctype bDocType, @doccategory varchar(10)=null, 
    @retcategory varchar(10) =null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @doctype is null
   	begin
   	select @msg = 'Missing document type!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @retcategory=DocCategory 
   from bPMDT with (nolock) where DocType = @doctype
   if @@rowcount = 0
   	begin
   	select @msg = 'PM Document type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
   	goto bspexit
   	end
   else
      if @retcategory <> isnull(@doccategory,@retcategory)
         begin
         select @msg = 'Document type is ' + isnull(@retcategory,'') + '.  must be of type ' + isnull(@doccategory,''), @rcode = 1
         goto bspexit
         end
   
   
   if (select count(*) from bPMOI with (nolock) where PMCo = @pmco and Project = @project and PCOType = @doctype) = 0 
   	begin
       select @msg = 'Document type does not exist in PMOI for this company', @rcode = 1
       goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDocTypeValExistsInPMOI] TO [public]
GO
