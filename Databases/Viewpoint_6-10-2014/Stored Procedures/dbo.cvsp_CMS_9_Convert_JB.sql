SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Convert all JB tables
	Created:	05.14.10
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
			
	EXEC cvsp_CMS_9_Convert_JB 1,1
*/


CREATE PROCEDURE [dbo].[cvsp_CMS_9_Convert_JB] 
(@fromco smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */

AS

declare @errmsg varchar(1000), @rowcount int, @rc int

/*
--  Step 2 of 3
--  un-rem this section if you would like to use a counter for multiple company, 2nd section at bottom of code also  
--  and a multi company xref will need to be created dbo.budXRefCompany(Fromco, Toco, Seq)

declare @counter int, @toco smallint, @fromco smallint
set @counter = 1
while (@counter <= (select MAX(Seq) from  dbo.budXRefCompany))
begin
      select @toco = Toco, @fromco=Fromco from  dbo.budXRefCompany where  Seq = @counter;

select @counter , @toco, @fromco;
*/

if not exists(select name from sysobjects where name='cvLog')
create table cvLog(ProcDate smalldatetime null, ProcName varchar(50) null,
	FromCo smallint null, ToCo smallint null,
	RowsConvert int null, ErrMsg varchar(1000) null); 

--JBCO
if not exists (select 1 from bJBCO where JBCo=@toco)
Begin
	select @errmsg='JBCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_JB',@fromco, @toco, 0, @errmsg
	return (1)
End


--JB Insert
exec @rc= dbo.cvsp_CMS_JB @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JB',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JB',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/

-- to be on safe side re-enable all SL/JC/AP triggers
ALTER table bJBIN enable trigger all; 
ALTER table bJBIT enable trigger all; 
ALTER table bJBIS enable trigger all; 
ALTER table bJBCX enable trigger all; 
ALTER Table bJBCC enable trigger all; 



return @@error

GO
