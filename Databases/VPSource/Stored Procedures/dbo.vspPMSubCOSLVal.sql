SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMSubCOSLVal    Script Date: 8/28/99 9:35:19 AM ******/
CREATE  proc [dbo].[vspPMSubCOSLVal]
/***********************************************************
 * Created By:	GF 03/16/2011 - TK-09613
 * Modified By:	DAN SO 05/12/2011 - TK-05178
 *				GF 11/02/2011 TK-09613 allow SCO for project to SL setup under another.
 *
 *
 * USAGE:
 * validates SL to SLHD for Subcontract Change Orders.
 * Must be approved and pending or open status against SLHD
 *
 * INPUT PARAMETERS
 * SLCo			SL Co to validate against
 * PMCo			PM Company
 * Project		PM Project
 * SL			SL to Validate
 *
 * OUTPUT PARAMETERS
 *   @msg
 * RETURN VALUE
 *   0         success
 *   1         Failure  'if Fails THEN it fails.
 *****************************************************/
(@slco bCompany = 0, @pmco bCompany, @project bJob, @SL VARCHAR(30),
 ---- TK-05178
 @VendorGroup bGroup = NULL OUTPUT, @Vendor bVendor = NULL OUTPUT,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @JCCo bCompany, @Job bJob,
		@Approved VARCHAR(1), @Status TINYINT

SET @rcode = 0

-- -- -- get description for SLHD
select @msg = Description, @JCCo = JCCo, @Job = Job,
		@Approved=Approved, @Status=Status,
		---- TK-04967
		@VendorGroup = VendorGroup, @Vendor = Vendor
from dbo.SLHD with (nolock)
WHERE SLCo=@slco AND SL=@SL
if @@rowcount = 0
	begin
	select @msg = 'Subcontract not on file', @rcode = 1
	goto bspexit
	end

IF @Status NOT IN (0,3)
	BEGIN
	SELECT @msg = 'Subcontract must be Open or Pending!', @rcode = 1
	GOTO bspexit
	END

IF @Approved = 'N'
	BEGIN
	SELECT @msg = 'Subcontract must be Approved!', @rcode = 1
	GOTO bspexit
	END

IF ISNULL(@JCCo,0) <> @pmco
	BEGIN
	SELECT @msg = 'Subcontract already exists for JCCo: ' + isnull(convert(varchar(3),@JCCo),'') + ' .', @rcode = 1
	GOTO bspexit
	END

----TK-09613
----if isnull(@JCCo,0) <> @pmco or isnull(@Job,'') <> @project
----	begin
----	select @msg='Subcontract already exists for JCCo: ' + isnull(convert(varchar(3),@JCCo),'') + ' and Job: ' + isnull(@Job,'') + '!', @rcode = 1
----	goto bspexit
----	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubCOSLVal] TO [public]
GO
