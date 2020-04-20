SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Gil Fox Tfs-00000 AP ATO EFile Address values meeting aussie specifications.
-- Create date: 06/13/2013
-- Description:	The function will be called from the vspAPAUATOExportGet stored procedure
-- to return address values (Address, Address2, City, State, PostalCode, Country)
-- meeting the efile specifications.
--
-- Address fields returned: Address, Address2, City, State, PostalCode, Country
--
-- 1. When address is empty, then all address fields are empty except Postal Code which will be 0000
-- 2. State must be one of the 6 AU states or 'OTH'.
-- 3. Postal Code:
--		a. When country is not AU then postal code is 9999.
--		b. When between range of 0001 and 9998 then use.
--		c. Otherwise 0000.
-- 4. When the country is 'AU' then AUSTRALIA.
--
-- =============================================
CREATE FUNCTION [dbo].[vfAPAUATOAddressGet]
(
	  @Address			VARCHAR(60)
	 ,@Address2			VARCHAR(60)
	 ,@City				VARCHAR(30)
	 ,@State			VARCHAR(4)
	 ,@PostalCode		VARCHAR(12)
	 ,@Country			VARCHAR(2)
)

RETURNS @ReportAddress TABLE (
								 [Address]		VARCHAR(60)
								 ,[Address2]	VARCHAR(60)
								 ,[City]		VARCHAR(30)
								 ,[State]		VARCHAR(4)
								 ,[PostalCode]	VARCHAR(12)
								 ,[Country] 	VARCHAR(20)
							    )

AS
BEGIN


	---- if the address is empty then we will return all address fields as empty
	IF ISNULL(LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Address,'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')), '') = ''
		BEGIN
		INSERT INTO @ReportAddress ([Address], [Address2], [City], [State], [PostalCode], [Country]) 
		VALUES ( '', '', '', '', '0000', '')
		END
 
	ELSE

		BEGIN
		INSERT INTO @ReportAddress ([Address], [Address2], [City], [State], [PostalCode], [Country])
		VALUES (
				LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Address,'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')),
				LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Address2,'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')),
				LTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@City,'      ',' '),'     ',' '),'    ',' '),'   ',' '),'  ',' ')),

				CASE WHEN @State NOT IN ('ACT', 'NSW', 'NT', 'QLD', 'SA', 'TAS', 'VIC', 'WA')
						THEN 'OTH'
						ELSE @State
						END, ----state

				CASE WHEN ISNULL(@Country, 'AU') <> 'AU' THEN '9999'
						WHEN ISNUMERIC(ISNULL(@PostalCode, '')) = 0
								THEN '0000'
						WHEN LEN(LTRIM(RTRIM(ISNULL(@PostalCode, '')))) <> 4
								THEN '0000'
						WHEN ISNULL(@PostalCode, '') BETWEEN '0001' AND '9998'
								THEN @PostalCode
						ELSE '0000'
						END, ----postal code
                 
				CASE WHEN ISNULL(@Country, 'AU') = 'AU' THEN 'AUSTRALIA'
						ELSE ISNULL(@Country, '')
						END ----country
				)       

		END
	
		  
	RETURN
END
GO
GRANT SELECT ON  [dbo].[vfAPAUATOAddressGet] TO [public]
GO
