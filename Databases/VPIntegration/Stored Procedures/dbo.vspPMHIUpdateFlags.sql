SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspPMHIUpdateFlags]
/*******************************
 * Created By:	GF 04/22/2008 6.x
 * Modified By:
 *
 *
 * Purpose of stored procedure is to update PMHI Printed, Emailed, or Faxed flags
 * when one of the processes occurs in PM Document Create and Send form
 *
 *******************************/
(@pmco bCompany, @pmdzkeyid bigint, @typeofprocess varchar(1),
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @pmdoccreateauditid bigint

select @rcode = 0

---- get keyid for the distribution record
select @pmdoccreateauditid=PMHIKeyId
from PMDZ with (nolock) where KeyID=@pmdzkeyid
if @@rowcount = 0
	begin
	select @msg = 'Error reading create and send information. Cannot add audit.', @rcode = 1
	goto bspexit
	end

---- update PMHI (audit info) record
if @typeofprocess = 'E'
	begin
	update PMHI set Emailed = 'Y'
	where KeyId=@pmdoccreateauditid
	end
if @typeofprocess = 'F'
	begin
	update PMHI set Faxed = 'Y'
	where KeyId=@pmdoccreateauditid
	end
if @typeofprocess = 'P'
	begin
	update PMHI set Printed = 'Y'
	where KeyId=@pmdoccreateauditid
	end


bspexit:
  	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMHIUpdateFlags] TO [public]
GO
