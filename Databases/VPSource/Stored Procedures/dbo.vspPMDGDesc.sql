SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDGDesc    Script Date: 08/02/2005 ******/
CREATE  proc [dbo].[vspPMDGDesc]
/*************************************
 * Created By:	GF 08/02/2005
 * Modified by:
 *
 * called from PMDrawingLogs to return Drawing View key description
 *
 * Pass:
 * PMCo				PM Company
 * Project			PM Project
 * DrawingType		PM Drawing Type
 * Drawing			PM Drawing
 * 
 * Returns:
 * Description
 *
 * Success returns:
 *	0 and Description from PMDG
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob, @drawingtype bDocType, @drawing bDocument, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@drawing,'') <> ''
	begin
	select @msg = Description
	from PMDG with (nolock) where PMCo=@pmco and Project=@project and DrawingType=@drawingtype and Drawing=@drawing
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDGDesc] TO [public]
GO
