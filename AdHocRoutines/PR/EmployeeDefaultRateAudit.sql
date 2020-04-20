


declare @rcode		int
declare @EmplRate	bUnitCost
declare @desc		varchar(255)

declare @PRCo		bCompany
declare @Employee	bEmployee
declare @Craft		bCraft
declare @Class		bClass
declare @EarnCode	int
declare @Shift		int
declare @PostDate	bMonth

declare @rcnt		int
set @rcnt=0

set @PostDate = '11/2/2014'

declare empcur cursor for
select 
	PRCo, Employee, Craft, Class, Shift, EarnCode
from  
	PREH
where
	PRCo < 100
AND ActiveYN='Y'
AND	Employee in
	(
		899
		,2111
		,2193
		,2228
		,2229
		,2234
		,2235
		,2241
		,2242
		,2244
		,2247
		,2249
		,2253
		,2254
		,2255
		,2266
		,2269
		,2294
		,2298
		,2300
		,2301
		,2314
		,2316
		,2317
		,2318
		,2320
		,2324
		,2328
		,2331
		,2338
		,36555
	)
order by
	PRCo, Employee

print
	cast('' as char(5))
+	cast('Date' as char(15))
+	cast('Co' as char(5)) 
+	cast('Employee' as char(10)) 
+	cast('Craft' as char(10)) 
+	cast('Class' as char(10)) 
+	cast('Shift' as char(7))
+	cast('EC' as char(5))
+	cast('Rate' as char(10))
+	cast('Desc' as varchar(50))

print replicate('-',100)

open empcur
fetch empcur into
	@PRCo 
,	@Employee 
,	@Craft 
,	@Class 
,	@Shift
,	@EarnCode 

while @@fetch_status=0
begin
	
	select @rcnt=@rcnt+1
	exec @rcode = bspPRRateDefault @PRCo, @Employee, @PostDate, @Craft, @Class, null /*@crafttemplate*/, @Shift, @EarnCode, @EmplRate output,  @desc output
	--select @rcode,@EmplRate,@desc

	print
		cast(@rcnt as char(5))
	+   convert(char(15),@PostDate,102)
	+	cast(@PRCo as char(5)) 
	+	cast(@Employee as char(10)) 
	+	cast(@Craft as char(10)) 
	+	cast(@Class as char(10)) 
	+	cast(@Shift as char(7))
	+	cast(@EarnCode as char(5))
	+	cast(coalesce(@EmplRate,'???') as char(10))
	+	cast(coalesce(@desc,'') as varchar(50))

	fetch empcur into
		@PRCo 
	,	@Employee 
	,	@Craft 
	,	@Class 
	,	@Shift
	,	@EarnCode
end

close empcur
deallocate empcur
go

