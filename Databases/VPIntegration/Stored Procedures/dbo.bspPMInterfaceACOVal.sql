SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************/
CREATE proc [dbo].[bspPMInterfaceACOVal]
/***********************************************************
* Created By:	GF 01/17/2002
* Modified By:	GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 02/14/2008 - issue #126936 added output parameter for PMOH.UniqueAttchID and New Flag
*
*
* USAGE:
* Validates PM Approved Change Order number for interface.
* Returns a message @acoexists warning if ACO or items exist
* in JC.
*
*
* INPUT PARAMETERS
*  PMCo		PM Company to validate against
*  Project		PM Project to validate against
*  ACO			Approved Change Order to validate
*
* OUTPUT PARAMETERS
* @acoexists	Warning message if ACO or Items exist in JC
* @newaco		Flag to indicate if ACO is new
* @pmohattachid	PMOH Unique Attachment Id
* @msg		error message if error occurs or description of ACO from PMOH
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @aco bACO = null, @acoexists varchar(500) = null output,
 @newaco bYN = 'N' output, @pmohattachid uniqueidentifier = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0

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

if @aco is null
	begin
	select @msg = 'Missing ACO!', @rcode = 1
	goto bspexit
	end

select @msg = Description, @pmohattachid = UniqueAttchID
from PMOH with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
if @@rowcount = 0
	begin
	select @msg = 'ACO not on file!', @rcode = 1
	goto bspexit
	end

---- check if ACO exists in JCOH
if not exists(select JCCo from JCOH with (nolock) where JCCo=@pmco and Job=@project and ACO=@aco)
	begin
	select @newaco = 'Y'
	goto bspexit
	end

select @acoexists = 'Change Order exists in JCOH.'

---- check if ACO Items exists in JCOI
select @validcnt=count(*)
from PMOI a with (nolock) 
join JCOI b with (nolock) on b.JCCo=a.PMCo and b.Job=a.Project and b.ACO=a.ACO and b.ACOItem=a.ACOItem
where a.PMCo=@pmco and a.Project=@project and a.ACO=@aco and b.JCCo=@pmco and b.Job=@project and b.ACO=@aco
if @validcnt = 0 goto bspexit

select @acoexists = isnull(@acoexists,'') + char(13) + 'Change Order Items exist in JCOI.'


bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'') 
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMInterfaceACOVal] TO [public]
GO
