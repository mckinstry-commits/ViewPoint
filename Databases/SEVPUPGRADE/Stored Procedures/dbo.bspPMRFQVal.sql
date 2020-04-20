SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPMRFQVal]
/***********************************************************
 * Created By:	GF 01/25/2007
 * Modified By:	GF 03/21/2008 - issue #127299 added RFQDate as output parameter
 *
 *
 * USAGE:
 * Validates PM Pending Change Order RFQ
 * An error is returned if any of the following occurs
 *
 * no company passed
 * no project passed
 * no pco type passed
 * no pco passed
 * no RFQ found in PMRQ
 *
 * INPUT PARAMETERS
 * PMCO- JC Company to validate against
 * PROJECT- project to validate against
 * PCOTYPE - PCO Type to validate against
 * PCO - Pending Change Order to against
 * RFQ - RFQ to validate
 *
 * OUTPUT PARAMETERS
 * RFQ Date
 * @msg - error message if error occurs otherwise Description of RFQ in PMRQ
 *  
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
*****************************************************/
(@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null,
 @pco bPCO = null, @rfq bDocument = null, @rfqdate bDate = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

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

if @pcotype is null
   	begin
   	select @msg = 'Missing PCO Type!', @rcode = 1
   	goto bspexit
   	end

if @pco is null
   	begin
   	select @msg = 'Missing PCO!', @rcode = 1
   	goto bspexit
   	end

if @rfq is null
   	begin
   	select @msg = 'Missing RFQ!', @rcode = 1
   	goto bspexit
   	end

---- validate RFQ
select @msg = Description, @rfqdate=RFQDate
from PMRQ with (nolock) where PMCo = @pmco and Project = @project
and PCOType=@pcotype and PCO=@pco and RFQ=@rfq
if @@rowcount = 0
   	begin
   	select @msg = 'RFQ not on file!', @rcode = 1
   	goto bspexit
   	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMRFQVal] TO [public]
GO
