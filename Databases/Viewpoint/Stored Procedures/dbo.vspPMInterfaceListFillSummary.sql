SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[vspPMInterfaceListFillSummary]
/*************************************
* CREATED BY:	TRL 04/19/2011 TK-04412
* MODIFIED By:	GF 05/21/2011 TK-05347
*				TRL 08/22/2011 TK-07623, added code so POCO won't show until original is interfaced
*				GF 09/29/2011 TK-08778 modified exists for POCO ready to interface
*				GPT 12/05/2011 TK-10543 Fill the ACO column for SCO/POCO. 
*				GF 12/12/2011 TK-10926 145249 check POIT for original item for POCO
*				GF 12/20/2011 TK-11086 144955 use an outer apply for SCO/POCO Amount to avoid cartesian
*				GF 01/30/2012 TK-10927 145248 change where clause for POCO to show in list
*				GF 03/08/2012 TK-13086 145859 change join for SCO - Subcontract Change Order - POCO also
*				GF 04/25/2012 TK-14423 146347 change to original subcontract list to show pending subct change orders
*				GP 07/25/2012 TK-16567 146688 changed the original subcontract list to only show type C when header status is pending
*				GF 10/09/2012 TK-18382 147184 display pending POCO for interface if approved
*
*
* USAGE:
* summary list of ACO's, PO's, SL's, MO's and MS Quotes's that are ready to be interfaced
*
* Pass in :
*	PMCo, Project, INCo (used for Material Orders)
*
* Output
*  Returns summary list to be used in 5 columns
*
* Returns
*	Error message and return code
*
*******************************/
(@PMCo bCompany, @Project bJob, @InterfaceType varchar(1), @errmsg varchar(255) output)
as
set nocount on

declare @rcode INT, @INCo bCompany

SET @rcode = 0
SET @INCo = @PMCo

---- must have company
If @PMCo is null
	BEGIN
	select @errmsg = 'Missing PM Company', @rcode=1
	goto vspexit
	END

---- must have project
If @Project IS null
	BEGIN
	select @errmsg = 'Missing PM Project', @rcode=1
	goto vspexit
	END

---- create interface items summary table
Create table  #InterfaceItemsSummary
(
	Interface varchar(30),
	ID varchar(30),
	CO int,
	ACO varchar(30),
	[Description] varchar (120),
	Amount decimal(16,2),
	InterfaceErrors VARCHAR(MAX)
)


---- Pending Projects that can be interfaced - if pending must be sent first
---- before anything else can be done
IF EXISTS(SELECT 1 FROM dbo.JCJM j WHERE j.JCCo=@PMCo and j.Job=IsNull(@Project,j.Job) and j.JobStatus = 0)
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, [Description])
	select 'Project Pending', 'Contract and Original Estimates'
	FROM dbo.JCJM j
	Where j.JCCo=@PMCo and j.Job = @Project and j.JobStatus = 0 
	Group by j.JCCo, j.Job
	---- we are done jump to result set list
	GOTO List_Resultset
	END



---- List Project updates or additions to open projects
---- must be open job or allow posting to soft/hard closed jobs is allowed in JC Company.
Insert into #InterfaceItemsSummary (Interface, [Description])
select 'Project Update', 'Contract and Cost Estimate updates'
From dbo.JCJM j 
INNER JOIN dbo.JCCO c on c.JCCo=j.JCCo
WHERE j.JCCo=@PMCo AND j.Job = @Project
	AND EXISTS(SELECT 1 FROM dbo.JCCH WHERE JCCo=@PMCo AND Job=@Project AND SourceStatus = 'Y')
	AND (j.JobStatus = 1
	 OR (j.JobStatus = 2 AND c.PostSoftClosedJobs = 'Y')
	 OR (j.JobStatus = 3 AND c.PostClosedJobs = 'Y'))
GROUP BY j.Job
		
				
---- Approved change orders to be interfaced interface types 1,2
IF @InterfaceType IN ('1','2')
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, ACO, [Description], Amount)
	select 'Approved Change Order', h.ACO, h.[Description], ISNULL(t.ACORevTotal,0)
	FROM dbo.PMOH h
	INNER JOIN dbo.PMOHTotals t ON t.PMCo = h.PMCo AND t.Project = h.Project AND t.ACO = h.ACO
	where h.PMCo=@PMCo AND h.Project = @Project
	AND h.ACO is not null 
	AND h.ReadyForAcctg = 'Y'
	group by h.ACO, h.[Description], t.ACORevTotal
	END


