SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLADVal    Script Date: 8/28/99 9:33:40 AM ******/
   
   CREATE  proc [dbo].[bspSLADVal]
   /***********************************************************
    * CREATED BY	: SE 6/6/97
    * MODIFIED BY	: SE 6/6/97
    *
    * USAGE:
    * validates SL Addon and returns some info,
    *
    * USED IN:
    *  SLEntry 
    *
    * INPUT PARAMETERS
    *   SLCo      Subcontract Company 
    *   Addon     Addon to validate
    * 
    * OUTPUT PARAMETERS
    *   @Type     Type of Addon, Either A=Amount or P=Pct
    *   @Pct      if Type P then Addon Percent
    *   @Amount   If Type A then Addon Amount
    *   @Phase    Default phase for this addon
    *   @CT       Default Cost Type for this addon
    *   @msg      error message if error occurs otherwise Description of addon
    * RETURN VALUE
    *   0         success
    *   1         Failure 
    *****************************************************/ 
   
       (@slco bCompany = 0, @addon tinyint, @type char(1) output, 
       @pct bPct output, @amount bDollar output, @phase bPhase output,
       @ct bJCCType output,  @msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 1, @type='', @pct=0, @amount=0, @phase='', @ct=null,
          @msg='Addon ' + convert(char(3),@addon) + ' not setup.'
   
   select @rcode=0, @msg=isnull(Description,''), @type = Type,
         @pct=Pct, @amount=Amount, @phase=Phase, @ct=JCCType from SLAD
         where SLCo=@slco and Addon=@addon
        
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLADVal] TO [public]
GO
