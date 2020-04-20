SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspPMDocMergeColumnListFill]
/****************************************************************************
 * Created By:	GF 04/28/2007 6.x
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns a resultset of Document Merge Columns to populate a list box.
 * Used in the PMDocTemplatesMergeOrder form to reorder merge columns.
 *
 * INPUT PARAMETERS:
 * Template		Document Template
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@template varchar(40) = null, @wordtableyn bYN = 'N')
as
set nocount on

declare @rcode int

select @rcode = 0

select 'Column Name' = MergeFieldName
from HQWF where TemplateName=@template and WordTableYN=@wordtableyn
order by MergeOrder, MergeFieldName




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocMergeColumnListFill] TO [public]
GO
