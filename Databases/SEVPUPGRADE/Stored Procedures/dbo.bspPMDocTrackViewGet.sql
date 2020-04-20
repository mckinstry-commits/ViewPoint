SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE  proc [dbo].[bspPMDocTrackViewGet]
/*************************************
 * Created By:	GF 04/12/2007 6.x
 * Modified By:
 *
 *
 * verify and return valid document tracking view
 *
 *
 * Pass:
 * PM View Name
 *
 *
 * Success returns:
 *	0 and View Description
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@pmco bCompany = 0, @viewname varchar(10) = null, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @pmcoview varchar(10)

select @rcode = 0, @msg = ''

---- if missing view check PMCO.DocTrackView
if isnull(@viewname,'') = ''
	begin
	select @pmcoview=DocTrackView from PMCO with (nolock) where PMCo=@pmco
	if @@rowcount = 0 select @viewname='Viewpoint'
	end

---- verify view exists in PMVM
if not exists(select Description from PMVM with (nolock) where ViewName=@viewname)
	begin
	select @viewname = 'Viewpoint'
	end

select @msg = @viewname



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDocTrackViewGet] TO [public]
GO
