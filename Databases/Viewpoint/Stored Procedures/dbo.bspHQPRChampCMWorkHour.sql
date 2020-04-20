SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspHQPRChampCMWorkHour]
    /************************************
    * Created By: 9/28/00 EN
    * Modified By: 10/23/00 EN - getting trade seq code from bPRCM rather than bPROC
    *				EN 8/15/02 - use PREH_TradeSeq as optional override to PRCM_TradeSeq
    *				EN 3/22/04 - issue 23906 Champ software expects hourly rate to be not factored
    *				EN 7/22/04 - issue 25191 the JCJM join statement refers to PREH.JCCo ... should be PRTH.JCCo
	*				mh 04/16/08 - Issue 130652.  NYSDOT wants data presented in a weekly summary form.  Procedure
	*					anticipates a weekly payroll.  For now we will be telling users if they are not on weekly
	*					payroll they will have to do manual entry.  Per NY if the payroll is bi-weekly or some other 
	*					non-weekly format we have to break down the data into a weekly format.  However, they said we can 
	*					set the week start and end dates - does not have to be calendar Sun thru Sat.  See issue notes
	*					for more detail.
	*				EN 4/23/2009 #121035 This was originally based on the concept of the job # being the same as
	*					contract #.  However, this may not always be the case.  Changed to lookup contract # in bJCJM
	*					and return it instead of job #.
    *
    ***********************************/
    (@prco bCompany, @prgroup bGroup, @beginped bDate = '01/01/1950', @endped bDate = '01/01/2050',
     @beginjcco bCompany, @endjcco bCompany, @beginjob bJob, @endjob bJob)
   
   as
   set nocount on
   
	--This is the original query for CHAMP exports.  This will show a listing by day.  Leaving it in but commented
	--out for testing purposes.   It is now used to feed the @mytemptable table variable.
	/*
	Select distinct Job=th.Job, SSN=e.SSN, LastName=e.LastName, FirstName=e.FirstName,
	WorkDate=convert(varchar(10), th.PostDate, 101), HoursWorked=sum(th.Hours), HrlyRate=th.Rate/c.Factor, /*#23906 Un-Factor the rate*/ WageAmt=sum(th.Amt),
	TypeOfHrs=(CASE c.Factor when 1 then 1 when 1.5 then 2 when 2 then 3 when 2.5 then 4 when 3 then 5 else 1 END),
	Class=cc.EEOClass, Trade=(CASE when e.TradeSeq is not null then e.TradeSeq else m.TradeSeq end), --issue 17502
	Benefits=0, CheckNumber='', th.JCCo
	from PREH e
	join PRTH th on th.PRCo = e.PRCo and th.Employee = e.Employee
	join JCJM j on j.JCCo = th.JCCo and j.Job = th.Job
	join PRRC r on r.PRCo = e.PRCo and r.Race= e.Race
	join PRCM m on m.PRCo = e.PRCo and m.Craft = th.Craft
	join PRCC cc on cc.PRCo = e.PRCo and cc.Craft = th.Craft and cc.Class = th.Class
	join PREC c on c.PRCo = e.PRCo and c.EarnCode = th.EarnCode
	where th.PRCo = @prco and th.PRGroup = @prgroup and th.PREndDate >= @beginped and th.PREndDate <= @endped and
	th.JCCo >= isnull(@beginjcco,th.JCCo) and th.JCCo <= isnull(@endjcco,th.JCCo) and
	th.Job >= isnull(@beginjob,th.Job) and th.Job <= isnull(@endjob,th.Job)
	group by th.JCCo, th.Job, e.SSN, th.Rate, e.LastName, e.FirstName, th.PostDate, c.Factor, cc.EEOClass, m.TradeSeq, e.TradeSeq
	*/

	declare @mytemptable table(Contract varchar(10), SSN char(11), Employee int, LastName varchar(30),
	FirstName varchar(30), WorkDate smalldatetime, HoursWorked numeric(10,2), HrlyRate numeric(16,5),
	WageAmt numeric(12,2), TypeOfHrs tinyint, Class varchar(10), Trade tinyint, JCCo int, 
	PREndDate smalldatetime, Benefits tinyint, CheckNumber varchar(1))

	--Records to insert into temp table variable
	insert into @mytemptable (Contract, SSN, Employee, LastName, FirstName, WorkDate, HoursWorked, 
	HrlyRate, WageAmt, TypeOfHrs, Class, Trade, Benefits, CheckNumber, JCCo, PREndDate)

	Select distinct Contract=j.Contract, SSN=e.SSN, e.Employee, LastName=e.LastName, FirstName=e.FirstName, 
	WorkDate=convert(varchar(10), th.PostDate, 101), HoursWorked=sum(th.Hours), 
	HrlyRate=th.Rate/c.Factor, /*#23906 Un-Factor the rate*/ WageAmt=sum(th.Amt),
	TypeOfHrs=(CASE c.Factor when 1 then 1 when 1.5 then 2 when 2 then 3 when 2.5 then 4 when 3 then 5 else 1 END),
	Class=cc.EEOClass, Trade=(CASE when e.TradeSeq is not null then e.TradeSeq else m.TradeSeq end), --issue 17502
	Benefits=0, CheckNumber='', th.JCCo, th.PREndDate
	from PREH e
	join PRTH th on th.PRCo = e.PRCo and th.Employee = e.Employee
	join JCJM j on j.JCCo = th.JCCo and j.Job = th.Job
	join PRRC r on r.PRCo = e.PRCo and r.Race= e.Race
	join PRCM m on m.PRCo = e.PRCo and m.Craft = th.Craft
	join PRCC cc on cc.PRCo = e.PRCo and cc.Craft = th.Craft and cc.Class = th.Class
	join PREC c on c.PRCo = e.PRCo and c.EarnCode = th.EarnCode
	where th.PRCo = @prco and th.PRGroup = @prgroup and th.PREndDate >= @beginped and th.PREndDate <= @endped and
	th.JCCo >= isnull(@beginjcco,th.JCCo) and th.JCCo <= isnull(@endjcco,th.JCCo) and
	th.Job >= isnull(@beginjob,th.Job) and th.Job <= isnull(@endjob,th.Job)
	group by th.JCCo, j.Contract, e.SSN, th.Rate, e.Employee, e.LastName, e.FirstName, th.PostDate, c.Factor, 
	cc.EEOClass, m.TradeSeq, e.TradeSeq, th.PREndDate

	--Return contents of table variable.
	select PREndDate 'WorkDate', Contract, TypeOfHrs, SSN, LastName, FirstName, Employee, 
	sum(HoursWorked) 'HoursWorked', HrlyRate, sum(WageAmt) 'WageAmt',  
	Class, Trade, Benefits, CheckNumber
	from @mytemptable 
	group by PREndDate, Contract, SSN, TypeOfHrs, LastName, FirstName, Employee,  HrlyRate,
	Class, Trade, Benefits, CheckNumber
	Order By PREndDate, Employee, Contract, TypeOfHrs


GO
GRANT EXECUTE ON  [dbo].[bspHQPRChampCMWorkHour] TO [public]
GO
