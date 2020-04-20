SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[vpspPMTestLogInsert]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Insert a inspection log.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @TestType bDocType,
      @TestCode bDocument,
      @Description bItemDesc,
      @Location VARCHAR(10),
      @TestDate bDate,
      @VendorGroup bGroup,
      @TestFirm bVendor,
      @TestContact bEmployee,
      @TesterName bDesc,
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
        SET @DocCat = 'TEST'
	
	--Test Code Validation
        IF ( ISNULL(@TestCode, '') = ''
             OR @TestCode = '+'
             OR @TestCode = 'n'
             OR @TestCode = 'N'
           ) 
            BEGIN
                DECLARE @nextTestCode INT
                SET @nextTestCode = ( SELECT    ISNULL(MAX(TestCode), 0) + 1
                                      FROM      PMTL WITH ( NOLOCK )
                                      WHERE     PMCo = @PMCo
                                                AND Project = @Project
                                                AND TestType = @TestType
                                                AND ISNUMERIC(TestCode) = 1
                                                AND TestCode NOT LIKE '%.%'
                                                AND SUBSTRING(LTRIM(TestCode),
                                                              1, 1) <> '0'
                                    )
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @nextTestCode,
                    @msg OUTPUT
                SET @TestCode = @msg
            END
        ELSE 
            BEGIN
                SET @msg = NULL
                EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @TestCode,
                    @msg OUTPUT
                SET @TestCode = @msg

		--Validate the the Test Type/Test Code pair does not already exist
                IF EXISTS ( SELECT  PMTL.TestCode
                            FROM    PMTL
                            WHERE   PMTL.PMCo = @PMCo
                                    AND PMTL.Project = @Project
                                    AND PMTL.TestType = @TestType
                                    AND PMTL.TestCode = @TestCode ) 
                    BEGIN
                        SET @msg = 'Test Code has already been used. Please use another Code.'
                        RAISERROR(@msg, 16, 1)
                        GOTO vspExit
                    END
            END
	
	--Firm Validation
        IF @TestFirm = -1 
            SET @TestFirm = NULL
	
	--Contact Validation
        IF @TestContact = -1 
            SET @TestContact = NULL
	
	--Status Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Issue Validation
        IF @Issue = -1 
            SET @Issue = NULL
	
	--TesterName Validation
        IF @TesterName = '' 
            SET @TesterName = NULL
	
	
	--Insert the Test Log
        INSERT  INTO PMTL
                ( PMCo,
                  Project,
                  TestType,
                  TestCode,
                  Description,
                  Location,
                  TestDate,
                  VendorGroup,
                  TestFirm,
                  TestContact,
                  TesterName,
                  Status,
                  Issue,
                  Notes,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @TestType,
                  @TestCode,
                  @Description,
                  @Location,
                  @TestDate,
                  @VendorGroup,
                  @TestFirm,
                  @TestContact,
                  @TesterName,
                  @Status,
                  @Issue,
                  @Notes,
                  @UniqueAttchID
		    )

	--Get the current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMTestLogGet @PMCo, @Project, @VendorGroup, @KeyID

        vspExit:
    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogInsert] TO [VCSPortal]
GO
