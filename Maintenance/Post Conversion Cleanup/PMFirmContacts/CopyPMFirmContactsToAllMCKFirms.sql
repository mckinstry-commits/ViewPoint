




DECLARE @Firm bFirm, @msg VARCHAR(255), @msgs VARCHAR(MAX)

DECLARE FirmCrsr CURSOR FOR
SELECT FirmNumber FROM dbo.PMFM
WHERE FirmType = 'MCK' AND VendorGroup = 1

OPEN FirmCrsr
FETCH NEXT FROM FirmCrsr INTO @Firm

WHILE @@FETCH_STATUS=0
BEGIN

	EXEC dbo.mckspPMFirmContactInitializeAll @vendorgroup = 1, @firm = @Firm, @msg = @msg OUT
	SELECT @msgs = ISNULL(@msgs,'') +CHAR(13)+ ISNULL(@msg,'')

	FETCH NEXT FROM FirmCrsr INTO @Firm
END
CLOSE FirmCrsr
DEALLOCATE FirmCrsr

SELECT @msgs