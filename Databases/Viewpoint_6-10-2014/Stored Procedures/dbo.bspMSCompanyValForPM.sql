SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE    proc [dbo].[bspMSCompanyValForPM]
/*************************************
   * Created By:   GF 02/05/2001
   * Modified By:
   *
   * validates MS Company number and returns Description from HQCo
   *
   * Pass:
   * 	MSCo	MS Company number
   *	PMCo	PM company number
   *	Project	PM project
   *
   * Success returns:
   *	MatlGroup	MS company material group
   *	MS Quote	MS Quote if one exists for PMCo and Project
   *	0 and Company name from HQCo
   *
   * Error returns:
   *	1 and error message
 **************************************/
(@msco bCompany = 0, @pmco bCompany = 0, @project bJob = null,
 @matlgroup bGroup output, @quote varchar(10) output, @msg varchar(255) output)
as
set nocount on
declare @rcode int

select @rcode = 0

if isnull(@msco,0) = 0
   	begin
   	select @msg = 'Missing MS Company', @rcode = 1
   	goto bspexit
   	end

if isnull(@pmco,0) = 0
   	begin
   	select @msg = 'Missing PM company', @rcode = 1
   	goto bspexit
   	end

if isnull(@project,'') = ''
   	begin
   	select @msg = 'Missing PM project', @rcode = 1
   	goto bspexit
   	end

---- get MS company info
if not exists(select * from bMSCO with (nolock) where MSCo=@msco)
	begin
   	select @msg = 'Not a valid MS Company', @rcode = 1
   	goto bspexit
   	end

---- get HQ company info
select @msg=Name, @matlgroup=MatlGroup
from bHQCO with (nolock) where HQCo=@msco
if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid HQ company', @rcode = 1
   	goto bspexit
   	end

---- get default quote if exists for PMCo,Project
select @quote=Quote from bMSQH with (nolock) 
where MSCo=@msco and QuoteType='J' and JCCo=@pmco and Job=@project






bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSCompanyValForPM] TO [public]
GO
