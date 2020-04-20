SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMEntityExt] AS 

	Select
		e.*,
		case 
			when smwoq.DateApproved is not null then 'Y'
			when (sma.DateActivated is not null or sma.DateCancelled is not null or sma.DateTerminated is not null or sma.EffectiveDate > GetDate()) then 'Y'
			when smwos.SMCo is not null then 'Y'
			else 'N'
		end as Locked,
		coalesce(smwoq.ServiceSite, /*smas.ServiceSite,*/ smwo.ServiceSite) as EntityServiceSite
	From
		SMEntity e
	Left Outer Join
		SMWorkOrderQuote smwoq on
			smwoq.SMCo = e.SMCo
			and smwoq.WorkOrderQuote = e.WorkOrderQuote
			and e.Type in (10,11)
	Left Outer Join
		SMAgreement sma on
			sma.SMCo = e.SMCo
			and sma.Agreement = e.Agreement
			and sma.Revision = e.AgreementRevision
			and e.Type in (8,9)
	--Left Outer Join --removed for now until we know how to deal with multiple servie sites per a single agreement/rev combo
	--	SMAgreementService smas on
	--		smas.SMCo = sma.SMCo
	--		and smas.Agreement = sma.Agreement
	--		and smas.Revision = sma.Revision
	Left Outer Join
		SMWorkOrder smwo on
			smwo.SMCo = e.SMCo
			and smwo.WorkOrder = e.WorkOrder
			and e.Type in (6,7)
	Left Outer Join
		SMWorkOrderStatus smwos on
			smwos.SMCo = smwo.SMCo
			and smwos.WorkOrder = smwo.WorkOrder
			and smwos.Status not in ('Open', 'New')
GO
GRANT SELECT ON  [dbo].[SMEntityExt] TO [public]
GRANT INSERT ON  [dbo].[SMEntityExt] TO [public]
GRANT DELETE ON  [dbo].[SMEntityExt] TO [public]
GRANT UPDATE ON  [dbo].[SMEntityExt] TO [public]
GO
