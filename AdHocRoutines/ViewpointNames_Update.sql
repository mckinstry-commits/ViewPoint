--SELECT 
--	'References PREH' AS Description, so.name AS TableName, sc.name AS ColumnName, st.name AS TypeName, '' AS Action 
--FROM 
--	sysobjects so join
--	syscolumns sc ON so.id=sc.id JOIN
--	systypes st on sc.xusertype=st.xusertype
--WHERE 
--	st.name='bEmployee'
--union
--SELECT 'Has Employee Names' AS Description, 'PREH' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			--Employee Master
--union
--SELECT 'Has Employee Names' AS Description, 'JCMP' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			--Project Manager Master
--union
--SELECT 'Has Employee Names' AS Description, 'HQRV' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			--HQ Reviewers
--union
--SELECT 'Has Employee Names' AS Description, 'PMPM' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			-- PM Firm Contacts
--UNION
--SELECT 'Has Employee Names' AS Description, 'DDUP' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			-- VA User Profiles
--UNION
--SELECT 'Has Employee Names' AS Description, 'APVM' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action			-- AP Vendor Master
--UNION
--SELECT 'Has Employee Names' AS Description, 'HQ Contacts' AS TableName,'' as ColumnName, '' as TypeName, 'Update First/Last Name from HR using KnownAs' AS Action	-- (I don’t think we’re using this one)
--ORDER BY
--	1,2,3

alter view mvsCheckEmployeeNamesFromHRNET
as
select
	t1.*
