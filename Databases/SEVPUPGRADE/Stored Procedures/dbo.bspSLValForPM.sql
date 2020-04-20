SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspSLValForPM    Script Date: 8/28/99 9:33:42 AM ******/
CREATE proc [dbo].[bspSLValForPM]
/***********************************************************
 * CREATED By:	CJW 7/1/98
 * MODIFIED BY: LM 2/3/99 - Fixed to properly validate SL in SLHD - unique by SLCo
 *              GF 07/30/2001 - Fixed to only allow status of open or pending.
 *				GF 03/30/2006 - added @nextslitem as output for 6.x, was done via query statement in 5.x
 *				GF 11/28/2007 - issue #124780 allow for null vendor and return SLVendor as output param.
 *				GF 02/16/2010 - issue #136053 subcontract prebilling
 *				DC 06/25/10 - #135813 - expand subcontract number
 *				Dan S0 06/07/2011 - TK-05850 - added flag to use proc for PMPCOSItemsDetail SL validation
 *				GF 06/18/2011 - TK-00000
 *				NH 07/17/2012 - TK-16262 - changed the default status from 0 (open) to 3 (pending)
 *
 * USAGE:
 * validates SL, returns SL Description
 * an error is returned if any of the following occurs
 *
 * INPUT PARAMETERS
 *   SLCo  SL Co to validate against
 *   SL to validate
 *   Project
 *   Vendor Group
 *   Vendor
 *
 * OUTPUT PARAMETERS
 * @nextslitem		Next sequential SL Item from SLIT
 * @slvendor		vendor assigned to subcontract
 * @origdate		SL original date
 * @SLExistsYN		Does the SL Exist?
 * @msg      error message if error occurs otherwise Description of SL, Vendor, Vendor group, and Vendor Name
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = 0, @slco bCompany = 0, @sl VARCHAR(30) = NULL,
 @project bJob = null, @vendor bVendor = null,
 @vendorgroup bGroup, @PCOSItemDetailYN char(1) = NULL, 
 @nextslitem bItem output, @slvendor bVendor output,
 @origdate bDate = null output, @status tinyint = NULL output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @slvendorgroup bGroup, @maxpmsl bItem, @maxslit bItem,
		----TK-00000
		@Approved CHAR(1)

select @rcode = 0, @status = 3, @maxpmsl = 0, @maxslit = 0, @nextslitem = 0

if @slco is null
   	begin
   	select @msg = 'Missing SL Company!', @rcode = 1
   	goto bspexit
   	end

if @sl is null
   	begin
   	select @msg = 'Missing SL!', @rcode = 1
   	goto bspexit
   	end

if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto bspexit
   	end

-- TK-05850 --
IF @PCOSItemDetailYN IS NULL
   	BEGIN
   		SELECT @msg = 'Missing PCOSItemDetailYN flag!', @rcode = 1
   		GOTO bspexit
   	END
   	

---- get info from SLHD #136053
select @msg = 'New Subcontract'
----#136053
select @msg=Description, @slvendor=Vendor, @slvendorgroup=VendorGroup,
		@origdate=OrigDate, @status=Status,
		----TK-00000
		@Approved = Approved
----#136053
from dbo.SLHD with (nolock) where SLCo=@slco and SL=@sl
if @@rowcount <> 0
	begin
	---- check to see if vendor entered matches the vendor in PM if we have a vendor
	if @slvendorgroup <> @vendorgroup
		begin
		select @msg = 'Vendor Group from SL Header (SLHD) does not match the PM Vendor Group.', @rcode = 1
		goto bspexit
		end
	if isnull(@vendor, @slvendor) <> @slvendor
		begin
		select @msg = 'Vendor entered does not match vendor in SL. ', @rcode = 1
		goto bspexit
		end
	---- check subcontract status allow only(0,3) - open or pending
	if @status not in (0,3)
		begin
		select @msg = 'Subcontract must be Open or Pending!', @rcode = 1
		goto bspexit
		END
	----TK-00000
	IF @PCOSItemDetailYN = 'Y'
		BEGIN
		---- check approved flag
		IF @Approved <> 'Y'
			BEGIN
			SET @rcode = 1
			SET @msg = 'Subcontract must be Approved'
			GOTO bspexit
			END
		END
	end
ELSE	-- TK-05850 --
	BEGIN
		IF @PCOSItemDetailYN = 'Y'
			BEGIN
			   	SELECT @msg = 'Subcontract is invalid!', @rcode = 1
   				GOTO bspexit
			END
	END

-- -- -- get maximum SL Item from PMSL
select @maxpmsl = max(SLItem) from PMSL with (nolock) where SLCo=@slco and SL=@sl
if @maxpmsl is null select @maxpmsl = 0
-- -- -- get maximum SL Item from SLIT
select @maxslit = max(SLItem) from SLIT with (nolock) where SLCo=@slco and SL=@sl
if @maxslit is null select @maxslit = 0
-- -- -- set @nextslitem to larger of two plus one
if @maxpmsl > @maxslit
	select @nextslitem = @maxpmsl + 1
else
	select @nextslitem = @maxslit + 1

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLValForPM] TO [public]
GO
