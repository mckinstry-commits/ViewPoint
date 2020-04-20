SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesLinesInsert]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
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
      @ItemLine VARCHAR(3),
      @Description NVARCHAR(255),
      @VendorGroup NVARCHAR(50),
      @ResponsibleFirm NVARCHAR(50),
      @ResponsiblePerson NVARCHAR(50),
      @InitDate bDate,
      @DueDate bDate,
      @FinDate bDate,
      @Status NVARCHAR(50),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Notes VARCHAR(MAX)
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
	
	--Item Line Validation
        SET @ItemLine = ( SELECT    ISNULL(MAX(ItemLine), 0) + 1
                          FROM      PMML WITH ( NOLOCK )
                          WHERE     PMCo = @PMCo
                                    AND Project = @Project
                                    AND Item = @Item
                                    AND MinutesType = @MinutesType
                                    AND Meeting = @Meeting
                                    AND MeetingType = @MeetingType
                        )
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL
	
	--Responsible Firm Validation
        IF @ResponsibleFirm = -1 
            SET @ResponsibleFirm = NULL

	--Insert the meeting minutes line
        INSERT  INTO PMML
                ( PMCo,
                  Project,
                  MeetingType,
                  Meeting,
                  MinutesType,
                  Item,
                  ItemLine,
                  Description,
                  VendorGroup,
                  ResponsibleFirm,
                  ResponsiblePerson,
                  InitDate,
                  DueDate,
                  FinDate,
                  Status,
                  UniqueAttchID,
                  Notes
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @MeetingType,
                  @Meeting,
                  @MinutesType,
                  @Item,
                  @ItemLine,
                  @Description,
                  @VendorGroup,
                  @ResponsibleFirm,
                  @ResponsiblePerson,
                  @InitDate,
                  @DueDate,
                  @FinDate,
                  @Status,
                  @UniqueAttchID,
                  @Notes
		    )

	--Get the updated current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMMeetingMinutesLinesGet @PMCo, @Project, @MeetingType,
            @Meeting, @MinutesType, @Item, @VendorGroup, @KeyID

        vspExit:
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesLinesInsert] TO [VCSPortal]
GO
