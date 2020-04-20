drop view CMSFIL.MCK_RETAILLOCKBOX_AR;

create view CMSFIL.MCK_RETAILLOCKBOX_AR
	as

	select 
		case 
			WHEN AINDC like '%ERVICEALLIAN%' THEN i.AINNO || left(i.ADTIN,2)
			ELSE i.AINNO
		end as InvoiceNumber
	,	sum(i.AAMIN) as InvoiceAmount
	,	i.ACONO as InvoiceCompanyNumber
	,	i.ACUST as InvoiceCustomer
	,	c.CNM25 as InvoiceCustomerName
	,	case
			when i.ASJNO='   ' then i.AJBNO
			else i.AJBNO || '.' || i.ASJNO
		end as JobNumber 
	,	min(CMSFIL.CGC_DATE_CAST(i.ADTIN)) as InvoiceDate
	,	CURDATE() as CurrentDate
	from 
		ARPOPC i left join
		CSTMST c on
			i.ACONO=c.CCONO
		and	i.ADVNO=c.CDVNO
		and	i.ACUST=c.CCUST
	where
		ACONO in (1,15,20,30,50,60)
	and ARCCD=2
	--and CURDATEi.ADTJR
group by
		i.AINNO
	,	i.ACONO
	,	i.ACUST
	,	c.CNM25
	,	case
			when i.ASJNO='   ' then i.AJBNO
			else i.AJBNO || '.' || i.ASJNO
		end
having sum(i.AAMIN) <> 0;

drop view CMSFIL.MCK_RETAILLOCKBOX_AR2;

create view CMSFIL.MCK_RETAILLOCKBOX_AR2
	as

	select 
		case 
			WHEN AINDC like '%ERVICEALLIAN%' THEN cast(i.AINNO as varchar(20)) || left(i.ADTIN,2)
			ELSE cast(i.AINNO as varchar(20))
		end as InvoiceNumber
	,	sum(i.AAMIN) as InvoiceAmount
	,	i.ACONO as InvoiceCompanyNumber
	,	i.ACUST as InvoiceCustomer
	,	c.CNM25 as InvoiceCustomerName
	,	case
			when i.ASJNO='   ' then i.AJBNO
			else i.AJBNO || '.' || i.ASJNO
		end as JobNumber 
	,	min(CMSFIL.CGC_DATE_CAST(i.ADTIN)) as InvoiceDate
	,	CURDATE() as CurrentDate
	from 
		ARPOPC i left join
		CSTMST c on
			i.ACONO=c.CCONO
		and	i.ADVNO=c.CDVNO
		and	i.ACUST=c.CCUST
	where
		ACONO in (1,15,20,30,50,60)
	and ARCCD=2
	--and CURDATEi.ADTJR
group by
		case 
			WHEN AINDC like '%ERVICEALLIAN%' THEN cast(i.AINNO as varchar(20)) || left(i.ADTIN,2)
			ELSE cast(i.AINNO as varchar(20))
		end
	,	i.ACONO
	,	i.ACUST
	,	c.CNM25
	,	case
			when i.ASJNO='   ' then i.AJBNO
			else i.AJBNO || '.' || i.ASJNO
		end
having sum(i.AAMIN) <> 0;