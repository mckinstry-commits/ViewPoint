SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[viDim_Date]

/**************************************************
 * Alterd: DH 5/13/08
 * Modified:      
 * Usage:  Dimension View used in SSAS cubes returning dates between the first Fiscal and Last fiscal periods 
 *         set up in the GL Fiscal Period tables (bGLFP and bGLFY)
 *         CalendarDateID is an integer value derived from the Datediff function, which is then used for linking
 *         dates to date columns in Fact tables.
 *
 ********************************************************/

as

with DateRange(Date) AS
    ( SELECT TheDate from vf_DateList('01/01/1950', '01/01/2100') )



select  Datediff(dd,'1/1/1950',Date) CalendarDateID, /*ROW_NUMBER() OVER( order by Date )*/ 
        Date as CalendarDate,
        Datediff(mm,'1/1/1950',cast(
                                cast(DATEPART(yy,Date) as varchar) + '-'+ DATENAME(m, Date) +'-01' 
                               as datetime)
                ) CalendarMonthID,
        cast(
                                cast(DATEPART(yy,Date) as varchar) + '-'+ DATENAME(m, Date) +'-01' 
                               as datetime) CalendarMonth,
        convert(char(8),Date,112) ISODate,
        DATEPART(yy,Date) as CalendarYearNumber,
	    case when datepart(yy, Date)= 1950 then 'None' else cast(DATEPART(yy,Date) as varchar) end as CalendarYearName,
        cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime) FirstDateOfCalendarYear,
        cast(cast(DATEPART(yy,Date) as varchar) + '-12-31' as datetime) LastDateOfCalendarYear,
        DATEPART(dy, Date) CalendarDayOfYear,
        DATEPART(q, Date) CalendarQuarterNumber,
        'Quarter ' + cast(DATEPART(q, Date) as char(1)) CalendarQuarterName,
        'Quarter ' + cast(DATEPART(q, Date) as char(1)) + ', ' + cast(DATEPART(yy,Date) as varchar) CalendarQuarterNameWithYear,
        'Q' + cast(DATEPART(q, Date) as char(1))       CalendarQuarterShortName,
        'Q' + cast(DATEPART(q, Date) as char(1)) + ' ' + cast(DATEPART(yy,Date) as varchar) CalendarQuarterShortNameWithYear,
        CASE DATEPART(q, Date)
            WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
            WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-04-01' as datetime)
            WHEN 3 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
            WHEN 4 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-10-01' as datetime)
        END   CalendarFirstDateOfQuarter,
            dateadd(day,-1,dateadd(q,1, CASE DATEPART(q, Date)                                                                                                                                    WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                                    END)) CalendarLastDateOfQuarter,
			Datediff(q,'1/1/1950',Date) CalendarQuarterID,
            DateDiff(day, CASE DATEPART(q, Date) WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                                                    WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-04-01' as datetime)
                                                    WHEN 3 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
                                                    WHEN 4 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-10-01' as datetime)
                          END , Date) + 1 CalendarDayOfQuarter,
            'Day ' + cast(DateDiff(day, CASE DATEPART(q, Date)
                                         WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                                         WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-04-01' as datetime)
                                         WHEN 3 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
                                         WHEN 4 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-10-01' as datetime)
                                        END
                                    , Date) + 1 as varchar(2)) + ' of Q' + cast(DATEPART(q, Date) as char(1)) CalendarDayOfQuarterName,

            CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END CalendarHalfNumber,
            'Half ' + cast(CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END as char(1)) CalendarHalfName,
            'Half ' + cast(CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END as char(1)) + ', ' + cast(DATEPART(yy,Date) as varchar) CalendarHalfNameWithYear,
            'H' + cast(CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END as char(1)) CalendarHalfShortName,
            'H' + cast(CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END as char(1)) + ' ' + cast(DATEPART(yy,Date) as varchar) HalfShortNameWithYear,
            CASE (CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END)
                       WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                       WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
                   END CalendarFirstDateOfHalf,
            CASE (CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END)
                       WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-06-30' as datetime)
                        WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-12-31' as datetime)
                   END CalendarLastDateOfHalf,
            DateDiff(day, CASE (CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END)
                                     WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                                      WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
                          END, Date) + 1 CalendarDayOfHalf,
           'Day ' + cast(DateDiff(day, CASE (CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END)
                                                   WHEN 1 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-01-01' as datetime)
                                                   WHEN 2 THEN cast(cast(DATEPART(yy,Date) as varchar) + '-07-01' as datetime)
                                         END
                                   , Date) + 1 as varchar(3)) + ' of H' + cast(CASE WHEN DATEPART(q, Date) <= 2 THEN 1 ELSE 2 END as char(1)) CalendarDayOfHalfName,
                       DATENAME(mm, Date) CalendarMonthName,
                       DATENAME(mm, Date) + ', ' + cast(DATEPART(yy,Date) as varchar) CalendarMonthNameWithYear,
                       Left(DATENAME(m, Date),3)   CalendarMonthShortName,
                       Left(DATENAME(m, Date) + ' ' + cast(DATEPART(yy,Date) as varchar),3)  CalendarMonthShortNameWithYear,
                       DATEPART(m, Date) CalendarMonthNumber,
                       cast(cast(DATEPART(yy,Date) as varchar) + '-'+ DATENAME(m, Date) +'-01' as datetime) CalendarFirstDateOfMonth,
                       dateadd(day,-1,dateadd(m,1,cast(cast(DATEPART(yy,Date) as varchar) + '-'+ DATENAME(m, Date) +'-01' as datetime))) LastDateOfMonth,
                       DATEPART(d, Date) CalendarDayOfMonth,
                       datename(m,Date) + ' ' + 
                                         cast(datepart(d,Date) as varchar(2)) +
                                         CASE left(right('00' + cast(datepart(d,Date) as varchar(2)),2),1)
                                            WHEN '1' THEN 'th'
                                            ELSE 
                                                 CASE right(right('00' + cast(datepart(d,Date) as varchar(2)),2),1)
                                                           WHEN '1' THEN 'st'
                                                           WHEN '2' THEN 'nd'
                                                           WHEN '3' THEN 'rd'
                                                           ELSE 'th'
                                                  END
                                            END CalendarDayOfMonthName,
                     'Week ' + datename(wk,Date) CalendarWeekName,
                     'Week ' + datename(wk,Date) + ', ' + cast(DATEPART(yy,Date) as varchar) CalendarWeekNameWithYear,
                     'WK'+right('00'+datename(wk,Date),2) CalendarWeekShortName,    
                     'WK'+right('00'+datename(wk,Date),2) + ' ' + cast(DATEPART(yy,Date) as varchar) CalendarWeekShortNameWithYear,
                      datepart(wk,Date) CalendarWeekNumber,
                      dateadd(day,(datepart(dw,Date)-1)*-1,Date) CalendarFirstDateOfWeek,
					  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date))) CalendarLastDateOfWeek,
				      Cast(
         cast(Month(
                  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
                  ) as varchar)
            +'-01-'+
          cast(Year(
				  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
				 ) as varchar)
		     as datetime
             ) as MonthOfCalendarLastDateOfWeek,
         Left(DateName(m,
              Cast(
         cast(Month(
                  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
                  ) as varchar)
            +'-01-'+
          cast(Year(
				  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
				 ) as varchar)
		     as datetime
             )),3) as MonthNameOfCalendarLastDateOfWeek,
		  Datediff(wk,'1/1/1950',Date) CalendarWeekID,
					  CAST(
					  cast(datepart(m,
                                      dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
                                    ) as varchar)+'-'+
					  cast(datepart(d,
									  dateadd(day,-1,dateadd(wk,1,dateadd(day,(datepart(dw,Date)-1)*-1,Date)))
                                    ) as varchar)
					  AS VARCHAR) CalendarLastDateOfWeekMonthDay,
					  datepart(dw, Date) CalendarDayOfWeek,
                      datename(dw, Date) CalendarDayOfWeekName,
                       case datepart(dw, Date) WHEN 1 THEN 0 WHEN 7 THEN 0 ELSE 1 END IsWeekday,
                       case datepart(dw, Date) WHEN 1 THEN 1 WHEN 7 THEN 1 ELSE 0 END IsWeekend

-- **********************************************************************************
                /*GLCo,
                Mth as FiscalMth,
                FiscalMthName,
                FiscalQtr,
                FiscalYrNumber,
                FiscalYrEndMth,
                FiscalYrEndMthName,
                FiscalYrBegMth,
                FiscalYrBegMthName,
                FiscalMthID*/

from DateRange
  left join (select distinct Mth as Mth from bGLFP With (NoLock)) as g
on cast(cast(DATEPART(yy,DateRange.Date) as varchar) + '-'+ DATENAME(m, Date) +'-01' as datetime) = g.Mth

GO
GRANT SELECT ON  [dbo].[viDim_Date] TO [public]
GRANT INSERT ON  [dbo].[viDim_Date] TO [public]
GRANT DELETE ON  [dbo].[viDim_Date] TO [public]
GRANT UPDATE ON  [dbo].[viDim_Date] TO [public]
GRANT SELECT ON  [dbo].[viDim_Date] TO [Viewpoint]
GRANT INSERT ON  [dbo].[viDim_Date] TO [Viewpoint]
GRANT DELETE ON  [dbo].[viDim_Date] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[viDim_Date] TO [Viewpoint]
GO
