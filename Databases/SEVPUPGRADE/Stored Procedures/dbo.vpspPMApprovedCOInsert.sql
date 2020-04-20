SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMApprovedCOInsert]
/************************************************************
* CREATED:		5/2/06		chs
* MODIFIED:		6/15/06		chs
* MODIFIED:		10/30/06	chs
* MODIFIED:		6/13/07		CHS
*				GF 09/03/2010 - issue #141031 change to use date only function
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts PM Approved Change Orders
*   
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @ACO bACO,
      @Description VARCHAR(60),
	--@ACOSequence int,
      @ACOSequence VARCHAR(10),
      @Issue bIssue,
      @Contract bContract,
      @ChangeDays SMALLINT,
      @NewCmplDate bDate,
      @IntExt CHAR(1),
      @DateSent bDate,
      @DateReqd bDate,
      @DateRecd bDate,
      @ApprovalDate bDate,
      @ApprovedBy VARCHAR(30),
      @BillGroup bBillingGroup,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    SET NOCOUNT ON ;
	
    DECLARE @nextACOSequence SMALLINT,
        @dfltstatus VARCHAR(6),
        @msg VARCHAR(255),
        @rcode INT

    IF @Issue = -1 
        SET @Issue = NULL

    SET @Contract = ( SELECT    Contract
                      FROM      JCJM
                      WHERE     @PMCo = JCCo
                                AND @Project = Job
                    )
    SET @msg = NULL
    EXEC @rcode = dbo.vpspPMOHACOSeqGet @PMCo, @Project, @ACO,
        @nextACOSequence OUTPUT, @dfltstatus OUTPUT, @msg OUTPUT
    SET @ACOSequence = @nextACOSequence

    SET @msg = NULL
    EXEC @rcode = dbo.vpspFormatDatatypeField 'bDocument', @ACO, @msg OUTPUT
    SET @ACO = @msg

----#141031
    IF @ApprovalDate IS NULL 
        SET @ApprovalDate = dbo.vfDateOnly()

	
    INSERT  INTO PMOH
            ( PMCo,
              Project,
              ACO,
              Description,
              ACOSequence,
              Issue,
              Contract,
              ChangeDays,
              NewCmplDate,
              IntExt,
              DateSent,
              DateReqd,
              DateRecd,
              ApprovalDate,
              ApprovedBy,
              BillGroup,
              Notes,
              UniqueAttchID
            )
    VALUES  ( @PMCo,
              @Project,
              @ACO,
              @Description,
              @ACOSequence,
              @Issue,
              @Contract,
              @ChangeDays,
              @NewCmplDate,
              @IntExt,
              @DateSent,
              @DateReqd,
              @DateRecd,
              @ApprovalDate,
              @ApprovedBy,
              @BillGroup,
              @Notes,
              @UniqueAttchID
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMApprovedCOGet @PMCo, @Project, @KeyID


GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOInsert] TO [VCSPortal]
GO
