use Viewpoint
go

--select * into udEmpUtilization_BU_20160314 from udEmpUtilization

set nocount on

declare empcur cursor for
select
	PRCo
,	Employee
,	PRGroup
from
	PREH
where 
	PRCo<100
and ActiveYN='Y'
order by
	2,1
for read only

declare @doUpdate int
select @doUpdate = 0

declare @PRCo bCompany
declare @Employee bEmployee
declare @PRGroup bGroup

declare @Year int
declare @utilEmpYearRecCount int
declare @utilEmpRecCount int
declare @msg	varchar(255)

declare @proc_count int

select @Year=2016, @utilEmpYearRecCount=0, @utilEmpRecCount=0, @proc_count=0


print
	cast('#' as char(8))
+	cast('Co' as char(5))
+	cast('Employee' as char(10))
+	cast('PRGroup' as char(8))
+	cast('Y#/E#' as char(15))
+	'Msg'

print replicate('-',100)

open empcur
fetch empcur into @PRCo, @Employee, @PRGroup

while @@FETCH_STATUS=0
begin
	select @msg=''

	select @utilEmpYearRecCount=count(*) from udEmpUtilization where Co=@PRCo and Employee=@Employee and Year=@Year
	select @utilEmpRecCount=count(*) from udEmpUtilization where Employee=@Employee and Year=@Year	

	if @utilEmpYearRecCount = 1
		select @msg=@msg + 'One ' + cast(@Year as varchar(10)) + ' Util Rec for Emp ' + cast(@PRCo as varchar(10)) + '.' + cast(@Employee as varchar(15)) + ' '

	if @utilEmpRecCount = 1
		select @msg=@msg + 'One ' + cast(@Year as varchar(10)) + ' Util Rec for Emp ' + cast(@Employee as varchar(15)) + ' '

	if @utilEmpYearRecCount <> 1 and @utilEmpRecCount <> 1
	begin
		select @proc_count=@proc_count+1


		if @PRGroup=1 -- STAFF
		begin
			select @msg=@msg + 'Staff Emp: Needs Utilization Assignment'
		end

		if @PRGroup=2 -- UNION
		begin
			select @msg=@msg + 'Union Emp: Add 100% Util'

			if @doUpdate=1
			begin
				insert udEmpUtilization ( Year, Co, Employee, AnnualPct, Q1, Q2, Q3, Q4, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec )
				values ( @Year, @PRCo, @Employee, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 )
			end
		end

		print
			cast(@proc_count as char(8))
		+	cast(@PRCo as char(5))
		+	cast(@Employee as char(10))
		+	cast(@PRGroup as char(8))
		+	cast(cast(@utilEmpYearRecCount as varchar(10)) + '/' + cast(@utilEmpRecCount as varchar(10)) as char(15))
		+	@msg

	end

	fetch empcur into @PRCo, @Employee, @PRGroup

end

close empcur
deallocate empcur

go

set nocount off

