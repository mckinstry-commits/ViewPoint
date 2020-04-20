SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bsp_UpdateHQTC    Script Date: 01/05/01 ******/
   CREATE              procedure [dbo].[bsp_UpdateHQTC]
   /*******************************************************************************
   * Created: DANF 05/19/01
   * Modified:	GF 04/21/2009 - issue #129898 bJCPR
   *
   * This SP will populate the HQTC with values from JBIN
   *
   * It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
   *
   * table to create HQTC entries for are as follows:
   * JBIN
   
   * This does not covnert bHQBC
   * RETURN PARAMS
   *   msg           Error Message, or Success message
   *
   * Returns
   *      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
   *
   *
   ********************************************************************************/
   
   (@Company bCompany = null, @msg varchar(255) output)
   
   as
   set nocount on
   
   
   declare @rcode int, @debug tinyint, @q char(1), @valcount int, @dovalidation int, @errmsg varchar(255),
           @begindate smalldatetime, @enddate smalldatetime, @bsperrmsg varchar(255)
   
   declare @openHQTC int, @validcnt int
   
   declare @co tinyint, @mth smalldatetime, @trans int, @tablename varchar(20)
   
     -- initialize cursor flag
     select @rcode = 0
   
   declare @openAPTH int
   select @tablename = 'bAPTH'
   
   -- create APTH cursor
   declare APTH_curs cursor local fast_forward for
   select APCo, Mth, Max(APTrans)
   from Viewpoint.dbo.bAPTH
   where @Company =APCo or (@Company is null)
   group by APCo, Mth
   order by APCo, Mth
   
   -- open cursor
   open APTH_curs
   select @openAPTH=1
   
   -- loop through cursor
   next_apth:
   fetch next from APTH_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endapth
   
   select @validcnt = count(*) from Viewpoint.dbo.bHQTC
   where TableName = @tablename and Co = @co and Mth = @mth
   If @validcnt > 0
   	begin
   	Update Viewpoint.dbo.bHQTC
   	Set LastTrans = @trans
   	where TableName = @tablename and Co = @co and Mth = @mth
   	IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   	end
   else	
   	begin
   	--insert the records if validated ok
   	insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
   	                   values (@tablename, @co, @mth,  @trans)
   	IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   	end
   
   goto next_apth
   
   
   endapth:
   
       if @openAPTH = 1
           begin
           close APTH_curs
           deallocate APTH_curs
           select @openAPTH = 0
           end
   
   
   -- create ARTH cursor
   declare @openARTH int
   select @tablename = 'bARTH'
   
   declare ARTH_curs cursor local fast_forward for
   select ARCo, Mth, Max(ARTrans)
   from Viewpoint.dbo.bARTH
   where @Company =ARCo or (@Company is null)
   group by ARCo, Mth
   order by ARCo, Mth
   
   -- open cursor
   open ARTH_curs
   select @openARTH=1
   
   -- loop through cursor
   next_arth:
   fetch next from ARTH_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endarth
   
   select @validcnt = count(*) from Viewpoint.dbo.bHQTC
   where TableName = @tablename and Co = @co and Mth = @mth
   If @validcnt > 0
      begin
       Update Viewpoint.dbo.bHQTC
       Set LastTrans = @trans
       where TableName = @tablename and Co = @co and Mth = @mth
       IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
      end
   else
      begin
   
   
           --insert the records if validated ok
             insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
                                     values (@tablename, @co, @mth,  @trans)
   
           IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
       end
   
   goto next_arth
   
   
   endarth:
   
       if @openARTH = 1
           begin
           close ARTH_curs
           deallocate ARTH_curs
           select @openARTH = 0
           end
   
   
     -- CM Detail
   -- create CMDT cursor
   declare @openCMDT int
   select @tablename = 'bCMDT'
   
   declare CMDT_curs cursor local fast_forward for
   select CMCo, Mth, Max(CMTrans)
   from Viewpoint.dbo.bCMDT
   where @Company =CMCo or (@Company is null)
   group by CMCo, Mth
   order by CMCo, Mth
   
   -- open cursor
   open CMDT_curs
   select @openCMDT=1
   
   -- loop through cursor
   next_CMDT:
   fetch next from CMDT_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endCMDT
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_CMDT
   
   
   endCMDT:
   
       if @openCMDT = 1
           begin
           close CMDT_curs
           deallocate CMDT_curs
           select @openCMDT = 0
           end
   
     -- EM Cost Detail
   
   -- create EMCD cursor
   declare @openEMCD int
   select @tablename = 'bEMCD'
   
   declare EMCD_curs cursor local fast_forward for
   select EMCo, Mth, Max(EMTrans)
   from Viewpoint.dbo.bEMCD
   where @Company =EMCo or (@Company is null)
   group by EMCo, Mth
   order by EMCo, Mth
   
   -- open cursor
   open EMCD_curs
   select @openEMCD=1
   
   -- loop through cursor
   next_EMCD:
   fetch next from EMCD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endEMCD
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_EMCD
   
   endEMCD:
   
       if @openEMCD = 1
           begin
           close EMCD_curs
           deallocate EMCD_curs
           select @openEMCD = 0
           end
   
   
      -- EM Revenue Detail
   
   -- create EMRD cursor
   declare @openEMRD int
   select @tablename = 'bEMRD'
   
   declare EMRD_curs cursor local fast_forward for
   select EMCo, Mth, Max(Trans)
   from Viewpoint.dbo.bEMRD
   where @Company =EMCo or (@Company is null)
   group by EMCo, Mth
   order by EMCo, Mth
   
   -- open cursor
   open EMRD_curs
   select @openEMRD=1
   
   -- loop through cursor
   next_EMRD:
   fetch next from EMRD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endEMRD
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   
   
   goto next_EMRD
   
   
   endEMRD:
   
       if @openEMRD = 1
           begin
           close EMRD_curs
           deallocate EMRD_curs
           select @openEMRD = 0
           end
   
      -- EM Location History
   -- create EMLH cursor
   declare @openEMLH int
    select @tablename = 'bEMLH'
   
   declare EMLH_curs cursor local fast_forward for
   select EMCo, Month, Max(Trans)
   from Viewpoint.dbo.bEMLH
   where @Company =EMCo or (@Company is null)
   group by EMCo, Month
   order by EMCo, Month
   
   -- open cursor
   open EMLH_curs
   select @openEMLH=1
   
   -- loop through cursor
   next_EMLH:
   fetch next from EMLH_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endEMLH
   
       select @validcnt = count(*) from Viewpoint.dbo.bHQTC
       where TableName = @tablename and Co = @co and Mth = @mth
       If @validcnt > 0
          begin
           Update Viewpoint.dbo.bHQTC
           Set LastTrans = @trans
           where TableName = @tablename and Co = @co and Mth = @mth
           IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
          end
       else
          begin
   
               --insert the records if validated ok
                 insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
   	                                  values (@tablename, @co, @mth,  @trans)
   
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
           end
   
   goto next_EMLH
   
   
   endEMLH:
   
       if @openEMLH = 1
           begin
           close EMLH_curs
           deallocate EMLH_curs
           select @openEMLH = 0
           end
   
       -- EM Meter Readings
   
   -- create EMMR cursor
   declare @openEMMR int
    select @tablename = 'bEMMR'
   
   declare EMMR_curs cursor local fast_forward for
   select EMCo, Mth, Max(EMTrans)
   from Viewpoint.dbo.bEMMR
   where @Company =EMCo or (@Company is null)
   group by EMCo, Mth
   order by EMCo, Mth
   
   -- open cursor
   open EMMR_curs
   select @openEMMR=1
   
   -- loop through cursor
   next_EMMR:
   fetch next from EMMR_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endEMMR
   
       select @validcnt = count(*) from Viewpoint.dbo.bHQTC
       where TableName = @tablename and Co = @co and Mth = @mth
       If @validcnt > 0
          begin
           Update Viewpoint.dbo.bHQTC
           Set LastTrans = @trans
           where TableName = @tablename and Co = @co and Mth = @mth
           IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
          end
       else
          begin
   
               --insert the records if validated ok
                 insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
   	                                  values (@tablename, @co, @mth,  @trans)
   
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
           end
   
   goto next_EMMR
   
   
   endEMMR:
   
       if @openEMMR = 1
           begin
           close EMMR_curs
           deallocate EMMR_curs
           select @openEMMR = 0
           end
   
   
   -- EM Miles By State
     declare @openEMSM int
      select @tablename = 'bEMSM'
     
     declare EMSM_curs cursor local fast_forward for
     select Co, Mth, Max(EMTrans)
     from Viewpoint.dbo.bEMSM
     where @Company=Co or (@Company is null)
     group by Co, Mth
     order by Co, Mth
     
     -- open cursor
     open EMSM_curs
     select @openEMSM=1
     
     -- loop through cursor
     next_EMSM:
     fetch next from EMSM_curs
     into @co, @mth, @trans
     
     if @@fetch_status <> 0 goto endEMSM
     
             select @validcnt = count(*) from Viewpoint.dbo.bHQTC
             where TableName = @tablename and Co = @co and Mth = @mth
             If @validcnt > 0
                begin
                 Update Viewpoint.dbo.bHQTC
                 Set LastTrans = @trans
                 where TableName = @tablename and Co = @co and Mth = @mth
                 IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
     
                end
             else
                begin
     
                     --insert the records if validated ok
                       insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
        	                                  values (@tablename, @co, @mth,  @trans)
     
                     IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
                 end
     
     goto next_EMSM
     
     
     endEMSM:
     
         if @openEMSM = 1
             begin
             close EMSM_curs
             deallocate EMSM_curs
             select @openEMSM = 0
             end
   
   
      -- GL Detail
   -- create GLDT cursor
   declare @openGLDT int
   select @tablename = 'bGLDT'
   
   declare GLDT_curs cursor local fast_forward for
   select GLCo, Mth, Max(GLTrans)
   from Viewpoint.dbo.bGLDT
   where @Company =GLCo or (@Company is null)
   group by GLCo, Mth
   order by GLCo, Mth
   
   -- open cursor
   open GLDT_curs
   select @openGLDT=1
   
   -- loop through cursor
   next_GLDT:
   fetch next from GLDT_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endGLDT
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_GLDT
   
   
   endGLDT:
   
       if @openGLDT = 1
           begin
           close GLDT_curs
           deallocate GLDT_curs
           select @openGLDT = 0
           end
   
   
       -- IN Detail
   -- create INDT cursor
   declare @openINDT int
   select @tablename = 'bINDT'
   
   declare INDT_curs cursor local fast_forward for
   select INCo, Mth, Max(INTrans)
   from Viewpoint.dbo.bINDT
   where @Company =INCo or (@Company is null)
   group by INCo, Mth
   order by INCo, Mth
   
   -- open cursor
   open INDT_curs
   select @openINDT=1
   
   -- loop through cursor
   next_INDT:
   fetch next from INDT_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endINDT
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_INDT
   
   
   endINDT:
   
       if @openINDT = 1
           begin
           close INDT_curs
           deallocate INDT_curs
           select @openINDT = 0
           end
   
   
   ------ JC Cost Detail
   ----select @tablename = 'bJCCD'
   ------ create JCCD cursor
   ----declare @openJCCD int
   
   ----declare JCCD_curs cursor local fast_forward for
   ----select JCCo, Mth, Max(CostTrans)
   ----from Viewpoint.dbo.bJCCD
   ----where @Company =JCCo or (@Company is null)
   ----group by JCCo, Mth
   ----order by JCCo, Mth
   
   
   ------ open cursor
   ----open JCCD_curs
   ----select @openJCCD=1
   
   ------ loop through cursor
   ----next_JCCD:
   ----fetch next from JCCD_curs
   ----into @co, @mth, @trans
   
   ----if @@fetch_status <> 0 goto endJCCD
   
   ----        select @validcnt = count(*) from Viewpoint.dbo.bHQTC
   ----        where TableName = @tablename and Co = @co and Mth = @mth
   ----        If @validcnt > 0
   ----           begin
   ----            Update Viewpoint.dbo.bHQTC
   ----            Set LastTrans = @trans
   ----            where TableName = @tablename and Co = @co and Mth = @mth
   ----            IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
   ----           end
   ----        else
   ----           begin
   
   ----                --insert the records if validated ok
   ----                  insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
   ----   	                                  values (@tablename, @co, @mth,  @trans)
   
   ----                IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   ----            end
   
   ----goto next_JCCD
   
   
   ----endJCCD:
   
   ----    if @openJCCD = 1
   ----        begin
   ----        close JCCD_curs
   ----        deallocate JCCD_curs
   ----        select @openJCCD = 0
   ----        end


