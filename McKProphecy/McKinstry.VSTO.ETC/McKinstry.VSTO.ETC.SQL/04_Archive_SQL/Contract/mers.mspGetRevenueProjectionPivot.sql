use Viewpoint
go

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspGetRevenueProjectionPivot' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspGetRevenueProjectionPivot'
	DROP PROCEDURE mers.mspGetRevenueProjectionPivot
end
go

print 'CREATE PROCEDURE mers.mspGetRevenueProjectionPivot'
go

CREATE PROCEDURE mers.mspGetRevenueProjectionPivot
(
	@JCCo		bCompany 
,	@Contract	bContract
)
as
-- ========================================================================
-- mers.mspGetRevenueProjectionBatchPivot
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	2016.05.06 - 2016.05.06 - LWO - Created
	/*Procedure to return JC Revenue Projection Detail (udJCIPD) data for use in "Prophecy" VSTO workbook solution.
	Determines the Start and End Months for a Provided Contract and returns the data "pivoted" so that the time 
	span (months) are returned as columns (instead of the row based storage method).*/
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================

set nocount on

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX),
	@dispMonth bMonth,
	@tmpSQL varchar(255)

select @dispMonth=max(Mth) from JCIP where JCCo=@JCCo and Contract=@Contract


if @dispMonth is not null 
	select @tmpSQL= 'and b.Mth = ''' + convert(varchar(10), @dispMonth, 120) + ''''
else 
	select @tmpSQL=''	

print @tmpSQL

--;with cte (Co, Contract, datelist, maxdate) as
--(
--    select Co, Contract, min(FromDate) datelist, max(ToDate) maxdate
--    from udJCIPD
--	where Co=@JCCo and Contract=@Contract
--	group by Co, Contract
--    union all
--    select Co, Contract, dateadd(month, 1, datelist), maxdate
--    from cte
--    where datelist < maxdate and Co=@JCCo and Contract=@Contract
--) 
--select Co, Contract,c.datelist
--into #tempDates
--from cte c

;with cte (JCCo, Contract, datelist, maxdate) as
(
    select JCCo, Contract, min(StartMonth) datelist, max(coalesce(ProjCloseDate, getdate())) maxdate
    from JCCM
	where JCCo=@JCCo and Contract=@Contract
	group by JCCo, Contract
    union all
    select JCCo, Contract, dateadd(month, 1, datelist), maxdate
    from cte
    where datelist < dateadd(day,( day(maxdate) * -1 ) + 1 ,maxdate) and JCCo=@JCCo and Contract=@Contract
) 
select JCCo, Contract,c.datelist
into #tempDates
from cte c

if not exists ( select 1 from udJCIPD where Co=@JCCo and Contract=@Contract and Mth=@dispMonth)
begin
	insert udJCIPD ( Co, Contract, Item, Mth, FromDate, ToDate )
	select distinct
		jcci.JCCo, jcci.Contract, jcci.Item, @dispMonth, t.datelist, dateadd(day,-1,dateadd(month,1,t.datelist))
	from #tempDates t join
	JCCI jcci on t.JCCo=jcci.JCCo and t.Contract=jcci.Contract

end

--select * from #tempDates
--select * from JCCI where JCCo=@JCCo and Contract=@Contract

--drop table #tempDates

select @cols = STUFF((SELECT distinct ',' + QUOTENAME(convert(CHAR(10), datelist, 120)) 
                    from #tempDates
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT JCCo, Contract, Item, Month, ' + @cols + ' from 
             (
                select jcci.JCCo, jcci.Contract, jcci.Item, b.Mth as Month, ProjDollars,
                    convert(CHAR(10), d.datelist, 120) PivotDate
                from #tempDates d join 
					JCCI jcci on
						d.JCCo=jcci.JCCo
					and d.Contract=jcci.Contract join
					udJCIPD b on 
						jcci.JCCo=b.Co
					and jcci.Contract=b.Contract
					and jcci.Item=b.Item
					and d.datelist between b.FromDate and b.ToDate
					' + @tmpSQL + ' 
            ) x
            pivot 
            (
                sum(ProjDollars)
                for PivotDate in (' + @cols + ')
            ) p;'

print @query
set nocount off

execute(@query)

drop table #tempDates

go

/*
declare @JCCo bCompany
declare @Contract bContract
declare @Month bMonth

select
	@JCCo=1
,	@Contract='104203-'

--select max(Mth) from JCIP where JCCo=@JCCo and Contract=@Contract
exec mers.mspGetRevenueProjectionPivot @JCCo=@JCCo, @Contract=@Contract
--select * from udJCIRD where Co=@JCCo and Contract=@Contract

select @Contract=' 14345-'
exec mers.mspGetRevenueProjectionPivot @JCCo=@JCCo, @Contract=@Contract
--select * from udJCIRD where Co=@JCCo and Contract=@Contract
go
*/