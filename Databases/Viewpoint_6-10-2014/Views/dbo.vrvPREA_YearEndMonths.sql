SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[vrvPREA_YearEndMonths]

/******************
 Created:  10/15/10  DH
 Usage:  View that returns Year End Month for each PR Company and Month that exist in
		 PR Employee Accumulations (PREA). Currently, view is hardcoded to return year 
		 end months of June for Australia.  Additional countries can be easily added later 
		 to case statement.  All other countries default to December year end month.  
		 The view is then linked to any payroll reports using PREA and is used to 
		 help calculate YTD and QTD information within these reports.
 
 Used in the following reports:
 
 
 
 ***************/

 
as

/*Get each distinct Mth in PREA by Company
  YearOffset used to calculate Year and Quarter End.
  For now, add new countries to case statement*/

With PREAMonths (PRCo, Mth, YearEndMthOffset)

as

(Select distinct PRCo, Mth
			     , YearEndMthOffset=case when HQCO.DefaultCountry='AU' then 6 else 0 end
 From PREA
 Join HQCO on HQCO.HQCo = PREA.PRCo),

/*Calculate the Period for the Month based on the YearOffset*/

PREAMonthPeriodOfYear (PRCo, Mth, PeriodOfYear, YearEndMthOffset)

as

(Select	  PREAMonths.PRCo
	    , PREAMonths.Mth
	    , month(Mth) + (case when month(Mth) > YearEndMthOffset then - YearEndMthOffset else YearEndMthOffset end) as PeriodOfYear
	    , PREAMonths.YearEndMthOffset
From PREAMonths
)

Select    P.PRCo
		, P.Mth
		, Dateadd(m, 12 - P.PeriodOfYear, P.Mth) as YearEndMth /*Find the year end month based on P.Mth*/
		, Dateadd(m,(P.PeriodOfYear-1)*-1,P.Mth) as YearEndBeginMth /*Beginning Mth of Year*/
		/** Divide the period by 3, use Ceiling to get next whole number
		    argugment for Ceiling must be cast as numeric **/
		, Ceiling (Cast (P.PeriodOfYear as numeric)/3) as QuarterOfYear
		, P.PeriodOfYear
		, P.YearEndMthOffset

From PREAMonthPeriodOfYear P



GO
GRANT SELECT ON  [dbo].[vrvPREA_YearEndMonths] TO [public]
GRANT INSERT ON  [dbo].[vrvPREA_YearEndMonths] TO [public]
GRANT DELETE ON  [dbo].[vrvPREA_YearEndMonths] TO [public]
GRANT UPDATE ON  [dbo].[vrvPREA_YearEndMonths] TO [public]
GRANT SELECT ON  [dbo].[vrvPREA_YearEndMonths] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPREA_YearEndMonths] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPREA_YearEndMonths] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPREA_YearEndMonths] TO [Viewpoint]
GO
