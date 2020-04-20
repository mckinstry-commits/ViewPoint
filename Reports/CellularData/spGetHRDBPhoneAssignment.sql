USE [CellularBill]
GO
/****** Object:  StoredProcedure [dbo].[spGetHRDBPhoneAssignment]    Script Date: 12/18/2014 6:53:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[spGetHRDBPhoneAssignment]

as

set nocount on

declare basecur cursor for
select
	EmpId, LastName, coalesce(Alias,FirstName) as FirstName, PRDepartment, GLDepartment, 'Mobile' as PhoneType, MobilePhone, Nextel as PTT, coalesce(DateCreated,getdate()) as EffectiveDate, Active
from
	Mck_HRDB.dbo.PersonnelInformation
where 
	( MobilePhone is not null or ( Nextel is not null and Nextel <> '0' ))
and EmpId < 500001  
union
select
	EmpId, LastName, coalesce(Alias,FirstName) as FirstName, PRDepartment, GLDepartment, 'Mobile' as PhoneType, MobilePhone, Nextel as PTT, coalesce(DateCreated,getdate()) as EffectiveDate, Active
from
	Mck_HRDB.dbo.ConsultantInformation
where 
	( MobilePhone is not null or Nextel is not null )
order by 2
for read only

declare @rcnt int

declare @EmpId int
declare @LastName varchar(50)
declare @FirstName varchar(50)
declare @PRDepartmentNumber decimal(9,0)
declare @GLDepartmentNumber decimal(9,0)
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
,	@PRDepartmentNumber
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
		print cast(@rcnt as varchar(10)) + ' ' + cast(@EmpId as varchar(15)) + ' ' + coalesce(@LastName,'') + ' ' + coalesce(@FirstName,'') + ' ' + ' ' + coalesce(@PhoneType,'') + ' ' + coalesce(@MobilePhone,'') + ' ' + coalesce(@PTT,'') + ' ' + coalesce(cast(@StartDate as varchar(20)),'')  + '  : ' + coalesce(cast(@GLDepartmentNumber as varchar(10)),'') 

		if not exists ( select 1 from EmployeePhoneAssignment where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT))
		begin
			insert EmployeePhoneAssignment 
			select
				@EmpId
			,	@LastName
			,	@FirstName
			,	@PRDepartmentNumber
			,	@GLDepartmentNumber
			,   ISNULL(@PhoneType,'Unknown')
			,	@MobilePhone
			,	@PTT
			,	@StartDate
		end
		else
		begin
			if @Active = 1
				update EmployeePhoneAssignment set EffectiveDate=getdate() where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT)
			else
				update EmployeePhoneAssignment set EffectiveDate=@StartDate where EmpID=@EmpId and (PhoneNumber=@MobilePhone or PTT=@PTT) 
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

			if not exists ( select 1 from EmployeePhoneAssignment where EmpID=@EmpId and (PhoneNumber=@AltPhone /* or PTT=@PTT */ ))
			begin
				insert EmployeePhoneAssignment 
				select
					@EmpId
				,	@LastName
				,	@FirstName
				,	@PRDepartmentNumber
				,	@GLDepartmentNumber
				,   ISNULL(@AltPhoneType,'Unknown')
				,	@AltPhone
				,	null
				,	@StartDate
			end
			else
			begin				
				if @Active = 1
					update EmployeePhoneAssignment set EffectiveDate=getdate() where EmpID=@EmpId and (PhoneNumber=@AltPhone )
				else
					update EmployeePhoneAssignment set EffectiveDate=@StartDate where EmpID=@EmpId and (PhoneNumber=@AltPhone ) 				
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
	,	@PRDepartmentNumber = null
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
	,   @PRDepartmentNumber
	,	@GLDepartmentNumber
	,	@PhoneType
	,	@MobilePhone
	,	@PTT
	,	@EffectiveDate
	,	@Active
end

close basecur
deallocate basecur

update EmployeePhoneAssignment
set 
	GLDepartmentNumber = o.GLDepartment
,	PRDepartmentNumber = o.PRDepartment
from
	McK_HRDB.dbo.PersonnelInformation o
where
	EmployeePhoneAssignment.EmpId = o.EmpId
and ( o.GLDepartment <> EmployeePhoneAssignment.GLDepartmentNumber or
	  o.PRDepartment <> EmployeePhoneAssignment.PRDepartmentNumber )


update EmployeePhoneAssignment
set 
	GLDepartmentNumber = o.GLDepartment
,	PRDepartmentNumber = o.PRDepartment
from
	McK_HRDB.dbo.ConsultantInformation o
where
	EmployeePhoneAssignment.EmpId = o.EmpId
and ( o.GLDepartment <> EmployeePhoneAssignment.GLDepartmentNumber or
	  o.PRDepartment <> EmployeePhoneAssignment.PRDepartmentNumber )

set nocount off

--select * from EmployeePhoneAssignment where LastName='Strader' order by 1

return @rcnt
