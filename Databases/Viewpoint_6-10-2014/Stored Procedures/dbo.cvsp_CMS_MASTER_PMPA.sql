SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/**
=========================================================================================
Copyright © 2014 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, modified,
transmitted or executed without written consent from VCS.
=========================================================================================
	Title:		PM Project Addons (bPMPA)
	Created:	2/14/2014
	Created by:	VCS Technical Services - Bryan Clark
	Revisions:	
		1. 
					
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_MASTER_PMPA] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output
	) 

as

set @errmsg=''
set @rowcount=0


--Add udConv field if not already there
if not exists (select * from syscolumns c
				join sysobjects o
					on o.id = c.id
				where o.name = 'bPMPA' and c.name = 'udConv')
begin
	alter table bPMPA add udConv char(1)
end;


alter table bPMPA disable trigger all;


--Delete existing records
delete bPMPA where PMCo = @toco;


BEGIN TRAN
BEGIN TRY


insert bPMPA
	(PMCo, Project, AddOn, Description, Basis, Pct, Amount, PhaseGroup, Phase, CostType, Contract, Item, 
		Notes, TotalType, Include, NetCalcLevel, BasisCostType, RevRedirect, RevItem, RevStartAtItem, 
		RevFixedACOItem, RevUseItem, Standard, RoundAmount, udConv)
select
	  ca.PMCo
	, Project = jm.Job
	, ca.Addon
	, ca.Description
	, ca.Basis
	, ca.Pct
	, ca.Amount
	, ca.PhaseGroup
	, ca.Phase
	, ca.CostType
	, Contract = jm.Contract
	, ca.Item
	, ca.Notes
	, ca.TotalType
	, ca.Include
	, ca.NetCalcLevel
	, ca.BasisCostType
	, ca.RevRedirect
	, ca.RevItem
	, ca.RevStartAtItem
	, ca.RevFixedACOItem
	, ca.RevUseItem
	, ca.Standard
	, ca.RoundAmount
	, udConv = 'Y'
--select *
from bPMCA ca
join bJCJM jm
	on jm.JCCo = ca.PMCo and jm.udConv = 'Y' and ca.PMCo = @toco;
		

select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bPMPA enable trigger all;

return @@error


GO
