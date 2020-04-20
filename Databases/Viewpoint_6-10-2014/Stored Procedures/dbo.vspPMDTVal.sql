SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspPMDTVal]
/*************************************
 * Created By:	GP 7/9/2010
 * Modified by:
 *
 * Returns description of doc type and validates that it exists.
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
 * 
 *	1 and error message
 **************************************/
(@DocType bDocType, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if not exists (select top 1 1 from PMDT with (nolock) where DocType = @DocType)
begin
   	select @msg = 'Document Type does not exist!', @rcode = 1
   	goto vspexit	
end
else
begin
	select @msg = Description from PMDT with (nolock) where DocType = @DocType
end	



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDTVal] TO [public]
GO
