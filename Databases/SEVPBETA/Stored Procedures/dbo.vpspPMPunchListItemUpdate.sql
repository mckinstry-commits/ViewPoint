SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   PROCEDURE [dbo].[vpspPMPunchListItemUpdate]
/************************************************************
* CREATED:     3/29/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:
*   Updates PM Punch List Item
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PunchList bDocument,
      @Item SMALLINT,
      @Description VARCHAR(255),
      @VendorGroup bGroup,
      @ResponsibleFirm bFirm,
      @Location VARCHAR(10),
      @DueDate bDate,
      @FinDate bDate,
      @BillableYN bYN,
      @BillableFirm bFirm,
      @Issue bIssue,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_Item SMALLINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PunchList bDocument,
      @Original_BillableFirm bFirm,
      @Original_BillableYN bYN,
      @Original_Description VARCHAR(255),
      @Original_DueDate bDate,
      @Original_FinDate bDate,
      @Original_Issue bIssue,
      @Original_Location VARCHAR(10),
      @Original_ResponsibleFirm bFirm,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup bGroup
    )
AS 
    SET NOCOUNT ON ;


    IF @ResponsibleFirm = -1 
        SET @ResponsibleFirm = NULL
    IF @BillableFirm = -1 
        SET @BillableFirm = NULL


    UPDATE  PMPI
    SET     --PMCo = @PMCo, Project = @Project, PunchList = @PunchList, Item = @Item, 
            Description = @Description,
            VendorGroup = @VendorGroup,
            ResponsibleFirm = @ResponsibleFirm,
            Location = @Location,
            DueDate = @DueDate,
            FinDate = @FinDate,
            BillableYN = @BillableYN,
            BillableFirm = @BillableFirm,
            Issue = @Issue,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( Item = @Original_Item )
            AND ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( PunchList = @Original_PunchList )
            AND ( BillableFirm = @Original_BillableFirm
                  OR @Original_BillableFirm IS NULL
                  AND BillableFirm IS NULL
                )
            AND ( BillableYN = @Original_BillableYN )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( DueDate = @Original_DueDate
                  OR @Original_DueDate IS NULL
                  AND DueDate IS NULL
                )
            AND ( FinDate = @Original_FinDate
                  OR @Original_FinDate IS NULL
                  AND FinDate IS NULL
                )
            AND ( Issue = @Original_Issue
                  OR @Original_Issue IS NULL
                  AND Issue IS NULL
                )
            AND ( Location = @Original_Location
                  OR @Original_Location IS NULL
                  AND Location IS NULL
                )
            AND ( ResponsibleFirm = @Original_ResponsibleFirm
                  OR @Original_ResponsibleFirm IS NULL
                  AND ResponsibleFirm IS NULL
                )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                )
            AND ( VendorGroup = @Original_VendorGroup
                  OR @Original_VendorGroup IS NULL
                  AND VendorGroup IS NULL
                ) ;

    SELECT  PMCo,
            Project,
            PunchList,
            Item,
            Description,
            VendorGroup,
            ResponsibleFirm,
            Location,
            DueDate,
            FinDate,
            BillableYN,
            BillableFirm,
            Issue,
            Notes,
            UniqueAttchID
    FROM    PMPI
    WHERE   ( Item = @Item )
            AND ( PMCo = @PMCo )
            AND ( Project = @Project )
            AND ( PunchList = @PunchList )





GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemUpdate] TO [VCSPortal]
GO