/***  START Purchase Orders   ***/
--Purchase Orders Originals interface types 1,3
IF @InterfaceType IN ('1','3')
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, ID, [Description], Amount)
	select 'Purchase Order - Original', a.PO, b.[Description], sum(IsNull(a.Amount,0))
	from dbo.PMMF a 
	INNER JOIN dbo.PMCO c on a.PMCo=c.PMCo
	INNER JOIN dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
	where a.PMCo=@PMCo and a.Project = @Project
	AND a.PO is not null AND a.POItem is not NULL
	AND a.SendFlag = 'Y' 
	AND a.MaterialOption = 'P'
	AND a.InterfaceDate is NULL
	AND a.POCONum IS NULL
	AND c.POInUse = 'Y'
	AND ISNULL(b.Approved, 'Y') = 'Y'
	----TK-18382
	AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND b.[Status] = 3))
	--AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND a.ACO IS NOT NULL))
	GROUP BY a.PO, b.[Description]
	END
	
	
--Purchase Order Change Orders interface types 1,4
IF @InterfaceType In ('1','4')
	BEGIN
	with ctePMMF_ACODesc (PMCo, Project, POCo, PO, POCONum, ACODesc) AS
	(
		SELECT PMCo, Project, POCo, PO, POCONum, CASE WHEN (COUNT(*) > 1) THEN MAX('Multiple') ELSE MAX(ACO) END as ACODesc 
			FROM (
			    SELECT DISTINCT PMCo, Project, POCo, PO, POCONum, ACO 
				FROM dbo.PMMF 
				WHERE PO IS NOT NULL AND POItem IS NOT NULL AND POCONum IS NOT NULL
					AND SendFlag='Y' AND InterfaceDate IS NULL 
					AND MaterialOption='P'
				GROUP BY PMCo, Project, POCo, PO, POCONum, ACO 
				) g
		GROUP BY PMCo, Project, POCo, PO, POCONum
	)
	Insert into #InterfaceItemsSummary (Interface, ID, CO, [Description], Amount, ACO)
	select 'Purchase Order CO',a.PO, a.POCONum, b.[Description], t.PMMFAmtCurrent, ad.ACODesc
	from dbo.PMMF a 
	inner join ctePMMF_ACODesc ad on ad.PMCo=a.PMCo and ad.Project=a.Project and ad.POCo=a.POCo and ad.PO=a.PO and ad.POCONum = a.POCONum
	inner join dbo.PMCO c on a.PMCo=c.PMCo
	inner Join dbo.POHD b on b.POCo=a.POCo and b.PO=a.PO
	----TK-13086 PMCo, Project not needed
	INNER JOIN dbo.PMPOCO o on o.POCo=a.POCo and o.PO=a.PO and o.POCONum = a.POCONum ----o.PMCo=a.PMCo and o.Project=a.Project and 
	----TK-11086
	OUTER APPLY (SELECT CAST(ISNULL(SUM(pmmf.Amount),0) + 
					CASE WHEN pmmf.TaxCode IS NULL THEN 0
						 WHEN pmmf.TaxType IN (2,3) THEN 0
					ELSE ISNULL(ROUND(ISNULL(SUM(pmmf.Amount), 0) * ISNULL(dbo.vfHQTaxRate(pmmf.TaxGroup, pmmf.TaxCode, GetDate()),0),2),0)
					END AS NUMERIC(18,2)) AS PMMFAmtCurrent
				FROM dbo.PMMF pmmf
				WHERE pmmf.POCo = a.POCo AND pmmf.PO=a.PO AND pmmf.POCONum=a.POCONum
			GROUP BY pmmf.Amount,
					 pmmf.TaxGroup,
					 pmmf.TaxCode,
					 pmmf.TaxType	
							) t
	----END TK-11086
	where a.PMCo=@PMCo and a.Project = @Project
	AND a.PO is not NULL AND a.POItem is not NULL
	AND a.POCONum IS NOT NULL
	AND o.ReadyForAcctg = 'Y'
	AND c.POInUse = 'Y'
	AND a.SendFlag='Y' 
	AND a.MaterialOption='P'
	AND a.InterfaceDate is NULL
	AND ISNULL(b.Approved, 'Y') = 'Y'
	----TK-10927 TK-18382
	----AND (a.PCO IS NULL OR a.ACO IS NOT NULL)	
	GROUP BY a.PO, o.POCONum, b.[Description], a.POCONum, t.PMMFAmtCurrent, ad.ACODesc
	END
