SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDocTypeVal    Script Date: 8/28/99 9:35:10 AM ******/
   CREATE    proc [dbo].[bspPMDocTypeVal]
   /*************************************
   * CREATED BY    : SAE  12/7/97
   * LAST MODIFIED : SAE  12/7/97
   *					GF 10/21/2004 - issue #24640 active only document types
   *					GF 09/06/2005 - issue #29758 set default for active flag parameter.
   *
   *
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
   (@doctype bDocType, @doccategory varchar(10)=null, @retcategory varchar(10) =null output, @active bYN = 'Y' output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @doctype is null and @doccategory <> 'PCO'
   	begin
   	select @msg = 'Missing document type!', @rcode = 1
   	goto bspexit
   	end
   
   if @doctype is null and @doccategory = 'PCO'
   	begin
   	select @msg = 'Missing Pending Change Order type!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @retcategory=DocCategory, @active=Active
   from bPMDT with (nolock) where DocType = @doctype
   if @@rowcount = 0
   	if @doccategory <> 'PCO'
   		begin
   		select @msg = 'PM Document type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
   		goto bspexit
   		end
   	else
   		begin
   		select @msg = 'PM Pending Change Order Type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
   		goto bspexit
   		end
   else
   	if @retcategory <> isnull(@doccategory,@retcategory)
   		begin
   		select @msg = 'Document category is ' + isnull(@retcategory,'') + '.  must be of category ' + isnull(@doccategory,''), @rcode = 1
   		goto bspexit
   		end
   
   
   
   -- -- -- if @active = 'N'
   -- -- -- 	begin
   -- -- -- 	select @msg = 'PM Document type: ' + isnull(@doctype,'') + ' is inactive!', @rcode = 1
   -- -- -- 	goto bspexit
   -- -- -- 	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDocTypeVal] TO [public]
GO
