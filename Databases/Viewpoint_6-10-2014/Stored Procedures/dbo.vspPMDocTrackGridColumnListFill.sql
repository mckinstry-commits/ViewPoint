SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspPMDocTrackGridColumnListFill]
/****************************************************************************
 * Created By:	GF 03/27/2007 6.x
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns a resultset of Document Tracking Grid Columns for a grid form.
 * Used in the PMDocTrackViewGridOrder form to reorder grid columns.
 *
 * INPUT PARAMETERS:
 * ViewName		Document View Name
 * GridForm		Document View Grid Form
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@viewname varchar(10) = null, @gridform varchar(30) = null)
as
set nocount on

declare @rcode int

select @rcode = 0

select 'Column Name' = ColTitle ----, 'Column' = GridCol
from PMVC where ViewName=@viewname and Form=@gridform
order by GridCol,ColTitle




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackGridColumnListFill] TO [public]
GO
