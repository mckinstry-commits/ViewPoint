SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesItemsInsert]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a meeting minutes item.
************************************************************/
    (
      @PMCo NVARCHAR(50),
      @Project NVARCHAR(50),
      @MeetingType NVARCHAR(50),
      @Meeting INT,
      @MinutesType TINYINT,
      @Item VARCHAR(10),
      @OriginalItem VARCHAR(10),
      @Minutes VARCHAR(MAX),
      @VendorGroup NVARCHAR(50),
      @InitFirm NVARCHAR(50),
      @Initiator NVARCHAR(50),
      @ResponsibleFirm NVARCHAR(50),
      @ResponsiblePerson NVARCHAR(50),
      @InitDate bDate,
      @DueDate bDate,
      @FinDate bDate,
      @Status NVARCHAR(50),
      @Issue NVARCHAR(50),
      @UniqueAttchID UNIQUEIDENTIFIER
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
	

	--Item Validation
        IF @Item = -1 
            SET @Item = NULL
        IF ( ISNULL(@Item, '') = '' )
            OR @Item = '+'
            OR @Item = 'n'
            OR @Item = 'N' 
            BEGIN
                SET @Item = ( SELECT    ISNULL(MAX(Item), 0) + 1
                              FROM      PMMI WITH ( NOLOCK )
                              WHERE     PMCo = @PMCo
                                        AND Project = @Project
                                        AND MinutesType = @MinutesType
                                        AND Meeting = @Meeting
                                        AND MeetingType = @MeetingType
                            )
            END
	

	--Insert the PM Meeting Minute Item
        INSERT  INTO PMMI
                ( PMCo,
                  Project,
                  MeetingType,
                  Meeting,
                  MinutesType,
                  Item,
                  OriginalItem,
                  Minutes,
                  VendorGroup,
                  InitFirm,
                  Initiator,
                  ResponsibleFirm,
                  ResponsiblePerson,
                  InitDate,
                  DueDate,
                  FinDate,
                  Status,
                  Issue,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @MeetingType,
                  @Meeting,
                  @MinutesType,
                  @Item,
                  @OriginalItem,
                  @Minutes,
                  @VendorGroup,
                  @InitFirm,
                  @Initiator,
                  @ResponsibleFirm,
                  @ResponsiblePerson,
                  @InitDate,
                  @DueDate,
                  @FinDate,
                  @Status,
                  @Issue,
                  @UniqueAttchID
		    )

	--Get the updated current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMMeetingMinutesItemsGet @PMCo, @Project, @MeetingType,
            @Meeting, @MinutesType, @VendorGroup, @KeyID

        vspExit:
    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesItemsInsert] TO [VCSPortal]
GO
