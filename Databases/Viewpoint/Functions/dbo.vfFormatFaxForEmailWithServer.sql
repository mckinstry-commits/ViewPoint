SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************/
CREATE function [dbo].[vfFormatFaxForEmailWithServer] (@PMCo INT, @VendorGroup INT,
					@Firm INT, @Contact INT)
RETURNS NVARCHAR(100) ---- limit for document distribution table currently
AS
BEGIN

/***********************************************************
* CREATED BY:	GF 06/18/2012 TK-00000
* MODIFIED By:
*
*
* USAGE:
* This function will return a fax number that can be used with fax server
* software. Will retrieve the fax number from firm contacts and the server name
* from PM Company. Will then build the fax address and return to calling routine.
*
* 1. if no fax number for contact returns NULL.
* 2. if a formatted fax is defined for the contact will be used as is.
* 3. If just a fax number exists this function will strip out any non-numeric
*	 characters for a fax number.
* 4. if a server name exists in PM company parameters, then will be added after fax.
*
*
* INPUT PARAMETERS
* @PMCo			PM Company
* @VendorGroup	Vendor Group
* @Firm			Firm 
* @Contact		Firm Contact 
*
*
* OUTPUT PARAMETERS
* Fax Address
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

DECLARE @Pos INT
		,@Fax varchar(20)
		,@FormattedFax varchar(128)
		,@FaxServerName varchar(50)
		,@FaxAddress NVARCHAR(500)
		,@UseFaxServerName CHAR(1)

---- if missing any key fields return null
IF @PMCo IS NULL OR @VendorGroup IS NULL OR @Firm IS NULL OR @Contact IS NULL RETURN NULL

---- get Fax Server Name for PM company
SET @FaxServerName = NULL
SELECT @FaxServerName = FaxServerName
FROM dbo.bPMCO
WHERE PMCo = @PMCo

---- get information from PMPM firm contacts
SELECT  @Fax = Fax, @FormattedFax = FormattedFax,
		@UseFaxServerName = UseFaxServerName
FROM dbo.bPMPM
WHERE VendorGroup = @VendorGroup
	AND FirmNumber = @Firm 
	AND ContactCode = @Contact
	
---- @UseFaxServerName NOT IN USE YET
SET @UseFaxServerName = 'N'

---- if fax numbers are empty return null
IF ISNULL(@Fax,'') = '' AND ISNULL(@FormattedFax,'') = '' RETURN NULL

---- if we have a formatted fax number we are done
IF ISNULL(@FormattedFax,'') <> '' AND @UseFaxServerName = 'N' RETURN @FormattedFax

---- format the fax number
IF ISNULL(@Fax,'') <> ''
	BEGIN
	SET @Pos = PATINDEX('%[^0-9]%', @Fax)

	---- loop through fax and remove non numeric characters
	WHILE @Pos > 0
		BEGIN
			SET @Fax = STUFF(@Fax,@Pos,1,'')
			SET @Pos = PATINDEX('%[^0-9]%', @Fax)
		END
	END


SET @FaxAddress = NULL
---- build fax server address
IF ISNULL(@FormattedFax,'') <> ''
	BEGIN
	SET @FaxAddress = @FormattedFax
	IF @UseFaxServerName = 'Y' AND ISNULL(@FaxServerName,'') <> ''
		BEGIN
		SET @FaxAddress = @FaxAddress + '@' + @FaxServerName
		END
	END
ELSE
	BEGIN	
	IF ISNULL(@Fax,'') <> ''
		BEGIN
		SET @FaxAddress = @Fax
		IF ISNULL(@FaxServerName,'') <> ''
			BEGIN
			SET @FaxAddress = @FaxAddress + '@' + @FaxServerName
			END
		END
	END



RETURN @FaxAddress

END


GO
GRANT EXECUTE ON  [dbo].[vfFormatFaxForEmailWithServer] TO [public]
GO
