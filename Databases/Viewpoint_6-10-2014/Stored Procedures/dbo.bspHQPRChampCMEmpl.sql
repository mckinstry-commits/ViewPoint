SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspHQPRChampCMEmpl]
    /************************************
    * Created By: 9/28/00 EN
    * Modified By: 10/23/00 EN - getting trade seq code from bPRCM rather than bPROC
    *				EN 8/15/02 - use PREH_TradeSeq as optional override to PRCM_TradeSeq
    *				EN 10/30/03 - issue 22179 pull job from bPRTH and join JCJM with t.JCCo rather than e.JCCo
    *				EN 5/19/04 - issue 22570 pull rate from bPRTH
	*				EN 4/23/2009 #121035 This was originally based on the concept of the job # being the same as
	*					contract #.  However, this may not always be the case.  Changed to lookup contract # in bJCJM
	*					and return it instead of job #.
    *
    ***********************************/
    (@prco bCompany, @prgroup bGroup, @beginped bDate = '01/01/1950', @endped bDate = '01/01/2050',
     @beginjcco bCompany, @endjcco bCompany, @beginjob bJob, @endjob bJob)
   
   as
   set nocount on
   
   Select distinct Contract=j.Contract, SSN=e.SSN, LastName=e.LastName, FirstName=e.FirstName, BirthDate=e.BirthDate, Gender=e.Sex,
       Race=(CASE r.EEOCat when 'B' then 1 when 'H' then 2 when 'I' then 3 when 'W' then 4 when 'A' then 5 else 4 END),
       Trade=(CASE when e.TradeSeq is not null then e.TradeSeq else m.TradeSeq end), --issue 17502
   	Class=f.EEOClass, HrlyRate=t.Rate/c.Factor,
       Benefits=0, Address1=e.Address, Address2=e.Address2, City=e.City, State=e.State, Zip=e.Zip, Phone=e.Phone
   from dbo.PREH e with (nolock)
   join dbo.PRTH t with (nolock) on t.PRCo = e.PRCo and t.Employee = e.Employee
   join dbo.JCJM j with (nolock) on j.JCCo = t.JCCo and j.Job = t.Job
   join dbo.PRRC r with (nolock) on r.PRCo = e.PRCo and r.Race= e.Race
   join dbo.PRCM m with (nolock) on m.PRCo = e.PRCo and m.Craft = t.Craft
   join dbo.PRCC f with (nolock) on f.PRCo = e.PRCo and f.Craft = t.Craft and f.Class = t.Class
   join dbo.PREC c with (nolock) on c.PRCo = e.PRCo and c.EarnCode = t.EarnCode
   where t.PRCo = @prco and t.PRGroup = @prgroup and t.PREndDate >= @beginped and t.PREndDate <= @endped and
       t.JCCo >= isnull(@beginjcco,t.JCCo) and t.JCCo <= isnull(@endjcco,t.JCCo) and
       t.Job >= isnull(@beginjob,t.Job) and t.Job <= isnull(@endjob,t.Job)
   order by e.SSN

GO
GRANT EXECUTE ON  [dbo].[bspHQPRChampCMEmpl] TO [public]
GO
