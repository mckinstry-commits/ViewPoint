SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMIssueUpdate]
/************************************************************
* CREATED:     3/16/06  chs
* Modified:		11/7/06 chs
*				GF 10/26/2010 - issue #141031 change to use vfDateOnly function
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				DAN SO - 11/08/2011 - TK-09596 - added RelatedFirm and RelatedFirmContact
*				DAN SO - 11/15/2011 - TK-10037 - Update ImpactYN flags
*				DAN SO - 12/05/2011 - D-03705 - Type field not required
* USAGE:
*   Updates the PM Project Issues
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @Issue bIssue,
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
      @RelatedFirmContact bEmployee, 
      @Original_Issue bIssue,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DateInitiated bDate,
      @Original_DateResolved bDate,
      @Original_Description bDesc,
      @Original_FirmNumber bFirm,
      @Original_Initiator bEmployee,
      @Original_MasterIssue bIssue,
      @Original_Status TINYINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup bGroup,
      @Original_IssueInfo VARCHAR(MAX),
      @Original_DescImpact bItemDesc,
      @Original_DaysImpact SMALLINT,
      @Original_CostImpact bDollar,
      @Original_ROMImpact bDollar,
      @Original_Type bDocType,
      @Original_Reference VARCHAR(30),
      @Original_RelatedFirm bFirm,                      
      @Original_RelatedFirmContact bEmployee
    )
AS 
    SET NOCOUNT ON ;

    DECLARE @msg VARCHAR(255)

    IF @DateResolved = '1900-01-11 00:00:00' 
        SET @DateResolved = NULL
    IF @DateResolved = 'Jan  1 1900 12:00AM' 
        SET @DateResolved = NULL
	

	--IF @Status > 0 and @Original_Status < 1 set @DateResolved = getdate()
	----#141031
    IF @DateInitiated IS NULL 
        SET @DateInitiated = dbo.vfDateOnly()

    IF @MasterIssue = -1 
        SET @MasterIssue = NULL
    IF @Original_MasterIssue = -1 
        SET @Original_MasterIssue = NULL
    IF @Initiator = -1 
        SET @Initiator = NULL
    IF @Original_Initiator = -1 
        SET @Original_Initiator = NULL
	
	
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

    UPDATE  PMIM
    SET     Description = @Description,
            DateInitiated = @DateInitiated,
            Initiator = @Initiator,
            MasterIssue = @MasterIssue,
            DateResolved = @DateResolved,
            Status = @Status,
            Notes = @Notes,
            IssueInfo = @IssueInfo,
            DescImpact = @DescImpact,
            DaysImpact = @DaysImpact,
            DaysImpactYN = CASE WHEN @DaysImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
            CostImpact = @CostImpact,
            CostImpactYN = CASE WHEN @CostImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
            ROMImpact = @ROMImpact,
            ROMImpactYN = CASE WHEN @ROMImpact IS NOT NULL THEN 'Y' ELSE 'N' END,		--TK-10037
            [Type] = @Type,
            Reference = @Reference,
            RelatedFirm = @RelatedFirm,
            RelatedFirmContact = @RelatedFirmContact
                 
    WHERE   ( Issue = @Original_Issue )
            AND ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( DateInitiated = @Original_DateInitiated
                  OR @Original_DateInitiated IS NULL
                  AND DateInitiated IS NULL
                )
            AND ( DateResolved = @Original_DateResolved
                  OR @Original_DateResolved IS NULL
                  AND DateResolved IS NULL
                )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( FirmNumber = @Original_FirmNumber
                  OR @Original_FirmNumber IS NULL
                  AND FirmNumber IS NULL
                ) 
--AND (Initiator = @Original_Initiator OR @Original_Initiator IS NULL AND Initiator IS NULL) 
            AND ( MasterIssue = @Original_MasterIssue
                  OR @Original_MasterIssue IS NULL
                  AND MasterIssue IS NULL
                )
            AND ( Status = @Original_Status
                  OR @Original_Status IS NULL
                  AND Status IS NULL
                )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                )
            AND ( IssueInfo = @Original_IssueInfo
                  OR @Original_IssueInfo IS NULL
                  AND IssueInfo IS NULL
                )
            AND ( DescImpact = @Original_DescImpact
                  OR @Original_DescImpact IS NULL
                  AND DescImpact IS NULL
                )
            AND ( DaysImpact = @Original_DaysImpact
                  OR @Original_DaysImpact IS NULL
                  AND DaysImpact IS NULL
                )
            AND ( CostImpact = @Original_CostImpact
                  OR @Original_CostImpact IS NULL
                  AND CostImpact IS NULL
                )
            AND ( ROMImpact = @Original_ROMImpact
                  OR @Original_ROMImpact IS NULL
                  AND ROMImpact IS NULL
                )
            AND ( [Type] = @Original_Type
                  OR @Original_Type IS NULL
                  AND [Type] IS NULL
                )
            AND ( Reference = @Original_Reference
                  OR @Original_Reference IS NULL
                  AND Reference IS NULL
                ) 
            AND ( RelatedFirm = @Original_RelatedFirm
                  OR @Original_RelatedFirm IS NULL
                  AND RelatedFirm IS NULL
                )
            AND ( RelatedFirmContact = @Original_RelatedFirmContact
                  OR @Original_RelatedFirmContact IS NULL
                  AND RelatedFirmContact IS NULL
                );




GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueUpdate] TO [VCSPortal]
GO
