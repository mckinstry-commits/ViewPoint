SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPMRequestForQuoteUpdate]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				DAN SO 11/14/2011 - D-03599 - allow DateDue field
*				GF 12/06/2011 TK-10599
* 
* Description:	Update a request for quote.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @PCOType bDocType,
      @PCO bPCO,
      @RFQ bDocument,
      @Description VARCHAR(60),
      @RFQDate bDate,
      @DateDue bDate,				-- D-03599
      @VendorGroup bGroup,
      @FirmNumber bFirm,
      @ResponsiblePerson bEmployee,
      @Status bStatus,
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_PCOType bDocType,
      @Original_PCO bPCO,
      @Original_RFQ bDocument,
      @Original_Description VARCHAR(60),
      @Original_RFQDate bDate,
      @Original_DateDue bDate,		-- D-03599
      @Original_VendorGroup bGroup,
      @Original_FirmNumber bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_Status bStatus,
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_KeyID BIGINT

    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'RFQ'

	--Status Code Validation
        IF @Status = '-1' 
            SET @Status = NULL
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Firm Validation
        IF @FirmNumber = -1 
            SET @FirmNumber = NULL
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL

	--Update the RFQ
        UPDATE  PMRQ
        SET     Description = @Description,
                RFQDate = @RFQDate,
                DateDue = @DateDue,				-- D-03599
                VendorGroup = @VendorGroup,
                FirmNumber = @FirmNumber,
                ResponsiblePerson = @ResponsiblePerson,
                Status = @Status,
                Notes = @Notes,
                UniqueAttchID = @UniqueAttchID
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( PCOType = @Original_PCOType )
                AND ( PCO = @Original_PCO )
                AND ( RFQ = @Original_RFQ ) 
	
	--Get the updated current record
        EXECUTE vpspPMRequestForQuoteGet @PMCo, @Project, @VendorGroup, @KeyID
	
        vspExit:
    END






GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForQuoteUpdate] TO [VCSPortal]
GO
