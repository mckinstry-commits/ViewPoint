SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMApprovedCOPhasesDelete]
/************************************************************
* CREATED:     5/2/06  chs
* Modified By:	GF 01/09/2011 TK-11594
*
*
*
* USAGE:
*   Deletes the PM Approved Change Orders Phase
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;

---- TK-11594
DECLARE @rcode int, @Message varchar(255),
		@Original_ACO NVARCHAR(50),
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50),
		@Original_ACOItem nvarchar(50),
		@Original_InterfacedDate SMALLDATETIME 
SET @rcode = 0
SET @Message = ''

---- GET ACO KEY DATA
SELECT 	@Original_ACO = ACO,
		@Original_PMCo = PMCo,
		@Original_Project = Project,
		@Original_ACOItem = ACOItem,
		@Original_InterfacedDate = InterfacedDate
FROM dbo.PMOL WHERE KeyID = @KeyID
IF @@ROWCOUNT = 0 RETURN

---- cannot delete if interfaced to Job Cost
IF @Original_InterfacedDate IS NOT NULL
	BEGIN
	SET @rcode = 1
	SET @Message = 'Approved Change Order Phase Cost Type record has been interfaced to Job Cost!'
	GoTo bspmessage
	END

---- delete detail
DELETE FROM dbo.PMOL WHERE KeyID = @KeyID


bspexit:
	return @rcode

bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode



----(
----	@Original_PMCo bCompany,
----	@Original_Project bJob,
----	@Original_PCOType bDocType,
----	@Original_PCO bPCO,
----	@Original_PCOItem bPCOItem,
----	@Original_ACO bACO,
----	@Original_ACOItem bACOItem,
----	@Original_PhaseGroup bGroup,
----	@Original_Phase bPhase,
----	@Original_CostType bJCCType,
----	@Original_EstUnits bUnits,
----	@Original_UM bUM,
----	@Original_UnitHours bHrs,
----	@Original_EstHours bHrs,
----	@Original_HourCost bUnitCost,
----	@Original_UnitCost bUnitCost,
----	@Original_ECM bECM,
----	@Original_EstCost bDollar,
----	@Original_SendYN bYN,
----	@Original_InterfacedDate bDate,
----	@Original_Notes VARCHAR(MAX),
----	@Original_UniqueAttchID uniqueidentifier
----)

----AS
----	SET NOCOUNT ON;
	
----DELETE FROM PMOL

----	WHERE (PMCo = @Original_PMCo) 
----		AND (Project = @Original_Project) 
----		AND (PCOType = @Original_PCOType) 
----		AND (PCO = @Original_PCO) 
----		AND (PCOItem = @Original_PCOItem) 
----		AND (ACO = @Original_ACO) 
----		AND (ACOItem = @Original_ACOItem) 
----		AND (PhaseGroup = @Original_PhaseGroup) 
----		AND (Phase = @Original_Phase) 
----		AND (CostType = @Original_CostType) 
----		AND (EstUnits = @Original_EstUnits) 
----		AND (UM = @Original_UM) 
----		AND (UnitHours = @Original_UnitHours) 
----		AND (EstHours = @Original_EstHours) 
----		AND (HourCost = @Original_HourCost) 
----		AND (UnitCost = @Original_UnitCost) 
----		AND (ECM = @Original_ECM) 
----		AND (EstCost = @Original_EstCost) 
----		AND (SendYN = @Original_SendYN OR @Original_SendYN IS NULL AND SendYN IS NULL) 
----		AND (InterfacedDate = @Original_InterfacedDate OR @Original_InterfacedDate IS NULL AND InterfacedDate IS NULL) 



GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOPhasesDelete] TO [VCSPortal]
GO
