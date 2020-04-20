SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE  proc [dbo].[bspINMOValForPM]
/***********************************************************
 * CREATED By:	GF 02/13/02
 * MODIFIED By:	GF 11/20/2006 6.x next item
 *
 *
 * USAGE:
 * validates MO, returns MO Description
 * an error is returned if any of the following occurs
 *
 * INPUT PARAMETERS
 * PMCo		PM Company to validate against
 * Project	PM Project to validate against
 * INCo		IN Company to validate against
 * MO		to validate
 * NextMOItem	Next IN MO Item
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description of MO
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = null, @project bJob = null, @inco bCompany = null, @mo varchar(10) = null, 
 @nextmoitem bItem output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @status int, @mojob bJob, @mojcco bCompany, @maxpmmf bItem, @maxinmi bItem

select @rcode = 0, @status = 0

if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @inco is null
   	begin
   	select @msg = 'Missing IN Company!', @rcode = 1
   	goto bspexit
   	end

if @mo is null
   	begin
   	select @msg = 'Missing MO!', @rcode = 1
   	goto bspexit
   	end

---- if it is in INMO then it must have a status of pending or open
select @msg = Description, @mojob=Job, @mojcco=JCCo, @status=Status
from INMO where INCo = @inco and MO = @mo
if @@rowcount <> 0
	begin
	---- check to see if job entered matches the project in PM
	if @mojob <> @project or @mojcco <> @pmco
		begin
		select @msg = 'MO ' + isnull(@mo,'') + ' already exists on a different Project. ', @rcode = 1
		goto bspexit
		end
	---- check status is 0,3 - open or pending
	if @status not in (0,3)
		begin
		select @msg = 'MO must be open or pending!', @rcode = 1
		goto bspexit
		end
	end


---- get maximum IN MO Item from PMMF
select @maxpmmf = max(MOItem)
from PMMF with (nolock) where PMCo=@pmco and INCo=@inco and MO=@mo
if @maxpmmf is null select @maxpmmf = 0
---- get maximum IN MO Item from INMI
select @maxinmi = max(MOItem) from INMI with (nolock) where INCo=@inco and MO=@mo
if @maxinmi is null select @maxinmi = 0
---- set @nextmoitem to larger of two plus one
if @maxpmmf > @maxinmi
	select @nextmoitem = @maxpmmf + 1
else
	select @nextmoitem = @maxinmi + 1



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOValForPM] TO [public]
GO
