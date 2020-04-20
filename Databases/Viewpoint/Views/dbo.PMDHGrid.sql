SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
 * Created By:	GF 10/17/2006 6.x only
 * Modfied By:	GF 04/11/2011 TK-04056
 *				GP 09/18/2012 - TK-17982 Added doc category SBMTL
 *
 * Provides a view of PM Document History joining to 
 * appropiate document view to get document description
 *
 *****************************************/
 
CREATE  view [dbo].[PMDHGrid] as
select a.*,
	'DocDesc' = case when a.DocCategory='TRANSMIT' then (select b.Subject from dbo.PMTM b with (nolock)
						where b.PMCo=a.PMCo and b.Project=a.Project and b.Transmittal=a.Document)

				when a.DocCategory='RFI' then (select c.Subject from dbo.PMRI c with (nolock)
						where c.PMCo=a.PMCo and c.Project=a.Project and c.RFIType=a.DocType and c.RFI=a.Document)

				when a.DocCategory='SUBMIT' then (select d.Description from dbo.PMSM d with (nolock)
						where d.PMCo=a.PMCo and d.Project=a.Project and d.SubmittalType=a.DocType and d.Submittal=a.Document and d.Rev=a.Rev)

				when a.DocCategory='DRAWING' then (select e.Description from dbo.PMDG e with (nolock)
						where e.PMCo=a.PMCo and e.Project=a.Project and e.DrawingType=a.DocType and e.Drawing=a.Document)

				when a.DocCategory='PCO' then (select g.Description from dbo.PMOP g with (nolock)
						where g.PMCo=a.PMCo and g.Project=a.Project and g.PCOType=a.DocType and g.PCO=a.Document)

				when a.DocCategory='PUNCH' then (select h.Description from dbo.PMPU h with (nolock)
						where h.PMCo=a.PMCo and h.Project=a.Project and h.PunchList=a.Document)

				when a.DocCategory='INSPECT' then (select i.Description from dbo.PMIL i with (nolock)
						where i.PMCo=a.PMCo and i.Project=a.Project and i.InspectionType=a.DocType and i.InspectionCode=a.Document)

				when a.DocCategory='OTHER' then (select j.Description from dbo.PMOD j with (nolock)
						where j.PMCo=a.PMCo and j.Project=a.Project and j.DocType=a.DocType and j.Document=a.Document)

				when a.DocCategory='TEST' then (select k.Description from dbo.PMTL k with (nolock)
						where k.PMCo=a.PMCo and k.Project=a.Project and k.TestType=a.DocType and k.TestCode=a.Document)

				when a.DocCategory='RFQ' then (select l.Description from dbo.PMRQ l with (nolock)
						where l.PMCo=a.PMCo and l.Project=a.Project and l.PCOType=a.DocType and l.PCO=a.RFQPCO and l.RFQ=a.Document)

				when a.DocCategory='ACO' then (select m.Description from dbo.PMOH m with (nolock)
						where m.PMCo=a.PMCo and m.Project=a.Project and m.ACO=a.Document)
						
				----TK-04056
				WHEN a.DocCategory='SUBCO' THEN (SELECT n.Description FROM dbo.PMSubcontractCO n WITH (NOLOCK)
						WHERE n.PMCo=a.PMCo and n.SLCo=a.SLCo and n.SL=a.SL and n.SubCO=a.SubCO)

				----TK-04056
				WHEN a.DocCategory='PURCHASECO' THEN (SELECT o.Description FROM dbo.PMPOCO o WITH (NOLOCK)
						WHERE o.PMCo=a.PMCo and o.POCo=a.POCo and o.PO=a.PO and o.POCONum=a.POCONum)
						
				WHEN a.DocCategory='SBMTL' THEN 
					(SELECT p.[Description] 
					 FROM dbo.PMSubmittal p
					 WHERE p.PMCo=a.PMCo AND p.Project=a.Project AND ISNULL(p.Seq,-1)=a.SubmittalRegisterSeq)		

				else '' end



From dbo.PMDH a


GO
GRANT SELECT ON  [dbo].[PMDHGrid] TO [public]
GRANT INSERT ON  [dbo].[PMDHGrid] TO [public]
GRANT DELETE ON  [dbo].[PMDHGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMDHGrid] TO [public]
GO
