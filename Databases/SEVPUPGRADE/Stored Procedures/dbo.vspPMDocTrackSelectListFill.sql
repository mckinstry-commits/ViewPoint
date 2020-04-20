SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspPMDocTrackSelectListFill]
/****************************************************************************
 * Created By:	GF 03/07/2007 6.x
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Returns a resultset of PM Document Tracking Views..
 * Used in the PMDocTrack under tools to select a different view.
 *
 * INPUT PARAMETERS:
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
as
set nocount on

declare @sql varchar(1000)

--select @sql = 'select a.ViewName, a.Description from dbo.PMVM a'
--select @sql = @sql + ' order by a.ViewName, a.Description'
--
--exec (@sql)

select @sql = 'select a.ViewName, a.Description from dbo.PMVM a'
select @sql = @sql + ' UNION '
select @sql = @sql + 'select ' + char(39) + 'Viewpoint' + char(39) + ', ' + char(39) + 'Default View' + char(39) + ' from dbo.PMVM b where 1=1'
select @sql = @sql + ' order by a.ViewName'

exec (@sql)

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackSelectListFill] TO [public]
GO
