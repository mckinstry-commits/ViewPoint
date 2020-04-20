SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMTestLogUpdate]
/***********************************************************
* Created:		8/26/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	Update PM Test Log.
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
      @UniqueAttchID UNIQUEIDENTIFIER,
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_TestType bDocType,
      @Original_TestCode bDocument,
      @Original_Description bItemDesc,
      @Original_Location VARCHAR(10),
      @Original_TestDate bDate,
      @Original_VendorGroup bGroup,
      @Original_TestFirm bVendor,
      @Original_TestContact bEmployee,
      @Original_TesterName bDesc,
      @Original_Status bStatus,
      @Original_Issue bIssue,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'TEST'
	
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
	
	
	--Update the Test Log
        UPDATE  PMTL
        SET     Description = @Description,
                Location = @Location,
                TestDate = @TestDate,
                VendorGroup = @VendorGroup,
                TestFirm = @TestFirm,
                TestContact = @TestContact,
                TesterName = @TesterName,
                Status = @Status,
                Issue = @Issue,
                Notes = @Notes,
                UniqueAttchID = @UniqueAttchID
        WHERE   PMCo = @Original_PMCo
                AND Project = @Original_Project
                AND TestType = @Original_TestType
                AND TestCode = @Original_TestCode
		
        EXECUTE vpspPMTestLogGet @PMCo, @Project, @VendorGroup, @KeyID
	
        vspExit:
    END
		
	


GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogUpdate] TO [VCSPortal]
GO