,	p.FIRSTNAME AS HRFistName
,	p.LASTNAME AS HRLastNAme
,	p.KNOWNAS AS HRKnownAs
,	p.EMAILPRIMARY	AS HREmail
,	'UPDATE ' + t1.TableName + ' set ' AS SQL1
,	CASE t1.TableName
		WHEN 'PMPM' THEN ' FirstName=''' + p.KNOWNAS + ''', LastName=''' + p.LASTNAME + ''', EMail=COALESCE(''' + p.EMAILPRIMARY + ''',EMail) '
		WHEN 'HQContact' THEN ' FirstName=''' + p.KNOWNAS + ''', LastName=''' + p.LASTNAME + ''', Email=COALESCE(''' + p.EMAILPRIMARY + ''',Email) '
		WHEN 'DDUP' THEN ' FullName=''' + p.KNOWNAS + ' ' + p.LASTNAME + ''', EMail=COALESCE(''' + p.EMAILPRIMARY + ''',EMail) '
		WHEN 'APVM' THEN ' Name=''' + p.KNOWNAS + ' ' + p.LASTNAME + ''', EMail=COALESCE(''' + p.EMAILPRIMARY + ''',EMail) '
		WHEN 'HQRV' THEN ' Name=''' + p.KNOWNAS + ' ' + p.LASTNAME + ''', RevEmail=COALESCE(''' + p.EMAILPRIMARY + ''',RevEmail) '
		WHEN 'JCMP' THEN ' Name=''' + p.KNOWNAS + ' ' + p.LASTNAME + ''', EMail=COALESCE(''' + p.EMAILPRIMARY + ''',Email) '
		ELSE ''
	END AS SQL2
,	CASE t1.TableName
		WHEN 'HQContact' THEN ' WHERE (UPPER(Email)=UPPER(''' + t1.EMail + ''') OR ( UPPER(FirstName) = UPPER(''' + t1.FirstName + ''') AND UPPER(LastName) = UPPER(''' + t1.LastName + ''') ))'
		ELSE ' WHERE KeyID=' + CAST(t1.KeyID AS VARCHAR(20))
	END AS SQL3
from
(
SELECT 'APVM' AS TableName, KeyID, udPRCo AS PRCo, udEmployee AS Employee, '' AS FirstName, '' AS LastName, Name, EMail from APVM WHERE CHECKSUM(udPRCo, udEmployee) IN ( SELECT CHECKSUM(PRCo, Employee) FROM PREH WHERE PRCo<100)
union
SELECT 'DDUP' AS TableName, KeyID, PRCo, Employee, '' AS FirstName, '' AS LastName, FullName, EMail FROM DDUP WHERE CHECKSUM(PRCo, Employee) IN ( SELECT CHECKSUM(PRCo, Employee) FROM PREH WHERE PRCo<100)
union
SELECT DISTINCT 'HQRV' AS TableName, hqc.KeyID, preh.PRCo AS PRCo, preh.Employee AS Employee, '' AS FirstName, '' AS LastName, hqc.Name,hqc.RevEmail FROM HQRV hqc JOIN PREH preh ON (UPPER(hqc.RevEmail)=UPPER(preh.Email) OR ( UPPER(preh.FirstName)+ ' ' + UPPER(preh.LastName) = UPPER(hqc.Name) )) AND preh.ActiveYN='Y' AND preh.PRCo<100
union
SELECT 'JCMP' AS TableName, KeyID, udPRCo AS PRCo, udEmployee AS Employee, '' AS FirstName, '' AS LastName, Name, Email from JCMP WHERE CHECKSUM(udPRCo, udEmployee) IN ( SELECT CHECKSUM(PRCo, Employee) FROM PREH WHERE PRCo<100)
union
SELECT DISTINCT 'PMPM' AS TableName, hqc.KeyID, preh.PRCo AS PRCo, preh.Employee AS Employee, hqc.FirstName, hqc.LastName,hqc.FirstName + ' ' + hqc.LastName AS Name, hqc.EMail FROM PMPM hqc JOIN PREH preh ON (UPPER(hqc.EMail)=UPPER(preh.Email) OR ( UPPER(preh.FirstName) = UPPER(hqc.FirstName) AND UPPER(preh.LastName) = UPPER(hqc.LastName) )  ) AND preh.ActiveYN='Y' AND preh.PRCo<100 AND hqc.FirmNumber >= 800000
UNION
SELECT DISTINCT 'HQContact' AS TableName, null AS KeyID, preh.PRCo AS PRCo, preh.Employee AS Employee, hqc.FirstName, hqc.LastName, hqc.FirstName + ' ' + hqc.LastName AS FullName, hqc.Email FROM HQContact hqc JOIN PREH preh ON (UPPER(hqc.Email)=UPPER(preh.Email) OR ( UPPER(preh.FirstName) = UPPER(hqc.FirstName) AND UPPER(preh.LastName) = UPPER(hqc.LastName) )) AND preh.ActiveYN='Y' AND preh.PRCo<100
) t1 LEFT OUTER JOIN [SESQL08].HRNET.dbo.PEOPLE p ON
	t1.Employee=p.REFERENCENUMBER
AND p.STATUS='A' JOIN
	[SESQL08].HRNET.dbo.JOBDETAIL j ON
		p.PEOPLE_ID=j.PEOPLE_ID
	AND j.TOPJOB='T'
	AND j.CURRENTRECORD='YES' join
	[SESQL08].HRNET.dbo.COMPANY c ON
	j.COMPANY=c.COMPANY_ID
AND c.COMPANYREFNO=t1.PRCo
go

GRANT SELECT ON mvsCheckEmployeeNamesFromHRNET TO PUBLIC
go

--SELECT * FROM mvsCheckEmployeeNamesFromHRNET ORDER BY PRCo, Employee
go

--SELECT * FROM [SESQL08].HRNET.dbo.PEOPLE
--SELECT * FROM [SESQL08].HRNET.dbo.COMPANY
--SELECT DISTINCT TOPJOB, CURRENTRECORD FROM [SESQL08].HRNET.dbo.JOBDETAIL
--SELECT * FROM PREH

--PMPM	207899	20	565	ALEX	GREVAS	ALEX GREVAS	NULL	Alex	Grevas	Alex	alexg@mckinstry.com	UPDATE PMPM set 	 FirstName='Alex', LastName='Grevas', EMail='alexg@mckinstry.com' 	 WHERE KeyID=207899
--SELECT * FROM PMPM WHERE KeyID=207899