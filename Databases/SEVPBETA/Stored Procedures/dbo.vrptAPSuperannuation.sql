SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*==================================================================================      
      
Author:
Scott Alvey    
     
Create date:
04/04/2012

Originating V1 reference:
Epic: B-07008 - Ability to Add on Burden to Vendors
Child: B-08295 & B-09269 - Add AP data to PR Superannuation report
      
Usage:   
This proc drives the AP Superannuation subreport of the PR Superannuation report.
It looks to APTH, APTL, and APTD to get payment data for payments made during the
On-Cost payment proces. Joins to APVM and HQCO are made as well to get some name
information for the vendor and company.

Things to keep in mind regarding this report and proc: 
These notes will not go into the full detail of the On-Cost payment process as the
help section regarding this process in Viewpoint will be much more in depth. A 
summary of the process is that when I pay a vendor for work done (parent vendor) I may
need to pay, on behalf of that vendor, dollars to a superannuation vendor (child vendor)
that manages the various superannuation plans for that parent vendor. The payment details
for both the parent and child vendors are all stored in the APTH\APTL\APTD record family
as at the end of the day both types of payments (parent and child) are just invoice 
payments. That is really key in understanding this whole process, these are just invoice
payments and records. Some records will have values in the 'oc' prended fields in APTL, 
and these are the payements made to the child vendor. The data in the 'oc' fields point to
what the parent was of that child record, who were the payments made on behalf of.

The report will have a pair of dollar amount columns, current and Year To Date (YTD).
And just like the PR side to the PR Superannuation report the data returned here needs
to support the ability to hide or show details.

