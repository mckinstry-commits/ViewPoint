use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME='mers')
BEGIN
	print 'SCHEMA ''mers'' already exists  -- McKinstry Enterprise Reporting Schema'
END
ELSE
BEGIN
	print 'CREATE SCHEMA ''mers'' -- McKinstry Enterprise Reporting Schema'
	EXEC sp_executesql N'CREATE SCHEMA mers AUTHORIZATION dbo'
END
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' and ROUTINE_NAME='mfnPRHeadcountByDept')
begin
	print 'DROP FUNCTION mers.mfnPRHeadcountByDept'
	DROP FUNCTION mers.mfnPRHeadcountByDept
end
go

print 'CREATE FUNCTION mers.mfnPRHeadcountByDept'
go

CREATE FUNCTION mers.mfnPRHeadcountByDept 
(	
	-- Add the parameters for the function here
	@Company [dbo].[bCompany] = null
)
RETURNS @retTable TABLE 
(
	Company				bCompany	NULL
,	PRGroup
)
AS
begin

	INSERT @retTable ( )

	SELECT 
		FN.PRCo AS Company
		,Grp.Description AS PayrollGroup
		,Dept.PRDept AS DepartmentNumber
		,Dept.Description AS DepartmentName
		,FN.Employee AS EmployeeNumber
		,FN.FullName AS EmployeeFullName
		,Class.Description AS ClassDescription
		,(CASE WHEN SUM(Empl.ActualHours) > 0 THEN SUM(Empl.ActualCost)/SUM(Empl.ActualHours) ELSE 0 END) AS HourlyRate
		,NULL AS HireDate -- Hire date not available after removing join to PREH
		,MAX(Empl.PostedDate) AS DateLastWorked
	 FROM   
		PREHFullName FN
		JOIN PRGR Grp ON FN.PRCo = Grp.PRCo AND FN.PRGroup = Grp.PRGroup
		JOIN PRDP Dept ON FN.PRCo = Dept.PRCo AND FN.PRDept = Dept.PRDept
		JOIN PRCM Craft ON Craft.PRCo = FN.PRCo AND Craft.Craft = FN.Craft
		JOIN PRCC Class ON Class.PRCo = Craft.PRCo AND Class.Craft = Craft.Craft AND Class.Class = FN.Class
		LEFT OUTER JOIN JCCD Empl ON FN.PRCo = Empl.PRCo AND FN.Employee = Empl.Employee
	 WHERE  
		FN.PRCo = @Company AND FN.ActiveYN = 'Y'
	 GROUP BY 
		FN.PRCo, Grp.Description, Dept.PRDept, Dept.Description, FN.Employee, FN.FullName, Class.DESCRIPTION
        
	RETURN 
end
--(
--	-- Add the SELECT statement with parameter references here
--	SELECT @@SERVERNAME as ServerName, db_name() as DatabaseName, suser_sname() as CurrentUser, getdate() as CurrentDateTime,@parmString as Note
--)
GO

select * from mers.mfnTestFunction('Direct from function')
go


if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' and ROUTINE_NAME='mspTestFunction')
begin
	print 'DROP PROCEDURE mers.mspTestFunction'
	DROP PROCEDURE mers.mspTestFunction
end
go

print 'CREATE PROCEDURE mers.mspTestFunction'
go

CREATE PROCEDURE mers.mspTestFunction 
(	
	-- Add the parameters for the function here
	@parmString	varchar(50) = ''
)
AS
BEGIN
	select * from mers.mfnTestFunction(@parmString)
END
GO

exec mers.mspTestFunction @parmString='Called via Stored Procedure'
go

if exists ( select * from [INFORMATION_SCHEMA].[VIEWS] where TABLE_SCHEMA='mers' and TABLE_NAME='mvwTestFunction')
begin
	print 'DROP VIEW mers.mvwTestFunction'
	DROP VIEW mers.mvwTestFunction
end
go

print 'CREATE VIEW mers.mvwTestFunction'
go

CREATE VIEW mers.mvwTestFunction 
AS

select * from mers.mfnTestFunction('Called via database View')

GO

select * from mers.mvwTestFunction 
go





