SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMIssueInsert]
/************************************************************
* CREATED:		3/16/06		chs
* MODIFIED:		6/12/07		CHS
*				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
*				GP 1/28/10 - added IssueInfo, DescImpact, DaysImpact, CostImpact, ROMImpact, Type, and Reference
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				DAN SO - 11/08/2011 - TK-09596 - added RelatedFirm and RelatedFirmContact
*				DAN SO - 11/15/2011 - TK-10037 - Update ImpactYN flags
*				DAN SO - 12/05/2011 - D-03705 - Type field not required
*
* USAGE:
*   Inserts the PM Project Issues
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
	--@Issue bIssue,
      @Issue VARCHAR(10),
      @Description bDesc,
      @DateInitiated bDate,     
      @VendorGroup bGroup,
      @FirmNumber bFirm,
      @Initiator bEmployee,
      @MasterIssue bIssue,
      @DateResolved bDate,
      @Status TINYINT,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @IssueInfo VARCHAR(MAX),
      @DescImpact bItemDesc,
      @DaysImpact SMALLINT,
      @CostImpact bDollar,
      @ROMImpact bDollar,
      @Type bDocType,
      @Reference VARCHAR(30),
      @RelatedFirm bFirm,                      
      @RelatedFirmContact bEmployee
    )
AS 
    SET NOCOUNT ON ;
	
    DECLARE @msg VARCHAR(255)	
	
----#141031
    IF @DateInitiated IS NULL 
        SET @DateInitiated = dbo.vfDateOnly()

	
    IF @Initiator = -1 
        SET @Initiator = NULL
    IF @DateResolved = '1900-01-01 00:00:00' 
        SET @DateResolved = NULL
    IF @DateResolved = 'Jan  1 1900 12:00AM' 
        SET @DateResolved = NULL

    IF @MasterIssue = -1 
        SET @MasterIssue = NULL

	
    DECLARE @NextIssue NVARCHAR(50),
        @OurVendorGroup NVARCHAR(50),
        @OurFirm NVARCHAR(50)

    SET @OurVendorGroup = ( SELECT  VendorGroup
                            FROM    JCJM WITH ( NOLOCK )
                            WHERE   JCJM.JCCo = @PMCo
                                    AND JCJM.Job = @Project
                          )

    SET @NextIssue = ( SELECT   ISNULL(( MAX(Issue) + 1 ), 1)
                       FROM     PMIM WITH ( NOLOCK )
                       WHERE    PMCo = @PMCo
                                AND Project = @Project
                     )


	IF ISNULL(@Type, '') <> ''	-- D-03705 --
		BEGIN
			--validate Type field against PM Document Types
			IF NOT EXISTS ( SELECT TOP 1
									1
							FROM    bPMDT
							WHERE   DocType = @Type ) 
				BEGIN
					SET @msg = 'Type does not exist in PM Document Types. Please enter another.'
					RAISERROR(@msg, 16, 1)
					RETURN
				END
		END


    INSERT  INTO PMIM
            ( PMCo,
              Project,
              Issue,
              Description,
              DateInitiated,
              VendorGroup,
              FirmNumber,
              Initiator,
              MasterIssue,
              DateResolved,
              Status,
              Notes,
              UniqueAttchID,   
              IssueInfo,
              DescImpact,
              DaysImpact,
              DaysImpactYN,
              CostImpact,
              CostImpactYN,
              ROMImpact,
              ROMImpactYN,
              Type,
              Reference,
              RelatedFirm,                     
			  RelatedFirmContact 
            )
    VALUES  ( @PMCo,
              @Project,
              @NextIssue,
              @Description,
              @DateInitiated,
              @OurVendorGroup,
              @FirmNumber,
              @Initiator,
              @MasterIssue,
              @DateResolved,
              @Status,
              @Notes,
              @UniqueAttchID,
              @IssueInfo,
              @DescImpact,
              @DaysImpact,
              CASE WHEN @DaysImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
              @CostImpact,
              CASE WHEN @CostImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
              @ROMImpact,
              CASE WHEN @ROMImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
              @Type,
              @Reference,
              @RelatedFirm,                      
			  @RelatedFirmContact 
            ) ;


    DECLARE @KeyID INT
    SET @KeyID = SCOPE_IDENTITY()
    EXECUTE vpspPMIssueGet @PMCo, @Project, @OurVendorGroup, @KeyID


GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueInsert] TO [VCSPortal]
GO
