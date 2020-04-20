use Viewpoint
go

--SELECT * FROM SMWorkOrderScope WHERE WorkOrder = 9018129 AND SMCo = 1 


-- RENTAL SCOPE on BREAK FIX
begin tran

update SMWorkOrderScope set
    ServiceCenter=us.ServiceCenter
,	CustGroup=us.CustGroup
,	BillToARCustomer=us.BillToARCustomer
,	RateTemplate=us.RateTemplate
,	SaleLocation=us.SaleLocation
,	PhaseGroup=us.PhaseGroup
from
(
select
	t1.SMCo
,	t1.WorkOrder
,	t1.Scope
,	t1.SMWorkOrderScopeID 
,   t1.ServiceCenter
,	t1.CustGroup
,	t1.BillToARCustomer
,	t1.RateTemplate
,	t1.SaleLocation
,	t1.PhaseGroup
,	t5.SMWorkOrderScopeID as TargetRowID
,	t5.Scope 
,   t5.ServiceCenter
,	t5.CustGroup
,	t5.BillToARCustomer
,	t5.RateTemplate
,	t5.SaleLocation
,	t5.PhaseGroup
from
	SMWorkOrderScope t1 join
	SMWorkOrderScope t5 on
		t1.SMCo=t5.SMCo
	and t1.WorkOrder=t5.WorkOrder
	and t1.Scope=1
	and t5.Scope=5
where
	t1.SMCo < 100
and t1.Job is null
) us
where SMWorkOrderScope.SMWorkOrderScopeID=us.TargetRowID
--and	  SMWorkOrderScope.SMCo=1
--and   SMWorkOrderScope.WorkOrder=9018129

if @@ERROR<>0
	ROLLBACK TRAN
else
	COMMIT TRAN

go



-- RENTAL SCOPE on PM
begin tran

update SMWorkOrderScope set
    ServiceCenter=us.ServiceCenter
,	CustGroup=us.CustGroup
,	BillToARCustomer=us.BillToARCustomer
,	RateTemplate=us.RateTemplate
,	SaleLocation=us.SaleLocation
,	PhaseGroup=us.PhaseGroup
from
(
select
	t1.SMCo
,	t1.WorkOrder
,	t1.Scope
,	t1.SMWorkOrderScopeID 
,   t1.ServiceCenter
,	t1.CustGroup
,	t1.BillToARCustomer
,	t1.RateTemplate
,	t1.SaleLocation
,	t1.PhaseGroup
,	t5.SMWorkOrderScopeID as TargetRowID
,	t5.Scope 
,   t5.ServiceCenter
,	t5.CustGroup
,	t5.BillToARCustomer
,	t5.RateTemplate
,	t5.SaleLocation
,	t5.PhaseGroup
from
	SMWorkOrderScope t1 join
	SMWorkOrderScope t5 on
		t1.SMCo=t5.SMCo
	and t1.WorkOrder=t5.WorkOrder
	and t1.Scope=1
	and t5.Scope=5
where
	t1.SMCo < 100
and t1.Job is not null
) us
where SMWorkOrderScope.SMWorkOrderScopeID=us.TargetRowID
--and	  SMWorkOrderScope.SMCo=1
--and   SMWorkOrderScope.WorkOrder=9018129

if @@ERROR<>0
	ROLLBACK TRAN
else
	COMMIT TRAN

go


-- SUBONTRACT SCOPE on PM
begin tran

update SMWorkOrderScope set
    ServiceCenter=us.ServiceCenter
,	CustGroup=us.CustGroup
,	BillToARCustomer=us.BillToARCustomer
,	RateTemplate=us.RateTemplate
,	SaleLocation=us.SaleLocation
,	PhaseGroup=us.PhaseGroup
from
(
select
	t1.SMCo
,	t1.WorkOrder
,	t1.Scope
,	t1.SMWorkOrderScopeID 
,   t1.ServiceCenter
,	t1.CustGroup
,	t1.BillToARCustomer
,	t1.RateTemplate
,	t1.SaleLocation
,	t1.PhaseGroup
,	t5.SMWorkOrderScopeID as TargetRowID
,	t5.Scope 
,   t5.ServiceCenter
,	t5.CustGroup
,	t5.BillToARCustomer
,	t5.RateTemplate
,	t5.SaleLocation
,	t5.PhaseGroup
from
	SMWorkOrderScope t1 join
	SMWorkOrderScope t5 on
		t1.SMCo=t5.SMCo
	and t1.WorkOrder=t5.WorkOrder
	and t1.Scope=1
	and t5.Scope=4 -- Subcontract Scope
where
	t1.SMCo < 100
and t1.Job is not null
) us
where SMWorkOrderScope.SMWorkOrderScopeID=us.TargetRowID
--and	  SMWorkOrderScope.SMCo=1
--and   SMWorkOrderScope.WorkOrder=9018129

if @@ERROR<>0
	ROLLBACK TRAN
else
	COMMIT TRAN

go
