-- Update existing HR.net records with valid CGC Classes, Types and Unions
-- Add Viewpoint Craft/Class values to HR.net Picklist
-- Update HR.net records with new Craft/Class values.
-- Delete/deactivate legacy CGC picklist values. Or update with "Do Not Use"

--Run on HRNET Database to back up original values
--TRUNCATE table OC_PICKLISTVALUES
--INSERT OC_PICKLISTVALUES SELECT * FROM OC_PICKLISTVALUES_20141016
--go

--UPDATE dbo.JOBDETAIL SET COSTCODE=t1.COSTCODE FROM
--JOBDETAIL_20141016 t1 WHERE JOBDETAIL.JOBDETAIL_ID=t1.JOBDETAIL_ID AND JOBDETAIL.COSTCODE<> t1.COSTCODE
--go

--UPDATE PEOPLE SET UNIONTYPE=t1.UNIONTYPE FROM
--PEOPLE_20141016 t1 WHERE PEOPLE.PEOPLE_ID=t1.PEOPLE_ID AND PEOPLE.UNIONTYPE<>t1.UNIONTYPE
--go

--SELECT * FROM CMS.S1017192.CMSFIL.PRPMST WHERE MEENO=68221


ALTER PROC mspUpdateHRNetCraftClass
as

SET NOCOUNT ON

DECLARE ecur CURSOR for
SELECT   
	CAST(c.COMPANYREFNO AS INT) AS CompanyNumber
,	CAST(p.REFERENCENUMBER AS INT) AS EmployeeNumber
,	p.FULLNAME AS FullName
,	CASE p.PRIMARYUNION 
		WHEN 'MEMBER' THEN 'Y' 
		ELSE 'N' 
	END AS UnionYN
,	rtrim(ltrim(jd.COSTCODE)) AS COSTCODE
,	CASE
		WHEN LEN(rtrim(ltrim(jd.COSTCODE))) > 0 AND charindex('.',rtrim(ltrim(jd.COSTCODE))) > 0 THEN LEFT(rtrim(ltrim(jd.COSTCODE)),charindex('.',rtrim(ltrim(jd.COSTCODE)))-1)
		WHEN LEN(rtrim(ltrim(jd.COSTCODE))) > 0 AND charindex('.',rtrim(ltrim(jd.COSTCODE))) = 0 THEN rtrim(ltrim(jd.COSTCODE))	
		ELSE NULL
	END AS EmployeeClass
,	CASE
		WHEN LEN(rtrim(ltrim(jd.COSTCODE))) > 0 AND charindex('.',rtrim(ltrim(jd.COSTCODE))) > 0 THEN SUBSTRING(rtrim(ltrim(jd.COSTCODE)),charindex('.',rtrim(ltrim(jd.COSTCODE)))+1,LEN(rtrim(ltrim(jd.COSTCODE)))-charindex('.',rtrim(ltrim(jd.COSTCODE)))+1)
		ELSE NULL
	END AS EmployeeType	
,	p.UNIONTYPE AS UNIONTYPE
,	CASE  
		WHEN p.PRIMARYUNION <> 'MEMBER' THEN COALESCE(pl.DISPLAYVALUE,'0001 - Staff Default') 
		ELSE COALESCE(pl.DISPLAYVALUE,'9999 - Union Default]')
	end AS UNIONTYPE	
,	CASE  
		WHEN p.PRIMARYUNION <> 'MEMBER' THEN REPLACE(LEFT(COALESCE(pl.DISPLAYVALUE,'0001 - Staff Default') ,CHARINDEX(' ',COALESCE(pl.DISPLAYVALUE,'0001 - Staff Default]'))-1),'z','')
		ELSE REPLACE(LEFT(COALESCE(pl.DISPLAYVALUE,'9999 - Union Default]'),CHARINDEX(' ',COALESCE(pl.DISPLAYVALUE,'9999 - Union Default'))-1),'z','')
	END AS UNIONNUMBER
