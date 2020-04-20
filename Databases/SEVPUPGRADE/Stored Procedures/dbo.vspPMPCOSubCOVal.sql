SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE  proc [dbo].[vspPMPCOSubCOVal]
/***********************************************************
* Created By:	DAN SO 3/15/2011 - B-02352 - SCO - PCO Integration - pull info
* Modified By:	DAN SO 05/02/2011 - AT-02070 - Attempt to default SubCOSeq
*				GF 06/20/2011 - TK-06029 loosen validation
*
* USAGE:
*	Validate SubCO is valid for a specific PCOItem
*
* INPUT PARAMETERS
*   PMCo		- PM Company
*   Project		- PM Project
*   SubCO		- SubCO from PMSL
*   SubCOSeq	- Seq from PMSubcontractCO
*	POItem		- PO Item
*
* OUTPUT PARAMETERS
*	@SubCOSeqOut	- Default Subcontract Change Order Sequence
*   @msg			- error message 

* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@PMCo bCompany = NULL, @Project bJob = NULL, @SubCO smallint = NULL,
 @SubCOSeq int = NULL, @Phase bPhase = NULL, @CostType bJCCType = NULL,
 @Vendor bVendor = NULL, @SL varchar(30) = null, @SLItem bItem = NULL, 
 @SubCOSeqOut int output, @msg varchar(255) output)
AS
SET NOCOUNT ON


DECLARE @Count	int,
		@Approved CHAR(1),
		@rcode int
   
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
		goto vspexit
	END

IF @Project IS NULL
	BEGIN
		SET @msg = 'Missing Project!'
		SET @rcode = 1
		goto vspexit
	END

IF @SubCO IS NULL
	BEGIN
		SET @msg = 'Missing SubCO!'
		SET @rcode = 1
		goto vspexit
	END

----TK-06029
SET @SubCOSeqOut = NULL
---- validate subcontract change order is valid
SELECT @msg = s.[Description], @Approved = h.Approved
FROM dbo.PMSubcontractCO s
INNER JOIN dbo.SLHD h ON h.SLCo=s.SLCo AND h.SL=s.SL
WHERE	s.PMCo = @PMCo
		AND	s.Project = @Project
		AND	s.SubCO = @SubCO
IF @@ROWCOUNT = 0
	BEGIN
	SET @msg = 'SubCO is NOT valid!'
	SET @rcode = 1
	goto vspexit
	END

---- subcontract must be approved
IF @Approved = 'N'
	BEGIN
	SET @msg = 'Subcontract has not been approved.'
	SET @rcode = 1
	goto vspexit
	END


---- try to find a default PMSL sequence to use as a default
---- there can only be one sequence for a default
SELECT @SubCOSeqOut = l.Seq
FROM dbo.PMSL l
WHERE	l.PMCo = @PMCo
	AND	l.Project = @Project
	AND	(l.Phase = @Phase OR @Phase IS NULL)
	AND	(l.CostType = @CostType OR @CostType IS NULL)
	AND	(l.Vendor = @Vendor OR @Vendor IS NULL)
	AND	(l.SL = @SL OR @SL IS NULL)
	AND	(l.Seq = @SubCOSeq or @SubCOSeq IS NULL)
	AND	(l.SLItem = @SLItem or @SLItem IS NULL)
---- store record count
SET @Count = @@ROWCOUNT

	-- AT-02070 --
	IF @Count = 1
		BEGIN
			---- DO NOT DEFAULT IF @POCONumSeqOut IS ALREADY IS USE --
			IF EXISTS (SELECT TOP 1 1 
						 FROM PMOL WITH (NOLOCK) 
						WHERE PMCo = @PMCo 
						  AND Project = @Project AND SubCO = @SubCO
						  AND SubCOSeq = @SubCOSeq)
						  
					SET @SubCOSeqOut = NULL
						
		END -- IF @Count = 1
		
	ELSE
		-- @Count <> 1 -- CLEAR @POCONumSeqOut
		SET @SubCOSeqOut = NULL

   
   
	vspexit:
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSubCOVal] TO [public]
GO
