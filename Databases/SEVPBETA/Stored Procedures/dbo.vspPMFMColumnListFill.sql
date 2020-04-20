SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMFMColumnListFill]
/****************************************************************************
 * Created By:	GF 06/12/2009
 * Modified By:
 *
 *
 *
 *
 *
 * USAGE:
 * Returns a resultset of column names for PMFM - Firm master
 * Used in the PMDocCatOver form to populate PMFM list view.
 *
 * INPUT PARAMETERS:
 * PM Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany = null)
as
set nocount on

declare @rcode int

select @rcode = 0

---- return resultset of PMFM Column Names
select 'PMFM.' + COLUMN_NAME
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'PMFM'
and COLUMN_NAME not in ('VendorGroup','Notes','UniqueAttchID','UpdateAP','KeyID','ExcludeYN')
order by COLUMN_NAME


bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMFMColumnListFill] TO [public]
GO