---- JC Cost Detail
set @tablename = 'bJCCD'

;
---- create CTE for JCCD transaction count to update bHQTC existing rows
with JCCDUpdate AS
	(SELECT top 100 percent d.JCCo, d.Mth, 'LastTrans' = Max(d.CostTrans)
		from bJCCD d join dbo.bHQTC t on t.TableName=@tablename and t.Co=d.JCCo and t.Mth=d.Mth
		where d.JCCo is not null
		group by d.JCCo, d.Mth
		order by d.JCCo, d.Mth
		)

		----select * from JCCDUpdate
		Update dbo.bHQTC Set LastTrans = JCCDUpdate.LastTrans
		from JCCDUpdate
		where dbo.bHQTC.TableName=@tablename and dbo.bHQTC.Co=JCCDUpdate.JCCo and dbo.bHQTC.Mth=JCCDUpdate.Mth
;


;
---- create CTE for JCCD transaction count to update bHQTC new rows
with JCCDInsert AS
	(SELECT top 100 percent d.JCCo, d.Mth, 'LastTrans' = Max(d.CostTrans)
		from bJCCD d
		where d.JCCo is not null
		and not exists(select 1 from dbo.bHQTC t where t.TableName=@tablename and t.Co=d.JCCo and t.Mth=d.Mth)
		group by d.JCCo, d.Mth
		order by d.JCCo, d.Mth
		)

		--select * from JCCDInsert
		insert dbo.bHQTC(TableName, Co, Mth, LastTrans)
		select @tablename, JCCDInsert.JCCo, JCCDInsert.Mth, JCCDInsert.LastTrans
		from JCCDInsert
