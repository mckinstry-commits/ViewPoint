SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMTMDesc Script Date: 08/17/2005 ******/
CREATE proc [dbo].[vspPMTMDesc]
/*************************************
 * Created By:	GF 08/17/2005
 * Modified by:
 *
 * called from PMTransmittal to return key description.
 *
 *
 * Pass:
 * PMCo				PM Company
 * Project			PM Project
 * Transmittal		PM Transmittal
 *
 *
 * Returns:
 * 
 * Success returns:
 *	0 and Description from PMTM
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@pmco bCompany, @project bJob = null, @transmittal bDocument = null,
 @createflag bYN = 'N', @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- if @create flag <> 'Y' then get description only. no validation
if @createflag = 'N'
	begin
	if isnull(@transmittal,'') <> ''
		begin
		select @msg = Subject
		from PMTM with (nolock) where PMCo=@pmco and Project=@project and Transmittal=@transmittal
		end
	goto bspexit
	end

---- if @create flag = 'Y' then validate also
if @createflag = 'Y'
	begin
	if exists(select * from PMTM with (nolock) where PMCo=@pmco and Project=@project and Transmittal=@transmittal)
		begin
		select @msg = 'Must be a new transmittal.', @rcode = 1
		goto bspexit
		end
	select @msg = 'New Transmittal'
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTMDesc] TO [public]
GO
