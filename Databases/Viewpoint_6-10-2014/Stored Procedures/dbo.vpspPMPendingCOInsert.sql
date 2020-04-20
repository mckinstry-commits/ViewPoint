SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCOInsert]
/************************************************************
* CREATED:     5/2/06 chs
* MODIFIED:    6/15/06 chs
*				GF 09/16/2011 TK-08524 Set Impact Estimate/Contract based on Internal/External
*				GF 11/15/2011 TK-09972 additional fields added in 6.4.0
*				GF 12/06/2011 TK-10599
*
*
* USAGE:
*   Inserts PM Approved Change Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@PCOType bDocType,
	@PCO bPCO,
	@Description VARCHAR(60),
	@Issue bIssue,
	@Contract bContract,
	@PendingStatus tinyint,
	@IntExt char(1),
	@Date1 bDate,
	@Date2 bDate,
	@Date3 bDate,
	@ApprovalDate bDate,
	@Notes VARCHAR(MAX),
	@UniqueAttchID UNIQUEIDENTIFIER
	----TK-09972
	,@DateCreated bDate
	,@Priority TINYINT
	,@Reference VARCHAR(30)
	,@ROMAmount bDollar
	--,@ReasonCode bReasonCode
	--,@Status bStatus
)
AS
	SET NOCOUNT ON;
	
declare @msg varchar(255), @rcode int

set @Contract = (select Contract from JCJM where @PMCo = JCCo and @Project = Job)

set @msg = null
exec @rcode = dbo.vpspFormatDatatypeField 'bDocument', @PCO, @msg output
set @PCO = @msg

if @Issue = -1 set @Issue = null

set @PendingStatus = 0

---- TK-08524
INSERT INTO PMOP(PMCo, Project, PCOType, PCO, Description, Issue, 
		Contract, PendingStatus, IntExt, Date1, Date2, 
		Date3, ApprovalDate, Notes, UniqueAttchID,
		----TK-08524
		BudgetType, ContractType,
		----TK-09972
		DateCreated, Priority, Reference, ROMAmount) 

VALUES (@PMCo, @Project, @PCOType, @PCO, @Description, @Issue, 
		@Contract, @PendingStatus, @IntExt, @Date1, @Date2, 
		@Date3, @ApprovalDate, @Notes, @UniqueAttchID,
		----TK-08524
		'Y', CASE @IntExt WHEN 'E' THEN 'Y' ELSE 'N' END,
		----TK-09972
		@DateCreated, @Priority, @Reference, @ROMAmount);


DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMPendingCOGet @PMCo, @Project, @KeyID

	



GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOInsert] TO [VCSPortal]
GO
