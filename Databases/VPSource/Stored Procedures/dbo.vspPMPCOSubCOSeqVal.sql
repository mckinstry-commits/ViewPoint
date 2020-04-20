SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspPMPCOSubCOSeqVal]
CREATE  proc [dbo].[vspPMPCOSubCOSeqVal]
   /***********************************************************
    * Created By: DAN SO 3/15/2011 - B-02352 - SCO - PCO Integration - pull info
    * Modified By: GF 06/20/2011 - TK-06039
    *				DAN SO 06/29/2011 - TK-06469 - Output new columns
    *				DAN SO 07/11/2011 - TK-06713 - Message stated invalid combination when it is actually already in use
    *								  - removed commented out code - check SVN to see what was commented out
    *				GP 11/14/2011 - TK-09963 - Phase/Cost Type exists error was always thrown if any PMOL records existed,
	*									now checks for specific Phase/Cost Type record. Also added @Interfaced parameter.
    *
    * USAGE:
	*	Validate that the associated SubCO and SubCOSeq is valid for a specific PCOItem
    *
    * INPUT PARAMETERS
    *   @PMCo		- PM Company
    *   @Project	- PM Project
    *   @SubCO		- SubCO from PMSL
    *   @SubCOSeq	- Seq from PMSubcontractCO
    *	@PCOType	- PCO Type
    *	@PCO		- PCO number
	*	@PCOItem	- PCO Item
    *	@InPhase	- Incoming Phase 
    *	@InCostType - Incoming Cost Type
    *	@InVendor	- Incoming Vendor
    *	@InSL		- Incoming SL
    *	@InItem		- Incoming Item
    *
    * OUTPUT PARAMETERS
    *	@OutPhase		- Output Phase
    *	@OutCostType	- Output Cost Type
    *	@OutVendor		- Output Vendor
    *	@OutSL			- Output SL
    *	@OutItem		- Item
    *	@Units			- Units
    *	@UM				- UM
    *	@UnitCost		- Unit Cost
    *	@Amount			- Amount
    *	@OutPurchUM		- Output Purchase UM
    *	@OutPurchUnits	- Output Purchase Units
    *	@OutPurchUC		- Output Purchase Unit Cost
    *   @msg			- error message 
    *
    * RETURN VALUE
    *   0 - Success
    *   1 - Failure
    *****************************************************/
   (@PMCo bCompany = NULL, @Project bJob = NULL, @SubCO smallint = NULL, @SubCOSeq int = NULL,
    @PCOType bDocType = NULL, @PCO bPCO = NULL, @PCOItem bPCOItem = NULL, 
	@InPhase bPhase = NULL, @OutPhase bPhase = NULL output,
	@InCostType bJCCType = NULL, @OutCostType bJCCType = NULL output,
    @InVendor bVendor = NULL, @OutVendor bVendor = NULL output,
    @InSL varchar(30) = NULL, @OutSL varchar(30) = NULL output,
    @InItem bItem = NULL, @OutItem bItem = NULL output,
    @Units bUnits = NULL output, @UM bUM = NULL output, 
    @UnitCost bUnitCost = NULL output, @Amount bDollar = NULL output,
    @Interfaced bYN output,
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
 
	IF @SubCO IS NULL
		BEGIN
			SET @msg = 'Missing SubCO!'
			SET @rcode = 1
			GOTO vspexit
		END
   
	IF @SubCOSeq IS NULL
		BEGIN
			SET @msg = 'Missing SubCOSeq!'
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
		

		
	------------------------------------------------
	-- CHECK FOR VALID SubCO/SubCOSeq COMBINATION --
	------------------------------------------------
	----TK-06039
	SELECT	@OutPhase = l.Phase, @OutCostType = l.CostType, @OutVendor = l.Vendor, @OutSL = l.SL,
			@OutItem = l.SLItem, @Units = l.Units, @UM = l.UM, @UnitCost = l.UnitCost, @Amount = l.Amount,
			@Interfaced = case when l.InterfaceDate is not null then 'Y' else 'N' end
	FROM	dbo.PMSubcontractCO sco
	LEFT JOIN	dbo.PMSL l on sco.PMCo = l.PMCo 
							  and sco.Project = l.Project 
							  AND l.Seq = @SubCOSeq
    WHERE	sco.PMCo = @PMCo
       AND	sco.Project = @Project
       AND	sco.SubCO = @SubCO
       AND	l.Seq = @SubCOSeq
        
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'SubCO/SubCOSeq combination not valid!'
			SET @rcode = 1
			GOTO vspexit
		 END
	
	----------------------------------------------------------
	-- CHECK IF IT HAS ALREADY BEEN USED ON A DIFFERENT PCO --
	----------------------------------------------------------
	SELECT TOP 1 1
	  FROM dbo.PMOL 
	 WHERE PMCo = @PMCo 
	   AND Project = @Project AND SubCO = @SubCO AND SubCOSeq = @SubCOSeq
		   							  												  
	IF @@ROWCOUNT <> 0 
		BEGIN
			-- CLEAR OUTPUT PARAMETERS --
			SET @OutPhase = NULL
			SET @OutCostType = NULL
			SET @OutVendor = NULL
			SET @OutSL = NULL
			SET @OutItem = NULL
				
			-- ERROR --
			SET @msg = 'SubCO/SubCOSeq combination already in use!'
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
			SET @OutSL = NULL
			SET @OutItem = NULL
				
			-- ERROR --
			SET @msg = 'Phase/CostType exists!'
			SET @rcode = 1
			GOTO vspexit
		END
   
     
   
   
   
	vspexit:
		return @rcode
		
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSubCOSeqVal] TO [public]
GO
