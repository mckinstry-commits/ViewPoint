SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMDocObjectColumnListFill]
/****************************************************************************
 * Created By:	GF 02/12/2007 6.x
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns a resultset of Object Table columns for the object table.
 * Used in the PMDocTempSelect form to populate list view.
 *
 * INPUT PARAMETERS:
 * ObjectTable		Document object table
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@objecttable varchar(30) = null)
as
set nocount on

declare @rcode int

select @rcode = 0

select 'Name' = COLUMN_NAME 
from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @objecttable
order by COLUMN_NAME




bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocObjectColumnListFill] TO [public]
GO