;




-- JC Revenue Detail
-- create JCID cursor
----declare @openJCID int
----select @tablename = 'bJCID'
   
----   declare JCID_curs cursor local fast_forward for
----   select JCCo, Mth, Max(ItemTrans)
----   from Viewpoint.dbo.bJCID
----   where @Company =JCCo or (@Company is null)
----   group by JCCo, Mth
----   order by JCCo, Mth
   
----   -- open cursor
----   open JCID_curs
----   select @openJCID=1
   
----   -- loop through cursor
----   next_JCID:
----   fetch next from JCID_curs
----   into @co, @mth, @trans
   
----   if @@fetch_status <> 0 goto endJCID
   
----           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
----           where TableName = @tablename and Co = @co and Mth = @mth
----           If @validcnt > 0
----              begin
----               Update Viewpoint.dbo.bHQTC
----               Set LastTrans = @trans
----               where TableName = @tablename and Co = @co and Mth = @mth
----               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
----              end
----           else
----              begin
   
----                   --insert the records if validated ok
----                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
----      	                                  values (@tablename, @co, @mth,  @trans)
   
----                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
----               end
   
----   goto next_JCID
   
   
----   endJCID:
   
----       if @openJCID = 1
----           begin
----           close JCID_curs
----           deallocate JCID_curs
----           select @openJCID = 0
----           end




