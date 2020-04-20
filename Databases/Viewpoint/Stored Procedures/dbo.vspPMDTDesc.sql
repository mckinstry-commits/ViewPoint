SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDTDesc    Script Date: 04/13/2005 ******/
CREATE   proc [dbo].[vspPMDTDesc]
/*************************************
 * Created By:	GF 04/13/2005
 * Modified by:
 *
 * called from PMDocTypes to return doc type key description
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
(@doctype bDocType, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@doctype,'') <> ''
	begin
	select @msg = Description
	from PMDT with (nolock) where DocType = @doctype
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDTDesc] TO [public]
GO
