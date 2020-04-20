SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspPMPCOPOCONumVal]
CREATE  proc [dbo].[vspPMPCOPOCONumVal]
   /***********************************************************
    * Created By:	DAN SO 04/15/2011 - B-04326 - POCO - PCO Integration
    * Modified By:	DAN SO 05/02/2011 - AT-02070 - Attempt to default POCONumSeq
    *				DAN SO 07/20/2011 - TK-06029 - Match validation for SubCO's
    *
    * USAGE:
	*	Validate POCONum is valid for a specific PCOItem
    *
    * INPUT PARAMETERS
    *   PMCo		- PM Company
    *   Project		- PM Project
    *   POCONum		- PO Change Order from PMMF
    *   POCONumSeq	- PO Change Order Seq from PMPOCO
    *	POItem		- PO Item
    *
    * OUTPUT PARAMETERS
    *	@POCONumSeqOut	- Default PO Change Order Sequence
    *   @msg			- error message 
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@PMCo bCompany = NULL, @Project bJob = NULL, @POCONum smallint = NULL, @POCONumSeq int = NULL, 
	@Phase bPhase = NULL, @CostType bJCCType = NULL, @Vendor bVendor = NULL, @PO varchar(30) = null,
	@POItem bItem = NULL, 
    @POCONumSeqOut int output, @msg varchar(255) output)
    
    
    AS
    SET NOCOUNT ON

	DECLARE @Count	int,
			@Approved CHAR(1),
			@rcode	int
   
	---------------------
	-- PRIME VARIABLES --
	---------------------
	SET @rcode = 0
   
	--------------------------------
	-- VERIFY INCOMING PARAMETERS --
	--------------------------------
	IF @PMCo IS NULL
		BEGIN
			SET @msg = 'Missing PM Company!'
			SET @rcode = 1
			GOTO vspexit
		END
   
	IF @Project IS NULL
		BEGIN
			SET @msg = 'Missing Project!'
			SET @rcode = 1
			GOTO vspexit
		END
 
	IF @POCONum IS NULL
		BEGIN
			SET @msg = 'Missing PO Change Order!'
			SET @rcode = 1
			GOTO vspexit
		END

	----TK-06029
	SET @POCONumSeqOut = NULL

	-- VALIDATE POCO -- TK-06029
	SELECT	@msg = p.[Description], @Approved = h.Approved
	  FROM	dbo.PMPOCO p
INNER JOIN	dbo.POHD h ON h.POCo=p.POCo AND h.PO=p.PO
	 WHERE	p.PMCo = @PMCo
	   AND	p.Project = @Project
	   AND	p.POCONum = @POCONum
	   
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'PO Change Order is NOT valid!'
			SET @rcode = 1
			GOTO vspexit
		END

	-- PO MUST BE APPROVED -- 
	IF @Approved = 'N'
		BEGIN
			SET @msg = 'PO has not been approved.'
			SET @rcode = 1
			GOTO vspexit
		END
	
	----------------------------------------
	-- DEFAULT SEQ IF ONLY 1 RECORD FOUND --
	----------------------------------------
	SELECT	@POCONumSeqOut = f.Seq
	  FROM	PMPOCO poco WITH (NOLOCK)
 LEFT JOIN	PMMF f WITH (NOLOCK) ON poco.PMCo = f.PMCo 
							  and poco.Project = f.Project 
							  and poco.POCo = f.POCo 
							  and poco.PO = f.PO
							  and poco.POCONum = f.POCONum
	 WHERE	poco.PMCo = @PMCo
	   AND	poco.Project = @Project
	   AND	poco.POCONum = @POCONum
	   AND	(f.Phase = @Phase OR @Phase IS NULL)
	   AND	(f.CostType = @CostType OR @CostType IS NULL)
	   AND	(f.Vendor = @Vendor OR @Vendor IS NULL)
	   AND	(f.PO = @PO OR @PO IS NULL)
	   AND	(f.Seq = @POCONumSeq or @POCONumSeq IS NULL)
	   AND	(f.POItem = @POItem or @POItem IS NULL)
         
    SET @Count = @@ROWCOUNT
	IF @Count = 1
		BEGIN
			---- DO NOT DEFAULT IF @POCONumSeqOut IS ALREADY IS USE --
			IF EXISTS (SELECT TOP 1 1 
						 FROM PMOL WITH (NOLOCK) 
						WHERE PMCo = @PMCo 
						  AND Project = @Project AND POCONum = @POCONum 
						  AND POCONumSeq = @POCONumSeqOut)
						  
					SET @POCONumSeqOut = NULL
						
		END -- IF @Count = 1
		
	ELSE
		-- @Count <> 1 -- CLEAR @POCONumSeqOut
		SET @POCONumSeqOut = NULL
 
   
   
	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOPOCONumVal] TO [public]
GO
