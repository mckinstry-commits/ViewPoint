SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPMInspectionLogUpdate]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
* 
* Description:	Update a inspection log.
************************************************************/
    (
      @PMCo NVARCHAR(50),
      @Project NVARCHAR(50),
      @InspectionType NVARCHAR(50),
      @InspectionCode NVARCHAR(50),
      @Description NVARCHAR(60),
      @Location VARCHAR(10),
      @InspectionDate bDate,
      @VendorGroup NVARCHAR(50),
      @InspectionFirm NVARCHAR(50),
      @InspectionContact NVARCHAR(50),
      @InspectorName NVARCHAR(50),
      @Status NVARCHAR(50),
      @Issue NVARCHAR(50),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @KeyID BIGINT,
      @Original_InspectionCode NVARCHAR(50),
      @Original_InspectionType NVARCHAR(50),
      @Original_PMCo NVARCHAR(50),
      @Original_Project NVARCHAR(50),
      @Original_Description NVARCHAR(60),
      @Original_InspectionContact NVARCHAR(50),
      @Original_InspectionDate bDate,
      @Original_InspectionFirm NVARCHAR(50),
      @Original_InspectorName NVARCHAR(50),
      @Original_Issue NVARCHAR(50),
      @Original_Location VARCHAR(10),
      @Original_Status NVARCHAR(50),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VendorGroup NVARCHAR(50),
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'INSPECT'
	
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
	
        UPDATE  PMIL
        SET     Location = @Location,
                InspectionDate = @InspectionDate,
                VendorGroup = @VendorGroup,
                InspectionFirm = @InspectionFirm,
                InspectionContact = @InspectionContact,
                InspectorName = @InspectorName,
                Status = @Status,
                Issue = @Issue,
                Notes = @Notes,
                UniqueAttchID = @UniqueAttchID
        WHERE   PMCo = @Original_PMCo
                AND Project = @Original_Project
                AND InspectionType = @Original_InspectionType
                AND InspectionCode = @Original_InspectionCode

	--Get the current record
        EXECUTE vpspPMInspectionLogGet @PMCo, @Project, @KeyID
	
        vspExit:

    END

GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogUpdate] TO [VCSPortal]
GO
