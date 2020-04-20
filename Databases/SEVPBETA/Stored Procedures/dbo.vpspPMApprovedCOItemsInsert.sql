SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMApprovedCOItemsInsert]
/***********************************************************
* Created:     8/28/09		JB		Rewrote SP/cleanup
* Modified:		GF 09/03/2010 - issue #141031 change to use date only function
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a PM Approved Change Order Item.
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
	SET NOCOUNT ON;
	DECLARE @nextACOItem INT, @DocCat VARCHAR(10), @msg VARCHAR(255)
	SET @DocCat = 'ACO'

	--ACOItem Validation
	IF (ISNULL(@ACOItem, '') = '' OR @ACOItem = '+' OR @ACOItem = 'n' OR @ACOItem = 'N')
	BEGIN
		SET @nextACOItem = (SELECT ISNULL(MAX(ACOItem), 0) + 1 FROM PMOI WITH (NOLOCK)
							WHERE PMCo = @PMCo AND Project = @Project AND ACO = @ACO
							AND ISNUMERIC(ACOItem) = 1 AND ACOItem NOT LIKE '%.%' 
							AND SUBSTRING(LTRIM(ACOItem), 1, 1) <> '0')
		SET @msg = NULL
		EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextACOItem, @msg OUTPUT
		SET @ACOItem = @msg
	END
	ELSE
	BEGIN
		SET @msg = NULL
		EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @ACOItem, @msg OUTPUT
		SET @ACOItem = @msg
	END
	
	--Issue Validation
	IF (@Issue = -1) SET @Issue = NULL
	
	--Status Code Validation
	IF ([dbo].vpfPMValidateStatusCode(@Status, @DocCat)) = 0
	BEGIN
		SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '') + ' is not valid for Document Category: ' + ISNULL(@DocCat, '') + '.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	--UM Validation
	IF (@UM <> 'LS')
	BEGIN
		SET @ApprovedAmt = @Units * @UnitPrice
	END
	ELSE
	BEGIN
		SET @ApprovedAmt = @ApprovedAmt
		SET @Units = 0
		SET @UnitPrice = 0	
	END
	
	--Approved Validation
	IF @Approved = 'Y'
	BEGIN
		SET @ApprovedBy = (SELECT FirstName + ' ' + LastName FROM pUsers WHERE UserID = @UserID)
		----#141031
		SET @ApprovedDate = dbo.vfDateOnly()
		END
	ELSE
	BEGIN
		SET @ApprovedBy = ''
		SET @ApprovedDate = NULL
	END
	
	--Insert the ACO Item
	INSERT INTO PMOI
		( PMCo
		, Project
		, PCOType
		, PCO
		, PCOItem
		, ACO
		, ACOItem
		, Description
		, Status
		, ApprovedDate
		, UM
		, Units
		, UnitPrice
		, PendingAmount
		, ApprovedAmt
		, Issue
		, Date1
		, Date2
		, Date3
		, Contract
		, ContractItem
		, Approved
		, ApprovedBy
		, ForcePhaseYN
		, FixedAmountYN
		, FixedAmount
		, Notes
		, BillGroup
		, ChangeDays
		, UniqueAttchID
		, InterfacedDate
		) 

	VALUES 
		( @PMCo
		, @Project
		, @PCOType
		, @PCO
		, @PCOItem
		, @ACO
		, @ACOItem
		, @Description
		, @Status
		, @ApprovedDate
		, @UM
		, @Units
		, @UnitPrice
		, @PendingAmount
		, @ApprovedAmt
		, @Issue
		, @Date1
		, @Date2
		, @Date3
		, @Contract
		, @ContractItem
		, @Approved
		, @ApprovedBy
		, @ForcePhaseYN
		, @FixedAmountYN
		, @FixedAmount
		, @Notes
		, @BillGroup
		, @ChangeDays
		, @UniqueAttchID
		, @InterfacedDate
		)


	--Get the current updated record
	DECLARE @KeyID INT
	SET @KeyID = SCOPE_IDENTITY()
	EXECUTE vpspPMApprovedCOItemsGet @PMCo, @Project, @ACO, @UserID, @KeyID

	vspExit:
	
END
GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOItemsInsert] TO [VCSPortal]
GO