,	jd.JOBDETAIL_ID
,	p.PEOPLE_ID
FROM 
	[SESQL08].HRNET.dbo.PEOPLE p JOIN
	[SESQL08].HRNET.dbo.JOBDETAIL jd ON
		p.PEOPLE_ID=jd.PEOPLE_ID LEFT OUTER JOIN
	[SESQL08].HRNET.dbo.COMPANY c ON
		jd.COMPANY=c.COMPANY_ID LEFT OUTER JOIN
	[SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll ON
		pll.CULTURECODE='en-US'
	AND pll.SHORTDESCRIPTION='Union Affiliation' LEFT OUTER JOIN
	[SESQL08].HRNET.dbo.OC_PICKLISTVALUES pl ON
		pl.PICKLISTID=pll.PICKLISTID
	AND	p.UNIONTYPE=pl.STOREVALUE
	AND pl.CULTURECODE ='en-US' 	
WHERE
	jd.TOPJOB='T' 
AND jd.CURRENTRECORD='YES' 
AND p.STATUS='A'
AND p.REFERENCENUMBER <= 99999
ORDER BY
	1,2
FOR READ ONLY

DECLARE @CompanyNumber		int
DECLARE @EmployeeNumber		int
DECLARE @FullName			VARCHAR(100)
DECLARE @UnionYN			CHAR(1)
DECLARE @COSTCODE			VARCHAR(20)
DECLARE @EmployeeClass		VARCHAR(10)
DECLARE @EmployeeType		VARCHAR(10)
DECLARE @UNIONTYPE			VARCHAR(50)
DECLARE @UNIONTYPENAME		VARCHAR(50)
DECLARE @UNIONNUMBER		VARCHAR(20)

DECLARE @CGCClass	VARCHAR(10)
DECLARE @CGCType	VARCHAR(10)
DECLARE @CGCUnion	VARCHAR(10)
DECLARE @CGCClassTypeDesc		VARCHAR(100)
DECLARE @CGCUnionDesc		VARCHAR(100)

DECLARE @VPCraft		bCraft
DECLARE @VPClass		bClass
DECLARE @VPCraftDesc		VARCHAR(100)
DECLARE @VPCraftClassDesc		VARCHAR(100)

DECLARE @jobdetailid UNIQUEIDENTIFIER
DECLARE @peopleid UNIQUEIDENTIFIER

DECLARE @hrclasstypeplid UNIQUEIDENTIFIER
DECLARE @unionlid UNIQUEIDENTIFIER

SELECT @unionlid=PICKLISTID FROM [SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll WHERE pll.CULTURECODE='en-US' AND pll.SHORTDESCRIPTION='Union Affiliation'
SELECT @hrclasstypeplid=PICKLISTID FROM [SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll WHERE pll.CULTURECODE='en-US' AND pll.SHORTDESCRIPTION='Standard Cost Code'
	
--Update existing Picklist values as CGC Legacy values
UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
SET DISPLAYVALUE = 'z' + DISPLAYVALUE 
WHERE PICKLISTID=@hrclasstypeplid
AND DISPLAYVALUE NOT LIKE 'z%'

UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
SET DISPLAYVALUE = 'z' + DISPLAYVALUE 
WHERE PICKLISTID=@unionlid
AND DISPLAYVALUE NOT LIKE 'z%'

PRINT 
	CAST('Co' AS CHAR(10))			--int
+	CAST('Emp#' AS CHAR(10))		--int
+	CAST('EmpName' AS CHAR(60))		--VARCHAR(100)
+	CAST('Union' AS CHAR(10))		--CHAR(1)
+	CAST('ClassType' AS CHAR(25))	--VARCHAR(20)
+	CAST('Class' AS CHAR(10))		--VARCHAR(10)
+	CAST('Type' AS CHAR(10))			--VARCHAR(10)
+	CAST('UnionId'	AS CHAR(10))	--VARCHAR(50)
+	CAST('UnionName' AS CHAR(30))	--VARCHAR(50)
+	CAST('Union#' AS CHAR(10))	--VARCHAR(20)

OPEN ecur
FETCH ecur INTO
	@CompanyNumber		--int
,	@EmployeeNumber		--int
,	@FullName			--VARCHAR(100)
,	@UnionYN			--CHAR(1)
,	@COSTCODE			--VARCHAR(20)
,	@EmployeeClass		--VARCHAR(10)
,	@EmployeeType		--VARCHAR(10)
,	@UNIONTYPE			--VARCHAR(50)
,	@UNIONTYPENAME		--VARCHAR(50)
,	@UNIONNUMBER		--VARCHAR(20)
,	@jobdetailid
,	@peopleid

WHILE @@fetch_status=0
BEGIN

	PRINT 
		CAST(COALESCE(@CompanyNumber,'[?]')	AS CHAR(10))		--int
	+	CAST(COALESCE(@EmployeeNumber,'[?]') AS CHAR(10))	--int
	+	CAST(COALESCE(@FullName,'[?]') AS CHAR(60))			--VARCHAR(100)
	+	CAST(COALESCE(@UnionYN,'[?]') AS CHAR(10))			--CHAR(1)
	+	CAST(COALESCE(@COSTCODE,'[?]') AS CHAR(25))			--VARCHAR(20)
	+	CAST(COALESCE(@EmployeeClass,'[?]') AS CHAR(10))		--VARCHAR(10)
	+	CAST(COALESCE(@EmployeeType,'[?]') AS CHAR(10))		--VARCHAR(10)
	+	CAST(COALESCE(@UNIONTYPE,'[?]')	AS CHAR(10))			--VARCHAR(50)
	+	CAST(COALESCE(@UNIONTYPENAME,'[?]') AS CHAR(30))	--VARCHAR(50)
	+	CAST(COALESCE(@UNIONNUMBER,'[?]') AS CHAR(10))		--VARCHAR(20)
	
	-- Get Current Class/Type/Union from CGC
	SELECT @CGCClass=MEECL, @CGCType=MEETY, @CGCUnion=MUNNO FROM CMS.S1017192.CMSFIL.PRPMST WHERE MCONO=CAST(@CompanyNumber AS DECIMAL(2)) AND MDVNO=CAST(0 AS DECIMAL(3)) AND MEENO=CAST(@EmployeeNumber AS DECIMAL(5,0))
	SELECT @CGCClassTypeDesc=FD15A FROM CMS.S1017192.CMSFIL.PRPECL WHERE FCONO=CAST(@CompanyNumber AS DECIMAL(2)) AND FDVNO=CAST(0 AS DECIMAL(3)) AND FEECL=CAST(@CGCClass AS DECIMAL(3)) AND FEETY=CAST(@CGCType AS VARCHAR(2))
	SELECT @CGCUnionDesc=MAX(QD15A) FROM CMS.S1017192.CMSFIL.PRPUNM WHERE QCONO=CAST(@CompanyNumber AS DECIMAL(2)) AND QDVNO=CAST(0 AS DECIMAL(3)) AND QUNNO=CAST(@CGCUnion AS VARCHAR(5))

	--If HRNet values are empty, use CGC Values
	IF ( @EmployeeClass IS NULL ) SELECT @EmployeeClass=@CGCClass
	IF ( @EmployeeType IS NULL ) SELECT @EmployeeType=@CGCType
	IF ( @UNIONTYPE IS NULL )	SELECT @UNIONNUMBER=@CGCUnion
	
	--Check Employee Class/Type and if null update to match CGC
	
	--IF  ( @EmployeeClass IS NOT NULL AND @EmployeeType IS NOT NULL )
	--BEGIN
	--	PRINT CAST('' AS CHAR(8)) + '+ Update Class to "' + @EmployeeClass + '" and Type to "' + @EmployeeType + '"  [' + @EmployeeClass + '.' + @EmployeeType + ']'

	--	IF NOT EXISTS (SELECT 1 FROM [SESQL08].HRNET.dbo.OC_PICKLISTVALUES plv WHERE plv.PICKLISTID=@hrclasstypeplid AND plv.STOREVALUE=@EmployeeClass + '.' + @EmployeeType )
	--	BEGIN
	--		INSERT [SESQL08].HRNET.dbo.OC_PICKLISTVALUES ( PICKLISTID, CULTURECODE, STOREVALUE, DISPLAYVALUE )
	--		SELECT 
	--			PICKLISTID
	--		,	CULTURECODE
	--		,	@EmployeeClass + '.' + @EmployeeType
	--		,	@EmployeeClass + '.' + @EmployeeType + ' - ' + COALESCE(@CGCClassTypeDesc,@EmployeeClass + '.' + @EmployeeType) + ' (CGC)'
	--		FROM
	--			[SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll
	--		WHERE
	--			pll.PICKLISTID=@hrclasstypeplid
			
	--	END 
	--	else
	--	BEGIN
	--		PRINT CAST('' AS CHAR(8)) +  '  Picklist Value : ' + COALESCE(@EmployeeClass,'?') + '.' + COALESCE(@EmployeeType,'?') + ' already exists.'
			
	--		--Update Existing HRNET Picklist value to indicate new VP reference
	--		UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
	--		SET DISPLAYVALUE = @EmployeeClass + '.' + @EmployeeType + ' - ' + COALESCE(@CGCClassTypeDesc,DISPLAYVALUE,@EmployeeClass + '.' + @EmployeeType) + ' (CGC)'
	--		WHERE 
	--			PICKLISTID=@hrclasstypeplid
	--		AND STOREVALUE=@EmployeeClass + '.' + @EmployeeType
	--	END		
		
	--	UPDATE [SESQL08].HRNET.dbo.JOBDETAIL SET COSTCODE=@EmployeeClass + '.' + @EmployeeType WHERE JOBDETAIL_ID=@jobdetailid AND COSTCODE <> @EmployeeClass + '.' + @EmployeeType
	--END
	--ELSE
	--BEGIN 
	--	PRINT CAST('' AS CHAR(8)) + '- Source Class and Type not found'
	--END 

	--IF (@UNIONNUMBER IS NOT NULL)
	--BEGIN 
	--	IF NOT EXISTS (SELECT 1 FROM [SESQL08].HRNET.dbo.OC_PICKLISTVALUES plv WHERE plv.PICKLISTID=@unionlid AND plv.STOREVALUE=@UNIONNUMBER )
	--	BEGIN
	--		INSERT [SESQL08].HRNET.dbo.OC_PICKLISTVALUES ( PICKLISTID, CULTURECODE, STOREVALUE, DISPLAYVALUE )
	--		SELECT 
	--			PICKLISTID
	--		,	CULTURECODE
	--		,	@UNIONNUMBER
	--		,	CAST(@UNIONNUMBER AS VARCHAR(10)) + ' - ' + coalesce(@CGCUnionDesc,'Union ' + CAST(@UNIONNUMBER AS VARCHAR(10))) + ' (CGC)'
	--		FROM
	--			[SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll
	--		WHERE
	--			pll.PICKLISTID=@unionlid
			
	--	END 
	--	else
	--	BEGIN
	--		PRINT CAST('' AS CHAR(8)) +  '  Picklist Value : ' + COALESCE(@CGCUnionDesc,'?') + ' already exists.'
			
	--		--Update Existing HRNET Picklist value to indicate new VP reference
	--		UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
	--		SET DISPLAYVALUE = CAST(@UNIONNUMBER AS VARCHAR(10)) + ' - ' + COALESCE(@CGCUnionDesc,DISPLAYVALUE,CAST(@UNIONNUMBER AS VARCHAR(10))) + ' (CGC)'
	--		WHERE 
	--			PICKLISTID=@unionlid
	--		AND STOREVALUE=@UNIONNUMBER
	--	END		
		
	--	UPDATE [SESQL08].HRNET.dbo.PEOPLE SET UNIONTYPE=@UNIONNUMBER WHERE PEOPLE_ID=@peopleid AND UNIONTYPE <> @UNIONNUMBER
	--END
	--ELSE
	--BEGIN
	--	PRINT CAST('' AS CHAR(8)) + '- Source Union not found'
	--END 
	
	--Update Existing HRNET Picklist value to indicate legacy CGC reference
	--UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
	--SET DISPLAYVALUE = DISPLAYVALUE + ' (CGC)'
	--WHERE 
	--	PICKLISTID=@hrclasstypeplid
	--AND STOREVALUE=@COSTCODE
		
	--Get Viewpoint Craft/Class from budxrefPRUnion
	SELECT @VPCraft=Craft, @VPClass=Class, @VPCraftClassDesc=Description from budxrefUnion WHERE Company=@CompanyNumber AND CMSClass=@EmployeeClass AND CMSType=@EmployeeType AND CAST(CMSUnion AS INT)=cast(@UNIONNUMBER AS INT)
	
	SELECT @VPCraftDesc=Description FROM PRCM WHERE PRCo=@CompanyNumber AND Craft=@VPCraft
	SELECT @VPCraftClassDesc=Description FROM PRCC WHERE PRCo=@CompanyNumber AND Craft=@VPCraft AND Class=@VPClass
	
	IF ( @VPCraft IS NOT NULL AND @VPClass IS NOT NULL )
	begin

		IF NOT EXISTS (SELECT 1 FROM [SESQL08].HRNET.dbo.OC_PICKLISTVALUES plv WHERE plv.PICKLISTID=@unionlid AND plv.CULTURECODE='en-US' AND plv.STOREVALUE=ltrim(rtrim(@VPCraft)) )
		BEGIN
			PRINT CAST('' AS CHAR(8)) +  '  Inserting Union Affiliation [' + @VPCraft + '] to HRNet Picklist'
			INSERT [SESQL08].HRNET.dbo.OC_PICKLISTVALUES ( PICKLISTID, CULTURECODE, STOREVALUE, DISPLAYVALUE )
			SELECT 
				PICKLISTID
			,	CULTURECODE
			,	LTRIM(RTRIM(@VPCraft))
			,	LTRIM(RTRIM(@VPCraft)) + ' - ' + COALESCE(@VPCraftDesc,@CGCUnionDesc,'Union ' + LTRIM(RTRIM(@VPCraft))) 
			FROM
				[SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES pll
			WHERE
				pll.PICKLISTID=@unionlid
			
		END 
		else
		BEGIN
			PRINT CAST('' AS CHAR(8)) +  '  Union Affiliation Picklist Value : ' + @VPCraft + ' already exists.'
			
			--Update Existing HRNET Picklist value to indicate new VP reference
			UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
			SET DISPLAYVALUE = LTRIM(RTRIM(@VPCraft)) + ' - ' + COALESCE(@VPCraftDesc,@CGCUnionDesc,DISPLAYVALUE,'Union ' + LTRIM(RTRIM(@VPCraft))) 
			WHERE 
				PICKLISTID=@unionlid
			AND STOREVALUE=LTRIM(RTRIM(@VPCraft))
		END

		PRINT CAST('' AS CHAR(8)) +  '  Viewpoint Craft/Class: ' + COALESCE(@VPCraft,'?') + '/' + COALESCE(@VPClass,'?')
		
		IF NOT EXISTS (SELECT 1 FROM [SESQL08].HRNET.dbo.OC_PICKLISTVALUES plv WHERE plv.PICKLISTID=@hrclasstypeplid AND plv.CULTURECODE='en-US' AND plv.STOREVALUE=LTRIM(RTRIM(@VPClass)) )
		BEGIN
			PRINT CAST('' AS CHAR(8)) +  '  Inserting Standard Cost Code [' + @VPClass + '] to HRNet Picklist'

			INSERT [SESQL08].HRNET.dbo.OC_PICKLISTVALUES ( PICKLISTID, CULTURECODE, STOREVALUE, DISPLAYVALUE )
			SELECT 
				PICKLISTID
			,	CULTURECODE
			,	LTRIM(RTRIM(@VPClass))
			,	LTRIM(RTRIM(@VPClass)) + ' - ' + COALESCE(@VPCraftClassDesc,@CGCClassTypeDesc,@VPClass) 
			FROM
				[SESQL08].HRNET.dbo.OC_PICKLISTLANGUAGES 
			WHERE
				PICKLISTID=@hrclasstypeplid	
		END 
		else
		BEGIN
		
			PRINT CAST('' AS CHAR(8)) +  '  Standard Cost Code Picklist Value : ' + @VPClass + ' already exists.'
			
			--Update Existing HRNET Picklist value to indicate new VP reference
			UPDATE [SESQL08].HRNET.dbo.OC_PICKLISTVALUES 
			SET DISPLAYVALUE = LTRIM(RTRIM(@VPClass)) + ' - ' + COALESCE(@VPCraftClassDesc,@CGCClassTypeDesc,DISPLAYVALUE,@VPClass) 
			WHERE 
				PICKLISTID=@hrclasstypeplid
			AND STOREVALUE=LTRIM(RTRIM(@VPClass))
		END
		
		UPDATE [SESQL08].HRNET.dbo.PEOPLE SET UNIONTYPE=LTRIM(RTRIM(@VPCraft)) WHERE PEOPLE_ID=@peopleid --AND UNIONTYPE<>LTRIM(RTRIM(@VPCraft))
		UPDATE [SESQL08].HRNET.dbo.JOBDETAIL SET COSTCODE=LTRIM(RTRIM(@VPClass)) WHERE JOBDETAIL_ID=@jobdetailid --AND COSTCODE<>LTRIM(RTRIM(@VPClass))
		
	END
	ELSE
	BEGIN
		PRINT CAST('' AS CHAR(8)) +  '   Viewpoint Craft/Class: Not Found' 
	end
	PRINT ''
	
	FETCH ecur INTO
		@CompanyNumber		--int
	,	@EmployeeNumber		--int
	,	@FullName			--VARCHAR(100)
	,	@UnionYN			--CHAR(1)
	,	@COSTCODE			--VARCHAR(20)
	,	@EmployeeClass		--VARCHAR(10)
	,	@EmployeeType		--VARCHAR(10)
	,	@UNIONTYPE			--VARCHAR(50)
	,	@UNIONTYPENAME		--VARCHAR(50)
	,	@UNIONNUMBER		--VARCHAR(20)
	,	@jobdetailid
	,	@peopleid
END
CLOSE ecur
DEALLOCATE ecur
go
	
mspUpdateHRNetCraftClass

	                         