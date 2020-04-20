SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--CREATE PROC [dbo].[vspPMPOCOVal]
CREATE PROC [dbo].[vspPMPOCOVal]
/*************************************
 * Created By:	DAN SO 03/31/2011
 * Modified by: DAN SO 04/11/2011 - TK-03815 - allow only Open PO's
 *				DAN SO 04/22/2011 - TK-04287 - ease restrictions on valid PO's
 *				GF 05/10/2011 - TK-04967 TK-04937
 *				GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 * Verify that a Purchase Order exists, in Status = 0,3 and return various informaion about the PO.
 *
 * Input:
 *	@POCo	PM PO Company
 *	@PMCo	PM Company
 *	@PO		PM Purchase Order
 *
 * Output:
 *	@POInBatch	Is PO in a Batch
 *	@msg		May be an error message
 *
 * Returns:
 *	0	Successful
 *	1	Error
 *
 **************************************/
(@POCo bCompany = NULL, @PMCo bCompany = NULL, 
 @Project bProject = NULL, @PO varchar(30) = NULL, 
 @POInBatch varchar(100) = NULL output,
 ---- TK-04967
 @VendorGroup bGroup = NULL OUTPUT, @Vendor bVendor = NULL OUTPUT,
 @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE @JCCo		bCompany,
		@Job		bJob,
		@Approved	varchar(1),
		@Status		tinyint,
		@rcode		int
	
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @Status = 255
	SET @rcode = 0

	-------------------------------
	-- CHECK INCOMING PARAMETERS --
	-------------------------------
	IF @POCo IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing PO Company!'
			GOTO vspexit
		END

	IF @PMCo IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing PM Company!'
			GOTO vspexit
		END
		
	IF @Project IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing PM Project!'
			GOTO vspexit
		END
		
	IF @PO IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing PO!'
			GOTO vspexit
		END


	-----------------
	-- VALIDATE PO -- TK-04286
	-----------------
	SELECT	@msg = Description, @Approved = Approved, @Status = Status,
			@JCCo = JCCo, @Job = Job,
			---- TK-04967
			@VendorGroup = VendorGroup, @Vendor = Vendor
	  FROM	dbo.POHD WITH (NOLOCK)
	 WHERE	POCo = @POCo
	 AND	PO = @PO

	IF @@ROWCOUNT = 0
		BEGIN
			SET @rcode = 1
			SET @msg = 'Purchase Order not on file for current Project'
			GOTO vspexit
		END
		
	-- CHECK STATUS --
	IF @Status NOT IN (0,3)
		BEGIN
			SET @rcode = 1
			SET @msg = 'Purchase Order must be Open or Pending'
			GOTO vspexit
		END

	---- check approved flag TK-04937
	IF @Approved <> 'Y'
		BEGIN
		SET @rcode = 1
		SET @msg = 'Purchase Order must be Approved'
		GOTO vspexit
		END
		
	-- CHECK JOBS --
	IF ISNULL(@JCCo,0) <> @PMCo OR ISNULL(@Job,'') <> @Project
		BEGIN
			SET @rcode = 1
			SET @msg = 'Purchase Order already exists for JCCo: ' + ISNULL(CONVERT(varchar(3),@JCCo),'') + ' and Job: ' + ISNULL(@Job,'') + '!'
			GOTO vspexit
		END
	


	vspexit:
		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCOVal] TO [public]
GO
