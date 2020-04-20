SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCOItemsUpdate]
/***********************************************************
* Created:     8/28/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Update the PM Pending Change Order Item.
************************************************************/
    (
      @KeyID BIGINT,
      @PMCo bCompany,
      @Project bJob,
      @PCOType bDocType,
      @PCO bPCO,
      @PCOItem bPCOItem,
      @ACO bACO,
      @ACOItem bACOItem,
      @Description bDesc,
      @Status bStatus,
      @ApprovedDate bDate,
      @UM bUM,
      @Units bUnits,
      @UnitPrice bUnitCost,
      @PendingAmount bDollar,
      @ApprovedAmt bDollar,
      @Issue bIssue,
      @Date1 bDate,
      @Date2 bDate,
      @Date3 bDate,
      @Contract bContract,
      @ContractItem bContractItem,
      @Approved bYN,
      @ApprovedBy bVPUserName,
      @ForcePhaseYN bYN,
      @FixedAmountYN bYN,
      @FixedAmount bDollar,
      @Notes VARCHAR(MAX),
      @BillGroup bBillingGroup,
      @ChangeDays SMALLINT,
      @UniqueAttchID UNIQUEIDENTIFIER,
      @InterfacedDate bDate,
      @Original_KeyID BIGINT,
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
      @Original_InterfacedDate bDate,
      @UserID INT
    )
AS 
SET NOCOUNT ON ;
        
        
DECLARE @DocCat VARCHAR(10), @msg VARCHAR(255)
SET @DocCat = 'PCO'

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
	
	--Issue Validation
        IF ( @Issue = -1 ) 
            SET @Issue = NULL
	
	--Status Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--UM Validation
        IF ( @UM = 'LS' ) 
            BEGIN
                SET @Units = 0
                SET @UnitPrice = 0
            END
	
	
	--Update the PCO Item 
        UPDATE  PMOI
        SET     Description = @Description,
                Status = @Status,
                ApprovedDate = @ApprovedDate,
                UM = @UM,
                Units = @Units,
                UnitPrice = @UnitPrice,
                PendingAmount = @PendingAmount,
                ApprovedAmt = @ApprovedAmt,
                Issue = @Issue,
                Date1 = @Date1,
                Date2 = @Date2,
                Date3 = @Date3,
                Contract = @Contract,
                ContractItem = @ContractItem,
                Approved = @Approved,
                ApprovedBy = @ApprovedBy,
                ForcePhaseYN = @ForcePhaseYN,
                FixedAmountYN = @FixedAmountYN,
                FixedAmount = @FixedAmount,
                Notes = @Notes,
                BillGroup = @BillGroup,
                ChangeDays = @ChangeDays,
                UniqueAttchID = @UniqueAttchID,
                InterfacedDate = @InterfacedDate
        WHERE   PMCo = @Original_PMCo
                AND Project = @Original_Project
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
	
	--Get the current updated record
        EXECUTE vpspPMPendingCOItemsGet @PMCo, @Project, @PCO, @PCOType,
            @UserID, @KeyID
	
vspExit:
	RETURN @rcode


bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOItemsUpdate] TO [VCSPortal]
GO
