SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCOItemsDelete]
/************************************************************
* CREATED:     5/2/06 chs
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 09/26/2011 TK-08655 check for detail in PMOL before delete
*
* USAGE:
*   Deletes the PM Approved Change Orders Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PCOType bDocType,
      @Original_PCO bPCO,
      @Original_PCOItem bPCOItem,
      @Original_ACO bACO,
      @Original_ACOItem bACOItem,
      @Original_Description bDesc,
      @Original_Status bStatus,
      @Original_ApprovedDate bDate,
      @Original_UM bUM,
      @Original_Units bUnits,
      @Original_UnitPrice bUnitCost,
      @Original_PendingAmount bDollar,
      @Original_ApprovedAmt bDollar,
      @Original_Issue bIssue,
      @Original_Date1 bDate,
      @Original_Date2 bDate,
      @Original_Date3 bDate,
      @Original_Contract bContract,
      @Original_ContractItem bContractItem,
      @Original_Approved bYN,
      @Original_ApprovedBy bVPUserName,
      @Original_ForcePhaseYN bYN,
      @Original_FixedAmountYN bYN,
      @Original_FixedAmount bDollar,
      @Original_Notes VARCHAR(MAX),
      @Original_BillGroup bBillingGroup,
      @Original_ChangeDays SMALLINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_InterfacedDate bDate
    )
AS 
SET NOCOUNT ON ;


---- TK-08655
DECLARE @rcode int, @Message varchar(255)
SET @rcode = 0
SET @Message = ''

---- check if PCO item has been approved
IF EXISTS(SELECT 1 FROM dbo.PMOI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND PCOItem = @Original_PCOItem AND ACO IS NOT NULL)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Pending Change Order Item has been approved!'
	GoTo bspmessage
	END

---- check for phase cost type detail
IF EXISTS(SELECT 1 FROM dbo.PMOL WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND PCOItem = @Original_PCOItem)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Pending Change Order Phases exist!'
	GoTo bspmessage
	END

---- check for subcontract detail
IF EXISTS(SELECT 1 FROM dbo.PMSL WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND PCOItem = @Original_PCOItem)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Subcontract detail exists for Pending Change Order!'
	GoTo bspmessage
	END
	
---- check for material detail
IF EXISTS(SELECT 1 FROM dbo.PMMF WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND PCOItem = @Original_PCOItem)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Material detail exists for Pending Change Order!'
	GoTo bspmessage
	END
	

---- delete record	
DELETE  FROM PMOI
WHERE   ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( PCOType = @Original_PCOType
                  OR @Original_PCOType IS NULL
                  AND PCOType IS NULL
                )
            AND ( PCO = @Original_PCO
                  OR @Original_PCO IS NULL
                  AND PCO IS NULL
                )
            AND ( PCOItem = @Original_PCOItem
                  OR @Original_PCOItem IS NULL
                  AND PCOItem IS NULL
                )
            AND ( ACO = @Original_ACO
                  OR @Original_ACO IS NULL
                  AND ACO IS NULL
                )
            AND ( ACOItem = @Original_ACOItem
                  OR @Original_ACOItem IS NULL
                  AND ACOItem IS NULL
                )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( ApprovedDate = @Original_ApprovedDate
                  OR @Original_ApprovedDate IS NULL
                  AND ApprovedDate IS NULL
                )
            AND ( UM = @Original_UM )
            AND ( Units = @Original_Units )
            AND ( UnitPrice = @Original_UnitPrice )
            AND ( PendingAmount = @Original_PendingAmount
                  OR @Original_PendingAmount IS NULL
                  AND PendingAmount IS NULL
                )
            AND ( ApprovedAmt = @Original_ApprovedAmt
                  OR @Original_ApprovedAmt IS NULL
                  AND ApprovedAmt IS NULL
                )
            AND ( Issue = @Original_Issue
                  OR @Original_Issue IS NULL
                  AND Issue IS NULL
                )
            AND ( Date1 = @Original_Date1
                  OR @Original_Date1 IS NULL
                  AND Date1 IS NULL
                )
            AND ( Date2 = @Original_Date2
                  OR @Original_Date2 IS NULL
                  AND Date2 IS NULL
                )
            AND ( Date3 = @Original_Date3
                  OR @Original_Date3 IS NULL
                  AND Date3 IS NULL
                )
            AND ( Contract = @Original_Contract )
            AND ( ContractItem = @Original_ContractItem
                  OR @Original_ContractItem IS NULL
                  AND ContractItem IS NULL
                )
            AND ( Approved = @Original_Approved )
            AND ( ApprovedBy = @Original_ApprovedBy
                  OR @Original_ApprovedBy IS NULL
                  AND ApprovedBy IS NULL
                )
            AND ( ForcePhaseYN = @Original_ForcePhaseYN )
            AND ( FixedAmountYN = @Original_FixedAmountYN )
            AND ( FixedAmount = @Original_FixedAmount
                  OR @Original_FixedAmount IS NULL
                  AND FixedAmount IS NULL
                )
            AND ( BillGroup = @Original_BillGroup
                  OR @Original_BillGroup IS NULL
                  AND BillGroup IS NULL
                )
            AND ( ChangeDays = @Original_ChangeDays
                  OR @Original_ChangeDays IS NULL
                  AND ChangeDays IS NULL
                )
            AND ( InterfacedDate = @Original_InterfacedDate
                  OR @Original_InterfacedDate IS NULL
                  AND InterfacedDate IS NULL
                )


bspexit:
	return @rcode

bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOItemsDelete] TO [VCSPortal]
GO
