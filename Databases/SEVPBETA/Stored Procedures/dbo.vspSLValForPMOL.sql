
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspSLValForPMOL]
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
 *				GP 06/20/2011 - TK-06041 Added SLItem, UM, and UnitCost outputs
 *				JG 06/23/2011 TK-06041 - Add phase/ct to filter items
 *				JG 06/29/2011 TK-06041 - Added Purchase Units/Amount
 *				JG 07/13/2011 TK-00000 - Changed from Orig values to Cur values
 *				JG 02/21/2012 TK-12755 - Modified the check for Phases and Cost types when the stored value is null.
 *				AW 03/14/2013 TFS-43659 - Allow new SL's if CreateSL is checked otherwise follow original rules
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
 @project bJob = null, @phase bPhase = NULL, @costtype bJCCType = NULL,
 @vendor bVendor = null,
 @vendorgroup bGroup, @PCOSItemDetailYN char(1) = NULL, @CreateSLYN char(1) = null,
 @nextslitem bItem output, @slvendor bVendor output,
 @origdate bDate = null output, @status tinyint = NULL output,
 @SLItem bItem output, @UM bUM output, @Units bUnits OUTPUT, @UnitCost bUnitCost output, @Amount bDollar OUTPUT, 
 @Phase bPhase output, @CostType bJCCType output, @NewCreateSLYN bYN output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @slvendorgroup bGroup, @maxpmsl bItem, @maxslit bItem,
		----TK-00000
		@Approved CHAR(1), @SLCount int, @DetailCount int, @SLItem1 bItem, @SLItem2 bItem

select @rcode = 0, @status = 0, @maxpmsl = 0, @maxslit = 0, @nextslitem = 0, @SLCount = 0, @DetailCount = 0

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
   	
IF @CreateSLYN IS NULL
   	BEGIN
   		SELECT @msg = 'Missing CreateSLYN flag!', @rcode = 1
   		GOTO bspexit
   	END

SET @NewCreateSLYN = @CreateSLYN
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
		select @msg = 'Subcontract must be New, Open, Pending!', @rcode = 1
		goto bspexit
		END
	----TK-00000
	IF @PCOSItemDetailYN = 'Y'
		BEGIN
		---- check approved flag
		IF @Approved <> 'Y'
			BEGIN
			SET @rcode = 1
			SET @msg = 'Subcontract must be either New or Approved'
			GOTO bspexit
			END
		END
	--TFS-43659 clear the CreateSL flag if SL already exists and passes validation
	IF @CreateSLYN = 'Y'
		BEGIN
			SET @NewCreateSLYN = 'N'
		END
	end
--TFS-43659 we will allow new SLs to be added if CreateSL = 'Y'
ELSE	-- TK-05850 --
	BEGIN
		IF @vendor is null
			BEGIN
			SET @rcode = 1
			SET @msg = 'Vendor required!'
			GOTO bspexit
			END
		IF @PCOSItemDetailYN = 'Y' and @CreateSLYN = 'N'
			BEGIN
			   	SET @NewCreateSLYN = 'Y'
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

set @SLItem = null

--Get a count of how many SL Item records exist for the SL
select DISTINCT @SLItem1 = SLItem 
from dbo.SLIT 
where JCCo = @pmco 
	and Job = @project 
	and SL = @sl 
	AND dbo.vfIsEqual(Phase, ISNULL(@phase, Phase)) & 
		dbo.vfIsEqual(JCCType, ISNULL(@costtype, JCCType)) = 1
SELECT @SLCount = @@ROWCOUNT

select DISTINCT @SLItem2 = SLItem 
from dbo.PMSL 
where PMCo = @pmco 
	and Project = @project 
	and SL = @sl 
	AND dbo.vfIsEqual(Phase, ISNULL(@phase, Phase)) & 
		dbo.vfIsEqual(CostType, ISNULL(@costtype, CostType)) = 1
SELECT @DetailCount = @@ROWCOUNT

if @SLCount is null		set @SLCount = 0
if @DetailCount is null	set @DetailCount = 0

--Check if we can narrow it down to 1 specific item only
if ((@SLCount = 1 AND @DetailCount = 1) AND (@SLItem1 = @SLItem2)) OR (@SLCount = 1 AND @DetailCount = 0)
begin
	select @SLItem = SLItem, @UM = UM, @Units = CurUnits, @UnitCost = CurUnitCost, @Amount = CurCost, @Phase = Phase, @CostType = JCCType 
	from dbo.SLIT 
	where JCCo = @pmco 
		and Job = @project 
		and SL = @sl 
		AND dbo.vfIsEqual(Phase, ISNULL(@phase, Phase)) & 
		dbo.vfIsEqual(JCCType, ISNULL(@costtype, JCCType)) = 1
end
else if @DetailCount = 1 and @SLCount = 0
begin
	select @SLItem = SLItem, @UM = UM, @Units = Units, @UnitCost = UnitCost, @Amount = Amount, @Phase = Phase, @CostType = CostType 
	from dbo.PMSL 
	where PMCo = @pmco 
		and Project = @project 
		and SL = @sl 
		AND dbo.vfIsEqual(Phase, ISNULL(@phase, Phase)) & 
		dbo.vfIsEqual(CostType, ISNULL(@costtype, CostType)) = 1
end
-- Make sure we return at least 1 as our SLItem
if @SLItem is null
	set @SLItem = @nextslitem



bspexit:
	return @rcode
GO

GRANT EXECUTE ON  [dbo].[vspSLValForPMOL] TO [public]
GO
