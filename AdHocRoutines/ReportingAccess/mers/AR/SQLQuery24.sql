select * from COMPANY

select
	jd.PEOPLE_ID
,	p.FULLNAME
,	jd.JOBTITLE
,	c.COMPANY
,	c.COMPANYREFNO
from 
	PEOPLE p
join JOBDETAIL jd on
	p.PEOPLE_ID=jd.PEOPLE_ID
join COMPANY c on
	jd.COMPANY=c.COMPANY_ID
where
	p.LASTNAME='Orebaugh'
