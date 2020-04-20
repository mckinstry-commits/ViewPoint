USE [CellularBill]
GO
/****** Object:  StoredProcedure [dbo].[spGetHRNetPhoneAssignment]    Script Date: 12/18/2014 11:43:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[spGetHRNetPhoneAssignment]
as

set nocount on

IF OBJECT_ID('tempdb..#tmpVPEmpGLDept') IS NOT NULL DROP TABLE #tmpVPEmpGLDept
SELECT 
    preh.PRCo as PRCompany, preh.Employee as EmpId, glpi.Instance COLLATE SQL_Latin1_General_CP1_CI_AS as GLDepartment
INTO #tmpVPEmpGLDept
FROM
    [ViewpointAG\Viewpoint].Viewpoint.dbo.PREHFullName preh JOIN
	[ViewpointAG\Viewpoint].Viewpoint.dbo.bHQCO hqco ON
		preh.PRCo=hqco.HQCo
	AND hqco.udTestCo <> 'Y' JOIN
    [ViewpointAG\Viewpoint].Viewpoint.dbo.PRDP prdp ON
            preh.PRCo=prdp.PRCo
    AND  preh.PRDept=prdp.PRDept JOIN
    [ViewpointAG\Viewpoint].Viewpoint.dbo.GLPI glpi ON
			prdp.GLCo=glpi.GLCo
    AND  glpi.PartNo=3
    AND  SUBSTRING(prdp.JCFixedRateGLAcct,10,4)=glpi.Instance

declare basecur cursor for
select
	h.EmpId, /* e.EMPLOYEEID, */ h.LastName, coalesce(h.Alias, h.FirstName) as FirstName, /* h.PRDepartment, left(e.DEPT,4) as GLDepartment, h.GLDepartment,*/ t.GLDepartment, 'Mobile' as PhoneType, h.MobilePhone, h.Nextel as PTT, coalesce(h.DateCreated,getdate()) as EffectiveDate, h.Active
from
	Mck_HRDB.dbo.PersonnelInformation h --LEFT JOIN HRNET.dbo.vwMcKAllEmployees e on h.EmpID=e.EMPLOYEEID 
	LEFT JOIN #tmpVPEmpGLDept t ON h.EmpID=t.EmpId AND h.CompanyId=t.PRCompany
where 
	( h.MobilePhone is not null or ( h.Nextel is not null and h.Nextel <> '0' )) and h.EmpId < 500001  
union
select	h.EmpId, h.LastName, coalesce(h.Alias, h.FirstName) as FirstName, /* h.PRDepartment, left(e.DEPT,4) as GLDepartment, h.GLDepartment,*/ t.GLDepartment, 'Mobile' as PhoneType, h.MobilePhone, h.Nextel as PTT, coalesce(h.DateCreated,getdate()) as EffectiveDate, h.Active
from
	Mck_HRDB.dbo.ConsultantInformation h --LEFT JOIN HRNET.dbo.vwMcKAllEmployees e on h.EmpID=e.EMPLOYEEID 
	LEFT JOIN #tmpVPEmpGLDept t ON h.EmpID=t.EmpId AND h.CompanyId=t.PRCompany
where 
	( h.MobilePhone is not null or h.Nextel is not null )
order by 1
for read only

declare @rcnt int

declare @EmpId int
declare @LastName varchar(50)
declare @FirstName varchar(50)
--declare @PRDepartmentNumber decimal(9,0)
declare @GLDepartmentNumber char(20) --decimal(9,0)
declare @PhoneType varchar(20)
declare @MobilePhone varchar(20)
declare @PTT varchar(20)
declare @EffectiveDate datetime
declare @AltPhoneType varchar(20)
declare @AltPhone varchar(20)
declare @Active bit

declare @StartDate datetime
declare @EndDate datetime

select @rcnt = 0

open basecur
fetch basecur into
	@EmpId
,	@LastName
,	@FirstName
--,	@PRDepartmentNumber
,	@GLDepartmentNumber
,   @PhoneType
,	@MobilePhone
,	@PTT
,	@EffectiveDate
,	@Active

while @@fetch_status = 0
begin

	-- Get Effective Dates
	if @Active = 1
		select @StartDate = coalesce(min(HireDate),@EffectiveDate) from Mck_HRDB.dbo.EmployeeHistory where EmpId=@EmpId
	else
		select @StartDate = coalesce(max(TermDate),@EffectiveDate) from Mck_HRDB.dbo.EmployeeHistory where EmpId=@EmpId 

	--select @StartDate = coalesce(min(HireDate),@EffectiveDate) from Mck_HRDB.dbo.EmployeeHistory where EmpId=@EmpId and HireDate is not null
	--select @EndDate = max(TermDate) from Mck_HRDB.dbo.EmployeeHistory where EmpId=@EmpId and TermDate > @StartDate


	select  @MobilePhone = replace(@MobilePhone,'-','')
	select  @MobilePhone = replace(@MobilePhone,'(','')
	select  @MobilePhone = replace(@MobilePhone,')','')
	select  @MobilePhone = replace(@MobilePhone,' ','')

	if @PTT = '0'
		select @PTT = null

	if ( @PTT is not null and @PTT not like '112*139*%')
		select @PTT = '112*139*' + @PTT

	if ltrim(rtrim(@MobilePhone)) <> '' or ltrim(rtrim(@PTT)) <> ''
	begin
		select @rcnt = @rcnt + 1
		print cast(@rcnt as varchar(10)) + ' ' + cast(@EmpId as varchar(15)) + ' ' + 
