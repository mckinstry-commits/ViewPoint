SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[cvsp_CMS_HQTC_Update_AllTables]


/**
=========================================================================
Copyright © 2009 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
      Title:      HQTC update
      Created on: 9.2.09
      Created By: JH - copy of vspVACompanyCopyHQTCUpdate  
      Revisions:  1. None
**/
       (@toco int, @msg varchar(200)= null output)
  as
  

  set nocount on
    
	declare @rcode int, @errmsg varchar(100)
	select @rcode = 0 
  
	if @toco is null
	begin
	select @errmsg = 'Missing Destination Company.',@rcode=1
	goto vspExit
	end

  	BEGIN TRY
	--clear bHQTC of any existing recs 
	delete from bHQTC where Co=@toco
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bARTH',ARCo, Mth, max(ARTrans) from bARTH where ARCo=@toco group by ARCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bAPTH',APCo, Mth, max(APTrans)  from bAPTH where APCo=@toco group by APCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bCMTT',CMCo, Mth, max(CMTransferTrans) from bCMTT where CMCo=@toco group by CMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bCMDT',CMCo, Mth, max(CMTrans) from bCMDT where CMCo=@toco group by CMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bGLDT',GLCo, Mth, max(GLTrans) from bGLDT where GLCo=@toco group by GLCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMMR',EMCo, Mth, max(EMTrans) from bEMMR where EMCo=@toco  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMCD',EMCo, Mth, max(EMTrans) from bEMCD where EMCo=@toco  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMRD',EMCo, Mth, max(Trans) from bEMRD where EMCo=@toco  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMSM',Co, Mth, max(EMTrans) from bEMSM where Co=@toco  group by Co, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMLH',EMCo, Month, max(Trans) from bEMLH where EMCo=@toco  group by EMCo, Month
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bHQBC',Co, Mth, max(BatchId) from bHQBC where Co=@toco group by Co, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bINDT',INCo, Mth, max(INTrans) from bINDT where INCo=@toco group by INCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bJCCD',JCCo, Mth, max(CostTrans) from bJCCD where JCCo=@toco group by JCCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bJCID',JCCo, Mth, max(ItemTrans) from bJCID where JCCo=@toco group by JCCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bMSTD',MSCo, Mth, max(MSTrans) from bMSTD where MSCo=@toco  group by MSCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bMSHH',MSCo, Mth, max(HaulTrans) from bMSHH where MSCo=@toco  group by MSCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPOCD',POCo, Mth, max(POTrans) from bPOCD where POCo=@toco group by POCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPORD',POCo, Mth, max(POTrans) from bPORD where POCo=@toco group by POCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPRLH',PRCo, Mth, max(Trans) from bPRLH where PRCo=@toco group by PRCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bSLCD',SLCo, Mth, max(SLTrans) from bSLCD where SLCo=@toco group by SLCo, Mth
	END TRY
	BEGIN CATCH
		SELECT 
		@errmsg = ERROR_MESSAGE();
		select @msg = 'Err updating bHQTC, Err Msg: ' + @errmsg,@rcode=1
		END CATCH
  
vspExit:
return @rcode
  
  
  
 






GO
