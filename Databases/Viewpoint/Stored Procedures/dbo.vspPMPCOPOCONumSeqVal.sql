SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspPMPCOPOCONumSeqVal]
   /***********************************************************
    * Created By: DAN SO 3/15/2011 - B-04326 - POCO - PCO Integration
    * Modified By:	DAN SO 06/28/2011 - TK-06469 - Output new columns
    *				DAN SO 07/11/2011 - TK-06713 - Message stated invalid combination when it is actually already in use
    *								  - removed commented out code - check SVN to see what was commented out
    *				GP 2/7/2012 - TK-12383 - Phase/CostType exists validation no longer sets @OutPhase or @OutCostType and
    *										doesn't check update to the current row.
    * USAGE:
	*	Validate that the associated POCONum and POCONumSeq is valid for a specific PCOItem
    *
    * INPUT PARAMETERS
    *   @PMCo		- PM Company
    *   @Project	- PM Project
    *   @POCONum	- PO Change Order from PMMF
    *   @POCONumSeq	- Seq from PMPOCO
    *	@PCOType	- PCO Type
    *	@PCO		- PCO number
	*	@PCOItem	- PCO Item
    *	@InPhase	- Incoming Phase 
    *	@InCostType - Incoming Cost Type
    *	@InVendor	- Incoming Vendor
    *	@InPO		- Incoming PO
    *	@InItem		- Incoming Item
    *
    * OUTPUT PARAMETERS
    *	@OutPhase		- Output Phase
    *	@OutCostType	- Output Cost Type
    *	@OutVendor		- Output Vendor
    *	@OutSL			- Output SL
    *	@OutItem		- Output Item
    *	@Units			- Units
    *	@UM				- UM
    *	@UnitCost		- Unit Cost
    *	@Amount			- Amount
    *	@Item			- Item
    *	@OutPurchUM		- Output Purchase UM
    *	@OutPurchUnits	- Output Purchase Units
    *	@OutPurchUC		- Output Purchase Unit Cost
    *	@OutMtlCode		- Output Material Code
    *   @msg			- error message 
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@PMCo bCompany = NULL, @Project bJob = NULL, @POCONum smallint = NULL, @POCONumSeq int = NULL,
    @PCOType bDocType = NULL, @PCO bPCO = NULL, @PCOItem bPCOItem = NULL, 
	@InPhase bPhase = NULL, @OutPhase bPhase = NULL output,
	@InCostType bJCCType = NULL, @OutCostType bJCCType = NULL output,
    @InVendor bVendor = NULL, @OutVendor bVendor = NULL output,
    @InPO varchar(30) = NULL, @OutPO varchar(30) = NULL output,
    @InItem bItem = NULL, @OutItem bItem = NULL output,
    @Units bUnits = NULL output, @UM bUM = NULL output, 
    @UnitCost bUnitCost = NULL output, @Amount bDollar = NULL output,
    @OutMtlCode bMatl = NULL output,	-- TK-06469
    @msg varchar(255) output)
        
    AS
    SET NOCOUNT ON

	DECLARE @rcode int, @UpdateRecordKeyID bigint
   
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
   
	IF @POCONumSeq IS NULL
		BEGIN
			SET @msg = 'Missing PO Change Order Seq!'
			SET @rcode = 1
			GOTO vspexit
		END

	IF @PCOType IS NULL
		BEGIN
			SET @msg = 'Missing PCO Type!'
			SET @rcode = 1
			GOTO vspexit
		END
 
	IF @PCO IS NULL
		BEGIN
			SET @msg = 'Missing PCO!'
			SET @rcode = 1
			GOTO vspexit
		END
   
	IF @PCOItem IS NULL
		BEGIN
			SET @msg = 'Missing PCO Item!'
			SET @rcode = 1
			GOTO vspexit
		END
		
		
	----------------------------------------------------
	-- CHECK FOR VALID POCONum/POCONumSeq COMBINATION --
	----------------------------------------------------
	SELECT	@OutPhase = f.Phase, @OutCostType = f.CostType, @OutVendor = f.Vendor, @OutPO = f.PO,
			@OutItem = f.POItem, @Units = f.Units, @UM = f.UM, @UnitCost = f.UnitCost, @Amount = f.Amount,
			@OutMtlCode = f.MaterialCode
	  FROM	PMPOCO poco with (nolock)
 LEFT JOIN	PMMF f with (nolock) on poco.PMCo = f.PMCo 
							  and poco.Project = f.Project 
							  and poco.POCo = f.POCo 
							  and poco.PO = f.PO
							  and poco.POCONum = f.POCONum
     WHERE	poco.PMCo = @PMCo
       AND	poco.Project = @Project
       AND	poco.POCONum = @POCONum
       AND	f.Seq = @POCONumSeq
       AND	(f.Phase = @InPhase OR @InPhase IS NULL)
       AND	(f.CostType = @InCostType OR @InCostType IS NULL)
       AND	(f.Vendor = @InVendor OR @InVendor IS NULL)
       AND	(f.PO = @InPO OR @InPO IS NULL)
       AND	(f.POItem = @InItem OR @InItem IS NULL)
        
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'PO Change Order/Seq combination not valid!'
			SET @rcode = 1
			GOTO vspexit
		 END
   
   
	----------------------------------------------------------
	-- CHECK IF IT HAS ALREADY BEEN USED ON A DIFFERENT PCO --
	----------------------------------------------------------
	SELECT TOP 1 1
	  FROM PMOL WITH (NOLOCK) 
	 WHERE PMCo = @PMCo 
	   AND Project = @Project AND POCONum = @POCONum AND POCONumSeq = @POCONumSeq
													  												  
	IF @@ROWCOUNT <> 0 
		BEGIN
			-- CLEAR OUTPUT PARAMETERS --
			SET @OutPhase = NULL
			SET @OutCostType = NULL
			SET @OutVendor = NULL
			SET @OutPO = NULL
			SET @OutItem = NULL
			SET @OutMtlCode = NULL
			
			-- ERROR --
			SET @msg = 'PO Change Order/Seq combination already in use!'
			SET @rcode = 1
			GOTO vspexit
		END

	---------------------------------------------------------------
	-- CHECK IF Phase/CostType COMBINATION EXISTS ON CURRENT PCO --
	---------------------------------------------------------------
	--Get KeyID for record being updated.
	--Used to ignore the following validation
	--if updating SubCOSeq on existing record.	
	SELECT @UpdateRecordKeyID = KeyID 
	FROM dbo.PMOL 
	WHERE PMCo = @PMCo 
		AND Project = @Project AND PCOType = @PCOType AND PCO = @PCO AND PCOItem = @PCOItem
		AND Phase = @OutPhase AND CostType = @OutCostType
	
	SELECT TOP 1 1
	  FROM dbo.PMOL
	 WHERE PMCo = @PMCo 
	   AND Project = @Project AND PCOType = @PCOType AND PCO = @PCO AND PCOItem = @PCOItem 
	   AND Phase = @OutPhase AND CostType = @OutCostType 
	   --Don't look at the record you are updating if the Phase/CostType haven't been changed.
	   AND NOT (@UpdateRecordKeyID = KeyID AND @InPhase = @OutPhase AND @InCostType = @OutCostType) 
														  												  
	IF @@ROWCOUNT <> 0 
		BEGIN
			-- CLEAR OUTPUT PARAMETERS --
			SET @OutPhase = NULL
			SET @OutCostType = NULL
			SET @OutVendor = NULL
			SET @OutPO = NULL
			SET @OutItem = NULL
			SET @OutMtlCode = NULL
			
			-- ERROR --
			SET @msg = 'Phase/CostType exists!'
			SET @rcode = 1
			GOTO vspexit
		END
		
		
	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOPOCONumSeqVal] TO [public]
GO
