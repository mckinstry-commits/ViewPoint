SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create proc [dbo].[cvsp_CMS_SM_AddColsIndexes] (@fromco smallint, @toco smallint, 
	@errmsg varchar(1000) output, @rowcount bigint output) 
as




/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Add Columns and Indexes to AP tables 
	Created:	10/14/2009
	Created by: JJH
	Revisions:	1. none
**/


set @errmsg=''
set @rowcount=0


BEGIN try


if not exists (select name from Viewpoint.dbo.syscolumns 
	where id=OBJECT_ID('Viewpoint.dbo.budxrefARCustomer')and name='SMCustomer')
ALter table Viewpoint.dbo.budxrefARCustomer add SMCustomer bYN



if not exists (select name from dbo.syscolumns 
	where id=OBJECT_ID('dbo.vSMCustomer')and name='udConvertedYN')
ALter table dbo.vSMCustomer add udConvertedYN bYN


--------------------------------------------------
--create index on newly created columns
-------------------------------------------------

--if not exists (select name from sysindexes 
--  where id=OBJECT_ID('bARTL') and name='iARTLudARTOPDID')
--create index iARTLudARTOPDID on bARTL(udARTOPDID)

	
	
	

END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')

END CATCH;


return @@error

GO
