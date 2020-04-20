use Viewpoint
go

DISABLE TRIGGER btAPULu ON bAPUL
GO

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


ENABLE TRIGGER btAPULu ON bAPUL
GO