coalesce(@LastName,'') + ' ' + coalesce(@FirstName,'') + ' ' + ' ' + coalesce(@PhoneType,'') + ' ' + 
coalesce(@MobilePhone,'') + ' ' + coalesce(@PTT,'') + ' ' + coalesce(cast(@StartDate as varchar
(20)),'')  + '  : ' + coalesce(cast(@GLDepartmentNumber as varchar(10)),'') 

		if not exists ( select 1 from VPEmployeePhoneAssignment where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT))
		begin
			insert VPEmployeePhoneAssignment 
			select
				@EmpId
			,	@LastName
			,	@FirstName
			--,	@PRDepartmentNumber
			,	@GLDepartmentNumber
			,   ISNULL(@PhoneType,'Unknown')
			,	@MobilePhone
			,	@PTT
			,	@StartDate
		end
		else
		begin
			if @Active = 1
				update VPEmployeePhoneAssignment set EffectiveDate=getdate() where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT)
			else
				update VPEmployeePhoneAssignment set EffectiveDate=@StartDate where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT) 
		end
	end


	-- Get Additional Phone Numbers
	--if exists ( select 1 from Mck_HRDB.dbo.PhoneInfo where EmpID = @EmpId and PhoneNum is not null)
    --begin

	--print @EmpId

	declare altcur cursor for
	select
		PhoneDesc, PhoneNum
	from
		Mck_HRDB.dbo.PhoneInfo
	where
		EmpID = @EmpId
	and PhoneNum is not null
	order by 2
	for read only

	open altcur
	fetch altcur into @AltPhoneType, @AltPhone

	while @@fetch_status = 0
	begin
		select  @AltPhone = replace(@AltPhone,'-','')
		select  @AltPhone = replace(@AltPhone,'(','')
		select  @AltPhone = replace(@AltPhone,')','')
		select  @AltPhone = replace(@AltPhone,' ','')
		if ltrim(rtrim(@AltPhone)) <> ''
		begin
			select @rcnt = @rcnt + 1
			print cast(@rcnt as varchar(10)) + ' ' + cast(@EmpId as varchar(15)) + ' ' + coalesce(@LastName,'') + ' ' + coalesce(@FirstName,'') + ' ' + coalesce(@AltPhoneType,'') + ' ' + coalesce(@AltPhone,'') + ' ' + coalesce(cast(@StartDate as varchar(20)),'') 			

			if not exists ( select 1 from VPEmployeePhoneAssignment where EmpID=@EmpId and (PhoneNumber=@AltPhone /* or PTT=@PTT */ ))
			begin
				insert VPEmployeePhoneAssignment 
				select
					@EmpId
				,	@LastName
				,	@FirstName
				--,	@PRDepartmentNumber
				,	@GLDepartmentNumber
				,   ISNULL(@AltPhoneType,'Unknown')
				,	@AltPhone
				,	null
				,	@StartDate
			end
			else
			begin				
				if @Active = 1
					update VPEmployeePhoneAssignment set EffectiveDate=getdate() where EmpID=@EmpId and (PhoneNumber=@AltPhone )
				else
					update VPEmployeePhoneAssignment set EffectiveDate=@StartDate where EmpID=@EmpId and (PhoneNumber=@AltPhone ) 				
			end
		end

		fetch altcur into @AltPhoneType, @AltPhone
	end

	close altcur
	deallocate altcur
	--end

	select
		@EmpId = null
	,	@LastName = null
	,	@FirstName = null
	--,	@PRDepartmentNumber = null
	,	@GLDepartmentNumber = null
	,   @PhoneType = null
	,	@MobilePhone = null
	,	@PTT = null
	,	@EffectiveDate = null
	,	@Active = null

	fetch basecur into
		@EmpId
	,	@LastName
	,	@FirstName
	--,   @PRDepartmentNumber
	,	@GLDepartmentNumber
	,	@PhoneType
	,	@MobilePhone
	,	@PTT
	,	@EffectiveDate
	,	@Active
end

close basecur
deallocate basecur

update VPEmployeePhoneAssignment
set 
	GLDepartmentNumber = t.GLDepartment --left(e.DEPT,4) --o.GLDepartment
--,	PRDepartmentNumber = o.PRDepartment
from
	McK_HRDB.dbo.PersonnelInformation o --LEFT JOIN HRNET.dbo.vwMcKAllEmployees e on o.EmpID=e.EMPLOYEEID 
	JOIN #tmpVPEmpGLDept t ON o.EmpID=t.EmpId AND o.CompanyId=t.PRCompany
where
	VPEmployeePhoneAssignment.EmpId = o.EmpId
and ( t.GLDepartment <> VPEmployeePhoneAssignment.GLDepartmentNumber ) --or
	  --( o.PRDepartment <> VPEmployeePhoneAssignment.PRDepartmentNumber )


update VPEmployeePhoneAssignment
set 
	GLDepartmentNumber = t.GLDepartment --left(e.DEPT,4) --o.GLDepartment
--,	PRDepartmentNumber = o.PRDepartment
from
	McK_HRDB.dbo.ConsultantInformation o --LEFT JOIN HRNET.dbo.vwMcKAllEmployees e on o.EmpID=e.EMPLOYEEID 
	JOIN #tmpVPEmpGLDept t ON o.EmpID=t.EmpId AND o.CompanyId=t.PRCompany
where
	VPEmployeePhoneAssignment.EmpId = o.EmpId
and ( t.GLDepartment <> VPEmployeePhoneAssignment.GLDepartmentNumber ) --or
	  --( o.PRDepartment <> VPEmployeePhoneAssignment.PRDepartmentNumber )

set nocount off
return @rcnt