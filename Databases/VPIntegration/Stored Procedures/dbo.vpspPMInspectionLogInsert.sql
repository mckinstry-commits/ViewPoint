SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMInspectionLogInsert]
/***********************************************************
* Created:		8/26/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert an inspection log.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @InspectionType bDocType,
      @InspectionCode bDocument,
      @Description bItemDesc,
      @Location VARCHAR(10),
      @InspectionDate bDate,
      @VendorGroup bGroup,
      @InspectionFirm bVendor,
      @InspectionContact bEmployee,
      @InspectorName bDesc,
      @Status bStatus,
      @Issue bIssue,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'INSPECT'
	
	--Inspection Code Validation
        IF ( ISNULL(@InspectionCode, '') = '' )
            OR @InspectionCode = '+'
            OR @InspectionCode = 'n'
            OR @InspectionCode = 'N' 
            BEGIN
                DECLARE @nextInspectionCode INT
                SET @nextInspectionCode = ( SELECT  ISNULL(MAX(InspectionCode),
                                                           0) + 1
                                            FROM    PMIL WITH ( NOLOCK )
                                            WHERE   PMCo = @PMCo
                                                    AND Project = @Project
                                                    AND InspectionType = @InspectionType
                                                    AND ISNUMERIC(InspectionCode) = 1
                                                    AND InspectionCode NOT LIKE '%.%'
                                                    AND SUBSTRING(LTRIM(InspectionCode),
                                                              1, 1) <> '0'
                                          )
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument',
                    @nextInspectionCode, @msg OUTPUT
                SET @InspectionCode = @msg
            END
        ELSE 
            BEGIN
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument',
                    @InspectionCode, @msg OUTPUT
                SET @InspectionCode = @msg

		--Validate that the Inspection Type/Inspection Code pair does not already exist.
                IF EXISTS ( SELECT  PMIL.InspectionCode
                            FROM    PMIL
                            WHERE   PMIL.PMCo = @PMCo
                                    AND PMIL.Project = @Project
                                    AND PMIL.InspectionType = @InspectionType
                                    AND PMIL.InspectionCode = @InspectionCode ) 
                    BEGIN
                        SET @msg = 'Inspection Code has already been used. Please use another Code.'
                        RAISERROR(@msg, 16, 1)
                        GOTO vspExit
                    END
            END
	
	--Issue Validation
        IF @Issue = -1 
            SET @Issue = NULL
	
	--Inspection Firm Validation
        IF @InspectionFirm = -1 
            SET @InspectionFirm = NULL
	
	--Inspection Contact Validation
        IF @InspectionContact = -1 
            SET @InspectionContact = NULL
	
	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END


	--Insert the Inspection Log
        INSERT  INTO PMIL
                ( PMCo,
                  Project,
                  InspectionType,
                  InspectionCode,
                  Description,
                  Location,
                  InspectionDate,
                  VendorGroup,
                  InspectionFirm,
                  InspectionContact,
                  InspectorName,
                  Status,
                  Issue,
                  Notes,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @InspectionType,
                  @InspectionCode,
                  @Description,
                  @Location,
                  @InspectionDate,
                  @VendorGroup,
                  @InspectionFirm,
                  @InspectionContact,
                  @InspectorName,
                  @Status,
                  @Issue,
                  @Notes,
                  @UniqueAttchID
		    )

        DECLARE @KeyID INT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMInspectionLogGet @PMCo, @Project, @KeyID

        vspExit:

    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogInsert] TO [VCSPortal]
GO