---- JC Revenue Detail
set @tablename = 'bJCCD'

;
---- create CTE for JCID transaction count to update bHQTC existing rows
with JCIDUpdate AS
	(SELECT top 100 percent d.JCCo, d.Mth, 'LastTrans' = Max(d.ItemTrans)
		from bJCID d join dbo.bHQTC t on t.TableName='bJCID' and t.Co=d.JCCo and t.Mth=d.Mth
		where d.JCCo is not null
		group by d.JCCo, d.Mth
		order by d.JCCo, d.Mth
		)

		----select * from JCCDUpdate
		Update dbo.bHQTC Set LastTrans = JCIDUpdate.LastTrans
		from JCIDUpdate
		where dbo.bHQTC.TableName='bJCID' and dbo.bHQTC.Co=JCIDUpdate.JCCo and dbo.bHQTC.Mth=JCIDUpdate.Mth
;


;
---- create CTE for JCID transaction count to update bHQTC new rows
with JCIDInsert AS
	(SELECT top 100 percent d.JCCo, d.Mth, 'LastTrans' = Max(d.ItemTrans)
		from bJCID d
		where d.JCCo is not null
		and not exists(select 1 from dbo.bHQTC t where t.TableName='bJCID' and t.Co=d.JCCo and t.Mth=d.Mth)
		group by d.JCCo, d.Mth
		order by d.JCCo, d.Mth
		)

		--select * from JCCDInsert
		insert dbo.bHQTC(TableName, Co, Mth, LastTrans)
		select 'bJCID', JCIDInsert.JCCo, JCIDInsert.Mth, JCIDInsert.LastTrans
		from JCIDInsert
