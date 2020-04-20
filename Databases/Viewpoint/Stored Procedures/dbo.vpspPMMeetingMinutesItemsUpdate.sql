SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesItemsUpdate]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Update a meeting minutes item.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @MeetingType bDocType,
      @Meeting INT,
      @MinutesType TINYINT,
      @Item INT,
      @OriginalItem VARCHAR(10),
      @Minutes VARCHAR(MAX),
      @VendorGroup bGroup,
      @InitFirm bFirm,
      @Initiator bEmployee,
      @ResponsibleFirm bFirm,
      @ResponsiblePerson bEmployee,
      @InitDate bDate,
      @DueDate bDate,
      @FinDate bDate,
      @Status bStatus,
      @Issue bIssue,
      @UniqueAttchID UNIQUEIDENTIFIER,
      @KeyID BIGINT,
      @Original_Item INT,
      @Original_Meeting INT,
      @Original_MeetingType bDocType,
      @Original_MinutesType TINYINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_DueDate bDate,
      @Original_FinDate bDate,
      @Original_InitDate bDate,
      @Original_InitFirm bFirm,
      @Original_Initiator bEmployee,
      @Original_Issue bIssue,
      @Original_OriginalItem VARCHAR(10),
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_Status bStatus,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup bGroup,
      @Original_Minutes VARCHAR(MAX),
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT OFF ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'MTG'

	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Initiator Validation
        IF @Initiator = -1 
            SET @Initiator = NULL 
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL 
	
	--Issue Validation
        IF @Issue = -1 
            SET @Issue = NULL
	
	--Init Firm Validation
        IF @InitFirm = -1 
            SET @InitFirm = NULL 
	
	--Responsible Firm Validation
        IF @ResponsibleFirm = -1 
            SET @ResponsibleFirm = NULL


	--Update the meeting minutes item
        UPDATE  PMMI
        SET     OriginalItem = @OriginalItem,
                Minutes = @Minutes,
                VendorGroup = @VendorGroup,
                InitFirm = @InitFirm,
                Initiator = @Initiator,
                ResponsibleFirm = @ResponsibleFirm,
                ResponsiblePerson = @ResponsiblePerson,
                InitDate = @InitDate,
                DueDate = @DueDate,
                FinDate = @FinDate,
                Status = @Status,
                Issue = @Issue,
                UniqueAttchID = @UniqueAttchID
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( Meeting = @Original_Meeting )
                AND ( MeetingType = @Original_MeetingType )
                AND ( MinutesType = @Original_MinutesType )
                AND ( Item = @Original_Item )
		
	--Get the updated current record
        EXECUTE vpspPMMeetingMinutesItemsGet @PMCo, @Project, @MeetingType,
            @Meeting, @MinutesType, @VendorGroup, @KeyID
	
        vspExit:
    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesItemsUpdate] TO [VCSPortal]
GO
