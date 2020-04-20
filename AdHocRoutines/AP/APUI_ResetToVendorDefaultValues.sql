use Viewpoint
go

--select * into APUI_20141118_LWO_BU from APUI

begin tran
update APUI set
	PayMethod=apvm.PayMethod
,	V1099YN=apvm.V1099YN
,	V1099Type=apvm.V1099Type
,	V1099Box=apvm.V1099Box
from
	APVM apvm 
where
	APUI.VendorGroup=apvm.VendorGroup
and APUI.Vendor=apvm.Vendor
and 
	(
	   APUI.PayMethod <> apvm.PayMethod
	or APUI.V1099YN <> apvm.V1099YN
	or APUI.V1099Type <> apvm.V1099Type
	or APUI.V1099Box <> apvm.V1099Box
	)
and	APUI.APCo < 100

if @@ERROR=0
	commit tran
else
	rollback tran
go


-- Update APUL Units, UnitCost, ECM from PO or set to zeros & defaults

begin tran

--Update from POIT or set defaults
update APUL set
	UM=coalesce(poit.UM,'LS')
,	Units=coalesce(poit.RemUnits,0)
,	UnitCost=coalesce(poit.CurUnitCost,0.00)
,	ECM=coalesce(poit.CurECM,ECM,'E')
from
	POIT poit
where
	APUL.APCo=poit.POCo
and APUL.PO=poit.PO
and APUL.APCo < 100
and
	(
		APUL.UM<>poit.UM
	OR	(APUL.Units is null) or (APUL.Units<>coalesce(poit.RemUnits,0))
	OR	(APUL.UnitCost is null) or (APUL.UnitCost<>coalesce(poit.CurUnitCost,0.00))
	OR	(APUL.ECM<>poit.CurECM)
	)

--Update from SLIT or set defaults
update APUL set
	UM=coalesce(slit.UM,'LS')
,	Units=coalesce(slit.CurUnits,0)
,	UnitCost=coalesce(slit.CurUnitCost,0.00)
,	ECM=coalesce(ECM,'E')
from
	SLIT slit
where
	APUL.APCo=slit.SLCo
and APUL.SL=slit.SL
and APUL.APCo < 100
and
	(
		APUL.UM<>slit.UM
	OR	(APUL.Units is null) or (APUL.Units<>coalesce(slit.CurUnits,0))
	OR	(APUL.UnitCost is null) or (APUL.UnitCost<>coalesce(slit.CurUnitCost,0.00))
	)

--Update Remaining with defaults ( or build join to APRL for more explicit matching)
update APUL set
	UM=coalesce(UM,'LS')
,	Units=coalesce(Units,0)
,	UnitCost=coalesce(UnitCost,0.00)
,	ECM=coalesce(ECM, 'E')
where
	UM is null
OR	Units is null
OR	UnitCost is null
OR	ECM is null

--from
--	APRL aprl
--where
--	APUL.APCo=aprl.APCo
--and APUL.InvId=aprl.InvId
--and APUL.VendorGroup=aprl.VendorGroup
--and APUL.Vendor=aprl.Vendor
--and APUL.APCo < 100
--and
--	(
--		APUL.UM<>aprl.UM
--	OR	(APUL.Units is null) or (APUL.Units<>coalesce(aprl.Units,0))
--	OR	(APUL.UnitCost is null) or (APUL.UnitCost<>coalesce(aprl.UnitCost,0.00))
--	OR	(APUL.ECM<>aprl.ECM)
--	)

if @@ERROR=0
	commit tran
else
	rollback tran
go

/*
select
	apul.APCo
,	apul.Line
,	apul.UISeq
,	apul.UM
,	apul.Units
,	apul.UnitCost
,	apul.ECM
,	poit.UM
,	poit.RemUnits
,	poit.CurUnitCost
,	poit.CurECM
from
	APUL apul join
	POIT poit on
		apul.APCo=poit.POCo
	and	apul.PO= poit.PO
where
	apul.APCo < 100
and
	(
		apul.UM<>poit.UM
	OR	(apul.Units is null) or (apul.Units<>coalesce(poit.RemUnits,0))
	OR	(apul.UnitCost is null) or (apul.UnitCost<>coalesce(poit.CurUnitCost,0.00))
	OR	(apul.ECM<>poit.CurECM)
	)
*/
/*

select
	apui.APCo
,	apui.Vendor
,	apui.PayMethod
,	apui.V1099YN
,	apui.V1099Type
,	apui.V1099Box
,	apvm.PayMethod
,	apvm.V1099YN
,	apvm.V1099Type
,	apvm.V1099Box
from
	APUI apui join
	APVM apvm on
		apui.VendorGroup=apvm.VendorGroup
	and apui.Vendor=apvm.Vendor
where
	apui.APCo < 100
*/