The difference between the current and YTD dollar amounts really pivots around the 
@BegPaidDate and @EndPaidDate parameters. The biggest thing to keep in mind here is 
that the current dollar amount is the sum, per vendor\scheme group, of the amount paid
the child vendor in the date range provided. The TYD dollar amount is the sum, per 
vendor\scheme group, of the amount paid to the child vendor from the start of the tax
year through to the date specified in @EndPaidDate. So if uses a starting and ending paid
date range of 01/03/2012 to 31/03/2012 then the current dollar amount column would just hold
the sum of the payments made in the date range while the YTD column would hold that amount
PLUS the amount paid to the vendor from the start of the tax year UP TO the day before the 
@BegPaidDate value. Example (Beg and End Paid date are 01/03/2012 to 30/03/2012:

records

vendor	paid date	amount
1		15/01/2012	50.00
1		25/01/2012	100.00
1		15/02/2012	100.00
1		01/03/2012	50.00
1		10/03/2012	50.00
1		30/03/2012	100.00

using the above record set the report would return a current column value of 200.00 and 
a YTD column (assuming the start of the tax year is 01/07/2011) of 450.00. 

Because the report gives users the option to show the details, the report will show the details
of all the 'current' records when that option is choses and the first record of the details
will have current column be truly that, but the YTD column will be a combination of that first
'current' detail record dollar about PLUS a single sum of all the amounts paid before that date 
starting from the current tax year date.

With all that said, in the final select statement there are two selection parts. The first is 
the selection of the 'curren't records and then the second part unioned is the selection of 
the 'YTD' records. YTD records will just be one line per vendor with a sum of the amount paid.

Performance testing:
Ran exec vrptAPSuperannuation against 7 internal databases on a 10 yr date range in the 
proc date range params.

unfilterd APTL record count		executed proc time in seconds		returned records
354809							36									390411
238862							05									242138
1000810							43									1115935
1706996							30									1753130
14287							01									14732							
216248							06									215214
178117							04									189620

Ran exec vrptAPSuperannuation against top 3 from above on a 1 yr date range in the proc 
date range params.

unfilterd APTL record count		executed proc time in seconds		returned records
354809							07									13300
1000810							05									26271
1706996							05									51352

Parameters:
@APCompany		- AP Company to fileter on
@BegPaidDate	- The starting date for payment details
@EndPaidDate	- The ending date for the payment details
@Vendor			- Vendor to filter on or if = 0 then show all vendors

Related reports:   
PR Superannuaton report (1124) 
      
Revision History      
Date  Author  Issue     Description
   
==================================================================================*/ 
 
CREATE PROCEDURE	[dbo].[vrptAPSuperannuation]
(		 
	 @APCompany		bCompany
	,@BegPaidDate	bDate
	,@EndPaidDate	bDate
	,@Vendor		bVendor
)

AS

/*
	Need to keep in mind that the AUS tax year starts on 7/1 and crosses over into
	the next calendar year to end on 6/30. So this @BeginTaxYear variable is introduced
	to capture the correct start of the tax year date so that later on we can
	grab YTD information.
*/

DECLARE @BeginTaxYear bDate
	IF DATEPART (mm,@BegPaidDate) > 6
		SET @BeginTaxYear = Cast('07/01/' + CAST(DATEPART (yyyy,@BegPaidDate) as char(4)) as datetime)
	ELSE
		SET @BeginTaxYear = Cast('07/01/' + CAST((DATEPART (yyyy,@BegPaidDate) -1) as char(4)) as datetime)

/*
	The @BegVendor and @EndVendor variables are used by the code below to define
	what vendors we will be filtered on. We will look to the proc parameter of @Vendor
	and if @Vendor = 0 than this means we do not want to filter on a specific vendor. So
	The related variables are set to the extreems of the datatype value. If @Vendor <> 0 
	then there IS a specific vendor to filter on. The variables are both set to the same value.
	We do a range here so that we do not have to introduce an case\when\end statement in the 
	where clause which could be more of a performance impact then desired.
*/

DECLARE @BegVendor		bVendor	
DECLARE @EndVendor		bVendor	

If @Vendor = 0  
	BEGIN
		SET	@BegVendor = 0
		SET	@EndVendor = 99999999
	END
ELSE
	BEGIN
		SET	@BegVendor = @Vendor
		SET	@EndVendor = @Vendor
	END;
	
WITH

/*
	Because the report shows both current and YTD columns, the report can technically bring 
	back On-Cost Vendors that were paid outside of the range of the paid date parameters 
	(@BegPaidDate and @EndPaidDate) when those outside vendors where paid between the @BegPaiddate 
	and @BeginTaxYear. I think these outside vendors should be ommitted from the report as
	the user most likely, when giving a paid date range, wants ONLY vendors that were paid
	in that range PLUS what ever THOSE vendors were paid from the start of the tax year so that
	the YTD column is correct. This means the report should never see vendors that only have 'ytd'
	RecType values and no corresponding 'cur' RecType values. 
	
	This CTE is joined into the final data call on both sides of the union, not just the North.
*/

APSuperannuationVendorFilter 
(      
	  APCo
	, VendorGroup
    , Vendor
)

as

(
	select
		h.APCo
		, h.VendorGroup
		, h.Vendor
	from
		APTH h 
	join
		APTL l on
			l.APCo = h.APCo
			and l.Mth = h.Mth
			and l.APTrans = h.APTrans
	join
		APTD d on 
			d.APCo = l.APCo
			and d.Mth = l.Mth
			and d.APTrans = l.APTrans
			and d.APLine = l.APLine
	where
		h.APCo = @APCompany
		and h.Vendor between @BegVendor and @EndVendor
		and d.PaidDate between @BegPaidDate and @EndPaidDate
		and l.ocApplyTrans is not null
	group by
		h.APCo
		, h.VendorGroup
		, h.Vendor 
),

/*
	Even though there are two aspects of dollar amount data in this related report, current
	and YTD, we can pull the data from a common CTE. The selection below will only return
	data for the dates between the start of the tax year and the ending paid date range
	value specificed by the user in the @EndPaidDate. Plus since we are filtering on AP
	Company and Vendor as well, we will not have filter on those fields in the final data
	call. Later on when we use the CTE we will create two subsets of this returned data. The
	first will be 'current' in that it will contain detail records for all payments made in 
	between the @BegPaidDate and @EndPaidDate parameters. The second will be 'year to date' and will
	really just be a sum on each vendor of the amount paid prior to the detail records. For a more
	in-depth description of the difference between current and YTD in this proc, see the notes
	section at the start of this proc up above.
	
	Finally a word about using the between operator in the where clause. The SQL execution plan will treat
	the between operator the same as (>= and <=). So either type of filter could be used, but it just looks
	a bit cleaner using between. Your call if you want to change it.
*/

APSuperannuationDetail 

(      
	  APCo
	, CompanyName
    , ocVendorGroup
    , ocVendor
    , ocName
    , ocSortName
--  , applyVendor
--  , applyName
--  , applySortName
    , applyMth
    , applyTrans
    , applyLine
    , PaidDate
    , PaidMth
    , Amount
    , ATOCategory
    , ocSchemeID
    , ocMembershipNbr
    , SchemeName
    , SchemeNameSort    
)

as

(
	select
		och.APCo
		, c.Name
		, och.VendorGroup
		, och.Vendor
		, ocm.Name
		, ocm.SortName
--		, applyh.Vendor
--		, applym.Name
--		, applym.SortName
		, ocl.ocApplyMth
		, ocl.ocApplyTrans
		, ocl.ocApplyLine
		, ocd.PaidDate
		, ocd.PaidMth
		, ocd.Amount
		, ocl.ATOCategory
		, ocl.ocSchemeID
		, ocl.ocMembershipNbr
		,scheme.Name  
		,UPPER(scheme.Name)
	from 
		APTL ocl
	join 
		APTH och on
			ocl.APCo = och.APCo
			and ocl.Mth = och.Mth
			and ocl.APTrans = och.APTrans
	join
		APTD ocd on 
			ocl.APCo = ocd.APCo
			and ocl.Mth = ocd.Mth
			and ocl.APTrans = ocd.APTrans
			and ocl.APLine = ocd.APLine
	join
		APVM ocm on
			och.VendorGroup = ocm.VendorGroup
			and och.Vendor = ocm.Vendor
			
/************************************************************************************************
	As of writing this code the specs requires just the On-Cost Vendor information, who are the
	vendors that received supperanuation dollars on behalf of the vendor that actually did the work.
	Since the payment records for the supperannuation vendors will always have a value in their 
	APTL.ocApplyTrans fields we can know that if that field is not null than it is a superannuation
	payment. I did leave code in here (commented out) that will bring in the vendor that was
	paid on behave of for future use if needed. But keep in mind that because we only need
	On-Cost vendors at this point in time we don't have to worry about linking APTL.oc fields back to
	their parent payment. 

--	join
--		APTL applyl on
--			ocl.APCo = applyl.APCo
--			and ocl.ocApplyMth = applyl.Mth
--			and ocl.ocApplyTrans = applyl.APTrans
--			and ocl.ocApplyLine = applyl.APLine
--	join
--		APTH applyh on
--			applyh.APCo = applyl.APCo
--			and applyh.Mth = applyl.Mth
--			and applyh.APTrans = applyl.APTrans
--	join
--		APVM applym on
--			applyh.VendorGroup = applym.VendorGroup
--			and applyh.Vendor = applym.Vendor

************************************************************************************************/

	join
		HQCO c on 
			och.APCo = c.HQCo
	join
		HQAUSuperSchemes scheme on
			scheme.SchemeID = ocl.ocSchemeID  
	where
		och.APCo = @APCompany
		and och.Vendor between @BegVendor and @EndVendor
		and ocd.PaidDate between @BeginTaxYear and @EndPaidDate
		and ocl.ocApplyTrans is not null
)

/*
	Want to see how we are doing so far? Then uncomment the select * statment
	just below, flip to alter, and go go go! Keep in mind that turning this
	select statement on and then attempting to run the report most likely will 
	cause the report to scream bloody murder
*/

--select * from APSuperannuationDetail

/*
	Final select
	I defined in the top notes section how we are using these two select statements but
	for those who replied with 'TLDR' here is the short of those notes. First select 
	gets detail records of payments that fall with in the date range specified in the 
	@BegPaidDate and @EndPaidDate parameters. Second select sums the paid amount on the 
	Vendor for all payments made from the start of the current tax year to the day BEFORE
	the value of @BegPaidDate. The report will then show the detail record dollar amounts
	in one column and the sum of those detail record dollar amounts PLUS the dollars from
	the second select in a YTD column. If you need a better understanding of all of this
	please read the notes at the start of this proc. 
	
*/

Select
	'cur' as RecType
	, cur.*
From
	APSuperannuationDetail cur
join
	APSuperannuationVendorFilter filter on
		cur.APCo = filter.APCo
		and cur.ocVendorGroup = filter.VendorGroup
		and cur.ocVendor = filter.Vendor
Where
	cur.PaidDate between @BegPaidDate and @EndPaidDate
	
union all

Select
	'ytd' as RecType
	, ytdate.APCo
	, max(ytdate.CompanyName)
	, 0
	, ytdate.ocVendor
	, max(ytdate.ocName)
	, max(ytdate.ocSortName)
	
/************************************************************************************************	
	The three commented out fields in the second select are there as a reminder so that if
	you add to the report the apply vendor info (commented apply fields in the CTE) you 
	do not forget to add them to the second select as well, since the first select is just
	really a select *.
	
--	, 0 
--	, ''
--	, ''

************************************************************************************************/

	, '01/01/1950'
	, 0
	, 0
	, '01/01/1950'
	, '01/01/1950'
	, sum(ytdate.Amount)
	, ytdate.ATOCategory
	, ytdate.ocSchemeID
	, ytdate.ocMembershipNbr
	, max(ytdate.SchemeName)
	, max(ytdate.SchemeNameSort)
From
	APSuperannuationDetail ytdate
join
	APSuperannuationVendorFilter filter on
		ytdate.APCo = filter.APCo
		and ytdate.ocVendorGroup = filter.VendorGroup
		and ytdate.ocVendor = filter.Vendor
Where
	ytdate.PaidDate >= @BeginTaxYear 
	and ytdate.PaidDate < @BegPaidDate
Group by
	ytdate.APCo
	, ytdate.ocVendor
	, ytdate.ATOCategory
	, ytdate.ocSchemeID
	, ytdate.ocMembershipNbr
GO
GRANT EXECUTE ON  [dbo].[vrptAPSuperannuation] TO [public]
GO