/***  END Purchase Orders   ***/


/***  START Subcontracts  ***/
--Subcontract Original - interface types 1, 5
IF @InterfaceType IN ('1','5')
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, ID, [Description], Amount)
	select 'Subcontract - Original', a.SL, s.[Description], sum(IsNull(a.Amount,0))
	from dbo.PMSL a with (nolock) 
	INNER JOIN dbo.PMCO c on c.PMCo=a.PMCo and c.APCo=a.SLCo
	INNER JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
	where a.PMCo=@PMCo and a.Project = @Project
	AND a.SL is not NULL AND a.SLItem is not NULL
	AND ISNULL(s.Approved,'Y') = 'Y'
	AND c.SLInUse = 'Y'
	AND a.SendFlag = 'Y'
	AND a.SubCO IS NULL
	AND a.InterfaceDate IS NULL
	----TK-14423
	AND (a.RecordType = 'O' OR (a.RecordType = 'C' AND s.[Status] = 3))
	group by a.SL, s.[Description]
	END
		
----Subcontract Changes - interface types 1, 6
IF @InterfaceType In ('1','6')
	BEGIN
	with ctePMSL_ACODesc (PMCo, Project, SLCo, SL, SubCO, ACODesc) AS
	(
		SELECT PMCo, Project, SLCo, SL, SubCO, CASE WHEN (COUNT(*) > 1) THEN MAX('Multiple') ELSE MAX(ACO) END as ACODesc 
			FROM (
			    SELECT DISTINCT PMCo, Project, SLCo, SL, SubCO, ACO 
				FROM dbo.PMSL 
				WHERE SL IS NOT NULL AND SLItem IS NOT NULL AND SubCO IS NOT Null 
					AND SendFlag='Y' AND InterfaceDate IS NULL 
				GROUP BY PMCo, Project, SLCo, SL, SubCO, ACO 
				) g
		GROUP BY PMCo, Project, SLCo, SL, SubCO
	)
	Insert into #InterfaceItemsSummary (Interface, ID, CO, [Description], Amount, ACO)
	select 'Subcontract CO',a.SL, a.SubCO, s.[Description], t.PMSLAmtCurrent, ad.ACODesc
	from dbo.PMSL a 
	INNER JOIN ctePMSL_ACODesc ad on ad.PMCo=a.PMCo and ad.Project=a.Project and ad.SLCo=a.SLCo and ad.SL=a.SL and ad.SubCO = a.SubCO
	INNER join dbo.PMCO c on c.PMCo=a.PMCo and c.APCo=a.SLCo
	INNER JOIN dbo.SLHD s on s.SLCo=a.SLCo and s.SL=a.SL
	----TK-13086 PMCo, Project not needed
	INNER JOIN dbo.PMSubcontractCO o on o.SLCo=a.SLCo and o.SL=a.SL and o.SubCO = a.SubCO ----o.PMCo=a.PMCo and o.Project=a.Project and 
	----TK-11086
	OUTER APPLY (SELECT CAST(ISNULL(SUM(pmsl.Amount),0) + 
					CASE WHEN pmsl.TaxCode IS NULL THEN 0
						 WHEN pmsl.TaxType IN (2,3) THEN 0
					ELSE ISNULL(ROUND(ISNULL(SUM(pmsl.Amount), 0) * ISNULL(dbo.vfHQTaxRate(pmsl.TaxGroup, pmsl.TaxCode, GetDate()),0),2),0)
					END AS NUMERIC(18,2)) AS PMSLAmtCurrent
				FROM dbo.PMSL pmsl
				WHERE pmsl.SLCo = a.SLCo AND pmsl.SL=a.SL AND pmsl.SubCO=a.SubCO
			GROUP BY pmsl.Amount,
					 pmsl.TaxGroup,
					 pmsl.TaxCode,
					 pmsl.TaxType	
							) t
	----END TK-11086
	WHERE a.PMCo=@PMCo AND a.Project = @Project
	AND a.SL is not NULL AND a.SLItem is not NULL
	AND a.SubCO is NOT Null 
	AND a.SendFlag='Y' 
	AND a.InterfaceDate is null 
	and c.SLInUse='Y' 
	AND o.ReadyForAcctg = 'Y' 
	AND ISNULL(s.Approved,'Y') = 'Y'
	----AND (a.RecordType ='O' OR (a.ACO IS NOT null AND a.RecordType = 'C'))
	group by a.SL, s.[Description], a.SubCO, t.PMSLAmtCurrent, ad.ACODesc
	END
	
	
