SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMPendingCOItemsInsert]
/***********************************************************
* Created:     8/28/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a PM Pending Change Order Item.
************************************************************/
    (
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
      @UserID INT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
	
        DECLARE @FirstLastName VARCHAR(128),
            @nextPCOItem INT,
            @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'PCO'

	--Issue Validation
        IF ( @Issue = -1 ) 
            SET @Issue = NULL
	
	--Status Validation
        IF @Status IS NULL 
            SET @Status = ( SELECT  BeginStatus
                            FROM    PMCO
                            WHERE   PMCo = @PMCo
                          )
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END

	--PCOItem Validation
        IF @PCOItem IS NULL 
            BEGIN
                SET @nextPCOItem = ( SELECT ISNULL(MAX(PCOItem), 0) + 1
                                     FROM   PMOI WITH ( NOLOCK )
                                     WHERE  PMCo = @PMCo
                                            AND Project = @Project
                                            AND PCO = @PCO
                                            AND ISNUMERIC(PCOItem) = 1
                                            AND PCOItem NOT LIKE '%.%'
                                            AND SUBSTRING(LTRIM(PCOItem), 1, 1) <> '0'
                                   )
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextPCOItem,
                    @msg OUTPUT
                SET @PCOItem = @msg
            END
        ELSE 
            BEGIN
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @PCOItem,
                    @msg OUTPUT
                SET @PCOItem = @msg
            END
	
	--UM Validation
        IF ( @UM = 'LS' ) 
            BEGIN
                SET @Units = 0
                SET @UnitPrice = 0
            END	

	--Insert the PCO Item
        INSERT  INTO PMOI
                ( PMCo,
                  Project,
                  PCOType,
                  PCO,
                  PCOItem,
                  ACO,
                  ACOItem,
                  Description,
                  Status,
                  ApprovedDate,
                  UM,
                  Units,
                  UnitPrice,
                  PendingAmount,
                  ApprovedAmt,
                  Issue,
                  Date1,
                  Date2,
                  Date3,
                  Contract,
                  ContractItem,
                  Approved,
                  ApprovedBy,
                  ForcePhaseYN,
                  FixedAmountYN,
                  FixedAmount,
                  Notes,
                  BillGroup,
                  ChangeDays,
                  UniqueAttchID,
                  InterfacedDate
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @PCOType,
                  @PCO,
                  @PCOItem,
                  @ACO,
                  @ACOItem,
                  @Description,
                  @Status,
                  @ApprovedDate,
                  @UM,
                  @Units,
                  @UnitPrice,
                  @PendingAmount,
                  @ApprovedAmt,
                  @Issue,
                  @Date1,
                  @Date2,
                  @Date3,
                  @Contract,
                  @ContractItem,
                  @Approved,
                  @FirstLastName,
                  @ForcePhaseYN,
                  @FixedAmountYN,
                  @FixedAmount,
                  @Notes,
                  @BillGroup,
                  @ChangeDays,
                  @UniqueAttchID,
                  @InterfacedDate
		    )

	--Get the current updated record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMPendingCOItemsGet @PMCo, @Project, @PCO, @PCOType,
            @UserID, @KeyID
	
        vspExit:
    END



GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOItemsInsert] TO [VCSPortal]
GO
