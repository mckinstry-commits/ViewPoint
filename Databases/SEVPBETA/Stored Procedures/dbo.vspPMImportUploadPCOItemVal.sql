SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImportUploadPCOItemVal	Script Date: 06/07/2006 ******/
CREATE proc [dbo].[vspPMImportUploadPCOItemVal]
/***********************************************************
 * Created By:	GF 12/04/2006 6.x issue #27450
 * Modified By:
 *
 *
 * USAGE:
 * Validates PM PCO Item for PM import upload form.
 *
 *
 *
 * INPUT PARAMETERS
 * PMCO			PM Company 
 * Project		PM Project
 * PCOType		PM PCO Type
 * PCO			PM PCO to validate
 * PCOItem		PM PCO Item to validate
 *
 *
 * OUTPUT PARAMETERS
 *
 *
 * @msg - error message if pco item exists in PMOI
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/ 
(@pmco bCompany = 0, @project bJob = null, @pcotype bDocType = null,
 @pco varchar(10) = null, @pcoitem varchar(10) = null,
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

if @pcoitem is null
	begin
   	select @msg = 'Missing PCO Item!', @rcode = 1
   	goto bspexit
   	end

---- if @pcoitem if not null must not exist in PMOI
if exists(select * from PMOI with (nolock) where PMCo=@pmco and Project=@project
				and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem)
	begin
	select @msg = 'Invalid PCO Item, already exists for PCO.', @rcode = 1
	goto bspexit
	end




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportUploadPCOItemVal] TO [public]
GO
