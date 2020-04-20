SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMWPUniqueVal    Script Date: 8/28/99 9:36:27 AM ******/
CREATE  proc [dbo].[bspPMWPUniqueVal]
/*************************************
 * Created By:	GF 06/17/99
 * Modified By:	GF 05/25/2006 6.x
 *				GF 11/28/2008 - issue #131100 expanded phase description
 *
   *
   * Pass:
   *	ImportId, Sequence, Item
   * Returns:
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
(@importid varchar(10) = Null, @sequence int = Null, @phase bPhase = Null,
 @pmco bCompany = Null, @phasegroup bGroup = Null, @phase_desc bItemDesc = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @job bJob, @pmsg varchar(255)

select @rcode = 0, @job=null, @phase_desc = null

if @importid is null
       begin
       select @msg = 'ImportId is missing!', @rcode = 1
       goto bspexit
       end

if @phase is null
       begin
       select @msg = 'Phase is missing!', @rcode = 1
       goto bspexit
       end

if @pmco is null
       begin
       select @msg = 'PM Company is missing', @rcode = 1
       goto bspexit
       end

if @phasegroup is null
       begin
       select @msg = 'Phase Group is missing', @rcode = 1
       goto bspexit
       end

if isnull(@sequence,0) = 0
	begin
	if exists (select * from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase)
		begin
		select @msg = 'Phase already exists', @rcode=1
		goto bspexit
		end
	end
else
	begin
	if exists (select * from bPMWP where PMCo=@pmco and ImportId=@importid and Phase=@phase and Sequence<>@sequence)
		begin
		select @msg = 'Phase already exists', @rcode=1
		goto bspexit
		end
	end

exec @rcode = dbo.bspJCPMValUseValidChars @pmco, @phasegroup, @phase, @job, @msg output
if @rcode = 0 select @phase_desc = @msg



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMWPUniqueVal] TO [public]
GO
