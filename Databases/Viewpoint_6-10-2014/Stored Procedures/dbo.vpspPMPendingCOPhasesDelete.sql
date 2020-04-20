SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMPendingCOPhasesDelete]
/************************************************************
* CREATED:  5/2/06  chs
*			GF 11/26/2011 TK-10373 do not allow delete if PCO Item approved
*			GF 01/06/2011 TK-11521
*
*
* USAGE:
*   Deletes PM Approved Change Orders Item Detail
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


---- TK-11521
DECLARE @rcode int, @Message varchar(255),
		@Original_PCOType nvarchar(50),
		@Original_PCO NVARCHAR(50),
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50),
		@Original_PCOItem nvarchar(50),
		@Original_InterfacedDate SMALLDATETIME 
SET @rcode = 0
SET @Message = ''

---- GET PCO KEY DATA
SELECT 	@Original_PCOType = PCOType,
		@Original_PCO = PCO,
		@Original_PMCo = PMCo,
		@Original_Project = Project,
		@Original_PCOItem = PCOItem,
		@Original_InterfacedDate = InterfacedDate
FROM dbo.PMOL WHERE KeyID = @KeyID
IF @@ROWCOUNT = 0 RETURN

---- check if PCO item has been approved
IF EXISTS(SELECT 1 FROM dbo.PMOI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND PCOItem = @Original_PCOItem AND ACO IS NOT NULL)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Pending Change Order Item has been approved!'
	GoTo bspmessage
	END

---- cannot delete if interfaced to Job Cost
IF @Original_InterfacedDate IS NOT NULL
	BEGIN
	SET @rcode = 1
	SET @Message = 'Pending Change Order Phase Cost Type record has been interfaced to Job Cost!'
	GoTo bspmessage
	END

---- delete detail
DELETE FROM dbo.PMOL WHERE KeyID = @KeyID


--(
--	@Original_PMCo bCompany,
--	@Original_Project bJob,
--	@Original_PCOType bDocType,
--	@Original_PCO bPCO,
--	@Original_PCOItem bPCOItem,
--	@Original_ACO bACO,
--	@Original_ACOItem bACOItem,
--	@Original_PhaseGroup bGroup,
--	@Original_Phase bPhase,
--	@Original_CostType bJCCType,
--	@Original_EstUnits bUnits,
--	@Original_UM bUM,
--	@Original_UnitHours bHrs,
--	@Original_EstHours bHrs,
--	@Original_HourCost bUnitCost,
--	@Original_UnitCost bUnitCost,
--	@Original_ECM bECM,
--	@Original_EstCost bDollar,
--	@Original_SendYN bYN,
--	@Original_InterfacedDate bDate,
--	@Original_Notes VARCHAR(MAX),
--	@Original_UniqueAttchID uniqueidentifier
--)

--AS
--SET NOCOUNT ON;
	
------ TK-10373
--DECLARE @rcode int, @Message varchar(255)
--SET @rcode = 0
--SET @Message = ''

------ check if PCO item has been approved
--IF EXISTS(SELECT 1 FROM dbo.PMOI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
--				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
--				AND PCOItem = @Original_PCOItem AND ACO IS NOT NULL)
--	BEGIN
--	SET @rcode = 1
--	SET @Message = 'Pending Change Order Item has been approved!'
--	GoTo bspmessage
--	END

--DELETE FROM PMOL

--	WHERE (PMCo = @Original_PMCo) 
--		AND (Project = @Original_Project) 
--		AND (PCOType = @Original_PCOType) 
--		AND (PCO = @Original_PCO) 
--		AND (PCOItem = @Original_PCOItem) 
--		AND (ACO = @Original_ACO) 
--		AND (ACOItem = @Original_ACOItem) 
--		AND (PhaseGroup = @Original_PhaseGroup) 
--		AND (Phase = @Original_Phase) 
--		AND (CostType = @Original_CostType) 
--		AND (EstUnits = @Original_EstUnits) 
--		AND (UM = @Original_UM) 
--		AND (UnitHours = @Original_UnitHours) 
--		AND (EstHours = @Original_EstHours) 
--		AND (HourCost = @Original_HourCost) 
--		AND (UnitCost = @Original_UnitCost) 
--		AND (ECM = @Original_ECM) 
--		AND (EstCost = @Original_EstCost) 
--		AND (SendYN = @Original_SendYN OR @Original_SendYN IS NULL AND SendYN IS NULL) 
--		AND (InterfacedDate = @Original_InterfacedDate OR @Original_InterfacedDate IS NULL AND InterfacedDate IS NULL) 



bspexit:
	return @rcode

bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOPhasesDelete] TO [VCSPortal]
GO
