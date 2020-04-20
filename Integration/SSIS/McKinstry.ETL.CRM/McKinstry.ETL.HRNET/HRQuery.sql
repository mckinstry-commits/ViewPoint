
select
	p.REFERENCENUMBER as EmployeeNumber
,	case p.STATUS
		when 'PRE' then 'Pre'
		else coalesce(p.KNOWNAS,p.FIRSTNAME) 
	end as FirstName
,	case p.STATUS
		when 'PRE' then 'Employment'
		else p.LASTNAME 
	end as LastName
,	case p.STATUS
		when 'PRE' then 'Pre-Employment'
		else p.FULLNAME
	end as FullName
,	p.EMAILPRIMARY
,	case p.STATUS
		when 'T' then 'Terminated'
		when 'A' then 'Active'
		when 'PRE' then 'Pre-Employment'
		else p.Status 
	end as EmployeeStatus
,	jd.PERSONALJOBTITLE as JobTitle
,	l.NAME as OfficeLocation
,	case p.PRIMARYUNION 
		when 'MEMBER' then 'TRUE'
		else 'FALSE'
	end as UnionMember
,	p.UNIONLOCATION as JobSite
,	post.TITLE as PositionTitle
,	post.JOBFAMILY as JobFamily
,	c.COMPANYREFNO as CompanyNumber
,	c.COMPANYNAME as CompanyName
,	PARSENAME(ol2.CODE,3) as DepartmentNumber
,	ol2.DESCRIPTION as DepartmentName
,	p.DATEOFJOIN as HireDate
,	p.ORIGINALHIREDATE as OriginalHireDate
,	p.DATEOFLEAVING as TerminationDate
,	jd.EFFECTIVEDATE as JobStartDate
,	jd.ENDDATE as JobEndDate
,	post.EXEMPTSTATUS as ExemptStatus
,	eeocode.DISPLAYVALUE as EEOJobCategory
,	mgr.REFERENCENUMBER as MgrEmployeeNumber
,	case mgr.STATUS
		when 'PRE' then 'Pre'
		else coalesce(mgr.KNOWNAS,mgr.FIRSTNAME) 
	end as MgrFirstName
,	case mgr.STATUS
		when 'PRE' then 'Employment'
		else mgr.LASTNAME 
	end as MgrLastName
,	case mgr.STATUS
		when 'PRE' then 'Pre-Employment'
		else mgr.FULLNAME
	end as MgrFullName
,	case mgr.STATUS
		when 'T' then 'Terminated'
		when 'A' then 'Active'
		when 'PRE' then 'Pre-Employment'
		else mgr.Status 
	end as MgrEmployeeStatus
,	p.DATEOFBIRTH
from
	PEOPLE p left outer join
	JOBDETAIL jd on
		jd.PEOPLE_ID=p.PEOPLE_ID left outer join
	LOCATION l on 
		jd.LOCATION=l.LOCATION_ID left outer join
	POST post on
		jd.JOBTITLE=post.POST_ID left outer join
	ORGLEVEL2 ol2 on
		jd.ORGLEVEL2=ol2.ORGLEVEL2_ID left outer join
	COMPANY c on
		jd.COMPANY=c.COMPANY_ID left outer join
	PEOPLE mgr on
		p.REPORTSTO=mgr.PEOPLE_ID left outer join
	OC_PICKLISTVALUES eeocode on
		post.EEOJOBCATEGORIES=eeocode.STOREVALUE
	and eeocode.CULTURECODE='en-US'
	and eeocode.PICKLISTID='718E77D1-3107-4B30-B5ED-7B5B6168F2B5' /* From OC_PICKLISTLANGUAGES */  
where
--	jd.TOPJOB='T'
	jd.CURRENTRECORD='YES'
and c.COMPANYREFNO <> '90'
--and	mgrjd.TOPJOB='T'
--and p.STATUS<>'T'
--and	p.STATUS='PRE'
order by
	p.REFERENCENUMBER

