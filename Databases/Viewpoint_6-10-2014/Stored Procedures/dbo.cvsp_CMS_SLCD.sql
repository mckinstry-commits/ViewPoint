SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE proc [dbo].[cvsp_CMS_SLCD] 
	( @fromco1 smallint
	, @fromco2 smallint
	, @fromco3 smallint
	, @toco smallint
	, @errmsg varchar(1000) output
	, @rowcount bigint output
	) 
as





/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		SL Change Orders (SLCD)
	Created on:	10.12.09
	Created by:	JJH    
	Revisions:	1. 10/25/2012 BTC - Modified to pull SubCO from PMSL
	
	EXEC cvsp_CMS_SLCD 1,15,50,1,'',0
**/


set @errmsg=''
set @rowcount=0



ALTER Table bSLCD disable trigger all;
ALTER TABLE vPMSubcontractCO disable trigger all;

-- delete existing trans
BEGIN tran
delete from bSLCD where SLCo=@toco
delete from vPMSubcontractCO where SLCo=@toco
COMMIT TRAN;

-- add new trans
BEGIN TRAN
BEGIN TRY




insert bSLCD (SLCo, Mth, SLTrans,SL, SLItem,SLChangeOrder,AppChangeOrder,
	ActDate,UM,ChangeCurUnits,ChangeCurUnitCost,ChangeCurCost,BatchId,PostedDate,PurgeYN,udSource,udConv)

select @toco
, Mth=convert(nvarchar(max),DATEPART(mm,InterfaceDate)) + '/01/' + convert(nvarchar(max),DATEPART(yy,InterfaceDate))
, SLTrans=/*Seq*/ROW_NUMBER() over (partition by SLCo,convert(nvarchar(max),DATEPART(mm,InterfaceDate)) + '/01/' + convert(nvarchar(max),DATEPART(yy,InterfaceDate)) order by SLCo,convert(nvarchar(max),DATEPART(mm,InterfaceDate)) + '/01/' + convert(nvarchar(max),DATEPART(yy,InterfaceDate)))
, SL
, SLItem
, SubCO=SubCO --ROW_NUMBER() OVER (PARTITION BY SLCo, SL order by SLCo, SL, InterfaceDate)
, ACO
, InterfaceDate
, UM=PMSL.UM
, ChangeCurUnits=0
, ChangeCurUnitCost=0
, ChangeCurCost=Amount
, BatchId=1
, PostedDate=InterfaceDate
, PurgeYN='N' 
, udSource='SLCD'
	,udConv ='Y'
from bPMSL PMSL
where RecordType='C' 
	and SL is not null
	and PMSL.SLCo=@toco

insert vPMSubcontractCO
	( PMCo
	, Project
	, SubCO
	, Description
	, Date
	, Status
	, SLCo
	, SL
	, ReadyForAcctg
	, ApprovedBy
	, DateApproved
	)

select distinct PMCo		= bSLHD.SLCo
	 , Project  = Job
	 , SubCO	= SLChangeOrder
	 , Description	= bSLHD.Description
	 , Date		= ActDate
	 , Status	= 'FINAL'
	 , SLCo		= bSLHD.SLCo
	 , SL		= bSLHD.SL
	 , ReadyForAcctg = 'Y'
	 , ApprovedBy		= 'viewpointcs'
	 , DateApproved		= PostedDate
  from bSLCD 
  join bSLHD
    on bSLHD.SL = bSLCD.SL
   and bSLHD.SLCo = bSLCD.SLCo
 where bSLCD.SLCo = @toco


select @rowcount=@@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

ALTER Table bSLCD enable trigger all;
ALTER TABLE vPMSubcontractCO enable trigger all;

return @@error



GO
