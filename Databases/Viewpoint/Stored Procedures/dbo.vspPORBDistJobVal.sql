SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************/
CREATE  proc [dbo].[vspPORBDistJobVal]
/***********************************************************
* CREATED BY:	GF 04/23/2011
* MODIFIED By:
*
*
* USAGE:
* validates PO Receiving Distribution job using the standard job validation.
* an error is returned if any of the following occurs
*
* INPUT PARAMETERS
* JCCo   JC Co to validate agains
* Job    Job to validate
*
* OUTPUT PARAMETERS
* @JobStatus
* @LockPhases

*   @msg      error message if error occurs otherwise Description of EarnCode
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@JCCo bCompany = NULL, @Job bJob = null,
 @JobStatus TINYINT  = NULL OUTPUT, @LockPhases CHAR(1) = NULL OUTPUT,
 @Msg varchar(255) output)
AS
SET NOCOUNT ON
   
DECLARE @rcode INT, @Contract bContract, @ErrMsg VARCHAR(255),
		@TaxCode bTaxCode, @Description bItemDesc
   
SET @rcode = 0
   
if @JCCo is null
	begin
	select @Msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @Job is null
	begin
	select @Msg = 'Missing Job!', @rcode = 1
	goto bspexit
	end

---- validate job exists
SELECT @Description = Description
from dbo.JCJM where JCCo = @JCCo AND @Job=@Job
IF @@rowcount = 0
	begin
	select @Msg='Invalid Job!', @rcode=1
	goto bspexit
	end 

---- validate job status
exec @rcode = dbo.bspJCJMPostVal @JCCo, @Job, @Contract output, @JobStatus output,
			@LockPhases output, @TaxCode output, @Msg = @ErrMsg output
if @rcode = 1
	begin
	select @Msg = @ErrMsg
	goto bspexit
  	end

if @JobStatus < 1
	begin
	select @Msg='Job status cannot be (Pending)', @rcode=1
	goto bspexit
	end


SET @Msg = @Description




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPORBDistJobVal] TO [public]
GO
