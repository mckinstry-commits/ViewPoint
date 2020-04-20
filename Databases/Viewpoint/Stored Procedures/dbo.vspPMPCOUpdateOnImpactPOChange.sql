SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPMPCOUpdateOnImpactPOChange]
   /***********************************************************
    * Created By:		JG	01/10/2012 - TK-11624
    * Code Reviewed By:	
    * Modified By:		
    * Purpose:		Called in PMPCOS when ImpactSL is changed to look for 
    *				PCO Items associated with the PCO. 
    *****************************************************/
   (@PMCo bCompany, @Project dbo.bJob, @PCOType dbo.bDocType, @PCO dbo.bPCO, @Checked dbo.bYN, @RemoveRecords dbo.bYN, 
   @dataToRemove dbo.bYN OUTPUT, @alreadyChecked dbo.bYN OUTPUT, @complete dbo.bYN OUTPUT
   , @msg VARCHAR(255) OUTPUT)
   as
   set nocount on
   
declare @rcode int

select @rcode = 0, @dataToRemove = 'N', @complete = 'N'

--------------
--VALIDATION--
--------------
if @PMCo is null
begin
	select @msg = 'Missing PM Company.', @rcode = 1
	goto vspexit
end

if @Project is null
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end

if @PCOType is null
begin
	select @msg = 'Missing PCO Type.', @rcode = 1
	goto vspexit
end

if @PCO is null
begin
	select @msg = 'Missing PCO.', @rcode = 1
	goto vspexit
END

IF @Checked IS NULL
BEGIN
	select @msg = 'Missing Impact PO Flag.', @rcode = 1
	goto vspexit
END

------------------------------------
--CHECK FOR ITEM DETAILS--
------------------------------------
IF @Checked = 'Y'
BEGIN
	-- Add PMMF records for the PCO Item Detail records that are SL types
	EXEC @rcode = vspPMPCOAddPMMFRecords @PMCo, @Project, @PCOType, @PCO, @msg
	
	IF @rcode <> 0
	BEGIN
		GOTO vspexit
	END
	ELSE
	BEGIN
		GOTO vspcomplete
	END
END
ELSE
BEGIN
	IF EXISTS (	SELECT 1 
				FROM dbo.PMOL
					JOIN dbo.PMMF 
					ON PMMF.PMCo = PMOL.PMCo
					AND PMMF.Project = PMOL.Project
					AND PMMF.PCOType = PMOL.PCOType
					AND PMMF.PCO = PMOL.PCO
					AND PMMF.PCOItem = PMOL.PCOItem
					AND PMMF.PhaseGroup = PMOL.PhaseGroup
					AND PMMF.Phase = PMOL.Phase
					AND PMMF.CostType = PMOL.CostType
				WHERE PMOL.PMCo = @PMCo 
				AND PMOL.Project = @Project
				AND PMOL.PCOType = @PCOType 
				AND PMOL.PCO = @PCO
				AND (PMOL.POCONum IS NOT NULL 
				OR PMMF.InterfaceDate IS NOT NULL)
				)
	BEGIN
		select @rcode = 1, @msg = 'PO Impact cannot change due to PCO Item Detail records being used on Purchase Order COs or having been interfaced.'
		goto vspexit
	END
END	


------------------------------------
--CHECK FOR ITEM DETAILS--
------------------------------------
if @alreadyChecked = 'N'
begin
	
	IF EXISTS	(	SELECT 1 
					FROM dbo.PMOL
					JOIN dbo.PMMF 
						ON PMMF.PMCo = PMOL.PMCo
						AND PMMF.Project = PMOL.Project
						AND PMMF.PCOType = PMOL.PCOType
						AND PMMF.PCO = PMOL.PCO
						AND PMMF.PCOItem = PMOL.PCOItem
						AND PMMF.PhaseGroup = PMOL.PhaseGroup
						AND PMMF.Phase = PMOL.Phase
						AND PMMF.CostType = PMOL.CostType
					WHERE PMOL.PMCo = @PMCo 
					AND PMOL.Project = @Project
					AND PMOL.PCOType = @PCOType 
					AND PMOL.PCO = @PCO
				)
	BEGIN
		SET @dataToRemove = 'Y'
	END
		
	SET @alreadyChecked = 'Y'
	GOTO vspexit
END

-----------------------
--REMOVE PMMF RECORDS--
-----------------------
IF @RemoveRecords = 'Y'
BEGIN
	DELETE
	FROM dbo.bPMMF
	WHERE PMCo = @PMCo 
		AND Project = @Project
		AND PCOType = @PCOType 
		AND PCO = @PCO
		AND POCONum IS NULL
		AND InterfaceDate IS NULL	
END

vspcomplete:
	set @complete = 'Y'

   
vspexit:
   	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOUpdateOnImpactPOChange] TO [public]
GO
