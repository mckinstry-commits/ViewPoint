USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mckAutomateEmplCopy]    Script Date: 12/17/2014 11:05:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/30/2013
-- Description:	Trigger to add SMTechnician record
-- =============================================
ALTER TRIGGER [dbo].[mckAutomateEmplCopy] 
   ON  [dbo].[bPREH] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @PRCo TINYINT, @Employee INT, @SortName bSortName, @VendorGroup bGroup
	SELECT @PRCo = PRCo, @Employee = Employee, @SortName = SortName FROM INSERTED

	

    -- Insert statements for trigger here
	--Check for valid Employee data and is active
	IF EXISTS(SELECT 1 FROM INSERTED WHERE LastName <> '' AND LastName IS NOT NULL AND ActiveYN = 'Y')
	BEGIN
		--INSERT record using stored proc.
		EXEC mckPREmplToSMTech @PRCo, @Employee, 0,''
		
		DECLARE @PMFirm bFirm, @APCo bCompany, @PMCo bCompany
			SELECT TOP 1 @PMCo = PMCo, @APCo = APCo, @PMFirm = OurFirm FROM PMCO WHERE PRCo = @PRCo
			SELECT @VendorGroup = VendorGroup FROM HQCO WHERE HQCo = @APCo

		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE SortName NOT IN (SELECT SortName FROM PMPM WHERE VendorGroup = @VendorGroup AND FirmNumber = @PMFirm))
		BEGIN
			
			--INSERT record to PMPM using stored proc.
			EXEC dbo.bspPMFirmContactInitialize @pmco = @PMCo, -- bCompany
			    @vendorgroup = @VendorGroup, -- bGroup
			    @firm = @PMFirm, -- bFirm
			    @beginemployee = @Employee, -- bEmployee
			    @endemployee = @Employee, -- bEmployee
			    @activeonly = 'Y', -- bYN
			    @msg = '' -- varchar(255)
			
			--EXEC mckPREmplToPMContact @PRCo, @SortName
		END
	END

	

END

