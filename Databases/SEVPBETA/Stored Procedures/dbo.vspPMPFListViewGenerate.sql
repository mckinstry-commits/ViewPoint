SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMPFListViewGenerate]
/****************************************************************************
 * Created By:	GP 06/18/2009
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns a resultset with information on the structure of the PMPF List View
 *
 * INPUT PARAMETERS:
 * DocCat
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@DocCat varchar(10) = null)
as
set nocount on

declare @rcode int

select @rcode = 0
	

select ColumnAlias, Visible
from dbo.PMLS with (nolock)
where DocCat = @DocCat
order by KeyID


bspexit:
   	return @rcode	

GO
GRANT EXECUTE ON  [dbo].[vspPMPFListViewGenerate] TO [public]
GO
