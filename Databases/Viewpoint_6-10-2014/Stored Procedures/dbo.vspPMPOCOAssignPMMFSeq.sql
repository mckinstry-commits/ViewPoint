SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE PROC [dbo].[vspPMPOCOAssignPMMFSeq]
/**************************************
 * Created By:	GF 05/11/2011 TK-04938
 * Modified by: GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 *
 * Assigns a PMMF material sequence record to a PO Change Order.
 *
 * Input:

 * @POCOKeyID	PM POCO Key ID
 * @PMMFSeq		PMMF Sequence number to assign to POCO
 *
 * Output:
 *	@msg		Error message if PMMF sequence cannot be assigned to PO change order
 *
 * Returns:
 *	0	Successful
 *	1	Error
 *
 **************************************/
(@POCOKeyID BIGINT = NULL, @PMMFSeq INT = NULL, 
 @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @PMCo bCompany, @Project bJob, 
		@POCo bCompany, @PO varchar(30), @POCONum SMALLINT,
		@POItem bItem, @PMMFKeyID BIGINT, @POIT_Item bItem,
		@PMMF_Item bItem, @VendorGroup bGroup, @Vendor bVendor

SET @rcode = 0

-------------------------------
-- CHECK INCOMING PARAMETERS --
-------------------------------
IF @POCOKeyID IS NULL
	BEGIN
		SET @rcode = 1
		SET @msg = 'Missing PO Change Order Key ID'
		GOTO vspexit
	END
	
IF @PMMFSeq IS NULL
	BEGIN
		SET @rcode = 1
		SET @msg = 'Missing PM Material Detail Sequence'
		GOTO vspexit
	END

---- validate POCO and retrieve info
SELECT @PMCo=c.PMCo, @Project=c.Project, @POCo=c.POCo, @PO=c.PO,
		@POCONum=c.POCONum, @VendorGroup=h.VendorGroup, @Vendor=h.Vendor
FROM dbo.PMPOCO c
INNER JOIN dbo.POHD h ON h.POCo=c.POCo AND h.PO=c.PO
WHERE c.KeyID=@POCOKeyID
IF @@ROWCOUNT = 0
	BEGIN
	SET @rcode = 1
	SET @msg = 'Invalid POCO Number'
	GOTO vspexit
	END

---- validate PMMF sequence and retrieve info 
SELECT @PMMFKeyID = KeyID
FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq
IF @@ROWCOUNT = 0
	BEGIN
	SET @rcode = 1
	SET @msg = 'Invalid PM Material Detail Sequence'
	GOTO vspexit
	END
	
	
---- if the PMMF sequence is already assigned to the PO and Item
---- we are just assigning the POCONum to the PMMF sequence
UPDATE dbo.PMMF SET POCONum=@POCONum
FROM dbo.PMMF m
INNER JOIN dbo.POHD h ON h.POCo=m.POCo AND h.PO=m.PO
WHERE m.KeyID=@PMMFKeyID AND m.POItem IS NOT NULL
IF @@ROWCOUNT = 0
	BEGIN
	---- get next PO Item from POIT
   	select @POIT_Item = isnull(max(POItem),0)+1
   	from dbo.POIT where POCo=@POCo and PO=@PO
	IF @@ROWCOUNT = 0 SET @POIT_Item = NULL
	
	---- get next PO Item from PMMF
	select @PMMF_Item = isnull(max(POItem),0)+1
	from dbo.PMMF where POCo=@POCo AND PO=@PO
	IF @@ROWCOUNT = 0 SET @PMMF_Item = NULL
  
   	---- take the max of the two
   	SET @POItem = null
	if @PMMF_Item IS NULL SET @PMMF_Item = 0
	if @POIT_Item IS NULL SET @POIT_Item = 1
	if @PMMF_Item >= @POIT_Item SET @POItem = @PMMF_Item
	IF ISNULL(@POItem,0) < 1 SET @POItem = 1
	
	SELECT @PMMF_Item, @POIT_Item, @POItem
	
	---- we will now assign the VendorGroup, Vendor, POCo, PO, next POItem, and POCONum
	UPDATE dbo.PMMF
			SET VendorGroup = @VendorGroup,
				Vendor=@Vendor,
				PO = @PO,
				POItem = @POItem,
				POCONum = @POCONum
	WHERE KeyID = @PMMFKeyID
					
	END





vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCOAssignPMMFSeq] TO [public]
GO
