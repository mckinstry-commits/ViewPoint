SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************/
CREATE PROC [dbo].[vspPMPOCOItemSeqVal]
/**************************************
 * Created By:	GF 05/10/2011 TK-04938
 * Modified by: GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 *
 * Validates the item sequence entered in PM PO Change Order form Item detail section.
 * If assigning a PMMF record to a POCO, must be a valid unassigned PMMF detail
 * record. If already assigned to a POCO, then error is returned and not allowed.
 *
 * Input:

 * @PMCo		PM Company
 * @Project		PM Project
 * @POCo		PO Company
 * @PO			Purchase Order
 * @POCONum		PO change order number
 * @PMMFSeq		PMMF Sequence number to validate
 *
 * Output:
 *	@msg		Error message if PMMF sequence cannot be assigned to PO change order
 *
 * Returns:
 *	0	Successful
 *	1	Error
 *
 **************************************/
(@PMCo bCompany = NULL, @Project bProject = NULL,
 @POCo bCompany = NULL, @PO varchar(30) = NULL,
 @POCONum SMALLINT = NULL, @PMMFSeq INT = NULL, 
 @Exists CHAR(1) = 'N' OUTPUT, @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode INT, @Vendor bVendor

SET @rcode = 0
SET @Exists = 'N'

-------------------------------
-- CHECK INCOMING PARAMETERS --
-------------------------------
IF @PMCo IS NULL
	BEGIN
		SET @rcode = 1
		SET @msg = 'Missing PM Company'
		GOTO vspexit
	END
	
IF @Project IS NULL
	BEGIN
		SET @rcode = 1
		SET @msg = 'Missing PM Project'
		GOTO vspexit
	END

IF @PO IS NULL
	BEGIN
		SET @rcode = 1
		SET @msg = 'Missing PO'
		GOTO vspexit
	END

---- if sequence is null
IF @PMMFSeq IS NULL GOTO vspexit
---- not numeric (maybe 'N')
IF ISNUMERIC(@PMMFSeq) = 0 GOTO vspexit
---- sequence does not exist
IF NOT EXISTS(SELECT 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq) GOTO vspexit

---- get vendor from POHD
SELECT @Vendor = Vendor
FROM dbo.POHD WHERE POCo=@POCo AND PO=@PO
IF @@ROWCOUNT = 0
	BEGIN
	SET @rcode = 1
	SET @msg = 'Invalid Purchase Order'
	GOTO vspexit
	END	

---- PMMF interface date must be null
IF EXISTS(SELECT TOP 1 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq AND InterfaceDate IS NOT NULL)
	BEGIN
	SET @rcode = 1
	SET @msg = 'Material detail record has been interfaced'
	GOTO vspexit
	END	

---- PMMF material option must be 'P'urchase order
IF EXISTS(SELECT TOP 1 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq AND MaterialOption <> 'P')
	BEGIN
	SET @rcode = 1
	SET @msg = 'Material detail is not a (P)urchase order type'
	GOTO vspexit
	END	
	
---- validate the PMMF record vendor matches PO change order vendor 
IF EXISTS(SELECT TOP 1 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq
			AND Vendor IS NOT NULL AND Vendor <> @Vendor)
	BEGIN
	SET @rcode = 1
	SET @msg = 'Material detail vendor is different from PO change order'
	GOTO vspexit
	END	
	
---- validate the PMMF sequence is available to assign to the PO change order
IF EXISTS(SELECT TOP 1 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq
			AND POCONum IS NOT NULL AND POCONum <> @POCONum)
	BEGIN
	SET @rcode = 1
	SET @msg = 'Material detail sequence is already assigned to a PO change order'
	GOTO vspexit
	END

---- validate the PMMF record vendor matches PO change order vendor 
IF EXISTS(SELECT TOP 1 1 FROM dbo.PMMF WHERE PMCo=@PMCo AND Project=@Project AND Seq=@PMMFSeq
			AND PO IS NOT NULL AND PO <> @PO)
	BEGIN
	SET @rcode = 1
	SET @msg = 'Material detail PO is different from PO change order'
	GOTO vspexit
	END	

SET @Exists = 'Y'



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCOItemSeqVal] TO [public]
GO
