SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMPCOItemDetailPullDetails  Script Date: 8/28/99 9:33:05 AM ******/
CREATE proc [dbo].[vspPMPCOItemDetailPullDetails]
/***********************************************************
 * CREATED BY:	JG 02/21/2011 - V1# B-02366 
 * MODIFIED BY:	GP 03/10/2011 - V1# B-03081 - added @um and @unitCost output params
 *				JG 04/04/2011 - TK-03733 - Shrunk down logic in pull of details
 *				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 *
 *
 *
 * USAGE: Called from PMPCOS to pull the Phase, Cost Type, Vendor, SL/PO, and SL/PO Item, depending on
 * when a Vendor, or a PO/SL is received.
 *
 *
 * INPUT PARAMETERS
 * PMCO
 * PROJECT
 * VENDOR
 * PO
 * SL
 * ITEM
 * PHASE
 * COSTTYPE
 *
 * OUTPUT PARAMETERS
 * OUTPUTS
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *****************************************************/
(@pmco bCompany = 0, @project bJob = null, @vendor bVendor = NULL OUTPUT, @po varchar(30) = NULL OUTPUT, 
 @sl VARCHAR(30) = NULL OUTPUT, @phase bPhase = NULL OUTPUT, @costtype dbo.bJCCType = NULL OUTPUT, 
 @item dbo.bItem = NULL OUTPUT, @um bUM = NULL OUTPUT, @unitCost bUnitCost = NULL OUTPUT,
 @msg VARCHAR(255) = NULL OUTPUT)
as
set nocount on

DECLARE @ItemTable TABLE
					(
					PO varchar(30) NULL,
					SL VARCHAR(30) NULL,
					Item dbo.bItem NULL,
					Vendor dbo.bVendor NULL,
					Phase dbo.bPhase NULL,
					CostType dbo.bJCCType NULL,
					UM dbo.bUM NULL,
					UnitCost dbo.bUnitCost NULL
					)

DECLARE @itemcount INT, @rcode INT

select @rcode = 0, @msg = ''

-- Validate Parameters
IF @pmco IS NULL OR @pmco < 1 OR @project IS NULL
BEGIN
	SELECT @msg = 'Invalid input parameters. Please contact Viewpoint Construction Software.', @rcode = 1
	GOTO vspexit
END


-- Pull details based on details
INSERT INTO @ItemTable (
	Phase,
	CostType,
	Vendor,
	SL,
	Item,
	UM,
	UnitCost
	) 

SELECT SLITPM.Phase, SLITPM.JCCType, SLHDPM.Vendor, SLITPM.SL, SLITPM.SLItem, SLITPM.UM, SLITPM.OrigUnitCost FROM SLITPM
LEFT JOIN SLHDPM ON dbo.SLITPM.SL = dbo.SLHDPM.SL
AND dbo.SLITPM.PMCo = dbo.SLHDPM.PMCo
AND dbo.SLITPM.Job = dbo.SLHDPM.Job
WHERE SLITPM.ItemType NOT IN (3,4) -- Leave items that are in invalid states alone!
AND SLITPM.JCCo = @pmco
AND SLITPM.Job = @project
AND SLITPM.Phase = ISNULL(@phase, SLITPM.Phase)
AND SLITPM.JCCType = ISNULL(@costtype, SLITPM.JCCType)
AND SLHDPM.Vendor = CASE WHEN @sl IS NULL THEN ISNULL(@vendor, SLHDPM.Vendor) ELSE SLHDPM.Vendor END
AND SLITPM.SL = CASE WHEN @po IS NULL THEN ISNULL(@sl, SLITPM.SL) ELSE NULL END
AND SLITPM.SLItem = CASE WHEN @sl IS NOT NULL THEN ISNULL(@item, SLITPM.SLItem) ELSE SLITPM.SLItem END

INSERT INTO @ItemTable (
	Phase,
	CostType,
	Vendor,
	PO,
	Item,
	UM,
	UnitCost
	) 

SELECT POITPM.Phase, POITPM.JCCType, POHDPM.Vendor, POITPM.PO, POITPM.POItem, POITPM.UM, POITPM.OrigUnitCost FROM POITPM
LEFT JOIN POHDPM ON dbo.POITPM.PO = dbo.POHDPM.PO
AND dbo.POITPM.PMCo = dbo.POHDPM.PMCo
AND dbo.POITPM.Job = dbo.POHDPM.Job
WHERE POITPM.ItemType = 1 -- Leave items that are in invalid states alone!
AND POITPM.JCCo = @pmco
AND POITPM.Job = @project
AND POITPM.Phase = ISNULL(@phase, POITPM.Phase)
AND POITPM.JCCType = ISNULL(@costtype, POITPM.JCCType)
AND POHDPM.Vendor = ISNULL(@vendor, POHDPM.Vendor)
AND POITPM.PO = CASE WHEN @sl IS NULL THEN ISNULL(@po, POITPM.PO) ELSE NULL END
AND POITPM.POItem = CASE WHEN @po IS NOT NULL THEN ISNULL(@item, POITPM.POItem) ELSE POITPM.POItem END



-- Pull distinct items

--Vendor
IF @vendor IS NULL
BEGIN
	SELECT DISTINCT Vendor FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @vendor = Vendor FROM @ItemTable	
END

IF @vendor IS NULL
BEGIN
	IF @sl IS NOT NULL
	BEGIN
		SELECT @vendor = Vendor FROM SLHDPM WHERE SL = @sl
	END
	ELSE IF @po IS NOT NULL
	BEGIN
		SELECT @vendor = Vendor FROM POHDPM WHERE PO = @po
	END	
END	

--PO
IF @po IS NULL
BEGIN
	SELECT DISTINCT PO FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @po = PO FROM @ItemTable	
END

--SL
IF @sl IS NULL
BEGIN
	SELECT DISTINCT SL FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @sl = SL FROM @ItemTable
END

--Item	
IF @sl IS NOT NULL OR @po IS NOT NULL
BEGIN
	SELECT DISTINCT Item FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @item = Item, @um = UM, @unitCost = UnitCost FROM @ItemTable
END
ELSE
BEGIN
	SELECT @item = NULL
END

--Phase
IF @phase IS NULL
BEGIN
	SELECT DISTINCT Phase FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @phase = Phase FROM @ItemTable
END

--CostType
IF @costtype IS NULL
BEGIN
	SELECT DISTINCT CostType FROM @ItemTable
	SELECT @itemcount = @@ROWCOUNT
	IF @itemcount = 1
		SELECT DISTINCT @costtype = CostType FROM @ItemTable
END

vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOItemDetailPullDetails] TO [public]
GO
