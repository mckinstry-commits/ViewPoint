SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesLinesUpdate]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
*
* 
* Description:	Insert a meeting minutes Line.
************************************************************/
    (
      @PMCo NVARCHAR(50),
      @Project NVARCHAR(50),
      @MeetingType NVARCHAR(50),
      @Meeting INT,
      @MinutesType TINYINT,
      @Item INT,
      @ItemLine TINYINT,
      @Description NVARCHAR(255),
      @VendorGroup NVARCHAR(50),
      @ResponsibleFirm NVARCHAR(50),
      @ResponsiblePerson NVARCHAR(50),
      @InitDate bDate,
      @DueDate bDate,
      @FinDate bDate,
      @Status NVARCHAR(50),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Notes VARCHAR(MAX),
      @KeyID BIGINT,
      @Original_Item INT,
      @Original_ItemLine TINYINT,
      @Original_Meeting INT,
      @Original_MeetingType NVARCHAR(50),
      @Original_MinutesType TINYINT,
      @Original_PMCo NVARCHAR(50),
      @Original_Project NVARCHAR(50),
      @Original_Description NVARCHAR(255),
      @Original_DueDate bDate,
      @Original_FinDate bDate,
      @Original_InitDate bDate,
      @Original_ResponsibleFirm NVARCHAR(50),
      @Original_ResponsiblePerson NVARCHAR(50),
      @Original_Status NVARCHAR(50),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup NVARCHAR(50),
      @Original_Notes VARCHAR(MAX),
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
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
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL
	
	--Responsible Firm Validation
        IF @ResponsibleFirm = -1 
            SET @ResponsibleFirm = NULL
	
        UPDATE  PMML
        SET     Description = @Description,
                VendorGroup = @VendorGroup,
                ResponsibleFirm = @ResponsibleFirm,
                ResponsiblePerson = @ResponsiblePerson,
                InitDate = @InitDate,
                DueDate = @DueDate,
                FinDate = @FinDate,
                Status = @Status,
                UniqueAttchID = @UniqueAttchID,
                Notes = @Notes
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( Meeting = @Original_Meeting )
                AND ( MeetingType = @Original_MeetingType )
                AND ( MinutesType = @Original_MinutesType )
                AND ( Item = @Original_Item )
                AND ( ItemLine = @Original_ItemLine ) 
		 
	--Get the updated current record
        EXECUTE vpspPMMeetingMinutesLinesGet @PMCo, @Project, @MeetingType,
            @Meeting, @MinutesType, @Item, @VendorGroup, @KeyID

        vspExit:
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesLinesUpdate] TO [VCSPortal]
GO
