use Viewpoint
go

/*
2014.11.20 - LWO - As per direction from Kendra, "Lock" all Converted Jobs.
To be run on Monday (11/24/2014) before WIP data generation.
*/

--Make a backup of the table "just in case"
--select * into JCCI_20141120_LWO_BU from JCCI

BEGIN TRAN

update
	JCCI
set
	udLockYN='Y'
where
	JCCo < 100
and len(ltrim(left(Contract,charindex('-',Contract)-1))) = 5
and udLockYN<>'Y'

IF @@ERROR != 0 --check @@ERROR variable after each DML statements..
BEGIN
	PRINT 'ERROR'
	ROLLBACK TRANSACTION --RollBack Transaction if Error..
	RETURN
END
ELSE
BEGIN
	COMMIT TRANSACTION --finally, Commit the transaction if Success..
	RETURN
END

GO


--When confirmed, drop the Backup table.
--drop table JCCI_20141120_LWO_BU 
--go


-- 2014-11-19 - LWO - Investigative Query to determine data set we're dealing with.
--select
--	jccm.JCCo
--,	jccm.Contract
--,	jccm.ContractStatus
--,	case jccm.ContractStatus
--		when 1 then 'Open'
--		when 2 then 'Soft Close'
--		when 3 then 'Hard Close'
--		else 'Pending'
--	end as ContractStatusName
--,	jcci.Item
--,	jcci.udLockYN
--,	case 
--		when jcch.InterfaceDate is null then 'No Interface'
--		else 'Interfaced'
--	end as InterfaceStatus
----,	jcch.InterfaceDate as PhaseCTInterfaceDate
----,	jcjp.Job
----,	jcjp.Phase
----,	jcch.CostType
--,	count(*) as JoinPhaseCTCount
--from
--	JCCM jccm join
--	JCCI jcci on
--		jccm.JCCo=jcci.JCCo
--	and jccm.Contract=jcci.Contract join
--	JCJP jcjp on
--		jcci.JCCo=jcjp.JCCo
--	and jcci.Contract=jcjp.Contract
--	and jcci.Item=jcjp.Item join 
--	JCCH jcch on
--		jcjp.JCCo=jcch.JCCo
--	and jcjp.Job=jcch.Job
--	and jcjp.PhaseGroup=jcch.PhaseGroup  
--	and jcjp.Phase=jcch.Phase 
--where 
--	jccm.JCCo < 100
--and len(ltrim(left(jccm.Contract,charindex('-',jccm.Contract)-1))) = 5
--and udLockYN<>'Y'
----and jcch.InterfaceDate is null
--group by
--	jccm.JCCo
--,	jccm.Contract
--,	jccm.ContractStatus
--,	case jccm.ContractStatus
--		when 1 then 'Open'
--		when 2 then 'Soft Close'
--		when 3 then 'Hard Close'
--		else 'Pending'
--	end 
--,	jcci.Item
--,	jcci.udLockYN
--,	case 
--		when jcch.InterfaceDate is null then 'No Interface'
--		else 'Interfaced'
--	end 
----,	jcch.InterfaceDate as PhaseCTInterfaceDate
----,	jcjp.Job
----,	jcjp.Phase
----,	jcch.CostType
--order by 
--	jccm.JCCo, jccm.Contract, jcci.Item

--select max(len(rtrim(ltrim(Contract)))) from JCCI where JCCo<100