SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPCOApproveVal    Script Date: 8/28/99 9:33:05 AM ******/
CREATE  proc [dbo].[bspPMPCOApproveVal]
   /***********************************************************
    * CREATED BY:  bc 6/26/98
    * MODIFIED BY: bc 8/25/98
    *				TV 03/30/01
    *				GF 06/19/2002 - Issue #17496
    *				GF 01/20/2004 - issue #16548 - added Int/Ext flag to PMOP
	*				GF 10/30/2008 - issue #130772 expanded description to 60 characters.
    *				GF 09/05/2010 - changed to use function vfDateOnly
	*
    *
    * USAGE:
    *  Validates PM Pending Change Order number
    *  An error is returned if any of the following occurs
    * 	no company passed
    *	no project passed
    *	no matching ACO found in PMOH
    *
    * INPUT PARAMETERS
    *   PMCO- JC Company to validate against
    *   PROJECT- project to validate against
    *   ACO - Approved Change Order to validate
    *   PCO - Pending change order needed to default values from PMOP on new ACOs
    *   PCOType - PCO type needed to default values from PMOP on new ACOs
    *
    * OUTPUT PARAMETERS
    *	@desc - description
    * 	@approval_date	- defaults todays date or respective value in PMOH
    *	@addtl_days  - 0 or respective value in PMOH
    *	@seq  - respective value + 1 if new or value straight-up if already in PMOH
    *	@status - declares whether the ACO already exists in PMOH or is new
    *  @msg - error message if error occurs
    *	03/30/01- @addtl_days now shows sum of item enties
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @aco bACO = null, @pco bPCO = null,
 @pco_type bDocType = null, @desc varchar(60) = null output, @approval_date bDate output,
 @addtl_days smallint output, @seq int output, @status char(10) output,
 @intext char(1) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @addtl_days = 0, @seq = 1, @status = 'existing'

----#141031
set @approval_date = dbo.vfDateOnly()

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

---- Look for this ACO number in PMOH.  If it exists get values for defaults.  Otherwise use PMOP values
select @desc = Description, @approval_date = ApprovalDate, @seq = ACOSequence, @intext = IntExt
from PMOH with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
if @@rowcount = 0
   	begin
   	-- bring in defaults from PMOP
   	select @status = 'new'
   	select @desc = Description, @intext = IntExt,
   		   @seq = (select (isnull(max(ACOSequence),0) + 1) from PMOH where PMCo = @pmco and Project = @project)
   	from PMOP with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco
   	-- get sum ChangeDays from bPMOI for change order items
   	select @addtl_days = isnull(sum(ChangeDays),0)
   	from PMOI with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pco_type and PCO=@pco and ACO is null
   	end
else
   	begin
   	-- Displays sum of Change Days
   	select @addtl_days =sum(isnull(ChangeDays,0))
   	from PMOH with (nolock) where PMCo = @pmco and Project = @project and ACO = @aco
   	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOApproveVal] TO [public]
GO
