SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [dbo].[vspVACompanyCopyHQTCUpdate]
  /************************************************************************
  * CREATED: 	MV 06/24/07 
  * MODIFIED:    
  *
  * Purpose of Stored Procedure:	delete all entries in HQTC for the
  *									destination company and then insert
  *									the max transaction info for all tables
  *									with a transacation column
  *
  *************************************************************************/
       (@DestCo int, @msg varchar(200)= null output)
  as
  
  set nocount on
    
	declare @rcode int,@errmsg varchar(100)
	select @rcode = 0 
  
	if @DestCo is null
	begin
	select @errmsg = 'Missing Destination Company.',@rcode=1
	goto vspExit
	end

  	BEGIN TRY
	--clear bHQTC of any existing recs 
	delete from bHQTC where Co=@DestCo
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bARTH',ARCo, Mth, max(ARTrans) from bARTH where ARCo=@DestCo group by ARCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bAPTH',APCo, Mth, max(APTrans)  from bAPTH where APCo=@DestCo group by APCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bCMTT',CMCo, Mth, max(CMTransferTrans) from bCMTT where CMCo=@DestCo group by CMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bCMDT',CMCo, Mth, max(CMTrans) from bCMDT where CMCo=@DestCo group by CMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bGLDT',GLCo, Mth, max(GLTrans) from bGLDT where GLCo=@DestCo group by GLCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMMR',EMCo, Mth, max(EMTrans) from bEMMR where EMCo=@DestCo  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMCD',EMCo, Mth, max(EMTrans) from bEMCD where EMCo=@DestCo  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMRD',EMCo, Mth, max(Trans) from bEMRD where EMCo=@DestCo  group by EMCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMSM',Co, Mth, max(EMTrans) from bEMSM where Co=@DestCo  group by Co, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bEMLH',EMCo, Month, max(Trans) from bEMLH where EMCo=@DestCo  group by EMCo, Month
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bHQBC',Co, Mth, max(BatchId) from bHQBC where Co=@DestCo group by Co, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bINDT',INCo, Mth, max(INTrans) from bINDT where INCo=@DestCo group by INCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bJCCD',JCCo, Mth, max(CostTrans) from bJCCD where JCCo=@DestCo group by JCCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bJCID',JCCo, Mth, max(ItemTrans) from bJCID where JCCo=@DestCo group by JCCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bMSTD',MSCo, Mth, max(MSTrans) from bMSTD where MSCo=@DestCo  group by MSCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bMSHH',MSCo, Mth, max(HaulTrans) from bMSHH where MSCo=@DestCo  group by MSCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPOCD',POCo, Mth, max(POTrans) from bPOCD where POCo=@DestCo group by POCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPORD',POCo, Mth, max(POTrans) from bPORD where POCo=@DestCo group by POCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bPRLH',PRCo, Mth, max(Trans) from bPRLH where PRCo=@DestCo group by PRCo, Mth
	Insert bHQTC(TableName, Co, Mth, LastTrans) select 'bSLCD',SLCo, Mth, max(SLTrans) from bSLCD where SLCo=@DestCo group by SLCo, Mth
	END TRY
	BEGIN CATCH
		SELECT 
		@errmsg = ERROR_MESSAGE();
		select @msg = 'Err updating bHQTC, Err Msg: ' + @errmsg,@rcode=1
		END CATCH
  
vspExit:
return @rcode
  
  
  
 




GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyHQTCUpdate] TO [public]
GO