---- Material Orders - Interface Types (1,7)
IF @InterfaceType In ('1','7')
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, ID, [Description] , Amount)
	select 'Material Order', a.MO, b.[Description], sum(IsNull(a.Amount,0))
	from dbo.PMMF a
	INNER JOIN dbo.PMCO c ON c.PMCo=a.PMCo
	INNER JOIN dbo.INMO b on b.INCo=a.INCo and b.MO=a.MO
	where a.PMCo=@PMCo and a.Project = @Project
	AND a.MO IS NOT NULL AND a.MOItem IS NOT NULL
	AND a.INCo = @INCo
	----AND a.RecordType = 'O'
	AND a.SendFlag = 'Y'
	AND a.MaterialOption = 'M'
	AND a.InterfaceDate IS NULL
	AND c.INInUse = 'Y'
	AND ISNULL(b.Approved,'Y') = 'Y'
	group by a.INCo, a.MO, b.[Description]
	END


---- Material Quotes - Interface Types (1,8)
IF @InterfaceType In ('1','8')
	BEGIN
	Insert into #InterfaceItemsSummary (Interface, ID, [Description] ,Amount)
	select'Quote', a.Quote, b.[Description], sum(IsNull(a.Amount,0))
	from dbo.PMMF a
	INNER JOIN dbo.PMCO c ON c.PMCo=a.PMCo
	INNER JOIN dbo.MSQH b on b.MSCo=a.MSCo and b.Quote=a.Quote
	where a.PMCo=@PMCo and a.Project = @Project 
	AND a.Quote is not null AND a.Location is not NULL
	AND a.MSCo = @INCo
	----AND a.RecordType = 'O'
	AND a.SendFlag = 'Y'
	AND a.MaterialOption='Q' 
	AND a.InterfaceDate is NULL
	AND c.MSInUse = 'Y'
	GROUP BY a.Quote, b.[Description]
	END
	
	
	



List_Resultset:
--All
If @InterfaceType = '1'
begin
	select Interface, IsNull(ID,ACO) as [ID], [Description],
			CO as [CO Number],
			case when Interface = 'Approved Change Order' then ID else ACO end as [ACO],
			Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description],CO,ACO, InterfaceErrors
	Order by Interface asc, ID, CO, ACO
end
--Approved Change Orders
If @InterfaceType = '2'
	begin
	select Interface,ACO,[Description],Sum(Amount)as [Amount],
				InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ACO,[Description], InterfaceErrors
	Order by ACO, Interface asc
	END
	
--Purchase Orders Original
If @InterfaceType In ('3')
begin
	select Interface,ID as [PO],[Description],Sum(Amount)as [Amount],
				InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--Purchase Order Change Orders
If @InterfaceType In ('4')
begin
	select Interface,ID as [PO],[Description], CO as [CO Number],
			ACO, Sum(Amount)as [Amount], 
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,CO,[Description], ACO, InterfaceErrors
	Order by ID, CO
END

--Subcontracts Original
If @InterfaceType in ('5')
begin
	select Interface,ID as [Subcontract],[Description],Sum(Amount)as [Amount],
	InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--Subcontract CO's
If @InterfaceType in ('6')
begin
	select Interface,ID as [Subcontract],[Description],CO as [CO Number],
			ACO, Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,CO,[Description],ACO , InterfaceErrors
	Order by ID, CO
END

--Material Orders
If @InterfaceType = '7'
begin
	select Interface,ID as [Matl Order],[Description],Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
END

--MS Quotes
If @InterfaceType = '8'
begin
	select Interface,ID as [Quote],[Description],Sum(Amount)as [Amount],
			InterfaceErrors as [Interface Error] 
	from #InterfaceItemsSummary  
	Group by Interface,ID,[Description], InterfaceErrors
	Order by ID
end
	
vspexit:
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceListFillSummary] TO [public]
GO
