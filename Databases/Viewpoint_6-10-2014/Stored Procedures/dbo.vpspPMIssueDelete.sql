SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMIssueDelete]
/************************************************************
* CREATED:     3/16/06  chs
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Deletes PM Project Issues
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
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
      @Original_Notes VARCHAR(MAX),
      @Original_IssueInfo VARCHAR(MAX),
      @Original_DescImpact bItemDesc,
      @Original_DaysImpact SMALLINT,
      @Original_CostImpact bDollar,
      @Original_ROMImpact bDollar,
      @Original_Type bDocType,
      @Original_Reference VARCHAR(30)
    )
AS 
    SET NOCOUNT ON ;
	
    DELETE  FROM PMIM
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
            AND ( Initiator = @Original_Initiator
                  OR @Original_Initiator IS NULL
                  AND Initiator IS NULL
                ) 
--AND (MasterIssue = @Original_MasterIssue OR @Original_MasterIssue IS NULL AND MasterIssue IS NULL) 
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
GO
GRANT EXECUTE ON  [dbo].[vpspPMIssueDelete] TO [VCSPortal]
GO
