SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVADeleteUserConfirm    Script Date: 8/28/99 9:34:54 AM ******/
   CREATE      PROC [dbo].[bspVADeleteUserConfirm]
   /***********************************************************
    * CREATED BY: DANF 10/31/01
    * Modified  : DANF 05/14/07 - 6.X recode.
    *   
    * USAGE:
    * 	Confirm the user to be delete.
    *
    * INPUT PARAMETERS
    *   User
    *
    * OUTPUT PARAMETERS
    *   @msg      Warning or error message
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   
   (@user bVPUserName, @msg varchar(500) output)
   as
   
   set nocount on
   declare @rcode int, @validcnt int, @Desc bDesc,
           @cntAPWD int, @cntAPWH int, @cntARAA int, @cntRPRS int, @cntPRUP int, @cntPRPE int,
           @cntPRGS int, @cntJCUO int, @cntHQRP int, @cntDDUI int, @cntDDTS int, @cntDDSU int,
           @cntDDFS int, @cntDDDU int, @cntDDUP int, @cntINCW int, @cntDDFU int, @cntDDSF int,
		   @cntDDSI int
   
   select @rcode = 0
   
   if @user is null
   	begin
   	select @msg = 'Missing User!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   -- get list of tables the user will be removed from.
   
   select @cntARAA=Count(*) from ARAA where VPUserName = @user
   
   select @cntAPWD=Count(*) from APWD where UserId = @user

   select @cntAPWH=Count(*) from APWH where UserId = @user

   select @cntDDDU=Count(*) from DDDU where VPUserName = @user
   
   select @cntDDFS=Count(*) from DDFS where VPUserName = @user

   select @cntDDFU=Count(*) from DDFU where VPUserName = @user
   
   select @cntDDSU=Count(*) from DDSU where VPUserName = @user
   
   select @cntDDSF=Count(*) from DDSF where VPUserName = @user

   select @cntDDSI=Count(*) from DDSI where VPUserName = @user

   select @cntDDTS=Count(*) from DDTS where VPUserName = @user
   
   select @cntDDUI=Count(*) from DDUI where VPUserName = @user
   
   select @cntDDUP=Count(*) from DDUP where VPUserName = @user
   
   select @cntHQRP=Count(*) from HQRP where VPUserName = @user
   
   select @cntJCUO=Count(*) from JCUO where UserName = @user

   select @cntINCW=Count(*) from INCW where UserName = @user
   
   select @cntPRGS=Count(*) from PRGS where VPUserName = @user
   
   select @cntPRPE=Count(*) from PRPE where VPUserName = @user
   
   select @cntPRUP=Count(*) from PRUP where UserName = @user
   
   select @cntRPRS=Count(*) from RPRS where VPUserName = @user
   
  
   
   
   if @cntAPWD <> 0 or @cntAPWH <>0 or @cntARAA <> 0 or @cntRPRS <> 0 or @cntPRUP <> 0 or  @cntPRPE <> 0 or 
      @cntPRGS <> 0 or @cntJCUO <>0 or @cntHQRP <> 0 or @cntDDUI <> 0 or @cntDDTS <> 0 or  @cntDDSU <> 0 or
      @cntDDFS <>0 or @cntDDDU <> 0 or @cntDDUP <> 0 or @cntINCW <> 0 or  @cntDDFU <>0
   	begin
   	select @msg = 'You are about to Delete User '  + isnull(@user,'') + ' From the following tables ' + char(13)
       if @cntAPWD > 0  
          begin
          select @Desc = Description from DDTH where TableName = 'APWD'
          select @msg = isnull(@msg,'') + ' APWD - ' + isnull(@Desc,'') + char(13)
          end
       if @cntAPWH > 0        
          begin
          select @Desc = Description from DDTH where TableName = 'APWH'
          select @msg = isnull(@msg,'') + ' APWH - ' + isnull(@Desc,'') + char(13)
          end
       --if @cntARAA > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'ARAA'
       --   select @msg = @msg + ' ARAA - ' + @Desc + char(13)
       --   end
       --if @cntRPRS > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'RPRS'
       --   select @msg = @msg + ' RPRS - ' + @Desc + char(13)
       --   end

       --if @cntPRUP > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'PRUP'
       --   select @msg = @msg + ' PRUP - ' + @Desc + char(13)
       --   end 
       --if @cntPRPE > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'PRPE'
       --   select @msg = @msg + ' PRPE - ' + @Desc + char(13)
       --   end 
       --if @cntPRGS > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'PRGS'
       --   select @msg = @msg + ' PRGS - ' + @Desc + char(13)
       --   end
       --if @cntJCUO > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'JCUO'
       --   select @msg = @msg + ' JCUO - ' + @Desc + char(13)
       --   end 

       if @cntINCW > 0  
          begin
          select @Desc = Description from DDTH where TableName = 'INCW'
          select @msg = isnull(@msg,'') + ' INWC - ' + isnull(@Desc,'') + char(13)
		  end

       --if @cntDDUI > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDUI'
       --   select @msg = @msg + ' DDUI - ' + @Desc + char(13)
       --   end
       --if @cntDDTS > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDTS'
       --   select @msg = @msg + ' DDTS - ' + @Desc + char(13)
       --   end
       --if @cntDDSU > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDSU'
       --   select @msg = @msg + ' DDSU - ' + @Desc + char(13)
       --   end
       --if @cntDDSF > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDSF'
       --   select @msg = @msg + ' DDSF - ' + @Desc + char(13)
       --   end
       --if @cntDDSI > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDSI'
       --   select @msg = @msg + ' DDSI - ' + @Desc + char(13)
       --   end
       --if @cntDDFS > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDFS'
       --   select @msg = @msg + ' DDFS - ' + @Desc + char(13)
       --   end 
       --if @cntDDFU > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDFU'
       --   select @msg = @msg + ' DDFU - ' + @Desc + char(13)
       --   end 
       --if @cntDDDU > 0  
       --   begin
       --   select @Desc = Description from DDTH where TableName = 'DDDU'
       --   select @msg = @msg + ' DDDU - ' + @Desc + char(13)
       --   end
       if @cntDDUP > 0  
          begin
          select @Desc = Description from DDTH where TableName = 'DDUP'
          select @msg = @msg + ' DDUP - ' + @Desc + char(13)
          end
       select @msg = @msg + 'Do you wish to continue?', @rcode=0
   	end
   else
   	begin
   	select @msg = 'User was not found to have any entries in any Viewpoint tables', @rcode=1
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspVADeleteUserConfirm] TO [public]
GO