;








---- JC Projection Worksheet detail
---- create JCPR cursor
declare @openJCPR int
select @tablename = 'bJCPR'

declare JCPR_curs cursor local fast_forward for
select JCCo, Mth, Max(ResTrans)
from Viewpoint.dbo.bJCPR
where @Company =JCCo or (@Company is null)
group by JCCo, Mth
order by JCCo, Mth

---- open cursor
open JCPR_curs
select @openJCPR=1

---- loop through cursor
next_JCPR:
fetch next from JCPR_curs
into @co, @mth, @trans

if @@fetch_status <> 0 goto endJCPR

select @validcnt = count(*) from Viewpoint.dbo.bHQTC
where TableName = @tablename and Co = @co and Mth = @mth
If @validcnt > 0
	begin
	Update Viewpoint.dbo.bHQTC Set LastTrans = @trans
	where TableName = @tablename and Co = @co and Mth = @mth
	IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
	end
else
	begin
	---- insert the records if validated ok
	insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
	values (@tablename, @co, @mth,  @trans)
	IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
	end

goto next_JCPR

endJCPR:
   if @openJCPR = 1
       begin
       close JCPR_curs
       deallocate JCPR_curs
       select @openJCPR = 0
       end





---- MS Haulers
   
   declare @openMSHH int
   select @tablename = 'bMSHH'
   
   declare MSHH_curs cursor local fast_forward for
   select MSCo, Mth, Max(HaulTrans)
   from Viewpoint.dbo.bMSHH
   where @Company =MSCo or (@Company is null)
   group by MSCo, Mth
   order by MSCo, Mth
   
   -- open cursor
   open MSHH_curs
   select @openMSHH=1
   
   -- loop through cursor
   next_MSHH:
   fetch next from MSHH_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endMSHH
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_MSHH
   
   
   endMSHH:
   
       if @openMSHH = 1
           begin
           close MSHH_curs
           deallocate MSHH_curs
           select @openMSHH = 0
           end
   
   
         --MS Ticket Detail
   -- create MSTD cursor
   declare @openMSTD int
   select @tablename = 'bMSTD'
   
   declare MSTD_curs cursor local fast_forward for
   select MSCo, Mth, Max(MSTrans)
   from Viewpoint.dbo.bMSTD
   where @Company =MSCo or (@Company is null)
   group by MSCo, Mth
   order by MSCo, Mth
   
   -- open cursor
   open MSTD_curs
   select @openMSTD=1
   
   -- loop through cursor
   next_MSTD:
   fetch next from MSTD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endMSTD
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_MSTD
   
   
   endMSTD:
   
       if @openMSTD = 1
           begin
           close MSTD_curs
           deallocate MSTD_curs
           select @openMSTD = 0
           end
   
   
          --PO Change Order Detail
   
   declare @openPOCD int
   select @tablename = 'bPOCD'
   
   declare POCD_curs cursor local fast_forward for
   select POCo, Mth, Max(POTrans)
   from Viewpoint.dbo.bPOCD
   where @Company =POCo or (@Company is null)
   group by POCo, Mth
   order by POCo, Mth
   
   -- open cursor
   open POCD_curs
   select @openPOCD=1
   
   -- loop through cursor
   next_POCD:
   fetch next from POCD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endPOCD
   --
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_POCD
   
   
   endPOCD:
   
       if @openPOCD = 1
           begin
           close POCD_curs
           deallocate POCD_curs
           select @openPOCD = 0
           end
   
           --PO Receipt Detail
   
   declare @openPORD int
   select @tablename = 'bPORD'
   
   declare PORD_curs cursor local fast_forward for
   select POCo, Mth, Max(POTrans)
   from Viewpoint.dbo.bPORD
   where @Company =POCo or (@Company is null)
   group by POCo, Mth
   order by POCo, Mth
   
   -- open cursor
   open PORD_curs
   select @openPORD=1
   
   -- loop through cursor
   next_PORD:
   fetch next from PORD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endPORD
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_PORD
   
   
   endPORD:
   
       if @openPORD = 1
           begin
           close PORD_curs
           deallocate PORD_curs
           select @openPORD = 0
           end
   
           --PR Leave History
   
   declare @openPRLH int
   select @tablename = 'bPRLH'
   
   declare PRLH_curs cursor local fast_forward for
   select PRCo, Mth, Max(Trans)
   from Viewpoint.dbo.bPRLH
   where @Company =PRCo or (@Company is null)
   group by PRCo, Mth
   order by PRCo, Mth
   
   -- open cursor
   open PRLH_curs
   select @openPRLH=1
   
   -- loop through cursor
   next_PRLH:
   fetch next from PRLH_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endPRLH
   
           select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_PRLH
   
   
   endPRLH:
   
       if @openPRLH = 1
           begin
           close PRLH_curs
           deallocate PRLH_curs
           select @openPRLH = 0
           end
   
            --SL Change Order Detail
   
    select @tablename = 'bSLCD'
   declare @openSLCD int
   select @tablename = 'bSLCD'
   
   declare SLCD_curs cursor local fast_forward for
   select SLCo, Mth, Max(SLTrans)
   from Viewpoint.dbo.bSLCD
   where @Company =SLCo or (@Company is null)
   group by SLCo, Mth
   order by SLCo, Mth
   
   -- open cursor
   open SLCD_curs
   select @openSLCD=1
   
   -- loop through cursor
   next_SLCD:
   fetch next from SLCD_curs
   into @co, @mth, @trans
   
   if @@fetch_status <> 0 goto endSLCD
   
            select @validcnt = count(*) from Viewpoint.dbo.bHQTC
           where TableName = @tablename and Co = @co and Mth = @mth
           If @validcnt > 0
              begin
               Update Viewpoint.dbo.bHQTC
               Set LastTrans = @trans
               where TableName = @tablename and Co = @co and Mth = @mth
               IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Update Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
   
              end
           else
              begin
   
                   --insert the records if validated ok
                     insert Viewpoint.dbo.bHQTC (TableName, Co, Mth, LastTrans)
      	                                  values (@tablename, @co, @mth,  @trans)
   
                   IF @@ERROR <> 0 select @rcode = 1, @msg = 'HQTC Insert Error for table ' + @tablename + ' Company ' + convert(varchar(3),@co) + ' Month ' + convert(varchar(20),@mth)
               end
   
   goto next_SLCD
   
   
   endSLCD:
   
       if @openSLCD = 1
           begin
           close SLCD_curs
           deallocate SLCD_curs
           select @openSLCD = 0
           end 
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bsp_UpdateHQTC] TO [public]
GO
