SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOValForPM    Script Date: 8/28/99 9:33:10 AM ******/
CREATE proc [dbo].[bspPOValForPM]
/***********************************************************
 * CREATED By:		CJW 2/23/98
 * MODIFIED By:		LM 2/3/99
 *					GF 07/30/2001 - Fixed to check status is open or pending
 *					GF 11/20/2006 - 6.x next po item
 *					GF 7/27/2011 - TK-07144 changed to varchar(30) 
 *					GP 4/3/2012 - TK-13774 added check against pending purchase order table
 *
 * USAGE:
 * validates PO, returns PO Description, Vendor, and Vendor Description
 * an error is returned if any of the following occurs
 *
 * INPUT PARAMETERS
 * PMCo			PM Company
 * PO			PO to validate
 * POCo			PO Co to validate against
 * Project		PM Project
 * Vendor		PO Vendor
 * VendorGroup	PO VendorGroup
 * NextPOItem	Next sequential item for PO.
 *
 *
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description of PO, Vendor, Vendor group, and Vendor Name
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @po VARCHAR(30) = null, @poco bCompany = 0, @project bJob = null, @vendor bVendor,
 @vendorgroup bGroup, @nextpoitem bItem output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @status int, @povendor bVendor, @povendorgroup bGroup, @pojob bJob,
		@pojcco bCompany, @maxpmmf bItem, @maxpoit bItem

select @rcode = 0, @status = 0

if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end

if @po is null
   	begin
   	select @msg = 'Missing PO!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @vendor is null
   	begin
   	select @msg = 'Missing Vendor!', @rcode = 1
   	goto bspexit
   	end

if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto bspexit
   	end

--Check pending purchase order table
if exists (select 1 from dbo.vPOPendingPurchaseOrder where POCo = @poco and PO = @po)
begin
	set @msg = 'Pending PO ' + @po + ' already exists.'
	return 1
end

---- if it is in POHD then it must have a status of pending or open
select @msg = Description, @povendor = Vendor, @povendorgroup = VendorGroup, @pojob=Job,
          @pojcco=JCCo, @status=Status
from POHD with (nolock) where POCo = @poco and PO = @po
if @@rowcount <> 0
	begin
	---- check to see if vendor entered matches the vendor in PM.
	if @povendor <> @vendor or @povendorgroup < > @vendorgroup
		begin
		select @msg = 'Vendor entered does not match vendor in PO. ', @rcode = 1
		goto bspexit
		end
	---- check status is 0,3 - open or pending
	if @status not in (0,3)
		begin
		select @msg = 'PO must be open or pending!', @rcode = 1
		goto bspexit
		end
	end



---- get maximum po Item from PMMF
select @maxpmmf = max(POItem) from PMMF with (nolock) where POCo=@poco and PO=@po
if @maxpmmf is null select @maxpmmf = 0
-- -- -- get maximum PO Item from POIT
select @maxpoit = max(POItem) from POIT with (nolock) where POCo=@poco and PO=@po
if @maxpoit is null select @maxpoit = 0
-- -- -- set @nextslitem to larger of two plus one
if @maxpmmf > @maxpoit
	select @nextpoitem = @maxpmmf + 1
else
	select @nextpoitem = @maxpoit + 1



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValForPM] TO [public]
GO
